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

/// Shell escaping utility for secure command construction
///
/// Prevents command injection attacks by properly escaping user input
/// before interpolation into shell commands.
library;

/// Escapes a string for safe use in shell commands.
///
/// Uses single quotes and escapes embedded single quotes by ending the
/// quoted string, adding an escaped quote, and starting a new quoted string.
///
/// Example:
/// ```dart
/// shellEscape("hello")          // returns 'hello'
/// shellEscape("hello'world")    // returns 'hello'\''world'
/// shellEscape('"; rm -rf /')    // returns '"; rm -rf /'
/// ```
///
/// This approach is safe for sh, bash, and most POSIX-compatible shells.
String shellEscape(String input) {
  if (input.isEmpty) {
    return "''";
  }
  // Escape single quotes by wrapping in single quotes and escaping
  // embedded single quotes as '\''
  return "'${input.replaceAll("'", "'\\''")}'";
}

/// Escapes a string for use as a POSIX filename/path.
///
/// Similar to shellEscape but optimized for file paths.
/// Handles spaces, special characters, and quote characters safely.
String pathEscape(String input) {
  if (input.isEmpty) {
    return "''";
  }
  // Use the same single-quote escaping strategy
  return "'${input.replaceAll("'", "'\\''")}'";
}
