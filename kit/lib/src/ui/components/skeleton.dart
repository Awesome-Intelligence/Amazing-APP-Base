import 'package:material_ui/material_ui.dart';

import '../../theme/kit_theme.dart';

/// 骨架占位 —— 符合 M3 规范。
///
/// - 基础色：浅色用 `surfaceContainerHighest`，深色用 `surfaceContainerLow`
///   （深色下如果用 Highest 会亮得像张卡，不像"占位"）
/// - 动效：呼吸脉动（1.0 ↔ 0.55，1.1s 往复），不用 M2 的 shimmer
/// - 系统开了「减动效」时**不脉动**，停在完全不透明 —— 静止的灰块比闪烁更友好
///
/// 每个占位块各自跑一个 `AnimationController`。它们在同一帧里启动，视觉上同步；
/// 真要严格对齐得在外面共享一个动画，但骨架屏总共活几百毫秒，不值得。
class _PulseBox extends StatefulWidget {
  const _PulseBox({
    this.width,
    required this.height,
    this.borderRadius,
  });

  /// null = 撑满可用宽度（等价 Compose 的 `fillMaxWidth`）。
  final double? width;
  final double height;
  final BorderRadius? borderRadius;

  @override
  State<_PulseBox> createState() => _PulseBoxState();
}

class _PulseBoxState extends State<_PulseBox>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
    // 0 = Tween 的 begin 端 = 完全不透明。首帧从全亮开始，
    // 而不是从最暗那帧闪一下。
    value: 0,
  );

  late final Animation<double> _opacity = Tween<double>(begin: 1, end: 0.55)
      .animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // 无障碍开关可能在运行时被改（设置页），所以放 didChangeDependencies 而不是 initState。
    if (KitTheme.reducedMotionOf(context)) {
      _controller.stop();
      // 同样停在 begin 端（全亮）：静止的实心灰块比一块半透明更清楚。
      _controller.value = 0;
    } else if (!_controller.isAnimating) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = KitTheme.of(context);
    return FadeTransition(
      opacity: _opacity,
      child: Container(
        width: widget.width ?? double.infinity,
        height: widget.height,
        decoration: BoxDecoration(
          color: tokens.isDark
              ? tokens.colorScheme.surfaceContainerLow
              : tokens.colorScheme.surfaceContainerHighest,
          borderRadius: widget.borderRadius ?? tokens.shapes.small,
        ),
      ),
    );
  }
}

/// 骨架文本行 —— 替代 Text。
class SkeletonTextLine extends StatelessWidget {
  const SkeletonTextLine({
    super.key,
    this.width,
    this.lineHeight = 16,
    this.cornerRadius = 8,
  });

  final double? width;
  final double lineHeight;
  final double cornerRadius;

  @override
  Widget build(BuildContext context) => _PulseBox(
        width: width,
        height: lineHeight,
        borderRadius: themedCorner(context, cornerRadius),
      );
}

/// 骨架圆角矩形 —— 替代各种内容块。
class SkeletonRect extends StatelessWidget {
  const SkeletonRect({
    super.key,
    this.width,
    this.boxHeight = 60,
    this.cornerRadius = 12,
  });

  final double? width;
  final double boxHeight;
  final double cornerRadius;

  @override
  Widget build(BuildContext context) => _PulseBox(
        width: width,
        height: boxHeight,
        borderRadius: themedCorner(context, cornerRadius),
      );
}

/// 骨架圆形头像。
class SkeletonCircle extends StatelessWidget {
  const SkeletonCircle({super.key, this.circleSize = 48});

  final double circleSize;

  @override
  Widget build(BuildContext context) => _PulseBox(
        width: circleSize,
        height: circleSize,
        borderRadius: BorderRadius.circular(circleSize / 2),
      );
}

/// 骨架列表项：头像 + 两行文字。
class SkeletonListItem extends StatelessWidget {
  const SkeletonListItem({
    super.key,
    this.showAvatar = true,
    this.showSubtitle = true,
    this.avatarSize = 48,
  });

