import 'dart:math' as math;
import 'dart:ui' show Color;

import 'package:material_ui/material_ui.dart' show FontWeight;
import 'package:flutter_test/flutter_test.dart';
import 'package:kit/kit.dart';
import 'package:kit/kit_ui.dart';

/// WCAG 相对亮度。
double _luminance(Color c) {
  double channel(double v) =>
      v <= 0.03928 ? v / 12.92 : math.pow((v + 0.055) / 1.055, 2.4).toDouble();
  return 0.2126 * channel(c.r) + 0.7152 * channel(c.g) + 0.0722 * channel(c.b);
}

/// WCAG 对比度。
double _contrast(Color a, Color b) {
  final la = _luminance(a);
  final lb = _luminance(b);
  final hi = la > lb ? la : lb;
  final lo = la > lb ? lb : la;
  return (hi + 0.05) / (lo + 0.05);
}

/// 主题迁移的**等价性**验证。
///
/// 这些断言对着色板源文件写死期望值 —— 如果哪天有人手改了色板，
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

    test('色值逐项一致（抽查各风格）', () {
      // Mono.primaryLight
      expect(monoThemeTokens(false).colorScheme.primary, const Color(0xFF1D1915));
      // Mono.surface 与 background 在 Mono 里同值
      expect(monoThemeTokens(false).extras.background, const Color(0xFFFDFAF6));
      // EInk.primaryLight 是 `= ink` 别名，验证别名解析没丢
      expect(eInkThemeTokens(false).colorScheme.primary, const Color(0xFF20211E));
      expect(eInkThemeTokens(false).colorScheme.surface, const Color(0xFFF5F3EA));
    });

    test('圆角风格一致', () {
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
      // 这两项取值不同（EEEE vs E5E1DD），必须能分别取到
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

    test('排版：绝对行高已换算成 Flutter 倍数', () {
      // typography_tokens.dart: bodyLarge fontSize 16 / lineHeight 24 -> height 1.5
      final body = monoThemeTokens(false).textTheme.bodyLarge!;
      expect(body.fontSize, 16);
      expect(body.height, closeTo(1.5, 0.0001));
      // typography_tokens.dart: displayLarge 88 / 86 -> 0.9773
      final swissDisplay = swissThemeTokens(false).textTheme.displayLarge!;
      expect(swissDisplay.fontSize, 88);
      expect(swissDisplay.height, closeTo(86 / 88, 0.0001));
      expect(swissDisplay.fontWeight, FontWeight.w700);
    });
  });

  group('提示条对比度', () {
    test('各级别容器上的文字 ≥4.5:1（10 套明暗全查）', () {
      for (final style in ThemeStyle.values) {
        for (final dark in [false, true]) {
          final t = tokensFor(style, dark);
          final s = t.colorScheme;
          final e = t.extendedColors;
          final cases = <String, (Color, Color)>{
            'info': (s.secondaryContainer, s.onSecondaryContainer),
            'success': (e.successContainer, e.onSuccessContainer),
            'warning': (e.warningContainer, e.onWarningContainer),
            'error': (s.errorContainer, s.onErrorContainer),
            // 浮动形态（M3 SnackBar）走 inverseSurface。
            'floating': (s.inverseSurface, s.onInverseSurface),
          };
          cases.forEach((name, pair) {
            expect(
              _contrast(pair.$1, pair.$2),
              greaterThanOrEqualTo(4.5),
              reason: '$style 深浅=$dark $name',
            );
          });
        }
      }
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

    test('Swiss 标签色板一致（含别名 Swiss.redInk）', () {
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
