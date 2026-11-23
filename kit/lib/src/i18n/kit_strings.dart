import 'package:flutter/widgets.dart';

import '../settings/app_language.dart';
import '../settings/theme_enums.dart';

/// 底座内置文案。
///
/// 为什么不用 gen-l10n / intl：kit 是被各 app fork 的底座，文案量很小（个位数），
/// 走 ARB 会引入代码生成步骤、也让下游改一句话得跑一遍 build。这里用普通的类继承：
/// 加一门语言 = 加一个子类，改一句话 = 改一行。
abstract class KitStrings {
  const KitStrings();

  /// 「过程 N 步」——聊天里折叠条收起时那一行。
  String chatProcessCount(int count);

  String get chatStepRunning;
  String get chatStepDone;
  String get chatStepFailed;

  String get chatApprovalTitle;
  String get chatApprovalDeny;
  String get chatApprovalAllowAlways;
  String get chatApprovalAllowOnce;

  String get emptyTitle;
  String get emptyRetry;

  /// 通用动作。
  String get confirm;
  String get cancel;
  String get delete;
  String get loading;

  /// 删除确认弹窗。
  String get deleteConfirmTitle;
  String get deleteConfirmMessage;

  /// 复选框 / 可选中的无障碍状态描述。
  String get selectedState;
  String get unselectedState;

  /// 设置页。
  String get settings;
  String get back;
  String get appearance;
  String get themeStyle;
  String get appearanceMode;
  String get reduceMotion;
  String get reduceMotionDesc;
  String get language;
  String get languageSetting;
  String get followSystem;
  String get lightMode;
  String get darkMode;
  String get languageChinese;
  String get languageEnglish;

  /// 主题风格的显示名。
  ///
  /// 用 `switch` 而不是 Map：新增风格时编译期就报错，不会静默漏一条导致
  /// 下拉选项和枚举错位（错位了 `selectedIndex` 就指错人）。
  String themeStyleName(ThemeStyle style) => switch (style) {
        ThemeStyle.mono => 'Mono',
        ThemeStyle.swiss => 'Swiss',
        ThemeStyle.notion => 'Notion',
        ThemeStyle.eInk => 'E-Ink',
        ThemeStyle.macOS => 'macOS',
      };

  /// 外观模式的显示名。枚举顺序 = 设置页选项顺序。
  String appearanceModeName(AppearanceMode mode) => switch (mode) {
        AppearanceMode.system => followSystem,
        AppearanceMode.light => lightMode,
        AppearanceMode.dark => darkMode,
      };

  /// 语言选项的显示名。枚举顺序 = 设置页选项顺序。
  String languageName(AppLanguage language) => switch (language) {
        AppLanguage.system => followSystem,
        AppLanguage.chinese => languageChinese,
        AppLanguage.english => languageEnglish,
      };

  /// 搜索框。
  String get searchHint;
  String get search;
  String get clear;
  String get filter;
  String get collapse;

  /// 日历。
  String get previousMonth;
  String get nextMonth;
  String get monthViewSwitchHint;
  String get weekViewSwitchHint;

  /// 「11月15日」/「11/15」—— 日期的无障碍读法。
  String dateMonthDay(int month, int day);
  String get todaySuffix;
  String get selectedSuffix;
  String get weekSelectedSuffix;

  /// 相对时间。
  String get timeJustNow;
  String timeMinutesAgo(int minutes);
  String timeHoursAgo(int hours);
  String timeDaysAgo(int days);

  /// 空状态。
  String get emptyNoContacts;
  String get addFirstContactSubtitle;
  String get emptyNoGoals;
  String get addFirstGoalSubtitle;
  String get noRecordsRecent;
  String get startFirstRecord;
  String get noResultsFound;
  String get tryDifferentSearch;

  /// 操作反馈。
  String get operationSuccess;
  String get operationFailed;

  /// 提示条的级别名（读屏用）。
  String get noticeInfo;
  String get noticeSuccess;
  String get noticeWarning;
  String get noticeError;

