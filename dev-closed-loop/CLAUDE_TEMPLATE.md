# {{PROJECT_NAME}}

## 語言設定

- 所有互動使用繁體中文
- 程式碼註解使用繁體中文

## 專案配置

- **語言**：{{LANGUAGE}}
- **框架**：{{FRAMEWORK}}
- **測試指令**：`{{TEST_COMMAND}}`
- **建置指令**：`{{BUILD_COMMAND}}`

## ⚠️ 開發設計閉環（必須遵守）

本檔案包含 Claude 執行閉環所需的**所有資訊**。不需要讀取其他檔案就能跑完整流程。
`.claudedocs/` 目錄是給人類閱讀的補充文檔，不影響閉環執行。

所有非微小的程式碼變更，都要走五階段閉環流程。
只有自証通過，這段程式碼才算完成。

**觸發條件**：新增函式/類別/模組、重構 ≥ 3 個函式、安全相關程式碼、用戶說「完整閉環」
**跳過條件**：1-3 行 bug 修正、註解/設定微調、純文件更新、用戶說「快速修改」

人類補充閱讀：[閉環核心理念](.claudedocs/concepts/閉環核心理念.md) | [五階段閉環流程](.claudedocs/process/五階段閉環流程.md)

### 前置需求

本閉環依賴以下工具。部署前請確認已安裝，否則部分 Phase 的 Agent 調用會失敗。

