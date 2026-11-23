import 'dart:ui' show Color;

import 'package:material_ui/material_ui.dart' show ColorScheme, TextTheme;

import '../settings/theme_enums.dart' show ThemeStyle;
import 'color_schemes.dart';
import 'extended_colors.dart';
import 'kit_shapes.dart';
import 'palettes.dart';
import 'typography_tokens.dart';

/// 一套完整主题的「四轴 + 三个开关」。
///
/// 底座预置的 [monoThemeTokens] / [swissThemeTokens] 等
/// 只是几套**预设**；App 要做自己的品牌，就在自己的模块里造一个 [ThemeTokens]，
/// **不用改 kit**：
///
/// ```dart
/// // apps/<name>/theme/brand_theme.dart
/// ThemeTokens brandLight() => themeTokens(
///   colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF00696D)),
///   isDark: false,
/// );
///
/// KitApp(tokens: ...) // 或 AppTheme + kitThemeData
/// ```
///
/// 四个轴：颜色 / 扩展语义色 / 排版 / 形状。三个开关：明暗、主题风格、圆角。
/// [tagColors] 留空时按 [themeStyle] 取底座色板（品牌色板自己传）。
class ThemeTokens {
  const ThemeTokens({
    required this.colorScheme,
    required this.extras,
    required this.extendedColors,
    required this.textTheme,
    required this.shapes,
    required this.isDark,
    this.themeStyle = ThemeStyle.mono,
    this.cornerStyle = CornerStyle.rounded,
    this.tagColors = const <String, Color>{},
  });

  /// Material 3 的颜色槽位。
  final ColorScheme colorScheme;

  /// Flutter 已废弃、但主题里独立取值的三项（页面底色等）。
  final ColorSchemeExtras extras;

  /// M3 之外的语义色（success / warning / aiAccent / star…）。
  final ExtendedColors extendedColors;

  /// 字号 / 行高 / 字距。
  final TextTheme textTheme;

  /// 圆角桶。
  final KitShapes shapes;

  /// 这套 tokens 是深色还是浅色 —— 组件靠它选透明度/色阶。
  final bool isDark;

  /// 主题风格开关：影响「风格化」组件的色调分发（Swiss 卡片底色等）。
  final ThemeStyle themeStyle;

  /// 圆角风格：[themedCorner] 用它，而不是只看 [themeStyle]。
  final CornerStyle cornerStyle;

  /// 标签色板（键：neutral / rose / sage / mauve / clay / slate）。
  /// 留空 = 按 [themeStyle] + [isDark] 取底座色板。
  final Map<String, Color> tagColors;

  /// 取标签色；没有该键就回落到 neutral。
  Color tagColor(String name) {
    final palette = tagColors.isEmpty ? tagColorsFor(themeStyle, isDark) : tagColors;
    return palette[name.toLowerCase()] ?? palette['neutral'] ?? colorScheme.onSurfaceVariant;
  }
}

/// 造一套自定义主题的便捷入口 —— 只传颜色也能跑，其余轴走合理默认值。
///
/// 默认值刻意选「不抢品牌」的：Mono 排版 / M3 圆角 / Mono 扩展语义色。
/// 品牌有自己的一套就显式传；没有就先跑起来，后面再逐轴替换。
///
/// [isDark] 是「这套色板是深色还是浅色」，不是「当前系统是不是深色」，别传错。
ThemeTokens themeTokens({
  required ColorScheme colorScheme,
  required bool isDark,
  ExtendedColors? extendedColors,
  TextTheme? textTheme,
  KitShapes? shapes,
  CornerStyle cornerStyle = CornerStyle.rounded,
  Map<String, Color> tagColors = const <String, Color>{},
}) {
  return ThemeTokens(
    colorScheme: colorScheme,
    extras: ColorSchemeExtras(
      background: colorScheme.surface,
      onBackground: colorScheme.onSurface,
      surfaceVariant: colorScheme.surfaceContainerHighest,
    ),
    extendedColors: extendedColors ?? (isDark ? DarkExtended : LightExtended),
    textTheme: textTheme ?? monoTextTheme,
    shapes: shapes ?? KitShapes.m3,
    isDark: isDark,
    themeStyle: ThemeStyle.mono,
    cornerStyle: cornerStyle,
    tagColors: tagColors,
  );
}

/// 按「主题风格 + 明暗」取对应的标签色板。
Map<String, Color> tagColorsFor(ThemeStyle style, bool isDark) => switch (style) {
      ThemeStyle.swiss => isDark ? swissDarkTagColors : swissLightTagColors,
      ThemeStyle.notion => isDark ? notionDarkTagColors : notionLightTagColors,
      ThemeStyle.eInk => isDark ? eInkDarkTagColors : eInkLightTagColors,
      ThemeStyle.macOS => isDark ? macOSDarkTagColors : macOSLightTagColors,
      ThemeStyle.mono => isDark ? darkTagColors : lightTagColors,
    };

