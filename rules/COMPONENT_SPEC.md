# Android-Kit - Android 公共组件规范

> 版本：1.2.0
> 日期：2026-11-16
> 适用范围：Flutter 版（Dart + Widget），底座 `kit/` + 各 app

---

## 1. 设计令牌 (Design Tokens)

### 1.1 圆角半径

| Token | 值 | 用途 |
|-------|-----|------|
| `corner_radius` | 16dp | 卡片、容器 |
| `corner_radius_medium` | 12dp | 输入框、中按钮 |
| `corner_radius_small` | 10dp | 小元素 |
| `corner_radius_tertiary` | 8dp | 标签、Chip |
| `corner_radius_badge` | 4dp | 徽章、小指示器 |
| `corner_radius_editor` | 6dp | 文本输入区 |
| `corner_radius_large` | 20dp | 大卡片、浮层 |

> Token 数值与 `kit/lib/src/theme/` 下的 tokens 一致；dp 直接当逻辑像素用。

### 1.2 间距 (4pt Grid)

| Token | 值 | 用途 |
|-------|-----|------|
| `spacing1` | 4dp | 标签内间距 |
| `spacing2` | 8dp | 小元素间距 |
| `spacing3` | 12dp | 卡片内元素间距 |
| `spacing4` | 16dp | 页面边距、卡片间距 |
| `spacing5` | 20dp | 大区块间距 |
| `spacing6` | 24dp | 区块间间距 |
| `spacing8` | 32dp | 页面顶部/底部间距 |

### 1.3 阴影

| Token | 用途 |
|-------|------|
| `card_elevation` | 卡片阴影 |
| `elevated_elevation` | 悬浮元素 |
| `dragging_elevation` | 拖拽时 |

```dart
// Flutter 没有 res/values —— 阴影直接用 Material 的 elevation 数值：
// 卡片 2 / 悬浮 6 / 拖拽 8；需要按主题变化就用 kit 的 token（kit/lib/src/theme/kit_shapes.dart）。
```

### 1.4 字体

使用 Material 3 Typography（`kit/lib/src/theme/typography_tokens.dart`）：

| Style | 字号 / 行高 | 用途 |
|-------|-------------|------|
| `displayLarge` | 57 / 64 sp | 大标题 |
| `headlineLarge` | 32 / 40 sp | 页面标题 |
| `headlineMedium` | 28 / 36 sp | 区块标题 |
| `headlineSmall` | 24 / 32 sp | 次级标题 |
| `titleLarge` | 22 / 28 sp | 卡片标题 |
| `titleMedium` | 16 / 24 sp | 列表项标题 |
| `bodyLarge` | 16 / 24 sp | 正文 |
| `bodyMedium` | 14 / 20 sp | 次级正文 |
| `bodySmall` | 12 / 16 sp | 辅助说明 |
| `labelLarge` | 14 / 20 sp | 按钮文字 |
| `labelMedium` | 12 / 16 sp | 标签 |
| `labelSmall` | 11 / 16 sp | 徽章、计数 |

---

## 2. 颜色系统

### 2.1 语义颜色

| 用途 | 浅色模式 | 深色模式 | 来源 |
|------|----------|----------|------|
| Primary | #1D1915 | #E6E2DE | `Mono.primaryLight/Dark` |
| Success | #2D6A4F | #6BCB96 | `ExtendedColors.success` |
| Warning | #B75D00 | #FFB95C | `ExtendedColors.warning` |
| Error | #BA1A1A | #FFB4AB | `Mono.errorLight/Dark` |

> Primary 走单色（近黑 / 近白）主题；Success / Warning 是 Material 3 之外扩展的语义色，
> 通过 `MaterialTheme.extendedColors` 读取。

### 2.2 文本颜色

| 用途 | 浅色模式 | 深色模式 | 来源 |
|------|----------|----------|------|
| 主文本 `onSurface` | #1D1915 | #E7E3DF | `Mono.onSurfaceLight/Dark` |
| 次文本 `onSurfaceVariant` | #4C463F | #C8C3BE | `Mono.onSurfaceVariantLight/Dark` |
| 三级文本 `outline` | #7C756E | #918B84 | `Mono.outlineLight/Dark` |

### 2.3 背景颜色

