/// 单文件存储后端抽象 —— 设置等「一个文件一份数据」用它。
///
/// 核心逻辑层只依赖这个接口，落盘由调用方注入具体实现
/// （桌面/移动用文件后端，Web 用 localStorage 后端）。
abstract class StorageBackend {
  Future<String?> read();

  Future<void> write(String? content);
}

/// 纯内存后端 —— 测试与无持久化场景用。
class MemoryStorageBackend implements StorageBackend {
  String? _content;

  String? get lastWritten => _content;

  @override
  Future<String?> read() async => _content;

  @override
  Future<void> write(String? content) async {
    _content = content;
  }
}
