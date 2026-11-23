import 'package:material_ui/material_ui.dart';

import '../../i18n/kit_strings.dart';
import '../../theme/kit_theme.dart';
import '../components/header.dart';

/// 表单页模板 —— 新增 / 编辑的标准套路。
///
/// 页头只有两个动作：左边关闭（不保存）、右边保存。**不放删除** ——
/// 删除是破坏性操作，塞在保存旁边最容易点错；该放页面内容区的底部。
///
/// 这里只画一个 [Column]。原因是 [Header] 自己已经吃了状态栏内边距、也铺了底色，
/// 再套一层 Scaffold 会多出一层 Material 和一层底色，在带透明度的主题
/// （macOS 毛玻璃）下会叠成两种颜色。外层仍建议由路由提供 Scaffold 承载
/// SnackBar 和悬浮按钮。
class KitFormScreen extends StatelessWidget {
  const KitFormScreen({
    super.key,
    required this.title,
    required this.isEditMode,
    required this.onCloseClick,
    required this.onSaveClick,
    required this.content,
    this.saveEnabled = true,
    this.saveLoading = false,
    this.titleIcon,
  });

  /// 标题。传空串时按模式回落成「添加」/「编辑」。
  final String title;

  final bool isEditMode;

  /// 左上角关闭（返回，不保存）。
  final VoidCallback onCloseClick;

  final VoidCallback onSaveClick;

  /// 内容填完了才置 true。保存进行中也自动禁用。
  final bool saveEnabled;

  /// 保存中：按钮禁用，防止连点提交两次。
  final bool saveLoading;

  /// 标题前的小图标（emoji / 分类图标）。
  final Widget? titleIcon;

  /// 表单内容，通常是若干 [FormSection] + [KitFormField]。
  final Widget content;

  @override
  Widget build(BuildContext context) {
    final tokens = KitTheme.of(context);
    final strings = KitStringsScope.of(context);
    final headerTitle = title.isNotEmpty
        ? title
        : (isEditMode ? strings.edit : strings.add);

    return ColoredBox(
      color: tokens.extras.background,
      child: Column(
        children: [
          Header(
            title: headerTitle,
            titleIcon: titleIcon,
            leading1: IconButton(
              icon: const Icon(Icons.arrow_back, size: 24),
              tooltip: strings.close,
              onPressed: onCloseClick,
            ),
            action1: IconButton(
              icon: const Icon(Icons.check, size: 24),
              tooltip: strings.save,
              onPressed: saveEnabled && !saveLoading ? onSaveClick : null,
            ),
          ),
          Expanded(
            child: SingleChildScrollView(child: content),
          ),
        ],
      ),
    );
  }
}

/// 表单域 —— 给**非文本**控件（日期卡、色板、Chip 组）用的外置标题布局。
///
/// 名字带 `Kit` 前缀：Flutter 的 widgets 里有 `FormField<T>`（`Form` 的字段包装），
/// 两包都 import 时必撞名，且撞了之后报错只提示"imported from both"，不好定位。
///
/// 文本框和下拉框自带 M3 浮动标签，**不要**再用这个包一层，
/// 否则屏幕上会出现两个标题（外置一个、浮动一个）。
class KitFormField extends StatelessWidget {
  const KitFormField({
    super.key,
    required this.label,
    required this.child,
    this.padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
  });

  final String label;
  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final tokens = KitTheme.of(context);
    return Padding(
      padding: padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            label,
            style: tokens.textTheme.labelLarge?.copyWith(
              color: tokens.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }
}

/// 表单分组 —— 一组字段上方的小标题（primary 色，弱于页头标题）。
class FormSection extends StatelessWidget {
  const FormSection({
    super.key,
    required this.title,
    required this.children,
  });

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final tokens = KitTheme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Text(
            title,
            style: tokens.textTheme.titleSmall?.copyWith(
              color: tokens.colorScheme.primary,
            ),
          ),
        ),
        ...children,
      ],
    );
  }
}
