// ColorScheme（5 套风格 × 深浅）。
// 改色值请连同 palettes.dart 一起改，两边对不上会出「组件一个色、页面另一个色」。
// 源：palettes.dart（色板 + 标签色板）
//
// 槽位映射：inverseOnSurface -> onInverseSurface；
// background / onBackground / surfaceVariant 在 Flutter 已废弃，
// 但它们与 surface / onSurface / surfaceContainerHighest **取值不同**，
// 所以单独放 ColorSchemeExtras，避免页面底色和卡片底色被抹平成同一个色。

import 'dart:ui' show Color;

import 'package:material_ui/material_ui.dart' show Brightness, ColorScheme;

import 'palettes.dart';

/// Flutter ColorScheme 已废弃、但主题里独立取值的三项。
class ColorSchemeExtras {
  const ColorSchemeExtras({
    required this.background,
    required this.onBackground,
    required this.surfaceVariant,
  });

  /// 页面底色（对应 `colorScheme.background`）。
  final Color background;

  /// 页面底色上的文字色。
  final Color onBackground;

  /// `surfaceVariant`（Flutter 建议改用 surfaceContainerHighest）。
  final Color surfaceVariant;
}

/// 浅色配色方案。
const ColorScheme monoLightScheme = ColorScheme(
  brightness: Brightness.light,
  primary: Mono.primaryLight,
  onPrimary: Mono.onPrimaryLight,
  primaryContainer: Mono.primaryContainerLight,
  onPrimaryContainer: Mono.onPrimaryContainerLight,
  secondary: Mono.secondaryLight,
  onSecondary: Mono.onSecondaryLight,
  secondaryContainer: Mono.secondaryContainerLight,
  onSecondaryContainer: Mono.onSecondaryContainerLight,
  tertiary: Mono.tertiaryLight,
  onTertiary: Mono.onTertiaryLight,
  tertiaryContainer: Mono.tertiaryContainerLight,
  onTertiaryContainer: Mono.onTertiaryContainerLight,
  error: Mono.errorLight,
  onError: Mono.onErrorLight,
  errorContainer: Mono.errorContainerLight,
  onErrorContainer: Mono.onErrorContainerLight,
  surface: Mono.surfaceLight,
  onSurface: Mono.onSurfaceLight,
  onSurfaceVariant: Mono.onSurfaceVariantLight,
  surfaceDim: Mono.surfaceDimLight,
  surfaceBright: Mono.surfaceBrightLight,
  surfaceContainerLowest: Mono.surfaceContainerLowestLight,
  surfaceContainerLow: Mono.surfaceContainerLowLight,
  surfaceContainer: Mono.surfaceContainerLight,
  surfaceContainerHigh: Mono.surfaceContainerHighLight,
  surfaceContainerHighest: Mono.surfaceContainerHighestLight,
  outline: Mono.outlineLight,
  outlineVariant: Mono.outlineVariantLight,
  scrim: Mono.scrimLight,
  inverseSurface: Mono.inverseSurfaceLight,
  inversePrimary: Mono.inversePrimaryLight,
  surfaceTint: Mono.outlineLight,
  onInverseSurface: Mono.inverseOnSurfaceLight,
);

const ColorSchemeExtras monoLightSchemeExtras = ColorSchemeExtras(
  background: Mono.backgroundLight,
  onBackground: Mono.onBackgroundLight,
  surfaceVariant: Mono.surfaceVariantLight,
);

