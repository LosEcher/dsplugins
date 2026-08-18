# dsplugins — DSH 插件管理工作区

DeepSeek Harness (DSH) 插件仓库管理目录。**所有 DSH 自研/本地插件必须进入本目录**，
每个插件独立成一个 git 仓库，统一推送到 [LosEcher](https://github.com/LosEcher) GitHub 账号。

> **目录职责边界（2026-08-15 约定）**
> - `dsplugins/`：DSH 插件的唯一本地归宿（自研插件 + 需要本地开发的第三方插件）。
> - `dsfolder/`：**执行目录**（业务项目、los 网关代理等非插件服务），**不再放置任何插件**。
> - 纯第三方插件（如 dsh-tool-ocr）走 npm / `github:` 依赖 + profile patch 激活，
>   不占用本地目录；仅当需要本地改造时才在 dsplugins 建仓。
> - profile 依赖统一指向 `link:/Users/echerlos/syncthing/project/dsplugins/<name>`
>   （开发期）或 `github:LosEcher/<name>#main`（发布后），禁止再指向 dsfolder。

## 仓库清单

| 插件 | GitHub | 状态 | 说明 |
|---|---|---|---|
| [dsh-jj](dsh-jj/) | [LosEcher/dsh-jj](https://github.com/LosEcher/dsh-jj) | ✅ 已发布 1.0.1（2026-08-15，已切 `github:`） | jj (Jujutsu) MCP server bundle（自研零依赖，14 工具 + CI 冒烟全绿） |
| [dsh-channel-telegram](dsh-channel-telegram/) | [LosEcher/dsh-channel-telegram](https://github.com/LosEcher/dsh-channel-telegram) | ✅ 已发布 0.1.1（2026-08-15，已切 `github:`） | Telegram 薄桥（长轮询 Bot API，allowlist，每聊一会话；CI mock 单测） |
| [kimi-webbridge-mcp](kimi-webbridge-mcp/) | [LosEcher/kimi-webbridge-mcp](https://github.com/LosEcher/kimi-webbridge-mcp) | ✅ 已发布 1.0.1（2026-08-15，已切 `github:`） | Kimi WebBridge MCP server（浏览器控制，跨 DSH/Claude Code/Codex；vivaldi-open 在 extras/） |
| [dsh-semantic-eviction](dsh-semantic-eviction/) | [LosEcher/dsh-semantic-eviction](https://github.com/LosEcher/dsh-semantic-eviction) | ⚠️ 已 public，依赖待修 | 语义逐出：大工具结果落盘后替换为 stub；workspace:^ 依赖不兼容 GitHub 安装，待切真实范围后标 experimental |
| [dsh-multimedia](dsh-multimedia/) | 待发布 | 📦 本地已建仓（0.2.0） | 多媒体生成（fal/elevenlabs/comfyui/xai/zenmux/pollinations/googletts/cloudflare 渠道；CSS Module+locales 范式已整改） |
| [dsh-scheduler](dsh-scheduler/) | [LosEcher/dsh-scheduler](https://github.com/LosEcher/dsh-scheduler) | ✅ 已发布 0.2.1（2026-08-18，含 9a95916 crash-loop 修复 + b32a5d4 加固；profile 仍 link: 至下次空闲重启） | 定时任务（cron/interval/once + headless 执行 + deliverTo + 熔断 + 事件溯源台账 + 管理 UI） |
| [dsh-context-doctor](dsh-context-doctor/) | 待发布 | 📦 本地已建仓（0.5.1） | fork 自 Zhenyu98（保留 upstream remote），dock 槽位迁移 + 令牌清理已修活 |
| [dsh-code-analysis](dsh-code-analysis/) | 待发布 | 📦 本地已建仓 | CBM 代码知识图谱接入（mcp__cbm__*，本机 allowlist 10 工具） |
| [dsh-health-panel](dsh-health-panel/) | 待发布 | 📦 本地已建仓 | DSH 观测面板（client 半包，host 指标 API；Wave3 拟并入 code-analysis） |
| [dsh-channel-wechat](dsh-channel-wechat/) | 待发布 | 📦 本地已建仓（0.3.0） | 微信渠道插件（weclaw 桥接；标准卡片 + weclaw-admin 管理页；provider 默认已 de-Los） |
| [dsh-mcp-common](dsh-mcp-common/) | 不发布 | 📦 本地已建仓 | MCP 公共工具（context7 已 disabled；开源评审结论 REBUILD-or-DROP） |
| [dsh-theme-tune](dsh-theme-tune/) | 待发布 | 📦 本地已建仓（0.1.0） | 主题令牌覆盖：全局对比度矫正（ThemeService.overrideTokens，state-primary light 加深；分析见 dsfolder/DSH-THEME-OVERRIDE-ANALYSIS-2026-08-15.md） |
| … | | | 待开发 |

状态说明：`✅ 已发布` = 已推 LosEcher GitHub 且 web profile 依赖已切 `github:LosEcher/<name>#main`。
`⚠️ 已 public，依赖待修` = 仓库已公开但 GitHub 安装仍有 blocker。
`📦 本地已建仓` = 2026-08-15 从 dsfolder 迁入，git 仓库已建、尚未发布（括号内为当前版本）。

## 结构约定

```
dsplugins/
├── README.md                  # 本索引（仓库清单 + 目录职责边界）
├── install-first-batch.sh     # 第一批社区插件安装脚本
├── <plugin-name>/             # 每个插件一个独立 git 仓库
│   ├── package.json           # dsh.bundle.patch → cordis.patch.yml 声明
│   ├── cordis.patch.yml       # profile 补丁层
│   ├── src/                   # host 半 + client 半
│   └── tests/
└── .gitignore                 # 忽略插件子目录（子目录各自是独立仓库）
```

## 新建/迁移插件的标准流程

```bash
# 1. 脚手架起步（参照 dsh-semantic-eviction 结构；迁移则直接搬入）
mkdir -p dsplugins/<plugin-name>/src/client dsplugins/<plugin-name>/tests

# 2. 初始化独立仓库
cd dsplugins/<plugin-name>
git init -b main
git add -A && git commit -m "feat: <plugin-name> — <一句话>"

# 3. 发布到 GitHub（LosEcher 账号）
gh repo create LosEcher/<plugin-name> --public --source=. --remote=origin --push

# 4. 安装到 DSH（发布前用 link: 本地开发，发布后切 github:）
dsh plugin --profile web add link:/Users/echerlos/syncthing/project/dsplugins/<plugin-name>
dsh plugin --profile web add "github:LosEcher/<plugin-name>#main"
```

## 第三方插件安装（不占本地目录）

以 dsh-tool-ocr 为例（plain plugin，非 bundle，`add` 只装依赖不自动挂载）：

```bash
# 1. 引擎（可选，取决于插件）：nbocr 已装 ~/.local/bin/nbocr
# 2. 安装依赖
dsh plugin --profile web add dsh-tool-ocr          # npm 源
# 3. profile patch 激活（cordis.patch.yml insert 行，见 ~/.dsh/profiles/web/cordis.patch.yml）
- insert:
    - id: ocr
      name: dsh-tool-ocr
      inject: [tools, subprocess, systemPrompt]
      config:
        command: '/Users/echerlos/.local/bin/nbocr'
        language: 'chinese'
        detModel: 'v6-tiny'
# 4. 重启 dsh web（新插件必须重启，HMR 不加载新模块）→ RPC 插件树验证 active
```

注意：`cordis.patch.yml` 的 insert 块编辑后别重复 reapply（loader 对重复 entry id 拒绝）；
激活行属于 profile 配置层，不属于任何插件目录。

## 外部插件 fork（样式/兼容性调整后引入）

外部插件（github:/npm: 安装）存在样式不合标准或与当前 DSH 版本不兼容（如槽位改名）时，
fork 到 dsplugins 调整后引入（流程详见技能 dsh-plugin-operations「外部插件样式可优化 →
fork 流程」）：

- **dsh-context-doctor**（已 fork，2026-08-15）：上游注册在已移除的
  `conversation.input.context` 槽位 → **GUI 完全不渲染**；fork 迁移到
  `conversation.input.dock`（list 槽需 id+order）后 UI 修活；同时清理 TONE 常量里的
  深色 fallback hex（令牌缺失时浅色主题错乱）、MONO 改 `var(--dsw-font-family)`。
  profile 已切 `link:dsplugins/dsh-context-doctor`，upstream remote 保留可合上游。

## 安装脚本

`install-first-batch.sh` 安装第一批社区插件（context-doctor / llm-fallbacks /
subagent-tools / revive / undo / memory-evolve / session-search）：

```bash
bash install-first-batch.sh            # 全部安装
bash install-first-batch.sh --dry-run  # 预览
```
