/// 主题风格。
enum ThemeStyle {
  mono,
  swiss,
  notion,
  eInk,
  macOS,
}

/// 外观（深浅色）模式。
///
/// - [system] — 跟随系统
/// - [light] / [dark] — 强制浅色 / 深色
enum AppearanceMode {
  system,
  light,
  dark,
}

extension AppearanceModeX on AppearanceMode {
  /// 把外观模式落成实际深浅色。[system] 时用系统值。
  ///
  /// 用它而不是到处 `switch`：设置页和入口都要用同一套判定，散开写早晚不一致。
  bool resolveDark(bool systemDark) => switch (this) {
        AppearanceMode.system => systemDark,
        AppearanceMode.light => false,
        AppearanceMode.dark => true,
      };
}
