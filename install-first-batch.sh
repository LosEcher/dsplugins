#!/usr/bin/env bash
# ============================================================================
# install-first-batch.sh — 第一批 DSH 插件安装脚本
#
# 对应分析报告「第一批：必装」7 个插件。已验证仓库存在性与 manifest 声明：
#
#   ✅ 标准 bundle 插件（dsh.bundle.patch 声明，dsh plugin add 直接生效）：
#       - dsh-context-doctor      (Zhenyu98)      bundle.patch ✅
#       - dsh-llm-fallbacks       (omdsh-dev)     bundle.patch ✅ (bundle/cordis.patch.yml)
#       - dsh-subagent-tools      (lynx-gt)       bundle.patch ✅ (默认分支 master!)
#       - dsh-revive              (omdsh-dev)     bundle.patch ✅
#       - dsh-undo                (LingLambda)    bundle.patch ✅ (默认分支 master!)
#   ⚠️  客户端注入型插件（无 bundle.patch，add 后需手动注册 insert 行）：
#       - dsh-memory-evolve       (csyangwen)     client.inject 型，需 patch 注册
#       - dsh-session-search      (Tieboyh)       无 dsh 声明，用 dshx 或手动 mount
#
# 用法：
#   bash install-first-batch.sh                # 安装全部
#   bash install-first-batch.sh --dry-run      # 只打印将执行的命令，不执行
#   bash install-first-batch.sh --only memory  # 只装 memory-evolve
#   bash install-first-batch.sh --skip session # 跳过 session-search
#
# 依赖：dsh CLI 可用（PATH 中或已 npm 全局安装），git、node、pnpm。
# 装完必须重启：dsh --profile web
# ============================================================================
set -euo pipefail

# ── 可配置：DSH 命令 ------------------------------------------------------
# 默认取 PATH 中的 dsh；若不在 PATH，可改为：
#   DSH="node /Users/echerlos/.dsh/profiles/node_modules/@deepseek-ai/dsh/lib/bin.js"
DSH="${DSH:-dsh}"
PROFILE="${PROFILE:-web}"

DRY_RUN=0
ONLY=""
SKIP=""

# ── 参数解析 --------------------------------------------------------------
while [[ $# -gt 0 ]]; do
  case "$1" in
    --dry-run) DRY_RUN=1 ;;
    --only)    ONLY="$2"; shift ;;
    --skip)    SKIP="$2"; shift ;;
    *) echo "未知参数: $1"; exit 1 ;;
  esac
  shift
done

run() {
  if [[ $DRY_RUN -eq 1 ]]; then
    echo "[dry-run] $*"
  else
    echo "[run] $*"
    "$@"
  fi
}

want() {
  # want <key> — 是否安装此插件
  if [[ -n "$ONLY" && "$ONLY" != "$1" ]]; then return 1; fi
  if [[ -n "$SKIP" && "$SKIP" == "$1" ]]; then return 1; fi
  return 0
}

echo "==> DSH: $DSH  profile: $PROFILE  (dry-run=$DRY_RUN)"
echo

# ── 0. 环境自检 -----------------------------------------------------------
if [[ $DRY_RUN -eq 0 ]]; then
  if ! command -v "$DSH" >/dev/null 2>&1; then
    echo "!! 未找到 dsh 命令。请先安装：npm i -g @deepseek-ai/dsh"
    echo "   或设置 DSH='node /path/to/dsh/lib/bin.js'"
    exit 1
  fi
  "$DSH" plugin --profile "$PROFILE" ls >/dev/null 2>&1 || {
    echo "!! dsh plugin 子命令不可用，请确认 DSH 版本 >= 0.1.0-rc.5"
    exit 1
  }
fi

# ── 1. 标准 bundle 插件 ---------------------------------------------------
# 这些包声明了 dsh.bundle.patch，dsh plugin add 后即成为激活的 profile 层。
if want context-doctor; then
  run "$DSH" plugin --profile "$PROFILE" add "github:Zhenyu98/dsh-context-doctor#main"
fi

if want llm-fallbacks; then
  run "$DSH" plugin --profile "$PROFILE" add "github:omdsh-dev/dsh-llm-fallbacks#main"
fi

if want subagent-tools; then
  # 注意：默认分支是 master，不是 main！
  run "$DSH" plugin --profile "$PROFILE" add "github:lynx-gt/dsh-subagent-tools#master"
fi

if want revive; then
  run "$DSH" plugin --profile "$PROFILE" add "github:omdsh-dev/dsh-revive#main"
fi

if want undo; then
  # 注意：默认分支是 master，不是 main！
  run "$DSH" plugin --profile "$PROFILE" add "github:LingLambda/dsh-undo#master"
fi

# ── 2. 客户端注入型插件 ---------------------------------------------------
# dsh-memory-evolve：纯客户端插件（dsh.client.inject），无 bundle.patch。
#   安装包后还需在 profile 的 cordis.patch.yml 手动注册 insert 行（见下）。
if want memory; then
  run "$DSH" plugin --profile "$PROFILE" add "github:csyangwen/dsh-memory-evolve#main"
  echo
  echo "!! dsh-memory-evolve 需要手动注册 patch 行："
  echo "   编辑 ~/.dsh/profiles/${PROFILE}/cordis.patch.yml，追加："
  echo "------------------------------------------------------------"
  echo "  - insert:"
  echo "      - id: dsh-memory-evolve"
  echo "        name: dsh-memory-evolve"
  echo "        config:"
  echo "          reviewEnabled: true"
  echo "          reviewInterval: 10"
  echo "------------------------------------------------------------"
fi

# dsh-session-search：无标准 bundle 声明（dsh: null），用 dshx 或手动 mount。
if want session; then
  echo
  echo "!! dsh-session-search 不是标准 profile bundle，两种安装方式："
  echo "   方式 A（dshx）:"
  echo "     git clone https://github.com/Tieboyh/dsh-session-search.git"
  echo "     dshx install dsh-session-search ./dsh-session-search"
  echo "   方式 B（手动 mount 到 ~/.dsh/config.yaml）:"
  echo "     - insert:"
  echo "         - id: dsh-session-search"
  echo "           name: '/absolute/path/to/dsh-session-search/lib/index.js'"
  echo "           config:"
  echo "             sources: { dsh: true, codex: true, claude: true, pi: true, opencode: true }"
  echo "             maxResults: 10"
  echo "             readWindow: 10"
fi

# ── 3. 收尾 ---------------------------------------------------------------
echo
if [[ $DRY_RUN -eq 1 ]]; then
  echo "==> dry-run 结束。实际安装后请重启：$DSH --profile $PROFILE"
else
  echo "==> 安装完成。请重启 DSH：$DSH --profile $PROFILE"
  echo "    管理面板：Settings → Plugins 查看已装插件"
fi
