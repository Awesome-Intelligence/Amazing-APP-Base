/// 检查更新的本地状态 —— 只存两件事，够“自动发现”用了。
/// 对应 KMP 的 `data/update/UpdateState.kt`。
///
/// - [lastCheckedAtMillis]：上次**尝试**检查的时间（失败也记）。节流靠它，
///   否则离线的用户每次冷启动都要等一次超时
/// - [skippedVersion]：用户点过“跳过此版本”的版本号；出现更新的版本时自动失效
class UpdateState {
  final int lastCheckedAtMillis;
  final String? skippedVersion;

  const UpdateState({
    this.lastCheckedAtMillis = 0,
    this.skippedVersion,
  });

  UpdateState copyWith({
    int? lastCheckedAtMillis,
    String? skippedVersion,
  }) =>
      UpdateState(
        lastCheckedAtMillis: lastCheckedAtMillis ?? this.lastCheckedAtMillis,
        // 显式传 null 表示清掉，用 hasSkipped 区分“没传”和“传了 null”
        skippedVersion:
            skippedVersion == null ? this.skippedVersion : skippedVersion,
      );

  /// 清掉“跳过此版本”的记录（出现更新的版本时用）。
  UpdateState clearSkipped() => UpdateState(
        lastCheckedAtMillis: lastCheckedAtMillis,
        skippedVersion: null,
      );

  factory UpdateState.fromJson(Map<String, Object?> json) {
    final millis = json['lastCheckedAtMillis'];
    final skipped = json['skippedVersion'];
    return UpdateState(
      lastCheckedAtMillis: millis is int ? millis : 0,
      skippedVersion: skipped is String && skipped.isNotEmpty ? skipped : null,
    );
  }

  Map<String, Object?> toJson() => <String, Object?>{
        'lastCheckedAtMillis': lastCheckedAtMillis,
        if (skippedVersion != null) 'skippedVersion': skippedVersion,
      };

  @override
  String toString() =>
      'UpdateState(last: $lastCheckedAtMillis, skipped: $skippedVersion)';
}
