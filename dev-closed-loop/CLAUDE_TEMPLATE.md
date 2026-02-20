# {{PROJECT_NAME}}

## 語言設定

- 所有互動使用繁體中文
- 程式碼註解使用繁體中文

## 專案配置

- **語言**：{{LANGUAGE}}
- **框架**：{{FRAMEWORK}}
- **測試指令**：`{{TEST_COMMAND}}`
- **建置指令**：`{{BUILD_COMMAND}}`

## ⚠️ 執行約束（最高優先級）

收到任何非微小的任務時，**禁止直接開始寫程式碼**。必須先判定等級再執行對應流程。

### 1. 判定任務等級（必做）

| 等級 | 條件 | 要求的流程 |
|------|------|-----------|
| **微小** | < 50 行 · 單檔修改 · 設定調整 · 用戶說「快速修改」 | 直接執行 |
| **中型** | 新增單一函式/元件 · 1-3 檔案 · < 300 行 | 精簡閉環（設計→實作→驗證） |
| **大型** | 新模組/功能 · (≥ 3 檔案或 ≥ 300 行) 且有多個交互子系統 · 用戶說「完整閉環」 | 完整五階段閉環（Phase 1→5） |

### 2. TaskCreate 拆解（中型 + 大型必做）

**大型任務 — 單模組**：建 5 個 Phase 任務 + blockedBy 鏈：
`[P1-設計] → [P2-實作] → [P3-檢核] → [P4-測試] → [P5-自証]`

**大型任務 — 多模組**：每個模組建 `[P1] → [P2] → [P3] → [P4]` 鏈，有 IF-x 依賴的模組按依賴順序執行（被依賴方先完成 P2）。所有模組完成 P4 後 → 統一 `[P5-整合自証]`（blockedBy 所有 P4）。

**中型任務** — 建 3 個任務 + blockedBy 鏈：
`[設計] 功能名 → [實作] 功能名 → [驗證] 功能名`

**每步上限**：最多 2-3 個檔案或 ~300 行程式碼。

### 3. ⛔ 禁止跳過的閘門

- ⛔ **禁止**沒有設計產出就寫程式碼
- ⛔ **禁止**沒有驗證就標完成
- ⛔ **禁止**單次回應寫完所有檔案

### 4. 逐步執行（必做）

- 按順序，一次只做一個步驟
- 每完成一步，用 TaskUpdate 標記 completed
- blockedBy 未解除前，禁止將該任務設為 in_progress
- **升級機制**：實作過程中若發現實際規模超出當前等級（精簡閉環的檔案數 ≥ 3 或行數 ≥ 300），暫停當前流程，升級為完整閉環（已完成的設計保留為 Phase 1 基礎，從 Phase 2 繼續）

### 5. 可見性（必做）

- **TaskCreate**：觸發閉環時立即建立任務鏈（大型 5 個 / 中型 3 個），讓用戶看到進度
- **Phase 標記**：進入/離開每個 Phase 時輸出 `═══ 📐 Phase 1：架構師 | 開始 ═══` 格式標記
- **Agent 宣告**：調用 Agent 時輸出 `→ 調用 ...`，完成時輸出 `← ... 完成：[摘要]`

---

## 完整閉環（Phase 1-5）

> 大型任務觸發。每個 Phase 的閘門是硬性約束，禁止跳過。

### Phase 1：架構師 📐

**Agent**：需求模糊 → `sc:brainstorm` | 需求明確 → `sc:design` | 複雜系統 → Task `Plan`
**約束**：只產出設計規格，不寫程式碼。BC-x ≥ 2、所有參數有型別、EH-x 覆蓋可預見異常。若涉及跨模組 API → 從 `.claude-loop/interfaces/` 讀取或產出 IF-x 介面契約。涉及 status 變更的 BC-x 必須同時定義「變更後的行為約束」（哪些方法應被禁用、哪些子系統應停止）。
**⛔ 閘門**：參數有型別 ∧ BC ≥ 2 ∧ EH 覆蓋異常 ∧ status 變更有行為約束 → 才能進 Phase 2。

### Phase 2：程序設計師 💻

**Agent**：`sc:implement` | 有計畫 → `superpowers:executing-plans`
**約束**：嚴格按 Phase 1 規格實作。每個 BC-x、EH-x 都要有對應程式碼。覺得設計有問題就回報，不自己改設計。
**增量驗證**：每完成一個檔案後，立即執行 `{{BUILD_COMMAND}}`（或等效 lint 指令）。目的：及早捕獲型別錯誤、未使用 imports、框架 lint 規則違規，避免錯誤累積到 Phase 4 才集中爆發。發現錯誤立即修正再繼續下一個檔案。
**單檔上限**：單一檔案超過 300 行時，必須將邏輯拆分到獨立模組（如 `utils.ts`、`helpers/`），禁止繼續在同一檔案堆積。拆分後各檔案分別通過增量驗證。
**強制優化**：實作完必須調用 Task `code-simplifier`（審查清晰度/一致性/可維護性，不改行為規格）。斷點回退後：修正範圍 < 50 行 → 跳過；≥ 50 行 → 重跑。
**⛔ 閘門**：無語法錯誤 ∧ 設計項都有實作 ∧ code-simplifier 已執行 → 才能進 Phase 3。

