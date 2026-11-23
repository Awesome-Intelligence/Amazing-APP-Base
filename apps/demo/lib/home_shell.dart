import 'package:go_router/go_router.dart';
import 'package:kit/kit_ui.dart' as ui;
import 'package:material_ui/material_ui.dart';

import 'demo_store.dart';

/// demo 的页面外壳：底部四个页签（待办 / 通知 / 组件 / 模板）。
///
/// 页签由 `StatefulShellRoute.indexedStack` 驱动 —— 每个页签有自己的
/// Navigator，切页签不重建页面，栈和滚动位置都留着。
/// 底栏只负责切分支；返回键的语义在 [PopScope] 里定。
class HomeShell extends StatelessWidget {
  const HomeShell({
    super.key,
    required this.navigationShell,
    required this.store,
  });

  /// go_router 的分支外壳：当前是第几个页签 + 怎么切。
  final StatefulNavigationShell navigationShell;

  /// 全局状态（消息、未读数）。
  final DemoStore store;

  @override
  Widget build(BuildContext context) {
    final router = GoRouter.of(context);

    // 返回键的三段语义（业界惯例）：
    // 1. 分支里还有页面 → 退那一层；
    // 2. 在别的页签 → 回第一个页签（不是直接退出 app）；
    // 3. 已经在第一个页签且没东西可退 → 交回系统（退出 app）。
    final canExit = navigationShell.currentIndex == 0 && !router.canPop();

    return PopScope(
      canPop: canExit,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (router.canPop()) {
          router.pop();
          return;
        }
        if (navigationShell.currentIndex != 0) {
          navigationShell.goBranch(0);
        }
      },
      child: Scaffold(
        body: navigationShell,
        // 用 kit 的 `AppBottomNavigation`：它自带角标（`badgeCount`），
        // 底栏那点未读数才有地方显示。
        bottomNavigationBar: ListenableBuilder(
          listenable: store,
          builder: (context, _) => ui.AppBottomNavigation(
            selectedIndex: navigationShell.currentIndex,
            // 再点当前页签 = 回到该页签的根（业界惯例）。
            onItemSelected: (i) => navigationShell.goBranch(
              i,
              initialLocation: i == navigationShell.currentIndex,
            ),
            items: [
              const ui.BottomNavItem(
                label: '待办',
                icon: Icons.chat_bubble_outline,
                selectedIcon: Icons.chat_bubble,
              ),
              ui.BottomNavItem(
                label: '通知',
                icon: Icons.notifications_none,
                selectedIcon: Icons.notifications,
                badgeCount: store.unread,
              ),
              const ui.BottomNavItem(
                label: '组件',
                icon: Icons.widgets_outlined,
                selectedIcon: Icons.widgets,
              ),
              const ui.BottomNavItem(
                label: '模板',
                icon: Icons.dashboard_customize_outlined,
                selectedIcon: Icons.dashboard_customize,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
