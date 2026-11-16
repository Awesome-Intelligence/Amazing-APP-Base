import 'storage.dart';
import 'plan.dart';

/// 一项计数：累计次数 + 计数所属的那一天（按天重置的额度用）。
class UsageRecord {
  final int count;
  final int day;

  const UsageRecord({this.count = 0, this.day = 0});

  Map<String, dynamic> toJson() => {'count': count, 'day': day};

  factory UsageRecord.fromJson(Map<String, dynamic> json) => UsageRecord(
        count: json['count'] as int? ?? 0,
        day: json['day'] as int? ?? 0,
      );

  @override
  bool operator ==(Object other) =>
      other is UsageRecord && other.count == count && other.day == day;

  @override
  int get hashCode => count.hashCode ^ day.hashCode;
}

/// 额度计数器：记「用了多少次」，让额度引擎能判断超没超。
///
/// - [QuotaPeriod.daily]：本地时区的自然日一变，计数归零
/// - [QuotaPeriod.total]：一直累加
///
/// 落盘在一个 JSON 文件里（app 内部存储）。
class UsageTracker {
  final JsonFile<Map<String, UsageRecord>> _file;

  UsageTracker(StorageBackend backend)
      : _file = JsonFile<Map<String, UsageRecord>>(
          backend,
          _recordsFromJson,
          _recordsToJson,
          const {},
        );

  /// 已用次数（按天重置的额度只算当天）。
  Future<int> used(String key, QuotaPeriod period, int now) async {
    final record = (await _file.read())[key];
    if (record == null) return 0;
    return (period == QuotaPeriod.daily && record.day != _epochDays(now))
        ? 0
        : record.count;
  }

  /// 记一次消耗，返回累计次数。
  Future<int> consume(String key, QuotaPeriod period, int amount, int now) async {
    final records = {...await _file.read()};
    final old = records[key];
    final count = switch ((
      old,
      period == QuotaPeriod.daily && (old?.day ?? -1) != _epochDays(now),
    )) {
      (null, _) => amount,
      (_, true) => amount,
      (final o, false) => o!.count + amount,
    };
    records[key] = UsageRecord(count: count, day: _epochDays(now));
    await _file.write(records);
    return count;
  }

  /// 清掉一项计数（升级会员后重置，或业务主动重置）。
  Future<void> reset(String key) async {
    final records = {...await _file.read()}..remove(key);
    await _file.write(records);
  }

  /// 本地时区的今天（epochDay）。
  static int _epochDays(int millis) {
    final dt = DateTime.fromMillisecondsSinceEpoch(millis).toLocal();
    final localMidnight = DateTime(dt.year, dt.month, dt.day);
    return localMidnight.difference(DateTime.utc(1970, 1, 1)).inDays;
  }
}

Map<String, UsageRecord> _recordsFromJson(Map<String, dynamic> json) => {
      for (final e in json.entries)
        e.key: UsageRecord.fromJson(e.value as Map<String, dynamic>)
    };

Map<String, dynamic> _recordsToJson(Map<String, UsageRecord> records) => {
      for (final e in records.entries) e.key: e.value.toJson(),
    };
