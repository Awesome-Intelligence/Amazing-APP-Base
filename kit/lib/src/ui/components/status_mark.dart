import 'package:material_ui/material_ui.dart';

import '../../theme/kit_theme.dart';

/// 状态形状标记 —— 实心 / 空心方块。
///
/// 规范（电子纸）：「圆点不是唯一的状态载体，错误和警告不另发明新色相」。
/// 零色相主题里颜色扛不住状态，**形状 + 文字**才扛得住 —— 这个方块就是那个形状。
///
/// 不叫 EInkXxx：它是通用的形状标记，灰阶之外的主题也能用。
class StatusMark extends StatelessWidget {
  const StatusMark({
    super.key,
    required this.filled,
    this.size = 8,
    this.color,
  });

  final bool filled;
  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final tokens = KitTheme.of(context);
    final c = color ?? tokens.colorScheme.onSurfaceVariant;

    return SizedBox.square(
      dimension: size,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: filled ? c : null,
          // 空心是描边 —— 直角风格下描边方块和实心方块才区分得开，
          // 所以这里刻意不跟主题圆角走。
          border: filled ? null : Border.all(color: c, width: 1),
        ),
      ),
    );
  }
}
