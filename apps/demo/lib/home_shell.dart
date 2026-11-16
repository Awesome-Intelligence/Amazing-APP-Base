import 'package:material_ui/material_ui.dart';
import 'package:kit/kit.dart' show AppSettings;
import 'package:kit/kit_ui.dart' as ui;

import 'gallery_page.dart';
import 'templates_page.dart';
import 'todo_chat_page.dart';

/// demo 的页面外壳：底部三个页签（待办 / 组件 / 模板）。
///
/// 设置页的打开逻辑放在这一层，几个页面共用 —— 各自实现一份迟早会分叉。
///
/// 页签用「访问过才构建」的 `IndexedStack`：组件目录里有骨架屏，
/// 那是**无限循环**动画，一开始就构建的话 `pumpAndSettle` 永远等不到静止，
/// 测试全得改写。顺带也省了首屏开销。
class HomeShell extends StatefulWidget {
  const HomeShell({
    super.key,
    required this.settings,
    required this.onSettingsChange,
  });

  final AppSettings settings;
  final ValueChanged<AppSettings> onSettingsChange;

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;
  final Set<int> _built = {0};

  /// 打开设置页。
  ///
  /// 设置页在路由里，而设置状态在根上 —— 根重建时这个路由不会自动重画，
  /// 所以外面套一层 `StatefulBuilder`：改完值先冒到根（换主题），
  /// 再让设置页自己重建一次读新值（副标题才不会停在旧风格上）。
  Future<void> _openSettings() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => StatefulBuilder(
          builder: (routeContext, setLocal) => ui.SettingsScreen(
            settings: widget.settings,
            onSettingsChange: (next) {
              widget.onSettingsChange(next);
              setLocal(() {});
            },
            onBackClick: () => Navigator.of(routeContext).pop(),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: [
          _built.contains(0)
              ? TodoChatPage(onOpenSettings: _openSettings)
              : const SizedBox.shrink(),
          _built.contains(1)
              ? GalleryPage(onOpenSettings: _openSettings)
              : const SizedBox.shrink(),
          _built.contains(2)
              ? TemplatesPage(
                  settings: widget.settings,
                  onSettingsChange: widget.onSettingsChange,
                )
              : const SizedBox.shrink(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() {
          _index = i;
          _built.add(i);
        }),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.chat_bubble_outline),
            selectedIcon: Icon(Icons.chat_bubble),
            label: '待办',
          ),
          NavigationDestination(
            icon: Icon(Icons.widgets_outlined),
            selectedIcon: Icon(Icons.widgets),
            label: '组件',
          ),
          NavigationDestination(
            icon: Icon(Icons.dashboard_customize_outlined),
            selectedIcon: Icon(Icons.dashboard_customize),
            label: '模板',
          ),
        ],
      ),
    );
  }
}
