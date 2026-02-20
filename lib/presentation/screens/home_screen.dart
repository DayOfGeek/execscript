// ExecScript - Mobile SSH Script Execution
// Copyright (C) 2026 DayOfGeek.com
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// You should have received a copy of the GNU General Public License
// along with this program. If not, see <https://www.gnu.org/licenses/>.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../core/theme.dart';
import '../../data/models/execution.dart';
import '../../data/models/script.dart';
import '../../data/models/server.dart';
import '../../data/repositories/server_repository.dart';
import '../../data/repositories/script_repository.dart';
import '../../data/repositories/execution_repository.dart';
import '../providers/servers_provider.dart';
import '../providers/scripts_provider.dart';
import '../providers/executions_provider.dart';
import 'servers_screen.dart';
import 'scripts_screen.dart';
import 'background_jobs_screen.dart';
import 'execution_screen.dart';
import 'settings_screen.dart';
import '../forms/server_form.dart';
import '../forms/script_form.dart';

/// Home screen with dashboard overview
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colors = theme.extension<CyberTermThemeExtension>();
    final surface = colors?.surface ?? CyberTermColors.surface;
    final primary = colors?.primary ?? CyberTermColors.primary;
    final warning = colors?.warning ?? CyberTermColors.warning;
    final border = colors?.border ?? CyberTermColors.border;

    final serversState = ref.watch(serversProvider);
    final scriptsState = ref.watch(scriptsProvider);
    final executionsState = ref.watch(executionsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'EXECSCRIPT',
          style: GoogleFonts.jetBrainsMono(
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => _navigateToSettings(context),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await ref.read(serversProvider.notifier).loadServers();
          await ref.read(scriptsProvider.notifier).loadScripts();
          await ref.read(executionsProvider.notifier).loadExecutions();
        },
        color: primary,
        backgroundColor: surface,
        child: ListView(
          children: [
            // Servers Section
            _buildSectionHeader(
              context,
              'SERVERS',
              onTap: () => _navigateToServers(context),
            ),
            _buildServersSection(context, serversState),
            Divider(height: 1, color: border),

            // Scripts Section
            _buildSectionHeader(
              context,
              'SCRIPT LIBRARY',
              onTap: () => _navigateToScripts(context),
            ),
            _buildScriptsSection(context, scriptsState),
            Divider(height: 1, color: border),

            // Recent Executions Section
            _buildSectionHeader(context, 'RECENT EXECUTIONS'),
            _buildExecutionsSection(context, executionsState),
            const SizedBox(height: 80), // Space for FAB
          ],
        ),
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton.small(
            onPressed: () => _showAddMenu(context),
            heroTag: 'addMenu',
            child: const Icon(Icons.add),
          ),
          const SizedBox(height: 8),
          FloatingActionButton.small(
            onPressed: () => _navigateToBackgroundJobs(context),
            heroTag: 'backgroundJobs',
            backgroundColor: surface,
            child: Stack(
              children: [
                Icon(Icons.terminal, color: primary),
                if (executionsState.runningExecutions.isNotEmpty)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: warning,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(
    BuildContext context,
    String title, {
    VoidCallback? onTap,
  }) {
    final theme = Theme.of(context);
    final colors = theme.extension<CyberTermThemeExtension>();
    final surface = colors?.surface ?? CyberTermColors.surface;
    final primary = colors?.primary ?? CyberTermColors.primary;
    final textDim = colors?.textDim ?? CyberTermColors.textDim;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(color: surface),
      child: Row(
        children: [
          const TerminalLabel('SECTION'),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              title,
              style: GoogleFonts.jetBrainsMono(
                color: primary,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          if (onTap != null)
            TextButton(
              onPressed: onTap,
              child: Text(
                '[VIEW ALL]',
                style: GoogleFonts.jetBrainsMono(fontSize: 10, color: textDim),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildServersSection(BuildContext context, ServersState state) {
    final theme = Theme.of(context);
    final colors = theme.extension<CyberTermThemeExtension>();
    final primary = colors?.primary ?? CyberTermColors.primary;

    if (state.isLoading && state.servers.isEmpty) {
      return SizedBox(
        height: 100,
        child: Center(child: CircularProgressIndicator(color: primary)),
      );
    }

    if (state.servers.isEmpty) {
      return SizedBox(
        height: 120,
        child: _buildEmptyState(
          context,
          icon: Icons.computer,
          message: 'No servers configured',
          action: '[ADD SERVER]',
          onAction: () => _navigateToAddServer(context),
        ),
      );
    }

    // Show up to 3 servers
    final servers = state.servers.take(3).toList();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: servers
          .map(
            (server) => _ServerListTile(
              server: server,
              onTap: () => _navigateToEditServer(context, server),
            ),
          )
          .toList(),
    );
  }

  Widget _buildScriptsSection(BuildContext context, ScriptsState state) {
    final theme = Theme.of(context);
    final colors = theme.extension<CyberTermThemeExtension>();
    final primary = colors?.primary ?? CyberTermColors.primary;

    if (state.isLoading && state.scripts.isEmpty) {
      return SizedBox(
        height: 100,
        child: Center(child: CircularProgressIndicator(color: primary)),
      );
    }

    if (state.scripts.isEmpty) {
      return SizedBox(
        height: 120,
        child: _buildEmptyState(
          context,
          icon: Icons.code,
          message: 'No scripts created',
          action: '[CREATE SCRIPT]',
          onAction: () => _navigateToAddScript(context),
        ),
      );
    }

    // Show 5 most recent scripts
    final scripts = state.scripts.take(5).toList();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: scripts
          .map(
            (script) => _ScriptListTile(
              script: script,
              onTap: () => _showQuickExecute(context, script),
            ),
          )
          .toList(),
    );
  }

  Widget _buildExecutionsSection(BuildContext context, ExecutionsState state) {
    final theme = Theme.of(context);
    final colors = theme.extension<CyberTermThemeExtension>();
    final primary = colors?.primary ?? CyberTermColors.primary;

    if (state.isLoading && state.executions.isEmpty) {
      return SizedBox(
        height: 80,
        child: Center(child: CircularProgressIndicator(color: primary)),
      );
    }

    if (state.recentExecutions.isEmpty) {
      return SizedBox(
        height: 80,
        child: _buildEmptyState(
          context,
          icon: Icons.terminal,
          message: 'No executions yet',
          action: null,
        ),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: state.recentExecutions
          .map(
            (execution) => _ExecutionListTile(
              execution: execution,
              onTap: () => _viewExecution(context, execution),
            ),
          )
          .toList(),
    );
  }

  Widget _buildEmptyState(
    BuildContext context, {
    required IconData icon,
    required String message,
    String? action,
    VoidCallback? onAction,
  }) {
    final theme = Theme.of(context);
    final colors = theme.extension<CyberTermThemeExtension>();
    final primaryDim = colors?.primaryDim ?? CyberTermColors.primaryDim;
    final textDim = colors?.textDim ?? CyberTermColors.textDim;
    final primary = colors?.primary ?? CyberTermColors.primary;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 32, color: primaryDim),
          const SizedBox(height: 8),
          Text(
            message,
            style: GoogleFonts.jetBrainsMono(color: textDim, fontSize: 12),
          ),
          if (action != null && onAction != null) ...[
            const SizedBox(height: 8),
            TextButton(
              onPressed: onAction,
              child: Text(
                action,
                style: GoogleFonts.jetBrainsMono(
                  color: primary,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _showAddMenu(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.extension<CyberTermThemeExtension>();
    final surface = colors?.surface ?? CyberTermColors.surface;
    final primary = colors?.primary ?? CyberTermColors.primary;

    showModalBottomSheet(
      context: context,
      backgroundColor: surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.computer, color: primary),
              title: Text('[ADD SERVER]', style: GoogleFonts.jetBrainsMono()),
              onTap: () {
                Navigator.pop(context);
                _navigateToAddServer(context);
              },
            ),
            ListTile(
              leading: Icon(Icons.code, color: primary),
              title: Text(
                '[CREATE SCRIPT]',
                style: GoogleFonts.jetBrainsMono(),
              ),
              onTap: () {
                Navigator.pop(context);
                _navigateToAddScript(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showQuickExecute(BuildContext context, Script script) {
    // Show dialog to select server and execute
    showDialog(
      context: context,
      builder: (context) => _QuickExecuteDialog(script: script),
    );
  }

  // Navigation methods
  void _navigateToServers(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ServersScreen()),
    );
  }

  void _navigateToScripts(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ScriptsScreen()),
    );
  }

  void _navigateToBackgroundJobs(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const BackgroundJobsScreen()),
    );
  }

  void _navigateToSettings(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SettingsScreen()),
    );
  }

  void _navigateToAddServer(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ServerForm()),
    );
  }

  void _navigateToEditServer(BuildContext context, Server server) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => ServerForm(server: server)),
    );
  }

  void _navigateToAddScript(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ScriptForm()),
    );
  }

  void _viewExecution(BuildContext context, Execution execution) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ExecutionScreen(executionId: execution.id!),
      ),
    );
  }
}

