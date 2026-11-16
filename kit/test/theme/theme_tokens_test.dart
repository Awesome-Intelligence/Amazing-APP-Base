import 'dart:ui' show Color;

import 'package:material_ui/material_ui.dart' show FontWeight;
import 'package:flutter_test/flutter_test.dart';
import 'package:kit/kit.dart';
import 'package:kit/kit_ui.dart';

/// 主题迁移的**等价性**验证。
///
/// 这些断言对着 KMP 的 Kotlin 源文件写死期望值 —— 如果哪天有人手改了色板，
/// 这里会立刻红，而不是等上线发现「颜色淡了一点」。
void main() {
  group('五套预设 tokens', () {
    test('每套风格明暗都能造，风格与明暗标记正确', () {
      for (final style in ThemeStyle.values) {
        final light = tokensFor(style, false);
        final dark = tokensFor(style, true);

        expect(light.isDark, isFalse, reason: '$style 浅色标记');
        expect(dark.isDark, isTrue, reason: '$style 深色标记');
        expect(light.themeStyle, style);
        expect(dark.themeStyle, style);
        expect(light.tagColors.length, 6, reason: '$style 标签色板应有 6 色');
      }
    });

    test('色值与 KMP 逐项一致（抽查各风格）', () {
      // Mono.primaryLight
      expect(monoThemeTokens(false).colorScheme.primary, const Color(0xFF1D1915));
      // Mono.surface 与 background 在 Mono 里同值
      expect(monoThemeTokens(false).extras.background, const Color(0xFFFDFAF6));
      // EInk.primaryLight 是 `= ink` 别名，验证别名解析没丢
      expect(eInkThemeTokens(false).colorScheme.primary, const Color(0xFF20211E));
      expect(eInkThemeTokens(false).colorScheme.surface, const Color(0xFFF5F3EA));
    });

    test('圆角风格与 KMP 一致', () {
      expect(monoThemeTokens(false).cornerStyle, CornerStyle.rounded);
      expect(swissThemeTokens(false).cornerStyle, CornerStyle.square);
      expect(eInkThemeTokens(false).cornerStyle, CornerStyle.square);
      expect(notionThemeTokens(false).cornerStyle, CornerStyle.rounded);

      // Swiss / E-Ink 全直角；Notion 4px；macOS 6/10/14
      expect(swissThemeTokens(false).shapes.medium.topLeft.x, 0);
      expect(eInkThemeTokens(false).shapes.medium.topLeft.x, 0);
      expect(notionThemeTokens(false).shapes.medium.topLeft.x, 4);
      expect(macOSThemeTokens(true).shapes.medium.topLeft.x, 10);
    });

    test('扩展语义色随明暗切换', () {
      expect(monoThemeTokens(false).extendedColors.success, LightExtended.success);
      expect(monoThemeTokens(true).extendedColors.success, DarkExtended.success);
      expect(
        monoThemeTokens(false).extendedColors.success,
        isNot(monoThemeTokens(true).extendedColors.success),
      );
    });

    test('surfaceVariant 与 surfaceContainerHighest 不被抹平', () {
      // KMP 里这两项取值不同（EEEE vs E5E1DD），迁到 Flutter 后仍要能分别取到
      final tokens = monoThemeTokens(false);
      expect(tokens.extras.surfaceVariant, const Color(0xFFE9E5E1));
      expect(tokens.colorScheme.surfaceContainerHighest, const Color(0xFFE5E1DD));
      expect(tokens.extras.surfaceVariant, isNot(tokens.colorScheme.surfaceContainerHighest));
    });

    test('页面底色独立于卡片底色（Notion 浅色底 vs 白卡）', () {
      final notion = notionThemeTokens(false);
      expect(notion.extras.background, const Color(0xFFF7F6F3));
      expect(notion.colorScheme.surface, const Color(0xFFFFFFFF));
      expect(notion.extras.background, isNot(notion.colorScheme.surface));
    });

    test('排版：Compose 绝对行高换算成 Flutter 倍数', () {
      // Type.kt: bodyLarge fontSize 16 / lineHeight 24 -> height 1.5
      final body = monoThemeTokens(false).textTheme.bodyLarge!;
      expect(body.fontSize, 16);
      expect(body.height, closeTo(1.5, 0.0001));
      // TypeSwiss.kt: displayLarge 88 / 86 -> 0.9773
      final swissDisplay = swissThemeTokens(false).textTheme.displayLarge!;
      expect(swissDisplay.fontSize, 88);
      expect(swissDisplay.height, closeTo(86 / 88, 0.0001));
      expect(swissDisplay.fontWeight, FontWeight.w700);
    });
  });

  group('标签色板', () {
    test('按风格与明暗取色，未知键回落 neutral', () {
      final tokens = monoThemeTokens(false);
      expect(tokens.tagColors.keys, containsAll(<String>['neutral', 'rose', 'sage']));
      expect(tokens.tagColors['neutral'], const Color(0xFF5A5A5A));
      expect(tokens.tagColor('neutral'), const Color(0xFF5A5A5A));
      // 大小写不敏感
      expect(tokens.tagColor('ROSE'), tokens.tagColors['rose']);
      // 未知键回落 neutral
      expect(tokens.tagColor('nope'), tokens.tagColors['neutral']);
    });

    test('Swiss 标签色板与 KMP 一致（含别名 Swiss.redInk）', () {
      final swing = swissThemeTokens(false);
      expect(swing.tagColors['neutral'], const Color(0xFF000000));
      expect(swing.tagColors['rose'], Swiss.redInk);
    });
  });

  group('自定义品牌主题', () {
    test('themeTokens 只传颜色也能造出完整 tokens', () {
      final tokens = themeTokens(
        colorScheme: monoThemeTokens(false).colorScheme,
        isDark: false,
      );
      expect(tokens.themeStyle, ThemeStyle.mono);
      expect(tokens.cornerStyle, CornerStyle.rounded);
      expect(tokens.textTheme.bodyMedium, isNotNull);
      expect(tokens.tagColors, isEmpty);
      // tagColors 留空时按风格取底座色板
      expect(tokens.tagColor('neutral'), const Color(0xFF5A5A5A));
    });
  });
}
