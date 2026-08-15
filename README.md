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
| [dsh-semantic-eviction](dsh-semantic-eviction/) | [LosEcher/dsh-semantic-eviction](https://github.com/LosEcher/dsh-semantic-eviction) | ✅ 已发布 | 语义逐出：大工具结果落盘后替换为 stub（移植自 los） |
| [dsh-jj](dsh-jj/) | [LosEcher/dsh-jj](https://github.com/LosEcher/dsh-jj) | ✅ 已发布（2026-08-15） | jj (Jujutsu) MCP server bundle（自研零依赖，14 工具 + 冒烟测试全绿；profile 依赖待切 `github:`） |
| [dsh-channel-telegram](dsh-channel-telegram/) | [LosEcher/dsh-channel-telegram](https://github.com/LosEcher/dsh-channel-telegram) | ✅ 已发布（2026-08-15） | Telegram 薄桥（长轮询 Bot API，allowlist，每聊一会话；profile 依赖待切 `github:`） |
| [kimi-webbridge-mcp](kimi-webbridge-mcp/) | [LosEcher/kimi-webbridge-mcp](https://github.com/LosEcher/kimi-webbridge-mcp) | ✅ 已发布（2026-08-15） | Kimi WebBridge MCP server（浏览器控制，跨 DSH/Claude Code/Codex；profile 依赖待切 `github:`） |
| [dsh-code-analysis](dsh-code-analysis/) | 待发布 | 📦 本地已建仓 | CBM 代码知识图谱接入（mcp__cbm__* 14 工具） |
| [dsh-health-panel](dsh-health-panel/) | 待发布 | 📦 本地已建仓 | DSH 观测面板（client 半包，host 指标 API） |
| [dsh-channel-wechat](dsh-channel-wechat/) | 待发布 | 📦 本地已建仓 | 微信渠道插件（weclaw 桥接） |
| [dsh-mcp-common](dsh-mcp-common/) | 待发布 | 📦 本地已建仓 | MCP 公共工具（MCP server 一键接入） |
| … | | | 待开发 |

状态说明：`✅ 已发布` = 已推 LosEcher GitHub；profile 依赖仍为 `link:` 时注明「待切 `github:`」。`📦 本地已建仓` = 2026-08-15 从 dsfolder 迁入，git 仓库已建、尚未发布。

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
