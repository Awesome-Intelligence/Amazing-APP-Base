import 'package:material_ui/material_ui.dart';

import '../../i18n/kit_strings.dart';
import '../../theme/kit_theme.dart';
import '../../theme/theme_tokens.dart';

/// 提示条的语义级别。
enum NoticeSeverity { info, success, warning, error }

/// 语义级别 → 配色 / 图标。
///
/// 内联形态用「容器色 + 容器上的前景色」这一对 —— 和 M3 的
/// `errorContainer` / `onErrorContainer` 同一个套路。成功/警告在 ColorScheme
/// 里没有角色，走扩展色。
extension NoticeSeverityStyle on NoticeSeverity {
  /// 容器底色。
  Color background(ThemeTokens tokens) => switch (this) {
        NoticeSeverity.info => tokens.colorScheme.secondaryContainer,
        NoticeSeverity.success => tokens.extendedColors.successContainer,
        NoticeSeverity.warning => tokens.extendedColors.warningContainer,
        NoticeSeverity.error => tokens.colorScheme.errorContainer,
      };

  /// 容器上的前景色（文字 + 图标）。
  Color foreground(ThemeTokens tokens) => switch (this) {
        NoticeSeverity.info => tokens.colorScheme.onSecondaryContainer,
        NoticeSeverity.success => tokens.extendedColors.onSuccessContainer,
        NoticeSeverity.warning => tokens.extendedColors.onWarningContainer,
        NoticeSeverity.error => tokens.colorScheme.onErrorContainer,
      };

  /// 级别图标。
  ///
  /// 灰度主题（E-Ink）里颜色分不出语义，级别全靠这个图标区分。
  IconData get icon => switch (this) {
        NoticeSeverity.info => Icons.info,
        NoticeSeverity.success => Icons.check_circle,
        NoticeSeverity.warning => Icons.warning_amber_rounded,
        NoticeSeverity.error => Icons.error,
      };

  /// 读屏用的级别名。
  String label(KitStrings strings) => switch (this) {
        NoticeSeverity.info => strings.noticeInfo,
        NoticeSeverity.success => strings.noticeSuccess,
        NoticeSeverity.warning => strings.noticeWarning,
        NoticeSeverity.error => strings.noticeError,
      };
}

/// 提示条 —— 图标 + 一句话。项目里唯一的「提示条」组件。
///
/// 两种形态：
/// - **内联**（默认）：直接插在页面里（列表项下方、聊天气泡下面）。
///   底色跟语义走（成功 = successContainer、失败 = errorContainer…），
///   文字和图标用对应的 on*Container 色，保证 ≥4.5:1。
/// - **浮动**（[floating] = true）：M3 SnackBar 的样子 —— `inverseSurface` 底 +
///   `onInverseSurface` 字。级别这时只靠图标区分（M3 的 SnackBar 就是单色的）。
///
/// 这是**纯 widget**，不是 Flutter 的 `SnackBar` —— 后者必须挂在 Scaffold 上、
/// 由 ScaffoldMessenger 驱动。这里做成普通 widget，是为了能直接插在任意位置。
///
/// 想让它自己弹出来，用 [showAppNotice]。
class AppNotice extends StatelessWidget {
  const AppNotice({
    super.key,
    required this.message,
    this.severity = NoticeSeverity.info,
    this.floating = false,
  });

  final String message;

  /// 语义级别。
  final NoticeSeverity severity;

  /// 走浮动（SnackBar）配色，而不是内联容器配色。
  final bool floating;

  @override
  Widget build(BuildContext context) {
    final tokens = KitTheme.of(context);
    final strings = KitStringsScope.of(context);
    final scheme = tokens.colorScheme;
    final bg = floating ? scheme.inverseSurface : severity.background(tokens);
    final fg = floating ? scheme.onInverseSurface : severity.foreground(tokens);

    return Semantics(
      liveRegion: true,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: tokens.shapes.small,
        ),
        child: Row(
          children: [
            Icon(
              severity.icon,
              size: 20,
              color: fg,
              semanticLabel: severity.label(strings),
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

/// 弹一条提示条（走 ScaffoldMessenger，3 秒自动消失）。
///
/// 和 [AppNotice] 的关系：这个负责「弹」，那个负责「长什么样」。
void showAppNotice(
  BuildContext context, {
  required String message,
  NoticeSeverity severity = NoticeSeverity.info,
}) {
  final messenger = ScaffoldMessenger.maybeOf(context);
  if (messenger == null) return;
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: AppNotice(
          message: message,
          severity: severity,
          floating: true,
        ),
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
