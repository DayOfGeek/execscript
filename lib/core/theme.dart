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
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../presentation/providers/theme_provider.dart';

/// Color definitions for each theme
class ThemeColors {
  static const Map<AppTheme, Map<String, Color>> colors = {
    AppTheme.p1Green: {
      'background': Color(0xFF0A0F0A),
      'surface': Color(0xFF0F1A0F),
      'surfaceLight': Color(0xFF142214),
      'primary': Color(0xFF33FF33),
      'primaryDim': Color(0xFF1A801A),
      'textColor': Color(0xFF33FF33),
      'textDim': Color(0xFF66FF66),
      'textMuted': Color(0xFF4D994D),
      'accent': Color(0xFF66FF66),
      'error': Color(0xFFFF3333),
      'warning': Color(0xFFFFAA33),
      'success': Color(0xFF33FF33),
      'border': Color(0xFF1A3A1A),
      'userBubble': Color(0xFF0F1A0F),
      'botBubble': Color(0xFF0A150A),
      'inputFill': Color(0xFF0F1A0F),
    },
    AppTheme.p3Amber: {
      'background': Color(0xFF0F0A00),
      'surface': Color(0xFF1A1200),
      'surfaceLight': Color(0xFF241900),
      'primary': Color(0xFFFFB300),
      'primaryDim': Color(0xFF805900),
      'textColor': Color(0xFFFFB300),
      'textDim': Color(0xFFFFD54F),
      'textMuted': Color(0xFF997F00),
      'accent': Color(0xFFFFD54F),
      'error': Color(0xFFFF4444),
      'warning': Color(0xFFFF8800),
      'success': Color(0xFF33FF33),
      'border': Color(0xFF3A2A00),
      'userBubble': Color(0xFF1A1200),
      'botBubble': Color(0xFF0F0A00),
      'inputFill': Color(0xFF1A1200),
    },
    AppTheme.p4White: {
      'background': Color(0xFF0A0A0F),
      'surface': Color(0xFF12121A),
      'surfaceLight': Color(0xFF1A1A24),
      'primary': Color(0xFFE0E0FF),
      'primaryDim': Color(0xFF8080AA),
      'textColor': Color(0xFFE0E0FF),
      'textDim': Color(0xFFB0B0D0),
      'textMuted': Color(0xFF707090),
      'accent': Color(0xFFFFFFFF),
      'error': Color(0xFFFF6666),
      'warning': Color(0xFFFFCC66),
      'success': Color(0xFF66FF66),
      'border': Color(0xFF2A2A3A),
      'userBubble': Color(0xFF12121A),
      'botBubble': Color(0xFF0A0A10),
      'inputFill': Color(0xFF12121A),
    },
    AppTheme.neonCyan: {
      'background': Color(0xFF050A0F),
      'surface': Color(0xFF0A1520),
      'surfaceLight': Color(0xFF0F2030),
      'primary': Color(0xFF00FFFF),
      'primaryDim': Color(0xFF008080),
      'textColor': Color(0xFF00FFFF),
      'textDim': Color(0xFF66FFFF),
      'textMuted': Color(0xFF0080AA),
      'accent': Color(0xFFFF00FF),
      'error': Color(0xFFFF3366),
      'warning': Color(0xFFFFAA00),
      'success': Color(0xFF00FF99),
      'border': Color(0xFF0A3A50),
      'userBubble': Color(0xFF0A1520),
      'botBubble': Color(0xFF050A10),
      'inputFill': Color(0xFF0A1520),
    },
    AppTheme.synthwave: {
      'background': Color(0xFF0F0A1A),
      'surface': Color(0xFF1A1030),
      'surfaceLight': Color(0xFF251540),
      'primary': Color(0xFFFF66FF),
      'primaryDim': Color(0xFF8033AA),
      'textColor': Color(0xFFE0B0FF),
      'textDim': Color(0xFFCC80FF),
      'textMuted': Color(0xFF8050AA),
      'accent': Color(0xFF00FFFF),
      'error': Color(0xFFFF5588),
      'warning': Color(0xFFFFAA55),
      'success': Color(0xFF55FF99),
      'border': Color(0xFF2A1A3A),
      'userBubble': Color(0xFF1A1030),
      'botBubble': Color(0xFF0F0A1A),
      'inputFill': Color(0xFF1A1030),
    },
  };

