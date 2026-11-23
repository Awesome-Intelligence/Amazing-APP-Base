import 'package:material_ui/material_ui.dart';
// localizations delegate 直接用 material_ui 那套（它自带 Global*Localizations）。
// 别再引 flutter_localizations —— 两边都有 GlobalMaterialLocalizations，
// 同时可见就是 ambiguous_import，而 Material 组件来自 material_ui，delegate 必须同源。

import '../../i18n/kit_strings.dart';
import '../../settings/app_language.dart';
import '../../settings/app_settings.dart';
import '../../settings/theme_enums.dart';
import '../../theme/app_theme.dart';
import '../../theme/kit_theme.dart';
import '../../theme/theme_tokens.dart';

/// 带设置的完整应用外壳 —— 一个 [AppSettings] 驱动整套主题 + 文案 + 语言。
///
/// 和 [KitApp] 的区别：KitApp 只能定一套主题（5 选 1 + 固定深浅），
/// 而真实 app 要「跟随系统深浅」「运行时切风格」「切界面语言」。
/// 后者必须让 MaterialApp 同时拿到 `theme` + `darkTheme` + `themeMode`，
/// 系统切深浅时才会自动重绘 —— 所以这里走 MaterialApp 而不是自己算。
///
/// ```dart
/// KitAppShell(
///   settings: _settings,
///   onSettingsChange: (s) => setState(() => _settings = s),
///   home: HomePage(),
/// )
/// ```
///
/// 设置页见 `SettingsScreen`；两者配对使用就能得到常见 app 的「设置 → 改外观」闭环。
///
/// [KitTheme] 从 `builder` 注入（在 MaterialApp 内部、Navigator 之上），
/// 所以每个路由里 `KitTheme.of(context)` 都能拿到与实际渲染一致的 tokens。
///
/// app 自己带路由（go_router 等）时给 [routerConfig]：底座不内置路由，
/// 但主题和文案照样注入到路由里的每一个页面。
class KitAppShell extends StatelessWidget {
  const KitAppShell({
    super.key,
    required this.settings,
    this.home,
    this.routerConfig,
    this.title = '',
    this.tokens,
    this.locale,
    this.debugShowCheckedModeBanner = false,
  }) : assert(
         home != null || routerConfig != null,
         '要么给 home，要么给 routerConfig —— 两个都没有的话没东西可显示',
       );

  /// 当前设置。改了它（新实例）就会重绘整套主题。
  final AppSettings settings;

  /// 首屏。给了 [routerConfig] 就用不上（`MaterialApp.router` 不收 home）。
  final Widget? home;

  /// app 自带的路由（go_router 之类）。给了就走 `MaterialApp.router`。
  ///
  /// 底座**不内置路由** —— 路由表由 app 自己定；这里只保证主题和文案照样
  /// 注入到路由里的每一个页面（`builder` 在 Navigator 之上）。
  final RouterConfig<Object>? routerConfig;

  final String title;

  /// 品牌主题：给了就用它，忽略 [AppSettings.themeStyle]。
  ///
  /// 注意品牌 tokens 自带明暗，这里会明暗都用同一套 ——
  /// 要真正支持深浅，请给两套并通过 `KitTheme` 自行注入。
  final ThemeTokens? tokens;

  /// 强制 locale；null = 跟 [AppSettings.language]（system 时跟系统）。
  final Locale? locale;

  final bool debugShowCheckedModeBanner;

  @override
  Widget build(BuildContext context) {
    final style = settings.themeStyle;
    final language = settings.language;
    final router = routerConfig;

    // 主题和文案的注入 —— 两条路径（MaterialApp / MaterialApp.router）共用。
    Widget inject(BuildContext context, Widget? child) {
      // 到了这里 Theme 已经按 themeMode 定好，反查就得到「实际生效的深浅」——
      // 跟随系统时不用自己监听平台亮度。
      final isDark = Theme.of(context).brightness == Brightness.dark;
      final resolved = tokens ?? tokensFor(style, isDark);
      // system 语言要按「系统实际给的 locale」落，不能用 settings.language 猜。
      final effectiveLanguage = language == AppLanguage.system
          ? AppLanguage.fromSystemLanguage(Localizations.localeOf(context).languageCode)
          : language;

      return KitTheme(
        tokens: resolved,
        reducedMotion: settings.reducedMotion,
        child: KitStringsScope(
          strings: KitStrings.forLanguage(effectiveLanguage),
          child: child ?? const SizedBox.shrink(),
        ),
      );
    }

    if (router != null) {
      return MaterialApp.router(
        title: title,
        debugShowCheckedModeBanner: debugShowCheckedModeBanner,
        theme: kitThemeData(tokens ?? tokensFor(style, false)),
        darkTheme: kitThemeData(tokens ?? tokensFor(style, true)),
        themeMode: _themeModeOf(settings.appearanceMode),
        locale: locale ?? _localeOf(language),
        supportedLocales: const [Locale('zh'), Locale('en')],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        routerConfig: router,
        builder: inject,
      );
    }

    return MaterialApp(
      title: title,
      debugShowCheckedModeBanner: debugShowCheckedModeBanner,
      theme: kitThemeData(tokens ?? tokensFor(style, false)),
      darkTheme: kitThemeData(tokens ?? tokensFor(style, true)),
      themeMode: _themeModeOf(settings.appearanceMode),
      locale: locale ?? _localeOf(language),
      supportedLocales: const [Locale('zh'), Locale('en')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      builder: inject,
      home: home,
    );
  }
}

ThemeMode _themeModeOf(AppearanceMode mode) => switch (mode) {
      AppearanceMode.system => ThemeMode.system,
      AppearanceMode.light => ThemeMode.light,
      AppearanceMode.dark => ThemeMode.dark,
    };

/// 语言偏好 → MaterialApp 的 locale。
///
/// [AppLanguage.tag] 是给平台 API 用的 BCP-47 全称（`zh-Hans`），
/// 这里只取主语言段做应用内覆盖 —— 底座只区分中英，不漏到 `zh-Hant` 这一层。
Locale? _localeOf(AppLanguage language) => switch (language) {
      AppLanguage.system => null,
      AppLanguage.chinese => const Locale('zh'),
      AppLanguage.english => const Locale('en'),
    };
