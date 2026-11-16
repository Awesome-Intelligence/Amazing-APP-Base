import 'dart:convert';

import '../storage/storage_backend.dart';
import 'app_language.dart';
import 'theme_enums.dart';

/// 应用设置 —— 就这几个开关，够底座用了。
///
/// 想加自己的项：加字段（带默认值，老配置文件照样能读），再在设置页加一行。
/// 字段顺序无所谓，JSON 按名字匹配。
class AppSettings {
  /// 主题风格（单色 / 位图 / …）。
  final ThemeStyle themeStyle;

  /// 深浅色：跟随系统 / 浅色 / 深色。
  final AppearanceMode appearanceMode;

  /// 关掉动效（无障碍）。
  final bool reducedMotion;

  /// 界面语言：跟随系统 / 简体中文 / English。
  final AppLanguage language;

  const AppSettings({
    this.themeStyle = ThemeStyle.mono,
    this.appearanceMode = AppearanceMode.system,
    this.reducedMotion = false,
    this.language = AppLanguage.system,
  });

  AppSettings copyWith({
    ThemeStyle? themeStyle,
    AppearanceMode? appearanceMode,
    bool? reducedMotion,
    AppLanguage? language,
  }) =>
      AppSettings(
        themeStyle: themeStyle ?? this.themeStyle,
        appearanceMode: appearanceMode ?? this.appearanceMode,
        reducedMotion: reducedMotion ?? this.reducedMotion,
        language: language ?? this.language,
      );

  Map<String, dynamic> toJson() => {
        'themeStyle': themeStyle.name,
        'appearanceMode': appearanceMode.name,
        'reducedMotion': reducedMotion,
        'language': language.name,
      };

  factory AppSettings.fromJson(Map<String, dynamic> json) => AppSettings(
        themeStyle: _enumByName(
            ThemeStyle.values, json['themeStyle'], ThemeStyle.mono),
        appearanceMode: _enumByName(
            AppearanceMode.values, json['appearanceMode'], AppearanceMode.system),
        reducedMotion: json['reducedMotion'] as bool? ?? false,
        language:
            _enumByName(AppLanguage.values, json['language'], AppLanguage.system),
      );
}

T _enumByName<T extends Enum>(List<T> values, dynamic name, T fallback) {
  if (name is String) {
    for (final v in values) {
      if (v.name == name) return v;
    }
  }
  return fallback;
}

/// 设置持久化：一个 JSON 文件（app 内部存储）。
///
/// 目录/后端由调用方给（Android 传文件后端，iOS 传另一个，Web 传 localStorage 后端），
/// 引擎只管读写这一个文件。
///
/// ponytail: 不是通用 KV 库 —— 就一个文件、一份 [AppSettings]。
/// 真要存一堆东西，上 [EntityStore]。
class SettingsStore {
  final StorageBackend backend;

  SettingsStore(this.backend);

  /// 读设置；文件不存在或读坏了都返回默认值。
  Future<AppSettings> load() async {
    final raw = await backend.read();
    if (raw == null) return const AppSettings();
    try {
      return AppSettings.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return const AppSettings();
    }
  }

  /// 写设置（覆盖整个文件）。
  Future<void> save(AppSettings settings) async {
    await backend.write(jsonEncode(settings.toJson()));
  }
}
