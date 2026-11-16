import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kit/kit.dart';
import 'package:kit/kit_ui.dart';

/// 会员 UI：付费墙（会员 / 额度）+ 升级面板。
///
/// 这几块只有一个地方真正会错：**当前方案是否被正确禁用** ——
/// 用户买了高级版还能再点一次「购买」，就是白扣一次钱。
/// 其余测的是「文案有没有拼错、回调有没有接错头」。
void main() {
  Future<void> pumpShell(
    WidgetTester tester,
    Widget child, {
    AppSettings settings = const AppSettings(language: AppLanguage.chinese),
  }) {
    return tester.pumpWidget(
      KitAppShell(settings: settings, home: Scaffold(body: child)),
    );
  }

  // 档位表：两个付费档，高级版是「当前方案」，年付是可以买的。
  const premium = Plan(
    id: 'premium',
    tier: 1,
    entitlements: {'export'},
    limits: {'ai': QuotaLimit(100, QuotaPeriod.daily)},
  );
  const yearly = Plan(
    id: 'yearly',
    tier: 2,
    entitlements: {'export', 'themes'},
    limits: {'ai': QuotaLimit(300, QuotaPeriod.daily)},
  );

  const options = [
    PlanOption(
      plan: premium,
      title: '高级版',
      price: '¥28 / 月',
      features: [
        PlanFeature('导出数据'),
        PlanFeature('每天 AI 次数', '100'),
      ],
    ),
    PlanOption(
      plan: yearly,
      title: '年付版',
      price: '¥268 / 年',
      features: [PlanFeature('含高级版全部权益'), PlanFeature('主题全部解锁')],
    ),
  ];

  group('会员付费墙', () {
    testWidgets('渲染标题、业务文案、升级按钮', (tester) async {
      await pumpShell(
        tester,
        const MembershipPaywall(
          message: '导出需要会员',
          onUpgradeClick: _noop,
          onDismiss: _noop,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('需要会员才能继续'), findsOneWidget);
      expect(find.text('导出需要会员'), findsOneWidget);
      expect(find.text('查看会员方案'), findsOneWidget);
      expect(find.text('取消'), findsOneWidget);
    });

    testWidgets('点「查看会员方案」走升级回调，点「取消」走关闭回调', (tester) async {
      var upgrades = 0;
      var dismisses = 0;
      await pumpShell(
        tester,
        MembershipPaywall(
          message: '导出需要会员',
          onUpgradeClick: () => upgrades++,
          onDismiss: () => dismisses++,
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('查看会员方案'));
      await tester.pump();
      expect(upgrades, 1);
      expect(dismisses, 0);

      await tester.tap(find.text('取消'));
      await tester.pump();
      expect(upgrades, 1);
      expect(dismisses, 1);
    });

    testWidgets('show() 点升级返回 true，点取消返回 false', (tester) async {
      // 弹窗要点两次、结果不同，所以开两个独立的 pump 循环。
      Future<bool> runAndTap(String button) async {
        bool? result;
        await pumpShell(
          tester,
          Builder(
            builder: (context) => Center(
              child: FilledButton(
                onPressed: () async {
                  result = await MembershipPaywall.show(
                    context,
                    message: '导出需要会员',
                  );
                },
                child: const Text('触发'),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.text('触发'));
        await tester.pumpAndSettle();
        await tester.tap(find.text(button));
        await tester.pumpAndSettle();
        return result!;
      }

      expect(await runAndTap('查看会员方案'), isTrue);
      expect(await runAndTap('取消'), isFalse);
    });
  });

  group('额度付费墙', () {
    test('三种原因的文案都带上当前上限', () {
      const s = KitStrings.chinese;
      expect(
        QuotaPaywall.messageFor(s, QuotaReason.goal, 5),
        '当前档位最多保存 5 个目标，升级后可以创建更多目标。',
      );
      expect(
        QuotaPaywall.messageFor(s, QuotaReason.contact, 50),
        '当前档位最多保存 50 位人脉，升级后可以添加更多人脉。',
      );
      expect(
        QuotaPaywall.messageFor(s, QuotaReason.ai, 3),
        '今天的 AI 次数已用完（当前档位每天 3 次），升级后可用更多次数。',
      );
    });

    test('英文文案同样是「上限 + 建议」结构', () {
      const s = KitStrings.english;
      expect(
        QuotaPaywall.messageFor(s, QuotaReason.ai, 3),
        "Today's AI calls are used up (3 per day on your current tier). "
        'Upgrade for more.',
      );
    });

    testWidgets('弹出来的是额度标题，不是会员标题', (tester) async {
      // 两个付费墙共用 ConfirmDialog，最容易出的错是复制粘贴后标题没换。
      await pumpShell(
        tester,
        const QuotaPaywall(
          reason: QuotaReason.ai,
          limit: 3,
          onUpgradeClick: _noop,
          onDismiss: _noop,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('额度已用完'), findsOneWidget);
      expect(find.text('需要会员才能继续'), findsNothing);
      expect(find.text('查看高级版'), findsOneWidget);
      expect(find.textContaining('每天 3 次'), findsOneWidget);
    });
  });

  group('升级面板', () {
    testWidgets('每个档位的标题、价格、权益都在', (tester) async {
      await pumpShell(
        tester,
        const UpgradeSheet(
          options: options,
          currentPlanId: 'premium',
          onPurchase: _noopId,
          onRestore: _noop,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('高级版'), findsOneWidget);
      expect(find.text('¥28 / 月'), findsOneWidget);
      expect(find.text('年付版'), findsOneWidget);
      expect(find.text('¥268 / 年'), findsOneWidget);
      expect(find.text('恢复购买'), findsOneWidget);
    });

    testWidgets('权益有条目时显示「名称：值」，没有条目时只显示名称', (tester) async {
      await pumpShell(
        tester,
        const UpgradeSheet(
          options: options,
          currentPlanId: null,
          onPurchase: _noopId,
          onRestore: _noop,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('导出数据'), findsOneWidget); // value 为空 → 不加冒号
      expect(find.text('每天 AI 次数：100'), findsOneWidget);
      expect(find.text('主题全部解锁'), findsOneWidget);
    });

    testWidgets('当前方案按钮显示「当前方案」且点不动', (tester) async {
      final purchased = <String>[];
      await pumpShell(
        tester,
        UpgradeSheet(
          options: options,
          currentPlanId: 'premium',
          onPurchase: purchased.add,
          onRestore: _noop,
        ),
      );
      await tester.pumpAndSettle();

      // 只有一个档位是当前方案，另一个仍可购买
      expect(find.text('当前方案'), findsOneWidget);
      expect(find.text('购买'), findsOneWidget);

      await tester.tap(find.text('当前方案'), warnIfMissed: false);
      await tester.pump();
      expect(purchased, isEmpty, reason: '当前方案不该能被再买一次');

      await tester.tap(find.text('购买'));
      await tester.pump();
      expect(purchased, ['yearly']);
    });

    testWidgets('没有当前方案时所有档位都可购买', (tester) async {
      await pumpShell(
        tester,
        const UpgradeSheet(
          options: options,
          currentPlanId: null,
          onPurchase: _noopId,
          onRestore: _noop,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('当前方案'), findsNothing);
      expect(find.text('购买'), findsNWidgets(2));
    });

    testWidgets('「恢复购买」是独立回调，不会误触发购买', (tester) async {
      final purchased = <String>[];
      var restores = 0;
      await pumpShell(
        tester,
        UpgradeSheet(
          options: options,
          currentPlanId: null,
          onPurchase: purchased.add,
          onRestore: () => restores++,
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('恢复购买'));
      await tester.pump();
      expect(restores, 1);
      expect(purchased, isEmpty);
    });

    testWidgets('show() 真的弹起面板，购买后回调拿到档位 id', (tester) async {
      final purchased = <String>[];
      await pumpShell(
        tester,
        Builder(
          builder: (context) => Center(
            child: FilledButton(
              onPressed: () => UpgradeSheet.show(
                context,
                options: options,
                currentPlanId: 'premium',
                onPurchase: purchased.add,
                onRestore: _noop,
              ),
              child: const Text('打开升级页'),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('打开升级页'));
      await tester.pumpAndSettle();

      expect(find.byType(UpgradeSheet), findsOneWidget);
      await tester.tap(find.text('购买'));
      await tester.pump();
      expect(purchased, ['yearly']);
    });
  });

  group('主题与语言', () {
    for (final style in ThemeStyle.values) {
      for (final dark in [false, true]) {
        testWidgets('${style.name} / ${dark ? '深' : '浅'} 下都能渲染', (tester) async {
          await pumpShell(
            tester,
            // 三个组件真实用法下是三个独立浮层，这里为了省事并排渲染 ——
            // 600px 高的测试画布装不下，包一层滚动只是为了让它们都建出来。
            SingleChildScrollView(
              child: Column(
                children: [
                  const MembershipPaywall(
                    message: '导出需要会员',
                    onUpgradeClick: _noop,
                    onDismiss: _noop,
                  ),
                  const QuotaPaywall(
                    reason: QuotaReason.goal,
                    limit: 5,
                    onUpgradeClick: _noop,
                    onDismiss: _noop,
                  ),
                  UpgradeSheet(
                    options: options,
                    currentPlanId: 'premium',
                    onPurchase: _noopId,
                    onRestore: _noop,
                  ),
                ],
              ),
            ),
            settings: AppSettings(
              language: AppLanguage.chinese,
              themeStyle: style,
              appearanceMode:
                  dark ? AppearanceMode.dark : AppearanceMode.light,
            ),
          );
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull, reason: '$style 渲染异常');
        });
      }
    }

    testWidgets('切英文后三处文案都跟着变', (tester) async {
      await pumpShell(
        tester,
        SingleChildScrollView(
          child: Column(
            children: [
              const MembershipPaywall(
                message: 'Export requires membership',
                onUpgradeClick: _noop,
                onDismiss: _noop,
              ),
              const QuotaPaywall(
                reason: QuotaReason.ai,
                limit: 3,
                onUpgradeClick: _noop,
                onDismiss: _noop,
              ),
              const UpgradeSheet(
                options: options,
                currentPlanId: 'premium',
                onPurchase: _noopId,
                onRestore: _noop,
              ),
            ],
          ),
        ),
        settings: const AppSettings(language: AppLanguage.english),
      );
      await tester.pumpAndSettle();

      expect(find.text('Membership required'), findsOneWidget);
      expect(find.text('View plans'), findsOneWidget);
      expect(find.text('Quota reached'), findsOneWidget);
      expect(find.text('View Premium'), findsOneWidget);
      expect(find.text('Current plan'), findsOneWidget);
      expect(find.text('Restore purchases'), findsOneWidget);
    });
  });
}

void _noop() {}

void _noopId(String _) {}
