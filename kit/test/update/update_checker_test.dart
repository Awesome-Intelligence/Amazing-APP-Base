import 'package:flutter_test/flutter_test.dart';
import 'package:kit/kit.dart';

/// 脚本化的假来源：想让它返回什么就返回什么，想让它是失败就失败。
class _FakeSource implements UpdateSource {
  UpdateManifest? manifest;
  Object? error;
  int calls = 0;

  _FakeSource({this.manifest, this.error});

  @override
  Future<UpdateManifest> fetch() async {
    calls++;
    final e = error;
    if (e != null) throw e is Exception ? e : Exception('$e');
    return manifest!;
  }
}

void main() {
  late MemoryUpdateStateStore stateStore;
  late int now;
  const sixHours = 6 * 60 * 60 * 1000;

  setUp(() {
    stateStore = MemoryUpdateStateStore();
    now = 1700000000000;
  });

  UpdateChecker checkerWith(_FakeSource source,
          {UpdateCheckPolicy policy = const UpdateCheckPolicy()}) =>
      UpdateChecker(
        source: source,
        stateStore: stateStore,
        policy: policy,
        nowMillis: () => now,
      );

  test('远端更新 → Available，带清单', () async {
    final source = _FakeSource(
      manifest: const UpdateManifest(
        latestVersion: '1.4.0',
        downloadUrl: 'https://example.com/app.apk',
        releaseNotes: '- 修复',
      ),
    );
    final result = await checkerWith(source).check('1.2.0');
    expect(result, isA<AvailableResult>());
    expect((result as AvailableResult).manifest.latestVersion, '1.4.0');
    expect(result.mandatory, isFalse);
  });

  test('已是最新 → UpToDate', () async {
    final source = _FakeSource(manifest: const UpdateManifest(latestVersion: '1.2.0'));
    expect(await checkerWith(source).check('1.2.0'), isA<UpToDateResult>());
  });

  test('当前版本比远端还新 → UpToDate', () async {
    final source = _FakeSource(manifest: const UpdateManifest(latestVersion: '1.0.0'));
    expect(await checkerWith(source).check('2.0.0'), isA<UpToDateResult>());
  });

  test('六小时内第二次自动检查 → Throttled，且不联网', () async {
    final source = _FakeSource(manifest: const UpdateManifest(latestVersion: '1.4.0'));
    final checker = checkerWith(source);

    await checker.check('1.2.0');
    expect(source.calls, 1);

    now += 60 * 1000; // 一分钟后再查
    expect(await checker.check('1.2.0'), isA<ThrottledResult>());
    expect(source.calls, 1, reason: '被节流时不该发请求');
  });

  test('超过间隔后恢复检查', () async {
    final source = _FakeSource(manifest: const UpdateManifest(latestVersion: '1.4.0'));
    final checker = checkerWith(source);
    await checker.check('1.2.0');
    now += sixHours + 1;
    expect(await checker.check('1.2.0'), isA<AvailableResult>());
    expect(source.calls, 2);
  });

  test('force 绕过节流', () async {
    final source = _FakeSource(manifest: const UpdateManifest(latestVersion: '1.4.0'));
    final checker = checkerWith(source);
    await checker.check('1.2.0');
    expect(await checker.check('1.2.0', force: true), isA<AvailableResult>());
    expect(source.calls, 2);
  });

  test('跳过此版本后 → Skipped；force 手动检查时跳过不生效', () async {
    final source = _FakeSource(manifest: const UpdateManifest(latestVersion: '1.4.0'));
    final checker = checkerWith(source);
    await checker.skip('1.4.0');

    // 自动检查：用户点过“跳过”，不再提示
    expect(await checker.check('1.2.0'), isA<SkippedResult>());

    // 手动检查：用户主动点“检查更新”，就是想看有没有新版
    expect(await checker.check('1.2.0', force: true), isA<AvailableResult>());
  });

  test('跳过 1.4.0 后出现 1.5.0 → 重新提示', () async {
    final source = _FakeSource(manifest: const UpdateManifest(latestVersion: '1.4.0'));
    final checker = checkerWith(source);
    await checker.skip('1.4.0');
    expect(await checker.check('1.2.0'), isA<SkippedResult>());

    source.manifest = const UpdateManifest(latestVersion: '1.5.0');
    now += sixHours + 1;
    final result = await checker.check('1.2.0');
    expect(result, isA<AvailableResult>());
    expect((result as AvailableResult).manifest.latestVersion, '1.5.0');
  });

  test('低于 minSupportedVersion → mandatory，跳过不生效', () async {
    final source = _FakeSource(
      manifest: const UpdateManifest(
        latestVersion: '2.0.0',
        minSupportedVersion: '1.5.0',
      ),
    );
    final checker = checkerWith(source);
    await checker.skip('2.0.0');

    final result = await checker.check('1.2.0');
    expect(result, isA<AvailableResult>());
    expect((result as AvailableResult).mandatory, isTrue,
        reason: '强制更新时用户点过“跳过”也得继续提示');
  });

  test('minSupportedVersion 写坏了 → 退化成不强制，但仍然提示', () async {
    final source = _FakeSource(
      manifest: const UpdateManifest(
        latestVersion: '2.0.0',
        minSupportedVersion: '不是版本号',
      ),
    );
    final result = await checkerWith(source).check('1.2.0');
    expect(result, isA<AvailableResult>());
    expect((result as AvailableResult).mandatory, isFalse);
  });

  test('网络失败 → Failed，且记下检查时间（避免离线时反复等超时）', () async {
    final source = _FakeSource(error: Exception('连不上'));
    final checker = checkerWith(source);

    final result = await checker.check('1.2.0');
    expect(result, isA<FailedResult>());

    final state = await stateStore.load();
    expect(state.lastCheckedAtMillis, now, reason: '失败也要记时间');

    now += 60 * 1000;
    expect(await checker.check('1.2.0'), isA<ThrottledResult>());
  });

  test('当前版本号非法 → Failed', () async {
    final source = _FakeSource(manifest: const UpdateManifest(latestVersion: '1.4.0'));
    final result = await checkerWith(source).check('不是版本号');
    expect(result, isA<FailedResult>());
  });

  test('远端版本号非法 → Failed', () async {
    final source = _FakeSource(manifest: const UpdateManifest(latestVersion: '乱码'));
    final result = await checkerWith(source).check('1.2.0');
    expect(result, isA<FailedResult>());
  });

  test('系统时间往回调 → 不节流，直接放行', () async {
    final source = _FakeSource(manifest: const UpdateManifest(latestVersion: '1.4.0'));
    final checker = checkerWith(source);
    await checker.check('1.2.0');

    now -= sixHours * 2; // 用户把时钟调回去了
    expect(await checker.check('1.2.0'), isA<AvailableResult>());
  });
}
