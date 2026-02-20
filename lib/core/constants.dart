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

/// App constants
class AppConstants {
  // Database
  static const String databaseName = 'execscript.db';
  static const int databaseVersion = 1;

  // Secure storage keys
  static const String credentialKeyPrefix = 'server_cred_';

  // Tmux session naming
  static const String tmuxSessionPrefix = 'execscript';

  // Execution timeouts
  static const Duration foregroundTimeout = Duration(minutes: 5);
  static const Duration backgroundTimeout = Duration(hours: 2);
  static const Duration sshConnectionTimeout = Duration(seconds: 20);

  // UI
  static const double terminalFontSize = 13;
  static const int maxOutputLines = 10000;

  // App info
  static const String appName = 'EXECSCRIPT';
  static const String appVersion = '1.0.0';
}
