import 'package:flutter/widgets.dart';

import '../../theme/kit_theme.dart';
import '../../theme/motion.dart';

/// 可展开/收起的一块内容 —— 高度撑开 + 淡入，收起时同步收缩。
///
/// 为什么不用 `AnimatedSize`：它只动「框的大小」，里面的内容在动画开始那一刻
/// 就是全尺寸铺好的 —— 收缩时看起来像被裁掉，而不是"收起来"。这里用
/// [SizeTransition] 驱动高度、[FadeTransition] 驱动透明度，两者共享一条
/// controller，进出场方向换曲线（进场减速、退场加速）。
///
/// 收起完成后直接返回 `SizedBox.shrink()`：不留 0 高度的子树，
/// 里面的 `TextField` 才不会继续持有焦点和光标。
class CollapsibleSection extends StatefulWidget {
  const CollapsibleSection({
    super.key,
    required this.isVisible,
    required this.child,
    this.duration = M3Motion.medium1,
    this.fadeDuration = M3Motion.short3,
  });

  final bool isVisible;
  final Widget child;

  /// 高度动画时长（M3 规范：面板展开走 `M3Motion.medium1`）。
  final Duration duration;

  /// 透明度动画时长。比高度短 —— 内容先亮起来，再长开。
  final Duration fadeDuration;

  @override
  State<CollapsibleSection> createState() => _CollapsibleSectionState();
}

class _CollapsibleSectionState extends State<CollapsibleSection>
    // 这条必须是复数的 TickerProviderStateMixin：下面有高度和透明度两条
    // controller。单数版会在建第二条时直接断言失败（"multiple tickers"）。
    with TickerProviderStateMixin {
  late final AnimationController _height = AnimationController(
    vsync: this,
    duration: widget.duration,
    reverseDuration: widget.duration,
    value: widget.isVisible ? 1 : 0,
  );

  late final AnimationController _fade = AnimationController(
    vsync: this,
    duration: widget.fadeDuration,
    reverseDuration: widget.fadeDuration,
    value: widget.isVisible ? 1 : 0,
  );

  // 曲线只造一次：`CurvedAnimation` 每帧都会读父动画，写在 build 里会每帧新建一个。
  late final Animation<double> _heightFactor = directedCurve(
    _height,
    forward: M3Motion.emphasizedDecelerate,
    reverse: M3Motion.emphasizedAccelerate,
  );

  late final Animation<double> _opacity = directedCurve(
    _fade,
    forward: M3Motion.emphasizedDecelerate,
    reverse: M3Motion.emphasizedAccelerate,
  );

  @override
  void initState() {
    super.initState();
    // 收完必须重建一次：动画跑完只是把 sizeFactor 降到 0，widget 树没变，
    // 内容还在那儿（只是被裁没了）。不主动 setState 的话 `build` 里那句
    // 「收完就整棵拿掉」永远等不到执行 —— 焦点和光标会一直留在隐藏的输入框上。
    _height.addStatusListener((status) {
      if (status.isDismissed) setState(() {});
    });
  }

  @override
  void didUpdateWidget(CollapsibleSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isVisible == oldWidget.isVisible) return;
    if (KitTheme.reducedMotionOf(context)) {
      // 减动效：当场跳，别留半截动画在跑。
      _height.value = widget.isVisible ? 1 : 0;
      _fade.value = widget.isVisible ? 1 : 0;
      return;
    }
    if (widget.isVisible) {
      _height.forward();
      _fade.forward();
    } else {
      // 退场：透明度先走完，高度随后收 —— 反过来的话会看到一块空底色在缩。
      _fade.reverse();
      _height.reverse();
    }
  }

  @override
  void dispose() {
    _height.dispose();
    _fade.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 收完就整棵子树拿掉（见类文档）。
    if (!widget.isVisible && _height.isDismissed) return const SizedBox.shrink();

    return SizeTransition(
      sizeFactor: _heightFactor,
      // 从顶边往下长，而不是从中间往两头撑 —— 展开时下面的内容才不会被顶下去又顶回来。
      // Flutter 3.41 起 axisAlignment（double）换成 alignment（AlignmentGeometry），
      // -1 就是「贴顶边」，等价于 Alignment.topCenter。
      alignment: Alignment.topCenter,
      child: FadeTransition(opacity: _opacity, child: widget.child),
    );
  }
}

/// 同位置整体替换内容 —— M3 的 Fade Through。
///
/// M3 规定两段**不重叠**：旧内容先淡出 90ms，新内容再淡入 210ms 并从 92% 放大。
/// 同时在场会看到两层叠影，比硬切还糟 —— 所以不能直接用 `AnimatedSwitcher`：
/// 它让进出场共用一条时间轴，两段必然重叠。
///
/// 用「目标状态」驱动，而不是靠 `child` 的实例比较：
/// 空态 ↔ 列表两边可能都是 `ListView`，只比 widget 实例会分不清该不该动。
class AnimatedContentSwitch<T> extends StatefulWidget {
  const AnimatedContentSwitch({
    super.key,
    required this.target,
    required this.builder,
  });

  /// 当前状态。值变了就放转场。
  final T target;

  /// 按状态造内容。转场途中**两个**状态都会被调用一次（旧的在退出）。
  final Widget Function(BuildContext context, T target) builder;

  @override
  State<AnimatedContentSwitch<T>> createState() =>
      _AnimatedContentSwitchState<T>();
}

class _AnimatedContentSwitchState<T> extends State<AnimatedContentSwitch<T>>
    with SingleTickerProviderStateMixin {
  static const Curve _exit =
      Interval(0, 0.3, curve: M3Motion.emphasizedAccelerate);
  static const Curve _enter =
      Interval(0.3, 1, curve: M3Motion.emphasizedDecelerate);

  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: M3Motion.fadeThrough,
    value: 1,
  );

  T? _outgoingTarget;

  @override
  void initState() {
    super.initState();
    // 转场跑完要重建一次把旧内容摘掉：控制器的完成只是把透明度停在 0，
    // 旧 widget 还挂在 Stack 里（`find.text` 依然找得到，语义树也照样读它）。
    _controller.addStatusListener((status) {
      if (status.isCompleted && _outgoingTarget != null) {
        setState(() => _outgoingTarget = null);
      }
    });
  }

  @override
  void didUpdateWidget(AnimatedContentSwitch<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.target == oldWidget.target) return;
    if (KitTheme.reducedMotionOf(context)) return; // 直接换，不留旧内容
    _outgoingTarget = oldWidget.target;
    _controller.forward(from: 0);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 静止态（转场没在跑）：只有当前内容，不套任何动画层，省一层重绘。
    if (_controller.isCompleted || _outgoingTarget == null) {
      return widget.builder(context, widget.target);
    }

    final outgoing = _outgoingTarget as T;
    return Stack(
      children: [
        // 旧内容：只淡出，不缩放（缩小的同时淡出会看出「两个图层」）。
        FadeTransition(
          opacity: ReverseAnimation(
            CurvedAnimation(parent: _controller, curve: _exit),
          ),
          child: widget.builder(context, outgoing),
        ),
        FadeTransition(
          opacity: CurvedAnimation(parent: _controller, curve: _enter),
          child: ScaleTransition(
            scale: tweened(
              _controller,
              M3Motion.fadeThroughInitialScale,
              1,
              curve: _enter,
            ),
            child: widget.builder(context, widget.target),
          ),
        ),
      ],
    );
  }
}
