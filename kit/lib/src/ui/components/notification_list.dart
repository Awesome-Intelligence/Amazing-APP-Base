import 'package:material_ui/material_ui.dart';

import '../../i18n/kit_strings.dart';
import '../../notification/notification.dart';
import '../../theme/kit_theme.dart';
import '../format/date_display.dart';
import 'empty_state.dart';

/// 通知列表 —— 消息中心的一屏。
///
/// 行自己画而不用 `AppListItem`：那个组件的未读小圆点跟 40px 的圆形 leading 绑在一起，
/// 通知行不需要大圆头像，只要一个小点。
class AppNotificationList extends StatelessWidget {
  const AppNotificationList({
    super.key,
    required this.notifications,
    this.onTap,
  });

  final List<AppNotification> notifications;

  /// 点一行（一般是「点开即已读」）。
  final ValueChanged<AppNotification>? onTap;

  @override
  Widget build(BuildContext context) {
    if (notifications.isEmpty) {
      final s = KitStringsScope.of(context);
      return IllustratedEmptyState(
        icon: Icons.notifications_none,
        title: s.notificationEmptyTitle,
        subtitle: s.notificationEmptySubtitle,
      );
    }
    return ListView.separated(
      padding: EdgeInsets.zero,
      itemCount: notifications.length,
      separatorBuilder: (context, index) =>
          Divider(height: 1, color: KitTheme.of(context).colorScheme.outlineVariant),
      itemBuilder: (context, i) => _row(context, notifications[i]),
    );
  }

  Widget _row(BuildContext context, AppNotification n) {
    final tokens = KitTheme.of(context);
    final strings = KitStringsScope.of(context);
    final unread = !n.read;

    return InkWell(
      onTap: onTap == null ? null : () => onTap!(n),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 未读点。宽度固定 —— 读过的那条不跳。
            SizedBox(
              width: 9,
              height: 9,
              child: unread
                  ? Semantics(
                      label: strings.notificationUnread,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: tokens.colorScheme.primary,
                          shape: BoxShape.circle,
                        ),
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(n.title, style: tokens.textTheme.titleSmall),
                  if (n.body.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      n.body,
                      style: tokens.textTheme.bodySmall
                          ?.copyWith(color: tokens.colorScheme.onSurfaceVariant),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 12),
            Text(
              formatRelativeTime(context, n.createdAt.millisecondsSinceEpoch),
              style: tokens.textTheme.bodySmall
                  ?.copyWith(color: tokens.colorScheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}
