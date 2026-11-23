import 'update_manifest.dart';

/// 一次版本检查的结果 —— UI 只认这几种，不需要接异常。
sealed class UpdateResult {
  const UpdateResult();
}

/// 当前已是最新（或比远端还新）。
class UpToDateResult extends UpdateResult {
  const UpToDateResult();
}

/// 距离上次检查太近，这次没联网。不是错误，别提示用户。
class ThrottledResult extends UpdateResult {
  const ThrottledResult();
}

/// 用户主动跳过了这个版本，且没有更强的更新理由。
class SkippedResult extends UpdateResult {
  const SkippedResult();
}

/// 有新版本。
///
/// [mandatory] 为 true 表示当前版本低于清单里的 `minSupportedVersion`，
/// UI 必须挡住入口（弹窗不可关闭）；否则可以让用户“稍后”或“跳过此版本”。
class AvailableResult extends UpdateResult {
  final UpdateManifest manifest;
  final bool mandatory;

  const AvailableResult({required this.manifest, this.mandatory = false});
}

/// 检查失败（网络、清单格式…）。[message] 只用于日志/排查，不建议直接弹给用户。
class FailedResult extends UpdateResult {
  final String message;

  const FailedResult(this.message);
}
