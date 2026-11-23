import 'package:go_router/go_router.dart';
import 'package:kit/kit_ui.dart';
import 'package:material_ui/material_ui.dart';

import 'demo_store.dart';
import 'gallery_page.dart';
import 'home_shell.dart';
import 'notification_page.dart';
import 'route_transition.dart';
import 'templates_page.dart';
import 'todo_chat_page.dart';
import 'update_gate.dart';

/// 根导航器：设置页浮在四个页签之上，不进任何页签的栈。
final _rootNavigatorKey = GlobalKey<NavigatorState>();

/// demo 的路由：四个页签各占一个分支（`StatefulShellRoute.indexedStack`）。
///
/// 一个分支 = 一个独立的 Navigator：
/// - 切页签不重建页面，栈和滚动位置都留着（这才叫嵌套导航）；
/// - 深链直接落到对应页签（`/todo` `/notifications` `/gallery` `/templates`）；
/// - web 上 URL 跟着页签走，刷新不丢位置。
///
/// 设置页是根导航器里的独立路由：它浮在页签之上，返回时回到原来的页签。
GoRouter createDemoRouter(DemoStore store, {required String appVersion}) {
  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/todo',
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) => UpdateGate(
          currentVersion: appVersion,
          child: HomeShell(navigationShell: navigationShell, store: store),
        ),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/todo',
                builder: (context, state) => TodoChatPage(
                  onOpenSettings: () => openSettings(context),
                  notifications: store.notifications,
                  onNotificationsChanged: store.reloadNotifications,
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/notifications',
                builder: (context, state) => ListenableBuilder(
                  listenable: store,
                  builder: (context, _) => NotificationPage(
                    notifications: store.items,
                    onOpen: store.openNotification,
                    onMarkAll: store.markAllRead,
                  ),
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/gallery',
                builder: (context, state) => ListenableBuilder(
                  listenable: store,
                  builder: (context, _) => GalleryPage(
                    onOpenSettings: () => openSettings(context),
                    unreadCount: store.unread,
                  ),
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/templates',
                builder: (context, state) => TemplatesPage(
                  onOpenSettings: () => openSettings(context),
                ),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: '/settings',
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) => CustomTransitionPage<void>(
          transitionDuration: motionDuration(context, M3Motion.medium2),
          reverseTransitionDuration: motionDuration(context, M3Motion.medium2),
          transitionsBuilder: buildRouteTransition,
          child: ListenableBuilder(
            listenable: store,
            builder: (context, _) => SettingsScreen(
              settings: store.settings,
              onSettingsChange: store.updateSettings,
              onBackClick: () => context.pop(),
            ),
          ),
        ),
      ),
    ],
  );
}

/// 打开设置页 —— 所有页面的设置入口都走这里，逻辑只有一份。
void openSettings(BuildContext context) => context.push('/settings');
