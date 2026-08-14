# dsplugins — DSH 插件管理工作区

DeepSeek Harness (DSH) 插件仓库管理目录。每个插件独立成一个 git 仓库，统一推送到
[LosEcher](https://github.com/LosEcher) GitHub 账号。

## 仓库清单

| 插件 | GitHub | 状态 | 说明 |
|---|---|---|---|
| [dsh-semantic-eviction](dsh-semantic-eviction/) | [LosEcher/dsh-semantic-eviction](https://github.com/LosEcher/dsh-semantic-eviction) | ✅ 已发布 | 语义逐出：大工具结果落盘后替换为 stub（移植自 los） |
| … | | | 待开发 |

## 结构约定

```
dsplugins/
├── README.md                  # 本索引
├── install-first-batch.sh     # 第一批社区插件安装脚本
├── <plugin-name>/             # 每个插件一个独立 git 仓库
│   ├── package.json           # dsh.bundle.patch → cordis.patch.yml 声明
│   ├── cordis.patch.yml       # profile 补丁层
│   ├── src/                   # host 半 + client 半
│   └── tests/
└── .gitignore                 # 忽略插件子目录（子目录各自是独立仓库）
```

## 新建插件的标准流程

```bash
# 1. 脚手架起步（参照 dsh-semantic-eviction 结构）
mkdir -p dsplugins/<plugin-name>/src/client dsplugins/<plugin-name>/tests

# 2. 初始化独立仓库
cd dsplugins/<plugin-name>
git init -b main
git add -A && git commit -m "feat: <plugin-name> — <一句话>"

# 3. 发布到 GitHub（LosEcher 账号）
gh repo create LosEcher/<plugin-name> --public --source=. --remote=origin --push

# 4. 安装到 DSH
dsh plugin --profile web add "github:LosEcher/<plugin-name>#main"
```

## 安装脚本

`install-first-batch.sh` 安装第一批社区插件（context-doctor / llm-fallbacks /
subagent-tools / revive / undo / memory-evolve / session-search）：

```bash
bash install-first-batch.sh            # 全部安装
bash install-first-batch.sh --dry-run  # 预览
```
