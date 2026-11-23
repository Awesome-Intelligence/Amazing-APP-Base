# Skills

## 组成

| 目录 | 来源 | 形式 |
|---|---|---|
| `android-skills/` | [android/skills](https://github.com/android/skills)（Google 官方） | **submodule** |
| `logo-design-skill/` | [kaankiziltug/logo-design-skill](https://github.com/kaankiziltug/logo-design-skill)（MIT） | **submodule** |

两个都是**上游仓库的镜像**，用 git submodule 挂进来 —— 上游更新了由 Dependabot 自动开 PR，
本仓库也不会被 1400+ 个 SVG 参考库撑大。

> ⚠️ **clone 本仓库必须带 `--recurse-submodules`**，否则这两个目录是空的：
> ```bash
> git clone --recurse-submodules <本仓库地址> myapp
> ```
> 忘了就补一句 `git submodule update --init --recursive`。
>
> fork 模式的完整注意事项（pull 之后要再同步、别在子模块里改文件、怎么固定版本…）见
> **[`rules/SUBMODULES.md`](../rules/SUBMODULES.md)**。

要装进自己的项目，直接 `cp -r` 对应目录到 `.claude/skills/`（或 `.agents/skills/`）。

---

## android-skills（Google 官方）

`android-skills/` 是 Google 官方 [android/skills](https://github.com/android/skills) 的**完整镜像**
（当前 v1.0.21，36 个 skill / 451 个文件，含 LICENSE.txt）。每次新增 skill 不必再 clone，直接查本地这份。

| 分类 | 目录 | 主要内容 |
|---|---|---|
| 构建 | `build-system/agp/agp-9-upgrade` | AGP 9 升级（KSP/kapt、paparazzi、built-in Kotlin） |
| 构建 | `devtools/android-cli` | `android` CLI 的交互与 journey |
| Compose | `jetpack-compose/adaptive` | 自适应布局、`NavigationSuiteScaffold`、list-detail |
| Compose | `jetpack-compose/migration/migrate-xml-views-to-jetpack-compose` | XML 视图迁移到 Compose |
| Compose | `jetpack-compose/ink/ink-app-builder` `jetpack-compose/ink/ink-custom-brush-builder` | Ink 手写笔绘制 |
| Compose | `jetpack-compose/jetpack-compose-performance` | Compose 性能排查 |
| 导航 | `navigation/navigation-3` | Nav3：类型安全路由、**`recipes/animations.md`（转场钩子）**、scenes |
| 导航 | `navigation/navigation-event` | 导航事件 / 返回处理 |
| 系统 | `system/edge-to-edge` | 边到边、M3 组件安全区 |
| 系统 | `system/glance-canonical-layouts` `system/glance-appwidget-updates-and-memory` | Glance 桌面小组件 |
| 相机 | `camera/camerax` | CameraX 迁移与进阶（foldable / XR / wear） |
| 车机 | `cars/android-for-cars-parked-apps` | 停车状态下的应用可见性 |
| 设备 AI | `device-ai/appfunctions` `device-ai/ml-kit-genai-prompt-api` `device-ai/mlkit-agent-api` | 系统级 function calling、ML Kit GenAI / Agent API |
| 设备 AI | `device-ai/litert/litert-lm` `device-ai/litert/litert-runtime` | LiteRT 端上推理 |
| 身份 | `identity/restore-credentials` `identity/verified-email` | Passkey / Digital Credentials |
| 媒体 | `media/media3-cast-integration` | Media3 Cast |
| 性能 | `performance/r8-analyzer` `performance/anr-audit-and-fix` `profilers/android-profiler` | R8 规则分析、ANR 审计、Perfetto 抓取与解读 |
| 发布 | `play/*` | 政策洞察、Engage SDK、Billing 升级 |
| 测试 | `testing/testing-setup` | 测试脚手架、截图测试 |
| 安全 | `security/android-intent-security` `security/android-permissions-security` | Intent / 权限安全 |
| 大屏 | `tv/leanback-to-compose-tv-migration` | TV Compose（`androidx.tv.material3`） |
| 手表 | `wear/wear-compose-m3` `wear/wear-widgets` | **Wear OS M3**：组件样例、`TransformingLazyColumn`；手表小组件 |
| XR | `xr/display-glasses-with-jetpack-compose-glimmer` `xr/projected-hardware` | Glimmer（眼镜）、投屏硬件 |

> ⚠️ 上游 **2026-10-26 删掉了 `jetpack-compose/theming/styles`**（Styles API 那个 skill）。
> 同步到 v1.0.21 后本地就没有这份了 —— 仓库里提到它的说法已一并更正。
> 主题/动效以本仓库自己的 `rules/GOOGLE_STYLE.md` 和 `rules/COMPONENT_SPEC.md` 为准。

## logo-design-skill

从 brief 到成品 SVG 的**专业 logo / 品牌标识设计**流程。含 mark 类型选择（字标 / 字母组合 /
图形 / 抽象 / 徽章 / 吉祥物 / 组合）、SVG 几何构建与光学修正、配色与字体、
16px / 单色 / 反白 / 货架对比测试、客户提案、交付变体与品牌规范模板，
以及 1,400+ 真实 SVG 参考库（按类型 / 技法 / 行业分类，仅作结构研究，**勿抄袭**）与审计 / 导出脚本。

上游是个多 skill 仓库，**真正的 skill 在 `logo-design-skill/skills/logo-design/` 下**
（仓库根还有 `docs/` `evals/` `tests/` `tools/`）。拷到别的项目时
映射成 `.claude/skills/logo-design-skill/`。

`.workbuddy/skills/logo-design-skill/` 只是给本机 WorkBuddy 直接调用的镜像，
已被 `.gitignore` 排除；同步上游后重新拷一份即可。

---

## 关于「M3 规范要求」

Google 官方这套 skill **没有**一份「M3 动效/令牌要求清单」：

- 唯一沾边动效的是 `navigation/navigation-3/recipes/animations.md`，只讲 `NavDisplay` 的
  `transitionSpec` / `popTransitionSpec` / `predictivePopTransitionSpec` 三个钩子，示例全是
  `tween(1000)` 占位值，没有 M3 时长/缓动；
- 原来讲 Styles API 状态动画的 `jetpack-compose/theming/styles` 已被上游删除（2026-10-26）。

M3 动效要求的实际出处在本仓库自己这边：

- `kit/lib/src/theme/motion.dart` 的 `M3Motion` —— Duration / 曲线令牌，
  出处是 **M3 官方站** `m3.material.io/styles/motion/easing-and-duration/spring-specs`
- `rules/GOOGLE_STYLE.md` §动效 —— 落到代码的选型表
- `rules/COMPONENT_SPEC.md` §11 —— 上面那套令牌的转录表（Duration / 曲线 / 组件级转场 / 减动效）

> 组件尺寸不跟 M3 官方走 —— 本项目用的是 **Google 原生 App 风格**（按钮 48dp/12dp 等），
> 见 `rules/GOOGLE_STYLE.md` §组件规范。动效跟 M3 官方，尺寸跟 Google 原生 App，两套口径别混。

---

## 使用约定

写 Android 相关代码前，先看 skill 里有没有现成的：

- AGP 升级 → `android-skills/build-system/agp/agp-9-upgrade`
- Compose 自适应 → `android-skills/jetpack-compose/adaptive`
- XML 迁移 → `android-skills/jetpack-compose/migration/migrate-xml-views-to-jetpack-compose`
- Compose 性能 → `android-skills/jetpack-compose/jetpack-compose-performance`
- 导航 / 转场 → `android-skills/navigation/navigation-3`
- 边到边 → `android-skills/system/edge-to-edge`
- 设计 logo / 品牌标识（brief→SVG→规范） → `logo-design-skill`（需具备看图能力的模型，工作流会把草稿渲染成 PNG 自检）

没有现成 skill 再自己实现 —— 别重复造轮子。

M3 相关的问题别翻 skill，直接查 `rules/GOOGLE_STYLE.md` / `rules/COMPONENT_SPEC.md` / `motion.dart`。

---

## 更新

| 想更新 | 怎么做 |
|---|---|
| `android-skills` / `logo-design-skill` | **不用手动做** —— Dependabot 每周自动开 PR 挪指针，你 review 后合并即可 |
| 手动拉上游最新 | `git submodule update --remote skills/android-skills && git add skills/android-skills && git commit` |

**别在子模块目录里改文件** —— 改动存不下来，`git submodule update` 一跑就没了。
要改上游的内容，去上游仓库提 PR。详见 [`rules/SUBMODULES.md`](../rules/SUBMODULES.md)。
