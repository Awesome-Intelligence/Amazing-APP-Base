/// kit 的 **Flutter 层**：主题 + UI 组件 + 文案。
///
/// 与 `package:kit/kit.dart`（纯 Dart 数据层）分开导出，是因为两者依赖不同：
/// - `kit.dart` 只依赖 dart 核心库，小程序端 / CLI / 契约校验可以只依赖它；
/// - `kit_ui.dart` 依赖 Flutter，只能在 Flutter 工程里用。
///
/// 主题：
/// - `AppTheme` / `KitApp` —— 主题入口（一步到位带 MaterialApp）
/// - `KitAppShell` —— 带 `AppSettings` 的应用外壳（5 套风格 + 跟随系统深浅 + 中英切换）
/// - `KitTheme.of(context)` —— 取 tokens（颜色/扩展色/排版/圆角/标签色）
/// - `kitThemeData(tokens)` —— 自己写 MaterialApp 时用
/// - `themedCorner` / `themedElevation` / `themedControlRadius` / `themedStrokeWidth` /
///   `themedCircleRadius` / `themedDisabledContentColor` / `tagColor`
/// - 5 套预设：`monoThemeTokens` / `swissThemeTokens` / `notionThemeTokens` /
///   `eInkThemeTokens` / `macOSThemeTokens`
///
/// 组件：
/// - 骨架：`Header` / `SettingsScreen` / `SettingsSectionHeader` / `SettingsCard`
/// - 搜索：`KitSearchBar` / `SearchToggleButton`
/// - 日历：`AppCalendar` / `CalendarDay` / `CalendarViewMode`
/// - 占位：`SkeletonTextLine` / `SkeletonRect` / `SkeletonCircle` /
///   `SkeletonListItem` / `SkeletonCard` / `SkeletonGridItem` + 4 个预设骨架屏
/// - 空态：`IllustratedEmptyState` / `EmptyStates`
/// - 反馈：`AppSnackbar` / `showAppSnackbar` / `LoadingIndicator` /
///   `LoadingOverlay` / `CenteredLoading`
/// - 进度：`LinearProgressBar` / `CircularProgressIndicatorWithText` / `StatusMark`
/// - 按钮：`PrimaryButton` / `SecondaryButton` / `SmallSecondaryButton` /
///   `FilledIconButton` / `TextActionButton`
/// - 列表行：`AppSettingsRow` / `AppSettingsIcon` / `AppIconTile` / `ToggleRow`
/// - 卡片：`AppCard` / `SmallCard` / `CardTitle` / `StatsCard` / `StatItem`
/// - 菜单：`SimpleMenuButton` / `SimpleMenuItem` / `ActionMenuRow` / `SelectDropdown`
/// - 导航：`AppBottomNavigation` / `BottomNavItem` / `PageIndicator`
/// - 头像：`UserAvatar` / `AvatarStack` / `ExpandedAvatarRow` / `ContactItem`
/// - 网格：`adaptiveGridColumns` / `adaptiveGridDelegate` / `gridSpacingFor`
/// - 动效：`CollapsibleSection` / `AnimatedContentSwitch` / `M3Motion` / `motionDuration`
/// - 弹窗：`ConfirmDialog` / `SelectDialog` / `DeleteConfirmDialog` /
///   `InputDialog` / `LoadingDialog`
/// - agent：`ChatMessage` / `ChatMessageList` / `ChatStepsFold` / `ChatStepRow` /
///   `ToolApprovalCard`
/// - 会员：`MembershipPaywall` / `QuotaPaywall` / `QuotaReason` / `UpgradeSheet`
///
/// 模板（所有页面按它实现）：
/// - `KitListScreen` / `ListViewMode` / `KitListItem` / `KitListItemCard`
/// - `KitFormScreen` / `FormSection` / `KitFormField`
///
/// 日期显示：`currentLanguageOf` / `formatYearMonth` / `formatShortDate` /
/// `formatFullDate` / `formatRelativeTime`
///
/// 文案：`KitStrings` / `KitStringsScope`
library kit_ui;

// 会员 UI 的入参类型（`PlanOption` / `PlanFeature` 等）来自 membership 包。
// 顺带导出这几个，业务只 import kit_ui 就能构造升级页。
export 'package:kit_membership/membership.dart'
    show Plan, PlanCatalog, PlanFeature, PlanOption, QuotaLimit, QuotaPeriod;

// 主题
export 'src/theme/app_theme.dart';
export 'src/theme/color_schemes.dart';
export 'src/theme/extended_colors.dart';
export 'src/theme/kit_shapes.dart';
export 'src/theme/kit_theme.dart';
export 'src/theme/motion.dart';
export 'src/theme/palettes.dart';
export 'src/theme/theme_tokens.dart';
export 'src/theme/typography_tokens.dart';

// 文案
export 'src/i18n/kit_strings.dart';

// 外壳
export 'src/ui/shell/kit_app_shell.dart';

// 异步状态：四态密封类 + mapUiState / uiStateOf。
// 页面用它承载加载/成功/失败，不要每个页面各写一套 isLoading+data+error。
export 'src/ui/state/ui_state.dart';

// 组件
export 'src/ui/components/active_filters_bar.dart';
export 'src/ui/components/adaptive_grid.dart';
export 'src/ui/components/avatar.dart';
export 'src/ui/components/bottom_navigation.dart';
export 'src/ui/components/buttons.dart';
export 'src/ui/components/calendar.dart';
export 'src/ui/components/cards.dart';
export 'src/ui/components/chips.dart';
export 'src/ui/components/dialogs.dart';
export 'src/ui/components/dropdowns.dart';
export 'src/ui/components/empty_state.dart';
export 'src/ui/components/feedback.dart';
export 'src/ui/components/header.dart';
export 'src/ui/components/list_items.dart';
export 'src/ui/components/menu.dart';
export 'src/ui/components/motion.dart';
export 'src/ui/components/page_indicator.dart';
export 'src/ui/components/progress.dart';
export 'src/ui/components/search_bar.dart';
export 'src/ui/components/settings_rows.dart';
export 'src/ui/components/skeleton.dart';
export 'src/ui/components/stats.dart';
export 'src/ui/components/status_mark.dart';
export 'src/ui/components/tag_text.dart';
export 'src/ui/components/text_fields.dart';
export 'src/ui/components/toggle_row.dart';
export 'src/ui/components/scroll_to_top.dart';
export 'src/ui/components/undo_history.dart';
export 'src/ui/components/update_dialog.dart';
export 'src/ui/agent/chat_message.dart';
export 'src/ui/agent/chat_message_list.dart';
export 'src/ui/agent/chat_message_mapper.dart';
export 'src/ui/agent/tool_approval_card.dart';

// 日期显示
export 'src/ui/format/date_display.dart';

// 会员
export 'src/ui/membership/paywall.dart';
export 'src/ui/membership/upgrade_sheet.dart';

// 设置页
export 'src/ui/settings/settings_screen.dart';

// 模板屏
export 'src/ui/templates/form_screen.dart';
export 'src/ui/templates/list_screen.dart';