/// 按风格取预设 tokens。
ThemeTokens tokensFor(ThemeStyle style, bool isDark) => switch (style) {
      ThemeStyle.mono => monoThemeTokens(isDark),
      ThemeStyle.swiss => swissThemeTokens(isDark),
      ThemeStyle.notion => notionThemeTokens(isDark),
      ThemeStyle.eInk => eInkThemeTokens(isDark),
      ThemeStyle.macOS => macOSThemeTokens(isDark),
    };

/// 底座预置：Mono（暖中性单色 + M3 动效）。默认主题。
///
/// App 层想微调品牌色，可以拿它当基底再 copy。
ThemeTokens monoThemeTokens(bool isDark) => ThemeTokens(
      colorScheme: isDark ? monoDarkScheme : monoLightScheme,
      extras: isDark ? monoDarkSchemeExtras : monoLightSchemeExtras,
      extendedColors: isDark ? DarkExtended : LightExtended,
      textTheme: monoTextTheme,
      shapes: KitShapes.m3,
      isDark: isDark,
      themeStyle: ThemeStyle.mono,
      cornerStyle: CornerStyle.rounded,
      tagColors: tagColorsFor(ThemeStyle.mono, isDark),
    );

/// 底座预置：Swiss（瑞士国际风格）。
///
/// 黑白画布 + 信号红强调、全直角、只变色。规范只给了浅色，深色版是自建的语义反转。
ThemeTokens swissThemeTokens(bool isDark) => ThemeTokens(
      colorScheme: isDark ? swissDarkColorScheme : swissLightColorScheme,
      extras: isDark ? swissDarkColorSchemeExtras : swissLightColorSchemeExtras,
      extendedColors: isDark ? SwissDarkExtended : SwissLightExtended,
      textTheme: swissTextTheme,
      shapes: KitShapes.square,
      isDark: isDark,
      themeStyle: ThemeStyle.swiss,
      cornerStyle: CornerStyle.square,
      tagColors: tagColorsFor(ThemeStyle.swiss, isDark),
    );

/// 底座预置：Notion（文档工具风格）。
///
/// 米色纸面 + 暖墨字 + 发丝线，4px 圆角，只变色（不位移、不缩放）。
ThemeTokens notionThemeTokens(bool isDark) => ThemeTokens(
      colorScheme: isDark ? notionDarkColorScheme : notionLightColorScheme,
      extras: isDark ? notionDarkColorSchemeExtras : notionLightColorSchemeExtras,
      extendedColors: isDark ? NotionDarkExtended : NotionLightExtended,
      textTheme: notionTextTheme,
      shapes: KitShapes.notion,
      isDark: isDark,
      themeStyle: ThemeStyle.notion,
      cornerStyle: CornerStyle.rounded,
      tagColors: tagColorsFor(ThemeStyle.notion, isDark),
    );

/// 底座预置：E-Ink（电子纸）。
///
/// 暖纸底 + 墨色 + 三档灰阶、全直角、等宽数值、只变色。
ThemeTokens eInkThemeTokens(bool isDark) => ThemeTokens(
      colorScheme: isDark ? eInkDarkColorScheme : eInkLightColorScheme,
      extras: isDark ? eInkDarkColorSchemeExtras : eInkLightColorSchemeExtras,
      extendedColors: isDark ? EInkDarkExtended : EInkLightExtended,
      textTheme: eInkTextTheme,
      shapes: KitShapes.square,
      isDark: isDark,
      themeStyle: ThemeStyle.eInk,
      cornerStyle: CornerStyle.square,
      tagColors: tagColorsFor(ThemeStyle.eInk, isDark),
    );

/// 底座预置：macOS 毛玻璃（vibrancy）。
///
/// 三档灰定层次，系统蓝是唯一强调色，圆角 6/10/14，只改颜色（不位移、不缩放）。
ThemeTokens macOSThemeTokens(bool isDark) => ThemeTokens(
      colorScheme: isDark ? macOSDarkColorScheme : macOSLightColorScheme,
      extras: isDark ? macOSDarkColorSchemeExtras : macOSLightColorSchemeExtras,
      extendedColors: isDark ? MacOSDarkExtended : MacOSLightExtended,
      textTheme: macOSTextTheme,
      shapes: KitShapes.macOS,
      isDark: isDark,
      themeStyle: ThemeStyle.macOS,
      cornerStyle: CornerStyle.rounded,
      tagColors: tagColorsFor(ThemeStyle.macOS, isDark),
    );
