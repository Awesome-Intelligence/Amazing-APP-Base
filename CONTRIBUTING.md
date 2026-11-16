# 参与开发

## 两种用法

| 用法 | 怎么做 | 适合 |
|---|---|---|
| **fork 模式**（推荐） | fork 本仓库 → `git remote rename origin upstream` → 在 `apps/<name>/` 里长出自己的 app | 要持续跟进底座更新 |
| **拷贝模式** | `cp -r apps/demo apps/<name>`，改 `pubspec.yaml` 的 name 和 `lib/` 里的业务 | 只想拿一份能跑的骨架 |

## fork 模式的唯一规矩

**只新增、不改底座文件。**

底座路径（**唯一真相是 `scripts/check-base-unchanged.sh` 里的 `PROTECTED_PATHS`**）：

| 类别 | 路径 |
|---|---|
| 包 | `kit/`、`kit-agent/`、`kit-membership/`、`chat-demo/` |
| 工作区 | 根 `pubspec.yaml`、`pubspec.lock` |
| 规范 | `rules/`、`skills/`、`backend/`、`apps/demo/` |
| 门禁 | `.github/`、`.gitmodules`、`scripts/ci.sh`、`scripts/check-base-unchanged.sh`、`scripts/verify_*.py` |
| 法务 | `LICENSE`、`SECURITY.md` |

改了，pull 上游就冲突，更新链就断。底座能力不够，**回上游提 PR**，别在下游打补丁。

**这条规矩是机器强制的**，不是嘴上说说：

- 上游有 `.github/workflows/base-guard.yml` —— 用 `pull_request_target` 触发，workflow 永远取 **base 分支**的版本，fork 改不动它（改了就等于把检查删了）。PR 碰了上面任一路径 → 这道门禁直接红，PR 合并不进来。
- fork 本地自查：`bash scripts/ci.sh base-guard`（默认比对 `upstream` 远端的默认分支）。提交前跑一遍，改了底座当场就知道。**它不在 `ci.sh all` 里** —— 上游自己改底座是正常的，塞进 `all` 会天天误报。

例外只有两个：

1. **自己的发布 workflow** —— fork 把 `.github/workflows/release.yml` 拷成自己的 `release-<name>.yml`（新文件，随便改；`.github/` 里只有上表那几个是底座）。
2. **自己的门禁脚本** —— 放 `scripts/checks/<你的名字>.sh`，那块不锁。

## 子模块（`skills/` 的上游镜像）★

`skills/android-skills/` 和 `skills/logo-design-skill/` 是 **git submodule** ——
挂的是上游仓库，不是抄进本仓库的文件。这几件事 fork 之后必须知道：

1. **clone 要带 `--recurse-submodules`**

   ```bash
   git clone --recurse-submodules <本仓库地址> myapp
   ```

   忘了的话那两个目录是**空的**，而且 `git status` **不会报错** —— 一眼看不出来，
   skill 一个都没拉下来。补救：`git submodule update --init --recursive`。

2. **`git pull upstream main` 之后要再同步一次**

   ```bash
   git pull upstream main
   git submodule update --init --recursive
   ```

   `pull` 只更新指针，不拉内容。

3. **别在子模块目录里改文件**

   改了存不进本仓库，`git submodule update` 一跑就没了。要改上游的内容 → 去上游仓库提 PR。
   要在本仓库**固定**某个版本 → 挪指针（`git submodule update --remote <path>` + `git add` + commit）。

4. **挪指针不算改底座**

   Dependabot 每周自动开 PR 把子模块指针挪到上游最新 —— 这个 PR **不会**被 base-guard 拦
   （子模块路径在 `scripts/check-base-unchanged.sh` 里单独豁免了）。
   但 `.gitmodules` 本身（url / branch）是底座，改它会被拦。

5. **CI 的 checkout 已带 `submodules: recursive`**

   fork 自己加 job 的话记得也带上，否则 `bash scripts/ci.sh verify` 里的 `submodules` 门禁会红。

完整说明见 [`rules/SUBMODULES.md`](rules/SUBMODULES.md)。

## 加一个新 app

```bash
cp -r apps/demo apps/myapp
```

