import 'package:material_ui/material_ui.dart';

/// M3 断点：中等宽度窗口的下界（dp）。
const double kMediumWidthBreakpoint = 600;

/// 网格边距：margin（贴边走多少）与 gutter（卡片之间隔多少）。
///
/// M3 按窗口宽度分档：紧凑档 margin 16，中等及以上 24。gutter 取 12/16 ——
/// 比 M3 的 8/16 略宽，跟项目「卡片间距 12–16」的规范一致。
@immutable
class GridSpacing {
  const GridSpacing({required this.margin, required this.gutter});

  final double margin;
  final double gutter;

  @override
  bool operator ==(Object other) =>
      other is GridSpacing && other.margin == margin && other.gutter == gutter;

  @override
  int get hashCode => Object.hash(margin, gutter);

  @override
  String toString() => 'GridSpacing(margin: $margin, gutter: $gutter)';
}

/// 按窗口宽度（dp）选边距。纯函数，方便单测。
GridSpacing gridSpacingFor(double widthDp) => widthDp >= kMediumWidthBreakpoint
    ? const GridSpacing(margin: 24, gutter: 16)
    : const GridSpacing(margin: 16, gutter: 12);

/// 画廊网格的列数：每格不小于 [minSize]，且**至少** [minColumns] 列。
///
/// 为什么不用 `SliverGridDelegateWithMaxCrossAxisExtent`：它只保证「每格不小于
/// maxExtent 的对应值」，列数 = 可用宽 / 单格上限向下取整，窗口一窄（分屏、
/// 自由窗口、折叠屏外屏）就掉回 1 列，卡片会变得又宽又扁。
/// 这里在同样的算法上加一个列数下限。
///
/// [widthDp] 是**内容区**宽度，已扣掉 [GridSpacing.margin]。
int adaptiveGridColumns(
  double widthDp, {
  double minSize = 132,
  int minColumns = 2,
  double spacing = 12,
}) {
  assert(minSize > 0, 'minSize 必须为正');
  assert(minColumns > 0, 'minColumns 必须为正');
  if (widthDp <= 0) return minColumns;
  final fit = ((widthDp + spacing) / (minSize + spacing)).floor();
  return fit < minColumns ? minColumns : fit;
}

/// 直接给 Flutter 用的网格代理。
///
/// 用法：
/// ```dart
/// GridView.builder(
///   padding: EdgeInsets.all(spacing.margin),
///   gridDelegate: adaptiveGridDelegate(width: constraints.maxWidth),
///   ...
/// )
/// ```
SliverGridDelegate adaptiveGridDelegate({
  required double width,
  double minSize = 132,
  int minColumns = 2,
  double spacing = 12,
  GridSpacing? gridSpacing,
  double childAspectRatio = 1,
}) {
  final s = gridSpacing ?? gridSpacingFor(width);
  final contentWidth = width - s.margin * 2;
  return SliverGridDelegateWithFixedCrossAxisCount(
    crossAxisCount: adaptiveGridColumns(
      contentWidth,
      minSize: minSize,
      minColumns: minColumns,
      spacing: s.gutter,
    ),
    mainAxisSpacing: gridSpacing?.gutter ?? s.gutter,
    crossAxisSpacing: s.gutter,
    childAspectRatio: childAspectRatio,
  );
}
