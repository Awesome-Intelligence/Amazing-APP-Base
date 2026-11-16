import 'dart:async';

import 'access.dart';
import 'billing.dart';
import 'membership_state.dart';
import 'membership_store.dart';
import 'plan.dart';
import 'usage_tracker.dart';

/// 会员 + 额度的门面 —— 业务代码只跟这一层打交道。
///
/// 规矩：
/// - 会员资格只认**已验签**的状态（[Membership.verified]）
/// - 过期 / 没验签 / 找不到档位 → 一律按免费档算
/// - 额度用 [consume] 扣，别自己加（扣了才知道超没超）
class MembershipManager {
  final PlanCatalog catalog;
  final MembershipStore store;
  final UsageTracker usage;

  /// 时钟（测试可以注入假的）。
  final int Function() now;

  Membership _current = Membership.free();
  final StreamController<Membership> _controller =
      StreamController<Membership>.broadcast();

  MembershipManager({
    required this.catalog,
    required this.store,
    required this.usage,
    this.now = _systemNow,
  });

  /// 当前会员状态（UI 可以用 [membership] stream 监听，或用 [current] 同步读）。
  Membership get current => _current;

  /// 当前生效的档位（过期就回免费档）。
  Plan get plan => effectivePlan(_current);

  /// 会员状态流（每次激活/刷新都会发新值）。
  Stream<Membership> get membership => _controller.stream;

  /// 读本地状态（app 启动时调一次）。
  Future<void> refresh() async {
    _current = await store.load();
    _emit();
  }

  /// 有没有这个权益点。
  bool has(String entitlement) => plan.entitlements.contains(entitlement);

  /// 要某个权益点：没有就返回 [AccessBlocked]。
  Access checkEntitlement(String entitlement) => has(entitlement)
      ? const AccessAllowed()
      : AccessBlocked(entitlement, -1, BlockReason.noEntitlement);

  /// 查额度：没超放行，超了返回 [AccessBlocked]。
  Future<Access> check(String key) async {
    final limit = plan.limits[key];
    if (limit == null) return const AccessAllowed();
    final used = await usage.used(key, limit.period, now());
    return used >= limit.limit
        ? AccessBlocked(key, limit.limit, BlockReason.quotaExceeded)
        : const AccessAllowed();
  }

  /// 还剩多少次额度（null = 不限）。给 UI 显示「今日剩 N 次」用。
  Future<int?> remaining(String key) async {
    final limit = plan.limits[key];
    if (limit == null) return null;
    final used = await usage.used(key, limit.period, now());
    final left = limit.limit - used;
    return left < 0 ? 0 : left;
  }

  /// 扣一次额度：没超就扣并放行，超了不动计数。
  Future<Access> consume(String key, [int amount = 1]) async {
    final access = await check(key);
    if (access is AccessBlocked) return access;
    final limit = plan.limits[key];
    if (limit != null) {
      await usage.consume(key, limit.period, amount, now());
    }
    return const AccessAllowed();
  }

  /// 直接设置会员状态（试用码、运营发码、支付成功后都用它）。
  Future<void> activate(String planId,
      {int? expiresAt, bool verified = true}) async {
    final next = Membership(
      planId: planId,
      expiresAt: expiresAt,
      verified: verified,
    );
    await store.save(next);
    _current = next;
    _emit();
  }

  /// 走通道买一单：只有「成功且验过签」才开会员。
  Future<PurchaseResult> purchase(BillingProvider provider, String productId) async =>
      _handle(await provider.purchase(productId));

  /// 恢复购买：同样只有验过签才开会员。
  Future<PurchaseResult> restore(BillingProvider provider) async =>
      _handle(await provider.restorePurchases());

  Future<PurchaseResult> _handle(PurchaseResult result) async {
    if (result is PurchaseSuccess) {
      if (result.verified) {
        await activate(result.productId, expiresAt: result.expiresAt);
        return result;
      }
      return const PurchaseFailed('购买结果未通过校验');
    }
    return result;
  }

  Plan effectivePlan(Membership membership) {
    final plan = catalog.byId(membership.planId) ?? catalog.free;
    if (!membership.isActive(now())) return catalog.free;
    // 付费档必须验过签，否则按免费算
    if (plan.tier > 0 && !membership.verified) return catalog.free;
    return plan;
  }

  void _emit() {
    if (!_controller.isClosed) _controller.add(_current);
  }

  /// 释放内部流。app 退出时调用。
  void dispose() => _controller.close();
}

int _systemNow() => DateTime.now().millisecondsSinceEpoch;
