/// 检查更新状态的落盘工厂 —— 平台差异只在这一处。
///
/// - 移动端 / 桌面：`FileUpdateStateStore`（`path_provider` 给目录）
/// - Web：没有文件系统，退化成内存实现（节流状态不跨刷新，可接受）
///
/// `dart:io` 在 Web 上不存在，所以这里用条件导出而不是 `if (kIsWeb)`
/// —— 后者救不了编译期。
library;

export 'update_state_store_factory_io.dart'
    if (dart.library.js_interop) 'update_state_store_factory_web.dart';
