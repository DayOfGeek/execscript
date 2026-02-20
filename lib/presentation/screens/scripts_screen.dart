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
import '../../core/theme.dart';
import '../../data/models/script.dart';
import '../providers/scripts_provider.dart';
import '../forms/script_form.dart';

/// Screen for managing scripts
class ScriptsScreen extends ConsumerStatefulWidget {
  const ScriptsScreen({super.key});

  @override
  ConsumerState<ScriptsScreen> createState() => _ScriptsScreenState();
}

class _ScriptsScreenState extends ConsumerState<ScriptsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.extension<CyberTermThemeExtension>();
    final primary = colors?.primary ?? CyberTermColors.primary;
    final textMuted = colors?.textMuted ?? CyberTermColors.textMuted;
    final border = colors?.border ?? CyberTermColors.border;

    final state = ref.watch(scriptsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          '[SCRIPTS]',
          style: GoogleFonts.jetBrainsMono(fontWeight: FontWeight.bold),
        ),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(
              child: Text(
                '[REUSABLE]',
                style: GoogleFonts.jetBrainsMono(fontSize: 11),
              ),
            ),
            Tab(
              child: Text(
                '[SERVER-SPECIFIC]',
                style: GoogleFonts.jetBrainsMono(fontSize: 11),
              ),
            ),
          ],
          labelColor: primary,
          unselectedLabelColor: textMuted,
          indicatorColor: primary,
          dividerColor: border,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.read(scriptsProvider.notifier).loadScripts(),
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildScriptList(
            context,
            state.reusableScripts,
            isReusable: true,
            colors: colors,
          ),
          _buildScriptList(
            context,
            state.serverSpecificScripts,
            isReusable: false,
            colors: colors,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navigateToForm(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildScriptList(
    BuildContext context,
    List<Script> scripts, {
    required bool isReusable,
    CyberTermThemeExtension? colors,
  }) {
    final state = ref.watch(scriptsProvider);
    final primary = colors?.primary ?? CyberTermColors.primary;

    if (state.isLoading && scripts.isEmpty) {
      return Center(child: CircularProgressIndicator(color: primary));
    }

    if (scripts.isEmpty) {
      return _buildEmptyState(context, isReusable: isReusable, colors: colors);
    }

    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: scripts.length,
      itemBuilder: (context, index) {
        final script = scripts[index];
        return _ScriptCard(
          script: script,
          onEdit: () => _navigateToForm(context, script: script),
          onDelete: () => _confirmDelete(context, script, colors),
          onLongPress: () => _confirmDelete(context, script, colors),
          colors: colors,
        );
      },
    );
  }

  Widget _buildEmptyState(
    BuildContext context, {
    required bool isReusable,
    CyberTermThemeExtension? colors,
  }) {
    final primaryDim = colors?.primaryDim ?? CyberTermColors.primaryDim;
    final textDim = colors?.textDim ?? CyberTermColors.textDim;
    final primary = colors?.primary ?? CyberTermColors.primary;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isReusable ? Icons.code : Icons.terminal,
            size: 64,
            color: primaryDim,
          ),
          const SizedBox(height: 16),
          Text(
            isReusable ? 'No reusable scripts' : 'No server-specific scripts',
            style: GoogleFonts.jetBrainsMono(color: textDim, fontSize: 14),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => _navigateToForm(context, isReusable: isReusable),
            child: Text(
              isReusable
                  ? '[CREATE REUSABLE SCRIPT]'
                  : '[CREATE SERVER SCRIPT]',
              style: GoogleFonts.jetBrainsMono(
                color: primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToForm(
    BuildContext context, {
    Script? script,
    bool? isReusable,
  }) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            ScriptForm(script: script, initialIsReusable: isReusable),
      ),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    Script script,
    CyberTermThemeExtension? colors,
  ) async {
    final surface = colors?.surface ?? CyberTermColors.surface;
    final error = colors?.error ?? CyberTermColors.error;
    final textDim = colors?.textDim ?? CyberTermColors.textDim;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: surface,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        title: Text(
          '[DELETE SCRIPT]',
          style: GoogleFonts.jetBrainsMono(
            color: error,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          'Are you sure you want to delete "${script.name}"?\n\nThis action cannot be undone.',
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
              '[DELETE]',
              style: GoogleFonts.jetBrainsMono(color: error),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await ref.read(scriptsProvider.notifier).deleteScript(script.id!);
        if (mounted) {
          final surfaceLocal = colors?.surface ?? CyberTermColors.surface;
          final textColorLocal = colors?.textColor ?? CyberTermColors.textColor;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '[DELETED] ${script.name}',
                style: GoogleFonts.jetBrainsMono(color: textColorLocal),
              ),
              backgroundColor: surfaceLocal,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          final surfaceLocal = colors?.surface ?? CyberTermColors.surface;
          final errorLocal = colors?.error ?? CyberTermColors.error;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Error: $e',
                style: GoogleFonts.jetBrainsMono(color: errorLocal),
              ),
              backgroundColor: surfaceLocal,
            ),
          );
        }
      }
    }
  }
}

/// Card widget for displaying script info
class _ScriptCard extends StatelessWidget {
  final Script script;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onLongPress;
  final CyberTermThemeExtension? colors;

  const _ScriptCard({
    required this.script,
    required this.onEdit,
    required this.onDelete,
    required this.onLongPress,
    this.colors,
  });

  @override
  Widget build(BuildContext context) {
    final background = colors?.background ?? CyberTermColors.background;
    final primaryDim = colors?.primaryDim ?? CyberTermColors.primaryDim;
    final textColor = colors?.textColor ?? CyberTermColors.textColor;
    final textDim = colors?.textDim ?? CyberTermColors.textDim;
    final textMuted = colors?.textMuted ?? CyberTermColors.textMuted;
    final border = colors?.border ?? CyberTermColors.border;
    final error = colors?.error ?? CyberTermColors.error;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
      child: InkWell(
        onTap: onEdit,
        onLongPress: onLongPress,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    script.isReusable ? Icons.code : Icons.terminal,
                    size: 16,
                    color: primaryDim,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      script.name,
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (script.variables.isNotEmpty)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.input, size: 12, color: textMuted),
                        const SizedBox(width: 4),
                        Text(
                          '${script.variables.length}',
                          style: GoogleFonts.jetBrainsMono(
                            fontSize: 11,
                            color: textMuted,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
              const SizedBox(height: 8),
              if (script.category != null && script.category!.isNotEmpty)
                Row(
                  children: [
                    const TerminalLabel('CATEGORY'),
                    const SizedBox(width: 8),
                    Text(
                      script.category!,
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 11,
                        color: textDim,
                      ),
                    ),
                  ],
                ),
              const SizedBox(height: 8),
              // Preview of script content
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: background,
                  border: Border.all(color: border),
                ),
                child: Text(
                  script.content.length > 60
                      ? '${script.content.substring(0, 60)}...'
                      : script.content,
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 10,
                    color: textMuted,
                    height: 1.3,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    onPressed: onEdit,
                    icon: const Icon(Icons.edit, size: 16),
                    label: Text(
                      '[EDIT]',
                      style: GoogleFonts.jetBrainsMono(fontSize: 11),
                    ),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: onDelete,
                    icon: Icon(Icons.delete, size: 16, color: error),
                    label: Text(
                      '[DELETE]',
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 11,
                        color: error,
                      ),
                    ),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