  /// 进度百分比。
  String progressPercent(int percent);

  /// 菜单 / 下拉。
  String get moreOptions;
  String get edit;
  String get selectPlaceholder;

  /// 列表 / 表单模板。
  String get add;
  String get save;
  String get close;

  /// 列表项上的紧急标记。
  String get urgent;

  /// 分页指示器（读屏用）。参数是**从 1 开始**的页码。
  String pageIndicator(int current, int total);

  /// 头像相关。
  String get expand;
  String get hideRemoveButton;
  String avatarDescription(String name);
  String get remove;
  String showMoreContacts(int count);

  /// 会员 / 付费墙。
  ///
  /// 这些属于 membership（跟 kit 的不混）；
  /// Flutter 只有一个 `KitStrings`，所以挪到这里，靠注释分组。
  String get membershipPaywallTitle;
  String get membershipUpgrade;
  String get membershipPurchase;
  String get membershipCurrentPlan;
  String get membershipRestore;

  /// 额度用完的付费墙。
  String get quotaPaywallTitle;
  String get quotaUpgrade;

  /// 额度用完的原因说明，[limit] 是当前档位上限。
  String quotaGoalMessage(int limit);
  String quotaContactMessage(int limit);
  String quotaAiMessage(int limit);

  /// 版本更新弹窗。
  String get updateAvailableTitle;
  String get updateRequiredTitle;
  String get updateRequiredHint;
  String get updateNotesTitle;
  String get updateNow;
  String get updateLater;
  String get updateSkipVersion;

  /// 「当前 x → 最新 y」。
  String updateVersionLine(String current, String latest);

  /// 活跃筛选条。
  String get clearAll;

  /// 移除单个筛选的无障碍描述，[label] 是筛选名。
  String removeFilter(String label);

  /// 通知 / 消息中心。
  String get notificationEmptyTitle;
  String get notificationEmptySubtitle;

  /// 未读标记的无障碍读法。
  String get notificationUnread;

  /// 按语言偏好取文案。[AppLanguage.system] 落中文（与「默认资源是中文」一致）。
  static KitStrings forLanguage(AppLanguage language) => switch (language) {
        AppLanguage.english => english,
        AppLanguage.system || AppLanguage.chinese => chinese,
      };

  /// 简体中文（默认）。
  static const KitStrings chinese = _ZhStrings();

  static const KitStrings english = _EnStrings();
}

class _ZhStrings extends KitStrings {
  const _ZhStrings();

  @override
  String chatProcessCount(int count) => '过程 $count 步';

  @override
  String get chatStepRunning => '进行中';
  @override
  String get chatStepDone => '完成';
  @override
  String get chatStepFailed => '失败';

  @override
  String get chatApprovalTitle => '需要你确认';
  @override
  String get chatApprovalDeny => '拒绝';
  @override
  String get chatApprovalAllowAlways => '本任务免确认';
  @override
  String get chatApprovalAllowOnce => '允许一次';

  @override
  String get emptyTitle => '这里还没有内容';
  @override
  String get emptyRetry => '重试';

  @override
  String get confirm => '确认';
  @override
  String get cancel => '取消';
  @override
  String get delete => '删除';
  @override
  String get loading => '正在加载...';

  @override
  String get deleteConfirmTitle => '确认删除';
  @override
  String get deleteConfirmMessage => '删除后无法恢复，确定要删除吗？';

  @override
  String get selectedState => '已选中';
  @override
  String get unselectedState => '未选中';

  @override
  String get settings => '设置';
  @override
  String get back => '返回';
  @override
  String get appearance => '外观';
  @override
  String get themeStyle => '主题风格';
  @override
  String get appearanceMode => '深浅模式';
  @override
  String get reduceMotion => '减动效';
  @override
  String get reduceMotionDesc => '关掉页面动效（无障碍）';
  @override
  String get language => '语言';
  @override
  String get languageSetting => '界面语言';
  @override
  String get followSystem => '跟随系统';
  @override
  String get lightMode => '浅色';
  @override
  String get darkMode => '深色';
  @override
  String get languageChinese => '简体中文';
  @override
  String get languageEnglish => 'English';

