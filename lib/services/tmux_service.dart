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

import '../core/constants.dart';
import '../core/utils.dart';
import '../data/models/server.dart';
import '../services/ssh_service.dart';

/// Service for managing tmux/screen sessions on remote servers
class TmuxService {
  /// Generate a unique session name
  static String generateSessionName(int executionId) {
    return '${AppConstants.tmuxSessionPrefix}-$executionId';
  }

  /// Check if tmux is available on server
  static Future<bool> isTmuxAvailable(SSHSession session) async {
    try {
      final result = await SSHService.execute(session, 'which tmux');
      return result.exitCode == 0;
    } catch (e) {
      return false;
    }
  }

  /// Check if screen is available on server
  static Future<bool> isScreenAvailable(SSHSession session) async {
    try {
      final result = await SSHService.execute(session, 'which screen');
      return result.exitCode == 0;
    } catch (e) {
      return false;
    }
  }

  /// Create a new tmux session
  static Future<void> createSession(
    SSHSession session,
    String sessionName, {
    String? workingDirectory,
  }) async {
    final cdCmd = workingDirectory != null
        ? 'cd ${shellEscape(workingDirectory)} && '
        : '';
    final result = await SSHService.execute(
      session,
      '${cdCmd}tmux new-session -d -s ${shellEscape(sessionName)}',
    );

    if (result.exitCode != 0) {
      throw Exception('Failed to create tmux session: ${result.stderr}');
    }
  }

  /// Send a command to a tmux session
  static Future<void> sendCommand(
    SSHSession session,
    String sessionName,
    String command, {
    bool pressEnter = true,
  }) async {
    final safeSessionName = shellEscape(sessionName);
    final safeCommand = shellEscape(command);
    final cmd = pressEnter
        ? 'tmux send-keys -t $safeSessionName $safeCommand Enter'
        : 'tmux send-keys -t $safeSessionName $safeCommand';

    final result = await SSHService.execute(session, cmd);

    if (result.exitCode != 0) {
      throw Exception('Failed to send command: ${result.stderr}');
    }
  }

  /// Send literal text (useful for special characters)
  static Future<void> sendLiteral(
    SSHSession session,
    String sessionName,
    String text,
  ) async {
    final safeSessionName = shellEscape(sessionName);
    final safeText = shellEscape(text);
    final result = await SSHService.execute(
      session,
      'tmux send-keys -t $safeSessionName -l $safeText',
    );

    if (result.exitCode != 0) {
      throw Exception('Failed to send literal text: ${result.stderr}');
    }
  }

  /// Check if a session is still active
  static Future<bool> isSessionActive(
    SSHSession session,
    String sessionName,
  ) async {
    try {
      final result = await SSHService.execute(
        session,
        'tmux has-session -t ${shellEscape(sessionName)}',
      );
      return result.exitCode == 0;
    } catch (e) {
      return false;
    }
  }

  /// Capture output from a session
  static Future<String> captureOutput(
    SSHSession session,
    String sessionName, {
    int lines = 500,
  }) async {
    final result = await SSHService.execute(
      session,
      'tmux capture-pane -t ${shellEscape(sessionName)} -p -S -$lines',
    );

    if (result.exitCode != 0) {
      throw Exception('Failed to capture output: ${result.stderr}');
    }

    return result.stdout;
  }

  /// Get all tmux sessions
  static Future<List<String>> listSessions(SSHSession session) async {
    final result = await SSHService.execute(
      session,
      'tmux list-sessions -F "#S"',
    );

    if (result.exitCode != 0) {
      return [];
    }

    return result.stdout
        .split('\n')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
  }

  /// Kill a session
  static Future<void> killSession(
    SSHSession session,
    String sessionName,
  ) async {
    await SSHService.execute(
      session,
      'tmux kill-session -t ${shellEscape(sessionName)}',
    );
  }

  /// Attach to a session (for interactive use - not used in background mode)
  static Future<void> attachSession(
    SSHSession session,
    String sessionName, {
    bool readOnly = false,
  }) async {
    final flag = readOnly ? '-r' : '';
    // This would be for interactive mode - execute tmux attach
    await SSHService.execute(
      session,
      'tmux attach $flag -t ${shellEscape(sessionName)}',
    );
  }

  // ==================== Screen Support ====================

  /// Create a new screen session (fallback if tmux not available)
  static Future<void> createScreenSession(
    SSHSession session,
    String sessionName, {
    String? workingDirectory,
  }) async {
    final cdCmd = workingDirectory != null
        ? 'cd ${shellEscape(workingDirectory)} && '
        : '';
    final result = await SSHService.execute(
      session,
      '${cdCmd}screen -dmS ${shellEscape(sessionName)}',
    );

    if (result.exitCode != 0) {
      throw Exception('Failed to create screen session: ${result.stderr}');
    }
  }

  /// Send command to screen session
  static Future<void> sendScreenCommand(
    SSHSession session,
    String sessionName,
    String command, {
    bool pressEnter = true,
  }) async {
    final safeSessionName = shellEscape(sessionName);
    final safeCommand = shellEscape(command);
    final cmd = 'screen -S $safeSessionName -X stuff $safeCommand';
    final enterCmd = pressEnter ? '\\015' : ''; // \r

    final result = await SSHService.execute(session, '$cmd$enterCmd');

    if (result.exitCode != 0) {
      throw Exception('Failed to send screen command: ${result.stderr}');
    }
  }

  /// Check if screen session is active
  static Future<bool> isScreenSessionActive(
    SSHSession session,
    String sessionName,
  ) async {
    try {
      final safeSessionName = shellEscape(sessionName);
      final result = await SSHService.execute(
        session,
        'screen -list | grep -q "\\.$safeSessionName\\t"',
      );
      return result.exitCode == 0;
    } catch (e) {
      return false;
    }
  }

  /// Get screen output (screen doesn't have capture-pane like tmux)
  /// This creates a log file and reads it
  static Future<String> captureScreenOutput(
    SSHSession session,
    String sessionName, {
    int lines = 500,
  }) async {
    final safeSessionName = shellEscape(sessionName);
    final logPath = pathEscape('/tmp/execscript-$sessionName.log');
    // Screen stores output differently - we can use hardcopy or log
    final result = await SSHService.execute(
      session,
      'screen -S $safeSessionName -X hardcopy $logPath && '
      'tail -n $lines $logPath',
    );

    if (result.exitCode != 0) {
      throw Exception('Failed to capture screen output: ${result.stderr}');
    }

    return result.stdout;
  }

  /// Kill screen session
  static Future<void> killScreenSession(
    SSHSession session,
    String sessionName,
  ) async {
    await SSHService.execute(
      session,
      'screen -S ${shellEscape(sessionName)} -X quit',
    );
  }

  /// Determine which multiplexer to use and check availability
  static Future<MultiplexerType> detectMultiplexer(
    SSHSession session,
    PreferredShell preference,
  ) async {
    switch (preference) {
      case PreferredShell.tmux:
        if (await isTmuxAvailable(session)) {
          return MultiplexerType.tmux;
        }
        if (await isScreenAvailable(session)) {
          return MultiplexerType.screen;
        }
        throw Exception('Neither tmux nor screen is available on server');

      case PreferredShell.screen:
        if (await isScreenAvailable(session)) {
          return MultiplexerType.screen;
        }
        if (await isTmuxAvailable(session)) {
          return MultiplexerType.tmux;
        }
        throw Exception('Neither screen nor tmux is available on server');

      case PreferredShell.none:
        throw Exception('Background execution requires tmux or screen');
    }
  }
}

enum MultiplexerType { tmux, screen }
