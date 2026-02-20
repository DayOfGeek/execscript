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

/// Execution mode: foreground (real-time) or background (tmux)
enum ExecutionMode { foreground, background }

/// Execution status
enum ExecutionStatus { pending, running, completed, failed, cancelled }

/// Execution model representing a script run
class Execution {
  final int? id;
  final int serverId;
  final int scriptId;
  final ExecutionMode mode;
  final String? tmuxSessionName; // For background mode
  final ExecutionStatus status;
  final String? output;
  final int? exitCode;
  final Map<String, String> variablesUsed;
  final DateTime startedAt;
  final DateTime? completedAt;

  Execution({
    this.id,
    required this.serverId,
    required this.scriptId,
    required this.mode,
    this.tmuxSessionName,
    this.status = ExecutionStatus.pending,
    this.output,
    this.exitCode,
    this.variablesUsed = const {},
    DateTime? startedAt,
    this.completedAt,
  }) : startedAt = startedAt ?? DateTime.now();

  bool get isRunning =>
      status == ExecutionStatus.running || status == ExecutionStatus.pending;
  bool get isComplete =>
      status == ExecutionStatus.completed ||
      status == ExecutionStatus.failed ||
      status == ExecutionStatus.cancelled;
  bool get isSuccessful =>
      status == ExecutionStatus.completed && (exitCode ?? -1) == 0;

  Duration? get duration {
    if (completedAt == null) return null;
    return completedAt!.difference(startedAt);
  }

  Execution copyWith({
    int? id,
    int? serverId,
    int? scriptId,
    ExecutionMode? mode,
    String? tmuxSessionName,
    ExecutionStatus? status,
    String? output,
    int? exitCode,
    Map<String, String>? variablesUsed,
    DateTime? startedAt,
    DateTime? completedAt,
  }) {
    return Execution(
      id: id ?? this.id,
      serverId: serverId ?? this.serverId,
      scriptId: scriptId ?? this.scriptId,
      mode: mode ?? this.mode,
      tmuxSessionName: tmuxSessionName ?? this.tmuxSessionName,
      status: status ?? this.status,
      output: output ?? this.output,
      exitCode: exitCode ?? this.exitCode,
      variablesUsed: variablesUsed ?? this.variablesUsed,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'server_id': serverId,
      'script_id': scriptId,
      'mode': mode.name,
      'tmux_session_name': tmuxSessionName,
      'status': status.name,
      'output': output,
      'exit_code': exitCode,
      'variables_used': variablesUsed.toString(),
      'started_at': startedAt.toIso8601String(),
      'completed_at': completedAt?.toIso8601String(),
    };
  }

  factory Execution.fromMap(Map<String, dynamic> map) {
    return Execution(
      id: map['id'] as int?,
      serverId: map['server_id'] as int,
      scriptId: map['script_id'] as int,
      mode: ExecutionMode.values.firstWhere(
        (e) => e.name == map['mode'],
        orElse: () => ExecutionMode.foreground,
      ),
      tmuxSessionName: map['tmux_session_name'] as String?,
      status: ExecutionStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => ExecutionStatus.pending,
      ),
      output: map['output'] as String?,
      exitCode: map['exit_code'] as int?,
      variablesUsed: {}, // Simplified - would parse from string
      startedAt: DateTime.parse(map['started_at'] as String),
      completedAt: map['completed_at'] != null
          ? DateTime.parse(map['completed_at'] as String)
          : null,
    );
  }

  @override
  String toString() {
    return 'Execution(id: $id, serverId: $serverId, scriptId: $scriptId, status: ${status.name})';
  }
}
