import 'package:material_ui/material_ui.dart';
import 'package:kit_membership/membership.dart';

import '../../i18n/kit_strings.dart';
import '../../theme/kit_theme.dart';
import '../components/buttons.dart';
import '../components/cards.dart';

/// 升级面板 —— 档位对比 + 购买 + 恢复购买。对应 KMP 的 `UpgradeSheet`。
///
/// 只管排版：档位名、价格、权益文案全由业务给的 [PlanOption] 决定，
/// 买了哪一单通过 [onPurchase] 回调出去。**框架不碰支付通道** ——
/// 那属于各端 app 的 [BillingProvider] 实现（Play Billing / StoreKit）。
///
/// ```dart
/// await UpgradeSheet.show(
///   context,
///   options: options,          // BillingProvider.planOptions(catalog)
///   currentPlanId: manager.plan.id,
///   onPurchase: (id) => manager.purchase(provider, id),
///   onRestore: () => manager.restore(provider),
/// );
/// ```
class UpgradeSheet extends StatelessWidget {
  const UpgradeSheet({
    super.key,
    required this.options,
    required this.currentPlanId,
    required this.onPurchase,
    required this.onRestore,
  });

  /// 要展示的档位。一般来自 `BillingProvider.planOptions(catalog)` ——
  /// 只有**商店里买得到**的付费档会进来，免费档没有商品。
  final List<PlanOption> options;

  /// 当前生效的档位 id；等于某个 option 时那个档位显示「当前方案」并禁用按钮。
  final String? currentPlanId;

  /// 点了某个档位的购买按钮，参数是 `plan.id`。
  final ValueChanged<String> onPurchase;

  final VoidCallback onRestore;

  @override
  Widget build(BuildContext context) {
    final strings = KitStringsScope.of(context);

    return SafeArea(
      top: false,
      child: ConstrainedBox(
        // 档位多的时候（3–4 档）内容会比屏幕高，必须给上限 + 可滚。
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.9,
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
          child: Center(
            child: ConstrainedBox(
              // 桌面窗口 / 平板横屏下不铺满整条边 —— 一行文本拉太长很难读。
              constraints: const BoxConstraints(maxWidth: 560),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (var i = 0; i < options.length; i++) ...[
                    _PlanCard(
                      option: options[i],
                      isCurrent: options[i].plan.id == currentPlanId,
                      onPurchase: () => onPurchase(options[i].plan.id),
                    ),
                    const SizedBox(height: 12),
                  ],
                  TextActionButton(
                    text: strings.membershipRestore,
                    onPressed: onRestore,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// 弹起面板。关闭（下滑 / 点遮罩）后 future 才完成，调用方可以紧接着刷新状态。
  static Future<void> show(
    BuildContext context, {
    required List<PlanOption> options,
    required String? currentPlanId,
    required ValueChanged<String> onPurchase,
    required VoidCallback onRestore,
  }) {
    final tokens = KitTheme.of(context);
    return showModalBottomSheet<void>(
      context: context,
      // 不给 isScrollControlled，默认最高只到屏幕一半，两三个档位就放不下。
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      backgroundColor: tokens.colorScheme.surface,
      // 0 高度 + 无 tint：M3 的 elevation tint 会在 surface 上叠一层色，
      // 跟弹窗用色阶分层（不叠阴影/不叠色）的约定冲突。
      elevation: 0,
      shape: RoundedRectangleBorder(
        // 只圆上面两个角：全圆角会让底部两角翘起来、露出底色。
        borderRadius: BorderRadius.vertical(top: tokens.shapes.extraLarge.topLeft),
      ),
      builder: (_) => UpgradeSheet(
        options: options,
        currentPlanId: currentPlanId,
        onPurchase: onPurchase,
        onRestore: onRestore,
      ),
    );
  }
}

/// 一个档位的卡片。
class _PlanCard extends StatelessWidget {
  const _PlanCard({
    required this.option,
    required this.isCurrent,
    required this.onPurchase,
  });

  final PlanOption option;
  final bool isCurrent;
  final VoidCallback onPurchase;

  @override
  Widget build(BuildContext context) {
    final tokens = KitTheme.of(context);
    final strings = KitStringsScope.of(context);
    final scheme = tokens.colorScheme;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(option.title, style: tokens.textTheme.titleMedium),
          const SizedBox(height: 2),
          Text(
            option.price,
            style: tokens.textTheme.bodyMedium?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
          if (option.features.isNotEmpty) const SizedBox(height: 8),
          // KMP 那版这里一条挨着一条（Compose Column 默认 0 间距），挤在一起
          // 读起来很像一段话；给 6px 让每条权益自成一行。
          for (final feature in option.features)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 图标比正文稍高一点会显得浮起来，往下压 1px 对齐首行文字基线。
                  Padding(
                    padding: const EdgeInsets.only(top: 1),
                    child: Icon(Icons.check, size: 16, color: scheme.primary),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      feature.value.isEmpty
                          ? feature.label
                          : '${feature.label}：${feature.value}',
                      style: tokens.textTheme.bodyMedium,
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 8),
          PrimaryButton(
            text: isCurrent
                ? strings.membershipCurrentPlan
                : strings.membershipPurchase,
            onPressed: onPurchase,
            enabled: !isCurrent,
            expand: true,
          ),
        ],
      ),
    );
  }
}
