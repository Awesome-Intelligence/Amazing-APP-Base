#!/usr/bin/env bash
# 密钥检查 —— 仓库里出现 API key 就直接失败。
#
# 为什么要这道：key 一旦进了 git 历史，删掉文件也没用（历史里还在），
# 只能换 key。所以拦在提交前最省事。
#
# 只扫源码和配置，跳过依赖目录与构建产物。
# 放行：在那一行加 `// pragma: allowlist secret`（只用于确实是测试假值的场合）。
set -o pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT" || exit 1

# 常见的密钥形态：Anthropic / OpenAI / AWS / GitHub / 私钥块
PATTERN='sk-ant-[A-Za-z0-9_-]{20,}|sk-[A-Za-z0-9]{32,}|AKIA[0-9A-Z]{16}|gh[pousr]_[A-Za-z0-9]{30,}|-----BEGIN [A-Z ]*PRIVATE KEY-----'

HITS=$(grep -rnE "$PATTERN" \
  --include='*.dart' --include='*.js' --include='*.ts' --include='*.yaml' \
  --include='*.yml' --include='*.json' --include='*.md' --include='*.sh' \
  . 2>/dev/null \
  | grep -v '/build/' \
  | grep -v '/.dart_tool/' \
  | grep -v '/node_modules/' \
  | grep -v '/.git/' \
  | grep -v 'allowlist secret' || true)

if [ -n "$HITS" ]; then
  echo "  发现疑似密钥（key 进了 git 历史就只能换，不能只删文件）："
  echo "$HITS" | sed 's/^/    /'
  exit 1
fi

exit 0
