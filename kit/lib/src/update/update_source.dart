import 'update_manifest.dart';

/// 版本信息的来源 —— 换实现就换“从哪知道有新版本”。
/// 对应 KMP 的 `data/update/UpdateSource.kt`。
///
/// 底座自带两个实现：
/// - [HttpUpdateSource]：读一个静态 JSON 清单（推荐，能控制强制更新）
/// - [GitHubReleaseSource]：直接读 GitHub Releases（零托管，适合开源项目）
///
/// 失败请抛异常：由 `UpdateChecker` 统一兜成 `FailedResult`，UI 不需要处理异常。
abstract class UpdateSource {
  Future<UpdateManifest> fetch();
}
