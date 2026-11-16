import 'dart:convert';

/// 字段取值 helper。
///
/// 宽松：老数据里所有值都是字符串（`progress: "0.65"`），这里照样能取成数字/布尔，
/// 所以旧 md 文件不用迁移也能用新的类型化接口读。
extension Fields on Map<String, dynamic> {
  /// 取字符串；null / 缺字段返回 null。
  String? str(String key) {
    final v = this[key];
    if (v == null) return null;
    return v.toString();
  }

  /// 取字符串，缺字段返回空串。
  String strOrEmpty(String key) => str(key) ?? '';

  /// 取 int；字符串会被宽松转成数字，转不了回默认。
  int intOr(String key, int defaultValue) {
    final s = str(key)?.trim();
    return s == null ? defaultValue : (int.tryParse(s) ?? defaultValue);
  }

  /// 取 long（Dart 里统一用 int）。
  int longOr(String key, int defaultValue) => intOr(key, defaultValue);

  /// 取 long，可能为 null。
  int? longOrNull(String key) {
    final s = str(key)?.trim();
    return s == null ? null : int.tryParse(s);
  }

  /// 取 double；字符串会被宽松转成数字，转不了回默认。
  double doubleOr(String key, double defaultValue) {
    final s = str(key)?.trim();
    return s == null ? defaultValue : (double.tryParse(s) ?? defaultValue);
  }

  /// 取 bool；`true`/`1` 算真，`false`/`0` 算假，其它回默认。
  bool boolOr(String key, bool defaultValue) {
    final s = str(key)?.trim().toLowerCase();
    if (s == 'true' || s == '1') return true;
    if (s == 'false' || s == '0') return false;
    return defaultValue;
  }

  /// 字符串列表：JSON 数组，或老格式的逗号分隔串（`"a,b"`）。
  List<String> listOrEmpty(String key) {
    final raw = str(key)?.trim();
    if (raw == null || raw.isEmpty) return const [];
    if (raw.startsWith('[')) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is List) {
          return decoded.map((e) => e.toString()).toList();
        }
      } catch (_) {
        // fall through to comma-separated parsing
      }
    }
    return raw
        .replaceAll('[', '')
        .replaceAll(']', '')
        .split(',')
        .map((e) => e.trim())
        .map((e) => e.replaceAll('"', '').replaceAll("'", ''))
        .where((e) => e.isNotEmpty)
        .toList();
  }

  /// 归档标记。兼容旧版本写入的 `isDeleted` 键，避免历史数据里的归档项被"复活"。
  bool archivedFlagOr(bool defaultValue) {
    for (final key in ['isArchived', 'isDeleted']) {
      final s = str(key)?.trim().toLowerCase();
      if (s == 'true' || s == '1') return true;
      if (s == 'false' || s == '0') return false;
    }
    return defaultValue;
  }

  /// 归档时间。兼容旧版本写入的 `deletedDate` 键。
  int? archivedDateOrNull() => longOrNull('archivedDate') ?? longOrNull('deletedDate');
}
