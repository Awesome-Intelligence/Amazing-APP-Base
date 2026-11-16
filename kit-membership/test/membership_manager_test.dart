import 'package:kit_membership/membership.dart';
import 'package:test/test.dart';

/// 把 KMP 的 MembershipManagerTest 逐条翻译过来，验证 Dart 版语义等价。
void main() {
  final catalog = PlanCatalog([
    Plan(
      id: 'free',
      tier: 0,
      limits: {
        'ai': QuotaLimit(2, QuotaPeriod.daily),
        'goals': QuotaLimit(3, QuotaPeriod.total),
      },
    ),
    Plan(
      id: 'premium',
      tier: 1,
      entitlements: {'export'},
      limits: {
        'ai': QuotaLimit(100, QuotaPeriod.daily),
        'goals': QuotaLimit(100, QuotaPeriod.total),
      },
    ),
  ]);

  /// 固定时钟，测试自己往前拨。
  var now = 1700000000000;

  MembershipManager newManager() => MembershipManager(
        catalog: catalog,
        store: MembershipStore(MemoryStorageBackend()),
        usage: UsageTracker(MemoryStorageBackend()),
        now: () => now,
      );

  group('MembershipManager', () {
    test('免费档额度用尽即拦截', () async {
      final m = newManager();
      expect(await m.check('ai'), isA<AccessAllowed>());
      expect(await m.consume('ai'), isA<AccessAllowed>());
      expect(await m.consume('ai'), isA<AccessAllowed>());

      final blocked = await m.consume('ai') as AccessBlocked;
      expect(blocked.reason, BlockReason.quotaExceeded);
      expect(blocked.limit, 2);
    });

    test('每日额度次日重置', () async {
      final m = newManager();
      await m.consume('ai');
      await m.consume('ai');
      expect(await m.check('ai'), isA<AccessBlocked>());

      now += twoDays;
      expect(await m.check('ai'), isA<AccessAllowed>());
    });

    test('累计额度永不过期', () async {
      final m = newManager();
      for (var i = 0; i < 3; i++) await m.consume('goals');
      expect(await m.check('goals'), isA<AccessBlocked>());

      now += twoDays;
      expect(await m.check('goals'), isA<AccessBlocked>());
    });

    test('升级提高上限并授予权益', () async {
      final m = newManager();
      for (var i = 0; i < 2; i++) await m.consume('ai');
      expect(await m.check('ai'), isA<AccessBlocked>());

      await m.activate('premium');
      expect(m.has('export'), isTrue);
      expect(await m.check('ai'), isA<AccessAllowed>());
    });

    test('过期会员回退免费档', () async {
      final m = newManager();
      await m.activate('premium', expiresAt: now + 1000);
      expect(m.has('export'), isTrue);

      now += 2000;
      expect(m.plan.id, 'free');
      expect(m.checkEntitlement('export'), isA<AccessBlocked>());
    });

    test('未验签购买不开会员', () async {
      final m = newManager();
      final result = await m.purchase(
        _FakeProvider(PurchaseSuccess(productId: 'premium', verified: false)),
        'premium',
      );
      expect(result, isA<PurchaseFailed>());
      expect(m.plan.id, 'free');
    });

    test('已验签购买才开会员', () async {
      final m = newManager();
      final result = await m.purchase(
        _FakeProvider(PurchaseSuccess(
          productId: 'premium',
          expiresAt: now + 100000,
          verified: true,
        )),
        'premium',
      );
      expect(result, isA<PurchaseSuccess>());
      expect(m.plan.id, 'premium');
    });

    test('会员状态跨重启保留', () async {
      final store = MembershipStore(MemoryStorageBackend());
      final backend = MemoryStorageBackend();
      final usage = UsageTracker(backend);

      await MembershipManager(
        catalog: catalog,
        store: store,
        usage: usage,
        now: () => now,
      ).activate('premium');

      final reopened = MembershipManager(
        catalog: catalog,
        store: store,
        usage: usage,
        now: () => now,
      );
      await reopened.refresh();
      expect(reopened.plan.id, 'premium');
    });
  });
}

/// 用一个共享内存后端模拟「同一个目录」，验证 persistence 语义。
class _FakeProvider implements BillingProvider {
  final PurchaseResult result;
  _FakeProvider(this.result);

  @override
  Future<List<Product>> products() async =>
      [const Product(id: 'premium', title: '高级版', price: '¥28 / 月')];

  @override
  Future<PurchaseResult> purchase(String productId) async => result;

  @override
  Future<PurchaseResult> restorePurchases() async => result;
}

const twoDays = 2 * 24 * 60 * 60 * 1000;
