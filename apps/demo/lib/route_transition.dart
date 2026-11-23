import 'package:kit/kit_ui.dart';
import 'package:material_ui/material_ui.dart';

/// 层级推进的转场：淡入 + 轻微右移。
///
/// 规范（`rules/COMPONENT_SPEC.md` §11.4）：底座不管路由，**app 自己写**
/// `PageRouteBuilder`，时长取 `M3Motion.medium2`；退场换 `emphasizedAccelerate`
/// —— 旧页面让得干脆，注意力才留在新内容上。
///
/// 减动效时时长由 [motionDuration] 归零（系统关了动画就直接跳到终态）。
Widget buildRouteTransition(
  BuildContext context,
  Animation<double> animation,
  Animation<double> secondaryAnimation,
  Widget child,
) {
  final curved = directedCurve(
    animation,
    forward: M3Motion.emphasizedDecelerate,
    reverse: M3Motion.emphasizedAccelerate,
  );
  return FadeTransition(
    opacity: curved,
    child: SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(0.08, 0),
        end: Offset.zero,
      ).animate(curved),
      child: child,
    ),
  );
}

/// app 自己的层级推进路由（列表 → 详情）。
Route<T> kitPageRoute<T>(
  BuildContext context, {
  required WidgetBuilder builder,
}) =>
    PageRouteBuilder<T>(
      transitionDuration: motionDuration(context, M3Motion.medium2),
      reverseTransitionDuration: motionDuration(context, M3Motion.medium2),
      pageBuilder: (context, animation, secondaryAnimation) => builder(context),
      transitionsBuilder: buildRouteTransition,
    );
