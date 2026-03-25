# 開發設計閉環

## 這是什麼

一套軟體開發的品質保證方法。核心概念是：每寫一段程式碼，都要經過五個角色的驗證（架構師 → 程序設計師 → 檢核師 → 測試師 → 自証師），最後由自証師確認所有產出物之間沒有矛盾，才算完成。

## 文件結構

這個目錄分成兩個部分：

### 實作（拿去用的）

| 文件 | 說明 |
|------|------|
| `CLAUDE_TEMPLATE.md` | CLAUDE.md 自包含模板（含產出物格式、自証檢查表、Agent 調度規則） |
| `.claudedocs/` | 補充文檔（10 檔），給人類閱讀 |
| `.claudedocs/languages/` | 語言 Skills（6 語言：TS/Py/Go/Rust/C#/Bash），部署時只複製偵測到的語言 |
| `skill/init-claude.md` | Skill 源碼（由 setup.sh 部署到 `~/.claude/commands/dev/`） |

### 設計歷史（了解這套方法怎麼來的）

| 文件 | 說明 |
|------|------|
| `design/01_原始構想.md` | 最初的閉環設計想法，包含 9 個角色、4 個層級 |
| `design/02_深度分析.md` | 對原始構想的問題分析和改進方向 |
| `design/03_落地路線圖.md` | 5 個 Phase 的執行計畫 |
| `design/04_Skill設計規劃.md` | `dev:init-claude` Skill 的設計藍圖 |
| `design/05-07` | 方法論分析、深度檢討、專案協調者研究 |

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