/// 深色配色方案。
const ColorScheme monoDarkScheme = ColorScheme(
  brightness: Brightness.dark,
  primary: Mono.primaryDark,
  onPrimary: Mono.onPrimaryDark,
  primaryContainer: Mono.primaryContainerDark,
  onPrimaryContainer: Mono.onPrimaryContainerDark,
  secondary: Mono.secondaryDark,
  onSecondary: Mono.onSecondaryDark,
  secondaryContainer: Mono.secondaryContainerDark,
  onSecondaryContainer: Mono.onSecondaryContainerDark,
  tertiary: Mono.tertiaryDark,
  onTertiary: Mono.onTertiaryDark,
  tertiaryContainer: Mono.tertiaryContainerDark,
  onTertiaryContainer: Mono.onTertiaryContainerDark,
  error: Mono.errorDark,
  onError: Mono.onErrorDark,
  errorContainer: Mono.errorContainerDark,
  onErrorContainer: Mono.onErrorContainerDark,
  surface: Mono.surfaceDark,
  onSurface: Mono.onSurfaceDark,
  onSurfaceVariant: Mono.onSurfaceVariantDark,
  surfaceDim: Mono.surfaceDimDark,
  surfaceBright: Mono.surfaceBrightDark,
  surfaceContainerLowest: Mono.surfaceContainerLowestDark,
  surfaceContainerLow: Mono.surfaceContainerLowDark,
  surfaceContainer: Mono.surfaceContainerDark,
  surfaceContainerHigh: Mono.surfaceContainerHighDark,
  surfaceContainerHighest: Mono.surfaceContainerHighestDark,
  outline: Mono.outlineDark,
  outlineVariant: Mono.outlineVariantDark,
  scrim: Mono.scrimDark,
  inverseSurface: Mono.inverseSurfaceDark,
  inversePrimary: Mono.inversePrimaryDark,
  surfaceTint: Mono.outlineDark,
  onInverseSurface: Mono.inverseOnSurfaceDark,
);

const ColorSchemeExtras monoDarkSchemeExtras = ColorSchemeExtras(
  background: Mono.backgroundDark,
  onBackground: Mono.onBackgroundDark,
  surfaceVariant: Mono.surfaceVariantDark,
);

/// Swiss 浅色配色方案。
const ColorScheme swissLightColorScheme = ColorScheme(
  brightness: Brightness.light,
  primary: Swiss.primaryLight,
  onPrimary: Swiss.onPrimaryLight,
  primaryContainer: Swiss.primaryContainerLight,
  onPrimaryContainer: Swiss.onPrimaryContainerLight,
  secondary: Swiss.secondaryLight,
  onSecondary: Swiss.onSecondaryLight,
  secondaryContainer: Swiss.secondaryContainerLight,
  onSecondaryContainer: Swiss.onSecondaryContainerLight,
  tertiary: Swiss.tertiaryLight,
  onTertiary: Swiss.onTertiaryLight,
  tertiaryContainer: Swiss.tertiaryContainerLight,
  onTertiaryContainer: Swiss.onTertiaryContainerLight,
  error: Swiss.errorLight,
  onError: Swiss.onErrorLight,
  errorContainer: Swiss.errorContainerLight,
  onErrorContainer: Swiss.onErrorContainerLight,
  surface: Swiss.surfaceLight,
  onSurface: Swiss.onSurfaceLight,
  onSurfaceVariant: Swiss.onSurfaceVariantLight,
  surfaceDim: Swiss.surfaceDimLight,
  surfaceBright: Swiss.surfaceBrightLight,
  surfaceContainerLowest: Swiss.surfaceContainerLowestLight,
  surfaceContainerLow: Swiss.surfaceContainerLowLight,
  surfaceContainer: Swiss.surfaceContainerLight,
  surfaceContainerHigh: Swiss.surfaceContainerHighLight,
  surfaceContainerHighest: Swiss.surfaceContainerHighestLight,
  outline: Swiss.outlineLight,
  outlineVariant: Swiss.outlineVariantLight,
  scrim: Swiss.scrimLight,
  inverseSurface: Swiss.inverseSurfaceLight,
  inversePrimary: Swiss.inversePrimaryLight,
  surfaceTint: Swiss.surfaceTintLight,
  onInverseSurface: Swiss.inverseOnSurfaceLight,
);

const ColorSchemeExtras swissLightColorSchemeExtras = ColorSchemeExtras(
  background: Swiss.backgroundLight,
  onBackground: Swiss.onBackgroundLight,
  surfaceVariant: Swiss.surfaceVariantLight,
);

