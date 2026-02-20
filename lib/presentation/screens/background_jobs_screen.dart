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
import '../../data/models/server.dart';
import '../../data/models/script.dart';
import '../../data/repositories/server_repository.dart';
import '../../data/repositories/script_repository.dart';
import '../providers/executions_provider.dart';
import '../screens/execution_screen.dart';

/// Screen for managing background job executions
class BackgroundJobsScreen extends ConsumerStatefulWidget {
  const BackgroundJobsScreen({super.key});

  @override
  ConsumerState<BackgroundJobsScreen> createState() {
    return _BackgroundJobsScreenState();
  }
}

class _BackgroundJobsScreenState extends ConsumerState<BackgroundJobsScreen> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.extension<CyberTermThemeExtension>();
    final primary = colors?.primary ?? CyberTermColors.primary;
    final surface = colors?.surface ?? CyberTermColors.surface;

    final state = ref.watch(executionsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          '[BACKGROUND JOBS]',
          style: GoogleFonts.jetBrainsMono(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () =>
                ref.read(executionsProvider.notifier).refreshRunning(),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(executionsProvider.notifier).loadExecutions(),
        color: primary,
        backgroundColor: surface,
        child: _buildBody(context, state, colors),
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    ExecutionsState state,
    CyberTermThemeExtension? colors,
  ) {
    final primary = colors?.primary ?? CyberTermColors.primary;

    // Filter to background executions only
    final backgroundExecutions = state.runningExecutions
        .where((e) => e.mode == ExecutionMode.background)
        .toList();

    final completedBackground = state.executions
        .where(
          (e) =>
              e.mode == ExecutionMode.background &&
              (e.status == ExecutionStatus.completed ||
                  e.status == ExecutionStatus.failed),
        )
        .take(20)
        .toList();

    if (state.isLoading &&
        backgroundExecutions.isEmpty &&
        completedBackground.isEmpty) {
      return Center(child: CircularProgressIndicator(color: primary));
    }

    if (backgroundExecutions.isEmpty && completedBackground.isEmpty) {
      return _buildEmptyState(context, colors);
    }

    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        if (backgroundExecutions.isNotEmpty) ...[
          _buildSectionHeader('RUNNING JOBS', colors),
          const SizedBox(height: 8),
          ...backgroundExecutions.map(
            (execution) => _JobCard(
              execution: execution,
              onCheckStatus: () => _checkStatus(context, execution, colors),
              onKill: () => _confirmKill(context, execution, colors),
              onViewOutput: () => _viewExecution(context, execution),
              colors: colors,
            ),
          ),
          const SizedBox(height: 24),
        ],
        if (completedBackground.isNotEmpty) ...[
          _buildSectionHeader('RECENTLY COMPLETED', colors),
          const SizedBox(height: 8),
          ...completedBackground.map(
            (execution) => _JobCard(
              execution: execution,
              onViewOutput: () => _viewExecution(context, execution),
              colors: colors,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildEmptyState(
    BuildContext context,
    CyberTermThemeExtension? colors,
  ) {
    final primaryDim = colors?.primaryDim ?? CyberTermColors.primaryDim;
    final textDim = colors?.textDim ?? CyberTermColors.textDim;
    final textMuted = colors?.textMuted ?? CyberTermColors.textMuted;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.terminal, size: 64, color: primaryDim),
          const SizedBox(height: 16),
          Text(
            'No background jobs',
            style: GoogleFonts.jetBrainsMono(color: textDim, fontSize: 14),
          ),
          const SizedBox(height: 8),
          Text(
            'Run scripts in background mode\nto see them here',
            textAlign: TextAlign.center,
            style: GoogleFonts.jetBrainsMono(color: textMuted, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, CyberTermThemeExtension? colors) {
    final primary = colors?.primary ?? CyberTermColors.primary;

    return Row(
      children: [
        const TerminalLabel('SECTION'),
        const SizedBox(width: 8),
        Text(
          title,
          style: GoogleFonts.jetBrainsMono(
            color: primary,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Future<void> _checkStatus(
    BuildContext context,
    Execution execution,
    CyberTermThemeExtension? colors,
  ) async {
    final surface = colors?.surface ?? CyberTermColors.surface;
    final primary = colors?.primary ?? CyberTermColors.primary;
    final textDim = colors?.textDim ?? CyberTermColors.textDim;
    final success = colors?.success ?? CyberTermColors.success;
    final error = colors?.error ?? CyberTermColors.error;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: surface,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: primary),
            const SizedBox(height: 16),
            Text(
              '[CHECKING STATUS]',
              style: GoogleFonts.jetBrainsMono(color: textDim, fontSize: 12),
            ),
          ],
        ),
      ),
    );

    try {
      // Get server and check tmux/screen session
      final server = await ServerRepository.getById(execution.serverId);
      if (server == null) {
        throw Exception('Server not found');
      }

      // TODO: Implement actual tmux/screen session check via SSH
      // For now, just reload execution from database
      await ref.read(executionsProvider.notifier).loadExecutions();

      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '[STATUS CHECKED]',
              style: GoogleFonts.jetBrainsMono(color: success),
            ),
            backgroundColor: surface,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error: $e',
              style: GoogleFonts.jetBrainsMono(color: error),
            ),
            backgroundColor: surface,
          ),
        );
      }
    }
  }

  Future<void> _confirmKill(
    BuildContext context,
    Execution execution,
    CyberTermThemeExtension? colors,
  ) async {
    final surface = colors?.surface ?? CyberTermColors.surface;
    final warning = colors?.warning ?? CyberTermColors.warning;
    final textDim = colors?.textDim ?? CyberTermColors.textDim;
    final error = colors?.error ?? CyberTermColors.error;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: surface,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        title: Row(
          children: [
            Icon(Icons.warning, color: warning, size: 20),
            const SizedBox(width: 8),
            Text(
              '[KILL SESSION]',
              style: GoogleFonts.jetBrainsMono(
                color: warning,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: Text(
          'Force kill background session?\n\nSession: ${execution.tmuxSessionName ?? execution.id}\n\nThis will terminate the running process immediately.',
          style: GoogleFonts.jetBrainsMono(color: textDim, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              '[CANCEL]',
              style: GoogleFonts.jetBrainsMono(color: textDim),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              '[KILL]',
              style: GoogleFonts.jetBrainsMono(color: error),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        // TODO: Implement actual kill via SSH
        await ref
            .read(executionsProvider.notifier)
            .updateStatus(execution.id!, ExecutionStatus.cancelled);

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '[SESSION KILLED]',
                style: GoogleFonts.jetBrainsMono(color: error),
              ),
              backgroundColor: surface,
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Error: $e',
                style: GoogleFonts.jetBrainsMono(color: error),
              ),
              backgroundColor: surface,
            ),
          );
        }
      }
    }
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

/// Card widget for background job
class _JobCard extends StatelessWidget {
  final Execution execution;
  final VoidCallback? onCheckStatus;
  final VoidCallback? onKill;
  final VoidCallback? onViewOutput;
  final CyberTermThemeExtension? colors;

  const _JobCard({
    required this.execution,
    this.onCheckStatus,
    this.onKill,
    this.onViewOutput,
    this.colors,
  });

  @override
  Widget build(BuildContext context) {
    final textColor = colors?.textColor ?? CyberTermColors.textColor;
    final textMuted = colors?.textMuted ?? CyberTermColors.textMuted;
    final textDim = colors?.textDim ?? CyberTermColors.textDim;
    final error = colors?.error ?? CyberTermColors.error;
    final warning = colors?.warning ?? CyberTermColors.warning;

    final isRunning = execution.isRunning;
    final statusColor = _getStatusColor(execution.status);
    final duration = DateTime.now().difference(execution.startedAt);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isRunning ? Icons.play_circle : Icons.terminal,
                  size: 16,
                  color: statusColor,
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withAlpha(51), // 0.2 * 255 ≈ 51
                    border: Border.all(color: statusColor),
                  ),
                  child: Text(
                    execution.status.name.toUpperCase(),
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 9,
                      color: statusColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const Spacer(),
                if (execution.tmuxSessionName != null)
                  Text(
                    '[${execution.tmuxSessionName}]',
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 10,
                      color: textMuted,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            // Server and script info - will be fetched async
            FutureBuilder<(Execution, Server?, Script?)>(
              future: _loadDetails(execution),
              builder: (context, snapshot) {
                final server = snapshot.data?.$2;
                final script = snapshot.data?.$3;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const TerminalLabel('SERVER'),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            server?.name ?? 'Loading...',
                            style: GoogleFonts.jetBrainsMono(
                              fontSize: 12,
                              color: textColor,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const TerminalLabel('SCRIPT'),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            script?.name ?? 'Loading...',
                            style: GoogleFonts.jetBrainsMono(
                              fontSize: 12,
                              color: textColor,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const TerminalLabel('STARTED'),
                const SizedBox(width: 8),
                Text(
                  DateFormat('yyyy-MM-dd HH:mm').format(execution.startedAt),
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 10,
                    color: textDim,
                  ),
                ),
              ],
            ),
            if (isRunning) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  const TerminalLabel('RUNNING'),
                  const SizedBox(width: 8),
                  Text(
                    _formatRunningTime(duration),
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 10,
                      color: warning,
                    ),
                  ),
                  const SizedBox(width: 8),
                  BlinkingCursor(color: warning, fontSize: 10),
                ],
              ),
            ] else if (execution.duration != null) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  const TerminalLabel('DURATION'),
                  const SizedBox(width: 8),
                  Text(
                    _formatDuration(execution.duration!),
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 10,
                      color: textDim,
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 12),
            // Action buttons
            if (isRunning) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (onCheckStatus != null)
                    TextButton.icon(
                      onPressed: onCheckStatus,
                      icon: const Icon(Icons.refresh, size: 16),
                      label: Text(
                        '[CHECK STATUS]',
                        style: GoogleFonts.jetBrainsMono(fontSize: 11),
                      ),
                    ),
                  if (onKill != null) ...[
                    const SizedBox(width: 8),
                    TextButton.icon(
                      onPressed: onKill,
                      icon: Icon(Icons.stop, size: 16, color: error),
                      label: Text(
                        '[KILL]',
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: 11,
                          color: error,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ] else if (onViewOutput != null) ...[
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: onViewOutput,
                  icon: const Icon(Icons.output, size: 16),
                  label: Text(
                    '[VIEW OUTPUT]',
                    style: GoogleFonts.jetBrainsMono(fontSize: 11),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<(Execution, Server?, Script?)> _loadDetails(
    Execution execution,
  ) async {
    final server = await ServerRepository.getById(execution.serverId);
    final script = await ScriptRepository.getById(execution.scriptId);
    return (execution, server, script);
  }

  Color _getStatusColor(ExecutionStatus status) {
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

  String _formatRunningTime(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    final seconds = duration.inSeconds % 60;

    if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else if (minutes > 0) {
      return '${minutes}m ${seconds}s';
    } else {
      return '${seconds}s';
    }
  }

  String _formatDuration(Duration duration) {
    if (duration.inMinutes > 0) {
      return '${duration.inMinutes}m ${duration.inSeconds % 60}s';
    } else {
      return '${duration.inSeconds}s';
    }
  }
}