  static Color getColor(AppTheme theme, String key) {
    return colors[theme]?[key] ?? colors[AppTheme.p1Green]![key]!;
  }
}

/// Legacy CyberTermColors - uses current theme from provider
/// Note: For dynamic theming, use Theme.of(context).extension<CyberTermThemeExtension>()
class CyberTermColors {
  // These will be deprecated in favor of dynamic theming
  static Color get background =>
      ThemeColors.getColor(AppTheme.p1Green, 'background');
  static Color get surface => ThemeColors.getColor(AppTheme.p1Green, 'surface');
  static Color get surfaceLight =>
      ThemeColors.getColor(AppTheme.p1Green, 'surfaceLight');
  static Color get primary => ThemeColors.getColor(AppTheme.p1Green, 'primary');
  static Color get primaryDim =>
      ThemeColors.getColor(AppTheme.p1Green, 'primaryDim');
  static Color get textColor =>
      ThemeColors.getColor(AppTheme.p1Green, 'textColor');
  static Color get textDim => ThemeColors.getColor(AppTheme.p1Green, 'textDim');
  static Color get textMuted =>
      ThemeColors.getColor(AppTheme.p1Green, 'textMuted');
  static Color get accent => ThemeColors.getColor(AppTheme.p1Green, 'accent');
  static Color get error => ThemeColors.getColor(AppTheme.p1Green, 'error');
  static Color get warning => ThemeColors.getColor(AppTheme.p1Green, 'warning');
  static Color get success => ThemeColors.getColor(AppTheme.p1Green, 'success');
  static Color get border => ThemeColors.getColor(AppTheme.p1Green, 'border');
  static Color get userBubble =>
      ThemeColors.getColor(AppTheme.p1Green, 'userBubble');
  static Color get botBubble =>
      ThemeColors.getColor(AppTheme.p1Green, 'botBubble');
  static Color get inputFill =>
      ThemeColors.getColor(AppTheme.p1Green, 'inputFill');
}

/// Theme extension for dynamic theming
class CyberTermThemeExtension extends ThemeExtension<CyberTermThemeExtension> {
  final AppTheme theme;
  final Map<String, Color> colors;

  CyberTermThemeExtension({required this.theme})
    : colors = ThemeColors.colors[theme]!;

  Color get background => colors['background']!;
  Color get surface => colors['surface']!;
  Color get surfaceLight => colors['surfaceLight']!;
  Color get primary => colors['primary']!;
  Color get primaryDim => colors['primaryDim']!;
  Color get textColor => colors['textColor']!;
  Color get textDim => colors['textDim']!;
  Color get textMuted => colors['textMuted']!;
  Color get accent => colors['accent']!;
  Color get error => colors['error']!;
  Color get warning => colors['warning']!;
  Color get success => colors['success']!;
  Color get border => colors['border']!;
  Color get userBubble => colors['userBubble']!;
  Color get botBubble => colors['botBubble']!;
  Color get inputFill => colors['inputFill']!;

  @override
  CyberTermThemeExtension copyWith({AppTheme? theme}) {
    return CyberTermThemeExtension(theme: theme ?? this.theme);
  }

  @override
  CyberTermThemeExtension lerp(
    ThemeExtension<CyberTermThemeExtension>? other,
    double t,
  ) {
    return this;
  }
}