/// Swiss 深色配色方案。
const ColorScheme swissDarkColorScheme = ColorScheme(
  brightness: Brightness.dark,
  primary: Swiss.primaryDark,
  onPrimary: Swiss.onPrimaryDark,
  primaryContainer: Swiss.primaryContainerDark,
  onPrimaryContainer: Swiss.onPrimaryContainerDark,
  secondary: Swiss.secondaryDark,
  onSecondary: Swiss.onSecondaryDark,
  secondaryContainer: Swiss.secondaryContainerDark,
  onSecondaryContainer: Swiss.onSecondaryContainerDark,
  tertiary: Swiss.tertiaryDark,
  onTertiary: Swiss.onTertiaryDark,
  tertiaryContainer: Swiss.tertiaryContainerDark,
  onTertiaryContainer: Swiss.onTertiaryContainerDark,
  error: Swiss.errorDark,
  onError: Swiss.onErrorDark,
  errorContainer: Swiss.errorContainerDark,
  onErrorContainer: Swiss.onErrorContainerDark,
  surface: Swiss.surfaceDark,
  onSurface: Swiss.onSurfaceDark,
  onSurfaceVariant: Swiss.onSurfaceVariantDark,
  surfaceDim: Swiss.surfaceDimDark,
  surfaceBright: Swiss.surfaceBrightDark,
  surfaceContainerLowest: Swiss.surfaceContainerLowestDark,
  surfaceContainerLow: Swiss.surfaceContainerLowDark,
  surfaceContainer: Swiss.surfaceContainerDark,
  surfaceContainerHigh: Swiss.surfaceContainerHighDark,
  surfaceContainerHighest: Swiss.surfaceContainerHighestDark,
  outline: Swiss.outlineDark,
  outlineVariant: Swiss.outlineVariantDark,
  scrim: Swiss.scrimDark,
  inverseSurface: Swiss.inverseSurfaceDark,
  inversePrimary: Swiss.inversePrimaryDark,
  surfaceTint: Swiss.surfaceTintDark,
  onInverseSurface: Swiss.inverseOnSurfaceDark,
);

const ColorSchemeExtras swissDarkColorSchemeExtras = ColorSchemeExtras(
  background: Swiss.backgroundDark,
  onBackground: Swiss.onBackgroundDark,
  surfaceVariant: Swiss.surfaceVariantDark,
);

/// Notion 浅色配色方案。
const ColorScheme notionLightColorScheme = ColorScheme(
  brightness: Brightness.light,
  primary: Notion.primaryLight,
  onPrimary: Notion.onPrimaryLight,
  primaryContainer: Notion.primaryContainerLight,
  onPrimaryContainer: Notion.onPrimaryContainerLight,
  secondary: Notion.secondaryLight,
  onSecondary: Notion.onSecondaryLight,
  secondaryContainer: Notion.secondaryContainerLight,
  onSecondaryContainer: Notion.onSecondaryContainerLight,
  tertiary: Notion.tertiaryLight,
  onTertiary: Notion.onTertiaryLight,
  tertiaryContainer: Notion.tertiaryContainerLight,
  onTertiaryContainer: Notion.onTertiaryContainerLight,
  error: Notion.errorLight,
  onError: Notion.onErrorLight,
  errorContainer: Notion.errorContainerLight,
  onErrorContainer: Notion.onErrorContainerLight,
  surface: Notion.surfaceLight,
  onSurface: Notion.onSurfaceLight,
  onSurfaceVariant: Notion.onSurfaceVariantLight,
  surfaceDim: Notion.surfaceDimLight,
  surfaceBright: Notion.surfaceBrightLight,
  surfaceContainerLowest: Notion.surfaceContainerLowestLight,
  surfaceContainerLow: Notion.surfaceContainerLowLight,
  surfaceContainer: Notion.surfaceContainerLight,
  surfaceContainerHigh: Notion.surfaceContainerHighLight,
  surfaceContainerHighest: Notion.surfaceContainerHighestLight,
  outline: Notion.outlineLight,
  outlineVariant: Notion.outlineVariantLight,
  scrim: Notion.scrimLight,
  inverseSurface: Notion.inverseSurfaceLight,
  inversePrimary: Notion.inversePrimaryLight,
  surfaceTint: Notion.surfaceTintLight,
  onInverseSurface: Notion.inverseOnSurfaceLight,
);