### Phase 3：檢核師 🔍

**Agent**：品質 → `sc:analyze --focus quality` 或 Task `superpowers:code-reviewer` | 安全 → Task `security-engineer`。品質與安全審查**可並行**發送，合併 R-x 結果後統一判定斷點 A。
**約束**：拿 Phase 1 規格比對 Phase 2 程式碼。問題標 R-x + 嚴重度（high/medium/low/by-design）。`by-design` 用於刻意的設計取捨，不計入斷點判定。安全檢核不可跳過。**R-x 報告策略**：high/medium 逐一列出；low 級合併為一句摘要（例如「另有 N 個 low 級建議」），不逐一列舉。
**⛔ 斷點 A**：有 high → 禁止進入 Phase 4，回 Phase 2 修正後重跑 Phase 3。

### Phase 4：測試師 🧪

**Agent**：`sc:test` | `superpowers:test-driven-development`
**約束**：每個測試標注 BC-x/EH-x。所有設計項都要有測試。必須用 Bash 依序執行 `{{TEST_COMMAND}}` 和 `{{BUILD_COMMAND}}`（測試驗邏輯，建置驗型別）。
**測試覆蓋要求**：BC-x 每項需覆蓋正常路徑 + 邊界值 + 違規輸入；EH-x 每項需實際觸發錯誤路徑，不僅驗證 guard 存在。
**測試設計原則**：場景足夠大以避免邊界觸發意外行為 | 斷言判行為而非具體值 | 有衍生狀態時同步設定所有關聯欄位 | 涉及即時模擬時優先注入確定性狀態而非依賴全程模擬 | 有級聯副作用的操作需精確控制測試中的操作順序。
**⛔ 斷點 B**：有測試或建置失敗 → 禁止進入 Phase 5，先判定原因：
- 程式碼 bug → 回 Phase 2 修正 → 重跑 Phase 3 + 4
- 測試設計問題（場景/斷言/前置條件有誤）→ 回 Phase 4 修正測試 → 通過即進 Phase 5

### Phase 5：自証師 ✅

**Agent**：先跑自証檢查表 → `sc:reflect --type completion`（可選）→ `superpowers:verification-before-completion`（可選）

**自証（三段式，必須逐一執行）**：
> 多模組任務：自証涵蓋所有模組的設計項、程式碼和測試。步驟 8 的全專案回歸測試為必做。

**Part A — 追溯檢查表**（設計 → 實作 → 測試）：
1. 從 Phase 1 列出所有 BC-x、EH-x、IF-x（若有）→ **基準清單**
2. 逐一確認 Phase 2 有對應實作（✅/❌）。IF-x 需確認函式簽名與契約一致
3. 逐一確認 Phase 4 有對應測試（✅/❌）
4. Phase 3 的 high/medium R-x 是否已修（✅/❌）
5. 四份產出物是否完整（設計規格/程式碼/檢核報告/測試報告）

**Part B — 反向分析**（程式碼 → 設計）：
6. 閱讀 Phase 2 程式碼，找出不被任何 BC-x/EH-x 覆蓋的行為路徑。有 → 判定是遺漏設計（回 P1 補）還是多餘程式碼（移除）
7. 挑最複雜的 2-3 個 BC-x，沿程式碼追蹤執行路徑，驗證行為與設計意圖一致

**Part C — 整體評估**：
8. 變更是否可能影響範圍外的現有功能 → 有風險則跑全專案 `{{TEST_COMMAND}}` + `{{BUILD_COMMAND}}`
9. 全 ✅ → 通過；有 ❌ → 不通過 + 回退建議

**回退規則**：設計-實作不一致 → P2（嚴重→P1）| 測試不足 → P4 | 檢核未修 → P2 | 產出物缺漏 → 對應 Phase
**通過後**：若專案有多模組，跑全專案 `{{TEST_COMMAND}}` + `{{BUILD_COMMAND}}` 確認 0 回歸。commit，message 帶自証摘要。

---

## 精簡閉環（中型任務）

> 中型任務觸發。設計→實作→驗證 三步流程。

**步驟 1 — 設計**：簡要設計規格（目標 | 主要函式簽名與參數型別 | BC-x ≥ 1 | EH-x 覆蓋主要異常）。
**步驟 2 — 實作**：按設計實作。每完成一個檔案立即執行 `{{BUILD_COMMAND}}` 驗證，發現錯誤當場修正。單檔超過 300 行須拆分。全部完成後調用 Task `code-simplifier` 優化。
**步驟 3 — 驗證**：
- 確認每個 BC-x/EH-x 有對應實作和測試
- 用 Bash 執行 `{{TEST_COMMAND}}` + `{{BUILD_COMMAND}}`
- 全通過 → commit；失敗 → 回步驟 2 修正

---

## 產出物格式

進入需要產出的 Phase 時，讀取 `.claudedocs/standards/產出物格式.md` 取得完整模板。

**ID 編號系統**：

