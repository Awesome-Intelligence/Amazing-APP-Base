import 'package:demo/main.dart' show demoAppVersion;
import 'package:demo/update_gate.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kit/kit.dart';
import 'package:kit/kit_ui.dart';

/// 脚本化假来源：想返回什么就返回什么，不联网。
class _FakeSource implements UpdateSource {
  UpdateManifest? manifest;
  _FakeSource([this.manifest]);

  @override
  Future<UpdateManifest> fetch() async => manifest!;
}

void main() {
  Future<UpdateChecker> checkerFor(UpdateManifest manifest,
      {MemoryUpdateStateStore? store}) {
    return Future.value(
      UpdateChecker(
        source: _FakeSource(manifest),
        stateStore: store ?? MemoryUpdateStateStore(),
      ),
    );
  }

  Future<void> pumpGate(
    WidgetTester tester, {
    required UpdateChecker? checker,
    Future<void> Function(String url)? onOpenDownload,
  }) async {
    await tester.pumpWidget(
      KitApp(
        style: ThemeStyle.mono,
        home: UpdateGate(
          currentVersion: demoAppVersion,
          checker: checker,
          onOpenDownload: onOpenDownload ?? (_) async {},
          child: const Scaffold(body: Center(child: Text('业务页面'))),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('没有检查器（没配 dart-define）→ 完全静默，业务页面照常', (tester) async {
    await pumpGate(tester, checker: null);

    expect(find.text('业务页面'), findsOneWidget);
    expect(find.text('发现新版本'), findsNothing);
  });

  testWidgets('已是最新 → 不弹窗', (tester) async {
    final checker = await checkerFor(
      const UpdateManifest(latestVersion: demoAppVersion),
    );
    await pumpGate(tester, checker: checker);

    expect(find.text('发现新版本'), findsNothing);
  });

  testWidgets('有新版本 → 弹窗，业务页面仍在下面', (tester) async {
    final checker = await checkerFor(
      const UpdateManifest(
        latestVersion: '1.4.0',
        downloadUrl: 'https://example.com/app',
        releaseNotes: '- 修复登录闪退',
      ),
    );
    await pumpGate(tester, checker: checker);

    expect(find.text('发现新版本'), findsOneWidget);
    expect(find.text('业务页面'), findsOneWidget);
    expect(find.textContaining('修复登录闪退'), findsOneWidget);
  });

  testWidgets('点「稍后」→ 弹窗关掉，不打开链接', (tester) async {
    var opened = 0;
    final checker = await checkerFor(
      const UpdateManifest(
        latestVersion: '1.4.0',
        downloadUrl: 'https://example.com/app',
      ),
    );
    await pumpGate(
      tester,
      checker: checker,
      onOpenDownload: (_) async => opened++,
    );

    await tester.tap(find.text('稍后'));
    await tester.pumpAndSettle();

    expect(find.text('发现新版本'), findsNothing);
    expect(opened, 0);
  });

  testWidgets('点「立即更新」→ 打开清单里的下载地址；非强制时关掉弹窗', (tester) async {
    String? openedUrl;
    final checker = await checkerFor(
      const UpdateManifest(
        latestVersion: '1.4.0',
        downloadUrl: 'https://example.com/app-1.4.0.apk',
      ),
    );
    await pumpGate(
      tester,
      checker: checker,
      onOpenDownload: (url) async => openedUrl = url,
    );

    await tester.tap(find.text('立即更新'));
    await tester.pumpAndSettle();

    expect(openedUrl, 'https://example.com/app-1.4.0.apk');
    expect(find.text('发现新版本'), findsNothing);
  });

  testWidgets('点「跳过此版本」→ 落盘，下次自动检查不再提示', (tester) async {
    final store = MemoryUpdateStateStore();
    final checker = await checkerFor(
      const UpdateManifest(
        latestVersion: '1.4.0',
        downloadUrl: 'https://example.com/app',
      ),
      store: store,
    );
    await pumpGate(tester, checker: checker);

    await tester.tap(find.text('跳过此版本'));
    await tester.pumpAndSettle();

    expect((await store.load()).skippedVersion, '1.4.0');
    expect(find.text('发现新版本'), findsNothing);
  });

  testWidgets('强制更新 → 标题变「需要更新」，没有稍后/跳过', (tester) async {
    final checker = await checkerFor(
      const UpdateManifest(
        latestVersion: '2.0.0',
        minSupportedVersion: '1.5.0',
        downloadUrl: 'https://example.com/app',
      ),
    );
    await pumpGate(tester, checker: checker);

    expect(find.text('需要更新'), findsOneWidget);
    expect(find.text('稍后'), findsNothing);
    expect(find.text('跳过此版本'), findsNothing);
  });

  testWidgets('强制更新点「立即更新」→ 打开链接后继续挡着（弹窗还在）', (tester) async {
    var opened = 0;
    final checker = await checkerFor(
      const UpdateManifest(
        latestVersion: '2.0.0',
        minSupportedVersion: '1.5.0',
        downloadUrl: 'https://example.com/app',
      ),
    );
    await pumpGate(
      tester,
      checker: checker,
      onOpenDownload: (_) async => opened++,
    );

    await tester.tap(find.text('立即更新'));
    await tester.pumpAndSettle();

    expect(opened, 1);
    expect(find.text('需要更新'), findsOneWidget,
        reason: '强制更新时用户没更新成功就还得挡着');
  });

  testWidgets('强制更新但清单没给下载地址 → 降级成可关闭，不留死胡同', (tester) async {
    final checker = await checkerFor(
      const UpdateManifest(
        latestVersion: '2.0.0',
        minSupportedVersion: '1.5.0',
      ),
    );
    await pumpGate(tester, checker: checker);

    expect(find.text('发现新版本'), findsOneWidget, reason: '没有下载地址就不能强制');
    expect(find.text('稍后'), findsOneWidget);
    expect(find.text('跳过此版本'), findsOneWidget);
  });

  testWidgets('打开链接抛异常 → 不把 app 弄崩', (tester) async {
    final checker = await checkerFor(
      const UpdateManifest(
        latestVersion: '1.4.0',
        downloadUrl: 'https://example.com/app',
      ),
    );
    await pumpGate(
      tester,
      checker: checker,
      onOpenDownload: (_) async => throw Exception('没有浏览器'),
    );

    await tester.tap(find.text('立即更新'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('发现新版本'), findsNothing);
  });
}