const ColorSchemeExtras notionLightColorSchemeExtras = ColorSchemeExtras(
  background: Notion.backgroundLight,
  onBackground: Notion.onBackgroundLight,
  surfaceVariant: Notion.surfaceVariantLight,
);

/// Notion 深色配色方案。
const ColorScheme notionDarkColorScheme = ColorScheme(
  brightness: Brightness.dark,
  primary: Notion.primaryDark,
  onPrimary: Notion.onPrimaryDark,
  primaryContainer: Notion.primaryContainerDark,
  onPrimaryContainer: Notion.onPrimaryContainerDark,
  secondary: Notion.secondaryDark,
  onSecondary: Notion.onSecondaryDark,
  secondaryContainer: Notion.secondaryContainerDark,
  onSecondaryContainer: Notion.onSecondaryContainerDark,
  tertiary: Notion.tertiaryDark,
  onTertiary: Notion.onTertiaryDark,
  tertiaryContainer: Notion.tertiaryContainerDark,
  onTertiaryContainer: Notion.onTertiaryContainerDark,
  error: Notion.errorDark,
  onError: Notion.onErrorDark,
  errorContainer: Notion.errorContainerDark,
  onErrorContainer: Notion.onErrorContainerDark,
  surface: Notion.surfaceDark,
  onSurface: Notion.onSurfaceDark,
  onSurfaceVariant: Notion.onSurfaceVariantDark,
  surfaceDim: Notion.surfaceDimDark,
  surfaceBright: Notion.surfaceBrightDark,
  surfaceContainerLowest: Notion.surfaceContainerLowestDark,
  surfaceContainerLow: Notion.surfaceContainerLowDark,
  surfaceContainer: Notion.surfaceContainerDark,
  surfaceContainerHigh: Notion.surfaceContainerHighDark,
  surfaceContainerHighest: Notion.surfaceContainerHighestDark,
  outline: Notion.outlineDark,
  outlineVariant: Notion.outlineVariantDark,
  scrim: Notion.scrimDark,
  inverseSurface: Notion.inverseSurfaceDark,
  inversePrimary: Notion.inversePrimaryDark,
  surfaceTint: Notion.surfaceTintDark,
  onInverseSurface: Notion.inverseOnSurfaceDark,
);

const ColorSchemeExtras notionDarkColorSchemeExtras = ColorSchemeExtras(
  background: Notion.backgroundDark,
  onBackground: Notion.onBackgroundDark,
  surfaceVariant: Notion.surfaceVariantDark,
);

/// E-Ink 浅色配色方案。
const ColorScheme eInkLightColorScheme = ColorScheme(
  brightness: Brightness.light,
  primary: EInk.primaryLight,
  onPrimary: EInk.onPrimaryLight,
  primaryContainer: EInk.primaryContainerLight,
  onPrimaryContainer: EInk.onPrimaryContainerLight,
  secondary: EInk.secondaryLight,
  onSecondary: EInk.onSecondaryLight,
  secondaryContainer: EInk.secondaryContainerLight,
  onSecondaryContainer: EInk.onSecondaryContainerLight,
  tertiary: EInk.tertiaryLight,
  onTertiary: EInk.onTertiaryLight,
  tertiaryContainer: EInk.tertiaryContainerLight,
  onTertiaryContainer: EInk.onTertiaryContainerLight,
  error: EInk.errorLight,
  onError: EInk.onErrorLight,
  errorContainer: EInk.errorContainerLight,
  onErrorContainer: EInk.onErrorContainerLight,
  surface: EInk.surfaceLight,
  onSurface: EInk.onSurfaceLight,
  onSurfaceVariant: EInk.onSurfaceVariantLight,
  surfaceDim: EInk.surfaceDimLight,
  surfaceBright: EInk.surfaceBrightLight,
  surfaceContainerLowest: EInk.surfaceContainerLowestLight,
  surfaceContainerLow: EInk.surfaceContainerLowLight,
  surfaceContainer: EInk.surfaceContainerLight,
  surfaceContainerHigh: EInk.surfaceContainerHighLight,
  surfaceContainerHighest: EInk.surfaceContainerHighestLight,
  outline: EInk.outlineLight,
  outlineVariant: EInk.outlineVariantLight,
  scrim: EInk.scrimLight,
  inverseSurface: EInk.inverseSurfaceLight,
  inversePrimary: EInk.inversePrimaryLight,
  surfaceTint: EInk.surfaceTintLight,
  onInverseSurface: EInk.inverseOnSurfaceLight,
);

