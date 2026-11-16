import 'package:material_ui/material_ui.dart';

import '../../i18n/kit_strings.dart';
import '../../theme/kit_theme.dart';
import 'buttons.dart';

/// 带插图的空状态。
///
/// 结构：100 的图标容器（tint 色淡填充）+ titleLarge 标题 + bodyMedium 副标题
/// + 可选主操作。整块纵向排布、间距 20、上下留白 40。
///
/// 对应 KMP 的 `IllustratedEmptyState`。
class IllustratedEmptyState extends StatelessWidget {
  const IllustratedEmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.actionTitle,
    this.onAction,
    this.tintColor,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final String? actionTitle;
  final VoidCallback? onAction;

  /// 图标容器与图标的着色，默认取主题 primary。
  final Color? tintColor;

  @override
  Widget build(BuildContext context) {
    final tokens = KitTheme.of(context);
    final tint = tintColor ?? tokens.colorScheme.primary;
    // 深色底上淡填充要更亮一点才看得出「有块底色」。
    final fillAlpha = tokens.isDark ? 0.15 : 0.08;
    final iconAlpha = tokens.isDark ? 0.85 : 0.7;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Column(
        crossAxisAlignment: themedCrossAxisAlignment(context, CrossAxisAlignment.center),
        children: [
          SizedBox(
            width: 100,
            height: 100,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: tint.withValues(alpha: fillAlpha),
                      borderRadius: themedCircleShape(context),
                    ),
                  ),
                ),
                Icon(icon, size: 40, color: tint.withValues(alpha: iconAlpha)),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Text(
            title,
            style: tokens.textTheme.titleLarge,
            textAlign: themedTextAlign(context, TextAlign.center),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                subtitle!,
                style: tokens.textTheme.bodyMedium?.copyWith(
                  color: tokens.colorScheme.onSurfaceVariant,
                ),
                textAlign: themedTextAlign(context, TextAlign.center),
              ),
            ),
          ],
          if (actionTitle != null && onAction != null) ...[
            const SizedBox(height: 28),
            PrimaryButton(text: actionTitle!, onPressed: onAction),
          ],
        ],
      ),
    );
  }
}

/// 预置空状态 —— 对应 KMP 的 `EmptyStates` 对象。
///
/// 都是静态工厂：业务页写 `EmptyStates.contacts()` 就够，不用每次凑图标和文案。
/// 返回 widget 而不是直接画，是为了能塞进 `CustomScrollView` 的 sliver 里
/// （`SliverFillRemaining(child: EmptyStates.contacts())`）。
abstract final class EmptyStates {
  /// 列表页空态。页面自带悬浮添加按钮，这里不再重复给「添加」操作。
  static Widget contacts() => const _Preset(
        icon: Icons.person_add_alt_1_outlined,
        titleKey: _EmptyText.noContacts,
      );

  static Widget goals() => const _Preset(
        icon: Icons.flag_outlined,
        titleKey: _EmptyText.noGoals,
      );

  static Widget records() => const _Preset(
        icon: Icons.edit_outlined,
        titleKey: _EmptyText.noRecords,
      );

  /// 搜索无结果 —— 用 onSurfaceVariant 着色，弱于「还没有内容」那种主色强调。
  static Widget noSearchResults(String query) =>
      _Preset(icon: Icons.search_off, titleKey: _EmptyText.noResults, muted: true);
}

enum _EmptyText { noContacts, noGoals, noRecords, noResults }

/// 预置空状态的共同实现。
///
/// 文案在 build 时从 [KitStringsScope] 取 —— 不能是 `static final`，
/// 那样会在第一次访问时把当时的语言固化下来，切语言不跟着变。
class _Preset extends StatelessWidget {
  const _Preset({
    required this.icon,
    required this.titleKey,
    this.muted = false,
  });

  final IconData icon;
  final _EmptyText titleKey;
  final bool muted;

  @override
  Widget build(BuildContext context) {
    final s = KitStringsScope.of(context);
    final tokens = KitTheme.of(context);
    final (title, subtitle) = switch (titleKey) {
      _EmptyText.noContacts => (s.emptyNoContacts, s.addFirstContactSubtitle),
      _EmptyText.noGoals => (s.emptyNoGoals, s.addFirstGoalSubtitle),
      _EmptyText.noRecords => (s.noRecordsRecent, s.startFirstRecord),
      _EmptyText.noResults => (s.noResultsFound, s.tryDifferentSearch),
    };
    return IllustratedEmptyState(
      icon: icon,
      title: title,
      subtitle: subtitle,
      tintColor: muted ? tokens.colorScheme.onSurfaceVariant : null,
    );
  }
}
