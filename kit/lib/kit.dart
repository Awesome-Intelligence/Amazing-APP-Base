/// kit —— Flutter 版通用层的**纯 Dart 数据层**。
///
/// 对应 KMP 的 `kit/` 里 `data/` 那部分：存储抽象、编解码、设置、跨端契约。
/// 这一层不依赖 Flutter，小程序端 / CLI / 契约校验都能直接用。
///
/// UI 层（主题 + 组件 + 文案）在 `package:kit/kit_ui.dart`。
///
/// 数据层导出（平台无关）：
/// - 存储抽象：`EntityStore` / `StoreCodec` / `StoredEntity`
/// - 编解码：`JsonCodec` / `MarkdownCodec`
/// - 字段取值：`Fields` extension
/// - 内存实现：`MemoryEntityStore` / `MemoryStorageBackend`
/// - 设置：`AppSettings` / `SettingsStore` / `AppLanguage` / `ThemeStyle` / `AppearanceMode`
/// - 跨端契约：`ActionContract` / `runActionSamples`
/// - 日期格式化：`KitDateFormat`（纯 Dart，不依赖 intl）
/// - 版本检查：`AppVersion` / `UpdateChecker` / `UpdateManifest` /
///   `HttpUpdateSource` / `GitHubReleaseSource` / `MemoryUpdateStateStore`
///
/// 注意：文件版实现（`FileEntityStore` / `FileStorageBackend` /
/// `FileUpdateStateStore`）依赖 `dart:io`，不在此导出，桌面/移动端按需
/// `import 'package:kit/src/storage/file_entity_store.dart'`。
library kit;

export 'src/storage/stored_entity.dart';
export 'src/storage/json_codec.dart';
export 'src/storage/markdown_codec.dart';
export 'src/storage/fields.dart';
export 'src/storage/memory_entity_store.dart';
export 'src/storage/storage_backend.dart';

export 'src/settings/app_language.dart';
export 'src/settings/theme_enums.dart';
export 'src/settings/app_settings.dart';

export 'src/contract/action_contract.dart';

export 'src/format/kit_date_format.dart';

// 版本检查（对应 KMP 的 data/update）。
// 这一层同样平台无关：HTTP 客户端由 App 注入，落盘实现按平台选。
export 'src/update/app_version.dart';
export 'src/update/update_manifest.dart';
export 'src/update/update_result.dart';
export 'src/update/update_source.dart';
export 'src/update/update_state.dart';
export 'src/update/update_state_store.dart';
export 'src/update/update_check_policy.dart';
export 'src/update/update_checker.dart';
export 'src/update/http_update_source.dart';
export 'src/update/github_release_source.dart';
