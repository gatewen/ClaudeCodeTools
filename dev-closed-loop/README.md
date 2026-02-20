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

1. 複製 `CLAUDE_TEMPLATE.md` + `.claudedocs/` 到專案根目錄
2. 把 `CLAUDE_TEMPLATE.md` 重新命名為 `CLAUDE.md`
3. 替換所有 `{{PLACEHOLDER}}` 為專案的實際值
4. Claude Code 啟動後會自動讀取並遵循閉環流程

或先執行 `bash setup.sh`（安裝 Skill），之後在任何專案目錄執行 `/dev:init-claude` 一鍵完成以上步驟。

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
└── records/
    └── 問題追蹤.md           ← 遇到問題怎麼記錄
```

## 閱讀建議

- 想**了解背景**：從 `design/01_原始構想` → `design/02_深度分析` → `design/03_落地路線圖` 讀
- 想**直接用**：從 `CLAUDE_TEMPLATE.md` 開始，搭配 `.claudedocs/` 裡的文檔
- 想**看閱讀順序**：看 `.claudedocs/README.md`

## 版本歷史

| 版本 | 重點 |
|------|------|
| v4.0 | Gen 3 重寫（601→185 行）+ GameBox 4 輪壓測改進（增量驗證、單檔上限、升級機制、並行審查、斷點 B 分支判定） |
| v3.5 | 跨 Session 持久化 (v1) + IF-x/CR-x 介面契約 (v2) + claude-mem 語義記憶 |
| v3.4 | 遷移至獨立 Git repo，setup.sh 一鍵部署，消除路徑依賴 |
| v3.3 | 前置需求區塊 + Step 0 環境依賴檢查 |
| v3.2 | `/dev:init-claude` Skill（自動偵測 + 互動確認 + 模板填充） |
| v3.1 | Phase 2 出口加入 code-simplifier 強制優化 |
| v3.0 | 產出物格式嵌入 CLAUDE.md + 6 步自証檢查表 + SkillsMP |
