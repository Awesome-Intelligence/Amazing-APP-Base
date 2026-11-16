# 子模块（skills 上游镜像）

`skills/` 下的第三方 skill 是**上游仓库的镜像**。它们用 git submodule 挂进来，
不是把文件抄进本仓库 —— 这样上游更新了能自动跟上，本仓库也不会被 14MB 的 SVG 参考库撑大。

| 目录 | 上游 | 形式 |
|---|---|---|
| `skills/android-skills/` | [android/skills](https://github.com/android/skills) | submodule |
| `skills/logo-design-skill/` | [kaankiziltug/logo-design-skill](https://github.com/kaankiziltug/logo-design-skill) | submodule |

---

## 一、为什么是 submodule

镜像上游有两条路：把文件抄进来（vendored），或者挂成 submodule。

| | 抄进来（vendored） | submodule |
|---|---|---|
| 上游更新了怎么跟上 | 手动 clone 一遍覆盖，容易忘 | Dependabot 自动开 PR |
| 本仓库体积 | +14MB / +1500 文件（logo 参考库） | 一个指针（60 字节） |
| 别人 clone 下来 | 直接就有文件 | **忘了 `--recurse-submodules` 就是空的** |
| 想改上游的东西 | 直接改，改乱了分不清谁改的 | 改不了，得去上游仓库改 |

选 submodule 的代价就是第三条：**空目录**。所以本仓库配了机器门禁兜着
（见「五、空目录是静默故障」）。

---

## 二、fork 模式下的注意事项 ★

本仓库的下游用法是 **fork + 在 `apps/` 里长自己的 app**。子模块有几件事必须知道：

### 1. clone 必须带 `--recurse-submodules`

```bash
git clone --recurse-submodules <本仓库地址> myapp
```

忘了的话 `skills/android-skills/` 和 `skills/logo-design-skill/` 会是**空目录**，
且 `git status` 不会报错 —— 一眼看不出来。补救：

```bash
git submodule update --init --recursive
```

### 2. `git pull upstream main` 之后要再跑一次

拉上游只更新**指针**，不会自动把子模块内容拉下来：

```bash
git pull upstream main
git submodule update --init --recursive
```

漏了第二步 → 指针指向新 commit，本地还是旧内容，`git status` 显示子模块 dirty。

### 3. 别在子模块目录里改文件

子模块里的文件属于**上游仓库**，不是你���的。直接改：

- 改动留在子模块自己的 git 里，**本仓库一个字节都存不下来**；
- 下次 `git submodule update` 直接被覆盖掉，改动无声消失；
- `git status` 只显示 `modified: skills/android-skills (modified content)`，看不出你改了什么。

要改上游的内容 → 去上游仓库提 PR。要在**本仓库**基于上游做定制 → 见第 4 条。

### 4. 想固定在某个版本 / 用自己的 fork

```bash
# 固定到某个 commit
cd skills/android-skills && git checkout <commit> && cd -
git add skills/android-skills && git commit -m "chore: 固定 android/skills 到 <commit>"

# 手动拉到上游最新
git submodule update --remote skills/android-skills
git add skills/android-skills && git commit -m "chore: 同步 android/skills"

# 改用自己维护的 fork（改的是 .gitmodules —— 底座路径，base-guard 会拦）
git submodule set-url skills/android-skills https://github.com/<你的账号>/skills.git
```

`git submodule update --remote` 走的是 `.gitmodules` 里 `branch =` 指定��分支；
没写 `branch` 就跟上游默认分支。

### 5. 上游的 PR 由 Dependabot 开

`.github/dependabot.yml` 里配了 `package-ecosystem: "submodules"`，
上游一有新的 commit，Dependabot 就开一个 PR 把指针挪过去。

**这个 PR 不会碰底座路径** —— `scripts/check-base-unchanged.sh` 里把子模块路径单独豁免了
（指针是上游的事，不是你的改动）。你 review 一下 diff（看的是「指针从 A 挪到 B」，
不是几百个文件的 diff），满意就合并。

---

## 三、常见命令

```bash
git submodule status                          # 看各子模块当前 commit（'-' = 没初始化，'+' = 和指针不一致）
git submodule update --init --recursive       # 初始化 / 对齐指针
git submodule update --remote skills/android-skills   # 拉上游最新
git submodule foreach 'git pull'              # 每个子模块里各自 pull
git submodule sync                            # .gitmodules 改了之后同步到 .git/config
```

---

## 四、子模块里的 skill 装出去长什么样

把 skills 装进目标项目时，**子模块里的 skill 目录位置由上游决定**，
不能靠 `cp` 的目录结构碰运气，要按下表显式映射：

| 源 | 装到目标项目的哪 |
|---|---|
| `skills/android-skills/` | `.claude/skills/android-skills/`（整包，skill 在 `<分类>/<名字>/SKILL.md`） |
| `skills/android-skills/` | `.agents/skills/`（整包，另一套 agent 的目录约定） |
| `skills/logo-design-skill/skills/logo-design/` | `.claude/skills/logo-design-skill/` |

注意 `logo-design-skill` 那行：上游是个多 skill 仓库，真正的 skill 在
`skills/logo-design/` 下（仓库根还有 `docs/` `evals/` `tests/` `tools/`），不是仓库根。
**改了上游布局，这里也要跟着改**，否则装出去的就是空的。

---

## 五、空目录是静默故障

子模块没初始化时目录是空的，而 `cp -r` 空目录**不报错** ——
装出来的项目 skill 全没了，CI 也不会红。

所以 `scripts/ci.sh verify` 会跑 `scripts/checks/submodules.sh`（一道 `submodules` 门禁），
发现子模块目录是空的就直接失败，并提示跑 `git submodule update --init --recursive`。
CI 里对应的是 `verify` job 的 checkout 带 `submodules: true`。
