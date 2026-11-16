import 'package:flutter/widgets.dart';

import '../../format/kit_date_format.dart';
import '../../i18n/kit_strings.dart';
import '../../settings/app_language.dart';

/// 当前界面语言。
///
/// 直接读 `Localizations.localeOf` —— 因为 `KitAppShell` 已经把应用内的语言选择
/// 落到了 `MaterialApp.locale`，所以这里读到的就是「实际生效」的那个，
/// 不用再从 `AppSettings` 里判断一次（两处判断早晚不一致）。
///
/// 非英文一律落中文，与 [AppLanguage.fromSystemLanguage] 的口径一致。
AppLanguage currentLanguageOf(BuildContext context) =>
    AppLanguage.fromSystemLanguage(Localizations.localeOf(context).languageCode);

/// 年月标题：「2026年10月」/「October 2026」
String formatYearMonth(BuildContext context, DateTime month) =>
    KitDateFormat.yearMonth(month, currentLanguageOf(context));

/// 短日期：「10月14日」/「Oct 14, 2026」
String formatShortDate(BuildContext context, DateTime date) =>
    KitDateFormat.shortDate(date, currentLanguageOf(context));

/// 完整日期：「2026年10月14日」/「Oct 14, 2026」
String formatFullDate(BuildContext context, DateTime date) =>
    KitDateFormat.fullDate(date, currentLanguageOf(context));

/// 相对时间：「刚刚」/「5 分钟前」/「3 小时前」/「2 天前」，超过一周显示短日期。
///
/// [now] 只用于测试注入「现在」，正常调用不传。
String formatRelativeTime(
  BuildContext context,
  int timestampMillis, {
  DateTime? now,
}) {
  final strings = KitStringsScope.of(context);
  final current = now ?? DateTime.now();
  final diff = current.millisecondsSinceEpoch - timestampMillis;

  const minute = 60 * 1000;
  const hour = 60 * minute;
  const day = 24 * hour;

  if (diff < minute) return strings.timeJustNow;
  if (diff < hour) return strings.timeMinutesAgo(diff ~/ minute);
  if (diff < day) return strings.timeHoursAgo(diff ~/ hour);
  if (diff < 7 * day) return strings.timeDaysAgo(diff ~/ day);

  return formatShortDate(
    context,
    DateTime.fromMillisecondsSinceEpoch(timestampMillis),
  );
}
