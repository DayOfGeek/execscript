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

import '../data/models/execution.dart';
import '../data/models/script.dart';
import '../data/models/server.dart';
import '../data/repositories/execution_repository.dart';
import '../services/ssh_service.dart';
import '../services/tmux_service.dart';

/// Service for managing script executions
class ExecutionService {
  /// Execute a script in foreground mode (real-time streaming)
  static Stream<ExecutionUpdate> executeForeground(
    Server server,
    Script script, {
    Map<String, String> variables = const {},
  }) async* {
    // Create execution record
    var execution = Execution(
      serverId: server.id!,
      scriptId: script.id!,
      mode: ExecutionMode.foreground,
      status: ExecutionStatus.pending,
      variablesUsed: variables,
    );
    execution = await ExecutionRepository.insert(execution);

    yield ExecutionUpdate(
      type: ExecutionUpdateType.status,
      execution: execution,
      message: 'Connecting to server...',
    );

    SSHSession? session;
    try {
      // Connect to server
      session = await SSHService.connect(server);
      execution = execution.copyWith(status: ExecutionStatus.running);
      await ExecutionRepository.update(execution);

      yield ExecutionUpdate(
        type: ExecutionUpdateType.status,
        execution: execution,
        message: 'Connected. Executing script...',
      );

      // Prepare script with variables
      final scriptContent = script.injectVariables(variables);

      // Execute and stream output
      final outputBuffer = StringBuffer();
      await for (final output in SSHService.executeStream(
        session,
        scriptContent,
      )) {
        outputBuffer.write(output.content);

        yield ExecutionUpdate(
          type: ExecutionUpdateType.output,
          execution: execution,
          output: output,
        );
      }

      // Get final result
      // For streaming, we don't get exit code directly, so we'll check if output indicates error
      final fullOutput = outputBuffer.toString();
      final exitCode = fullOutput.toLowerCase().contains('error') ? 1 : 0;

      execution = execution.copyWith(
        status: exitCode == 0
            ? ExecutionStatus.completed
            : ExecutionStatus.failed,
        exitCode: exitCode,
        output: fullOutput,
        completedAt: DateTime.now(),
      );
      await ExecutionRepository.update(execution);

      yield ExecutionUpdate(
        type: ExecutionUpdateType.complete,
        execution: execution,
        message: exitCode == 0
            ? 'Execution completed successfully'
            : 'Execution failed',
      );
    } catch (e) {
      execution = execution.copyWith(
        status: ExecutionStatus.failed,
        output: 'Error: $e',
        completedAt: DateTime.now(),
      );
      await ExecutionRepository.update(execution);

      yield ExecutionUpdate(
        type: ExecutionUpdateType.error,
        execution: execution,
        message: 'Execution failed: $e',
      );
    } finally {
      if (session != null) {
        await SSHService.disconnect(session);
      }
    }
  }

  /// Execute a script in background mode (tmux/screen)
  static Future<Execution> executeBackground(
    Server server,
    Script script, {
    Map<String, String> variables = const {},
  }) async {
    // Create execution record
    var execution = Execution(
      serverId: server.id!,
      scriptId: script.id!,
      mode: ExecutionMode.background,
      status: ExecutionStatus.pending,
      variablesUsed: variables,
    );
    execution = await ExecutionRepository.insert(execution);

    // Generate tmux session name
    final sessionName = TmuxService.generateSessionName(execution.id!);

    SSHSession? session;
    try {
      // Connect to server
      session = await SSHService.connect(server);

      // Detect which multiplexer to use
      final multiplexer = await TmuxService.detectMultiplexer(
        session,
        server.preferredShell,
      );

      // Create session
      if (multiplexer == MultiplexerType.tmux) {
        await TmuxService.createSession(session, sessionName);
        await TmuxService.sendCommand(
          session,
          sessionName,
          script.injectVariables(variables),
        );
      } else {
        await TmuxService.createScreenSession(session, sessionName);
        await TmuxService.sendScreenCommand(
          session,
          sessionName,
          script.injectVariables(variables),
        );
      }

      // Update execution record
      execution = execution.copyWith(
        status: ExecutionStatus.running,
        tmuxSessionName: sessionName,
      );
      await ExecutionRepository.update(execution);

      // Disconnect - job continues on server
      await SSHService.disconnect(session);

      return execution;
    } catch (e) {
      if (session != null) {
        await SSHService.disconnect(session);
      }

      execution = execution.copyWith(
        status: ExecutionStatus.failed,
        output: 'Failed to start background job: $e',
        completedAt: DateTime.now(),
      );
      await ExecutionRepository.update(execution);

      throw Exception('Failed to start background job: $e');
    }
  }