| 用途 | 浅色模式 | 深色模式 | 来源 |
|------|----------|----------|------|
| 背景 `background` | #FDFAF6 | #15110D | `Mono.backgroundLight/Dark` |
| 次级背景 `surfaceVariant` | #E9E5E1 | #2F2A25 | `Mono.surfaceVariantLight/Dark` |
| 三级背景 `surfaceContainer` | #F1EDEA | #221D19 | `Mono.surfaceContainerLight/Dark` |

### 2.4 填充颜色

| 用途 | 浅色模式 | 深色模式 | 来源 |
|------|----------|----------|------|
| Fill | `outline` @ 20% | `outline` @ 36% | `Mono.outlineLight/Dark` |
| 次级填充 | `outline` @ 12% | `outline` @ 24% | `Mono.outlineLight/Dark` |

---

## 3. 按钮组件

### 3.1 主按钮 (PrimaryButton)

```
┌──────────────────────────┐
│        按钮文字           │
└──────────────────────────┘
```

**规格：**
- 高度：48dp
- 圆角：12dp
- 背景：Primary
- 文字：OnPrimary，14sp Medium
- 内边距：水平 24dp

**状态：**
- Default：Primary 背景
- Pressed：Primary @ 80% 亮度
- Disabled：Primary @ 38% 亮度

```dart
// kit/lib/src/ui/components/buttons.dart
  const PrimaryButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.enabled = true,
    this.expand = false,
  });
```

### 3.2 次要按钮 (SecondaryButton)

```
┌──────────────────────────┐
│        按钮文字           │
└──────────────────────────┘
```

**规格：**
- 高度：48dp
- 圆角：12dp
- 背景：Transparent
- 边框：1dp，Primary
- 文字：Primary，14sp Medium

```dart
// kit/lib/src/ui/components/buttons.dart
  const SecondaryButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.enabled = true,
    this.icon,
    this.expand = false,
  });
```

### 3.3 图标按钮 (IconButton)

```
┌────┐
│ +  │
└────┘
```

**规格：**
- 尺寸：48dp × 48dp
- 圆角：12dp
- 图标：24dp
- TouchTarget：48dp × 48dp

```dart
// kit/lib/src/ui/components/buttons.dart
  const FilledIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.tooltip,
    this.enabled = true,
  });
```

### 3.4 图标按钮 (ScaleIconButton)

圆形图标按钮，**按下反馈用 M3 state layer**（onSurface 10% 圆角底），
不做缩放 —— M3 没有 "press scale" 这一条，按下反馈走 state layer。

> **未迁到 Flutter**：ScaleIconButton（带缩放动效的图标按钮）
>
> KMP 备份在仓库外 `kmp-legacy-backup/`，本仓库不维护。
> 真的要这个组件，从备份里挑实现搬进 `kit/lib/src/ui/components/`。
> 清单见 [`FLUTTER_MIGRATION.md`](../FLUTTER_MIGRATION.md)。

---

## 4. 卡片组件

### 4.1 标准卡片 (Card)

```
┌─────────────────────────────────────┐
│                                     │
│           卡片内容                  │
│                                     │
└─────────────────────────────────────┘
```

**规格：**
- 圆角：16dp
- 内边距：16dp
- 背景：Surface
- 阴影：elevation 2dp

```dart
// kit/lib/src/ui/components/cards.dart
  const AppCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(16),
    this.border,
  });
```

### 4.2 小卡片 (SmallCard)

```dart
// kit/lib/src/ui/components/cards.dart
  const SmallCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(12),
  });
```

### 4.3 记录卡片 (RecordCard)

> **未迁到 Flutter**：RecordCard（记录卡）
>
> KMP 备份在仓库外 `kmp-legacy-backup/`，本仓库不维护。
> 真的要这个组件，从备份里挑实现搬进 `kit/lib/src/ui/components/`。
> 清单见 [`FLUTTER_MIGRATION.md`](../FLUTTER_MIGRATION.md)。

---

## 5. 筛选/标签组件

### 5.1 筛选芯片 (FilterChip)

```
┌─────────────┐
│  标签文字    │
└─────────────┘
```

**规格：**
- 圆角：8dp
- 内边距：水平 12dp，垂直 6dp
- 文字：14sp
- 选中态：Primary @ 15% 背景，Primary 文字
- 未选中态：SurfaceVariant 背景，OnSurfaceVariant 文字