  @override
  String themeStyleName(ThemeStyle style) => switch (style) {
        ThemeStyle.mono => '单色',
        ThemeStyle.swiss => '瑞士',
        ThemeStyle.notion => '文档',
        ThemeStyle.eInk => '电子纸',
        ThemeStyle.macOS => '毛玻璃',
      };

  @override
  String get searchHint => '搜索...';
  @override
  String get search => '搜索';
  @override
  String get clear => '清除';
  @override
  String get filter => '筛选';
  @override
  String get collapse => '收起';

  @override
  String get previousMonth => '上个月';
  @override
  String get nextMonth => '下个月';
  @override
  String get monthViewSwitchHint => '月视图，点击切换到周视图';
  @override
  String get weekViewSwitchHint => '周视图，点击切换到月视图';

  @override
  String dateMonthDay(int month, int day) => '$month月$day日';
  @override
  String get todaySuffix => '，今天';
  @override
  String get selectedSuffix => '，已选中';
  @override
  String get weekSelectedSuffix => '，本周已选中';

  @override
  String get timeJustNow => '刚刚';
  @override
  String timeMinutesAgo(int minutes) => '$minutes 分钟前';
  @override
  String timeHoursAgo(int hours) => '$hours 小时前';
  @override
  String timeDaysAgo(int days) => '$days 天前';

  @override
  String get emptyNoContacts => '暂无联系人';
  @override
  String get addFirstContactSubtitle => '开始添加你的第一个联系人吧';
  @override
  String get emptyNoGoals => '暂无目标';
  @override
  String get addFirstGoalSubtitle => '开始设定你的第一个目标吧';
  @override
  String get noRecordsRecent => '暂无记录';
  @override
  String get startFirstRecord => '开始记录';
  @override
  String get noResultsFound => '未找到结果';
  @override
  String get tryDifferentSearch => '试试其他关键词';

  @override
  String get operationSuccess => '操作成功！';
  @override
  String get operationFailed => '操作失败！';

  @override
  String get noticeInfo => '提示';
  @override
  String get noticeSuccess => '成功';
  @override
  String get noticeWarning => '警告';
  @override
  String get noticeError => '错误';

  @override
  String progressPercent(int percent) => '$percent%';

  @override
  String get moreOptions => '更多选项';
  @override
  String get edit => '编辑';
  @override
  String get selectPlaceholder => '请选择';

  @override
  String get add => '添加';
  @override
  String get save => '保存';
  @override
  String get close => '关闭';
  @override
  String get urgent => '紧急';

  @override
  String pageIndicator(int current, int total) => '第 $current 页，共 $total 页';

  @override
  String get expand => '展开';
  @override
  String get hideRemoveButton => '隐藏删除按钮';
  @override
  String avatarDescription(String name) => '$name的头像';
  @override
  String get remove => '移除';
  @override
  String showMoreContacts(int count) => '还有 $count 位联系人，点击查看';

  @override
  String get membershipPaywallTitle => '需要会员才能继续';
  @override
  String get membershipUpgrade => '查看会员方案';
  @override
  String get membershipPurchase => '购买';
  @override
  String get membershipCurrentPlan => '当前方案';
  @override
  String get membershipRestore => '恢复购买';

  @override
  String get quotaPaywallTitle => '额度已用完';
  @override
  String get quotaUpgrade => '查看高级版';
  @override
  String quotaGoalMessage(int limit) => '当前档位最多保存 $limit 个目标，升级后可以创建更多目标。';
  @override
  String quotaContactMessage(int limit) => '当前档位最多保存 $limit 位人脉，升级后可以添加更多人脉。';
  @override
  String quotaAiMessage(int limit) => '今天的 AI 次数已用完（当前档位每天 $limit 次），升级后可用更多次数。';

