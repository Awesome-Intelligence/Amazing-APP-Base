import 'dart:convert';

import 'stored_entity.dart';

/// 每个实体一个 JSON 文件（`{id}.json`）：
///
/// ```json
/// { "id": "goal-1", "fields": { "progress": 0.65 }, "body": "..." }
/// ```
///
/// 字段结构完整（数字/布尔/数组/嵌套对象都保真），适合不需要人类可读、只要机器读的场景。
class JsonCodec implements StoreCodec {
  final bool pretty;

  const JsonCodec({this.pretty = true});

  @override
  String get extension => '.json';

  @override
  String encode(StoredEntity entity) {
    final map = {
      'id': entity.id,
      'fields': entity.fields,
      'body': entity.body,
    };
    final encoder = JsonEncoder.withIndent(pretty ? '  ' : null);
    return encoder.convert(map);
  }

  @override
  StoredEntity? decode(String id, String raw) {
    try {
      final obj = jsonDecode(raw) as Map<String, dynamic>;
      final fields = obj['fields'];
      final body = obj['body'];
      return StoredEntity(
        id: (obj['id'] as String?) ?? id,
        fields: fields is Map ? Map<String, dynamic>.from(fields) : {},
        body: body is String ? body : '',
      );
    } catch (_) {
      return null;
    }
  }
}