  final bool showAvatar;
  final bool showSubtitle;
  final double avatarSize;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      child: Row(
        children: [
          if (showAvatar) ...[
            SkeletonCircle(circleSize: avatarSize),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SkeletonTextLine(lineHeight: 14),
                if (showSubtitle) ...[
                  const SizedBox(height: 8),
                  const SkeletonTextLine(lineHeight: 12, width: 120),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// 骨架卡片：给内容加一层卡片底色与内边距。
class SkeletonCard extends StatelessWidget {
  const SkeletonCard({
    super.key,
    this.cardPadding = 16,
    required this.children,
  });

  final double cardPadding;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final tokens = KitTheme.of(context);
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(cardPadding),
      decoration: BoxDecoration(
        color: tokens.colorScheme.surfaceContainerLow,
        borderRadius: tokens.shapes.medium,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: children,
      ),
    );
  }
}

/// 骨架网格项。
class SkeletonGridItem extends StatelessWidget {
  const SkeletonGridItem({super.key, this.itemHeight = 64});

  final double itemHeight;

  @override
  Widget build(BuildContext context) {
    final tokens = KitTheme.of(context);
    return _PulseBox(height: itemHeight, borderRadius: tokens.shapes.large);
  }
}

// ==================== 预制骨架屏 ====================

/// 一组筛选 chip 的骨架（横向）。
class _ChipRowSkeleton extends StatelessWidget {
  const _ChipRowSkeleton({this.count = 4, this.chipWidth = 60});

  final int count;
  final double chipWidth;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 0; i < count; i++) ...[
          if (i > 0) const SizedBox(width: 8),
          SkeletonRect(width: chipWidth, boxHeight: 32, cornerRadius: 16),
        ],
      ],
    );
  }
}

/// 列表页骨架：搜索框 + 筛选行 + N 张卡片。
///
/// 对应 KMP 的 `GoalListSkeleton`。改名叫通用的，因为底座不该假定业务是「目标」。
class SkeletonListScreen extends StatelessWidget {
  const SkeletonListScreen({super.key, this.itemCount = 6});

  final int itemCount;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SkeletonRect(boxHeight: 56, cornerRadius: 28),
          const SizedBox(height: 16),
          const _ChipRowSkeleton(),
          const SizedBox(height: 16),
          for (var i = 0; i < itemCount; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: SkeletonGridItem(itemHeight: 100),
            ),
        ],
      ),
    );
  }
}

/// 带头像的列表骨架：搜索框 + 筛选行 + 头像行。
///
/// 对应 KMP 的 `ContactListSkeleton`。
class SkeletonAvatarList extends StatelessWidget {
  const SkeletonAvatarList({super.key, this.itemCount = 8});

  final int itemCount;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SkeletonRect(boxHeight: 56, cornerRadius: 28),
          const SizedBox(height: 12),
          const _ChipRowSkeleton(count: 5, chipWidth: 55),
          const SizedBox(height: 12),
          for (var i = 0; i < itemCount; i++) const SkeletonListItem(),
        ],
      ),
    );
  }
}

/// 文本卡片列表骨架：日期标题 + 筛选行 + 多行文本卡。
///
/// 对应 KMP 的 `RecordListSkeleton`。
class SkeletonTextCardList extends StatelessWidget {
  const SkeletonTextCardList({super.key, this.itemCount = 5});

  final int itemCount;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Center(child: SkeletonTextLine(width: 150, lineHeight: 24)),
          const SizedBox(height: 16),
          const _ChipRowSkeleton(count: 5, chipWidth: 50),
          const SizedBox(height: 16),
          for (var i = 0; i < itemCount; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: SkeletonCard(
                children: const [
                  SkeletonTextLine(width: 120, lineHeight: 12),
                  SizedBox(height: 8),
                  SkeletonTextLine(),
                  SizedBox(height: 4),
                  SkeletonTextLine(width: 200),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// 详情页骨架：大图 + 说明卡 + 标签卡 + 子项卡。
///
/// 对应 KMP 的 `GoalDetailSkeleton`。
class SkeletonDetailScreen extends StatelessWidget {
  const SkeletonDetailScreen({super.key, this.childItemCount = 3});

  final int childItemCount;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SkeletonRect(boxHeight: 120),
          const SizedBox(height: 16),
          const SkeletonCard(
            children: [
              SkeletonTextLine(),
              SizedBox(height: 4),
              SkeletonTextLine(width: 200),
            ],
          ),
          const SizedBox(height: 16),
          const SkeletonCard(
            children: [
              SkeletonTextLine(width: 60, lineHeight: 12),
              SizedBox(height: 8),
              _ChipRowSkeleton(chipWidth: 70),
            ],
          ),
          const SizedBox(height: 16),
          SkeletonCard(
            children: [
              const SkeletonTextLine(width: 80, lineHeight: 14),
              const SizedBox(height: 8),
              for (var i = 0; i < childItemCount; i++)
                SizedBox(
                  height: 48,
                  child: Row(
                    children: const [
                      SkeletonCircle(circleSize: 24),
                      SizedBox(width: 12),
                      Expanded(child: SkeletonTextLine()),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
