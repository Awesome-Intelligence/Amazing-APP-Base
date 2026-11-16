import 'dart:convert';

/// 存储后端抽象 —— 不绑定文件格式、不绑定平台。
///
/// 核心逻辑层只依赖这个接口，落盘由调用方注入具体实现
/// （桌面/移动用文件后端，Web 用 localStorage / shared_preferences 后端）。
abstract class StorageBackend {
  /// 读出整个文件内容；不存在返回 null。
  Future<String?> read();

  /// 写整个文件内容；传 null 可清除。
  Future<void> write(String? content);
}

/// 纯内存后端 —— 测试与无持久化场景用（等价「重启即丢」）。
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

/// 一个 JSON 文件的读写（app 内部存储）。
///
/// 读不懂就用默认值 —— 会员文件坏了不该让 app 起不来
/// （跟 kit 的 SettingsStore 一个路子）。
class JsonFile<T> {
  final StorageBackend backend;
  final T Function(Map<String, dynamic>) _fromJson;
  final Map<String, dynamic> Function(T) _toJson;
  final T _default;

  const JsonFile(this.backend, this._fromJson, this._toJson, this._default);

  static const JsonCodec _json = JsonCodec();

  /// 读文件；文件不存在或读坏了都返回默认值。
  Future<T> read() async {
    final raw = await backend.read();
    if (raw == null) return _default;
    try {
      return _fromJson(_json.decode(raw) as Map<String, dynamic>);
    } catch (_) {
      return _default;
    }
  }

  /// 写文件（覆盖整个文件）。
  Future<void> write(T value) async {
    await backend.write(_json.encode(_toJson(value)));
  }
}
