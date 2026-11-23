import '../settings/app_language.dart';

/// 迷你日期格式化器。
///
/// 为什么不引 `intl`：kit 是被各 app fork 的底座，只用到寥寥几种日期格式，
/// 引 intl 会带进一堆 locale 数据、还要初始化 `initializeDateFormatting`。
/// 这里自己实现一小撮 `DateTimeFormatter` 风格的 pattern 就够了：
///
/// - `yyyy` / `yy` / `y` —— 年
/// - `MMMM` / `MMM` —— 月名（英文全称/缩写；中文都是「10月」）
/// - `MM` / `M` —— 月（补零 / 不补零）
/// - `dd` / `d` —— 日
/// - `'...'` —— 引号里的字面量（`'年'`）
///
/// 只支持 kit 实际用到的这几个 token。
///
/// [AppLanguage.system] 在这里落中文（与「默认语言是中文」一致）；
/// UI 层应先按实际 locale 解析好再传进来 —— 见 `currentLanguageOf`。
class KitDateFormat {
  const KitDateFormat._();

  static const List<String> _enMonths = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December',
  ];

  static const List<String> _enMonthsShort = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  /// 星期窄名：周日 = 0 … 周六 = 6。
  static const List<String> _zhWeekdaysNarrow = ['日', '一', '二', '三', '四', '五', '六'];
  static const List<String> _enWeekdaysNarrow = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];

  /// 日历表头顺序：周日起。`DateTime.weekday` 里周日是 7，所以不是 1..7。
  static const List<int> weekColumnOrder = [7, 1, 2, 3, 4, 5, 6];

  /// 年月：「2026年10月」/「October 2026」
  static String yearMonth(DateTime month, AppLanguage language) => format(
        month,
        _resolve(language) == AppLanguage.english ? 'MMMM yyyy' : "yyyy'年'M'月'",
        language,
      );

  /// 短日期：「10月14日」/「Oct 14, 2026」
  static String shortDate(DateTime date, AppLanguage language) => format(
        date,
        _resolve(language) == AppLanguage.english ? 'MMM d, yyyy' : "M'月'd'日'",
        language,
      );

  /// 完整日期：「2026年10月14日」/「Oct 14, 2026」
  static String fullDate(DateTime date, AppLanguage language) => format(
        date,
        _resolve(language) == AppLanguage.english ? 'MMM d, yyyy' : "yyyy'年'M'月'd'日'",
        language,
      );

  static String format(DateTime date, String pattern, AppLanguage language) =>
      _formatParts(date.year, date.month, date.day, pattern, language);

  /// 星期窄名。传 `DateTime.weekday`（周一 = 1 … 周日 = 7）。
  static String weekdayNarrow(int weekday, AppLanguage language) {
    // 7 % 7 = 0 → 周日落在下标 0，正好对上「周日开头」的排列。
    final index = weekday % 7;
    return _resolve(language) == AppLanguage.english
        ? _enWeekdaysNarrow[index]
        : _zhWeekdaysNarrow[index];
  }

  /// 月份缩写名（「10月」/「Oct」）。
  static String monthShort(int monthNumber, AppLanguage language) =>
      _monthName(monthNumber, language, full: false);

  static AppLanguage _resolve(AppLanguage language) =>
      language == AppLanguage.system ? AppLanguage.chinese : language;

  static String _formatParts(
    int year,
    int month,
    int? day,
    String pattern,
    AppLanguage language,
  ) {
    final out = StringBuffer();
    var i = 0;

    while (i < pattern.length) {
      final c = pattern[i];

      // 引号里的字面量：'年' 原样输出，'' 表示一个引号本身。
      if (c == "'") {
        i++;
        if (i < pattern.length && pattern[i] == "'") {
          out.write("'");
          i++;
          continue;
        }
        while (i < pattern.length && pattern[i] != "'") {
          out.write(pattern[i]);
          i++;
        }
        if (i < pattern.length) i++; // 跳过收尾的 '
        continue;
      }

      if (_isLetter(c)) {
        var j = i;
        while (j < pattern.length && pattern[j] == c) {
          j++;
        }
        out.write(_token(c, j - i, year, month, day, language));
        i = j;
        continue;
      }

      out.write(c);
      i++;
    }

    return out.toString();
  }

  static String _token(
    String c,
    int count,
    int year,
    int month,
    int? day,
    AppLanguage language,
  ) {
    switch (c) {
      case 'y':
        return count == 2
            ? (year % 100).toString().padLeft(2, '0')
            : year.toString();
      case 'M':
        if (count >= 4) return _monthName(month, language, full: true);
        if (count == 3) return _monthName(month, language, full: false);
        if (count == 2) return month.toString().padLeft(2, '0');
        return month.toString();
      case 'd':
        if (day == null) return '';
        return count == 2 ? day.toString().padLeft(2, '0') : day.toString();
      default:
        return '';
    }
  }

  static String _monthName(int month, AppLanguage language, {required bool full}) {
    if (_resolve(language) != AppLanguage.english) return '$month月';
    return full ? _enMonths[month - 1] : _enMonthsShort[month - 1];
  }

  /// `String.isLetter` 不存在于 Dart，用码点判断拉丁字母即可 ——
  /// pattern 里的 token 全是 ASCII 字母，中文都在引号里。
  static bool _isLetter(String c) {
    final code = c.codeUnitAt(0);
    return (code >= 0x41 && code <= 0x5A) || (code >= 0x61 && code <= 0x7A);
  }
}