/// Server list tile for home screen
class _ServerListTile extends StatelessWidget {
  final Server server;
  final VoidCallback onTap;

  const _ServerListTile({required this.server, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.extension<CyberTermThemeExtension>();
    final primaryDim = colors?.primaryDim ?? CyberTermColors.primaryDim;
    final textColor = colors?.textColor ?? CyberTermColors.textColor;
    final textDim = colors?.textDim ?? CyberTermColors.textDim;
    final success = colors?.success ?? CyberTermColors.success;

    return ListTile(
      leading: Icon(
        server.authType == AuthType.password ? Icons.lock : Icons.vpn_key,
        color: primaryDim,
        size: 20,
      ),
      title: Text(
        server.name,
        style: GoogleFonts.jetBrainsMono(fontSize: 13, color: textColor),
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        '${server.username}@${server.hostname}:${server.port}',
        style: GoogleFonts.jetBrainsMono(fontSize: 10, color: textDim),
        overflow: TextOverflow.ellipsis,
      ),
      trailing: server.keyFingerprint != null
          ? Icon(Icons.verified, color: success, size: 16)
          : null,
      onTap: onTap,
    );
  }
}

/// Script list tile for home screen
class _ScriptListTile extends StatelessWidget {
  final Script script;
  final VoidCallback onTap;

