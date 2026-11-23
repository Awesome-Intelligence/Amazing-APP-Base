# Google 风格设计规范

本项目 UI 采用 Google 品牌设计风格（参考 Google Photos、Gmail 等 Google 原生 App）。

---

## 排版 (Typography)

使用 M3 Type Scale，具体值见 `kit/lib/src/theme/typography_tokens.dart`：

| 角色 | 字号 | 字重 | 用途 |
|------|------|------|------|
| displayLarge | 57sp | Normal | 极大数字/英雄标题 |
| displayMedium | 45sp | Normal | 大标题 |
| displaySmall | 36sp | Normal | 次大标题 |
| headlineLarge | 32sp | **Normal** | 页面标题 |
| headlineMedium | 28sp | **Normal** | 区块标题 |
| headlineSmall | 24sp | **Normal** | 卡片标题 |
| titleLarge | 22sp | **Normal** | TopAppBar 标题 |
| titleMedium | 16sp | Medium | Tab 标签 |
| titleSmall | 14sp | Medium | 小标题 |
| bodyLarge | 16sp | Normal | 默认正文 |
| bodyMedium | 14sp | Normal | 次要正文 |
| bodySmall | 12sp | Normal | 辅助文字 |
| labelLarge | 14sp | Medium | 按钮文字 |
| labelMedium | 12sp | Medium | Badge |
| labelSmall | 11sp | Medium | 时间戳 |

**字重要点：** M3 中所有 Headline 和 Title Large 使用 **Normal 字重**（不要擅自加粗成 SemiBold）。

---

## 颜色 (Color)

### 语义色（与 Mono 主题协调的暖中性色阶）
| 用途 | 浅色模式 | 深色模式 |
|------|---------|---------|
| Primary | #1D1915 | #E6E2DE |
| Background | #FDFAF6 | **#15110D** |
| Surface | #FDFAF6 | **#15110D** |
| SurfaceVariant | #E9E5E1 | #2F2A25 |
| Error | #BA1A1A | #FFB4AB |
| Success | #2D6A4F | #6BCB96 |
| SuccessContainer | #D8F3E4 | #1B4D35 |
| Warning | #B75D00 | #FFB95C |
| WarningContainer | #FFECCF | #6B3900 |
| 收藏星标 Star | #C77800 | #FFD54F |

