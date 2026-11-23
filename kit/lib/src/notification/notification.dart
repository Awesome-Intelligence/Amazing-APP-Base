import '../storage/fields.dart';
import '../storage/stored_entity.dart';

/// 一条通知（消息中心的一条）。
///
/// 叫 `AppNotification` 而不是 `Notification`：Flutter 自己有个 `Notification`（widget 树里
/// 往上冒的那种），撞名会让同时 import `material_ui` 的文件直接编译不过。
///
/// 字段只留底座用得上的：标题、正文、时间、已读标记。
/// **推送渠道（FCM / 系统通知）不在这里** —— 平台能力归 app 层。
class AppNotification {
  final String id;
  final String title;
  final String body;

  /// 什么时候产生的（用于排序和「3 分钟前」）。
  final DateTime createdAt;

  /// 是否已读。未读数就是底栏角标。
  final bool read;

  const AppNotification({
    required this.id,
    required this.title,
    this.body = '',
    required this.createdAt,
    this.read = false,
  });

  AppNotification copyWith({
    String? title,
    String? body,
    DateTime? createdAt,
    bool? read,
  }) =>
      AppNotification(
        id: id,
        title: title ?? this.title,
        body: body ?? this.body,
        createdAt: createdAt ?? this.createdAt,
        read: read ?? this.read,
      );

  @override
  bool operator ==(Object other) =>
      other is AppNotification &&
      other.id == id &&
      other.title == title &&
      other.body == body &&
      other.createdAt == createdAt &&
      other.read == read;

  @override
  int get hashCode => Object.hash(id, title, body, createdAt, read);
}

/// 通知仓库 —— 消息中心的数据层。
///
/// 落在 [EntityStore] 上，所以内存 / 文件 / 后端存储共用同一套代码：
/// 内存实现给测试和 demo，文件实现给真机（`FileEntityStore`）。
///
/// 只管存取和已读状态，**不做平台推送** —— 那是 app 层的事。
class NotificationStore {
  NotificationStore(this._store);

  final EntityStore _store;

  /// 通知存放的子目录。
  static const String subdir = 'notifications';

  /// 全部通知，按时间倒序（新的在前）。
  Future<List<AppNotification>> list() async {
    final entities = await _store.loadAll(subdir);
    final items = entities.map(_decode).toList();
    // 自己排序：内存 store 是插入序、文件 store 是文件名序，都不是时间序。
    items.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return items;
  }

  /// 未读数量（底栏角标）。
  Future<int> unreadCount() async =>
      (await list()).where((n) => !n.read).length;

  /// 新增一条通知（默认未读）。
  ///
  /// [id] 给了就是**幂等写入**：同一个 id 再写一次不会产生第二条（远端推送重发、
  /// 轮询重连都会重发同一条）。不给就用时间戳当 id。
  Future<AppNotification> add({
    required String title,
    String body = '',
    DateTime? createdAt,
    String? id,
  }) async {
    final finalId = id ?? DateTime.now().microsecondsSinceEpoch.toString();
    final existing = await _store.read(subdir, finalId);
    if (existing != null) return _decode(existing);
    final n = AppNotification(
      id: finalId,
      title: title,
      body: body,
      createdAt: createdAt ?? DateTime.now(),
    );
    await _store.write(subdir, _encode(n));
    return n;
  }

  /// 标记一条已读。
  Future<void> markRead(String id) async {
    final e = await _store.read(subdir, id);
    if (e == null) return;
    await _store.write(subdir, e.copyWith(fields: {...e.fields, 'read': true}));
  }

  /// 全部标记已读。
  Future<void> markAllRead() async {
    for (final e in await _store.loadAll(subdir)) {
      if (e.fields.boolOr('read', false)) continue;
      await _store.write(
        subdir,
        e.copyWith(fields: {...e.fields, 'read': true}),
      );
    }
  }

  /// 删除一条。
  Future<bool> remove(String id) => _store.delete(subdir, id);
}

StoredEntity _encode(AppNotification n) => StoredEntity(
      id: n.id,
      fields: {
        'title': n.title,
        'createdAt': n.createdAt.millisecondsSinceEpoch,
        'read': n.read,
      },
      body: n.body,
    );

AppNotification _decode(StoredEntity e) => AppNotification(
      id: e.id,
      title: e.fields.strOrEmpty('title'),
      body: e.body,
      createdAt:
          DateTime.fromMillisecondsSinceEpoch(e.fields.longOr('createdAt', 0)),
      read: e.fields.boolOr('read', false),
    );