  const _ScriptListTile({required this.script, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.extension<CyberTermThemeExtension>();
    final primaryDim = colors?.primaryDim ?? CyberTermColors.primaryDim;
    final textColor = colors?.textColor ?? CyberTermColors.textColor;
    final textDim = colors?.textDim ?? CyberTermColors.textDim;
    final textMuted = colors?.textMuted ?? CyberTermColors.textMuted;

    return ListTile(
      leading: Icon(
        script.isReusable ? Icons.code : Icons.terminal,
        color: primaryDim,
        size: 20,
      ),
      title: Text(
        script.name,
        style: GoogleFonts.jetBrainsMono(fontSize: 13, color: textColor),
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: script.category != null
          ? Text(
              '[${script.category}]',
              style: GoogleFonts.jetBrainsMono(fontSize: 10, color: textDim),
            )
          : null,
      trailing: script.variables.isNotEmpty
          ? Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.input, size: 14, color: textMuted),
                const SizedBox(width: 4),
                Text(
                  '${script.variables.length}',
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 10,
                    color: textMuted,
                  ),
                ),
              ],
            )
          : null,
      onTap: onTap,
    );
  }
}

/// Execution list tile for home screen
class _ExecutionListTile extends StatelessWidget {
  final Execution execution;
  final VoidCallback onTap;

  const _ExecutionListTile({required this.execution, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.extension<CyberTermThemeExtension>();
    final textColor = colors?.textColor ?? CyberTermColors.textColor;
    final textMuted = colors?.textMuted ?? CyberTermColors.textMuted;
    final primaryDim = colors?.primaryDim ?? CyberTermColors.primaryDim;

    final statusColor = _getStatusColor(execution.status, colors);

    return ListTile(
      leading: Container(
        width: 12,
        height: 12,
        decoration: BoxDecoration(color: statusColor, shape: BoxShape.circle),
      ),
      title: FutureBuilder<(Server?, Script?)>(
        future: _loadDetails(execution),
        builder: (context, snapshot) {
          final server = snapshot.data?.$1;
          final script = snapshot.data?.$2;
          return Text(
            '${script?.name ?? 'Unknown'} @ ${server?.name ?? 'Unknown'}',
            style: GoogleFonts.jetBrainsMono(fontSize: 12, color: textColor),
            overflow: TextOverflow.ellipsis,
          );
        },
      ),
      subtitle: Text(
        DateFormat('yyyy-MM-dd HH:mm').format(execution.startedAt),
        style: GoogleFonts.jetBrainsMono(fontSize: 10, color: textMuted),
      ),
      trailing: execution.mode == ExecutionMode.background
          ? Icon(Icons.terminal, size: 14, color: primaryDim)
          : null,
      onTap: onTap,
    );
  }

  Color _getStatusColor(
    ExecutionStatus status,
    CyberTermThemeExtension? colors,
  ) {
    switch (status) {
      case ExecutionStatus.pending:
        return colors?.warning ?? CyberTermColors.warning;
      case ExecutionStatus.running:
        return colors?.primary ?? CyberTermColors.primary;
      case ExecutionStatus.completed:
        return colors?.success ?? CyberTermColors.success;
      case ExecutionStatus.failed:
        return colors?.error ?? CyberTermColors.error;
      case ExecutionStatus.cancelled:
        return colors?.textMuted ?? CyberTermColors.textMuted;
    }
  }

  Future<(Server?, Script?)> _loadDetails(Execution execution) async {
    final server = await ServerRepository.getById(execution.serverId);
    final script = await ScriptRepository.getById(execution.scriptId);
    return (server, script);
  }
}

/// Quick execute dialog for running scripts from home screen
class _QuickExecuteDialog extends StatefulWidget {
  final Script script;

  const _QuickExecuteDialog({required this.script});

  @override
  State<_QuickExecuteDialog> createState() => _QuickExecuteDialogState();
}

class _QuickExecuteDialogState extends State<_QuickExecuteDialog> {
  List<Server> _servers = [];
  Server? _selectedServer;
  bool _isLoading = true;
  bool _isBackground = false;
  final Map<String, TextEditingController> _variableControllers = {};