```dart
// kit/lib/src/ui/components/chips.dart
  const KitFilterChip({
    super.key,
    required this.title,
    required this.isSelected,
    required this.onTap,
    this.leadingDotColor,
    this.leadingIcon,
  });
```

### 5.2 标签 (Tag)

```dart
// kit/lib/src/ui/components/tag_text.dart
  const TagText({
    super.key,
    required this.text,
    required this.color,
    this.isSelected = false,
    this.onTap,
    this.selectedIcon = Icons.check,
    this.showSelectedIcon = true,
  });
```

---

## 6. 空状态组件

### 6.1 空状态插图 (IllustratedEmptyState)

```dart
// kit/lib/src/ui/components/empty_state.dart
  const IllustratedEmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.actionTitle,
    this.onAction,
    this.tintColor,
  });
```

---

## 7. 反馈组件

### 7.1 Toast/Snackbar

```dart
// kit/lib/src/ui/components/feedback.dart
  const AppSnackbar({
    super.key,
    required this.message,
    required this.isSuccess,
  });
```

### 7.2 加载指示器

```dart
// kit/lib/src/ui/components/feedback.dart
  const LoadingIndicator({super.key});

  const LoadingOverlay({
    super.key,
    required this.isLoading,
    required this.child,
  });
```

---

## 8. 工具栏组件

### 8.1 悬浮工具栏 (FloatingToolbar)

> **未迁到 Flutter**：FloatingToolbar（悬浮工具栏）+ ToolbarIconButton
>
> KMP 备份在仓库外 `kmp-legacy-backup/`，本仓库不维护。
> 真的要这个组件，从备份里挑实现搬进 `kit/lib/src/ui/components/`。
> 清单见 [`FLUTTER_MIGRATION.md`](../FLUTTER_MIGRATION.md)。

---

## 9. 统计组件

### 9.1 统计项 (StatItem)

```dart
// kit/lib/src/ui/components/stats.dart
  const StatItem({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  const StatsCard({super.key, required this.stats});
```

---

## 10. 菜单组件

### 10.1 溢出菜单按钮 (MenuButton)

```dart
// kit/lib/src/ui/components/menu.dart
  const SimpleMenuButton({
    super.key,
    required this.items,
    required this.onItemSelected,
    this.contentDescription,
    this.icon = Icons.more_vert,
  });

  const SimpleMenuItem({
    this.title = '',
    this.icon,
    this.trailingIcon,
    this.isDivider = false,
    this.subItems = const <SimpleMenuItem>[],
  });
```

---

## 11. 动画规范

动效**全部**来自 `kit/lib/src/theme/motion.dart` 的 `M3Motion`。
页面/组件里**不许手写** `tween` / `spring` 的时长与 easing 字面量 —— 需要新节奏就先加 token。

选型表（什么场景用哪个预设）在 `rules/GOOGLE_STYLE.md` §动效，**这里不重复**：两处维护必然漂移，
（这条规矩本身就是因为本文件曾长期写着一段代码里并不存在的 `AppAnimations` 才立的）。

### 11.1 Duration（M3 标准值）

| Token | 值 | 用途 |
|---|---|---|
| `SHORT1` | 50ms | 选中 / 取消选中 |
| `SHORT2` | 100ms | 简单状态切换 |
| `SHORT3` | 150ms | 小组件出现 |
| `SHORT4` | 200ms | 标准交互 |
| `MEDIUM1` | 250ms | 面板展开 |
| `MEDIUM2` | 300ms | 标准转场 |
| `MEDIUM3` | 350ms | 复杂转场 |
| `MEDIUM4` | 400ms | 全屏转场（启动页） |
| `LONG1` | 450ms | 强调动画 |
| `LONG2` | 500ms | 复杂强调 |
| `EXIT_FADE` | 90ms | 转场退场淡出（必须比位移快） |
| `FADE_THROUGH_IN` | 210ms | Fade Through 进场（叠 90ms 退场 = 300ms） |
| `FADE_THROUGH_INITIAL_SCALE` | 0.92 | Fade Through 进场初始缩放 |
| `SHARED_AXIS_OFFSET` | 30dp | Shared Axis X 位移量（不是整屏宽度） |
| `FLOAT_INITIAL_SCALE` | 0.8 | 浮层从锚点长出的初始缩放 |

### 11.2 Easing

