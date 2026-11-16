/// 界面语言偏好 —— 底座目前支持简体中文和英文两种。
///
/// [tag] 是 BCP-47 语言标签，交给各端平台 API 去改 locale：
/// - `null`（[system]）= 不动平台 locale，跟随系统设置；
/// - 非空 = 应用内覆盖。
enum AppLanguage {
  /// 跟随系统；系统既不是中文也不是英文时落中文（默认资源）。
  system(null),

  /// 简体中文（默认资源）。
  chinese('zh-Hans'),

  /// 英文。
  english('en');

  final String? tag;

  const AppLanguage(this.tag);

  /// 系统语言 → 底座实际生效的语言。
  ///
  /// 与「默认资源是中文」这个事实保持一致：**除了英文一律落中文**。
  ///
  /// [language] 是 `Locale` 里的 language 段（如 "zh" / "en" / "ja"）。
  static AppLanguage fromSystemLanguage(String? language) =>
      (language != null && language.toLowerCase().startsWith('en'))
          ? english
          : chinese;
}
