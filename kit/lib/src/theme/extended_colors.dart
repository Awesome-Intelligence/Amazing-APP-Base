import 'dart:ui' show Color;

/// 不在 Material 3 colorScheme 里的扩展语义色。
///
/// 深浅色各自取值，保证对比度达标 ——
/// 所以它属于 tokens（一套 tokens 一套明暗），不能靠 `Color.lerp` 现算。
class ExtendedColors {
  const ExtendedColors({
    required this.success,
    required this.onSuccess,
    required this.successContainer,
    required this.onSuccessContainer,
    required this.warning,
    required this.onWarning,
    required this.warningContainer,
    required this.onWarningContainer,
    required this.aiAccent,
    required this.aiContainer,
    required this.onAiContainer,
    required this.star,
  });

  /// 成功/已完成。
  final Color success;

  /// success 上的前景色。
  final Color onSuccess;

  /// 成功态容器背景（成功提示条、已完成的徽标）。
  final Color successContainer;

  /// successContainer 上的前景色（提示条文字/图标）。
  ///
  /// M3 的 ColorScheme 里有 errorContainer/onErrorContainer 这一对，
  /// 成功/警告没有对应角色 —— 没有它，提示条只能拿强调色当文字色，
  /// 在自己的容器底上普遍达不到 4.5:1。
  final Color onSuccessContainer;

  /// 警告/待处理。
  final Color warning;

  /// warning 上的前景色。
  final Color onWarning;

  /// 警告态容器背景。
  final Color warningContainer;

  /// warningContainer 上的前景色（提示条文字/图标）。
  final Color onWarningContainer;

  /// AI 功能强调色（图标/小字），深浅色各自取值，保证 ≥4.5:1。
  final Color aiAccent;

  /// AI 容器背景（AI 建议条目、提示气泡）。
  final Color aiContainer;

  /// aiContainer 上的前景色。
  final Color onAiContainer;

  /// 收藏星标色（黄色系）。
  ///
  /// M3 没有「黄色」角色，收藏态属于语义强调，按扩展色处理；
  /// 对底色的非文字对比度 ≥3:1。
  final Color star;

  ExtendedColors copyWith({
    Color? success,
    Color? onSuccess,
    Color? successContainer,
    Color? onSuccessContainer,
    Color? warning,
    Color? onWarning,
    Color? warningContainer,
    Color? onWarningContainer,
    Color? aiAccent,
    Color? aiContainer,
    Color? onAiContainer,
    Color? star,
  }) {
    return ExtendedColors(
      success: success ?? this.success,
      onSuccess: onSuccess ?? this.onSuccess,
      successContainer: successContainer ?? this.successContainer,
      onSuccessContainer: onSuccessContainer ?? this.onSuccessContainer,
      warning: warning ?? this.warning,
      onWarning: onWarning ?? this.onWarning,
      warningContainer: warningContainer ?? this.warningContainer,
      onWarningContainer: onWarningContainer ?? this.onWarningContainer,
      aiAccent: aiAccent ?? this.aiAccent,
      aiContainer: aiContainer ?? this.aiContainer,
      onAiContainer: onAiContainer ?? this.onAiContainer,
      star: star ?? this.star,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is ExtendedColors &&
      other.success == success &&
      other.onSuccess == onSuccess &&
      other.successContainer == successContainer &&
      other.onSuccessContainer == onSuccessContainer &&
      other.warning == warning &&
      other.onWarning == onWarning &&
      other.warningContainer == warningContainer &&
      other.onWarningContainer == onWarningContainer &&
      other.aiAccent == aiAccent &&
      other.aiContainer == aiContainer &&
      other.onAiContainer == onAiContainer &&
      other.star == star;

  @override
  int get hashCode => Object.hash(
        success,
        onSuccess,
        successContainer,
        onSuccessContainer,
        warning,
        onWarning,
        warningContainer,
        onWarningContainer,
        aiAccent,
        aiContainer,
        onAiContainer,
        star,
      );
}
