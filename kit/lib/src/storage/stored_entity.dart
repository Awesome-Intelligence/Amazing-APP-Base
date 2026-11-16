/// 一个存下来的实体：id + 结构化字段 + 正文。
///
/// 字段用 [dynamic] 表示（数字、布尔、数组、嵌套对象都是一等公民，
/// 不用再塞进 `Map<String, String>` 里靠 `intOr`/`boolOr` 猜类型）。
class StoredEntity {
  final String id;
  final Map<String, dynamic> fields;
  final String body;

  const StoredEntity({
    required this.id,
    this.fields = const {},
    this.body = '',
  });

  StoredEntity copyWith({
    String? id,
    Map<String, dynamic>? fields,
    String? body,
  }) =>
      StoredEntity(
        id: id ?? this.id,
        fields: fields ?? this.fields,
        body: body ?? this.body,
      );

  @override
  bool operator ==(Object other) =>
      other is StoredEntity &&
      other.id == id &&
      other.fields == fields &&
      other.body == body;

  @override
  int get hashCode => id.hashCode ^ fields.hashCode ^ body.hashCode;
}

/// 实体 ↔ 文件文本的编解码器。
///
/// 存储引擎只读写字节，「这个实体在磁盘上长什么样」全归 codec。
/// 加一种新格式（比如 csv / 二进制）= 实现这一个接口，引擎一行都不用改。
abstract class StoreCodec {
  /// 实体文件后缀（含点，如 `.md`）。引擎按它拼文件名、过滤文件。
  String get extension;

  /// 实体 → 文件全文。
  String encode(StoredEntity entity);

  /// 文件全文 → 实体；解析不出来返回 null（引擎跳过该文件）。
  StoredEntity? decode(String id, String raw);
}

/// 存储抽象：**不绑定任何文件格式**。
///
/// 引擎只管「字节往哪写、怎么列出来」，实体长什么样由 [StoreCodec] 决定。
/// 换存储（内存 → 文件 → 数据库）或换格式（markdown → json）都只动实现，调用方不变。
abstract class EntityStore {
  /// 写入（新建或覆盖）`{subdir}/{entityId}{codec 后缀}`。
  Future<void> write(String subdir, StoredEntity entity);

  /// 读取实体，不存在返回 null。
  Future<StoredEntity?> read(String subdir, String entityId);

  /// 删除实体；本来就不存在返回 false。
  Future<bool> delete(String subdir, String entityId);

  /// 按精确文件名删任意文件（附件等）；不存在返回 false。
  Future<bool> deleteFile(String subdir, String filename);

  /// 列出子目录下的实体 id。
  Future<List<String>> listIds(String subdir);

  /// 列出子目录下的二进制（附件）文件名。
  Future<List<String>> listBinaryFilenames(String subdir);

  /// 读出子目录下所有实体。
  Future<List<StoredEntity>> loadAll(String subdir);

  /// 写二进制附件。
  Future<void> writeBinary(
    String subdir,
    String filename,
    List<int> bytes,
    String mimeType,
  );

  /// 读二进制附件，不存在返回 null。
  Future<List<int>?> readBinary(String subdir, String filename);

  /// 图片的可加载标识，null 表示还没有这张图（各端再转成自己的图片模型）。
  String? imageUri(String subdir, String filename);
}
