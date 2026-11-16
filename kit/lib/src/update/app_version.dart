/// 版本号（语义化版本，宽松解析）。对应 KMP 的 `data/update/AppVersion.kt`。
///
/// 为什么不用字符串比大小：按字典序 `"1.10.0" < "1.9.0"`，按语义正好相反 ——
/// 版本比较必须拆成数字段逐位比。
///
/// 支持的写法：`1.2.3`、`v1.2.3`、`1.2`、`1.2.3-beta.1`、`1.2.3+build.7`。
/// 规则按 [semver](https://semver.org/)：
/// - 数字段逐位比较，缺的位补 0（`1.2` == `1.2.0`）
/// - 同核心版本下，带 pre-release 的比正式版小（`1.2.3-beta` < `1.2.3`）
/// - pre-release 标识符按 semver 比（数字段比数值，数字 < 字母，字母按字典序）
/// - build metadata（`+` 后面）只做展示，不参与比较
///
/// 解析不出来就返回 null（[parseOrNull]），不抛异常 —— 版本号来自网络，
/// 不能让一条脏数据把 app 打崩。
class AppVersion implements Comparable<AppVersion> {
  /// 核心数字段，至少一段。
  final List<int> numbers;

  /// pre-release 标识符（`-` 后面，按点切开）。
  final List<String> preRelease;

  /// build metadata（`+` 后面），只做展示。
  final String? buildMetadata;

  const AppVersion(
    this.numbers, {
    this.preRelease = const <String>[],
    this.buildMetadata,
  }) : assert(numbers.length > 0, '版本号至少要有一段数字');

  /// 能解析就返回 [AppVersion]，否则返回 null。
  static AppVersion? parseOrNull(String raw) {
    var trimmed = raw.trim();
    if (trimmed.startsWith('v') || trimmed.startsWith('V')) {
      trimmed = trimmed.substring(1);
    }
    if (trimmed.isEmpty) return null;

    // 先切 build metadata（`+`），再切 pre-release（`-`）——
    // 两者都可能有，顺序不能反：1.2.3-beta+001
    final plusIndex = trimmed.indexOf('+');
    final withoutBuild = plusIndex < 0 ? trimmed : trimmed.substring(0, plusIndex);
    final buildMetadata =
        plusIndex < 0 ? null : trimmed.substring(plusIndex + 1);
    if (buildMetadata != null && buildMetadata.isEmpty) return null;

    final dashIndex = withoutBuild.indexOf('-');
    final corePart =
        dashIndex < 0 ? withoutBuild : withoutBuild.substring(0, dashIndex);

    final numbers = <int>[];
    for (final segment in corePart.split('.')) {
      final value = int.tryParse(segment);
      if (value == null) return null;
      numbers.add(value);
    }
    if (numbers.isEmpty) return null;

    var preRelease = const <String>[];
    if (dashIndex >= 0) {
      preRelease = withoutBuild.substring(dashIndex + 1).split('.');
      // 空标识符（`1.2.3-`、`1.2.3-alpha..2`）不是合法 semver
      if (preRelease.any((s) => s.isEmpty)) return null;
    }

    return AppVersion(
      numbers,
      preRelease: preRelease,
      buildMetadata: buildMetadata,
    );
  }

  @override
  int compareTo(AppVersion other) {
    // 1) 核心数字段：位数不同时短的一方补 0
    final size = numbers.length > other.numbers.length
        ? numbers.length
        : other.numbers.length;
    for (var i = 0; i < size; i++) {
      final left = i < numbers.length ? numbers[i] : 0;
      final right = i < other.numbers.length ? other.numbers[i] : 0;
      if (left != right) return left.compareTo(right);
    }

    // 2) 同核心版本：正式版 > 任何 pre-release
    if (preRelease.isEmpty && other.preRelease.isEmpty) return 0;
    if (preRelease.isEmpty) return 1;
    if (other.preRelease.isEmpty) return -1;

    // 3) pre-release 标识符逐个比
    final common = preRelease.length < other.preRelease.length
        ? preRelease.length
        : other.preRelease.length;
    for (var i = 0; i < common; i++) {
      final left = preRelease[i];
      final right = other.preRelease[i];
      final leftNumber = int.tryParse(left);
      final rightNumber = int.tryParse(right);
      final int result;
      if (leftNumber != null && rightNumber != null) {
        result = leftNumber.compareTo(rightNumber);
      } else if (leftNumber != null) {
        // 数字标识符永远小于字母标识符
        result = -1;
      } else if (rightNumber != null) {
        result = 1;
      } else {
        result = left.compareTo(right);
      }
      if (result != 0) return result;
    }
    return preRelease.length.compareTo(other.preRelease.length);
  }

  bool operator >(AppVersion other) => compareTo(other) > 0;
  bool operator <(AppVersion other) => compareTo(other) < 0;
  bool operator >=(AppVersion other) => compareTo(other) >= 0;
  bool operator <=(AppVersion other) => compareTo(other) <= 0;

  @override
  String toString() {
    final buffer = StringBuffer(numbers.join('.'));
    if (preRelease.isNotEmpty) {
      buffer
        ..write('-')
        ..write(preRelease.join('.'));
    }
    if (buildMetadata != null && buildMetadata!.isNotEmpty) {
      buffer
        ..write('+')
        ..write(buildMetadata);
    }
    return buffer.toString();
  }

  @override
  bool operator ==(Object other) =>
      other is AppVersion && compareTo(other) == 0 && _sameShape(other);

  /// build metadata 不参与比较，但参与相等判定 —— 否则 `1.2.3+a` 和 `1.2.3+b`
  /// 会被判成同一个版本，调试时看不出差别。
  bool _sameShape(AppVersion other) =>
      buildMetadata == other.buildMetadata &&
      preRelease.join('.') == other.preRelease.join('.');

  @override
  int get hashCode =>
      Object.hash(numbers.join('.'), preRelease.join('.'), buildMetadata);
}
