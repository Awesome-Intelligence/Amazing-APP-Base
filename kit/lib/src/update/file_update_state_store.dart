import 'dart:convert';
import 'dart:io';

import 'update_state.dart';
import 'update_state_store.dart';

/// 把 [UpdateState] 落到一个 JSON 文件（app 内部存储，移动端/桌面通用）。
/// 目录由调用方给（`getApplicationSupportDirectory()` / 测试用临时目录），
/// 和 `FileEntityStore` 一个路子。读坏了就退回默认状态 ——
/// 检查更新失败不该影响 app 启动。
///
/// 依赖 `dart:io`，所以**不导出**在 `package:kit/kit.dart` 里（Web 用不了）；
/// 需要时显式 `import 'package:kit/src/update/file_update_state_store.dart'`。
class FileUpdateStateStore implements UpdateStateStore {
  final Directory rootDir;

  FileUpdateStateStore(this.rootDir);

  static const String fileName = 'update-state.json';

  File get _file => File('${rootDir.path}${Platform.pathSeparator}$fileName');

  @override
  Future<UpdateState> load() async {
    try {
      final file = _file;
      if (!await file.exists()) return const UpdateState();
      final raw = await file.readAsString();
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, Object?>) return const UpdateState();
      return UpdateState.fromJson(decoded);
    } on Exception {
      // 文件坏了 / 权限不对：当成没检查过，别让 app 启动失败
      return const UpdateState();
    }
  }

  @override
  Future<void> save(UpdateState state) async {
    try {
      final dir = rootDir;
      if (!await dir.exists()) await dir.create(recursive: true);
      await _file.writeAsString(jsonEncode(state.toJson()), flush: true);
    } on Exception {
      // 写不进去也不抛：下次检查多打一次网络，比崩掉好
    }
  }
}
