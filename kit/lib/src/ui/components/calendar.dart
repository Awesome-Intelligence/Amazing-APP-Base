import 'package:material_ui/material_ui.dart';

import '../../format/kit_date_format.dart';
import '../../i18n/kit_strings.dart';
import '../../settings/theme_enums.dart';
import '../../theme/kit_theme.dart';
import '../format/date_display.dart';

/// 日历视图模式。
enum CalendarViewMode {
  /// 整月网格，只高亮选中的那一天。
  day,

  /// 单周一行。
  week,

  /// 整月网格（与 [day] 渲染相同，语义上表示「月」这一层）。
  month,

  /// 整月网格 + 高亮选中日所在的那一整周，并响应整周点击。
  monthWeekHighlight,
}

/// 日历里的一个格子。
class CalendarDay {
  const CalendarDay({
    required this.date,
    required this.dayNumber,
    this.isToday = false,
    this.isCurrentMonth = true,
  });

  /// 这个格子代表的日期。补位格子也有真实日期（属于上/下个月），点它同样能选中。
  final DateTime date;

  /// 显示的数字（1…31）。
  final String dayNumber;

  final bool isToday;

  /// 是否属于当前展示的月份。false = 上/下个月的补位格，字号会更淡。
  final bool isCurrentMonth;
}

/// Material 3 日历 —— 日 / 周 / 月视图，可翻页，可整周高亮。
///
/// - 圆角 12、surface 底
/// - 导航箭头 48 触控区
/// - 今天用 `secondaryContainer`，选中用 `primary`，整周高亮用 `primaryContainer`
/// - 每周从**周日**开始
///
/// [viewMode] 由外部控制：本组件不自己存视图状态，只在标题被点时回调
/// [onViewModeChange] 请求切换（viewMode 为 null 时标题不可点）。
/// 这么设计是因为「日/周/月」通常是页面级状态（要跟其它控件联动），
/// 藏在日历内部反而不好接。
class AppCalendar extends StatefulWidget {
  const AppCalendar({
    super.key,
    required this.selectedDate,
    this.onDateSelected,
    this.viewMode = CalendarViewMode.month,
    this.onViewModeChange,
    this.onWeekSelected,
  });

  final DateTime selectedDate;
  final ValueChanged<DateTime>? onDateSelected;
  final CalendarViewMode viewMode;
  final ValueChanged<CalendarViewMode>? onViewModeChange;

  /// 仅在 [CalendarViewMode.monthWeekHighlight] 下生效，回传那一周的周日。
  final ValueChanged<DateTime>? onWeekSelected;

  @override
  State<AppCalendar> createState() => _AppCalendarState();
}

class _AppCalendarState extends State<AppCalendar> {
  /// 展示用的日期与选中的日期**解耦**：箭头只翻页，选中某天才回调。
  /// 否则「翻到别的月看看」就会顺手改掉选中项。
  late DateTime _displayed = _dateOnly(widget.selectedDate);

  /// 翻页方向，决定动画从哪边滑进来。
  bool _forward = true;

  @override
  void didUpdateWidget(covariant AppCalendar oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 外部换了选中日期 → 展示位置跟过去。
    if (!_sameDay(oldWidget.selectedDate, widget.selectedDate)) {
      _displayed = _dateOnly(widget.selectedDate);
    }
  }

  void _go(int delta) {
    setState(() {
      _forward = delta > 0;
      _displayed = widget.viewMode == CalendarViewMode.week
          ? _addDays(_displayed, 7 * delta)
          : _addMonths(_displayed, delta);
    });
  }

  /// 点标题循环切视图：日 → 周 → 月(周高亮) → 日；月在两者之间按「日 → 周」走。
  void _cycleViewMode() {
    final callback = widget.onViewModeChange;
    if (callback == null) return;
    callback(switch (widget.viewMode) {
      CalendarViewMode.day => CalendarViewMode.week,
      CalendarViewMode.week => CalendarViewMode.monthWeekHighlight,
      CalendarViewMode.month => CalendarViewMode.day,
      CalendarViewMode.monthWeekHighlight => CalendarViewMode.day,
    });
  }

