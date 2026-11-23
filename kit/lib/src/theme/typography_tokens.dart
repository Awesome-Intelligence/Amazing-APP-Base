// 排版 tokens（5 套风格）。
//
// height 是字号倍数（Flutter 的 TextStyle.height），不是绝对行高 —— 改排版时注意。

import 'package:material_ui/material_ui.dart';

/// Mono 排版。
const TextTheme monoTextTheme = TextTheme(
  displayLarge: TextStyle(fontWeight: FontWeight.w400, height: 1.1228, fontSize: 57, letterSpacing: -0.25),
  displayMedium: TextStyle(fontWeight: FontWeight.w400, height: 1.1556, fontSize: 45, letterSpacing: 0),
  displaySmall: TextStyle(fontWeight: FontWeight.w400, height: 1.2222, fontSize: 36, letterSpacing: 0),
  headlineLarge: TextStyle(fontWeight: FontWeight.w400, height: 1.25, fontSize: 32, letterSpacing: 0),
  headlineMedium: TextStyle(fontWeight: FontWeight.w400, height: 1.2857, fontSize: 28, letterSpacing: 0),
  headlineSmall: TextStyle(fontWeight: FontWeight.w400, height: 1.3333, fontSize: 24, letterSpacing: 0),
  titleLarge: TextStyle(fontWeight: FontWeight.w400, height: 1.2727, fontSize: 22, letterSpacing: 0),
  titleMedium: TextStyle(fontWeight: FontWeight.w500, height: 1.5, fontSize: 16, letterSpacing: 0.15),
  titleSmall: TextStyle(fontWeight: FontWeight.w500, height: 1.4286, fontSize: 14, letterSpacing: 0.1),
  bodyLarge: TextStyle(fontWeight: FontWeight.w400, height: 1.5, fontSize: 16, letterSpacing: 0.5),
  bodyMedium: TextStyle(fontWeight: FontWeight.w400, height: 1.4286, fontSize: 14, letterSpacing: 0.25),
  bodySmall: TextStyle(fontWeight: FontWeight.w400, height: 1.3333, fontSize: 12, letterSpacing: 0.4),
  labelLarge: TextStyle(fontWeight: FontWeight.w500, height: 1.4286, fontSize: 14, letterSpacing: 0.1),
  labelMedium: TextStyle(fontWeight: FontWeight.w500, height: 1.3333, fontSize: 12, letterSpacing: 0.5),
  labelSmall: TextStyle(fontWeight: FontWeight.w500, height: 1.4545, fontSize: 11, letterSpacing: 0.5),
);

/// Swiss 排版。
const TextTheme swissTextTheme = TextTheme(
  displayLarge: TextStyle(fontWeight: FontWeight.w700, height: 0.9773, fontSize: 88, letterSpacing: -2.64),
  displayMedium: TextStyle(fontWeight: FontWeight.w700, height: 1.0, fontSize: 56, letterSpacing: -1.12),
  displaySmall: TextStyle(fontWeight: FontWeight.w700, height: 1.0625, fontSize: 32, letterSpacing: 0),
  headlineLarge: TextStyle(fontWeight: FontWeight.w700, height: 1.0, fontSize: 56, letterSpacing: -1.12),
  headlineMedium: TextStyle(fontWeight: FontWeight.w700, height: 1.0625, fontSize: 32, letterSpacing: 0),
  headlineSmall: TextStyle(fontWeight: FontWeight.w700, height: 1.4, fontSize: 20, letterSpacing: 0),
  titleLarge: TextStyle(fontWeight: FontWeight.w700, height: 1.0625, fontSize: 32, letterSpacing: 0),
  titleMedium: TextStyle(fontWeight: FontWeight.w700, height: 1.4, fontSize: 20, letterSpacing: 0),
  titleSmall: TextStyle(fontWeight: FontWeight.w700, height: 1.3333, fontSize: 15, letterSpacing: 0),
  bodyLarge: TextStyle(fontWeight: FontWeight.w400, height: 1.4, fontSize: 20, letterSpacing: 0),
  bodyMedium: TextStyle(fontWeight: FontWeight.w400, height: 1.4667, fontSize: 15, letterSpacing: 0),
  bodySmall: TextStyle(fontWeight: FontWeight.w400, height: 1.4615, fontSize: 13, letterSpacing: 0),
  labelLarge: TextStyle(fontWeight: FontWeight.w700, height: 1.3077, fontSize: 13, letterSpacing: 1.04),
  labelMedium: TextStyle(fontWeight: FontWeight.w700, height: 1.2727, fontSize: 11, letterSpacing: 0.88),
  labelSmall: TextStyle(fontWeight: FontWeight.w700, height: 1.2727, fontSize: 11, letterSpacing: 0.88),
);