1. 改 `apps/myapp/pubspec.yaml` 的 `name`（顺便把 `test/` 里的 `package:demo/` 全替换成新名）。
2. 包清单**不用注册** —— pub workspace 的成员来自根 `pubspec.yaml`，要新增一个 app 就往根
   `workspace:` 里加一行；`scripts/ci.sh` 也会自动发现 `apps/*/` 下的包。
   > fork 下游通常**不改根 pubspec**（它是底座）：这时 `cp -r` 出来的 app 不在 workspace 里，
   > 进它的目录单独 `flutter pub get` 也能跑，只是少一次全仓解析。
3. 引用 `kit/`（要 agent 再加 `kit-agent/`），为每个功能写一个 `SkillDefinition`。
4. 给 skill 配黄金样例 —— **skill 化没有编译期保障，样例就是它的「类型检查」**：
   - `skill.violations()`：静态体检（工具名、描述、重名、limit）
   - `skill.runSamples(...)`：工具样例（工具名 + 入参 + 期望返回里的一段话）

   照抄 `apps/demo/test/` 里的写法。

## 加一个微信小程序端

小程序端是**另一个客户端**，不是 Flutter 的新 target —— 它没有 Dart VM，跑不了 agent。
它只保留主要逻辑和界面。

```bash
python scripts/new_miniprogram.py <name>   # 生成 apps/<name>/miniprogram/ + contract/actions.json
```

跨端的共享物不是代码，是**契约**：一份 `contract/actions.json`，各端各实现一遍动作表，
再各跑同一批黄金样例 —— 谁改了行为或文案，红的就是谁。

1. `miniprogram/logic/store.js`：业务逻辑（纯逻辑，不认识 `wx`）
2. `miniprogram/logic/actions.js`：动作表，动作名跟契约文件对上
3. `contract/actions.json`：样例
4. `bash scripts/ci.sh contract` —— 绿了再往下走
5. Flutter 端也有一份实现的话，加一条单测跑同一份契约（照抄 `apps/demo/test/todo_contract_test.dart`）

完整规矩见 `rules/MULTI-CLIENT.md`。

## 质量门禁

门禁逻辑**不在 workflow 里** —— 全在 `scripts/ci.sh`，CI 和本地跑的是同一份。
workflow 只负责「在什么环境跑哪道门禁」。

```bash
bash scripts/ci.sh all         # 提交前跑这个：bootstrap + analyze + verify + test + contract
bash scripts/ci.sh bootstrap   # flutter pub get（workspace 一次解析）
bash scripts/ci.sh analyze     # dart analyze / flutter analyze，零 issue 才算过
bash scripts/ci.sh test        # 单元测试 + widget 测试
bash scripts/ci.sh verify      # 契约对齐 / 分层 / 密钥 + scripts/checks/ 下的自定义门禁
bash scripts/ci.sh contract    # 小程序端契约样例（node --test，零依赖）
bash scripts/ci.sh build       # 构建 demo（Web + Android debug）
bash scripts/ci.sh base-guard  # 底座保护：改了底座路径就失败（fork 必跑）
```

**加一道自己的门禁**：往 `scripts/checks/` 放一个 `.sh`，退出码非 0 = 失败。
`ci.sh verify` 会自动跑它 —— 不用改 `ci.sh`，也不用改 `.github/workflows/`。
上游只往那个目录加**自己命名的文件** —— 你用别的文件名，`git pull upstream` 就不会冲掉你那份。

**改了 `kit/` 的公开 API**（公开类/函数的签名）—— Dart 没有二进制兼容门禁，
但下游是 fork 关系，**破坏性改名要写进 `CHANGELOG.md` 并给迁移说明**。
下游只在 `apps/` 下写代码，上游改底座时请保持 `kit_ui.dart` 的导出面稳定。

## 代码风格

- 文案走 **`KitStrings`**（`_ZhStrings` / `_EnStrings` 两处都加），别把中文硬编码进 widget；
  `kit_strings.dart` 里漏一边，英文界面就会冒中文
- 界面语言切换走 `AppSettings.language` + `KitAppShell`，别自己改 locale
- 纯 Dart 层（`kit.dart` / `kit-agent` / `kit-membership`）**禁止** `import 'package:flutter/...'`
- `kit.dart` 里**禁止** `dart:io`（Web 编不过）；文件实现放 `kit_io.dart`
- 业务动作放 data 层，**UI 的按钮和 agent 的工具调同一个函数**（见 `rules/CLAUDE.template.md`「逻辑 api 化」）
- 主题颜色/圆角/字号从 `KitTheme.of(context)` 取，别写死
- 注释写「为什么」，不写「做了什么」

规则全文见 `rules/CLAUDE.template.md`。