  @override
  Widget build(BuildContext context) {
    final tokens = KitTheme.of(context);
    final reducedMotion = KitTheme.reducedMotionOf(context);
    // macOS 毛玻璃规范：动效只改颜色，不位移。
    final noMotion =
        reducedMotion || tokens.themeStyle == ThemeStyle.macOS;

    final yearMonth = DateTime(_displayed.year, _displayed.month);
    // key 带上日期本身：周视图翻周时年月不变，只带年月会认成「同一页」而不做动画。
    final contentKey = ValueKey(
      '${widget.viewMode.name}|${_displayed.year}-${_displayed.month}-${_displayed.day}',
    );

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: tokens.colorScheme.surface,
        borderRadius: tokens.shapes.medium,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _CalendarHeader(
            title: formatYearMonth(context, yearMonth),
            viewMode: widget.viewMode,
            onPrevious: () => _go(-1),
            onNext: () => _go(1),
            onTitleClick: widget.onViewModeChange == null ? null : _cycleViewMode,
          ),
          const SizedBox(height: 12),
          const _WeekdayLabels(),
          const SizedBox(height: 8),
          AnimatedSwitcher(
            duration: noMotion ? Duration.zero : const Duration(milliseconds: 220),
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeInCubic,
            transitionBuilder: (child, animation) {
              if (noMotion) return child;
              // Compose 版的 AnimatedContent 会区分「换视图（纯淡入）」和
              // 「翻页（带方向的滑入）」。AnimatedSwitcher 的 builder 拿不到
              // 前后状态，所以统一成「淡入 + 轻微横移」，翻页方向由 _forward 决定。
              final begin = Offset(_forward ? 0.12 : -0.12, 0);
              return SlideTransition(
                position: Tween<Offset>(begin: begin, end: Offset.zero)
                    .animate(animation),
                child: FadeTransition(opacity: animation, child: child),
              );
            },
            child: KeyedSubtree(
              key: contentKey,
              child: _buildGrid(yearMonth),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGrid(DateTime yearMonth) {
    switch (widget.viewMode) {
      case CalendarViewMode.week:
        return _weekRow(_generateWeekDays(_displayed), highlightWeek: true);
      case CalendarViewMode.day:
        return _monthGrid(_generateMonthDays(yearMonth), highlightWeek: false);
      case CalendarViewMode.month:
        return _monthGrid(_generateMonthDays(yearMonth), highlightWeek: false);
      case CalendarViewMode.monthWeekHighlight:
        return _monthGrid(_generateMonthDays(yearMonth), highlightWeek: true);
    }
  }

  Widget _monthGrid(List<CalendarDay> days, {required bool highlightWeek}) {
    final weeks = <List<CalendarDay>>[];
    for (var i = 0; i < days.length; i += 7) {
      weeks.add(days.sublist(i, (i + 7).clamp(0, days.length)));
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final week in weeks)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: _weekRow(week, highlightWeek: highlightWeek),
          ),
      ],
    );
  }

  Widget _weekRow(List<CalendarDay> week, {required bool highlightWeek}) {
    // 只统计真实日期格（补位格在这里也都有日期，所以就是整行）。
    final isSelectedWeek =
        highlightWeek && week.any((d) => _sameDay(d.date, widget.selectedDate));
    final firstDate = week.isEmpty ? null : week.first.date;

    final row = Row(
      children: [
        for (final day in week)
          Expanded(
            child: _CalendarDayCell(
              // 带上日期做 key：换月时同一位置的格子会被复用，
              // 没有 key 的话水波纹/语义节点会串到上个月的同位置格子上。
              key: ValueKey(
                'cal-${day.date.year}-${day.date.month}-${day.date.day}',
              ),
              day: day,
              isSelected: _sameDay(day.date, widget.selectedDate),
              isWeekSelected: isSelectedWeek,
              onTap: () => widget.onDateSelected?.call(day.date),
            ),
          ),
      ],
    );

    if (widget.onWeekSelected == null || firstDate == null) return row;
    return InkWell(
      onTap: () => widget.onWeekSelected!(firstDate),
      borderRadius: themedCorner(context, 12),
      child: row,
    );
  }
}

