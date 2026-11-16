import 'package:material_ui/material_ui.dart';

import '../../i18n/kit_strings.dart';
import '../../theme/kit_theme.dart';

/// 竖排分页圆点指示器。
///
/// 用于全屏纵向翻页的详情页，贴在屏幕右侧：当前页是拉长的胶囊，其余是圆点。
/// 方向与上滑翻页一致，且不占内容区高度。
///
/// 整列带一条语义标签（「第 2 页，共 5 页」），读屏用户能获知位置；
/// 单页时整体不渲染。
class PageIndicator extends StatelessWidget {
  const PageIndicator({
    super.key,
    required this.pageCount,
    required this.currentPage,
  });

  final int pageCount;

  /// 从 0 开始。
  final int currentPage;

  @override
  Widget build(BuildContext context) {
    if (pageCount <= 1) return const SizedBox.shrink();
    final tokens = KitTheme.of(context);
    final s = KitStringsScope.of(context);

    return Semantics(
      label: s.pageIndicator(currentPage + 1, pageCount),
      child: ExcludeSemantics(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var i = 0; i < pageCount; i++) ...[
                if (i > 0) const SizedBox(height: 6),
                AnimatedContainer(
                  duration: KitTheme.reducedMotionOf(context)
                      ? Duration.zero
                      : const Duration(milliseconds: 200),
                  curve: Curves.easeOut,
                  width: 6,
                  height: i == currentPage ? 16 : 6,
                  decoration: BoxDecoration(
                    color: i == currentPage
                        ? tokens.colorScheme.primary
                        : tokens.colorScheme.outlineVariant,
                    borderRadius: themedCorner(context, 3),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
