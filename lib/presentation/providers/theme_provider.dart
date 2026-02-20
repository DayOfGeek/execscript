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
import 'package:shared_preferences/shared_preferences.dart';

/// Available cyberpunk terminal themes
enum AppTheme {
  p1Green, // Classic green phosphor
  p3Amber, // Warm amber
  p4White, // Cool white
  neonCyan, // Cyberpunk cyan/magenta
  synthwave, // 80s purple/pink
}

/// Theme provider for managing app theme state
class ThemeNotifier extends StateNotifier<AppTheme> {
  static const String _themeKey = 'app_theme';

  ThemeNotifier() : super(AppTheme.p1Green) {
    _loadTheme();
  }

  /// Load saved theme from preferences
  Future<void> _loadTheme() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final themeName = prefs.getString(_themeKey);
      if (themeName != null) {
        final theme = AppTheme.values.firstWhere(
          (t) => t.name == themeName,
          orElse: () => AppTheme.p1Green,
        );
        state = theme;
      }
    } catch (e) {
      // Default to p1Green on error
    }
  }

  /// Set theme and save to preferences
  Future<void> setTheme(AppTheme theme) async {
    state = theme;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_themeKey, theme.name);
    } catch (e) {
      // Save failed, but state is updated
    }
  }

  /// Cycle to next theme
  void nextTheme() {
    final currentIndex = AppTheme.values.indexOf(state);
    final nextIndex = (currentIndex + 1) % AppTheme.values.length;
    setTheme(AppTheme.values[nextIndex]);
  }
}

/// Global theme provider
final themeProvider = StateNotifierProvider<ThemeNotifier, AppTheme>((ref) {
  return ThemeNotifier();
});

/// Theme display names
extension AppThemeExtension on AppTheme {
  String get displayName {
    switch (this) {
      case AppTheme.p1Green:
        return 'P1 Green (Classic)';
      case AppTheme.p3Amber:
        return 'P3 Amber (Warm)';
      case AppTheme.p4White:
        return 'P4 White (Cool)';
      case AppTheme.neonCyan:
        return 'Neon Cyan (Cyber)';
      case AppTheme.synthwave:
        return 'Synthwave (80s)';
    }
  }

  String get description {
    switch (this) {
      case AppTheme.p1Green:
        return 'Classic green phosphor terminal';
      case AppTheme.p3Amber:
        return 'Warm amber vintage monitor';
      case AppTheme.p4White:
        return 'Cool bright modern terminal';
      case AppTheme.neonCyan:
        return 'Vibrant cyan cyberpunk';
      case AppTheme.synthwave:
        return '80s retro purple/pink';
    }
  }
}