  @override
  String get updateAvailableTitle => '发现新版本';
  @override
  String get updateRequiredTitle => '需要更新';
  @override
  String get updateRequiredHint => '当前版本已不再支持，请更新后继续使用。';
  @override
  String get updateNotesTitle => '更新内容';
  @override
  String get updateNow => '立即更新';
  @override
  String get updateLater => '稍后';
  @override
  String get updateSkipVersion => '跳过此版本';
  @override
  String updateVersionLine(String current, String latest) => '当前 $current → 最新 $latest';

  @override
  String get clearAll => '清除全部';
  @override
  String removeFilter(String label) => '移除筛选 $label';

  @override
  String get notificationEmptyTitle => '暂无通知';
  @override
  String get notificationEmptySubtitle => '有新的动态时会显示在这里';
  @override
  String get notificationUnread => '未读';
}

class _EnStrings extends KitStrings {
  const _EnStrings();

  @override
  String chatProcessCount(int count) => count == 1 ? '1 step' : '$count steps';

  @override
  String get chatStepRunning => 'running';
  @override
  String get chatStepDone => 'done';
  @override
  String get chatStepFailed => 'failed';

  @override
  String get chatApprovalTitle => 'Approval needed';
  @override
  String get chatApprovalDeny => 'Deny';
  @override
  String get chatApprovalAllowAlways => 'Always allow';
  @override
  String get chatApprovalAllowOnce => 'Allow once';

  @override
  String get emptyTitle => 'Nothing here yet';
  @override
  String get emptyRetry => 'Retry';

  @override
  String get confirm => 'Confirm';
  @override
  String get cancel => 'Cancel';
  @override
  String get delete => 'Delete';
  @override
  String get loading => 'Loading...';

  @override
  String get deleteConfirmTitle => 'Delete?';
  @override
  String get deleteConfirmMessage =>
      'This cannot be undone. Are you sure you want to delete it?';

  @override
  String get selectedState => 'Selected';
  @override
  String get unselectedState => 'Not selected';

  @override
  String get settings => 'Settings';
  @override
  String get back => 'Back';
  @override
  String get appearance => 'Appearance';
  @override
  String get themeStyle => 'Theme style';
  @override
  String get appearanceMode => 'Appearance mode';
  @override
  String get reduceMotion => 'Reduce motion';
  @override
  String get reduceMotionDesc => 'Turn off page animations (accessibility)';
  @override
  String get language => 'Language';
  @override
  String get languageSetting => 'App language';
  @override
  String get followSystem => 'Follow system';
  @override
  String get lightMode => 'Light';
  @override
  String get darkMode => 'Dark';
  @override
  String get languageChinese => 'Chinese (Simplified)';
  @override
  String get languageEnglish => 'English';

  @override
  String themeStyleName(ThemeStyle style) => switch (style) {
        ThemeStyle.mono => 'Mono',
        ThemeStyle.swiss => 'Swiss',
        ThemeStyle.notion => 'Notion',
        ThemeStyle.eInk => 'E-Ink',
        ThemeStyle.macOS => 'Vibrancy',
      };

  @override
  String get searchHint => 'Search...';
  @override
  String get search => 'Search';
  @override
  String get clear => 'Clear';
  @override
  String get filter => 'Filter';
  @override
  String get collapse => 'Collapse';

  @override
  String get previousMonth => 'Previous month';
  @override
  String get nextMonth => 'Next month';
  @override
  String get monthViewSwitchHint => 'Month view, tap to switch to week view';
  @override
  String get weekViewSwitchHint => 'Week view, tap to switch to month view';

  @override
  String dateMonthDay(int month, int day) => '$month/$day';
  @override
  String get todaySuffix => ', today';
  @override
  String get selectedSuffix => ', selected';
  @override
  String get weekSelectedSuffix => ', selected this week';

