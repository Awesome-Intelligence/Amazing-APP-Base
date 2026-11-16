import 'package:kit_membership/membership.dart';

/// demo 用的假商店 —— 真机上是 Play Billing / StoreKit。
///
/// 三件事要跟真商店对齐，否则接真的时候会露馅：
/// 1. **价格文案由商店给**（`Product.price`），业务别自己拼 —— 各地区的
///    币种、含税与否、折扣档位都在商店那边定。
/// 2. **买成功要验签**（`PurchaseSuccess.verified`）。没验过的结果
///    `MembershipManager` 会拒掉，直接按免费档算。
/// 3. **恢复购买是独立入口**，换设备/重装后靠它把已买的拿回来。
class DemoBilling implements BillingProvider {
  /// 这个假商店「已经买过」的商品 id —— 恢复购买读它。
  String? _owned;

  @override
  Future<List<Product>> products() async => const [
        Product(
          id: 'premium',
          title: '高级版',
          price: '¥28 / 月',
          description: '每天 100 次 AI，解锁导出',
        ),
        Product(
          id: 'pro',
          title: '专业版',
          price: '¥68 / 月',
          description: '每天 300 次 AI，解锁导出与全部主题',
        ),
      ];

  @override
  Future<PurchaseResult> purchase(String productId) async {
    // 假装走了一趟支付 —— 真实现这里 await 平台通道，几秒到几十秒。
    await Future<void>.delayed(const Duration(milliseconds: 300));
    _owned = productId;
    return PurchaseSuccess(
      productId: productId,
      // 订阅一年。真实现用商店返回的到期时间。
      expiresAt: DateTime.now()
          .add(const Duration(days: 365))
          .millisecondsSinceEpoch,
      // 真实现是回执验签 / 服务端核对。这里恒真。
      verified: true,
    );
  }

  @override
  Future<PurchaseResult> restorePurchases() async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    final owned = _owned;
    if (owned == null) return const PurchaseFailed('没有可恢复的购买');
    return PurchaseSuccess(
      productId: owned,
      expiresAt: DateTime.now()
          .add(const Duration(days: 365))
          .millisecondsSinceEpoch,
      verified: true,
    );
  }
}
