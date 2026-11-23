import 'app_version.dart';
import 'update_check_policy.dart';
import 'update_manifest.dart';
import 'update_result.dart';
import 'update_source.dart';
import 'update_state.dart';
import 'update_state_store.dart';

/// “自动发现新版本”的唯一入口。
///
/// 它只做三件事：**节流 → 拉清单 → 比版本**，不发通知、不弹窗、不下载 ——
/// 那些是 UI 和 App 的决定（见 `UpdateDialog` 和 `apps/demo` 的 `UpdateGate`）。
///
/// ```dart
/// final checker = UpdateChecker(
///   source: HttpUpdateSource(client, 'https://example.com/latest.json'),
///   stateStore: FileUpdateStateStore(appDir),
/// );
/// // 冷启动/回到前台时调一次；节流会挡住高频调用
/// final result = await checker.check(currentVersion);
/// if (result is AvailableResult) showUpdateDialog(result);
/// // 失败静默：更新检查不该打扰正在用 app 的人
/// ```
///
/// `currentVersion` 是字符串参数而不是从包里读：kit 里没有构建配置概念，
/// 也不做平台接口 —— 各端各自把版本号传进来（Android `versionName`、
/// iOS `CFBundleShortVersionString`、Web 打包版本）。
///
/// [nowMillis] 可注入，测试里用来把时间钉死。
class UpdateChecker {
  final UpdateSource source;
  final UpdateStateStore stateStore;
  final UpdateCheckPolicy policy;
  final int Function() nowMillis;

  UpdateChecker({
    required this.source,
    required this.stateStore,
    this.policy = const UpdateCheckPolicy(),
    int Function()? nowMillis,
  }) : nowMillis =
            nowMillis ?? (() => DateTime.now().millisecondsSinceEpoch);

  /// 检查一次。
  ///
  /// [force] 手动检查：绕过节流和“跳过此版本”。UI 的“检查更新”按钮传 true。
  Future<UpdateResult> check(
    String currentVersion, {
    bool force = false,
  }) async {
    try {
      return await _checkInternal(currentVersion, force);
    } on Exception catch (e) {
      // 落盘失败之类的意外也不该把 app 弄崩
      return FailedResult('检查更新失败：$e');
    }
  }

  Future<UpdateResult> _checkInternal(
    String currentVersion,
    bool force,
  ) async {
    final now = nowMillis();
    final state = await stateStore.load();
    if (!force && _isThrottled(state, now)) return const ThrottledResult();

    final current = AppVersion.parseOrNull(currentVersion);
    if (current == null) {
      return FailedResult('当前版本号无法解析：$currentVersion');
    }

    // late final + catch 里 return：Dart 的流分析能确认“走到下一行就一定有值”
    late final UpdateManifest manifest;
    try {
      manifest = await source.fetch();
    } on Exception catch (e) {
      // 失败也记时间：否则离线用户每次冷启动都要白等一次超时
      await stateStore.save(state.copyWith(lastCheckedAtMillis: now));
      return FailedResult('检查更新失败：$e');
    }
    await stateStore.save(state.copyWith(lastCheckedAtMillis: now));

    final latest = AppVersion.parseOrNull(manifest.latestVersion);
    if (latest == null) {
      return FailedResult('远端版本号无法解析：${manifest.latestVersion}');
    }
    if (latest <= current) return const UpToDateResult();

    // 清单写错了就当作“不强制”，但仍然提示新版本 ——
    // 不能因为一个字段让更新提示整个消失
    final rawMinimum = manifest.minSupportedVersion;
    final minimum =
        rawMinimum == null ? null : AppVersion.parseOrNull(rawMinimum);
    final mandatory = minimum != null && current < minimum;

    // 手动检查时跳过记录不生效：用户点“检查更新”就是想看有没有新版
    if (!force && !mandatory && state.skippedVersion == manifest.latestVersion) {
      return const SkippedResult();
    }
    return AvailableResult(manifest: manifest, mandatory: mandatory);
  }

  /// 用户点了“跳过此版本”：只影响这个版本号，出现更新的版本会自动重新提示。
  Future<void> skip(String version) async {
    final state = await stateStore.load();
    await stateStore.save(state.copyWith(skippedVersion: version));
  }

  bool _isThrottled(UpdateState state, int now) {
    if (state.lastCheckedAtMillis <= 0) return false;
    // 用户把系统时间往回调过：别让“上次检查”永远在未来，直接放行
    if (now <= state.lastCheckedAtMillis) return false;
    return now - state.lastCheckedAtMillis < policy.minInterval.inMilliseconds;
  }
}
