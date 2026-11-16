/// kit 的 **IO 层**：依赖 `dart:io` 的实现。
///
/// 为什么单独一个入口，而不是塞进 `kit.dart`：
/// `kit.dart` 要能被 Web / 小程序工具链编译，而 `dart:io` 在那些环境里不存在。
/// 移动端 / 桌面 / CLI 从 `package:kit/kit_io.dart` 拿文件版实现，
/// Web 用各自的替代实现（localStorage 等），互不影响。
///
/// 对应 KMP 那边「实现放 `androidMain`/`desktopMain`、不进 commonMain」的做法 ——
/// Dart 没有 source set，用「分入口导出」达到同样的编译期隔离。
library;

export 'src/storage/file_entity_store.dart';
export 'src/update/file_update_state_store.dart';
