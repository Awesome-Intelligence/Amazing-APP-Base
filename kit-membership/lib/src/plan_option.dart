import 'billing.dart';
import 'plan.dart';

/// 可展示的一行权益/额度说明 —— 文案由业务给，框架只管排版。
class PlanFeature {
  final String label;
  final String value;

  const PlanFeature(this.label, [this.value = '']);
}

/// 一个档位的展示形态。
class PlanOption {
  final Plan plan;
  final String title;

  /// 价格文案（"¥28 / 月"），用商店给的。
  final String price;
  final List<PlanFeature> features;

  const PlanOption({
    required this.plan,
    required this.title,
    required this.price,
    this.features = const [],
  });
}

/// 把档位翻成可展示的权益/额度说明。
///
/// [entitlementLabels] 权益 key -> 显示名（没给的 key 直接显示 key）。
/// [quotaLabel] 额度 key -> 文案（框架把上限传进去，排版由业务决定）。
List<PlanFeature> toPlanFeatures(
  Plan plan, {
  Map<String, String> entitlementLabels = const {},
  String Function(String key, QuotaLimit limit) quotaLabel = _defaultQuotaLabel,
}) =>
    [
      for (final e in [...plan.entitlements]..sort())
        PlanFeature(entitlementLabels[e] ?? e),
      for (final e in [...plan.limits.entries]..sort((a, b) => a.key.compareTo(b.key)))
        PlanFeature(quotaLabel(e.key, e.value)),
    ];

String _defaultQuotaLabel(String key, QuotaLimit limit) =>
    '$key: ${limit.limit}';

/// 把商店商品和档位表对上 —— 升级页直接用这个列表。
///
/// 只有**在商店里买得到**的付费档才出现（免费档没有商品）；
/// 标题和价格用商店给的（本地化过的），别自己拼。
extension PlanOptionsX on BillingProvider {
  Future<List<PlanOption>> planOptions(
    PlanCatalog catalog, {
    List<PlanFeature> Function(Plan) features = defaultFeatures,
  }) async {
    final prods = {for (final p in await products()) p.id: p};
    return [
      for (final plan in catalog.paid)
        if (prods[plan.id] != null)
          PlanOption(
            plan: plan,
            title: prods[plan.id]!.title,
            price: prods[plan.id]!.price,
            features: features(plan),
          ),
    ];
  }
}

List<PlanFeature> defaultFeatures(Plan plan) => toPlanFeatures(plan);
