import 'package:material_ui/material_ui.dart';

import '../../i18n/kit_strings.dart';
import '../../theme/kit_theme.dart';
import '../../theme/theme_tokens.dart';

/// 用户头像圆 —— 有图显示图，没有就退回首字母。
///
/// 「我」相关页面（我的资料 / 我的 / 抽屉头部）共用同一套渲染。
/// 用 [Image.network] 加载，加载失败退回字母 —— 头像 URL 过期是很常见的情况，
/// 不能让整块空白。
class UserAvatar extends StatelessWidget {
  const UserAvatar({
    super.key,
    required this.avatar,
    required this.name,
    this.size = 48,
    this.initialStyle,
  });

  /// 头像地址；null 或空串 → 首字母。
  final String? avatar;

  final String name;
  final double size;

  /// 首字母的排版；不传按尺寸挑一档。
  final TextStyle? initialStyle;

  @override
  Widget build(BuildContext context) {
    final tokens = KitTheme.of(context);
    final url = avatar;
    final hasImage = url != null && url.trim().isNotEmpty;
    // 字大时用小一号的字号，头像放大到 96 时首字母才不会顶满。
    final style = initialStyle ??
        (size >= 64 ? tokens.textTheme.headlineSmall : tokens.textTheme.titleMedium);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: tokens.colorScheme.primary,
        shape: BoxShape.circle,
      ),
      clipBehavior: Clip.antiAlias,
      alignment: Alignment.center,
      child: hasImage
          ? Image.network(
              url,
              width: size,
              height: size,
              fit: BoxFit.cover,
              semanticLabel: name,
              errorBuilder: (_, __, ___) => _initial(style, tokens),
            )
          : _initial(style, tokens),
    );
  }

  Widget _initial(TextStyle? style, ThemeTokens tokens) {
    // characters 而不是 name[0]：名字以 emoji 开头时按码元取会切出半个字符。
    final ch = name.characters.isEmpty ? '?' : name.characters.first;
    return Text(ch, style: style, textAlign: TextAlign.center);
  }
}

/// 联系人。
@immutable
class ContactItem {
  const ContactItem({
    required this.id,
    required this.name,
    this.avatarUrl,
    this.subtitle,
  });

  final String id;
  final String name;
  final String? avatarUrl;
  final String? subtitle;
}

/// 联系人头像堆叠。
///
/// 两种形态：
/// - **紧凑**（默认）：数量 ≤ [maxVisible] 时横排不重叠；超出时重叠 1/3，
///   最右挂一个「+N」，点它展开。
/// - **展开**：横排全部显示，点头像选中（露出删除按钮），再点取消。
///
/// 点击整块也会在两种形态间切换 —— 但只有超量时才可点，否则点了个寂寞。
///

class AvatarStack extends StatefulWidget {
  const AvatarStack({
    super.key,
    required this.contacts,
    required this.onContactClick,
    this.onRemoveContact,
    this.maxVisible = 4,
    this.avatarSize = 40,
  });

  final List<ContactItem> contacts;
  final ValueChanged<ContactItem> onContactClick;
  final ValueChanged<ContactItem>? onRemoveContact;

  /// 紧凑态最多露几个。
  final int maxVisible;

  final double avatarSize;

  @override
  State<AvatarStack> createState() => _AvatarStackState();
}

class _AvatarStackState extends State<AvatarStack> {
  bool _expanded = false;
  String? _selectedId;

