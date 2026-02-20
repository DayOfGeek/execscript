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
import '../../data/models/server.dart';
import '../../services/ssh_service.dart';
import '../providers/servers_provider.dart';
import '../forms/server_form.dart';
import '../widgets/host_key_dialog.dart';

/// Screen for managing servers
class ServersScreen extends ConsumerWidget {
  const ServersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colors = theme.extension<CyberTermThemeExtension>();
    final surface = colors?.surface ?? CyberTermColors.surface;
    final primary = colors?.primary ?? CyberTermColors.primary;

    final state = ref.watch(serversProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          '[SERVERS]',
          style: GoogleFonts.jetBrainsMono(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.read(serversProvider.notifier).loadServers(),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(serversProvider.notifier).loadServers(),
        color: primary,
        backgroundColor: surface,
        child: _buildBody(context, ref, state, colors),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navigateToForm(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    WidgetRef ref,
    ServersState state,
    CyberTermThemeExtension? colors,
  ) {
    final primary = colors?.primary ?? CyberTermColors.primary;
    final error = colors?.error ?? CyberTermColors.error;

    if (state.isLoading && state.servers.isEmpty) {
      return Center(child: CircularProgressIndicator(color: primary));
    }

    if (state.error != null && state.servers.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error, size: 48, color: error),
            const SizedBox(height: 16),
            Text(
              state.error!,
              style: GoogleFonts.jetBrainsMono(color: error, fontSize: 13),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => ref.read(serversProvider.notifier).loadServers(),
              child: Text(
                '[RETRY]',
                style: GoogleFonts.jetBrainsMono(color: primary),
              ),
            ),
          ],
        ),
      );
    }

    if (state.servers.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.6,
            child: _buildEmptyState(context, colors),
          ),
        ],
      );
    }

    return ListView.builder(
      itemCount: state.servers.length,
      itemBuilder: (context, index) {
        final server = state.servers[index];
        return _ServerCard(
          server: server,
          onEdit: () => _navigateToForm(context, server: server),
          onDelete: () => _confirmDelete(context, ref, server, colors),
          onTest: () => _testConnection(context, ref, server, colors),
          colors: colors,
        );
      },
    );
  }

  Widget _buildEmptyState(
    BuildContext context,
    CyberTermThemeExtension? colors,
  ) {
    final primaryDim = colors?.primaryDim ?? CyberTermColors.primaryDim;
    final textDim = colors?.textDim ?? CyberTermColors.textDim;
    final primary = colors?.primary ?? CyberTermColors.primary;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.computer, size: 64, color: primaryDim),
          const SizedBox(height: 16),
          Text(
            'No servers configured',
            style: GoogleFonts.jetBrainsMono(color: textDim, fontSize: 14),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => _navigateToForm(context),
            child: Text(
              '[ADD YOUR FIRST SERVER]',
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

  void _navigateToForm(BuildContext context, {Server? server}) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => ServerForm(server: server)),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    Server server,
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
          '[DELETE SERVER]',
          style: GoogleFonts.jetBrainsMono(
            color: error,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          'Are you sure you want to delete "${server.name}"?\n\nThis action cannot be undone.',
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
        await ref.read(serversProvider.notifier).deleteServer(server.id!);
        if (context.mounted) {
          final surfaceLocal = colors?.surface ?? CyberTermColors.surface;
          final textColorLocal = colors?.textColor ?? CyberTermColors.textColor;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '[DELETED] ${server.name}',
                style: GoogleFonts.jetBrainsMono(color: textColorLocal),
              ),
              backgroundColor: surfaceLocal,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
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

  Future<void> _testConnection(
    BuildContext context,
    WidgetRef ref,
    Server server,
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
              '[TESTING CONNECTION]\n${server.hostname}:${server.port}',
              textAlign: TextAlign.center,
              style: GoogleFonts.jetBrainsMono(color: textDim, fontSize: 12),
            ),
          ],
        ),
      ),
    );

    try {
      final (successResult, fingerprint, isNewKey, errorMessage) =
          await SSHService.testConnectionWithFingerprint(server);

      if (context.mounted) {
        Navigator.pop(context); // Close loading dialog

        if (successResult) {
          // Update last connected
          await ref
              .read(serversProvider.notifier)
              .updateLastConnected(server.id!);

          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              backgroundColor: surface,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.zero,
              ),
              title: Row(
                children: [
                  Icon(Icons.check_circle, color: success, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    '[CONNECTION OK]',
                    style: GoogleFonts.jetBrainsMono(
                      color: success,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              content: Text(
                'Successfully connected to ${server.name}\n\nFingerprint: ${fingerprint ?? "N/A"}',
                style: GoogleFonts.jetBrainsMono(color: textDim, fontSize: 12),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    '[OK]',
                    style: GoogleFonts.jetBrainsMono(color: primary),
                  ),
                ),
              ],
            ),
          );
        } else {
          // Check for host key issues
          if (isNewKey && fingerprint != null) {
            final trustResult = await showDialog<HostKeyTrust>(
              context: context,
              builder: (context) => HostKeyDialog(
                fingerprint: fingerprint,
                serverName: server.name,
                isNewKey: true,
              ),
            );

            if (trustResult == HostKeyTrust.always) {
              // Update server with new fingerprint
              final updatedServer = server.copyWith(
                keyFingerprint: fingerprint,
              );
              await ref
                  .read(serversProvider.notifier)
                  .updateServer(updatedServer);

              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      '[TRUSTED] Host key saved',
                      style: GoogleFonts.jetBrainsMono(color: success),
                    ),
                    backgroundColor: surface,
                  ),
                );
              }
            }
          } else if (!isNewKey && fingerprint != null) {
            // Changed key
            showDialog(
              context: context,
              builder: (context) => HostKeyDialog(
                fingerprint: fingerprint,
                serverName: server.name,
                isNewKey: false,
                expectedFingerprint: server.keyFingerprint,
              ),
            );
          } else {
            // General error
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                backgroundColor: surface,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.zero,
                ),
                title: Row(
                  children: [
                    Icon(Icons.error, color: error, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      '[CONNECTION FAILED]',
                      style: GoogleFonts.jetBrainsMono(
                        color: error,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                content: Text(
                  errorMessage ?? 'Unknown error',
                  style: GoogleFonts.jetBrainsMono(
                    color: textDim,
                    fontSize: 12,
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      '[OK]',
                      style: GoogleFonts.jetBrainsMono(color: primary),
                    ),
                  ),
                ],
              ),
            );
          }
        }
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context); // Close loading dialog
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: surface,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.zero,
            ),
            title: Text(
              '[ERROR]',
              style: GoogleFonts.jetBrainsMono(
                color: error,
                fontWeight: FontWeight.bold,
              ),
            ),
            content: Text(
              e.toString(),
              style: GoogleFonts.jetBrainsMono(color: textDim, fontSize: 12),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  '[OK]',
                  style: GoogleFonts.jetBrainsMono(color: primary),
                ),
              ),
            ],
          ),
        );
      }
    }
  }
}

