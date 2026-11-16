#!/usr/bin/env bash
# 底座保护门禁 —— 改动碰到「底座路径」就失败。
#
# 底座 = 上游仓库里所有 app 共用的东西。fork 只在 apps/<name>/ 和
# scripts/checks/<自己的名字>.sh 里写代码；底座路径改了，pull 上游必冲突。
#
# 本仓库自己就是上游，所以默认走「工作区自查」模式：
#   bash scripts/ci.sh base-guard              # 看当前工作区有没有碰底座
#   bash scripts/check-base-unchanged.sh --base origin/main
#
# 退出码：0 = 没碰底座（或本次不检查）；1 = 碰了底座（打印清单）；2 = 用法错。
#
# 放行：BASE_GUARD_BYPASS=1（上游自己改底座时用）；fork 不该用这个。
set -o pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT" || exit 2

# ── 底座路径清单 ─────────────────────────────────────────────
# 以 / 结尾 = 整个子树。想加一条就往这儿加一行。
# 刻意没锁 apps/ 和 scripts/checks/ —— 那是 fork 自己的地界。
PROTECTED_PATHS=(
  "kit/"
  "kit-agent/"
  "kit-membership/"
  "scripts/ci.sh"
  "scripts/check-base-unchanged.sh"
  "scripts/verify_contract.py"
  "scripts/verify_layers.py"
  "scripts/verify_gateway.py"
  "backend/"
  "rules/"
  "skills/"
  "pubspec.yaml"
  ".gitmodules"
  ".github/"
  "README.md"
  "ARCHITECTURE.md"
  "LICENSE"
)

if [ "${BASE_GUARD_BYPASS:-}" = "1" ]; then
  echo "base-guard: BASE_GUARD_BYPASS=1，本次跳过"
  exit 0
fi

# 子模块路径（从 .gitmodules 读）—— 挪指针不算改底座。
SUBMODULE_PATHS=()
if [ -f .gitmodules ]; then
  while IFS= read -r sp; do
    [ -n "$sp" ] && SUBMODULE_PATHS+=("$sp")
  done <<< "$(git config --file .gitmodules --get-regexp '^submodule\..*\.path$' 2>/dev/null | awk '{print $2}')"
fi

# 没有 git 就没有"改动"这个概念 —— 明确跳过并说明，
# 不要假装检查过（静默打勾会让 CI 日志看起来是绿的，实际什么都没查）。
if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  echo "base-guard: 当前目录不是 git 仓库，跳过（git init + 首次提交后才会真正生效）"
  exit 0
fi

BASE=""
HEAD_REF="HEAD"
while [ $# -gt 0 ]; do
  case "$1" in
    --base) [ $# -ge 2 ] || { echo "--base 缺参数" >&2; exit 2; }; BASE="$2"; shift 2 ;;
    --head) [ $# -ge 2 ] || { echo "--head 缺参数" >&2; exit 2; }; HEAD_REF="$2"; shift 2 ;;
    -h|--help) sed -n '2,20p' "${BASH_SOURCE[0]}"; exit 0 ;;
    *) echo "用法: $0 [--base <git-ref>] [--head <git-ref>]" >&2; exit 2 ;;
  esac
done

# 没有任何 base 可用时：说明这本身就是上游仓库 / 没配远端。
# 这时候只检查「工作区未提交的改动」，并明确告诉用户检查范围 ——
# 静默打勾比没有门禁更糟（CI 日志里是绿的，实际什么都没查）。
if [ -z "$BASE" ]; then
  if git rev-parse --verify "upstream/main" >/dev/null 2>&1; then
    BASE="upstream/main"
  elif git rev-parse --verify "origin/main" >/dev/null 2>&1; then
    BASE="origin/main"
  fi
fi

is_protected() {
  local f="$1" p
  # 子模块路径豁免：挪子模块指针不算「改底座」（否则 Dependabot 每周的 PR 都会被拦死）。
  # 顺带解决「clone 没带 --recurse-submodules」时子模块目录显示为已删除的误报。
  if [ ${#SUBMODULE_PATHS[@]} -gt 0 ]; then
    for p in "${SUBMODULE_PATHS[@]}"; do
      case "$f" in
        "$p"|"$p"/*) return 1 ;;
      esac
    done
  fi
  for p in "${PROTECTED_PATHS[@]}"; do
    case "$f" in
      "$p"*) return 0 ;;
    esac
  done
  return 1
}

TOUCHED=()

if [ -n "$BASE" ]; then
  echo "base-guard: 与 $BASE 比较"
  while IFS= read -r f; do
    [ -n "$f" ] || continue
    is_protected "$f" && TOUCHED+=("$f")
  done < <(git diff --name-only "$BASE...$HEAD_REF" 2>/dev/null)
else
  echo "base-guard: 没有可用 base（本仓库即上游），只检查工作区未提交改动"
fi

# 无论有没有 base，都把工作区改动算进来
while IFS= read -r f; do
  [ -n "$f" ] || continue
  is_protected "$f" && TOUCHED+=("$f")
done < <(git status --porcelain --untracked-files=all 2>/dev/null | awk '{print $2}')

if [ ${#TOUCHED[@]} -eq 0 ]; then
  echo "base-guard: 没有改动碰到底座路径"
  exit 0
fi

# 去重后打印
printf 'base-guard: %d 个文件落在底座路径里：\n' "${#TOUCHED[@]}"
printf '%s\n' "${TOUCHED[@]}" | sort -u | sed 's/^/  - /' | head -40
echo ""
echo "  这是上游仓库在改底座，属正常 —— 但**下游 fork 不该有这些改动**。"
echo "  fork 侧请把改动挪进 apps/<name>/ 或 scripts/checks/。"
exit 1