### 颜色使用规则
| 场景 | 浅色 | 深色 |
|------|------|------|
| 背景 | Surface | Surface（不用纯黑）|
| 正文 | OnSurface (#1D1915) | OnSurface (#E7E3DF) |
| 次要文字 | OnSurfaceVariant (#4C463F) | OnSurfaceVariant (#C8C3BE) |
| 边框 | Outline (#7C756E) | Outline (#918B84) |
| 容器背景 | primaryContainer | primaryContainer |
| 错误提示 | errorContainer | errorContainer |

### 禁止事项
- ❌ 禁止使用纯黑 `#000000` 作为背景
- ❌ 禁止使用纯白 `#FFFFFF` 作为深色模式文字
- ❌ 禁止在业务代码中硬编码颜色值

---

## 间距系统 (Spacing)

### 基础间距值
```
4dp   — 最小间距（仅用于图标与文字间距）
8dp   — 紧凑间距（Chips、Tags 内部）
12dp  — 标准间距（组件内部）
16dp  — 常用间距（卡片内边距、列表项）
24dp  — 宽松间距（区块间、大组件内）
32dp  — 段落间距（空状态、副标题水平 padding）
48dp  — 大间距（页面主要区块间）
```

### 间距规则
- 所有间距必须是 **4dp 的倍数**
- 水平内边距最小 **16dp**
- 列表项垂直间距 **8dp**
- 卡片间间距 **12-16dp**

---

## Elevation 与 Tint

### Elevation 级别（扁平化优先）
| Level | 用途 | Google 风格 |
|-------|------|-------------|
| 0 | 平面组件 | ✅ 优先使用 |
| 1 | 卡片、导航栏 | ✅ 可接受 |
| 2 | 悬浮按钮、Snackbar | ✅ 可接受 |
| 3 | Dialog | ❌ Google 风格用 0dp |

### Surface Tint 使用
- 使用 `MaterialTheme.colorScheme.primary.copy(alpha = 0.05f)` 作为轻量 elevation
- 深色模式下 tint 更重要（阴影不可见）
- Google 风格偏好使用背景色区分层次，而非阴影

---

## 圆角系统 (Shape)

### 圆角分级
| 级别 | 圆角 | 适用组件 |
|------|------|---------|
| None | 0dp | — |
| Extra Small | 4dp | Text Field, Menu |
| Small | 8dp | Chips, Tags, Badges |
| Medium | 12dp | Buttons, Cards, Input |
| Large | 16dp | Dialogs, FAB, BottomSheet |
| Extra Large | 28dp | — |
| Full | 50% | CircleButton |

### 圆角使用规则
- 同一组件的子元素圆角 ≤ 父元素圆角
- 图标按钮用 Full（圆形）
- 列表项不使用圆角（除非可点击）

---

## 组件规范

### 按钮 (Buttons)

| 组件 | 高度 | 圆角 | 说明 |
|------|------|------|------|
| PrimaryButton | 48dp | 12dp | 实心按钮，primary 背景 |
| SecondaryButton | 48dp | 12dp | Outlined 按钮，primary 边框 |
| ScaleIconButton | 40dp | Full (50%) | 圆形图标按钮，按下用 M3 state layer（onSurface 10%），不缩放 |
| SmallScaleIconButton | 32dp | Full (50%) | 小尺寸工具栏按钮，按下用 M3 state layer |
| CircleIconButton | 40dp | Full (50%) | 圆形图标按钮 |

### 卡片 (Cards)

| 组件 | 圆角 | 内边距 | elevation | 说明 |
|------|------|--------|-----------|------|
| AppCard | 12dp | 16dp | 1dp | 标准卡片 |
| SmallCard | 12dp | 12dp | 1dp | 小尺寸卡片 |
| RecordCard | 12dp | 16dp | 0dp | 使用 surfaceVariant 背景 |

### 标签/筛选 (Chips)

| 组件 | 圆角 | 说明 |
|------|------|------|
| FilterChip | 8dp | M3 标准实现 |
| Tag | 8dp | 自定义彩色标签 |
| SelectableTag | 8dp | 可选中的标签 |

### 弹窗 (Dialogs)

| 属性 | 值 |
|------|-----|
| 圆角 | 16dp |
| elevation | 0dp |
| icon 尺寸 | 64dp |
| 内边距 | 24dp |

**通用结构：** icon（可选）→ 标题 → 正文（可选）→ 按钮行

### 搜索框 (SearchBar)

| 属性 | 值 |
|------|-----|
| 高度 | 56dp |
| 圆角 | 28dp |
| 风格 | Filled（无边框）|
| 背景 | surfaceVariant 80% |

### 底部导航 (BottomNavigation)

| 属性 | 值 |
|------|-----|
| 高度 | 64dp |
| 指示器尺寸 | 48×32dp |
| 指示器圆角 | 24dp |
| elevation | 0dp |

### TopAppBar（待创建）

| 属性 | 值 |
|------|-----|
| 高度 | 64dp |
| 标题 | titleLarge |
|  elevation | 0dp |

### FAB（待创建）

| 属性 | M3 | Google 风格 |
|------|-----|-------------|
| 尺寸 | 56dp | 56dp |
| 圆角 | Full (50%) | Full (50%) |
| elevation | 6dp | 3dp |

### 下拉菜单 (Dropdowns)

| 组件 | 说明 |
|------|------|
| 触发器 | OutlinedTextField，12dp 圆角，56dp 高 |
| 菜单 | M3 `DropdownMenu`（底座封装成 `SelectDropdown`） |
| 选项 | 选中项左侧一个 `Icons.check` + 标签，垂直排列 |
| 选中指示器 | 不用 `DropdownMenuItem.selectedLeadingIcon` —— 底座在 item 的 child 里手画勾 |

### 菜单 (Menu)

| 属性 | 说明 |
|------|------|
| 触发按钮 | 40×40dp，20dp 圆角 |
| 菜单 | M3 `MenuAnchor`（底座封装成 `SimpleMenuButton`，子菜单是真嵌套浮层） |

### 空状态 (EmptyState)

| 属性 | 值 |
|------|-----|
| 图标容器 | 100dp 圆形，tintColor 8-15% alpha |
| 图标尺寸 | 40dp |
| 标题 | headlineSmall |
| 副标题 | bodyMedium，onSurfaceVariant |

### 反馈 (Feedback)

| 组件 | 圆角 | 说明 |
|------|------|------|
| AppNotice | shapes.small（M3 8dp） | 提示条；内联用级别容器色，浮动用 inverseSurface |
| LoadingIndicator | — | 48dp，4dp 边框 |
| LoadingOverlay | — | scrim 30% 遮罩 |

### 统计 (Stats)

| 属性 | 值 |
|------|-----|
| 卡片圆角 | 12dp |
| 背景 | surfaceVariant |
| elevation | 0dp |

### 悬浮工具栏 (FloatingToolbar)

| 属性 | 值 |
|------|-----|
| 圆角 | 12dp |
| elevation | 8dp |
| 图片缩略图 | 60dp，8dp 圆角 |
| 删除按钮 | error 色 + Close icon |

---

## 动效 (Animations)

所有动效一律走 `kit/lib/src/theme/motion.dart` 的 `M3Motion` 令牌（时长 / 曲线全在里面），不要在页面里手写 `Duration` / `Curve` 字面量。下表只列选型：

| 场景 | 用什么 |
|------|--------|
| 颜色 / 透明度 | `M3Motion.short2`（100ms）+ `M3Motion.emphasized` |
| 展开 / 收起 | `CollapsibleSection`（高度 `M3Motion.medium1`，淡入淡出 `M3Motion.short3`） |
| 内容整体替换（无关联） | `AnimatedContentSwitch`（Fade Through：90ms 淡出 + 210ms 淡入，初始缩放 0.92） |
| **整页替换**（设置页、一级页面） | `AnimatedContentSwitch` |
| **层级推进 / 返回**（列表 → 详情） | app 自己写 `PageRouteBuilder`，位移量取 `M3Motion.medium2`（不是整屏） |
| 加载脉动 | 骨架屏（`SkeletonRect` / `SkeletonTextLine` / …），呼吸脉动 1.1s 往复 |
| 进场 / 退场曲线 | 进场 `M3Motion.emphasizedDecelerate`，退场 `M3Motion.emphasizedAccelerate` |

### Motion 原则
- 进入：decelerate；退出：accelerate（M3 emphasized 系）
- 退场必须比位移快（`M3Motion.exitFade` = 90ms），注意力才留在新页面
- 面板类必须有退场动画（`CollapsibleSection` 收起时先淡出再收高度）
- 遵循系统「减少动效」设置：`KitTheme.reducedMotionOf(context)` 为真时，
  `motionDuration(context, d)` 返回 `Duration.zero`，`CollapsibleSection` /
  `AnimatedContentSwitch` 内部直接跳到终态 —— 自写动画要自己判断，别硬编码时长。

---

## 触控目标

| 场景 | 最小尺寸 |
|------|---------|
| 普通触控目标 | 48×48dp |
| 图标按钮 | 40×40dp 或 48×48dp |
| FAB | 56×56dp |
| 列表项 | 最小 48dp 高度 |

---

## 无障碍 (Accessibility)

- 所有 Icon 必须有 `contentDescription`
- 对比度 ≥ 4.5:1（正常文字）
- 对比度 ≥ 3:1（大文字）
- 支持 TalkBack
- 支持动态字体大小

---

## 命名规范

### 组件命名
- 基础组件：`App` 前缀 + 描述性名称（`AppCard`、`AppButton`）
- 复合组件：`功能` + `类型`（`RecordCard`、`StatItem`）
- 数据类：`功能` + `Model`/`Data`（`RecordModel`、`StatItemData`）

### 字符串资源命名
- 页面级：`{page}_{component}_{state}`（如 `home_empty_contacts`）
- 通用：`{action}` 或 `{noun}`（如 `confirm`、`cancel`、`search`）
- 禁止：硬编码中文字符串

---

## 常用资源

### 图标库
- `Icons.Default` — Material Icons
- `Icons.Outlined` — Material Icons Outlined 版本
- 优先使用 Outlined 风格图标

### 圆角值
```dart
8   // Chips, Tags
12  // Buttons, Cards, Input
16  // Dialogs, FAB
24  // BottomNavigation 指示器
28  // SearchBar
```

> Flutter 里圆角是纯逻辑像素（`BorderRadius.circular(12)`），不用 dp。
> 组件圆角统一从 `KitTheme.of(context)` 的 `tokens.shapes` 取，别手写数字。

---

## 输入框 (TextField / Input)

### OutlinedTextField

| 属性 | 值 |
|------|-----|
| 高度 | 56dp |
| 圆角 | 12dp |
| 边框颜色（默认）| outline |
| 边框颜色（聚焦）| primary |
| 标签 | labelMedium，onSurfaceVariant |
| 输入文字 | bodyLarge |

### FilledTextField

| 属性 | 值 |
|------|-----|
| 高度 | 56dp |
| 圆角 | 4dp（顶部）/ 12dp（底部）|
| 背景 | surfaceVariant |
| 标签 | labelMedium |

### 状态

| 状态 | 边框/背景 | 文字颜色 |
|------|-----------|---------|
| 默认 | outline / surfaceVariant | onSurface |
| 聚焦 | primary | onSurface |
| 错误 | error | onSurface |
| 禁用 | outline（40% alpha）| onSurface（38% alpha）|

### 错误状态

| 场景 | 显示方式 |
|------|---------|
| 单行输入 | 边框变为 error 色 + 下方 error text |
| 多行输入 | 边框变为 error 色 + 下方 error text |
| 实时校验 | 输入失焦后显示错误 |

---

## 加载状态 (Loading States)

### Button Loading

| 场景 | 表现 |
|------|------|
| 加载中 | 显示 CircularProgressIndicator（16dp）替代文字，按钮禁用 |
| 加载完成 | 恢复正常按钮状态 |
| 失败 | 恢复按钮，允许重新提交 |

底座的 `PrimaryButton` **没有** loading 参数 —— 要这个态就在 app 层包一层：

```dart
SizedBox(
  height: 48,
  child: FilledButton(
    onPressed: isLoading ? null : onPressed,
    style: FilledButton.styleFrom(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    ),
    child: isLoading
        ? const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
        : const Text('提交'),
  ),
)
```

### Skeleton Loading（骨架屏）

| 场景 | 圆角 | 背景动画 |
|------|------|---------|
| 列表项骨架 | 8dp | shimmer 动画 |
| 卡片骨架 | 12dp | shimmer 动画 |
| 头像骨架 | 圆形 | shimmer 动画 |

### Pull-to-Refresh

- 用 Flutter 的 `RefreshIndicator`
- 指示器：`CircularProgressIndicator` 或自定义动画
- 触发阈值：80dp 下拉

---

## 错误处理 (Error States)

### Inline Error（内联错误）

| 场景 | 显示位置 | 文字样式 |
|------|---------|---------|
| TextField 错误 | 输入框下方 | bodySmall, error 色 |
| 表单错误 | 对应字段旁 | bodySmall, error 色 |
| 列表项错误 | 行内右侧 | error 色图标 + tooltip |

### Error 与 Loading 互斥

```
Loading 状态 → 显示 loading，禁用交互
Error 状态   → 显示错误文案，无 loading
Success 状态 → 显示成功反馈（可选）
```

### 错误反馈级别

| 级别 | 场景 | 组件 |
|------|------|------|
| Toast/Snackbar | 操作失败（可忽略）| AppNotice(floating) |
| Inline | 表单验证失败 | 字段下方错误文字 |
| Dialog | 严重错误需确认 | ConfirmDialog |
| Full Screen | 网络错误等 | EmptyState + 重试按钮 |

---

## 深色模式 SurfaceTint 规则

### Tint 透明度

| 浅色模式 | 深色模式 | 用途 |
|---------|---------|------|
| primary 5% | primary 10% | 最小层次（hover/press）|
| primary 8% | primary 15% | 卡片背景 |
| primary 12% | primary 20% | 选中态背景 |

### 深色模式特殊规则

- Surface 背景使用 `#15110D`（Mono surfaceDark），不用纯黑
- onSurface 使用 `#E7E3DF`（Mono onSurfaceDark），不用纯白
- elevation 主要靠 tint 而非阴影
- 阴影在深色模式不可见，避免依赖阴影区分层次

### 深色模式颜色映射

| 浅色 | 深色 |
|------|------|
| Surface #FDFAF6 | Surface #15110D |
| OnSurface #1D1915 | OnSurface #E7E3DF |
| SurfaceVariant #E9E5E1 | SurfaceVariant #2F2A25 |
| Outline #7C756E | Outline #918B84 |

---

## 图标使用规范

### Outlined vs Filled

| 场景 | 推荐类型 |
|------|---------|
| 导航选中态 | Outlined → Filled 切换 |
| 操作按钮 | Outlined |
| 状态指示 | Filled |
| Logo/品牌图标 | Filled |

### 图标尺寸

| 场景 | 尺寸 |
|------|------|
| 内联图标（文字旁）| 16-20dp |
| 独立操作按钮 | 24dp |
| 大图标（空状态）| 40dp |
| 导航栏图标 | 24dp |

---

## 分隔线 (Divider)

| 属性 | 值 |
|------|-----|
| 厚度 | 1dp |
| 颜色 | outlineVariant |
| 间距 | 水平 0dp，垂直按场景 |

---

## 提示条 (AppNotice)

项目里**只有一种提示条**：`AppNotice`。级别（info / success / warning / error）
由 `NoticeSeverity` 表达，图标 + 容器色一起变。

| 形态 | 背景 | 文字/图标 | 说明 |
|------|------|------|------|
| 内联（默认） | 级别容器色 | 级别 on*Container 色 | 直接插在页面里 |
| 浮动（floating） | inverseSurface | onInverseSurface | M3 SnackBar 配色，级别只靠图标区分 |

| 级别 | 容器色 | 前景色 | 图标 |
|------|------|------|------|
| info | secondaryContainer | onSecondaryContainer | info |
| success | successContainer | onSuccessContainer | check_circle |
| warning | warningContainer | onWarningContainer | warning_amber_rounded |
| error | errorContainer | onErrorContainer | error |

圆角一律 `shapes.small`（M3 8dp），别写死 28dp —— 圆角跟着主题走
（Swiss/E-Ink 全直角、Notion 4dp、macOS 6dp）。

---

## 待创建组件

以下组件在规范中已定义规格，但尚未实现：

| 组件 | 优先级 | 说明 |
|------|--------|------|
| TopAppBar | 高 | 页面顶部导航栏 |
| FAB | 高 | 浮动操作按钮 |
| ListItem | 中 | 标准列表项 |
| Avatar | 中 | 头像组件 |
| Badge | 低 | 徽章组件 |
| Tab | 低 | 标签页 |
| Tooltip | 低 | 工具提示 |
| BottomSheet | 中 | 底部抽屉 |
