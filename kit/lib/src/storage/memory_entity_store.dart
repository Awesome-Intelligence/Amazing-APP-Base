import 'stored_entity.dart';

/// 内存版 [EntityStore] —— 测试与无持久化场景用（等价「重启即丢」）。
///
/// 内部用 `subdir/filename` 为 key 存原文/字节，binary 共存。
class MemoryEntityStore implements EntityStore {
  final StoreCodec codec;
  final Map<String, Object> _files = {};

  MemoryEntityStore(this.codec);

  String _key(String subdir, String filename) => '$subdir/$filename';

  List<String> _subdirKeys(String subdir) =>
      _files.keys.where((k) => k.startsWith('$subdir/')).toList();

  @override
  Future<void> write(String subdir, StoredEntity entity) async {
    _files[_key(subdir, '${entity.id}${codec.extension}')] =
        codec.encode(entity);
  }

  @override
  Future<StoredEntity?> read(String subdir, String entityId) async {
    final raw = _files[_key(subdir, '$entityId${codec.extension}')];
    if (raw is String) return codec.decode(entityId, raw);
    return null;
  }

  @override
  Future<bool> delete(String subdir, String entityId) async =>
      deleteFile(subdir, '$entityId${codec.extension}');

  @override
  Future<bool> deleteFile(String subdir, String filename) async {
    final key = _key(subdir, filename);
    return _files.remove(key) != null;
  }

  @override
  Future<List<String>> listIds(String subdir) async => _subdirKeys(subdir)
      .where((k) => k.endsWith(codec.extension))
      .map((k) => k.substring('$subdir/'.length, k.length - codec.extension.length))
      .toList();

  @override
  Future<List<String>> listBinaryFilenames(String subdir) async =>
      _subdirKeys(subdir)
          .where((k) => !k.endsWith(codec.extension))
          .map((k) => k.substring('$subdir/'.length))
          .toList();

  @override
  Future<List<StoredEntity>> loadAll(String subdir) async => _subdirKeys(subdir)
      .where((k) => k.endsWith(codec.extension))
      .map((k) {
        final id = k.substring('$subdir/'.length, k.length - codec.extension.length);
        final raw = _files[k];
        return raw is String ? codec.decode(id, raw) : null;
      })
      .whereType<StoredEntity>()
      .toList();

  @override
  Future<void> writeBinary(
    String subdir,
    String filename,
    List<int> bytes,
    String mimeType,
  ) async {
    _files[_key(subdir, filename)] = List<int>.from(bytes);
  }

  @override
  Future<List<int>?> readBinary(String subdir, String filename) async {
    final v = _files[_key(subdir, filename)];
    return v is List<int> ? v : null;
  }

  @override
  String? imageUri(String subdir, String filename) {
    final key = _key(subdir, filename);
    return _files.containsKey(key) ? key : null;
  }
}