  @override
  String get timeJustNow => 'Just now';
  @override
  String timeMinutesAgo(int minutes) =>
      minutes == 1 ? '1 minute ago' : '$minutes minutes ago';
  @override
  String timeHoursAgo(int hours) => hours == 1 ? '1 hour ago' : '$hours hours ago';
  @override
  String timeDaysAgo(int days) => days == 1 ? '1 day ago' : '$days days ago';

  @override
  String get emptyNoContacts => 'No contacts yet';
  @override
  String get addFirstContactSubtitle => 'Start adding your first contact';
  @override
  String get emptyNoGoals => 'No goals yet';
  @override
  String get addFirstGoalSubtitle => 'Start setting your first goal';
  @override
  String get noRecordsRecent => 'No recent records';
  @override
  String get startFirstRecord => 'Start recording';
  @override
  String get noResultsFound => 'No results found';
  @override
  String get tryDifferentSearch => 'Try a different keyword';

  @override
  String get operationSuccess => 'Operation successful!';
  @override
  String get operationFailed => 'Operation failed!';

  @override
  String get noticeInfo => 'Notice';
  @override
  String get noticeSuccess => 'Success';
  @override
  String get noticeWarning => 'Warning';
  @override
  String get noticeError => 'Error';

  @override
  String progressPercent(int percent) => '$percent%';

  @override
  String get moreOptions => 'More options';
  @override
  String get edit => 'Edit';
  @override
  String get selectPlaceholder => 'Please select';

  @override
  String get add => 'Add';
  @override
  String get save => 'Save';
  @override
  String get close => 'Close';
  @override
  String get urgent => 'Urgent';

  @override
  String pageIndicator(int current, int total) => 'Page $current of $total';

  @override
  String get expand => 'Expand';
  @override
  String get hideRemoveButton => 'Hide delete button';
  @override
  String avatarDescription(String name) => '$name avatar';
  @override
  String get remove => 'Remove';
  @override
  String showMoreContacts(int count) => '$count more contacts, tap to view';

  @override
  String get membershipPaywallTitle => 'Membership required';
  @override
  String get membershipUpgrade => 'View plans';
  @override
  String get membershipPurchase => 'Purchase';
  @override
  String get membershipCurrentPlan => 'Current plan';
  @override
  String get membershipRestore => 'Restore purchases';

  @override
  String get quotaPaywallTitle => 'Quota reached';
  @override
  String get quotaUpgrade => 'View Premium';
  @override
  String quotaGoalMessage(int limit) =>
      'Your current tier allows up to $limit goals. Upgrade to create more.';
  @override
  String quotaContactMessage(int limit) =>
      'Your current tier allows up to $limit contacts. Upgrade to add more.';
  @override
  String quotaAiMessage(int limit) =>
      "Today's AI calls are used up ($limit per day on your current tier). "
      'Upgrade for more.';

  @override
  String get updateAvailableTitle => 'Update available';
  @override
  String get updateRequiredTitle => 'Update required';
  @override
  String get updateRequiredHint =>
      'This version is no longer supported. Please update to continue.';
  @override
  String get updateNotesTitle => "What's new";
  @override
  String get updateNow => 'Update now';
  @override
  String get updateLater => 'Later';
  @override
  String get updateSkipVersion => 'Skip this version';
  @override
  String updateVersionLine(String current, String latest) =>
      'Current $current → latest $latest';

  @override
  String get clearAll => 'Clear all';
  @override
  String removeFilter(String label) => 'Remove filter $label';

  @override
  String get notificationEmptyTitle => 'No notifications yet';
  @override
  String get notificationEmptySubtitle => 'New activity will show up here';
  @override
  String get notificationUnread => 'Unread';
}

/// 文案作用域。没套作用域时用中文，单测/预览不用额外配置。
class KitStringsScope extends InheritedWidget {
  const KitStringsScope({super.key, required this.strings, required super.child});

  final KitStrings strings;

  static KitStrings of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<KitStringsScope>()?.strings ??
      KitStrings.chinese;

  @override
  bool updateShouldNotify(KitStringsScope oldWidget) => strings != oldWidget.strings;
}
