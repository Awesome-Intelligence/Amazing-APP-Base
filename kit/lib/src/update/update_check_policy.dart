/// 自动检查的策略。对应 KMP 的 `data/update/UpdateCheckPolicy.kt`。
///
/// [minInterval]：两次**自动**检查之间的最小间隔。默认 6 小时 ——
/// 冷启动频繁的 app 不该每次启动都打一次网络；手动检查
/// （`check(force: true)`）不受它限制。
class UpdateCheckPolicy {
  final Duration minInterval;

  const UpdateCheckPolicy({this.minInterval = const Duration(hours: 6)});
}