/// Theme data builder for the cyberpunk terminal aesthetic
ThemeData buildCyberTermTheme(AppTheme appTheme) {
  final colors = ThemeColors.colors[appTheme]!;
  final monoTextTheme = GoogleFonts.jetBrainsMonoTextTheme();

  return ThemeData(
    brightness: Brightness.dark,
    useMaterial3: true,
    scaffoldBackgroundColor: colors['background'],
    extensions: [CyberTermThemeExtension(theme: appTheme)],

    colorScheme: ColorScheme.dark(
      primary: colors['primary']!,
      onPrimary: colors['background']!,
      secondary: colors['accent']!,
      onSecondary: colors['background']!,
      surface: colors['surface']!,
      onSurface: colors['textColor']!,
      error: colors['error']!,
      onError: colors['background']!,
      outline: colors['border']!,
    ),

    textTheme: monoTextTheme.copyWith(
      displayLarge: monoTextTheme.displayLarge?.copyWith(
        color: colors['textColor'],
        fontFamily: 'JetBrainsMono',
      ),
      displayMedium: monoTextTheme.displayMedium?.copyWith(
        color: colors['textColor'],
        fontFamily: 'JetBrainsMono',
      ),
      displaySmall: monoTextTheme.displaySmall?.copyWith(
        color: colors['textColor'],
        fontFamily: 'JetBrainsMono',
      ),
      headlineLarge: monoTextTheme.headlineLarge?.copyWith(
        color: colors['textColor'],
        fontFamily: 'JetBrainsMono',
      ),
      headlineMedium: monoTextTheme.headlineMedium?.copyWith(
        color: colors['textColor'],
        fontFamily: 'JetBrainsMono',
      ),
      headlineSmall: monoTextTheme.headlineSmall?.copyWith(
        color: colors['textColor'],
        fontFamily: 'JetBrainsMono',
      ),
      titleLarge: monoTextTheme.titleLarge?.copyWith(
        color: colors['textColor'],
        fontFamily: 'JetBrainsMono',
        fontWeight: FontWeight.bold,
      ),
      titleMedium: monoTextTheme.titleMedium?.copyWith(
        color: colors['textColor'],
        fontFamily: 'JetBrainsMono',
      ),
      titleSmall: monoTextTheme.titleSmall?.copyWith(
        color: colors['textDim'],
        fontFamily: 'JetBrainsMono',
      ),
      bodyLarge: monoTextTheme.bodyLarge?.copyWith(
        color: colors['textColor'],
        fontFamily: 'JetBrainsMono',
      ),
      bodyMedium: monoTextTheme.bodyMedium?.copyWith(
        color: colors['textColor'],
        fontFamily: 'JetBrainsMono',
        fontSize: 13,
        height: 1.5,
      ),
      bodySmall: monoTextTheme.bodySmall?.copyWith(
        color: colors['textDim'],
        fontFamily: 'JetBrainsMono',
        fontSize: 11,
      ),
      labelLarge: monoTextTheme.labelLarge?.copyWith(
        color: colors['primary'],
        fontFamily: 'JetBrainsMono',
        fontWeight: FontWeight.bold,
      ),
      labelMedium: monoTextTheme.labelMedium?.copyWith(
        color: colors['textDim'],
        fontFamily: 'JetBrainsMono',
        fontSize: 10,
      ),
      labelSmall: monoTextTheme.labelSmall?.copyWith(
        color: colors['textMuted'],
        fontFamily: 'JetBrainsMono',
        fontSize: 9,
      ),
    ),

    appBarTheme: AppBarTheme(
      backgroundColor: colors['background'],
      foregroundColor: colors['primary'],
      elevation: 0,
      centerTitle: false,
      titleTextStyle: GoogleFonts.jetBrainsMono(
        color: colors['primary'],
        fontSize: 16,
        fontWeight: FontWeight.bold,
      ),
      iconTheme: IconThemeData(color: colors['primary']),
      shape: Border(bottom: BorderSide(color: colors['border']!, width: 1)),
      systemOverlayStyle: SystemUiOverlayStyle(
        statusBarColor: colors['background'],
        statusBarIconBrightness: Brightness.light,
      ),
    ),

    cardTheme: CardThemeData(
      color: colors['surface'],
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.zero,
        side: BorderSide(color: colors['border']!, width: 1),
      ),
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
    ),

    listTileTheme: ListTileThemeData(
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      iconColor: colors['primaryDim'],
      textColor: colors['textColor'],
      tileColor: colors['surface'],
      selectedTileColor: colors['surfaceLight'],
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      titleTextStyle: GoogleFonts.jetBrainsMono(
        color: colors['textColor'],
        fontSize: 13,
      ),
      subtitleTextStyle: GoogleFonts.jetBrainsMono(
        color: colors['textDim'],
        fontSize: 11,
      ),
    ),

    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: colors['primary'],
        foregroundColor: colors['background'],
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        textStyle: GoogleFonts.jetBrainsMono(fontWeight: FontWeight.bold),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    ),

    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: colors['primary'],
        side: BorderSide(color: colors['border']!),
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        textStyle: GoogleFonts.jetBrainsMono(),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    ),

    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: colors['primary'],
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        textStyle: GoogleFonts.jetBrainsMono(),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
    ),

    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: colors['surface'],
      hintStyle: GoogleFonts.jetBrainsMono(color: colors['textDim']),
      labelStyle: GoogleFonts.jetBrainsMono(color: colors['textDim']),
      helperStyle: GoogleFonts.jetBrainsMono(
        color: colors['textMuted'],
        fontSize: 11,
      ),
      errorStyle: GoogleFonts.jetBrainsMono(
        color: colors['error'],
        fontSize: 11,
      ),
      contentPadding: const EdgeInsets.all(12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.zero,
        borderSide: BorderSide(color: colors['border']!),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.zero,
        borderSide: BorderSide(color: colors['border']!),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.zero,
        borderSide: BorderSide(color: colors['primary']!, width: 1),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.zero,
        borderSide: BorderSide(color: colors['error']!),
      ),
    ),

    dialogTheme: DialogThemeData(
      backgroundColor: colors['surface'],
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.zero,
        side: BorderSide(color: colors['primary']!, width: 1),
      ),
      titleTextStyle: GoogleFonts.jetBrainsMono(
        color: colors['primary'],
        fontSize: 14,
        fontWeight: FontWeight.bold,
      ),
      contentTextStyle: GoogleFonts.jetBrainsMono(
        color: colors['textDim'],
        fontSize: 12,
      ),
    ),

    dividerTheme: DividerThemeData(
      color: colors['border'],
      thickness: 1,
      space: 1,
    ),

    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: colors['primary'],
      foregroundColor: colors['background'],
      elevation: 0,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
    ),

    chipTheme: ChipThemeData(
      backgroundColor: colors['surface'],
      selectedColor: colors['primaryDim'],
      disabledColor: colors['surfaceLight'],
      labelStyle: GoogleFonts.jetBrainsMono(
        color: colors['textColor'],
        fontSize: 10,
      ),
      secondaryLabelStyle: GoogleFonts.jetBrainsMono(
        color: colors['background'],
        fontSize: 10,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      side: BorderSide(color: colors['border']!),
    ),

    iconTheme: IconThemeData(color: colors['primary'], size: 20),

    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {
        TargetPlatform.android: CupertinoPageTransitionsBuilder(),
        TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        TargetPlatform.linux: CupertinoPageTransitionsBuilder(),
        TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
        TargetPlatform.windows: CupertinoPageTransitionsBuilder(),
      },
    ),
  );
}

