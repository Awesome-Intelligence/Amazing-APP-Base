import 'dart:convert';

import 'stored_entity.dart';

/// YAML-ish frontmatter + 正文的文件格式（`{id}.md`）。
///
/// ```
/// ---
/// id: "goal-1"
/// progress: 0.65
/// done: true
/// tags: ["跑步","健身"]
/// ---
/// Markdown body.
/// ```
///
/// 值的写法：
/// - 字符串 → 带引号（`"…"`，内部转义引号/换行）
/// - 数字 / 布尔 / null → 直接写裸字面量
/// - 数组 / 对象 → 紧凑 JSON 写一行
///
/// 兼容旧数据：老版本把**所有**值都写成带引号的字符串，这里读回来仍是字符串；
/// 取值用 [Fields] 的 `intOr` / `doubleOr` / `boolOr`，字符串会被宽松地转成数字/布尔。
class MarkdownCodec implements StoreCodec {
  static const String _separator = '---';

  const MarkdownCodec();

  @override
  String get extension => '.md';

  @override
  String encode(StoredEntity entity) {
    final buffer = StringBuffer();
    buffer.writeln(_separator);
    entity.fields.forEach((k, v) {
      buffer.write(k);
      buffer.write(': ');
      buffer.writeln(_encodeValue(v));
    });
    buffer.writeln(_separator);
    buffer.write(entity.body);
    return buffer.toString();
  }

  @override
  StoredEntity? decode(String id, String raw) {
    var text = raw;
    if (text.startsWith('﻿')) text = text.substring(1); // BOM
    final lines = text.split('\n');
    if (lines.isEmpty || lines[0].trim() != _separator) return null;

    final fmLines = <String>[];
    var bodyStart = -1;
    for (var i = 1; i < lines.length; i++) {
      if (lines[i].trim() == _separator) {
        bodyStart = i + 1;
        break;
      }
      fmLines.add(lines[i]);
    }
    if (bodyStart < 0) return null;

    final body = lines.sublist(bodyStart).join('\n');
    return StoredEntity(
      id: id,
      fields: _parseFrontmatter(fmLines),
      body: body.startsWith('\n') ? body.substring(1) : body,
    );
  }

  // ─── 值编解码 ────────────────────────────────────────────────────────────

  String _encodeValue(dynamic value) {
    if (value == null) return 'null';
    if (value is String) return '"${_escape(value)}"';
    if (value is bool || value is num) return value.toString();
    return jsonEncode(value); // 数组 / 对象 → 紧凑 JSON
  }

  Map<String, dynamic> _parseFrontmatter(List<String> lines) {
    final result = <String, dynamic>{};
    for (final line in lines) {
      final colonIdx = line.indexOf(':');
      if (colonIdx <= 0) continue;
      final key = line.substring(0, colonIdx).trim();
      if (key.isEmpty) continue;
      final rest = line.substring(colonIdx + 1).trim();
      if (rest.isEmpty) continue;
      result[key] = _parseValue(rest);
    }
    return result;
  }

  dynamic _parseValue(String rest) {
    if (rest.startsWith('"')) {
      final endQuote = rest.lastIndexOf('"');
      if (endQuote > 0) return _unescape(rest.substring(1, endQuote));
    }
    try {
      return jsonDecode(rest);
    } catch (_) {
      // 老版本允许写不带引号的列表：`[a, b]`
      if (rest.startsWith('[')) {
        final items = rest
            .substring(1, rest.endsWith(']') ? rest.length - 1 : rest.length)
            .split(',')
            .map((e) => e.trim())
            .map((e) => e.replaceAll('"', '').replaceAll("'", ''))
            .where((e) => e.isNotEmpty)
            .toList();
        return items;
      }
      return rest;
    }
  }

  String _escape(String value) => value.replaceAllMapped(
        RegExp(r'([\\"\n\r])'),
        (m) => switch (m.group(1)) {
          '\\' => '\\\\',
          '"' => '\\"',
          '\n' => '\\n',
          '\r' => '\\r',
          _ => m.group(1)!,
        },
      );

  String _unescape(String value) {
    final buffer = StringBuffer();
    var i = 0;
    while (i < value.length) {
      final c = value[i];
      if (c == '\\' && i + 1 < value.length) {
        switch (value[i + 1]) {
          case '\\':
            buffer.write('\\');
            i += 2;
            continue;
          case '"':
            buffer.write('"');
            i += 2;
            continue;
          case 'n':
            buffer.write('\n');
            i += 2;
            continue;
          case 'r':
            buffer.write('\r');
            i += 2;
            continue;
          default:
            buffer.write(c);
            i += 1;
            continue;
        }
      } else {
        buffer.write(c);
        i += 1;
      }
    }
    return buffer.toString();
  }
}
