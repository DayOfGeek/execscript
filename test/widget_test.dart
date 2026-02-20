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

// This is a basic Flutter widget test for ExecScript.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:execscript/main.dart';

void main() {
  testWidgets('ExecScript app renders home screen', (
    WidgetTester tester,
  ) async {
    // Build our app with ProviderScope and trigger a frame.
    await tester.pumpWidget(const ProviderScope(child: ExecScriptApp()));

    // Verify that the app title is displayed.
    expect(find.text('EXECSCRIPT'), findsOneWidget);

    // Verify that the sections are displayed.
    expect(find.text('SERVERS'), findsOneWidget);
    expect(find.text('SCRIPT LIBRARY'), findsOneWidget);
    expect(find.text('RECENT EXECUTIONS'), findsOneWidget);
  });
}
