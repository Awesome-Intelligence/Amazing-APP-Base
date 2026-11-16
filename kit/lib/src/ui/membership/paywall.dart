import 'package:material_ui/material_ui.dart';

import '../../i18n/kit_strings.dart';
import '../components/dialogs.dart';

/// 额度用完的触发点 —— 对应 KMP 的 `QuotaReason`。
enum QuotaReason {
  goal,
  contact,
  ai,
}

/// 会员付费墙 —— 只说明「为什么被挡住」并把人送去升级页。
///
/// 档位对比**不在这里重复**：那属于 [UpgradeSheet] 的活。分成两个组件
/// 是为了让「被拦住」和「挑方案」各自能单独用（前者也常从 SnackBar 触发）。
///
/// ```dart
/// final upgrade = await MembershipPaywall.show(context, message: '导出需要会员');
/// if (upgrade) UpgradeSheet.show(context, options: options, ...);
/// ```
class MembershipPaywall extends StatelessWidget {
  const MembershipPaywall({
    super.key,
    required this.message,
    required this.onUpgradeClick,
    required this.onDismiss,
  });

  /// 被挡住的原因。业务给 —— 文案跟着业务走，框架猜不出来。
  final String message;

  final VoidCallback onUpgradeClick;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final strings = KitStringsScope.of(context);
    return ConfirmDialog(
      title: strings.membershipPaywallTitle,
      message: message,
      confirmText: strings.membershipUpgrade,
      onConfirm: onUpgradeClick,
      onDismiss: onDismiss,
    );
  }

  /// 弹窗并等结果：true = 用户要去升级，false = 算了。
  static Future<bool> show(
    BuildContext context, {
    required String message,
  }) {
    final strings = KitStringsScope.of(context);
    return ConfirmDialog.show(
      context,
      title: strings.membershipPaywallTitle,
      message: message,
      confirmText: strings.membershipUpgrade,
    );
  }
}

/// 额度用完的付费墙 —— 对应 KMP 的 `QuotaPaywall`。
///
/// 和 [MembershipPaywall] 的差别只有文案：这里的说明由 [reason] + [limit]
/// 拼出来，调用方不用自己写「每天 5 次用完了」这种句子。
class QuotaPaywall extends StatelessWidget {
  const QuotaPaywall({
    super.key,
    required this.reason,
    required this.limit,
    required this.onUpgradeClick,
    required this.onDismiss,
  });

  final QuotaReason reason;

  /// 当前档位的上限。
  final int limit;

  final VoidCallback onUpgradeClick;
  final VoidCallback onDismiss;

  /// 按原因取说明文案。抽成纯函数是为了能单测，也方便业务复用同一句。
  static String messageFor(
    KitStrings strings,
    QuotaReason reason,
    int limit,
  ) =>
      switch (reason) {
        QuotaReason.goal => strings.quotaGoalMessage(limit),
        QuotaReason.contact => strings.quotaContactMessage(limit),
        QuotaReason.ai => strings.quotaAiMessage(limit),
      };

  @override
  Widget build(BuildContext context) {
    final strings = KitStringsScope.of(context);
    return ConfirmDialog(
      title: strings.quotaPaywallTitle,
      message: messageFor(strings, reason, limit),
      confirmText: strings.quotaUpgrade,
      onConfirm: onUpgradeClick,
      onDismiss: onDismiss,
    );
  }

  /// 弹窗并等结果：true = 用户要去升级。
  static Future<bool> show(
    BuildContext context, {
    required QuotaReason reason,
    required int limit,
  }) {
    final strings = KitStringsScope.of(context);
    return ConfirmDialog.show(
      context,
      title: strings.quotaPaywallTitle,
      message: messageFor(strings, reason, limit),
      confirmText: strings.quotaUpgrade,
    );
  }
}
