import 'package:material_ui/material_ui.dart';

import '../../i18n/kit_strings.dart';
import '../../theme/kit_theme.dart';

/// 操作反馈条：图标 + 一句话。
///
/// 这是**纯 widget**，不是 Flutter 的 `SnackBar` —— 后者必须挂在 Scaffold 上、
/// 由 ScaffoldMessenger 驱动。这里做成普通 widget，是为了能像 Compose 版那样
/// 直接插在任意位置（底部表单、卡片里、甚至 gallery 里）。
///
/// 想在页面顶部/底部弹一条，用 [showAppSnackbar]。
class AppSnackbar extends StatelessWidget {
  const AppSnackbar({
    super.key,
    required this.message,
    required this.isSuccess,
  });

  final String message;
  final bool isSuccess;

  @override
  Widget build(BuildContext context) {
    final tokens = KitTheme.of(context);
    final s = KitStringsScope.of(context);
    final fg = tokens.colorScheme.onInverseSurface;

    return Semantics(
      liveRegion: true,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: tokens.colorScheme.inverseSurface,
          borderRadius: tokens.shapes.small,
        ),
        child: Row(
          children: [
            Icon(
              isSuccess ? Icons.check_circle : Icons.error,
              size: 20,
              color: isSuccess ? tokens.colorScheme.primary : tokens.colorScheme.error,
              semanticLabel: isSuccess ? s.operationSuccess : s.operationFailed,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: tokens.textTheme.bodyMedium?.copyWith(color: fg),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 弹一条反馈（走 ScaffoldMessenger，3 秒自动消失）。
///
/// 和 [AppSnackbar] 的关系：这个负责「弹」，那个负责「长什么样」。
void showAppSnackbar(
  BuildContext context, {
  required String message,
  bool isSuccess = true,
}) {
  final messenger = ScaffoldMessenger.maybeOf(context);
  if (messenger == null) return;
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: AppSnackbar(message: message, isSuccess: isSuccess),
        backgroundColor: Colors.transparent,
        elevation: 0,
        behavior: SnackBarBehavior.floating,
        padding: EdgeInsets.zero,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        duration: const Duration(seconds: 3),
      ),
    );
}

/// 48 的圆形加载指示器。
class LoadingIndicator extends StatelessWidget {
  const LoadingIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    final tokens = KitTheme.of(context);
    return SizedBox(
      width: 48,
      height: 48,
      child: CircularProgressIndicator(
        strokeWidth: 4,
        color: tokens.colorScheme.primary,
        backgroundColor: tokens.extras.surfaceVariant,
        semanticsLabel: KitStringsScope.of(context).loading,
      ),
    );
  }
}

/// 全屏加载遮罩：内容照常渲染，上面盖一层淡色 + 转圈。
///
/// 遮罩用 [AnimatedOpacity] 而不是硬切 —— 加载往往只闪几十毫秒，
/// 硬切会闪一下白，看起来像页面在抖。
class LoadingOverlay extends StatelessWidget {
  const LoadingOverlay({
    super.key,
    required this.isLoading,
    required this.child,
  });

  final bool isLoading;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final tokens = KitTheme.of(context);
    final reduced = KitTheme.reducedMotionOf(context);

    return Stack(
      children: [
        child,
        Positioned.fill(
          child: IgnorePointer(
            // 不加载的时候必须真正不吃事件，否则底层按钮全点不动。
            ignoring: !isLoading,
            child: AnimatedOpacity(
              opacity: isLoading ? 1 : 0,
              duration: reduced ? Duration.zero : const Duration(milliseconds: 200),
              // 不加载时必须把 ticker 停掉：转圈是无限动画，opacity 0 也照样每帧
              // 重绘 —— 白耗电，还会让任何等待「画面静止」的代码永远等不到。
              child: TickerMode(
                enabled: isLoading,
                child: ColoredBox(
                  color: tokens.colorScheme.surfaceTint.withValues(alpha: 0.3),
                  child: const Center(
                    child: SizedBox(
                      width: 40,
                      height: 40,
                      child: CircularProgressIndicator(strokeWidth: 3),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// 居中加载（占满父容器）。
class CenteredLoading extends StatelessWidget {
  const CenteredLoading({super.key});

  @override
  Widget build(BuildContext context) =>
      const Center(child: LoadingIndicator());
}