const ColorSchemeExtras eInkLightColorSchemeExtras = ColorSchemeExtras(
  background: EInk.backgroundLight,
  onBackground: EInk.onBackgroundLight,
  surfaceVariant: EInk.surfaceVariantLight,
);

/// E-Ink 深色配色方案。
const ColorScheme eInkDarkColorScheme = ColorScheme(
  brightness: Brightness.dark,
  primary: EInk.primaryDark,
  onPrimary: EInk.onPrimaryDark,
  primaryContainer: EInk.primaryContainerDark,
  onPrimaryContainer: EInk.onPrimaryContainerDark,
  secondary: EInk.secondaryDark,
  onSecondary: EInk.onSecondaryDark,
  secondaryContainer: EInk.secondaryContainerDark,
  onSecondaryContainer: EInk.onSecondaryContainerDark,
  tertiary: EInk.tertiaryDark,
  onTertiary: EInk.onTertiaryDark,
  tertiaryContainer: EInk.tertiaryContainerDark,
  onTertiaryContainer: EInk.onTertiaryContainerDark,
  error: EInk.errorDark,
  onError: EInk.onErrorDark,
  errorContainer: EInk.errorContainerDark,
  onErrorContainer: EInk.onErrorContainerDark,
  surface: EInk.surfaceDark,
  onSurface: EInk.onSurfaceDark,
  onSurfaceVariant: EInk.onSurfaceVariantDark,
  surfaceDim: EInk.surfaceDimDark,
  surfaceBright: EInk.surfaceBrightDark,
  surfaceContainerLowest: EInk.surfaceContainerLowestDark,
  surfaceContainerLow: EInk.surfaceContainerLowDark,
  surfaceContainer: EInk.surfaceContainerDark,
  surfaceContainerHigh: EInk.surfaceContainerHighDark,
  surfaceContainerHighest: EInk.surfaceContainerHighestDark,
  outline: EInk.outlineDark,
  outlineVariant: EInk.outlineVariantDark,
  scrim: EInk.scrimDark,
  inverseSurface: EInk.inverseSurfaceDark,
  inversePrimary: EInk.inversePrimaryDark,
  surfaceTint: EInk.surfaceTintDark,
  onInverseSurface: EInk.inverseOnSurfaceDark,
);

const ColorSchemeExtras eInkDarkColorSchemeExtras = ColorSchemeExtras(
  background: EInk.backgroundDark,
  onBackground: EInk.onBackgroundDark,
  surfaceVariant: EInk.surfaceVariantDark,
);