  @override
  void didUpdateWidget(AvatarStack oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 联系人被删到不超量时，还停在展开态就没意义了 —— 自动收起来。
    if (_expanded && widget.contacts.length <= widget.maxVisible) {
      _expanded = false;
      _selectedId = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = KitStringsScope.of(context);
    final contacts = widget.contacts;
    if (contacts.isEmpty) return const SizedBox.shrink();

    final overflow = contacts.length > widget.maxVisible;
    final expanded = _expanded && overflow;
    final step = widget.avatarSize / 3; // 相邻圆心距 = 1/3 直径 → 重叠 2/3

    final Widget content;
    if (expanded) {
      content = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final c in contacts)
            _AvatarItem(
              contact: c,
              size: widget.avatarSize,
              selected: _selectedId == c.id,
              showRemove: _selectedId == c.id && widget.onRemoveContact != null,
              onTap: () {
                setState(() => _selectedId = _selectedId == c.id ? null : c.id);
                widget.onContactClick(c);
              },
              onRemove: widget.onRemoveContact == null
                  ? null
                  : () {
                      widget.onRemoveContact!(c);
                      setState(() => _selectedId = null);
                    },
            ),
        ],
      );
    } else if (!overflow) {
      content = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final c in contacts)
            _AvatarItem(
              contact: c,
              size: widget.avatarSize,
              onTap: () => widget.onContactClick(c),
            ),
        ],
      );
    } else {
      final visible = contacts.take(widget.maxVisible).toList();
      final hidden = contacts.length - widget.maxVisible;
      final width = widget.avatarSize + step * (visible.length - 1) + step;

      content = SizedBox(
        height: widget.avatarSize,
        width: width,
        child: Stack(
          // 触控目标比圆大 8，最右那个会超出计算宽度 —— 不裁掉。
          clipBehavior: Clip.none,
          children: [
            for (var i = 0; i < visible.length; i++)
              Positioned(
                left: i * step,
                child: _AvatarItem(
                  contact: visible[i],
                  size: widget.avatarSize,
                  onTap: () => widget.onContactClick(visible[i]),
                ),
              ),
            Positioned(
              left: visible.length * step,
              child: _OverflowBadge(
                count: hidden,
                size: widget.avatarSize,
                onTap: () => setState(() => _expanded = true),
              ),
            ),
          ],
        ),
      );
    }

    return Semantics(
      button: overflow,
      label: overflow ? s.showMoreContacts(contacts.length - widget.maxVisible) : null,
      child: GestureDetector(
        onTap: overflow ? () => setState(() => _expanded = !_expanded) : null,
        child: AnimatedSize(
          duration: KitTheme.reducedMotionOf(context)
              ? Duration.zero
              : const Duration(milliseconds: 250),
          curve: Curves.easeOutCubic,
          alignment: Alignment.centerLeft,
          child: content,
        ),
      ),
    );
  }
}

/// 单个头像（含可选的删除角标）。外框比圆大 8，凑够 48 的触控目标。
class _AvatarItem extends StatelessWidget {
  const _AvatarItem({
    required this.contact,
    required this.size,
    required this.onTap,
    this.onRemove,
    this.selected = false,
    this.showRemove = false,
  });

  final ContactItem contact;
  final double size;
  final VoidCallback onTap;
  final VoidCallback? onRemove;
  final bool selected;
  final bool showRemove;