/// Extension to get JetBrains Mono font easily
extension TextStyleExtension on BuildContext {
  TextStyle get mono => GoogleFonts.jetBrainsMono();

  TextStyle monoStyle({
    double? fontSize,
    FontWeight? fontWeight,
    Color? color,
    double? height,
  }) {
    final theme = Theme.of(this);
    final extension = theme.extension<CyberTermThemeExtension>();
    final defaultColor = extension?.textColor ?? CyberTermColors.textColor;

    return GoogleFonts.jetBrainsMono(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color ?? defaultColor,
      height: height,
    );
  }
}

/// Terminal-style label widget
class TerminalLabel extends StatelessWidget {
  final String label;
  final Color? color;
  final double? fontSize;

  const TerminalLabel(this.label, {super.key, this.color, this.fontSize});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final extension = theme.extension<CyberTermThemeExtension>();
    final defaultColor = extension?.primaryDim ?? CyberTermColors.primaryDim;

    return Text(
      '[$label]',
      style: GoogleFonts.jetBrainsMono(
        color: color ?? defaultColor,
        fontSize: fontSize ?? 10,
        fontWeight: FontWeight.bold,
      ),
    );
  }
}

/// Blinking cursor widget (the signature animated element)
class BlinkingCursor extends StatefulWidget {
  final Color? color;
  final double? fontSize;
  final Duration duration;

  const BlinkingCursor({
    super.key,
    this.color,
    this.fontSize,
    this.duration = const Duration(milliseconds: 530),
  });

  @override
  State<BlinkingCursor> createState() => _BlinkingCursorState();
}

class _BlinkingCursorState extends State<BlinkingCursor>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);
    _animation = Tween<double>(
      begin: 1.0,
      end: 0.2,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
    _controller.repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final extension = theme.extension<CyberTermThemeExtension>();
    final defaultColor = extension?.primary ?? CyberTermColors.primary;

    return FadeTransition(
      opacity: _animation,
      child: Text(
        '█',
        style: GoogleFonts.jetBrainsMono(
          color: widget.color ?? defaultColor,
          fontSize: widget.fontSize ?? 13,
        ),
      ),
    );
  }
}