/// Notion 排版。
const TextTheme notionTextTheme = TextTheme(
  displayLarge: TextStyle(fontWeight: FontWeight.w600, height: 1.1875, fontSize: 32, letterSpacing: -0.32),
  displayMedium: TextStyle(fontWeight: FontWeight.w600, height: 1.25, fontSize: 28, letterSpacing: -0.28),
  displaySmall: TextStyle(fontWeight: FontWeight.w600, height: 1.2917, fontSize: 24, letterSpacing: -0.24),
  headlineLarge: TextStyle(fontWeight: FontWeight.w600, height: 1.2917, fontSize: 24, letterSpacing: 0),
  headlineMedium: TextStyle(fontWeight: FontWeight.w600, height: 1.4, fontSize: 20, letterSpacing: 0),
  headlineSmall: TextStyle(fontWeight: FontWeight.w600, height: 1.3889, fontSize: 18, letterSpacing: 0),
  titleLarge: TextStyle(fontWeight: FontWeight.w600, height: 1.3889, fontSize: 18, letterSpacing: 0),
  titleMedium: TextStyle(fontWeight: FontWeight.w500, height: 1.625, fontSize: 16, letterSpacing: 0),
  titleSmall: TextStyle(fontWeight: FontWeight.w500, height: 1.5714, fontSize: 14, letterSpacing: 0),
  bodyLarge: TextStyle(fontWeight: FontWeight.w400, height: 1.625, fontSize: 16, letterSpacing: 0),
  bodyMedium: TextStyle(fontWeight: FontWeight.w400, height: 1.5714, fontSize: 14, letterSpacing: 0),
  bodySmall: TextStyle(fontWeight: FontWeight.w400, height: 1.5833, fontSize: 12, letterSpacing: 0),
  labelLarge: TextStyle(fontWeight: FontWeight.w500, height: 1.4286, fontSize: 14, letterSpacing: 0),
  labelMedium: TextStyle(fontWeight: FontWeight.w500, height: 1.4167, fontSize: 12, letterSpacing: 0.24),
  labelSmall: TextStyle(fontWeight: FontWeight.w500, height: 1.4167, fontSize: 12, letterSpacing: 0.24),
);

/// E-Ink 排版。
const TextTheme eInkTextTheme = TextTheme(
  displayLarge: TextStyle(fontWeight: FontWeight.w600, height: 1.1944, fontSize: 36, letterSpacing: -0.72),
  displayMedium: TextStyle(fontWeight: FontWeight.w600, height: 1.2857, fontSize: 28, letterSpacing: -0.28),
  displaySmall: TextStyle(fontWeight: FontWeight.w500, height: 1.35, fontSize: 20, letterSpacing: 0),
  headlineLarge: TextStyle(fontWeight: FontWeight.w600, height: 1.2857, fontSize: 28, letterSpacing: -0.28),
  headlineMedium: TextStyle(fontWeight: FontWeight.w500, height: 1.35, fontSize: 20, letterSpacing: 0),
  headlineSmall: TextStyle(fontWeight: FontWeight.w500, height: 1.375, fontSize: 16, letterSpacing: 0),
  titleLarge: TextStyle(fontWeight: FontWeight.w500, height: 1.35, fontSize: 20, letterSpacing: 0),
  titleMedium: TextStyle(fontWeight: FontWeight.w600, height: 1.375, fontSize: 16, letterSpacing: 0),
  titleSmall: TextStyle(fontWeight: FontWeight.w600, height: 1.3846, fontSize: 13, letterSpacing: 0),
  bodyLarge: TextStyle(fontWeight: FontWeight.w400, height: 1.5625, fontSize: 16, letterSpacing: 0),
  bodyMedium: TextStyle(fontWeight: FontWeight.w400, height: 1.5385, fontSize: 13, letterSpacing: 0),
  bodySmall: TextStyle(fontWeight: FontWeight.w400, height: 1.5, fontSize: 12, letterSpacing: 0),
  labelLarge: TextStyle(fontWeight: FontWeight.w600, height: 1.4167, fontSize: 12, letterSpacing: 0.72),
  labelMedium: TextStyle(fontWeight: FontWeight.w600, height: 1.4167, fontSize: 12, letterSpacing: 0.72),
  labelSmall: TextStyle(fontWeight: FontWeight.w600, height: 1.3636, fontSize: 11, letterSpacing: 0.66),
);

/// macOS 排版。
const TextTheme macOSTextTheme = TextTheme(
  displayLarge: TextStyle(fontWeight: FontWeight.w700, fontFamily: 'serif', height: 1.15, fontSize: 40, letterSpacing: -0.4),
  displayMedium: TextStyle(fontWeight: FontWeight.w700, fontFamily: 'serif', height: 1.25, fontSize: 32, letterSpacing: 0),
  displaySmall: TextStyle(fontWeight: FontWeight.w400, fontFamily: 'serif', height: 1.25, fontSize: 24, letterSpacing: 0),
  headlineLarge: TextStyle(fontWeight: FontWeight.w400, fontFamily: 'serif', height: 1.25, fontSize: 32, letterSpacing: 0),
  headlineMedium: TextStyle(fontWeight: FontWeight.w400, fontFamily: 'serif', height: 1.25, fontSize: 24, letterSpacing: 0),
  headlineSmall: TextStyle(fontWeight: FontWeight.w600, height: 1.2941, fontSize: 17, letterSpacing: 0),
  titleLarge: TextStyle(fontWeight: FontWeight.w600, height: 1.2941, fontSize: 17, letterSpacing: 0),
  titleMedium: TextStyle(fontWeight: FontWeight.w600, height: 1.3333, fontSize: 15, letterSpacing: 0),
  titleSmall: TextStyle(fontWeight: FontWeight.w500, height: 1.3846, fontSize: 13, letterSpacing: 0),
  bodyLarge: TextStyle(fontWeight: FontWeight.w400, height: 1.4667, fontSize: 15, letterSpacing: 0),
  bodyMedium: TextStyle(fontWeight: FontWeight.w400, height: 1.5385, fontSize: 13, letterSpacing: 0),
  bodySmall: TextStyle(fontWeight: FontWeight.w400, height: 1.4545, fontSize: 11, letterSpacing: 0),
  labelLarge: TextStyle(fontWeight: FontWeight.w500, height: 1.3846, fontSize: 13, letterSpacing: 0),
  labelMedium: TextStyle(fontWeight: FontWeight.w500, height: 1.3636, fontSize: 11, letterSpacing: 0.22),
  labelSmall: TextStyle(fontWeight: FontWeight.w500, height: 1.3636, fontSize: 11, letterSpacing: 0.22),
);