/// Card widget for displaying server info
class _ServerCard extends StatelessWidget {
  final Server server;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onTest;
  final CyberTermThemeExtension? colors;

  const _ServerCard({
    required this.server,
    required this.onEdit,
    required this.onDelete,
    required this.onTest,
    this.colors,
  });

  @override
  Widget build(BuildContext context) {
    final primaryDim = colors?.primaryDim ?? CyberTermColors.primaryDim;
    final textColor = colors?.textColor ?? CyberTermColors.textColor;
    final textDim = colors?.textDim ?? CyberTermColors.textDim;
    final textMuted = colors?.textMuted ?? CyberTermColors.textMuted;
    final success = colors?.success ?? CyberTermColors.success;
    final error = colors?.error ?? CyberTermColors.error;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: InkWell(
        onTap: onEdit,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    server.authType == AuthType.password
                        ? Icons.lock
                        : Icons.vpn_key,
                    size: 16,
                    color: primaryDim,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      server.name,
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (server.keyFingerprint != null)
                    Icon(Icons.verified, size: 14, color: success),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const TerminalLabel('HOST'),
                  const SizedBox(width: 8),
                  Text(
                    '${server.username}@${server.hostname}:${server.port}',
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 11,
                      color: textDim,
                    ),
                  ),
                ],
              ),
              if (server.tags.isNotEmpty) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 4,
                  children: server.tags.map((tag) {
                    return Chip(
                      label: Text(
                        tag,
                        style: GoogleFonts.jetBrainsMono(fontSize: 9),
                      ),
                      padding: EdgeInsets.zero,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    );
                  }).toList(),
                ),
              ],
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (server.lastConnected != null)
                    Row(
                      children: [
                        const TerminalLabel('LAST'),
                        const SizedBox(width: 8),
                        Text(
                          DateFormat(
                            'yyyy-MM-dd HH:mm',
                          ).format(server.lastConnected!),
                          style: GoogleFonts.jetBrainsMono(
                            fontSize: 10,
                            color: textMuted,
                          ),
                        ),
                      ],
                    )
                  else
                    Text(
                      'Never connected',
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 10,
                        color: textMuted,
                      ),
                    ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.network_check, size: 18),
                        onPressed: onTest,
                        tooltip: 'Test Connection',
                        color: primaryDim,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(
                          minWidth: 32,
                          minHeight: 32,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit, size: 18),
                        onPressed: onEdit,
                        tooltip: 'Edit',
                        color: textDim,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(
                          minWidth: 32,
                          minHeight: 32,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, size: 18),
                        onPressed: onDelete,
                        tooltip: 'Delete',
                        color: error,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(
                          minWidth: 32,
                          minHeight: 32,
                        ),
                      ),
                    ],
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