  @override
  void initState() {
    super.initState();
    _loadServers();
    _initVariableControllers();
  }

  @override
  void dispose() {
    for (final controller in _variableControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _initVariableControllers() {
    for (final variable in widget.script.variables) {
      _variableControllers[variable.name] = TextEditingController(
        text: variable.defaultValue ?? '',
      );
    }
  }

  Future<void> _loadServers() async {
    final servers = await ServerRepository.getAll();
    setState(() {
      _servers = servers;
      _isLoading = false;
      if (widget.script.defaultServerId != null) {
        try {
          _selectedServer = servers.firstWhere(
            (s) => s.id == widget.script.defaultServerId,
          );
        } catch (_) {
          _selectedServer = servers.isNotEmpty ? servers.first : null;
        }
      } else if (servers.isNotEmpty) {
        _selectedServer = servers.first;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.extension<CyberTermThemeExtension>();
    final surface = colors?.surface ?? CyberTermColors.surface;
    final primary = colors?.primary ?? CyberTermColors.primary;
    final primaryDim = colors?.primaryDim ?? CyberTermColors.primaryDim;
    final textDim = colors?.textDim ?? CyberTermColors.textDim;
    final textMuted = colors?.textMuted ?? CyberTermColors.textMuted;
    final textColor = colors?.textColor ?? CyberTermColors.textColor;

    return AlertDialog(
      backgroundColor: surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      title: Text(
        '[EXECUTE: ${widget.script.name}]',
        style: GoogleFonts.jetBrainsMono(
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
      ),
      content: _isLoading
          ? Center(child: CircularProgressIndicator(color: primary))
          : _servers.isEmpty
          ? Text(
              'No servers available. Add a server first.',
              style: GoogleFonts.jetBrainsMono(color: textDim),
            )
          : SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Server selector
                  DropdownButtonFormField<Server>(
                    value: _selectedServer,
                    decoration: const InputDecoration(
                      labelText: 'Target Server',
                      prefixIcon: Icon(Icons.computer),
                    ),
                    items: _servers.map((server) {
                      return DropdownMenuItem(
                        value: server,
                        child: Text(
                          server.name,
                          style: GoogleFonts.jetBrainsMono(),
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedServer = value;
                      });
                    },
                    style: GoogleFonts.jetBrainsMono(),
                    dropdownColor: surface,
                  ),
                  const SizedBox(height: 16),

                  // Variable inputs
                  if (widget.script.variables.isNotEmpty) ...[
                    Text(
                      '[VARIABLES]',
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: primaryDim,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...widget.script.variables.map((variable) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: TextFormField(
                          controller: _variableControllers[variable.name],
                          decoration: InputDecoration(
                            labelText: '\${${variable.name}}',
                            helperText: variable.description,
                            helperStyle: GoogleFonts.jetBrainsMono(
                              fontSize: 10,
                              color: textMuted,
                            ),
                          ),
                          style: GoogleFonts.jetBrainsMono(),
                        ),
                      );
                    }),
                    const SizedBox(height: 16),
                  ],

                  // Background mode toggle
                  SwitchListTile(
                    title: Text(
                      'Background Mode',
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 12,
                        color: textColor,
                      ),
                    ),
                    subtitle: Text(
                      'Run in tmux/screen session',
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 10,
                        color: textDim,
                      ),
                    ),
                    value: _isBackground,
                    onChanged: (value) {
                      setState(() {
                        _isBackground = value;
                      });
                    },
                    activeColor: primary,
                    contentPadding: EdgeInsets.zero,
                  ),
                ],
              ),
            ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(
            '[CANCEL]',
            style: GoogleFonts.jetBrainsMono(color: textDim),
          ),
        ),
        FilledButton(
          onPressed: _selectedServer == null ? null : _execute,
          child: Text(
            '[EXECUTE]',
            style: GoogleFonts.jetBrainsMono(fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }

  Future<void> _execute() async {
    if (_selectedServer == null) return;

    // Collect variable values
    final variables = <String, String>{};
    for (final entry in _variableControllers.entries) {
      variables[entry.key] = entry.value.text;
    }

    // Create execution
    final execution = Execution(
      serverId: _selectedServer!.id!,
      scriptId: widget.script.id!,
      mode: _isBackground ? ExecutionMode.background : ExecutionMode.foreground,
      status: ExecutionStatus.pending,
      variablesUsed: variables,
    );

    final savedExecution = await ExecutionRepository.insert(execution);

    if (mounted) {
      Navigator.pop(context);

      // Navigate to execution screen
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) =>
              ExecutionScreen(executionId: savedExecution.id!),
        ),
      );
    }
  }
}
