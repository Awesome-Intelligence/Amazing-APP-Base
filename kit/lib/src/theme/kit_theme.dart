import 'package:flutter/widgets.dart';

import '../settings/theme_enums.dart' show ThemeStyle;
import 'kit_shapes.dart';
import 'theme_tokens.dart';

/// 主题作用域 —— 把 [ThemeTokens] 注入 widget 树。
///
/// 为什么不用 Material 的 `Theme.of`：底色（[ColorSchemeExtras.background]）、
/// 扩展语义色、圆角风格、标签色板这些都不在 `ThemeData` 里，硬塞进去要改一堆
/// ComponentTheme；单独一个 InheritedWidget 更干净，也不受 MaterialApp 覆盖影响。
///
/// 用法：`KitTheme.of(context).extendedColors.success`。
class KitTheme extends InheritedWidget {
  const KitTheme({
    super.key,
    required this.tokens,
    this.reducedMotion = false,
    required super.child,
  });

  /// 当前生效的 tokens。
  final ThemeTokens tokens;

  /// 系统是否关掉了动画（无障碍设置）。读系统开关是平台活，由各端启动时传进来。
  final bool reducedMotion;

  /// 取当前 tokens。没有作用域时回落到 Mono 浅色，保证预览/单测不炸。
  static ThemeTokens of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<KitTheme>();
    return scope?.tokens ?? monoThemeTokens(false);
  }

  static KitTheme? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<KitTheme>();

  static bool reducedMotionOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<KitTheme>()?.reducedMotion ?? false;

  @override
  bool updateShouldNotify(KitTheme oldWidget) =>
      tokens != oldWidget.tokens || reducedMotion != oldWidget.reducedMotion;
}

/// 主题化圆角：组件只传「这处该用多大半径」，风格由主题决定。
///
/// 组件里别写死 `BorderRadius.circular(x)` —— 写死了就跟主题脱钩，
/// 换风格时那几处不变，看起来就是「半套主题」。
///
/// 圆形（头像、指示点）不在此列：那是图形本身，不是风格。
BorderRadius themedCorner(BuildContext context, double radius) {
  final tokens = KitTheme.of(context);
  if (tokens.cornerStyle == CornerStyle.square) return BorderRadius.zero;
  return BorderRadius.circular(radius);
}

/// 主题化圆角（返回 double 半径），给需要数值的地方用（如 `BorderRadius.all`）。
double themedRadius(BuildContext context, double radius) {
  final tokens = KitTheme.of(context);
  return tokens.cornerStyle == CornerStyle.square ? 0 : radius;
}

/// 圆形（或按主题风格的直角）。
///
/// 日历的日期格、头像这类「本来就是圆」的元素用它：
/// Swiss 这种直角风格下改成方形，否则整套主题里会剩几个圆点格格不入。
/// 半径给 9999 是惯例写法 —— 超过边长一半时绘制结果就是正圆，不用先量尺寸。
BorderRadius themedCircleShape(BuildContext context) {
  final tokens = KitTheme.of(context);
  return tokens.cornerStyle == CornerStyle.square
      ? BorderRadius.zero
      : BorderRadius.circular(9999);
}

/// 控件圆角（按钮 / 输入框）。
///
/// macOS 毛玻璃规范：按钮 6px、输入框 6px —— 比卡片（10px）小一号。
/// 其它风格沿用调用方给的默认。
BorderRadius themedControlRadius(BuildContext context, BorderRadius fallback) {
  final tokens = KitTheme.of(context);
  if (tokens.themeStyle == ThemeStyle.macOS) return BorderRadius.circular(6);
  if (tokens.cornerStyle == CornerStyle.square) return BorderRadius.zero;
  return fallback;
}

/// 描边宽度。
///
/// macOS 毛玻璃规范：「边框永远 1px」—— 再粗就变成描边强调了。
double themedStrokeWidth(BuildContext context, double fallback) =>
    KitTheme.of(context).themeStyle == ThemeStyle.macOS ? 1 : fallback;

/// 装饰性圆形容器 —— 直角风格（瑞士 / 电子纸）下改成直角。
///
/// 头像/照片那种**图形本身**的圆形不走这里 —— 直接用圆形。
BorderRadius themedCircleRadius(BuildContext context) {
  final tokens = KitTheme.of(context);
  return tokens.cornerStyle == CornerStyle.square
      ? BorderRadius.zero
      : KitShapes.pill;
}

/// 阴影高度 —— 瑞士规范写死「Elevation: None」，该主题下所有 elevation 归零。
///
/// Notion 同样是平铺文档（只有弹层允许阴影）；电子纸是纸面印刷；
/// macOS 毛玻璃「层次靠背景深浅，不靠阴影」—— 这三档灰就是它的层级。
double themedElevation(BuildContext context, double fallback) {
  final tokens = KitTheme.of(context);
  return switch (tokens.themeStyle) {
    ThemeStyle.swiss || ThemeStyle.notion || ThemeStyle.eInk || ThemeStyle.macOS => 0,
    ThemeStyle.mono => fallback,
  };
}

/// 禁用态文字色。
///
/// 瑞士规范要求「降对比但仍可读」—— M3 默认 onSurface 38% 透明读不了；
/// 瑞士改用 onSurfaceVariant（白底上 ≈8.9:1），降了对比但读得清。
Color themedDisabledContentColor(BuildContext context) {
  final tokens = KitTheme.of(context);
  if (tokens.themeStyle == ThemeStyle.swiss) return tokens.colorScheme.onSurfaceVariant;
  return tokens.colorScheme.onSurface.withValues(alpha: 0.38);
}

/// 主题化字重 —— 瑞士规范只有 Normal / Bold 两档。
///
/// 规范原文「Typography: Two weights only」。Medium/SemiBold 在瑞士风格里要么读不出
/// 加粗感、要么糊成一团，所以只要比 Normal 重就统一上 Bold。
FontWeight themedFontWeight(BuildContext context, FontWeight fallback) {
  final tokens = KitTheme.of(context);
  if (tokens.themeStyle == ThemeStyle.swiss &&
      fallback.value > FontWeight.normal.value) {
    return FontWeight.bold;
  }
  return fallback;
}

/// 主题化文字对齐 —— 瑞士一律左对齐，绝不居中。
///
/// 网格版面里居中的标题会脱离左基线，看起来「没对齐」。
TextAlign themedTextAlign(BuildContext context, TextAlign centered) =>
    KitTheme.of(context).themeStyle == ThemeStyle.swiss
        ? TextAlign.start
        : centered;

/// 主题化横向对齐（`Column.crossAxisAlignment`）。
///
/// 只把文字改成左对齐、容器还居中，视觉上照样是「居中版面」，所以容器也得一起走这里。
CrossAxisAlignment themedCrossAxisAlignment(
  BuildContext context,
  CrossAxisAlignment centered,
) =>
    KitTheme.of(context).themeStyle == ThemeStyle.swiss
        ? CrossAxisAlignment.start
        : centered;

/// 取标签色（业务代码禁止硬编码标签色，统一走这里）。
Color tagColor(BuildContext context, String name) => KitTheme.of(context).tagColor(name);
