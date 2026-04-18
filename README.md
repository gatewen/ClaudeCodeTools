# ClaudeCodeTools

讓 Claude Code 寫出更可靠的程式碼。

這個工具包的核心是「開發設計閉環」——一套品質保證方法。簡單來說，每段程式碼都會經過五個角色的檢查（架構師 → 程序設計師 → 檢核師 → 測試師 → 自證師），最後由自證師確認所有產出物沒有矛盾，才算完成。

裝好之後，你只要在專案目錄裡跑一行指令，Claude Code 就會自動按照這套流程工作。

## 安裝

打開終端機，貼上這行：

```bash
curl -sL https://raw.githubusercontent.com/gatewen/ClaudeCodeTools/main/setup.sh | bash
```

這會自動下載所有檔案到 `~/.claude/cache/ClaudeCodeTools/`，並把 Skill 部署好。

> **開發者？** 也可以用 `git clone https://github.com/gatewen/ClaudeCodeTools.git && cd ClaudeCodeTools && bash setup.sh`

### 前置依賴

閉環自帶 Agent 專家庫（8 個專家 prompt），**不依賴外部工具**即可完整運作。Task agent（`code-simplifier` 等）是 Claude Code 內建功能。

以下是可選的增強工具，有的話體驗更好，沒有也不影響閉環流程：

| 工具 | 做什麼用的 | 怎麼裝 |
|------|-----------|--------|
| **claude-mem** _(可選)_ | 跨對話的語義記憶（Phase 前查歷史決策、Phase 後保存教訓） | Claude Code 插件：`claude-mem` |

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
Phase 5  自證師    交叉比對前四個階段的產出物，找出矛盾
```

Phase 5 是這套方法的特色——它用編號系統（BC-x / EH-x / R-x）精確追溯每個宣稱，確保設計、程式碼、審查報告、測試報告之間完全一致。

### 自動化 Hook

部署時會一起裝六個 Hook，在背景自動幫你做品質把關：

| Hook | 什麼時候觸發 | 做什麼 |
|------|------------|--------|
| **修改前統一守衛** | 修改檔案之前 | **阻擋**修改，雙閘門：①理解確認（對頻）②因果鏈分析（影響評估），合併為一次 block |
| **委派前因果鏈閘門** | 呼叫 Agent 之前 | **阻擋**修改型 Agent 委派，要求先分析預期修改範圍和影響 |
| **理解確認旗標** | 用戶提交指令時 | 偵測修改意圖，設定旗標 + 清理因果鏈/委派閘門 marker |
| **增量驗證** | 修改檔案之後 | 自動對改過的檔案跑 lint |
| **委派追蹤** | 呼叫 Agent 之後 | 自動記錄 Agent 的任務和結果 |
| **學習日誌提醒** | git commit 之後 | 檢查 learning-log.md 是否在 commit 中，未包含則提醒 |

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
    ├── deploy-hooks.sh                ← 一鍵部署 Hook 系統（腳本保證，不靠 AI 自律）
    ├── check-version.sh              ← 版本檢查工具（快取/部署/遠端一次比完）
    ├── hooks/
    │   ├── impact-analysis-guard.sh  ← 修改前統一守衛（雙閘門阻擋）
    │   ├── delegation-gate.sh        ← 委派前因果鏈閘門（修改型 Agent 阻擋）
    │   ├── prompt-understanding-guard.sh ← 理解確認旗標 + marker 清理
    │   ├── incremental-lint.sh       ← 增量驗證
    │   ├── delegation-tracker.sh     ← 委派追蹤
    │   └── learning-log-checker.sh   ← 學習日誌提醒
    ├── .claudedocs/                  ← 給人看的技術文檔
    │   ├── agents/                   ← Agent 專家庫（8 個專家 prompt）
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
| v5.22.1 | 升格機制覆蓋擴大——design-reviewer 步驟 5b 學習查詢執行檢查（補閉環獨立性漏洞）+ 精簡閉環迷你追溯加入升格檢查（主 agent 自做，補日常 80-90% 工作的累積落差） |
| v5.22.0 | 兩層教訓架構——`learning-log.md` 短期工作記憶 + `問題追蹤.md` 長期警惕模式 + 升格機制（同類根因 ≥ 3 次 + Phase 5 verifier 偵測候選 + 主 agent AskUserQuestion 確認 + 升格寫入並標記）+ architect Phase 1 必讀長期模式 + reel_core 案兩條種子條目 |
| v5.21.1 | 術語修正——「自証」→「自證」（繁中正寫），跨 23 個活檔案統一替換 105 處（design/ 設計歷史保留原始術語作為時間快照） |
| v5.21.0 | 防轉述遺漏——設計規格持久化為 `P1-design-spec.md`（必須）+ 4 個 task agent 改為路徑模式（Sub-Agent 直接 Read 原始產出物，主 agent 不轉述） + input_contract 每項標明讀取方式 + 路徑完整性校驗 |
| v5.20.0 | 反偷懶三措施——因果鏈呼叫者逐條展開 + Phase 5 行為路徑枚舉前置 + 跨 Phase 一致性驗證 |
| v5.19.0 | 因果鏈分析「呼叫者存在性」——修改函式前 grep 確認呼叫者，呼叫者=0 禁止修改 |
| v5.18.0 | Hook 系統修正 + 委派前閘門——因果鏈 marker 每輪重置 + 短指令偵測擴充 + 新增 delegation-gate.sh（修改型 Agent 委派前強制因果鏈分析） |
| v5.17.1 | 升級系統 SHA 追蹤——下載時記錄 commit SHA + 版本同但 SHA 異時警告 + status 顯示 SHA |
| v5.17.0 | Agent 調用精確化——自文檔化調用方式 + 活動日誌 + learning-log agent 標籤 + Task activeForm + 斷點回退可見性 |
| v5.16.0 | 回顧式學習自動化——失敗驅動學習日誌（即時捕獲 + commit 前寫入 + Hook 檢查）+ 模式分析 |
| v5.15.0 | 精簡閉環迷你追溯（步驟 4.5 正向覆蓋表）+ CLAUDE_TEMPLATE 認知負荷降低（606→361 行，-40%） |
| v5.14.0 | Agent 專家庫（8 個自包含 agent prompt），方法論自包含無外部依賴 |
| v5.13.0 | 全 Hook 阻擋式升級：因果鏈守衛 + 理解確認守衛均為 block 機制（雙閘門合併阻擋） |
| v5.12.0 | 理解確認守衛 Hook + 全 Hook 橙色可見性（防不對頻，用戶輸入即觸發理解確認） |
| v5.11.0 | 同類掃描（修改時橫向掃描同類項目，避免只修冰山一角） |
| v5.10.1 | 模板瘦身：子 agent prompt 移至 .claudedocs，模板 512→448 行（-12.5%） |
| v5.10.0 | 架構體質拆解（第一性原理：設計前拆解現有架構假設，審查架構擴展能力） |
| v5.9.0 | 合理性審查（Phase 1 自檢 + Phase 3 審查維度 + 非閉環通用規則） |
| v5.8.0 | 因果鏈分析可見性 + 深度規則（畫面輸出推導過程，穿透呼叫鏈/語意/時序/邊界） |
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
