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


import 'package:flutter_test/flutter_test.dart';
import 'package:execscript/core/utils.dart';

void main() {
  group('shellEscape', () {
    test('escapes simple strings correctly', () {
      expect(shellEscape('hello'), "'hello'");
      expect(shellEscape('world'), "'world'");
    });

    test('wraps empty string in quotes', () {
      expect(shellEscape(''), "''");
    });

    test('escapes single quotes correctly', () {
      expect(shellEscape("hello'world"), "'hello'\\''world'");
      expect(shellEscape("it's"), "'it'\\''s'");
    });

    test('escapes multiple single quotes', () {
      expect(shellEscape("don't touch'"), "'don'\\''t touch'\\'''");
    });

    test('prevents command injection with semicolon', () {
      const malicious = '; rm -rf /';
      final escaped = shellEscape(malicious);
      // The entire string should be wrapped in single quotes
      expect(escaped, "'; rm -rf /'");
      // This should NOT allow command injection when used in a shell command
      // The shell will treat the entire string as a single argument
    });

    test('prevents command injection with backticks', () {
      const malicious = '\`whoami\`';
      final escaped = shellEscape(malicious);
      expect(escaped, "'\`whoami\`'");
    });

    test('prevents command injection with dollar parens', () {
      const malicious = '\$(whoami)';
      final escaped = shellEscape(malicious);
      expect(escaped, "'\$(whoami)'");
    });

    test('prevents command injection with pipe', () {
      const malicious = 'cmd | cat /etc/passwd';
      final escaped = shellEscape(malicious);
      expect(escaped, "'cmd | cat /etc/passwd'");
    });

    test('prevents command injection with ampersand', () {
      const malicious = 'cmd \u0026\u0026 evil';
      final escaped = shellEscape(malicious);
      expect(escaped, "'cmd \u0026\u0026 evil'");
    });

    test('handles complex malicious input', () {
      // This is a typical command injection attempt
      const malicious = '"; rm -rf /; echo "';
      final escaped = shellEscape(malicious);
      // The entire thing should be wrapped in single quotes
      expect(escaped, "'\"; rm -rf /; echo \"'");
    });

    test('handles session name injection attempt', () {
      // Simulating what could happen with session names
      const maliciousSession = 'my-session"; rm -rf /; echo "';
      final escaped = shellEscape(maliciousSession);
      expect(escaped, "'my-session\"; rm -rf /; echo \"'");
    });
  });

  group('pathEscape', () {
    test('escapes paths with spaces', () {
      expect(pathEscape('/path/to/my file.txt'), "'/path/to/my file.txt'");
    });

    test('escapes paths with single quotes', () {
      expect(pathEscape("/path/to/file's.txt"), "'/path/to/file'\\''s.txt'");
    });

    test('escapes empty path', () {
      expect(pathEscape(''), "''");
    });
  });
}