  /// Check status of a background execution
  static Future<ExecutionStatusCheck> checkBackgroundStatus(
    Execution execution,
  ) async {
    if (execution.mode != ExecutionMode.background) {
      throw ArgumentError('Only background executions can be checked');
    }

    if (execution.tmuxSessionName == null) {
      throw ArgumentError('No tmux session name associated with execution');
    }

    final server = execution.serverId; // Would need to fetch actual server
    SSHSession? session;

    try {
      // Get server details
      // final server = await ServerRepository.getById(execution.serverId);
      // For now, we'll need to pass server separately or cache it
      // This is a placeholder - actual implementation needs ServerRepository

      return ExecutionStatusCheck(
        isRunning: false,
        execution: execution,
        message: 'Server lookup not implemented',
      );
    } catch (e) {
      return ExecutionStatusCheck(
        isRunning: false,
        execution: execution,
        message: 'Error checking status: $e',
      );
    }
  }

  /// Capture output from a completed background execution
  static Future<Execution> captureBackgroundOutput(
    Server server,
    Execution execution,
  ) async {
    if (execution.tmuxSessionName == null) {
      throw ArgumentError('No tmux session name');
    }

    SSHSession? session;
    try {
      session = await SSHService.connect(server);

      // Check if session still exists
      final isTmux = execution.tmuxSessionName!.startsWith('execscript-');
      final isActive = isTmux
          ? await TmuxService.isSessionActive(
              session,
              execution.tmuxSessionName!,
            )
          : await TmuxService.isScreenSessionActive(
              session,
              execution.tmuxSessionName!,
            );

      if (isActive) {
        // Still running - capture current output
        final output = isTmux
            ? await TmuxService.captureOutput(
                session,
                execution.tmuxSessionName!,
              )
            : await TmuxService.captureScreenOutput(
                session,
                execution.tmuxSessionName!,
              );

        await SSHService.disconnect(session);

        return execution.copyWith(output: output);
      } else {
        // Completed - capture final output
        final output = isTmux
            ? await TmuxService.captureOutput(
                session,
                execution.tmuxSessionName!,
              )
            : await TmuxService.captureScreenOutput(
                session,
                execution.tmuxSessionName!,
              );

        await SSHService.disconnect(session);

        // Update execution as completed
        final updatedExecution = execution.copyWith(
          status: ExecutionStatus.completed,
          output: output,
          exitCode: 0, // We can't easily get exit code from tmux
          completedAt: DateTime.now(),
        );
        await ExecutionRepository.update(updatedExecution);

        return updatedExecution;
      }
    } catch (e) {
      if (session != null) {
        await SSHService.disconnect(session);
      }
      throw Exception('Failed to capture output: $e');
    }
  }

  /// Cancel a running execution
  static Future<void> cancel(Execution execution) async {
    if (execution.mode == ExecutionMode.background &&
        execution.tmuxSessionName != null) {
      // Kill the tmux session
      // final server = await ServerRepository.getById(execution.serverId);
      // final session = await SSHService.connect(server);
      // await TmuxService.killSession(session, execution.tmuxSessionName!);
      // await SSHService.disconnect(session);
    }

    final updated = execution.copyWith(
      status: ExecutionStatus.cancelled,
      completedAt: DateTime.now(),
    );
    await ExecutionRepository.update(updated);
  }
}

/// Update from execution stream
class ExecutionUpdate {
  final ExecutionUpdateType type;
  final Execution execution;
  final String? message;
  final SSHOutput? output;

  ExecutionUpdate({
    required this.type,
    required this.execution,
    this.message,
    this.output,
  });
}

enum ExecutionUpdateType { status, output, complete, error }

/// Result of checking background execution status
class ExecutionStatusCheck {
  final bool isRunning;
  final Execution execution;
  final String message;

  ExecutionStatusCheck({
    required this.isRunning,
    required this.execution,
    required this.message,
  });
}
