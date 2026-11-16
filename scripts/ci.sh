#!/usr/bin/env bash
# 门禁执行层 —— 每个 job 和本地都调这一份脚本。
#
# 为什么门禁逻辑不写在 .github/workflows/ 里：
#   workflows/ 是「底座不可改路径」——fork 想加一道自己的门禁，改它就等于跟上游冲突。
#   逻辑放 scripts/（fork 可以自由改），YAML 只负责「在什么环境跑哪个子命令」。
#
# 用法：
#   bash scripts/ci.sh bootstrap    # pub get（已有 package_config 的包会跳过）
#   bash scripts/ci.sh analyze      # 静态分析（dart analyze / flutter analyze）
#   bash scripts/ci.sh test         # 单元测试 + widget 测试
#   bash scripts/ci.sh contract     # 跨端契约：小程序端动作表跑 contract/actions.json
#   bash scripts/ci.sh verify       # 自带脚本：契约动作名对齐 / 底座不许反依赖 / 网关协议对齐 / 无硬编码密钥
#   bash scripts/ci.sh backend      # agent 网关：tsc --noEmit + 冒烟检查（不花钱）
#   bash scripts/ci.sh build        # 构建 demo（Web + Android）
#   bash scripts/ci.sh base-guard   # 底座保护：改 kit/ 等底座路径就失败（fork 必跑）
#   bash scripts/ci.sh all          # 除 build 外全跑（本地提交前跑这个）
set -o pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT" || exit 1

FAILED=()
ok()   { printf '  \033[32m✓\033[0m %s\n' "$1"; }
bad()  { printf '  \033[31m✗\033[0m %s\n' "$1"; FAILED+=("$1"); }
step() { printf '\n\033[1m==> %s\033[0m\n' "$1"; }

# ── 环境探测 ────────────────────────────────────────────────────
# flutter 常常不在 PATH 里（本机在 D:\flutter）。按优先级找：
#   1. $FLUTTER_BIN        显式指定，CI 里用
#   2. PATH 里的 flutter
#   3. 本机默认安装路径
find_flutter() {
  if [ -n "${FLUTTER_BIN:-}" ] && [ -x "${FLUTTER_BIN}" ]; then
    echo "$FLUTTER_BIN"; return 0
  fi
  if command -v flutter >/dev/null 2>&1; then
    echo "flutter"; return 0
  fi
  for p in /d/flutter/bin/flutter /c/flutter/bin/flutter "$HOME/flutter/bin/flutter"; do
    [ -x "$p" ] && { echo "$p"; return 0; }
  done
  # Windows 上是 .bat
  for p in /d/flutter/bin/flutter.bat /c/flutter/bin/flutter.bat; do
    [ -f "$p" ] && { echo "$p"; return 0; }
  done
  echo ""
}

FLUTTER="$(find_flutter)"
if [ -z "$FLUTTER" ]; then
  printf '\033[31m找不到 flutter。装 Flutter SDK，或设 FLUTTER_BIN=/path/to/flutter\033[0m\n'
  exit 1
fi

# 纯 Dart 包要 dart（不是 flutter）。它一定在 SDK 的 bin 下，和 flutter 挨着。
find_dart() {
  if [ -n "${DART_BIN:-}" ] && [ -x "${DART_BIN}" ]; then
    echo "$DART_BIN"; return 0
  fi
  if command -v dart >/dev/null 2>&1; then
    echo "dart"; return 0
  fi
  local fdir
  fdir="$(cd "$(dirname "$FLUTTER")" && pwd)"
  for p in "$fdir/dart" "$fdir/dart.bat"; do
    [ -f "$p" ] && { echo "$p"; return 0; }
  done
  echo ""
}

DART="$(find_dart)"

# 包清单：底座包 + apps/ 下每个带 pubspec.yaml 的目录
all_packages() {
  for d in kit/ kit-agent/ kit-membership/ chat-demo/ apps/*/; do
    [ -f "$d/pubspec.yaml" ] || continue
    echo "${d%/}"
  done
}

# 包是否依赖 Flutter（决定用 flutter analyze 还是 dart analyze）
is_flutter_pkg() {
  grep -q "^  flutter:" "$1/pubspec.yaml" 2>/dev/null
}

# ── 各道门禁 ────────────────────────────────────────────────────
cmd_bootstrap() {
  step "bootstrap（pub get）"
  # 本仓库是 pub workspace（根 pubspec 的 workspace:），一次 pub get 解析全部包。
  # 逐包 pub get 在 workspace 下会报 "included in the workspace"，所以只跑根。
  if "$FLUTTER" pub get >/tmp/pubget.log 2>&1; then
    ok "workspace（kit / kit-agent / kit-membership / chat-demo / apps/*）"
  else
    tail -30 /tmp/pubget.log
    bad "workspace pub get"
  fi
}

cmd_analyze() {
  step "analyze（静态分析）"
  local p tool
  while read -r p; do
    [ -n "$p" ] || continue
    if is_flutter_pkg "$p"; then
      tool="$FLUTTER analyze"
    else
      [ -n "$DART" ] || { ok "$p（找不到 dart，跳过）"; continue; }
      tool="$DART analyze"
    fi
    # shellcheck disable=SC2086
    if (cd "$p" && $tool >/tmp/analyze.log 2>&1); then
      ok "$p"
    else
      cat /tmp/analyze.log
      bad "$p"
    fi
  done < <(all_packages)
}

cmd_test() {
  step "test（单元 + widget 测试）"
  local p
  while read -r p; do
    [ -n "$p" ] || continue
    [ -d "$p/test" ] || { ok "$p（没有 test，跳过）"; continue; }
    local tcmd
    if is_flutter_pkg "$p"; then tcmd="$FLUTTER test"; else tcmd="$DART test"; fi
    if (cd "$p" && $tcmd >/tmp/test.log 2>&1); then
      ok "$p"
    else
      tail -40 /tmp/test.log
      bad "$p"
    fi
  done < <(all_packages)
}

cmd_contract() {
  step "contract（跨端契约：小程序端）"
  if ! command -v node >/dev/null 2>&1; then
    ok "没有 node，跳过（小程序端零依赖，有 node 18+ 就能跑）"
    return
  fi
  local ran=0 d app
  for d in apps/*/miniprogram; do
    [ -d "$d/test" ] || continue
    ran=1
    app="$(basename "$(dirname "$d")")"
    if node --test "$d/test/*.test.js"; then
      ok "$app 小程序端契约"
    else
      bad "$app 小程序端契约"
    fi
  done
  [ $ran -eq 0 ] && ok "没有小程序端"
}

