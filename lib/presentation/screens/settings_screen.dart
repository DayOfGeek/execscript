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
import '../providers/theme_provider.dart';

/// Settings screen with theme switching and data management
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentTheme = ref.watch(themeProvider);
    final themeExt = Theme.of(context).extension<CyberTermThemeExtension>();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          '[SETTINGS]',
          style: GoogleFonts.jetBrainsMono(fontWeight: FontWeight.bold),
        ),
      ),
      body: ListView(
        children: [
          // Header Section
          _buildHeader(context, themeExt),

          const Divider(height: 1),

          // Theme Section
          _buildThemeSection(context, ref, currentTheme, themeExt),

          const Divider(height: 1),

          // Data Management Section
          _buildDataManagementSection(context, themeExt),

          const Divider(height: 1),

          // About Section
          _buildAboutSection(context, themeExt),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, CyberTermThemeExtension? themeExt) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Text(
            'EXECSCRIPT',
            style: GoogleFonts.jetBrainsMono(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: themeExt?.primary ?? CyberTermColors.primary,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              border: Border.all(
                color: themeExt?.primaryDim ?? CyberTermColors.primaryDim,
                width: 1,
              ),
            ),
            child: Text(
              'v1.0.0',
              style: GoogleFonts.jetBrainsMono(
                fontSize: 10,
                color: themeExt?.textDim ?? CyberTermColors.textDim,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildThemeSection(
    BuildContext context,
    WidgetRef ref,
    AppTheme currentTheme,
    CyberTermThemeExtension? themeExt,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          color: themeExt?.surface ?? CyberTermColors.surface,
          child: Row(
            children: [
              const TerminalLabel('THEME'),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Appearance',
                  style: GoogleFonts.jetBrainsMono(
                    color: themeExt?.primary ?? CyberTermColors.primary,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),

        // Current Theme Display
        Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Text(
                'Current: ',
                style: GoogleFonts.jetBrainsMono(
                  color: themeExt?.textDim ?? CyberTermColors.textDim,
                  fontSize: 12,
                ),
              ),
              Text(
                currentTheme.displayName,
                style: GoogleFonts.jetBrainsMono(
                  color: themeExt?.primary ?? CyberTermColors.primary,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),

        // Theme Options
        ...AppTheme.values.map(
          (theme) => _ThemeOption(
            theme: theme,
            isSelected: theme == currentTheme,
            onTap: () => _setTheme(ref, theme),
          ),
        ),
      ],
    );
  }

  void _setTheme(WidgetRef ref, AppTheme theme) {
    ref.read(themeProvider.notifier).setTheme(theme);
  }

  Widget _buildDataManagementSection(
    BuildContext context,
    CyberTermThemeExtension? themeExt,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          color: themeExt?.surface ?? CyberTermColors.surface,
          child: Row(
            children: [
              const TerminalLabel('DATA MANAGEMENT'),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Backup & Restore',
                  style: GoogleFonts.jetBrainsMono(
                    color: themeExt?.primary ?? CyberTermColors.primary,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 8),

        // Export Button
        _DataButton(
          icon: Icons.upload_file,
          label: '[EXPORT DATA]',
          description: 'Save all servers and scripts to file',
          onTap: () => _showExportDialog(context),
        ),

        const SizedBox(height: 4),

        // Import Button
        _DataButton(
          icon: Icons.download,
          label: '[IMPORT DATA]',
          description: 'Load from JSON backup file',
          onTap: () => _showImportDialog(context),
        ),

        const SizedBox(height: 4),

        // Clear All Button (Destructive)
        _DataButton(
          icon: Icons.delete_forever,
          label: '[CLEAR ALL DATA]',
          description: 'Delete all servers, scripts, and history',
          isDestructive: true,
          onTap: () => _showClearConfirmationDialog(context),
        ),

        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildAboutSection(
    BuildContext context,
    CyberTermThemeExtension? themeExt,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          color: themeExt?.surface ?? CyberTermColors.surface,
          child: Row(
            children: [
              const TerminalLabel('ABOUT'),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Information',
                  style: GoogleFonts.jetBrainsMono(
                    color: themeExt?.primary ?? CyberTermColors.primary,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),

        // About Content
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'EXECSCRIPT v1.0.0',
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: themeExt?.primary ?? CyberTermColors.primary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '© 2026 DayOfGeek.com',
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 11,
                  color: themeExt?.textDim ?? CyberTermColors.textDim,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'The spiritual successor to Script Kitty.\nExecute scripts remotely on Linux servers.',
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 12,
                  color: themeExt?.textColor ?? CyberTermColors.textColor,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 20),

              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _openDocumentation(context),
                      icon: const Icon(Icons.description, size: 16),
                      label: Text(
                        '[VIEW DOCUMENTATION]',
                        style: GoogleFonts.jetBrainsMono(fontSize: 10),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _reportIssue(context),
                      icon: const Icon(Icons.bug_report, size: 16),
                      label: Text(
                        '[REPORT ISSUE]',
                        style: GoogleFonts.jetBrainsMono(fontSize: 10),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showExportDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor:
            Theme.of(context).extension<CyberTermThemeExtension>()?.surface ??
            CyberTermColors.surface,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        title: Text(
          '[EXPORT DATA]',
          style: GoogleFonts.jetBrainsMono(
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
        content: Text(
          'Export functionality will be available in a future update.\n\nThis will save all servers, scripts, and execution history to a JSON file.',
          style: GoogleFonts.jetBrainsMono(
            color:
                Theme.of(
                  context,
                ).extension<CyberTermThemeExtension>()?.textDim ??
                CyberTermColors.textDim,
            fontSize: 12,
            height: 1.5,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              '[OK]',
              style: GoogleFonts.jetBrainsMono(
                color:
                    Theme.of(
                      context,
                    ).extension<CyberTermThemeExtension>()?.primary ??
                    CyberTermColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showImportDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor:
            Theme.of(context).extension<CyberTermThemeExtension>()?.surface ??
            CyberTermColors.surface,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        title: Text(
          '[IMPORT DATA]',
          style: GoogleFonts.jetBrainsMono(
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
        content: Text(
          'Import functionality will be available in a future update.\n\nThis will load servers and scripts from a JSON backup file.',
          style: GoogleFonts.jetBrainsMono(
            color:
                Theme.of(
                  context,
                ).extension<CyberTermThemeExtension>()?.textDim ??
                CyberTermColors.textDim,
            fontSize: 12,
            height: 1.5,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              '[OK]',
              style: GoogleFonts.jetBrainsMono(
                color:
                    Theme.of(
                      context,
                    ).extension<CyberTermThemeExtension>()?.primary ??
                    CyberTermColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showClearConfirmationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor:
            Theme.of(context).extension<CyberTermThemeExtension>()?.surface ??
            CyberTermColors.surface,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        title: Row(
          children: [
            Icon(
              Icons.warning,
              color:
                  Theme.of(
                    context,
                  ).extension<CyberTermThemeExtension>()?.error ??
                  CyberTermColors.error,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              '[CLEAR ALL DATA]',
              style: GoogleFonts.jetBrainsMono(
                color:
                    Theme.of(
                      context,
                    ).extension<CyberTermThemeExtension>()?.error ??
                    CyberTermColors.error,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'This action cannot be undone!',
              style: GoogleFonts.jetBrainsMono(
                color:
                    Theme.of(
                      context,
                    ).extension<CyberTermThemeExtension>()?.textColor ??
                    CyberTermColors.textColor,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'The following will be permanently deleted:',
              style: GoogleFonts.jetBrainsMono(
                color:
                    Theme.of(
                      context,
                    ).extension<CyberTermThemeExtension>()?.textDim ??
                    CyberTermColors.textDim,
                fontSize: 11,
              ),
            ),
            const SizedBox(height: 8),
            _buildBulletPoint(context, 'All configured servers'),
            _buildBulletPoint(context, 'All saved scripts'),
            _buildBulletPoint(context, 'All execution history'),
            _buildBulletPoint(context, 'All cached credentials'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              '[CANCEL]',
              style: GoogleFonts.jetBrainsMono(
                color:
                    Theme.of(
                      context,
                    ).extension<CyberTermThemeExtension>()?.textDim ??
                    CyberTermColors.textDim,
              ),
            ),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              _performClearData(context);
            },
            style: FilledButton.styleFrom(
              backgroundColor:
                  Theme.of(
                    context,
                  ).extension<CyberTermThemeExtension>()?.error ??
                  CyberTermColors.error,
            ),
            child: Text(
              '[CLEAR ALL]',
              style: GoogleFonts.jetBrainsMono(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBulletPoint(BuildContext context, String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, top: 4),
      child: Row(
        children: [
          Text(
            '• ',
            style: GoogleFonts.jetBrainsMono(
              color:
                  Theme.of(
                    context,
                  ).extension<CyberTermThemeExtension>()?.textDim ??
                  CyberTermColors.textDim,
              fontSize: 11,
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.jetBrainsMono(
                color:
                    Theme.of(
                      context,
                    ).extension<CyberTermThemeExtension>()?.textDim ??
                    CyberTermColors.textDim,
                fontSize: 11,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _performClearData(BuildContext context) {
    // TODO: Implement actual data clearing
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '[TODO] Clear data functionality coming soon',
          style: GoogleFonts.jetBrainsMono(
            color:
                Theme.of(
                  context,
                ).extension<CyberTermThemeExtension>()?.textColor ??
                CyberTermColors.textColor,
          ),
        ),
        backgroundColor:
            Theme.of(context).extension<CyberTermThemeExtension>()?.surface ??
            CyberTermColors.surface,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _openDocumentation(BuildContext context) {
    // TODO: Open documentation URL
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '[TODO] Documentation link coming soon',
          style: GoogleFonts.jetBrainsMono(
            color:
                Theme.of(
                  context,
                ).extension<CyberTermThemeExtension>()?.textColor ??
                CyberTermColors.textColor,
          ),
        ),
        backgroundColor:
            Theme.of(context).extension<CyberTermThemeExtension>()?.surface ??
            CyberTermColors.surface,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _reportIssue(BuildContext context) {
    // TODO: Open issue reporter URL
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '[TODO] Issue reporter link coming soon',
          style: GoogleFonts.jetBrainsMono(
            color:
                Theme.of(
                  context,
                ).extension<CyberTermThemeExtension>()?.textColor ??
                CyberTermColors.textColor,
          ),
        ),
        backgroundColor:
            Theme.of(context).extension<CyberTermThemeExtension>()?.surface ??
            CyberTermColors.surface,
        duration: const Duration(seconds: 2),
      ),
    );
  }
}

/// Theme option widget with radio-style selection
class _ThemeOption extends StatelessWidget {
  final AppTheme theme;
  final bool isSelected;
  final VoidCallback onTap;

  const _ThemeOption({
    required this.theme,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final themeExt = Theme.of(context).extension<CyberTermThemeExtension>();
    final themeColors = ThemeColors.colors[theme]!;

    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? themeExt?.surfaceLight ?? CyberTermColors.surfaceLight
              : null,
          border: Border(
            left: BorderSide(
              color: isSelected
                  ? themeExt?.primary ?? CyberTermColors.primary
                  : Colors.transparent,
              width: 3,
            ),
          ),
        ),
        child: Row(
          children: [
            // Radio indicator
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                border: Border.all(
                  color: themeExt?.textDim ?? CyberTermColors.textDim,
                  width: 1,
                ),
              ),
              child: isSelected
                  ? Center(
                      child: Container(
                        width: 12,
                        height: 12,
                        color: themeExt?.primary ?? CyberTermColors.primary,
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 12),

            // Theme color preview
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: themeColors['primary'],
                border: Border.all(color: themeColors['border']!, width: 1),
              ),
            ),
            const SizedBox(width: 12),

            // Theme name and description
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    theme.displayName,
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 13,
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.normal,
                      color: isSelected
                          ? themeExt?.primary ?? CyberTermColors.primary
                          : themeExt?.textColor ?? CyberTermColors.textColor,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    theme.description,
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 10,
                      color: themeExt?.textMuted ?? CyberTermColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),

            // Checkmark for selected
            if (isSelected)
              Icon(
                Icons.check,
                size: 16,
                color: themeExt?.primary ?? CyberTermColors.primary,
              ),
          ],
        ),
      ),
    );
  }
}

/// Data management button widget
class _DataButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final String description;
  final bool isDestructive;
  final VoidCallback onTap;

  const _DataButton({
    required this.icon,
    required this.label,
    required this.description,
    this.isDestructive = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final themeExt = Theme.of(context).extension<CyberTermThemeExtension>();

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Icon(
              icon,
              size: 20,
              color: isDestructive
                  ? themeExt?.error ?? CyberTermColors.error
                  : themeExt?.primaryDim ?? CyberTermColors.primaryDim,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: isDestructive
                          ? themeExt?.error ?? CyberTermColors.error
                          : themeExt?.primary ?? CyberTermColors.primary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    description,
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 10,
                      color: themeExt?.textMuted ?? CyberTermColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              size: 16,
              color: themeExt?.textMuted ?? CyberTermColors.textMuted,
            ),
          ],
        ),
      ),
    );
  }
}
