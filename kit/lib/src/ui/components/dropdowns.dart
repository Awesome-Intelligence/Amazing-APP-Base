import 'package:material_ui/material_ui.dart';

import '../../i18n/kit_strings.dart';
import '../../theme/kit_theme.dart';

/// 下拉选项。
@immutable
class DropdownOption<T> {
  const DropdownOption({required this.label, required this.value});

  final String label;
  final T value;
}

/// 下拉选择菜单 —— 外形等同于带外框的输入框，点开是选项列表。
///
/// 对应 KMP 的 `SelectDropdown`（M3 ExposedDropdownMenu）。
///
/// 为什么不用 Flutter 的 [DropdownButtonFormField]：它的 `value` 已废弃改成
/// `initialValue`，受控组件每次外部改值都得换 key 强制重建。这里用
/// [InputDecorator] + [DropdownButton]，是**完全受控**的，行为可预期。
///
/// 选中项左侧带 Check 图标（M3 规范），选中值同时显示在框里。
class SelectDropdown<T> extends StatelessWidget {
  const SelectDropdown({
    super.key,
    required this.options,
    required this.selectedOption,
    required this.onOptionSelected,
    this.label = '',
    this.placeholder,
    this.enabled = true,
  });

  final List<DropdownOption<T>> options;
  final T? selectedOption;
  final ValueChanged<T> onOptionSelected;
  final String label;

  /// 未选中时的提示；不传走「请选择」。
  final String? placeholder;

  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final tokens = KitTheme.of(context);
    final s = KitStringsScope.of(context);
    final selected = options.where((o) => o.value == selectedOption).firstOrNull;
    final hint = placeholder ?? s.selectPlaceholder;
    final radius = tokens.shapes.medium;
    final border = OutlineInputBorder(
      borderRadius: radius,
      borderSide: BorderSide(
        color: tokens.colorScheme.outline,
        width: themedStrokeWidth(context, 1),
      ),
    );

    return InputDecorator(
      // isEmpty 的语义是「还没填值」→ label 浮到上边、hint 显示在框内。
      isEmpty: selected == null,
      decoration: InputDecoration(
        labelText: label.isEmpty ? null : label,
        labelStyle: tokens.textTheme.labelMedium,
        hintText: hint,
        hintStyle: tokens.textTheme.bodyMedium?.copyWith(
          color: tokens.colorScheme.onSurfaceVariant,
        ),
        enabled: enabled,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        border: border,
        enabledBorder: border,
        disabledBorder: border,
        focusedBorder: border.copyWith(
          borderSide: BorderSide(color: tokens.colorScheme.primary, width: 2),
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: selected?.value,
          isExpanded: true,
          isDense: true,
          borderRadius: radius,
          hint: Text(hint, style: tokens.textTheme.bodyMedium),
          icon: Icon(Icons.arrow_drop_down, color: tokens.colorScheme.onSurfaceVariant),
          items: [
            for (final option in options)
              DropdownMenuItem<T>(
                value: option.value,
                child: Row(
                  children: [
                    if (option.value == selectedOption) ...[
                      Icon(Icons.check, size: 20, color: tokens.colorScheme.primary),
                      const SizedBox(width: 8),
                    ],
                    Flexible(
                      child: Text(
                        option.label,
                        style: tokens.textTheme.bodyMedium,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
          ],
          onChanged: enabled
              ? (value) {
                  if (value != null) onOptionSelected(value);
                }
              : null,
        ),
      ),
    );
  }
}
