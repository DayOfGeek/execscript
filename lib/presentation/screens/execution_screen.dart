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

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme.dart';
import '../../data/models/execution.dart';
import '../../data/models/server.dart';
import '../../data/models/script.dart';
import '../../data/repositories/execution_repository.dart';
import '../../data/repositories/server_repository.dart';
import '../../data/repositories/script_repository.dart';
import '../../services/ssh_service.dart';
import '../widgets/terminal_view.dart';

/// Screen for viewing execution progress and output
class ExecutionScreen extends ConsumerStatefulWidget {
  final int executionId;

  const ExecutionScreen({super.key, required this.executionId});

  @override
  ConsumerState<ExecutionScreen> createState() => _ExecutionScreenState();
}

class _ExecutionScreenState extends ConsumerState<ExecutionScreen> {
  Execution? _execution;
  Server? _server;
  Script? _script;
  List<SSHOutput> _outputs = [];
  bool _isLoading = true;
  String? _error;
  StreamSubscription<SSHOutput>? _outputSubscription;
  final ScrollController _scrollController = ScrollController();
  bool _isCancelling = false;

  @override
  void initState() {
    super.initState();
    _loadExecution();
  }

  @override
  void dispose() {
    _outputSubscription?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadExecution() async {
    try {
      final execution = await ExecutionRepository.getById(widget.executionId);
      if (execution == null) {
        setState(() {
          _error = 'Execution not found';
          _isLoading = false;
        });
        return;
      }

      final server = await ServerRepository.getById(execution.serverId);
      final script = await ScriptRepository.getById(execution.scriptId);

      setState(() {
        _execution = execution;
        _server = server;
        _script = script;
        _isLoading = false;
      });

      // Load existing output
      if (execution.output != null && execution.output!.isNotEmpty) {
        setState(() {
          _outputs = execution.output!.split('\n').map((line) {
            return SSHOutput(content: line, isError: false);
          }).toList();
        });
      }

      // If running, stream output
      if (execution.isRunning) {
        _streamOutput(execution);
      }
    } catch (e) {
      setState(() {
        _error = 'Error loading execution: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _streamOutput(Execution execution) async {
    if (_server == null || _script == null) return;

    // Update status to running
    if (execution.id != null) {
      await ExecutionRepository.updateStatus(
        execution.id!,
        ExecutionStatus.running,
      );
    }
    setState(() {
      _execution = _execution?.copyWith(status: ExecutionStatus.running);
    });

    try {
      // Connect to server
      final session = await SSHService.connect(
        _server!,
        acceptNewHostKey: true,
      );

      // Get the script content with variables injected
      final scriptContent = _script!.injectVariables(execution.variablesUsed);

      // Stream output
      _outputSubscription = SSHService.executeStream(session, scriptContent)
          .listen(
            (output) {
              setState(() {
                _outputs.add(output);
              });
              _scrollToBottom();
            },
            onError: (error) async {
              setState(() {
                _outputs.add(
                  SSHOutput(content: 'ERROR: $error', isError: true),
                );
                _execution = _execution?.copyWith(
                  status: ExecutionStatus.failed,
                  exitCode: 1,
                  completedAt: DateTime.now(),
                );
              });
              _scrollToBottom();
              // Update database
              if (_execution?.id != null) {
                await ExecutionRepository.complete(
                  _execution!.id!,
                  output: _outputs.map((o) => o.content).join('\n'),
                  exitCode: 1,
                );
              }
            },
            onDone: () async {
              await session.close();
              // Mark as complete in UI - don't reload from DB
              // The stream completion means the command finished successfully
              setState(() {
                _execution = _execution?.copyWith(
                  status: ExecutionStatus.completed,
                  exitCode: 0,
                  completedAt: DateTime.now(),
                );
              });
              // Update database status
              if (_execution?.id != null) {
                await ExecutionRepository.updateStatus(
                  _execution!.id!,
                  ExecutionStatus.completed,
                );
              }
            },
          );
    } catch (e) {
      setState(() {
        _outputs.add(SSHOutput(content: 'CONNECTION ERROR: $e', isError: true));
        _execution = _execution?.copyWith(status: ExecutionStatus.failed);
      });
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      });
    }
  }

  Future<void> _cancelExecution() async {
    if (_execution == null) return;

    setState(() {
      _isCancelling = true;
    });

    try {
      await ExecutionRepository.updateStatus(
        _execution!.id!,
        ExecutionStatus.cancelled,
      );

      _outputSubscription?.cancel();

      setState(() {
        _isCancelling = false;
        _execution = _execution?.copyWith(status: ExecutionStatus.cancelled);
        _outputs.add(
          SSHOutput(content: '[EXECUTION CANCELLED BY USER]', isError: false),
        );
      });
    } catch (e) {
      setState(() {
        _isCancelling = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.extension<CyberTermThemeExtension>();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          '[EXECUTION]',
          style: GoogleFonts.jetBrainsMono(fontWeight: FontWeight.bold),
        ),
        actions: [
          if (_execution != null && _execution!.isComplete)
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () => _deleteExecution(colors),
              tooltip: 'Delete execution record',
            ),
        ],
      ),
      body: _buildBody(colors),
      bottomNavigationBar: _buildBottomBar(colors),
    );
  }

  Widget _buildBody(CyberTermThemeExtension? colors) {
    final primary = colors?.primary ?? CyberTermColors.primary;
    final error = colors?.error ?? CyberTermColors.error;

    if (_isLoading) {
      return Center(child: CircularProgressIndicator(color: primary));
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error, size: 48, color: error),
            const SizedBox(height: 16),
            Text(
              _error!,
              style: GoogleFonts.jetBrainsMono(color: error, fontSize: 13),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: _loadExecution,
              child: Text(
                '[RETRY]',
                style: GoogleFonts.jetBrainsMono(color: primary),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // Header
        _buildHeader(colors),
        // Terminal output
        Expanded(
          child: TerminalView(
            outputs: _outputs,
            isRunning: _execution?.isRunning ?? false,
            scrollController: _scrollController,
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(CyberTermThemeExtension? colors) {
    final surface = colors?.surface ?? CyberTermColors.surface;
    final border = colors?.border ?? CyberTermColors.border;
    final textColor = colors?.textColor ?? CyberTermColors.textColor;
    final textDim = colors?.textDim ?? CyberTermColors.textDim;
    final success = colors?.success ?? CyberTermColors.success;
    final error = colors?.error ?? CyberTermColors.error;

    final statusColor = _getStatusColor(_execution?.status, colors);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: surface,
        border: Border(bottom: BorderSide(color: border)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const TerminalLabel('SERVER'),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _server?.name ?? 'Unknown',
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 13,
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
                  _script?.name ?? 'Unknown',
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 13,
                    color: textColor,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const TerminalLabel('STATUS'),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: statusColor.withAlpha(51), // 0.2 * 255 ≈ 51
                  border: Border.all(color: statusColor),
                ),
                child: Text(
                  _execution?.status.name.toUpperCase() ?? 'UNKNOWN',
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 10,
                    color: statusColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const Spacer(),
              if (_execution?.exitCode != null)
                Text(
                  'EXIT CODE: ${_execution!.exitCode}',
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 10,
                    color: _execution!.exitCode == 0 ? success : error,
                  ),
                ),
            ],
          ),
          if (_execution?.duration != null) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                const TerminalLabel('DURATION'),
                const SizedBox(width: 8),
                Text(
                  _formatDuration(_execution!.duration!),
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 11,
                    color: textDim,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBottomBar(CyberTermThemeExtension? colors) {
    final surface = colors?.surface ?? CyberTermColors.surface;
    final border = colors?.border ?? CyberTermColors.border;
    final error = colors?.error ?? CyberTermColors.error;
    final primary = colors?.primary ?? CyberTermColors.primary;

    final isRunning = _execution?.isRunning ?? false;
    final isComplete = _execution?.isComplete ?? false;

    return SafeArea(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: surface,
          border: Border(top: BorderSide(color: border)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            if (isRunning) ...[
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _isCancelling ? null : _cancelExecution,
                  icon: _isCancelling
                      ? SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: error,
                          ),
                        )
                      : Icon(Icons.stop, color: error),
                  label: Text(
                    '[CANCEL]',
                    style: GoogleFonts.jetBrainsMono(color: error),
                  ),
                ),
              ),
            ] else if (isComplete) ...[
              Expanded(
                child: FilledButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.check),
                  label: Text('[DONE]', style: GoogleFonts.jetBrainsMono()),
                ),
              ),
            ] else ...[
              // Pending state
              BlinkingCursor(color: primary, fontSize: 13),
            ],
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(
    ExecutionStatus? status,
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
      default:
        return colors?.textDim ?? CyberTermColors.textDim;
    }
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    final milliseconds = duration.inMilliseconds % 1000;

    if (minutes > 0) {
      return '${minutes}m ${seconds}s';
    } else if (seconds > 0) {
      return '${seconds}s ${milliseconds}ms';
    } else {
      return '${milliseconds}ms';
    }
  }

  Future<void> _deleteExecution(CyberTermThemeExtension? colors) async {
    final surface = colors?.surface ?? CyberTermColors.surface;
    final error = colors?.error ?? CyberTermColors.error;
    final textDim = colors?.textDim ?? CyberTermColors.textDim;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: surface,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        title: Text(
          '[DELETE EXECUTION]',
          style: GoogleFonts.jetBrainsMono(
            color: error,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          'Delete this execution record?\n\nThis action cannot be undone.',
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

    if (confirmed == true && _execution?.id != null) {
      try {
        await ExecutionRepository.delete(_execution!.id!);
        if (mounted) {
          Navigator.pop(context);
        }
      } catch (e) {
        if (mounted) {
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
}