  @override
  Widget build(BuildContext context) {
    final tokens = KitTheme.of(context);
    final s = KitStringsScope.of(context);
    final reduced = KitTheme.reducedMotionOf(context);

    return SizedBox(
      width: size + 8,
      height: size + 8,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: 4,
            top: 4,
            child: Semantics(
              label: s.avatarDescription(contact.name),
              button: true,
              child: GestureDetector(
                onTap: onTap,
                child: Container(
                  width: size,
                  height: size,
                  decoration: BoxDecoration(
                    color: tokens.colorScheme.primaryContainer,
                    shape: BoxShape.circle,
                  ),
                  clipBehavior: Clip.antiAlias,
                  alignment: Alignment.center,
                  child: _face(tokens),
                ),
              ),
            ),
          ),
          if (onRemove != null)
            Positioned(
              right: 0,
              top: 0,
              child: AnimatedScale(
                scale: showRemove ? 1 : 0,
                duration: reduced ? Duration.zero : const Duration(milliseconds: 150),
                child: IgnorePointer(
                  ignoring: !showRemove,
                  child: GestureDetector(
                    onTap: onRemove,
                    child: Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        color: tokens.colorScheme.errorContainer,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.close,
                        size: 12,
                        color: tokens.colorScheme.onErrorContainer,
                        semanticLabel: s.remove,
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _face(ThemeTokens tokens) {
    final url = contact.avatarUrl;
    if (url != null && url.trim().isNotEmpty) {
      return Image.network(
        url,
        width: size,
        height: size,
        fit: BoxFit.cover,
        semanticLabel: contact.name,
        errorBuilder: (_, __, ___) => _initial(tokens),
      );
    }
    return _initial(tokens);
  }

  Widget _initial(ThemeTokens tokens) {
    final ch = contact.name.characters.isEmpty ? '?' : contact.name.characters.first;
    return Text(
      ch,
      style: tokens.textTheme.titleMedium?.copyWith(
        color: tokens.colorScheme.onPrimaryContainer,
      ),
    );
  }
}

/// 超量时的「+N」圆。
class _OverflowBadge extends StatelessWidget {
  const _OverflowBadge({
    required this.count,
    required this.size,
    required this.onTap,
  });

  final int count;
  final double size;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = KitTheme.of(context);
    final s = KitStringsScope.of(context);

    return SizedBox(
      width: size + 8,
      height: size + 8,
      child: Center(
        child: GestureDetector(
          onTap: onTap,
          child: Semantics(
            label: s.showMoreContacts(count),
            button: true,
            child: Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                color: tokens.colorScheme.secondaryContainer,
                shape: BoxShape.circle,
                border: Border.all(
                  // 描边用页面底色，让「+N」从被盖住的头像里跳出来。
                  color: tokens.extras.background,
                  width: 2,
                ),
              ),
              alignment: Alignment.center,
              child: Text(
                '+$count',
                style: tokens.textTheme.labelMedium?.copyWith(
                  color: tokens.colorScheme.onSecondaryContainer,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// 展开形态的横向滚动卡片列表（备选布局）。
///
/// 和 [AvatarStack] 的展开态不同：这里是「头像 + 名字 + 删除」的横向滚动条，
/// 适合横向空间充足（平板 / 宽屏）的场景。
class ExpandedAvatarRow extends StatelessWidget {
  const ExpandedAvatarRow({
    super.key,
    required this.contacts,
    required this.onContactClick,
    this.onRemoveContact,
    this.avatarSize = 40,
  });

  final List<ContactItem> contacts;
  final ValueChanged<ContactItem> onContactClick;
  final ValueChanged<ContactItem>? onRemoveContact;
  final double avatarSize;

  @override
  Widget build(BuildContext context) {
    final tokens = KitTheme.of(context);
    final s = KitStringsScope.of(context);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final c in contacts) ...[
            Material(
              color: tokens.extras.surfaceVariant,
              borderRadius: tokens.shapes.medium,
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: () => onContactClick(c),
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Semantics(
                        label: s.avatarDescription(c.name),
                        child: Container(
                          width: avatarSize,
                          height: avatarSize,
                          decoration: BoxDecoration(
                            color: tokens.colorScheme.primaryContainer,
                            shape: BoxShape.circle,
                          ),
                          clipBehavior: Clip.antiAlias,
                          alignment: Alignment.center,
                          child: Text(
                            c.name.characters.isEmpty ? '?' : c.name.characters.first,
                            style: tokens.textTheme.titleMedium?.copyWith(
                              color: tokens.colorScheme.onPrimaryContainer,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        c.name,
                        style: tokens.textTheme.bodyMedium?.copyWith(
                          color: tokens.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      if (onRemoveContact != null) ...[
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: () => onRemoveContact!(c),
                          child: Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: tokens.colorScheme.errorContainer,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.close,
                              size: 16,
                              color: tokens.colorScheme.onErrorContainer,
                              semanticLabel: s.remove,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
          ],
        ],
      ),
    );
  }
}
