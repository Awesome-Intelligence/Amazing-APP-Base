import 'dart:ui' show Radius;

import 'package:flutter/painting.dart' show BorderRadius;

/// 圆角风格：品牌主题解耦了「像素风」之后，圆角由 tokens 单独决定。
///
/// 圆角风格。
enum CornerStyle {
  /// 跟随传入的半径（Mono 默认）。
  rounded,

  /// 全直角（Swiss / E-Ink 默认，品牌也可以选）。
  square,
}

/// 圆角桶（五个槽位）。
///
/// 组件只按语义取（small/medium/large…），不写死数值 ——
/// 写死就跟主题脱钩，换风格时那几处不变，看起来就是「半套主题」。
class KitShapes {
  const KitShapes({
    required this.extraSmall,
    required this.small,
    required this.medium,
    required this.large,
    required this.extraLarge,
  });

  final BorderRadius extraSmall;
  final BorderRadius small;
  final BorderRadius medium;
  final BorderRadius large;
  final BorderRadius extraLarge;

  static BorderRadius _r(double v) => BorderRadius.circular(v);

  /// M3 默认圆角桶：4 / 8 / 12 / 16 / 28。
  static final KitShapes m3 = KitShapes(
    extraSmall: _r(4),
    small: _r(8),
    medium: _r(12),
    large: _r(16),
    extraLarge: _r(28),
  );

  /// 全直角（Swiss / E-Ink）：网格和纸面印刷都没有圆角，层次靠硬边框和色阶。
  static const KitShapes square = KitShapes(
    extraSmall: BorderRadius.zero,
    small: BorderRadius.zero,
    medium: BorderRadius.zero,
    large: BorderRadius.zero,
    extraLarge: BorderRadius.zero,
  );

  /// Notion：卡片/按钮/输入框一律 4px，弹层 8px。
  static final KitShapes notion = KitShapes(
    extraSmall: _r(4),
    small: _r(4),
    medium: _r(4),
    large: _r(4),
    extraLarge: _r(8),
  );

  /// macOS 毛玻璃：按钮/输入框 6px、卡片 10px、面板 14px。
  static final KitShapes macOS = KitShapes(
    extraSmall: _r(6),
    small: _r(6),
    medium: _r(10),
    large: _r(14),
    extraLarge: _r(14),
  );

  /// 药丸（头像堆叠、圆形指示点之外的胶囊标签）用这个：999 半径。
  static const BorderRadius pill = BorderRadius.all(Radius.circular(999));

  @override
  bool operator ==(Object other) =>
      other is KitShapes &&
      other.extraSmall == extraSmall &&
      other.small == small &&
      other.medium == medium &&
      other.large == large &&
      other.extraLarge == extraLarge;

  @override
  int get hashCode => Object.hash(extraSmall, small, medium, large, extraLarge);
}