/// macOS 深色配色方案。
const ColorScheme macOSDarkColorScheme = ColorScheme(
  brightness: Brightness.dark,
  primary: MacOS.primaryDark,
  onPrimary: MacOS.onPrimaryDark,
  primaryContainer: MacOS.primaryContainerDark,
  onPrimaryContainer: MacOS.onPrimaryContainerDark,
  secondary: MacOS.secondaryDark,
  onSecondary: MacOS.onSecondaryDark,
  secondaryContainer: MacOS.secondaryContainerDark,
  onSecondaryContainer: MacOS.onSecondaryContainerDark,
  tertiary: MacOS.tertiaryDark,
  onTertiary: MacOS.onTertiaryDark,
  tertiaryContainer: MacOS.tertiaryContainerDark,
  onTertiaryContainer: MacOS.onTertiaryContainerDark,
  error: MacOS.errorDark,
  onError: MacOS.onErrorDark,
  errorContainer: MacOS.errorContainerDark,
  onErrorContainer: MacOS.onErrorContainerDark,
  surface: MacOS.surfaceDark,
  onSurface: MacOS.onSurfaceDark,
  onSurfaceVariant: MacOS.onSurfaceVariantDark,
  surfaceDim: MacOS.surfaceDimDark,
  surfaceBright: MacOS.surfaceBrightDark,
  surfaceContainerLowest: MacOS.surfaceContainerLowestDark,
  surfaceContainerLow: MacOS.surfaceContainerLowDark,
  surfaceContainer: MacOS.surfaceContainerDark,
  surfaceContainerHigh: MacOS.surfaceContainerHighDark,
  surfaceContainerHighest: MacOS.surfaceContainerHighestDark,
  outline: MacOS.outlineDark,
  outlineVariant: MacOS.outlineVariantDark,
  scrim: MacOS.scrimDark,
  inverseSurface: MacOS.inverseSurfaceDark,
  inversePrimary: MacOS.inversePrimaryDark,
  surfaceTint: MacOS.surfaceTintDark,
  onInverseSurface: MacOS.inverseOnSurfaceDark,
);

const ColorSchemeExtras macOSDarkColorSchemeExtras = ColorSchemeExtras(
  background: MacOS.backgroundDark,
  onBackground: MacOS.onBackgroundDark,
  surfaceVariant: MacOS.surfaceVariantDark,
);

/// macOS 浅色配色方案。
const ColorScheme macOSLightColorScheme = ColorScheme(
  brightness: Brightness.light,
  primary: MacOS.primaryLight,
  onPrimary: MacOS.onPrimaryLight,
  primaryContainer: MacOS.primaryContainerLight,
  onPrimaryContainer: MacOS.onPrimaryContainerLight,
  secondary: MacOS.secondaryLight,
  onSecondary: MacOS.onSecondaryLight,
  secondaryContainer: MacOS.secondaryContainerLight,
  onSecondaryContainer: MacOS.onSecondaryContainerLight,
  tertiary: MacOS.tertiaryLight,
  onTertiary: MacOS.onTertiaryLight,
  tertiaryContainer: MacOS.tertiaryContainerLight,
  onTertiaryContainer: MacOS.onTertiaryContainerLight,
  error: MacOS.errorLight,
  onError: MacOS.onErrorLight,
  errorContainer: MacOS.errorContainerLight,
  onErrorContainer: MacOS.onErrorContainerLight,
  surface: MacOS.surfaceLight,
  onSurface: MacOS.onSurfaceLight,
  onSurfaceVariant: MacOS.onSurfaceVariantLight,
  surfaceDim: MacOS.surfaceDimLight,
  surfaceBright: MacOS.surfaceBrightLight,
  surfaceContainerLowest: MacOS.surfaceContainerLowestLight,
  surfaceContainerLow: MacOS.surfaceContainerLowLight,
  surfaceContainer: MacOS.surfaceContainerLight,
  surfaceContainerHigh: MacOS.surfaceContainerHighLight,
  surfaceContainerHighest: MacOS.surfaceContainerHighestLight,
  outline: MacOS.outlineLight,
  outlineVariant: MacOS.outlineVariantLight,
  scrim: MacOS.scrimLight,
  inverseSurface: MacOS.inverseSurfaceLight,
  inversePrimary: MacOS.inversePrimaryLight,
  surfaceTint: MacOS.surfaceTintLight,
  onInverseSurface: MacOS.inverseOnSurfaceLight,
);

const ColorSchemeExtras macOSLightColorSchemeExtras = ColorSchemeExtras(
  background: MacOS.backgroundLight,
  onBackground: MacOS.onBackgroundLight,
  surfaceVariant: MacOS.surfaceVariantLight,
);

// ── 标签色板（6 个核心色调）──────────────────────────────
/// 色板键名顺序即标签色板顺序，neutral 是默认色。
const List<String> tagColorNames = <String>[
  'neutral',
  'rose',
  'sage',
  'mauve',
  'clay',
  'slate',
];