class _CalendarHeader extends StatelessWidget {
  const _CalendarHeader({
    required this.title,
    required this.viewMode,
    required this.onPrevious,
    required this.onNext,
    required this.onTitleClick,
  });

  final String title;
  final CalendarViewMode viewMode;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final VoidCallback? onTitleClick;

  @override
  Widget build(BuildContext context) {
    final tokens = KitTheme.of(context);
    final strings = KitStringsScope.of(context);
    final switchHint = switch (viewMode) {
      CalendarViewMode.month => strings.monthViewSwitchHint,
      CalendarViewMode.monthWeekHighlight => strings.monthViewSwitchHint,
      _ => strings.weekViewSwitchHint,
    };

    return Row(
      children: [
        // M3 IconButton 自带 48 触控区。
        IconButton(
          onPressed: onPrevious,
          tooltip: strings.previousMonth,
          color: tokens.colorScheme.onSurfaceVariant,
          icon: const Icon(Icons.chevron_left),
        ),
        Expanded(
          child: Center(
            child: Tooltip(
              // 标题在可切换时提示「点我能换视图」，否则不弹。
              message: onTitleClick == null ? '' : switchHint,
              child: InkWell(
                onTap: onTitleClick,
                borderRadius: tokens.shapes.small,
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Text(
                    title,
                    style: tokens.textTheme.titleMedium
                        ?.copyWith(color: tokens.colorScheme.onSurface),
                  ),
                ),
              ),
            ),
          ),
        ),
        IconButton(
          onPressed: onNext,
          tooltip: strings.nextMonth,
          color: tokens.colorScheme.onSurfaceVariant,
          icon: const Icon(Icons.chevron_right),
        ),
      ],
    );
  }
}

class _WeekdayLabels extends StatelessWidget {
  const _WeekdayLabels();

  @override
  Widget build(BuildContext context) {
    final tokens = KitTheme.of(context);
    final language = currentLanguageOf(context);

    return Row(
      children: [
        for (final weekday in KitDateFormat.weekColumnOrder)
          Expanded(
            child: Text(
              KitDateFormat.weekdayNarrow(weekday, language),
              textAlign: TextAlign.center,
              style: tokens.textTheme.labelSmall
                  ?.copyWith(color: tokens.colorScheme.onSurfaceVariant),
            ),
          ),
      ],
    );
  }
}

class _CalendarDayCell extends StatelessWidget {
  const _CalendarDayCell({
    super.key,
    required this.day,
    required this.isSelected,
    required this.isWeekSelected,
    required this.onTap,
  });

  final CalendarDay day;
  final bool isSelected;
  final bool isWeekSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = KitTheme.of(context);
    final strings = KitStringsScope.of(context);

    // 背景色优先级：选中 > 整周高亮 > 今天 > 普通。
    final background = isSelected
        ? tokens.colorScheme.primary
        : isWeekSelected
            ? tokens.colorScheme.primaryContainer
            : day.isToday
                ? tokens.colorScheme.secondaryContainer
                : tokens.colorScheme.surface;

    final foreground = isSelected
        ? tokens.colorScheme.onPrimary
        : isWeekSelected
            ? tokens.colorScheme.onPrimaryContainer
            : day.isToday
                ? tokens.colorScheme.onSecondaryContainer
                : day.isCurrentMonth
                    ? tokens.colorScheme.onSurface
                    : tokens.colorScheme.onSurfaceVariant.withValues(alpha: 0.5);

    // 读屏要能听出「几月几号 + 今天 / 已选中 / 本周已选中」，
    // 光念一个「15」是没用的。
    final label = StringBuffer(
      strings.dateMonthDay(day.date.month, day.date.day),
    );
    if (day.isToday) label.write(strings.todaySuffix);
    if (isSelected) {
      label.write(strings.selectedSuffix);
    } else if (isWeekSelected) {
      label.write(strings.weekSelectedSuffix);
    }