| 前綴 | 含義 | 使用階段 |
|------|------|---------|
| BC-x | 邊界條件 | Phase 1 定義 → Phase 2, 4, 5 引用 |
| EH-x | 錯誤處理 | Phase 1 定義 → Phase 2, 4, 5 引用 |
| R-x | 檢核問題 | Phase 3 定義 → Phase 5 引用 |
| IF-x | 介面契約 | 跨模組時定義 → Phase 1, 2, 5 引用 |
| CR-x | 變更請求 | 介面變更時建立 → 受影響模組引用 |

---

## 跨 Session 持久化

**觸發條件**：模組數 ≥ 3 且有跨模組依賴 | 預計多 Session | 用戶說「啟用持久化」
**輕量持久化**：大型任務的 Phase 1 設計規格（BC-x/EH-x 清單）建議寫入 `.claude-loop/modules/{name}/design-spec.md`，即使未啟用完整持久化，避免 context 壓縮導致設計意圖丟失。
**機制**：產出物寫入 `.claude-loop/` 目錄，新 Session 從檔案恢復狀態。
詳細目錄結構與操作規則：[跨 Session 持久化](.claudedocs/process/跨Session持久化.md) | [介面契約與變更管理](.claudedocs/process/介面契約與變更管理.md)

## 跨時間語義記憶（claude-mem · 可選）

若 `mcp__plugin_claude-mem_mcp-search__search` 工具可用，啟用以下規則。不可用則跳過，不影響閉環運作。

- **Phase 1 前**：`search({ query: "[任務關鍵詞]", project: "{{PROJECT_NAME}}", limit: 5 })`，查詢相關歷史決策和教訓作為設計參考
- **Phase 5 通過後**：`save_memory({ text: "[架構決策/關鍵教訓摘要]", project: "{{PROJECT_NAME}}" })`，保存值得跨任務記住的經驗
- **斷點回退時**：`save_memory({ text: "斷點[A/B]：[錯誤原因和教訓]", project: "{{PROJECT_NAME}}" })`，記錄踩坑經驗避免重蹈覆轍
- **保存原則**：存「為什麼這樣做」而非「做了什麼」；存「下次要避免什麼」而非「這次出了什麼錯」

---

## 工作規範

- **Git**：自証通過後 commit（message 帶自証摘要）| 風險修改前先 commit | 大功能用分支 | 斷點觸發時先 commit 標 `[斷點X]`
- **品質**：跟專案慣例 | BC-x/EH-x 100% 測試覆蓋 | 外部輸入必驗證 | 敏感資料不寫死
- **文檔**：放 `.claudedocs/`、白話文、修訂不新增、專業眼光不討好
- **問題追蹤**：Bug 和踩坑記到 `.claudedocs/records/問題追蹤.md`

## 參考文檔

| 文檔 | Claude 何時讀取 |
|------|---------------|
| [產出物格式](.claudedocs/standards/產出物格式.md) | **進入 Phase 1/3/4/5 時必讀**（取得產出物模板） |
| [Agent 使用指南](.claudedocs/standards/Agent使用指南.md) | 想了解 Agent 選擇邏輯和配合方式時 |
| [五階段流程](.claudedocs/process/五階段閉環流程.md) | 需要更多 Phase 細節時 |
| [跨 Session 持久化](.claudedocs/process/跨Session持久化.md) | 啟用持久化時 |
| [介面契約與變更管理](.claudedocs/process/介面契約與變更管理.md) | 跨模組開發時 |

## 前置需求

本閉環依賴以下工具，部署前請確認已安裝：

| 工具 | 用途 | 安裝方式 |
|------|------|---------|
| **SuperClaude** | `sc:*` 系列 Skills（Phase 1-5 主要調用） | `pipx install superclaude && superclaude install` |
| **Superpowers** | `superpowers:*` 系列 Skills（Phase 2-5 補充） | Claude Code 插件：`superpowers@claude-plugins-official` |
| **claude-mem** _(可選)_ | 跨時間語義記憶（Phase 前查詢歷史、Phase 後保存經驗） | Claude Code 插件：`claude-mem` |

> Task agent（`code-simplifier`、`security-engineer` 等）是 Claude Code 內建功能，無需額外安裝。

## 驗證紀錄

| 輪次 | 專案 | 測試目標 | 結果 | 發現與修正 |
|------|------|---------|------|-----------|
| — | — | — | — | （在此追加每次驗證的結果） |

## 📖 補充文檔

`.claudedocs/` 目錄含 10 份文檔，給想深入了解閉環方法論的人看。閱讀順序見 [.claudedocs/README.md](.claudedocs/README.md)。

<!--
部署說明：
1. 複製 CLAUDE_TEMPLATE.md + .claudedocs/ 到專案根目錄
2. CLAUDE_TEMPLATE.md 重新命名為 CLAUDE.md
3. 替換所有 {{PLACEHOLDER}} 為實際值：
   {{PROJECT_NAME}} {{LANGUAGE}} {{FRAMEWORK}} {{TEST_COMMAND}} {{BUILD_COMMAND}}
4. Claude Code 會自動讀取並遵循閉環調度規則
-->
