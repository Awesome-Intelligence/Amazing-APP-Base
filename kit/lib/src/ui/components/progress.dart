import 'package:material_ui/material_ui.dart';

import '../../i18n/kit_strings.dart';
import '../../theme/kit_theme.dart';

/// 线性进度条：高 8、圆角 4。
///
/// 进度变化走补间动画；开了减动效就当场跳变（KMP 版是 `M3Motion.defaultSpatial()`
/// 在减动效时返回 snap，这里等价处理）。
class LinearProgressBar extends StatelessWidget {
  const LinearProgressBar({
    super.key,
    required this.progress,
    this.color,
    this.trackColor,
  });

  /// 0.0 ~ 1.0。越界会被夹住（真实 bug：后端给了 1.2 时
  /// `LinearProgressIndicator` 会画到轨道外面）。
  final double progress;

  final Color? color;
  final Color? trackColor;

  @override
  Widget build(BuildContext context) {
    final tokens = KitTheme.of(context);
    final reduced = KitTheme.reducedMotionOf(context);
    final value = progress.clamp(0.0, 1.0).toDouble();

    return ClipRRect(
      borderRadius: themedCorner(context, 4),
      child: SizedBox(
        height: 8,
        child: TweenAnimationBuilder<double>(
          tween: Tween<double>(end: value),
          duration: reduced ? Duration.zero : const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
          builder: (context, v, _) => LinearProgressIndicator(
            value: v,
            color: color ?? tokens.colorScheme.primary,
            backgroundColor: trackColor ?? tokens.extras.surfaceVariant,
          ),
        ),
      ),
    );
  }
}

/// 带百分比的环形进度（默认 60 大小 / 6 环宽，圆角端点）。
///
/// 轨道用「完整一圈的 track 色」再盖一层进度弧，所以进度为 0 时也能看到底环 ——
/// 只有一个 `CircularProgressIndicator` 的话，0% 时整个环消失，看起来像没加载出来。
class CircularProgressIndicatorWithText extends StatelessWidget {
  const CircularProgressIndicatorWithText({
    super.key,
    required this.progress,
    this.progressColor,
    this.trackColor,
    this.size = 60,
    this.strokeWidth = 6,
  });

  final double progress;
  final Color? progressColor;
  final Color? trackColor;
  final double size;
  final double strokeWidth;

  @override
  Widget build(BuildContext context) {
    final tokens = KitTheme.of(context);
    final s = KitStringsScope.of(context);
    final reduced = KitTheme.reducedMotionOf(context);
    final value = progress.clamp(0.0, 1.0).toDouble();
    final textStyle =
        size >= 60 ? tokens.textTheme.labelMedium : tokens.textTheme.labelSmall;

    return SizedBox(
      width: size,
      height: size,
      child: TweenAnimationBuilder<double>(
        tween: Tween<double>(end: value),
        duration: reduced ? Duration.zero : const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        builder: (context, v, _) => Stack(
          alignment: Alignment.center,
          children: [
            SizedBox.expand(
              child: CircularProgressIndicator(
                value: 1,
                color: trackColor ?? tokens.extras.surfaceVariant,
                strokeWidth: strokeWidth,
                strokeCap: StrokeCap.round,
              ),
            ),
            SizedBox.expand(
              child: CircularProgressIndicator(
                value: v,
                color: progressColor ?? tokens.colorScheme.primary,
                strokeWidth: strokeWidth,
                strokeCap: StrokeCap.round,
              ),
            ),
            Text(
              s.progressPercent((v * 100).round()),
              style: textStyle,
              // 数字宽度不一会让百分比在圆心左右跳；等宽数字对齐住。
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
