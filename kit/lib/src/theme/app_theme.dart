import 'package:material_ui/material_ui.dart';

import '../settings/theme_enums.dart' show ThemeStyle;
import 'kit_theme.dart';
import 'theme_tokens.dart';

/// 把 [ThemeTokens] 落成 Material 的 [ThemeData]。
///
/// 关键点：页面底色取 [ColorSchemeExtras.background] 而不是 `colorScheme.surface` ——
/// KMP 里这两项是**分开取值**的（Notion 浅色底 `#f7f6f3`，卡片白 `#ffffff`），
/// 统一成 surface 会让整页发白发平。
ThemeData kitThemeData(ThemeTokens tokens) {
  final base = ThemeData(
    useMaterial3: true,
    colorScheme: tokens.colorScheme,
    scaffoldBackgroundColor: tokens.extras.background,
  );
  return base.copyWith(
    textTheme: tokens.textTheme,
    canvasColor: tokens.extras.background,
    // 分屏/对话框底：M3 用 surfaceContainerHigh，KMP 一致
    dialogTheme: DialogThemeData(
      backgroundColor: tokens.colorScheme.surfaceContainerHigh,
      shape: RoundedRectangleBorder(borderRadius: tokens.shapes.extraLarge),
    ),
  );
}

/// 主题入口 —— 只负责把 tokens 注入 widget 树，不创建 MaterialApp。
///
/// 两种用法：
/// 1. 用 [KitApp]（推荐，一步到位带 MaterialApp + 主题）；
/// 2. 自己写 MaterialApp，则用 `theme: kitThemeData(KitTheme.of(context))`。
///
/// 为什么不在 [AppTheme] 里直接套 `Theme(data: …)`：MaterialApp 会用自己那份主题
/// 覆盖上层 Theme，套了也白套。所以这里只提供 tokens，ThemeData 由 MaterialApp 拿到。
class AppTheme extends StatelessWidget {
  const AppTheme({
    super.key,
    this.style = ThemeStyle.mono,
    this.darkTheme,
    this.tokens,
    this.reducedMotion = false,
    required this.child,
  });

  /// 主题风格。传了 [tokens] 时忽略本字段。
  final ThemeStyle style;

  /// 强制深浅色；null = 跟随系统。
  final bool? darkTheme;

  /// 直接给一套 tokens（品牌主题走这个），优先于 [style] + [darkTheme]。
  final ThemeTokens? tokens;

  /// 系统是否关掉了动画（无障碍设置）。
  final bool reducedMotion;

  final Widget child;

  /// 读当前系统深浅色。
  ///
  /// 优先 MediaQuery（会被宿主 app 的 themeMode 覆盖，符合预期）；
  /// 在 MaterialApp 之上没有 MediaQuery 时退到平台调度器（不依赖 View 祖先，单测也能跑）。
  static bool systemDark(BuildContext context) {
    final mq = MediaQuery.maybeOf(context);
    if (mq != null) return mq.platformBrightness == Brightness.dark;
    return WidgetsBinding.instance.platformDispatcher.platformBrightness == Brightness.dark;
  }

  @override
  Widget build(BuildContext context) {
    final resolved = tokens ?? tokensFor(style, darkTheme ?? systemDark(context));
    return KitTheme(
      tokens: resolved,
      reducedMotion: reducedMotion,
      child: child,
    );
  }
}

/// 一步到位的应用外壳：主题 + MaterialApp。
///
/// ```dart
/// void main() => runApp(const KitApp(title: '待办', home: TodoChatPage()));
/// ```
class KitApp extends StatelessWidget {
  const KitApp({
    super.key,
    required this.home,
    this.title = '',
    this.style = ThemeStyle.mono,
    this.darkTheme,
    this.tokens,
    this.reducedMotion = false,
    this.debugShowCheckedModeBanner = false,
    this.themeMode,
  });

  final Widget home;
  final String title;

  /// 主题风格（品牌主题请改用 [tokens]）。
  final ThemeStyle style;

  /// 强制深浅色；null = 跟随系统。
  final bool? darkTheme;

  /// 品牌 tokens，优先于 [style]。
  final ThemeTokens? tokens;

  final bool reducedMotion;
  final bool debugShowCheckedModeBanner;

  /// 传给 MaterialApp 的 themeMode；一般不用（深浅由 [darkTheme] 决定）。
  final ThemeMode? themeMode;

  @override
  Widget build(BuildContext context) {
    return AppTheme(
      style: style,
      darkTheme: darkTheme,
      tokens: tokens,
      reducedMotion: reducedMotion,
      child: Builder(
        builder: (context) {
          final resolved = KitTheme.of(context);
          return MaterialApp(
            title: title,
            debugShowCheckedModeBanner: debugShowCheckedModeBanner,
            theme: kitThemeData(resolved),
            themeMode: themeMode,
            home: home,
          );
        },
      ),
    );
  }
}
