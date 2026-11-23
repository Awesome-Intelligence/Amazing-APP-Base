import 'package:flutter/foundation.dart';
import 'package:kit/kit.dart';

/// demo 的全局状态：设置 + 站内消息。
///
/// 放在路由**之上** —— 页签里的页面（聊天写消息、通知页读消息）要共享同一份，
/// 底栏角标也得跟着变。放在页面里就各写各的，迟早对不上。
class DemoStore extends ChangeNotifier {
  DemoStore({AppSettings initialSettings = const AppSettings()})
    : _settings = initialSettings;

  AppSettings _settings;

  /// 当前设置（主题 / 深浅 / 语言）。
  AppSettings get settings => _settings;

  /// 改设置。改完通知所有订阅者 —— 主题和设置页都跟着重画。
  void updateSettings(AppSettings next) {
    _settings = next;
    notifyListeners();
  }

  /// 站内消息。demo 用内存实现（真机换 `FileEntityStore` 即可）。
  final NotificationStore notifications =
      NotificationStore(MemoryEntityStore(const JsonCodec()));

  List<AppNotification> _items = const [];
  int _unread = 0;

  /// 通知列表（页面直接渲染这份）。
  List<AppNotification> get items => _items;

  /// 底栏角标用的未读数。
  int get unread => _unread;

  /// 重读消息（写完或标记已读之后调用）。
  Future<void> reloadNotifications() async {
    final list = await notifications.list();
    _items = list;
    _unread = list.where((n) => !n.read).length;
    notifyListeners();
  }

  /// 点开一条 = 已读。
  Future<void> openNotification(AppNotification n) async {
    await notifications.markRead(n.id);
    await reloadNotifications();
  }

  /// 全部已读。
  Future<void> markAllRead() async {
    await notifications.markAllRead();
    await reloadNotifications();
  }
}
