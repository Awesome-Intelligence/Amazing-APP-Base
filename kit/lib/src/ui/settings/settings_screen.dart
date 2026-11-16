import 'package:material_ui/material_ui.dart';

import '../../i18n/kit_strings.dart';
import '../../settings/app_language.dart';
import '../../settings/app_settings.dart';
import '../../settings/theme_enums.dart';
import '../../theme/kit_theme.dart';
import '../components/dialogs.dart';
import '../components/header.dart';
import '../components/settings_rows.dart';
import '../components/toggle_row.dart';

/// 设置页 —— 底座自带的通用设置（外观 / 动效 / 语言）。
///
/// 状态由调用方持有并落盘（kit 自带 [SettingsStore]）：本页只管显示和回调，
/// 不碰存储 —— 这样 app 想存哪、怎么存都行。
///
/// app 自己的设置项（账号、数据管理等）用 [extraSections] 插在通用项下面。
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({
    super.key,
    required this.settings,
    required this.onSettingsChange,
    required this.onBackClick,
    this.extraSections = const [],
  });

  final AppSettings settings;
  final ValueChanged<AppSettings> onSettingsChange;
  final VoidCallback onBackClick;

  /// app 自己的设置分区，接在「语言」下面。
  ///
  /// 传 `[SettingsSectionHeader('账号'), SettingsCard([...])]` 这种现成 widget 即可。
  final List<Widget> extraSections;

  @override
  Widget build(BuildContext context) {
    final tokens = KitTheme.of(context);
    final strings = KitStringsScope.of(context);

    return Scaffold(
      backgroundColor: tokens.colorScheme.surface,
      body: Column(
        children: [
          Header(
            title: strings.settings,
            leading1: IconButton(
              onPressed: onBackClick,
              icon: const Icon(Icons.arrow_back),
              tooltip: strings.back,
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.only(bottom: 24),
              children: [
                SettingsSectionHeader(title: strings.appearance),
                SettingsCard(
                  children: [
                    AppSettingsRow(
                      icon: Icons.palette_outlined,
                      title: strings.themeStyle,
                      subtitle: strings.themeStyleName(settings.themeStyle),
                      onClick: () => _pickStyle(context),
                    ),
                    const _CardDivider(),
                    AppSettingsRow(
                      icon: Icons.dark_mode_outlined,
                      title: strings.appearanceMode,
                      subtitle: strings.appearanceModeName(settings.appearanceMode),
                      onClick: () => _pickAppearance(context),
                    ),
                    const _CardDivider(),
                    ToggleRow(
                      icon: Icons.animation_outlined,
                      title: strings.reduceMotion,
                      subtitle: strings.reduceMotionDesc,
                      isChecked: settings.reducedMotion,
                      onCheckedChange: (v) =>
                          onSettingsChange(settings.copyWith(reducedMotion: v)),
                    ),
                  ],
                ),
                SettingsSectionHeader(title: strings.language),
                SettingsCard(
                  children: [
                    AppSettingsRow(
                      icon: Icons.language_outlined,
                      title: strings.languageSetting,
                      subtitle: strings.languageName(settings.language),
                      onClick: () => _pickLanguage(context),
                    ),
                  ],
                ),
                ...extraSections,
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickStyle(BuildContext context) async {
    final strings = KitStringsScope.of(context);
    final picked = await SelectDialog.show(
      context,
      title: strings.themeStyle,
      options: [
        for (final style in ThemeStyle.values) strings.themeStyleName(style),
      ],
      selectedIndex: ThemeStyle.values.indexOf(settings.themeStyle),
    );
    if (picked == null) return;
    onSettingsChange(
      settings.copyWith(themeStyle: ThemeStyle.values[picked]),
    );
  }

  Future<void> _pickAppearance(BuildContext context) async {
    final strings = KitStringsScope.of(context);
    final picked = await SelectDialog.show(
      context,
      title: strings.appearanceMode,
      options: [
        for (final mode in AppearanceMode.values) strings.appearanceModeName(mode),
      ],
      selectedIndex: AppearanceMode.values.indexOf(settings.appearanceMode),
    );
    if (picked == null) return;
    onSettingsChange(
      settings.copyWith(appearanceMode: AppearanceMode.values[picked]),
    );
  }

  Future<void> _pickLanguage(BuildContext context) async {
    final strings = KitStringsScope.of(context);
    final picked = await SelectDialog.show(
      context,
      title: strings.languageSetting,
      options: [
        for (final lang in AppLanguage.values) strings.languageName(lang),
      ],
      selectedIndex: AppLanguage.values.indexOf(settings.language),
    );
    if (picked == null) return;
    onSettingsChange(settings.copyWith(language: AppLanguage.values[picked]));
  }
}

/// 小节标题（M3 list section header）。
class SettingsSectionHeader extends StatelessWidget {
  const SettingsSectionHeader({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final tokens = KitTheme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: tokens.textTheme.labelLarge?.copyWith(
          color: tokens.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

/// 分组卡片：内容不自带内边距，行自带 padding —— 涟漪能铺到卡片边。
class SettingsCard extends StatelessWidget {
  const SettingsCard({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final tokens = KitTheme.of(context);
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      elevation: 0,
      color: tokens.colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(borderRadius: tokens.shapes.medium),
      clipBehavior: Clip.antiAlias,
      child: Column(mainAxisSize: MainAxisSize.min, children: children),
    );
  }
}

class _CardDivider extends StatelessWidget {
  const _CardDivider();

  @override
  Widget build(BuildContext context) => const Divider(height: 1, indent: 16, endIndent: 16);
}
