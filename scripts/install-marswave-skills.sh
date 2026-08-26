#!/bin/bash
# install-marswave-skills.sh — 把 marswaveai/skills（MIT）平铺安装到 DSH 技能库
# DSH 发现规则：~/.agents/skills/<name>/SKILL.md（一层深度）
# 冲突处理：与现有技能同名的目录加前缀 msw-（如 asr → msw-asr）
# 运行前提（技能真正可用需要）：
#   npm install -g @marswave/listenhub-cli && listenhub auth login   # ListenHub 账号/API Key
# 更新：git -C "$SRC" pull && 重跑本脚本（幂等，覆盖同名 msw-* 目录）
set -euo pipefail

SRC="$HOME/.agents/marswaveai-skills"
DEST="$HOME/.agents/skills"
REPO="https://github.com/marswaveai/skills.git"
PREFIX="msw-"

echo "== 拉取/更新源仓库 =="
if [ -d "$SRC/.git" ]; then
  git -C "$SRC" pull --ff-only -q
else
  git clone --depth 1 "$REPO" "$SRC"
fi
mkdir -p "$DEST"

echo "== 平铺安装技能 =="
count=0
for dir in "$SRC"/*/; do
  name=$(basename "$dir")
  [ -f "$dir/SKILL.md" ] || continue
  target="$DEST/$name"
  if [ -d "$target" ] && [ "$name" != "shared" ]; then
    # 冲突：改名（frontmatter name 同步改，保持技能自引一致）
    target="$DEST/${PREFIX}${name}"
    sed "s/^name: ${name}$/name: ${PREFIX}${name}/" "$dir/SKILL.md" > /tmp/msw-skill.md
    rm -rf "$target"
    mkdir -p "$target"
    cp /tmp/msw-skill.md "$target/SKILL.md"
    for f in "$dir"/*; do
      [ "$(basename "$f")" = "SKILL.md" ] && continue
      cp -R "$f" "$target/"
    done
  else
    rm -rf "$target"
    cp -R "$dir" "$target"
  fi
  echo "  + $name -> $(basename "$target")"
  count=$((count + 1))
done
echo "== 完成：$count 个技能已安装到 $DEST =="
echo "提示：新技能需新会话/刷新后出现在技能目录；使用前请 listenhub auth login"