cmd_verify() {
  step "verify（自带静态检查）"
  local py
  for c in python3 python; do
    command -v "$c" >/dev/null 2>&1 && { py="$c"; break; }
  done
  if [ -z "$py" ]; then
    ok "没有 python，跳过 verify"
    return
  fi

  if "$py" scripts/verify_contract.py; then ok "契约动作名与各端一致"; else bad "契约动作名与各端一致"; fi
  if "$py" scripts/verify_layers.py;     then ok "底座没有反依赖 app";   else bad "底座没有反依赖 app"; fi
  if "$py" scripts/verify_gateway.py;    then ok "网关协议两边对得上";   else bad "网关协议两边对得上"; fi
  if bash scripts/checks/no-hardcoded-secrets.sh; then ok "没找到硬编码的 API key"; else bad "没找到硬编码的 API key"; fi
  if bash scripts/checks/submodules.sh; then ok "子模块都已初始化"; else bad "子模块都已初始化"; fi
}

cmd_backend() {
  step "backend（agent 网关：类型检查 + 冒烟）"
  if ! command -v node >/dev/null 2>&1; then
    ok "没有 node，跳过 backend"
    return
  fi
  if [ ! -d backend ]; then
    ok "没有 backend/，跳过"
    return
  fi
  if [ ! -d backend/node_modules ]; then
    if (cd backend && npm ci >/tmp/backend-install.log 2>&1); then
      ok "npm ci"
    else
      tail -20 /tmp/backend-install.log
      bad "npm ci"
      return
    fi
  fi
  local sub
  for sub in check smoke; do
    if (cd backend && npm run "$sub" >"/tmp/backend-$sub.log" 2>&1); then
      ok "npm run $sub"
    else
      tail -40 "/tmp/backend-$sub.log"
      bad "npm run $sub"
    fi
  done
}

cmd_build() {
  step "build（demo：Web + Android debug）"
  if (cd apps/demo && "$FLUTTER" build web --release >/tmp/build-web.log 2>&1); then
    ok "web"
  else
    tail -30 /tmp/build-web.log
    bad "web"
  fi
  # Android 需要 SDK；没有就跳过而不是失败（CI 的 android job 有 SDK）
  if (cd apps/demo && "$FLUTTER" build apk --debug >/tmp/build-apk.log 2>&1); then
    ok "android apk"
  else
    if grep -qi "No Android SDK\|Android SDK file not found" /tmp/build-apk.log 2>/dev/null; then
      ok "android apk（本机没装 Android SDK，跳过）"
    else
      tail -30 /tmp/build-apk.log
      bad "android apk"
    fi
  fi
}

cmd_base_guard() {
  step "base-guard（底座路径未被改动）"
  bash scripts/check-base-unchanged.sh "$@"
}

# ── 入口 ────────────────────────────────────────────────────────
case "${1:-all}" in
  bootstrap)  cmd_bootstrap ;;
  analyze)    cmd_analyze ;;
  test)       cmd_test ;;
  contract)   cmd_contract ;;
  verify)     cmd_verify ;;
  backend)    cmd_backend ;;
  build)      cmd_build ;;
  base-guard) shift; cmd_base_guard "$@" ;;
  all)        cmd_bootstrap; cmd_analyze; cmd_verify; cmd_test; cmd_contract; cmd_backend ;;
  *) echo "用法: $0 {bootstrap|analyze|test|contract|verify|backend|build|base-guard|all}" >&2; exit 2 ;;
esac

echo ""
if [ ${#FAILED[@]} -eq 0 ]; then
  printf '\033[32m全部门禁通过\033[0m\n'
  exit 0
else
  printf '\033[31m%d 道门禁失败：\033[0m\n' "${#FAILED[@]}"
  printf '  - %s\n' "${FAILED[@]}"
  exit 1
fi
