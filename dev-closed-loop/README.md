# 開發設計閉環

## 這是什麼

一套軟體開發的品質保證方法。核心概念是：每寫一段程式碼，都要經過五個角色的驗證（架構師 → 程序設計師 → 檢核師 → 測試師 → 自証師），最後由自証師確認所有產出物之間沒有矛盾，才算完成。

## 文件結構

這個目錄分成兩個部分：

### 實作（拿去用的）

| 文件 | 說明 |
|------|------|
| `CLAUDE_TEMPLATE.md` | CLAUDE.md 自包含模板（含 Agent 調度規則、閘門、學習日誌、活動日誌、Task 可見性） |
| `.claudedocs/` | 技術文檔（10 核心 + 9 agent prompt），給人類閱讀 |
| `.claudedocs/agents/` | Agent 專家庫（8 個專家 prompt），Phase 觸發時按需載入 |
| `.claudedocs/languages/` | 語言 Skills（6 語言：TS/Py/Go/Rust/C#/Bash），部署時只複製偵測到的語言 |
| `skill/init-claude.md` | Skill 源碼（由 setup.sh 部署到 `~/.claude/commands/dev/`） |
| `hooks/` | 5 個 Hook 腳本（修改守衛、理解確認、增量 lint、委派追蹤、學習日誌提醒） |
| `deploy-hooks.sh` | 一鍵部署 Hook 系統（複製腳本 + 合併 settings.json + 驗證） |
| `check-version.sh` | 版本檢查工具（快取/部署/遠端一次比完，輸出 key=value） |

### 設計歷史（了解這套方法怎麼來的）

| 文件 | 說明 |
|------|------|
| `design/01_原始構想.md` | 最初的閉環設計想法，包含 9 個角色、4 個層級 |
| `design/02_深度分析.md` | 對原始構想的問題分析和改進方向 |
| `design/03_落地路線圖.md` | 5 個 Phase 的執行計畫 |
| `design/04_Skill設計規劃.md` | `dev:init-claude` Skill 的設計藍圖 |
| `design/05-research-methodology-analysis.md` | 方法論比較分析 |
| `design/06-analysis-deep-review.md` | 方法論深度檢討 |
| `design/07-research-project-orchestrator.md` | 專案協調者研究 |

## 使用方式

最簡單的方法是裝好 Skill 後直接跑指令：

```
/dev:init-claude          ← 部署閉環到專案
/dev:init-claude status   ← 查看部署狀態
/dev:init-claude upgrade  ← 從 GitHub 下載最新版
```

安裝方式見根目錄 README。

手動部署也可以：複製 `CLAUDE_TEMPLATE.md` + `.claudedocs/` 到專案根目錄，改名為 `CLAUDE.md`，替換所有 `{{PLACEHOLDER}}`。

## .claudedocs 目錄結構

```
.claudedocs/
├── README.md               ← 閱讀順序指南
├── agents/                 ← Agent 專家庫（8 個專家 prompt）
│   ├── README.md
│   ├── requirements-analyst.md  ← 需求探索
│   ├── architect.md             ← Phase 1 設計
│   ├── design-reviewer.md       ← Phase 1b 設計審查
│   ├── implementer.md           ← Phase 2 實作
│   ├── code-reviewer.md         ← Phase 3 品質審查
│   ├── security-reviewer.md     ← Phase 3 安全審查
│   ├── tester.md                ← Phase 4 測試
│   └── verifier.md              ← Phase 5 雙向追溯
├── concepts/
│   └── 閉環核心理念.md      ← 這套方法在幹嘛、為什麼有用
├── process/
│   ├── 五階段閉環流程.md     ← 實際怎麼跑，每個階段做什麼
│   ├── 層級擴展.md          ← 從函式到模組到框架怎麼串
│   ├── 跨Session持久化.md   ← 大型專案怎麼跨 Session 保存狀態
│   └── 介面契約與變更管理.md  ← 跨模組 API 怎麼定義和追蹤變更
├── standards/
│   ├── Agent使用指南.md      ← 每個階段該用什麼工具
│   ├── Git工作流.md          ← 閉環跟 Git 怎麼配合
│   └── 產出物格式.md         ← 每個階段要交什麼東西
├── records/
│   └── 問題追蹤.md           ← 遇到問題怎麼記錄
└── languages/               ← 語言特定指南
    ├── README.md
    ├── typescript.md
    ├── python.md
    ├── go.md
    ├── rust.md
    ├── csharp.md
    └── bash.md
```

## 閱讀建議

- 想**了解背景**：從 `design/01_原始構想` → `design/02_深度分析` → `design/03_落地路線圖` 讀
- 想**直接用**：從 `CLAUDE_TEMPLATE.md` 開始，搭配 `.claudedocs/` 裡的文檔
- 想**看閱讀順序**：看 `.claudedocs/README.md`

## 版本歷史

| 版本 | 重點 |
|------|------|
| v5.17.0 | Agent 調用精確化——自文檔化調用方式 + 活動日誌 + learning-log agent 標籤 + Task activeForm + 斷點回退可見性 |
| v5.16.0 | 回顧式學習自動化——失敗驅動學習日誌 + 模式分析 + PostToolUse Hook 檢查 |
| v5.15.0 | 精簡閉環迷你追溯（步驟 4.5）+ CLAUDE_TEMPLATE 認知負荷降低（606→361 行，-40%） |
| v5.14.0 | Agent 專家庫（8 個自包含 agent prompt），方法論自包含無外部依賴 |
| v5.13.0 | 全 Hook 阻擋式升級：因果鏈守衛 + 理解確認守衛均為 block 機制（雙閘門合併阻擋） |
| v5.12.0 | 理解確認守衛 Hook + 全 Hook 橙色可見性（防不對頻，用戶輸入即觸發理解確認） |
| v5.11.0 | 同類掃描（修改時橫向掃描同類項目，避免只修冰山一角） |
| v5.10.1 | 模板瘦身：子 agent prompt 移至 .claudedocs，模板 512→448 行（-12.5%） |
| v5.10.0 | 架構體質拆解（第一性原理：設計前拆解現有架構假設，審查架構擴展能力） |
| v5.9.0 | 合理性審查（Phase 1 自檢 + Phase 3 審查維度 + 非閉環通用規則） |
| v5.8.0 | 因果鏈分析可見性 + 深度規則（畫面輸出推導過程，穿透呼叫鏈/語意/時序/邊界） |
| v5.7.0 | 自動更新系統 + 三位數版本制（curl 安裝、upgrade 模式、GitHub 版本偵測） |
| v5.6.0 | 因果鏈守衛 Hook（修改前自動提醒做影響分析） |
| v5.5.0 | 領域偵測、架構風險嚴重度、Phase 5 雙向合併、測試分層 |
| v5.3.0 | 委派追蹤 Hook（Agent 呼叫自動記錄） |
| v5.2.0 | 委派產出物強制寫入 .claude-loop/artifacts/ |
| v5.1.0 | 依賴影響分析規則 |
| v5.0.0 | 獨立子 agent 架構 + PRD 需求分解 + 增量驗證 Hook |
| v4.0 | Gen 3 重寫（601→185 行）+ 升級機制 |
| v3.x | Skill 系統、跨 Session 持久化、介面契約、claude-mem 整合 |
