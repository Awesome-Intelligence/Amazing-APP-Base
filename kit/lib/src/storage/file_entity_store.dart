import 'dart:io';

import 'markdown_codec.dart';
import 'storage_backend.dart';
import 'stored_entity.dart';

/// 文件版 [EntityStore]（app 内部存储）。
///
/// 磁盘格式由 [codec] 决定，引擎本身跟格式无关：
/// `FileEntityStore(dir)` 默认写 `.md`（frontmatter + 正文），
/// `FileEntityStore(dir, const JsonCodec())` 写 `.json`。
///
/// ⚠️ 依赖 `dart:io`，仅桌面 / 移动端可用；Web 端请用 [MemoryEntityStore]
/// 或基于 localStorage 的后端。本文件**不从 `kit.dart` 导出**，避免 Web 构建被拉入 `dart:io`。
class FileEntityStore implements EntityStore {
  final String rootDir;
  final StoreCodec codec;

  FileEntityStore(this.rootDir, [StoreCodec? codec])
      : codec = codec ?? const MarkdownCodec();

  /// 实体文件的后缀集合：当前 codec 的 + 旧版本遗留的 md。
  Set<String> get _entityExtensions => {codec.extension, '.md', '.markdown'};

  String _dirPath(String subdir) => '$rootDir${Platform.pathSeparator}$subdir';

  File _file(String subdir, String filename) =>
      File('${_dirPath(subdir)}${Platform.pathSeparator}$filename');

  @override
  Future<void> write(String subdir, StoredEntity entity) async {
    await Directory(_dirPath(subdir)).create(recursive: true);
    await _file(subdir, '${entity.id}${codec.extension}')
        .writeAsString(codec.encode(entity));
  }

  @override
  Future<StoredEntity?> read(String subdir, String entityId) async {
    final file = _file(subdir, '$entityId${codec.extension}');
    if (!await file.exists()) return null;
    return codec.decode(entityId, await file.readAsString());
  }

  @override
  Future<bool> delete(String subdir, String entityId) =>
      deleteFile(subdir, '$entityId${codec.extension}');

  @override
  Future<bool> deleteFile(String subdir, String filename) async {
    final file = _file(subdir, filename);
    if (!await file.exists()) return false;
    await file.delete();
    return true;
  }

  Future<List<File>> _listFiles(String subdir) async {
    final dir = Directory(_dirPath(subdir));
    if (!await dir.exists()) return const [];
    return dir
        .list()
        .where((e) => e is File)
        .cast<File>()
        .toList();
  }

  @override
  Future<List<String>> listIds(String subdir) async => (await _listFiles(subdir))
      .where((f) => f.path.endsWith(codec.extension))
      .map((f) => f.uri.pathSegments.last)
      .map((name) => name.substring(0, name.length - codec.extension.length))
      .toList();

  @override
  Future<List<String>> listBinaryFilenames(String subdir) async =>
      (await _listFiles(subdir))
          .where((f) => !_entityExtensions.any((ext) => f.path.endsWith(ext)))
          .map((f) => f.uri.pathSegments.last)
          .toList();

  @override
  Future<List<StoredEntity>> loadAll(String subdir) async {
    final files = (await _listFiles(subdir))
        .where((f) => f.path.endsWith(codec.extension))
        .toList()
      ..sort((a, b) => a.path.compareTo(b.path));
    final result = <StoredEntity>[];
    for (final file in files) {
      final name = file.uri.pathSegments.last;
      final id = name.substring(0, name.length - codec.extension.length);
      final entity = codec.decode(id, await file.readAsString());
      if (entity != null) result.add(entity);
    }
    return result;
  }

  @override
  Future<void> writeBinary(
    String subdir,
    String filename,
    List<int> bytes,
    String mimeType,
  ) async {
    await Directory(_dirPath(subdir)).create(recursive: true);
    await _file(subdir, filename).writeAsBytes(bytes);
  }

  @override
  Future<List<int>?> readBinary(String subdir, String filename) async {
    final file = _file(subdir, filename);
    if (!await file.exists()) return null;
    return file.readAsBytes();
  }

  @override
  String? imageUri(String subdir, String filename) {
    final file = _file(subdir, filename);
    return file.existsSync() ? file.path : null;
  }
}

/// 文件版 [StorageBackend]（单文件，如 `settings.json`）。
///
/// ⚠️ 依赖 `dart:io`，仅桌面 / 移动端可用。
class FileStorageBackend implements StorageBackend {
  final String path;

  FileStorageBackend(this.path);

  @override
  Future<String?> read() async {
    final file = File(path);
    return await file.exists() ? await file.readAsString() : null;
  }

  @override
  Future<void> write(String? content) async {
    final file = File(path);
    if (content == null) {
      if (await file.exists()) await file.delete();
      return;
    }
    await file.parent.create(recursive: true);
    await file.writeAsString(content);
  }
}