/// 浅色标签色板。
const Map<String, Color> lightTagColors = <String, Color>{
  'neutral': Color(0xFF5A5A5A),
  'rose': Color(0xFFB87070),
  'sage': Color(0xFF5B7A5B),
  'mauve': Color(0xFF8B6B8B),
  'clay': Color(0xFFAD7A5A),
  'slate': Color(0xFF6B7A8A),
};

/// 深色标签色板。
const Map<String, Color> darkTagColors = <String, Color>{
  'neutral': Color(0xFFA0A0A0),
  'rose': Color(0xFFD0A0A0),
  'sage': Color(0xFFB0C9A0),
  'mauve': Color(0xFFD0A8D0),
  'clay': Color(0xFFD8B8A0),
  'slate': Color(0xFFA0B8C8),
};

/// Swiss 浅色标签色板。
const Map<String, Color> swissLightTagColors = <String, Color>{
  'neutral': Color(0xFF000000),
  'rose': Swiss.redInk,
  'sage': Color(0xFF1B7A4B),
  'mauve': Color(0xFF5C3D91),
  'clay': Color(0xFF8A5A00),
  'slate': Color(0xFF0057B8),
};

/// Swiss 深色标签色板。
const Map<String, Color> swissDarkTagColors = <String, Color>{
  'neutral': Color(0xFFFFFFFF),
  'rose': Color(0xFFFF6B6B),
  'sage': Color(0xFF6BCB96),
  'mauve': Color(0xFFB79BEA),
  'clay': Color(0xFFE8B84B),
  'slate': Color(0xFF7FB0F0),
};

/// Notion 浅色标签色板。
const Map<String, Color> notionLightTagColors = <String, Color>{
  'neutral': Color(0xFF6B6A67),
  'rose': Color(0xFFB04A44),
  'sage': Color(0xFF0F7B6C),
  'mauve': Color(0xFF6D4AD8),
  'clay': Color(0xFFA06A2C),
  'slate': Color(0xFF1B6F96),
};

/// Notion 深色标签色板。
const Map<String, Color> notionDarkTagColors = <String, Color>{
  'neutral': Color(0xFFA8A6A3),
  'rose': Color(0xFFE08A84),
  'sage': Color(0xFF4FBFAE),
  'mauve': Color(0xFFB39CF0),
  'clay': Color(0xFFD99A5B),
  'slate': Color(0xFF6FB6DD),
};

/// E-Ink 浅色标签色板。
const Map<String, Color> eInkLightTagColors = <String, Color>{
  'neutral': Color(0xFF555750),
  'rose': Color(0xFF5E5F57),
  'sage': Color(0xFF67685F),
  'mauve': Color(0xFF707167),
  'clay': Color(0xFF797A6F),
  'slate': Color(0xFF828377),
};

/// E-Ink 深色标签色板。
const Map<String, Color> eInkDarkTagColors = <String, Color>{
  'neutral': Color(0xFFBAB9B0),
  'rose': Color(0xFFADACA2),
  'sage': Color(0xFFA0A096),
  'mauve': Color(0xFF939389),
  'clay': Color(0xFF86857C),
  'slate': Color(0xFF797870),
};

/// macOS 深色标签色板。
const Map<String, Color> macOSDarkTagColors = <String, Color>{
  'neutral': Color(0xFFAEAEAE),
  'rose': Color(0xFFFF6961),
  'sage': Color(0xFF30D158),
  'mauve': Color(0xFFBF5AF2),
  'clay': Color(0xFFFF9F0A),
  'slate': Color(0xFF64D2FF),
};

/// macOS 浅色标签色板。
const Map<String, Color> macOSLightTagColors = <String, Color>{
  'neutral': Color(0xFF6E6E73),
  'rose': Color(0xFFD70015),
  'sage': Color(0xFF1E7A34),
  'mauve': Color(0xFF8944AB),
  'clay': Color(0xFFC93400),
  'slate': Color(0xFF0071E3),
};
