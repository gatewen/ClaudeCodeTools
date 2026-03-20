# ClaudeCodeTools

讓 Claude Code 寫出更可靠的程式碼。

這個工具包的核心是「開發設計閉環」——一套品質保證方法。簡單來說，每段程式碼都會經過五個角色的檢查（架構師 → 程序設計師 → 檢核師 → 測試師 → 自証師），最後由自証師確認所有產出物沒有矛盾，才算完成。

裝好之後，你只要在專案目錄裡跑一行指令，Claude Code 就會自動按照這套流程工作。

## 安裝

打開終端機，貼上這行：

```bash
curl -sL https://raw.githubusercontent.com/gatewen/ClaudeCodeTools/main/setup.sh | bash
```

這會自動下載所有檔案到 `~/.claude/cache/ClaudeCodeTools/`，並把 Skill 部署好。

> **開發者？** 也可以用 `git clone https://github.com/gatewen/ClaudeCodeTools.git && cd ClaudeCodeTools && bash setup.sh`

### 前置依賴

安裝腳本會自動幫你檢查，缺少的話會提示你怎麼裝：

| 工具 | 做什麼用的 | 怎麼裝 |
|------|-----------|--------|
| **SuperClaude** | 提供 `sc:*` 系列進階指令 | `pipx install superclaude && superclaude install` |
| **Superpowers** | 提供 `superpowers:*` 系列品質工具 | Claude Code 插件：`superpowers@claude-plugins-official` |
| **claude-mem** _(選裝)_ | 跨對話的長期記憶 | Claude Code 插件：`claude-mem` |

> Task agent（`code-simplifier`、`security-engineer` 等）是 Claude Code 內建的，不用另外裝。

## 使用

安裝完成後，在任何專案目錄開 Claude Code，輸入：

```
/dev:init-claude
```

它會自動偵測你的專案（語言、框架、測試指令等），問你確認後，把閉環的 CLAUDE.md 和文檔部署到專案裡。之後 Claude Code 每次啟動都會自動遵循閉環流程。

### 其他指令

| 指令 | 做什麼 |
|------|--------|
| `/dev:init-claude status` | 看目前的部署狀態、版本、健康度 |
| `/dev:init-claude upgrade` | 從 GitHub 下載最新版，一鍵升級 |
| `/dev:init-claude uninstall` | 把閉環從專案移除 |

## 更新

不用手動 pull。直接在 Claude Code 裡跑：

```
/dev:init-claude upgrade
```

它會從 GitHub 抓最新版本到快取，更新 Skill，然後引導你升級目前的專案。

> 用 git clone 安裝的人也可以照傳統方式：`git pull && bash setup.sh`

## 閉環是怎麼運作的

每次開發一個功能，Claude 會自動跑五個階段：

```
Phase 1  架構師    寫設計規格，定義介面和測試策略
Phase 2  程序設計師  照規格寫程式碼，寫完自動跑 code-simplifier 優化
Phase 3  檢核師    逐行檢查程式碼是否符合規格，產出審查報告
Phase 4  測試師    跑測試、驗證效能，產出測試報告
Phase 5  自証師    交叉比對前四個階段的產出物，找出矛盾
```

Phase 5 是這套方法的特色——它用編號系統（BC-x / EH-x / R-x）精確追溯每個宣稱，確保設計、程式碼、審查報告、測試報告之間完全一致。

### 自動化 Hook

部署時會一起裝三個 Hook，在背景自動幫你做品質把關：

| Hook | 什麼時候觸發 | 做什麼 |
|------|------------|--------|
| **因果鏈守衛** | 修改檔案之前 | 提醒 AI 先做影響分析，避免改 A 壞 B |
| **增量驗證** | 修改檔案之後 | 自動對改過的檔案跑 lint |
| **委派追蹤** | 呼叫 Agent 時 | 自動記錄 Agent 的任務和結果 |

## 目錄結構

```
ClaudeCodeTools/
├── README.md                         ← 你在看的這個
├── CLAUDE.md                         ← 給 Claude Code 看的 repo 指引
├── setup.sh                          ← 安裝腳本（支援 curl 遠端 + 本地雙模式）
└── dev-closed-loop/
    ├── CLAUDE_TEMPLATE.md            ← 閉環模板（核心產物）
    ├── skill/
    │   └── init-claude.md            ← /dev:init-claude 指令的源碼
    ├── hooks/
    │   ├── impact-analysis-guard.sh  ← 因果鏈守衛
    │   ├── incremental-lint.sh       ← 增量驗證
    │   └── delegation-tracker.sh     ← 委派追蹤
    ├── .claudedocs/                  ← 給人看的技術文檔（10 份）
    │   ├── concepts/                 ← 核心理念
    │   ├── process/                  ← 流程說明
    │   ├── standards/                ← 工具和格式規範
    │   ├── records/                  ← 問題追蹤
    │   └── languages/               ← 語言指南（TS/Py/Go/Rust/C#/Bash）
    └── design/                       ← 設計歷史（01-07），了解方法怎麼演變的
```

## 支援的語言

部署時會自動偵測你的專案語言，載入對應的語言指南：

| 語言 | lint 指令 | 完整驗證序列 |
|------|----------|------------|
| TypeScript | `npx tsc --noEmit && npx eslint src/` | tsc + eslint + vitest + build |
| Python | `ruff check src/` | mypy + ruff + pytest |
| Go | `go vet ./... && golangci-lint run` | vet + lint + build + test |
| Rust | `cargo clippy -- -D warnings` | fmt + clippy + build + test |
| C# | `dotnet build --warnaserrors` | format + build + test |
| Bash | `shellcheck *.sh` | syntax + shellcheck + bats |

沒有對應語言指南的專案也能用——只是少了語言特定的 lint 規則，閉環流程一樣會跑。

## 版本歷史

| 版本 | 重點 |
|------|------|
| v5.7.0 | 自動更新系統 + 三位數版本制（curl 安裝、`upgrade` 模式、GitHub 版本偵測） |
| v5.6.0 | 因果鏈守衛 Hook（修改前自動提醒做影響分析） |
| v5.5.0 | 領域偵測、架構風險嚴重度、Phase 5 雙向合併、測試分層 |
| v5.3.0 | 委派追蹤 Hook（Agent 呼叫自動記錄） |
| v5.2.0 | 委派產出物強制寫入 .claude-loop/artifacts/ |
| v5.1.0 | 依賴影響分析規則 |
| v5.0.0 | 獨立子 agent 架構 + PRD 需求分解 + 增量驗證 Hook |
| v4.0 | Gen 3 重寫（601→185 行）+ 升級機制 |
| v3.x | Skill 系統、跨 Session 持久化、介面契約、claude-mem 整合 |

## 想了解更多

- **快速上手**：裝好後直接跑 `/dev:init-claude`，看它怎麼偵測你的專案
- **理解原理**：讀 `dev-closed-loop/.claudedocs/concepts/閉環核心理念.md`
- **看完整流程**：讀 `dev-closed-loop/.claudedocs/process/五階段閉環流程.md`
- **設計歷史**：`dev-closed-loop/design/` 裡有從構想到實作的完整記錄

## License

MIT
