import 'dart:ui' show lerpDouble;

import 'package:flutter/widgets.dart';

import 'kit_theme.dart';

/// Material 3 动效令牌。
///
/// 用法：位置/尺寸变化走 [medium1] 一档的**时长** + [emphasizedDecelerate]；
/// 颜色/透明度变化用更短的时长（[short2] / [short3]）。退场永远比进场快 ——
/// 注意力要留在新内容上，旧内容慢慢消失只会让人以为还有东西没出来。
///
/// 这里的常量是**纯数据**，不读 context。要按「系统是否关了动画」自动退化，
/// 用 [motionDuration]；转场交给 `CollapsibleSection` / `AnimatedContentSwitch`，
/// 它们内部已经处理了减动效。
abstract final class M3Motion {
  // ── 时长 ──────────────────────────────────────────────────────────
  static const Duration short1 = Duration(milliseconds: 50);
  static const Duration short2 = Duration(milliseconds: 100);
  static const Duration short3 = Duration(milliseconds: 150);
  static const Duration short4 = Duration(milliseconds: 200);
  static const Duration medium1 = Duration(milliseconds: 250);
  static const Duration medium2 = Duration(milliseconds: 300);
  static const Duration medium3 = Duration(milliseconds: 350);
  static const Duration medium4 = Duration(milliseconds: 400);
  static const Duration long1 = Duration(milliseconds: 450);
  static const Duration long2 = Duration(milliseconds: 500);

  /// 转场退场淡出：M3 规定 90ms。
  static const Duration exitFade = Duration(milliseconds: 90);

  /// Fade Through 进场：M3 规范 210ms（先等 90ms 退场，合计 300ms）。
  static const Duration fadeThroughIn = Duration(milliseconds: 210);

  /// Fade Through 全程 = 退场 + 进场，两条动画串行不重叠。
  static const Duration fadeThrough = Duration(milliseconds: 300);

  /// Fade Through 进场初始缩放：92% —— 不加缩放就只剩淡入，看不出「换了一层」。
  static const double fadeThroughInitialScale = 0.92;

  // ── 缓动 ──────────────────────────────────────────────────────────
  /// 强调曲线（M3 emphasized）。两端都缓，中段最快。
  static const Curve emphasized = Cubic(0.2, 0.0, 0.0, 1.0);

  /// 进场用：起步就快、末端极慢地停住。
  static const Curve emphasizedDecelerate = Cubic(0.05, 0.7, 0.1, 1.0);

  /// 退场用：慢慢起步、末端迅速离开。
  static const Curve emphasizedAccelerate = Cubic(0.3, 0.0, 0.8, 0.15);
}

/// 按「系统是否关了动画」返回时长 —— 关了就是 [Duration.zero]，动画当场跳到终态。
///
/// 为什么不返回一个更短的时长：无障碍设置里的「移除动画」语义是**不要动画**，
/// 慢慢淡入淡出对前庭功能敏感的用户同样是负担。
Duration motionDuration(BuildContext context, Duration duration) =>
    KitTheme.reducedMotionOf(context) ? Duration.zero : duration;

/// 三段缓动的组合：进场用 [M3Motion.emphasizedDecelerate]，
/// 退场换 [M3Motion.emphasizedAccelerate]。
///
/// `CurvedAnimation(reverseCurve:)` 是 Flutter 少见的**按方向换曲线**的入口，
/// 不这么写的话退场也会用进场曲线，看起来「走得不利索」。
Animation<double> directedCurve(
  Animation<double> parent, {
  required Curve forward,
  required Curve reverse,
}) =>
    CurvedAnimation(parent: parent, curve: forward, reverseCurve: reverse);

/// 从 [begin] 到 [end] 的补间，用给定曲线（默认强调减速）。
///
/// 只是少写一层 `Tween(...).animate(CurvedAnimation(...))`。
Animation<double> tweened(
  Animation<double> parent,
  double begin,
  double end, {
  Curve curve = M3Motion.emphasizedDecelerate,
  Curve? reverseCurve,
}) =>
    Tween<double>(begin: begin, end: end).animate(
      CurvedAnimation(
        parent: parent,
        curve: curve,
        reverseCurve: reverseCurve ?? curve,
      ),
    );

/// 数值插值（给 `lerpDouble` 收口用，避免各组件各写一遍）。
double lerp(double a, double b, double t) => lerpDouble(a, b, t)!;