| Token | 曲线 | 用途 |
|---|---|---|
| `emphasized` | cubic-bezier(0.2, 0, 0, 1) | 强调 |
| `emphasizedDecelerate` | cubic-bezier(0.05, 0.7, 0.1, 1) | 进场 |
| `emphasizedAccelerate` | cubic-bezier(0.3, 0, 0.8, 0.15) | 退场 |

### 11.3 Spring

| Token | damping / stiffness | 用途 |
|---|---|---|
| `fastSpatial()` | 0.9 / 1400 | 跟手位移、尺寸 |
| `defaultSpatial()` | 0.9 / 700 | 常态位移、尺寸 |
| `expressiveSpatial()` | 0.6 / 800 | 庆祝 / 强调回弹（唯一允许过冲的一档，别用于常态位移） |
| `fastEffects()` | 1.0 / 3800 | 颜色、透明度（不过冲） |
| `defaultEffects()` | 1.0 / 1600 | 同上，常态 |
| `itemPlacement()` | 1.0 / 400 | 列表条目换位（不过冲，项不会互相压过） |
| `pagerScroll()` | tween MEDIUM2 + 强调减速 | Pager 程序化翻页（只用于相邻页） |

### 11.4 页面级转场

组件内部用 `M3Motion`，**整页之间**用 `kit/lib/src/theme/motion.dart` 的转场曲线：

| 场景 | 用什么 |
|---|---|
| 同层级、无空间关系（设置页、一级页面） | `M3Motion.fadeThrough()`（`AnimatedContent` 里）或 `NavTransitions.fadeThroughIn/Out()` |
| 层级推进 / 返回（列表 → 详情） | `NavTransitions.sharedAxisIn/Out/PopIn/PopOut(offsetPx)`，`offsetPx` 取 `sharedAxisOffsetPx()` |

### 11.5 减动效

系统「移除动画」（开发者选项 → 动画时长缩放 = 0）命中时，**所有** spec 退化为 `snap()`、
所有转场退化为 `None`：

- `AppTheme(reducedMotion = …)` 注入 `LocalReducedMotion`，`M3Motion` 内部自动判断；
- `NavTransitions` 的函数不是 `@Composable`（navigation 的转场 lambda 读不到 CompositionLocal），
  减动效由调用侧显式传 `reducedMotion`。


---

## 12. 主题集成

### 12.1 Material 3 主题

```dart
// kit/lib/src/theme/app_theme.dart
  const AppTheme({
    super.key,
    this.style = ThemeStyle.mono,
    this.darkTheme,
    this.tokens,
    this.reducedMotion = false,
    required this.child,
  });
```

---

## 附录：组件索引

所有视觉组件都封装在 `ui/components/` 下，页面不直接写原始 Material 组件。

| 组件 | 文件 |
|------|------|
| `KitFilterChip` | `kit/lib/src/ui/components/chips.dart` |
| `TagText` | `kit/lib/src/ui/components/tag_text.dart` |
| `IllustratedEmptyState` | `kit/lib/src/ui/components/empty_state.dart` |
| `AppSnackbar` | `kit/lib/src/ui/components/feedback.dart` |
| `StatItem` | `kit/lib/src/ui/components/stats.dart` |
| `PrimaryButton` / `SecondaryButton` / `FilledIconButton` / `TextActionButton` | `kit/lib/src/ui/components/buttons.dart` |
| `AppCard` / `SmallCard` | `kit/lib/src/ui/components/cards.dart` |
| `SimpleTextField` | `kit/lib/src/ui/components/text_fields.dart` |
| `ConfirmDialog` / `DeleteConfirmDialog` / `InputDialog` / `SelectDialog` | `kit/lib/src/ui/components/dialogs.dart` |
| `SelectDropdown` | `kit/lib/src/ui/components/dropdowns.dart` |
| `Header` | `kit/lib/src/ui/components/header.dart` |
| `LinearProgressBar` / `CircularProgressIndicatorWithText` | `kit/lib/src/ui/components/progress.dart` |
| 设计令牌（尺寸） | `kit/lib/src/theme/kit_shapes.dart` |
| 颜色 / 排版 / 主题 | `kit/lib/src/theme/palettes.dart`、`typography_tokens.dart`、`theme_tokens.dart`、`app_theme.dart` |

> `ScaleIconButton` / `RecordCard` / `FloatingToolbar` **未迁**，见上文对应小节与
> [`FLUTTER_MIGRATION.md`](../FLUTTER_MIGRATION.md)。
