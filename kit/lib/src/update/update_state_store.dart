import 'update_state.dart';

/// 检查状态的持久化抽象。对应 KMP 的 `data/update/UpdateStateStore.kt`。
///
/// 抽成接口是为了测试：`UpdateChecker` 的节流/跳过逻辑不该依赖真实文件。
/// 生产用 `FileUpdateStateStore`（`dart:io`，移动端/桌面），Web 用自己实现的
/// localStorage 版本 —— 都实现这个接口。
abstract class UpdateStateStore {
  Future<UpdateState> load();
  Future<void> save(UpdateState state);
}

/// 内存实现：测试 / 预览 / Web 不想落盘时用。
class MemoryUpdateStateStore implements UpdateStateStore {
  UpdateState _state;

  MemoryUpdateStateStore([UpdateState? initial])
      : _state = initial ?? const UpdateState();

  @override
  Future<UpdateState> load() async => _state;

  @override
  Future<void> save(UpdateState state) async => _state = state;
}
