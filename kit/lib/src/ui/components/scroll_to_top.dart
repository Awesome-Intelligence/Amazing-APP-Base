import 'package:material_ui/material_ui.dart';

/// 底部导航「已选中项再点一次」的联动：tick 变化时执行 [onScrollToTop]。
/// 首次组合不触发，只有 tick **变化**那一刻触发 —— 所以从别的 tab 切回来、
/// 或者页面重建，都不会莫名其妙跳回顶部。调用方在 reselect 时对 tick 自增即可。
///
/// ```dart
/// // 顶层的数字（每次重按当前 tab 就 ++）
/// int reselectTick = 0;
///
/// // 页面里
/// ScrollToTopEffect(tick: reselectTick, onScrollToTop: () async {
///   if (!controller.hasClients) return;
///   await controller.animateTo(0, duration: ..., curve: ...);
/// });
/// ```
///
/// 这是个「副作用组件」，本身不占位置（渲染成零尺寸）。
/// 用 [State.didUpdateWidget] 比对 tick。
class ScrollToTopEffect extends StatefulWidget {
  const ScrollToTopEffect({
    super.key,
    required this.tick,
    required this.onScrollToTop,
  });

  /// 重按当前 tab 时自增的计数。
  final int tick;

  /// tick 变化时执行。返回的 Future 不等待（不阻塞帧）。
  final Future<void> Function() onScrollToTop;

  @override
  State<ScrollToTopEffect> createState() => _ScrollToTopEffectState();
}

class _ScrollToTopEffectState extends State<ScrollToTopEffect> {
  @override
  void didUpdateWidget(covariant ScrollToTopEffect oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.tick != widget.tick) {
      // 故意不 await：这是一个"发出去就别管"的副作用
      widget.onScrollToTop();
    }
  }

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}

/// [ScrollController] 的便利版：平滑回顶，系统开了「减少动效」就直接跳。
///
/// Flutter 的 `ScrollController` 列表 / 网格通用，所以只要一个。
class ScrollToTopControllerEffect extends StatelessWidget {
  const ScrollToTopControllerEffect({
    super.key,
    required this.tick,
    required this.controller,
    this.curve = Curves.easeOutCubic,
    this.duration = const Duration(milliseconds: 300),
  });

  final int tick;
  final ScrollController controller;
  final Curve curve;
  final Duration duration;

  @override
  Widget build(BuildContext context) {
    // 系统「减少动效」时不做动画：滚动也是动效，别只认转场
    final reduceMotion = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    return ScrollToTopEffect(
      tick: tick,
      onScrollToTop: () async {
        // 列表还没挂上（首帧、空态）时 hasClients 是 false，直接跳过
        if (!controller.hasClients) return;
        if (reduceMotion) {
          controller.jumpTo(0);
        } else {
          await controller.animateTo(0, duration: duration, curve: curve);
        }
      },
    );
  }
}
