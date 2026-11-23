import 'package:kit/kit.dart';
import 'package:kit/kit_ui.dart' as ui;
import 'package:material_ui/material_ui.dart';

/// demo 的消息中心页：通知列表 +「全部已读」。
///
/// 纯展示页 —— 数据由外壳持有（它也管着底栏角标那份未读数）。
/// 通知来自 kit 的 `NotificationStore`（站内消息）。**不含平台推送** ——
/// FCM / 系统通知是平台能力，归 app 层。
class NotificationPage extends StatelessWidget {
  const NotificationPage({
    super.key,
    required this.notifications,
    required this.onOpen,
    required this.onMarkAll,
  });

  final List<AppNotification> notifications;

  /// 点一条（一般是「点开即已读」）。
  final ValueChanged<AppNotification> onOpen;

  /// 「全部已读」。
  final VoidCallback onMarkAll;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          ui.Header(
            title: '通知',
            action1: ui.TextActionButton(text: '全部已读', onPressed: onMarkAll),
          ),
          Expanded(
            child: ui.AppNotificationList(
              notifications: notifications,
              onTap: onOpen,
            ),
          ),
        ],
      ),
    );
  }
}
