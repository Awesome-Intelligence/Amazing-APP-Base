/// 商店里的一个商品（订阅或买断）。
class Product {
  /// 商品 id，和档位表里的 plan.id 对齐。
  final String id;

  /// 标题（本地化过的）。
  final String title;

  /// 本地化价格文案（"¥28 / 月"）—— 价格用商店给的，别自己算。
  final String price;

  final String description;

  const Product({
    required this.id,
    required this.title,
    required this.price,
    this.description = '',
  });
}

/// 一次购买的结果。
sealed class PurchaseResult {
  const PurchaseResult();
}

/// 买成功。[verified] 为 true 表示回执已验签 / 已跟服务端核对过。
final class PurchaseSuccess extends PurchaseResult {
  final String productId;
  final int? expiresAt;
  final bool verified;

  const PurchaseSuccess({
    required this.productId,
    this.expiresAt,
    this.verified = false,
  });
}

/// 用户取消。
final class PurchaseCancelled extends PurchaseResult {
  const PurchaseCancelled();
}

/// 还在处理中（家长确认、3DS 之类），稍后再查。
final class PurchasePending extends PurchaseResult {
  const PurchasePending();
}

/// 失败。[reason] 是给日志看的原因。
final class PurchaseFailed extends PurchaseResult {
  final String reason;

  const PurchaseFailed(this.reason);
}

/// 平台支付通道 —— **各端 app 自己实现**（Android Play Billing / iOS StoreKit / 桌面的假实现）。
///
/// 框架不碰平台 SDK，也不碰回执：
/// [PurchaseSuccess.verified] 由实现方决定，没验过签的结果不给开会员
/// （见 [MembershipManager.purchase]）。
abstract class BillingProvider {
  /// 当前可买的商品（价格文案用商店给的）。
  Future<List<Product>> products();

  /// 发起购买。
  Future<PurchaseResult> purchase(String productId);

  /// 恢复购买（换设备 / 重装后用）。
  Future<PurchaseResult> restorePurchases();
}
