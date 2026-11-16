#!/usr/bin/env bash
# 子模块检查 —— 子模块目录是空的就失败。
#
# 为什么要这道：submodule 没初始化时目录是**空目录**，而 `cp -r` 拷空目录**不报错** ——
# 装出去的项目一个 skill 都没有，CI 也不会红。这道门禁就是防这个。
#
# 修：git submodule update --init --recursive
set -o pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT" || exit 1

if [ ! -f .gitmodules ]; then
  echo "  没有 .gitmodules，跳过"
  exit 0
fi

EMPTY=""
while read -r path; do
  [ -z "$path" ] && continue
  if [ ! -d "$path" ] || [ -z "$(ls -A "$path" 2>/dev/null)" ]; then
    EMPTY="$EMPTY $path"
  fi
done <<< "$(git config --file .gitmodules --get-regexp '^submodule\..*\.path$' 2>/dev/null | awk '{print $2}')"

if [ -n "$EMPTY" ]; then
  echo "  下列子模块目录是空的（没初始化）："
  for p in $EMPTY; do echo "    $p"; done
  echo "  → git submodule update --init --recursive"
  exit 1
fi

exit 0