    return Semantics(
      label: label.toString(),
      button: true,
      // 排掉子节点的语义：不然读屏会把「11月15日，已选中」和格子里的「15」念两遍。
      excludeSemantics: true,
      child: AspectRatio(
        aspectRatio: 1,
        child: Padding(
          padding: const EdgeInsets.all(2),
          child: Material(
            color: background,
            shape: RoundedRectangleBorder(
              borderRadius: themedCircleShape(context),
            ),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: onTap,
              child: Center(
                child: Text(
                  day.dayNumber,
                  style: tokens.textTheme.bodyMedium
                      ?.copyWith(color: foreground),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ==================== 日期计算 ====================

DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

bool _sameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

/// `DateTime(y, m + 1, 0)` 就是「下个月的第 0 天」= 本月最后一天，Dart 会自动归一化。
int _daysInMonth(int year, int month) => DateTime(year, month + 1, 0).day;

/// 加减月份后归一到 1 号：避免「1 月 31 日 + 1 个月」溢出成 3 月。
/// 展示层只用到年月，丢掉「几号」没有副作用。
DateTime _addMonths(DateTime d, int delta) => DateTime(d.year, d.month + delta, 1);

/// 加减天数用构造器而不是 `add(Duration)` —— Duration 是绝对时长，
/// 遇到夏令时切换那天会偏一小时，跨到前一天/后一天。
DateTime _addDays(DateTime d, int delta) =>
    DateTime(d.year, d.month, d.day + delta);

/// 生成整月网格，前后用相邻月份补满整周。
List<CalendarDay> _generateMonthDays(DateTime yearMonth) {
  final first = DateTime(yearMonth.year, yearMonth.month, 1);
  // 每周从周日开始：Dart 的 weekday 是周一=1…周日=7，取模后周日正好落在 1。
  final firstWeekday = first.weekday % 7 + 1;
  final daysInMonth = _daysInMonth(first.year, first.month);
  final today = _dateOnly(DateTime.now());

  final result = <CalendarDay>[];

  // 上个月补齐第一周
  if (firstWeekday > 1) {
    final prevMonthDays = _daysInMonth(first.year, first.month - 1);
    for (var i = prevMonthDays - firstWeekday + 2; i <= prevMonthDays; i++) {
      result.add(CalendarDay(
        date: DateTime(first.year, first.month - 1, i),
        dayNumber: '$i',
        isCurrentMonth: false,
        isToday: _sameDay(DateTime(first.year, first.month - 1, i), today),
      ));
    }
  }

  // 本月
  for (var day = 1; day <= daysInMonth; day++) {
    final date = DateTime(first.year, first.month, day);
    result.add(CalendarDay(
      date: date,
      dayNumber: '$day',
      isToday: _sameDay(date, today),
    ));
  }

  // 下个月补齐最后一周
  final remaining = 7 - (result.length % 7);
  if (remaining < 7) {
    for (var day = 1; day <= remaining; day++) {
      final date = DateTime(first.year, first.month + 1, day);
      result.add(CalendarDay(
        date: date,
        dayNumber: '$day',
        isCurrentMonth: false,
        isToday: _sameDay(date, today),
      ));
    }
  }

  return result;
}

/// 生成某一周的七天（周日起）。
List<CalendarDay> _generateWeekDays(DateTime anchor) {
  final today = _dateOnly(DateTime.now());
  // daysSinceSunday：周日 0、周一 1 … 周六 6。
  final daysSinceSunday = anchor.weekday % 7;
  final sunday = _addDays(anchor, -daysSinceSunday);

  return [
    for (var i = 0; i < 7; i++)
      () {
        final date = _addDays(sunday, i);
        return CalendarDay(
          date: date,
          dayNumber: '${date.day}',
          isToday: _sameDay(date, today),
        );
      }(),
  ];
}