| 工具 | 用途 | 安裝方式 |
|------|------|---------|
| **SuperClaude** | 提供 `sc:*` 系列 Skills（Phase 1-5 主要調用） | `pipx install superclaude && superclaude install` — [安裝說明](https://github.com/SuperClaude-Org/SuperClaude_Framework) |
| **Superpowers** | 提供 `superpowers:*` 系列 Skills（Phase 2-5 補充調用） | Claude Code 插件市場：`superpowers@claude-plugins-official` |

> Task agent（`code-simplifier`、`system-architect` 等）是 Claude Code 內建功能，無需額外安裝。

---

## 閉環調度規則

每個 Phase 調用指定的 Agent 來執行。Agent 有自己的預設行為，但在閉環中必須服從以下約束。
約束是硬性規則，Agent 的預設行為不得覆蓋。

### 閉環可見性規則（所有 Phase 通用）

閉環執行時，用戶必須能清楚知道**目前在哪個 Phase、誰在處理、進度如何**。以下規則強制執行。

**1. 進度追蹤（TaskCreate）**

觸發閉環時，立即用 TaskCreate 建立 5 個任務，讓用戶在狀態列看到整體進度：

```
TaskCreate: "Phase 1：架構師 — 設計規格"        activeForm: "📐 設計中..."
TaskCreate: "Phase 2：程序設計師 — 實作 + 優化"   activeForm: "💻 實作中..."
TaskCreate: "Phase 3：檢核師 — 檢核報告"         activeForm: "🔍 檢核中..."
TaskCreate: "Phase 4：測試師 — 測試報告"         activeForm: "🧪 測試中..."
TaskCreate: "Phase 5：自証師 — 自証結果"         activeForm: "✅ 自証中..."
```

進入每個 Phase 時，用 TaskUpdate 標記 `in_progress`。
完成時標記 `completed`。斷點回退時在 description 補充回退原因。

**2. Phase 進出標記**

進入任何 Phase 時，輸出：

```
═══════════════════════════════════════
📐 Phase 1：架構師 | 開始
  目標：產出設計規格
═══════════════════════════════════════
```

離開任何 Phase 時，輸出：

```
═══════════════════════════════════════
📐 Phase 1：架構師 | 完成 ✅
  產出：設計規格（BC-1~BC-3, EH-1~EH-2）
═══════════════════════════════════════
```

若 Phase 失敗或觸發斷點：

```
═══════════════════════════════════════
🔍 Phase 3：檢核師 | ⚠️ 斷點 A 觸發
  原因：R-1 (high) 未修正
  下一步：回到 Phase 2 修正
═══════════════════════════════════════
```

**3. Agent 調用宣告**

每次調用 Agent 時，輸出一行宣告：

```
→ 調用 Skill: sc:design（需求明確，直接做技術設計）
→ 調用 Task agent: code-simplifier（強制程式碼優化）
→ 調用 Task agent: security-engineer + code-reviewer（平行執行檢核）
```

Task agent 完成時，輸出結果摘要：

```
← code-simplifier 完成：優化了 3 個函式，無功能行為變更
← security-engineer 完成：無安全問題
← code-reviewer 完成：發現 2 個問題（R-1 high, R-2 medium）
```

### Phase 1：架構師 📐

**調用方式（擇一）**：
- 需求模糊 → 先調用 Skill `sc:brainstorm` 或 `superpowers:brainstorming` 釐清需求
- 需求明確 → 調用 Skill `sc:design` 做技術設計
- 複雜系統 → 調用 Task agent `system-architect` 或 `Plan` 做架構規劃

**約束（Agent 必須遵守）**：
- 只產出設計規格，不寫實作程式碼
- 邊界條件用 BC-1、BC-2 編號，錯誤處理用 EH-1、EH-2 編號
- 至少 2 個邊界條件、所有參數有型別定義

**必須產出**：設計規格（格式見下方「產出物格式」章節）
**進入 Phase 2 的條件**：參數有型別 ∧ 邊界條件 ≥ 2 ∧ 錯誤處理覆蓋可預見異常

### Phase 2：程序設計師 💻

**調用方式（擇一）**：
- 一般實作 → 調用 Skill `sc:implement`
- 有完整計畫 → 調用 Skill `superpowers:executing-plans`
- 後端 → 可搭配 Task agent `backend-architect`
- 前端 → 可搭配 Task agent `frontend-architect`
- Python → 可搭配 Task agent `python-expert`

**約束（Agent 必須遵守）**：
- 嚴格按照 Phase 1 的設計規格實作，不自行增加功能
- 設計規格的每個 BC-x 和 EH-x 都必須有對應實作
- 覺得設計有問題就回報，不要自己改設計

**必須產出**：可執行的程式碼

**🔧 強制程式碼優化（進入 Phase 3 前必須執行）**：

實作完成後，**必須**調用 Task agent `code-simplifier` 對所有新增和修改的程式碼進行優化。
這一步不能跳過，除非用戶明確說「保留原始碼」或「不要優化」。

調用 `code-simplifier` 時的嚴格規則：
1. **禁止照搬舊碼**：AI 產生的程式碼不能原樣複製舊程式碼。即使邏輯相同，也必須審視是否有更簡潔的寫法
2. **三個面向必須審查**：
   - **Clarity（清晰度）**：命名是否表意、邏輯是否一目了然
   - **Consistency（一致性）**：風格是否跟專案慣例一致
   - **Maintainability（可維護性）**：有沒有不必要的複雜度、能不能更簡單
3. **優化不等於改設計**：code-simplifier 只能簡化實作方式，不能改變 Phase 1 定義的行為規格
4. **唯一例外**：用戶明確指定「保留原始碼」「不要優化」「照搬就好」時可跳過

**進入 Phase 3 的條件**：無語法錯誤 ∧ 每個設計項目有對應實作 ∧ code-simplifier 已執行完畢

### Phase 3：檢核師 🔍

**調用方式（擇一）**：
- 標準檢核 → 調用 Skill `sc:analyze --focus quality`
- 正式 code review → 調用 Task agent `superpowers:code-reviewer`
- 安全面向 → 額外調用 Task agent `security-engineer`
- 程式碼品質 → 額外調用 Task agent `superpowers:code-reviewer`

**約束（Agent 必須遵守）**：
- 必須拿 Phase 1 的設計規格跟 Phase 2 的程式碼做比對，不是只看程式碼本身
- 問題標嚴重度：high（必修）/ medium（建議修）/ low（記錄）
- 每個問題用 R-1、R-2 編號
- 安全檢核不能跳過：輸入驗證、注入風險、敏感資料

**必須產出**：檢核報告（格式見下方「產出物格式」章節）
**⚠️ 斷點 A**：有 high 問題 → 回到 Phase 2 修正 → 修完重跑 Phase 3

### Phase 4：測試師 🧪

**調用方式（擇一）**：
- 標準測試 → 調用 Skill `sc:test`
- TDD 流程 → 調用 Skill `superpowers:test-driven-development`
- 完整品質策略 → 調用 Task agent `quality-engineer`
- 前端 E2E → 搭配 Playwright MCP

**約束（Agent 必須遵守）**：
- 每個測試案例必須標注對應的設計規格 ID（BC-x 或 EH-x）
- 設計規格的每個 BC-x 和 EH-x 都必須有對應測試
- 必須用 Bash 實際執行上方「專案配置」中的測試指令，不能只寫測試不跑

**必須產出**：測試程式碼 + 測試報告（格式見下方「產出物格式」章節）
**⚠️ 斷點 B**：有測試失敗 → 回到 Phase 2 修正 → 重跑 Phase 3 和 Phase 4

### Phase 5：自証師 ✅

**調用方式（依序執行）**：
1. 先執行下方的「自証檢查表」（這是核心步驟，不能跳過）
2. 調用 Skill `sc:reflect --type completion` — 補充評估完成度
3. 調用 Skill `superpowers:verification-before-completion` — 最終驗證

**約束（Agent 必須遵守）**：
- 自証不是重新測試，不是重新跑程式碼。是比對 Phase 1-4 的產出物之間有沒有矛盾
- 必須逐一執行下方檢查表的每一步，不能跳步
- 比對時用 BC-x、EH-x、R-x 編號做精確追溯

**自証檢查表（6 步，必須逐一執行）**：

```
步驟 1：建立基準清單
  從 Phase 1 的設計規格中，列出所有 BC-x 和 EH-x 的 ID
  這就是「基準清單」，後面所有比對都以此為準

步驟 2：設計-實作一致性
  對照基準清單，逐一確認 Phase 2 的程式碼中有沒有對應實作
  每個 ID 標注：✅ 有實作 / ❌ 缺漏（記錄具體缺了什麼）

步驟 3：實作-測試覆蓋
  對照基準清單，逐一確認 Phase 4 的測試中有沒有對應測試案例
  每個 ID 標注：✅ 有測試 / ❌ 缺漏（記錄哪個 ID 沒測到）

步驟 4：檢核-修正閉合
  從 Phase 3 的檢核報告中，列出所有 high 和 medium 的 R-x
  逐一確認是否已修正（status = resolved）
  每個 R-x 標注：✅ 已修 / ❌ 未修

步驟 5：產出物完整性
  確認四份產出物都存在：
  設計規格 ✅/❌ | 程式碼 ✅/❌ | 檢核報告 ✅/❌ | 測試報告 ✅/❌

步驟 6：產出自証結果
  用下方「自証結果」格式輸出
  四個維度全 ✅ → 判定通過
  任何一個 ❌ → 判定不通過，附回退建議
```

**回退規則**：
- 設計-實作不一致 → Phase 2（嚴重的話 Phase 1）
- 測試覆蓋不足 → Phase 4
- 檢核問題未修正 → Phase 2
- 產出物缺漏 → 缺漏的 Phase

**自証通過後**：用 `/sc:git` 或直接 commit，message 帶上自証摘要

---

## 產出物格式

每個 Phase 的產出物都有固定格式和 ID 編號。自証師靠這些 ID 做交叉比對。
格式不統一，自証就做不了。所以**必須**按以下格式產出。

### ID 編號系統

| 前綴 | 含義 | 使用階段 |
|------|------|---------|
| BC-1, BC-2... | 邊界條件（Boundary Condition） | Phase 1 定義 → Phase 2, 4, 5 引用 |
| EH-1, EH-2... | 錯誤處理（Error Handling） | Phase 1 定義 → Phase 2, 4, 5 引用 |
| R-1, R-2... | 檢核問題（Review finding） | Phase 3 定義 → Phase 5 引用 |

### 設計規格（Phase 1 產出）

```markdown
## 📐 設計規格

### 目標
[一句話說明這段程式碼要解決什麼問題]

### 函式簽名
- 名稱：[函式名]
- 參數：

| 名稱 | 型別 | 約束條件 | 必填 |
|------|------|---------|------|

- 回傳值：

| 型別 | 說明 |
|------|------|

### 邊界條件

| ID | 條件描述 | 預期行為 |
|----|---------|---------|
| BC-1 | [例：輸入為空字串] | [例：回傳預設值] |
| BC-2 | [例：數字超過上限] | [例：拋出 RangeError] |

### 錯誤處理

| ID | 錯誤類型 | 處理方式 |
|----|---------|---------|
| EH-1 | [例：網路逾時] | [例：重試 3 次後拋出錯誤] |
| EH-2 | [例：檔案不存在] | [例：回傳 null 並記錄 warning] |

### 設計決策
[為什麼這樣設計，排除了什麼替代方案]
```

### 檢核報告（Phase 3 產出）

```markdown
## 🔍 檢核報告

- 檢核對象：[函式/模組名稱]
- 檢核時間：[YYYY-MM-DD HH:MM]

| ID | 嚴重度 | 位置 | 問題描述 | 建議修正 | 狀態 |
|----|--------|------|---------|---------|------|
| R-1 | high | [檔案:行數] | [問題是什麼] | [建議怎麼改] | open/resolved |
| R-2 | medium | [檔案:行數] | [問題是什麼] | [建議怎麼改] | open/resolved |

嚴重度定義：
- high：邏輯錯誤、安全漏洞、跟設計規格不符 → 必修
- medium：品質問題、可維護性風險 → 建議修
- low：風格建議、微小改進 → 記錄
```

### 測試報告（Phase 4 產出）

```markdown
## 🧪 測試報告

- 測試對象：[函式/模組名稱]
- 測試時間：[YYYY-MM-DD HH:MM]
- 邊界條件覆蓋：X / Y
- 錯誤處理覆蓋：X / Y

| 測試名稱 | 對應規格 ID | 結果 | 說明 |
|---------|------------|------|------|
| [test_empty_input] | BC-1 | pass/fail | [補充說明] |
| [test_overflow] | BC-2 | pass/fail | [補充說明] |
| [test_network_timeout] | EH-1 | pass/fail | [補充說明] |
| [test_happy_path] | — | pass/fail | [正常路徑測試] |
```

「對應規格 ID」欄位是自証比對的關鍵——用來確認設計規格的每個 ID 都有被測到。

### 自証結果（Phase 5 產出）

```markdown
## ✅ 自証結果

- 自証對象：[函式/模組名稱]
- 自証時間：[YYYY-MM-DD HH:MM]
- **判定：通過 / 不通過**

| 維度 | 狀態 | 證據 | 缺口描述 |
|------|------|------|---------|
| 設計-實作一致性 | ✅/❌ | [例：BC-1, BC-2, EH-1, EH-2 均有對應實作] | [若有缺口寫這裡] |
| 實作-測試覆蓋 | ✅/❌ | [例：邊界條件 2/2、錯誤處理 2/2] | [若有缺口寫這裡] |
| 檢核-修正閉合 | ✅/❌ | [例：R-1(high) 已修正、無未處理問題] | [若有缺口寫這裡] |
| 產出物完整性 | ✅/❌ | [例：設計規格 ✅ 程式碼 ✅ 檢核報告 ✅ 測試報告 ✅] | [若有缺口寫這裡] |

（若不通過）
### 回退建議
- 回退目標：Phase X
- 原因：[具體說明哪裡不一致]
- 修正方向：[建議怎麼修]
```

---

## 跨 Phase 的調度補充

### 遇到問題時

| 情境          | 調用                                                                   | 說明                  |
| ----------- | -------------------------------------------------------------------- | ------------------- |
| 斷點觸發，需要找根因  | `superpowers:systematic-debugging` 或 Task agent `root-cause-analyst` | 先找到原因再回退修正          |
| 回退修正後要改善程式碼 | `sc:improve` 或 Task agent `refactoring-expert`                       | 不只修 bug，順便改善品質      |
| 多個函式要同時閉環   | `superpowers:dispatching-parallel-agents` 或 `sc:spawn`               | 獨立的函式可以平行處理         |
| 閉環完成要收分支    | `superpowers:finishing-a-development-branch`                         | 處理 merge/PR/cleanup |

### Agent 調用的優先順序

同一個 Phase 有多個 Agent 可選時，按這個順序決定：

1. **Skill（sc: 系列）** — 優先用，因為在當前對話中執行，能保持完整上下文
2. **Skill（superpowers: 系列）** — 次選，提供更專門化的流程
3. **Task agent** — 用於可獨立執行的子任務（code review、安全掃描等）

用 Task agent 的時候，prompt 裡要帶上閉環的約束和前面 Phase 的產出物。

### 外部 Skills 資源

如果內建的 Agent 不夠用，可以到 [SkillsMP](https://skillsmp.com/) 搜尋社群 Skills。
以下是各 Phase 推薦搜尋的分類和關鍵字：

| Phase | 推薦搜尋 | 參考 Skills |
|-------|---------|------------|
| Phase 1 架構 | `architecture`, `project-planner`, `adr` | planning-architect, roadmap-generator |
| Phase 2 實作 | 搜尋對應語言的 skill | 語言特定的 best practices skills |
| Phase 3 檢核 | `code-review`, `security` | code-review-excellence, secure-code-guardian |
| Phase 4 測試 | `testing`, `test-generation` | test-master, frontend-testing |
| Phase 5 自証 | 無直接對應（自証是本閉環獨有概念） | — |

**安全警告**：SkillsMP 是社群專案，非 Anthropic 官方。據調查約 26% 的 skills 含有潛在漏洞。
使用前務必：
1. 優先選擇 GitHub 星級 ≥ 10 的 skill
2. 閱讀 skill 原始碼，確認沒有危險操作（如任意 bash 執行）
3. 在非正式環境先測試再引入專案

詳細的 Skills 選擇指南和推薦清單：[Agent 使用指南](.claudedocs/standards/Agent使用指南.md#外部-skills-資源)

---

## Git 工作規範

- 每完成一個閉環（自証通過後），做一次 commit
- 有風險的修改，先 commit 保存現狀再動手
- 大功能用分支隔離，不要直接在主線改
- commit message 帶上自証結果摘要
- 斷點觸發回退時：先 commit 當前狀態（message 標 `[斷點X]`），再開始修正
- 詳細規則：[Git 工作流](.claudedocs/standards/Git工作流.md)

## 問題追蹤

開發中遇到的 Bug、技術踩坑、解法，都要記到 `.claudedocs/records/問題追蹤.md`。
記錄要有時間、問題描述、怎麼修的。

## 文檔管理規則

- 所有技術文檔放 `.claudedocs/`，按分類放好
- 白話文撰寫，看得懂最重要
- 已有的文檔修訂補充，不要一直生新的
- 不在意 token 消耗，專注最優解決方案
- 評價用專業眼光，不要討好式回應

## 品質標準

- 程式碼風格：跟專案慣例走
- 測試覆蓋：設計規格的 BC-x 和 EH-x 必須 100% 覆蓋
- 安全性：外部輸入必須驗證，敏感資料不能寫死
- 產出物格式：必須遵守上方「產出物格式」章節的格式

## 📖 補充文檔（給人類閱讀）

以下是 `.claudedocs/` 裡的文檔，給想深入了解閉環方法論的人看。
Claude 執行閉環不需要讀這些——所有必要資訊已在上方。

| 順序  | 文檔                                        | 你會學到什麼              |
| --- | ----------------------------------------- | ------------------- |
| 1   | [閉環核心理念](.claudedocs/concepts/閉環核心理念.md)        | 這套方法在幹嘛、為什麼有用       |
| 2   | [五階段閉環流程](.claudedocs/process/五階段閉環流程.md)      | 實際怎麼跑，每個階段做什麼       |
| 3   | [Agent 使用指南](.claudedocs/standards/Agent使用指南.md) | 每個 Agent 的詳細說明和選擇邏輯 |
| 4   | [產出物格式](.claudedocs/standards/產出物格式.md)          | 格式的完整說明和 ID 編號系統    |
| 5   | [層級擴展](.claudedocs/process/層級擴展.md)            | 從函式到模組到框架怎麼串        |
| 6   | [Git 工作流](.claudedocs/standards/Git工作流.md)       | 閉環跟 Git 怎麼配合        |
| 7   | [問題追蹤](.claudedocs/records/問題追蹤.md)            | 遇到問題怎麼記錄            |

<!--
使用方式：
1. 複製 CLAUDE_TEMPLATE.md + .claudedocs/ 到專案根目錄
2. CLAUDE_TEMPLATE.md 重新命名為 CLAUDE.md
3. 替換所有 {{PLACEHOLDER}} 為實際值
4. Claude Code 會自動讀取並遵循閉環調度規則
-->
