# v6.0.0 P1 設計規格（v2 — DR 修正後）

> Phase 1 架構師產出（inline agent · 主 agent 直接執行）
> 日期：2026-04-26
> Branch：feature/v6.0.0-karpathy
> 上游文件：dev-closed-loop/design/08-v6.0.0-karpathy-integration.md
> 下游消費者：Phase 1b design-reviewer / Phase 2 implementer / Phase 3 一致性審查 / Phase 5 verifier
> Scope：v6.0.0 milestone（5 條 K-x：K-09 / K-15 / K-01 / K-17 / K-04）
> **修正歷史**：v1（初稿）→ P1b 第 1 輪 1 high / 2 arch-risk / 3 medium / 1 low → v2 採用全 7 條修正 → P1b 第 2 輪 0 high / 0 arch-risk / 2 medium / 1 low → **v3 採用 medium + low 修正（DR-1v2 / DR-2v2 / DR-3v2）**

---

## 0 學習查詢結果

| 來源 | 結果 |
|------|------|
| 問題追蹤「長期警惕模式」 | **命中 [#003]**（單線索→事實，已透過「Karpathy 原文 vs 延伸」分類緩解過度歸因）；**[#004, #005] 不適用**（純文檔升級無 config / 環境事實處理） |
| `.claude-loop/learning-log.md` | 不存在（本 repo 首次啟動閉環，無短期事件記錄） |

**緩解措施**：design/08 已透過「Karpathy 原文（A 級字面證據）vs 本專案延伸（B 級推論）」分類，預先處理 #003 過度歸因風險。本 P1 規格遵守此分類，不引入新推論。#004（忽視字面證據）與 #005（共用值私有化）涉及 config / 環境事實處理，本任務（純文檔升級）不適用。

**Step 0a 字面證據掃描**：`不適用`——v6.0.0 不涉及讀取未知 config / legacy 程式碼推論環境事實。Karpathy 來源已在 design/08 做完字面證據分類。

**Step 0b 共用值檢測**：`不適用`——無 config 處理。

**Step 0c 模組資產查詢**：`不適用`——本 repo 無 `module-registry.md`。

---

## 1 架構體質拆解

### 1.1 現有結構（v5.23.1）

| 層 | 內容 |
|----|------|
| 主入口 | `CLAUDE_TEMPLATE.md`（444 行，Section 1-13 + Phase 1-5 完整閉環 / 精簡閉環 / 微小直通） |
| 文檔層 | `.claudedocs/`（10 核心 + 9 agent + 語言指南） |
| Skill 層 | `skill/init-claude.md`（部署 / status / upgrade flow） |
| Hook 層 | `hooks/`（6 個 Hook 腳本：修改前守衛 / 委派閘門 / 理解確認 / 增量 lint / 委派追蹤 / 學習日誌） |

### 1.2 假設驗證

| v5.x 假設 | v6.0.0 驗證結果 |
|-----------|---------------|
| Karpathy 4 原則切片到 Phase 即足夠 | **不成立**——切片導致 Phase 2-5 不再被要求 Think Before Coding 等 cross-cutting 精神。需橫切層（Section 0）。 |
| 既有閘門（Section 9-13）已涵蓋所有 LLM 失誤類型 | **部分成立**——Section 9-13 處理「假設驗證」與「事實驗證」，但缺「主動反對用戶」維度（push back）。 |
| Skill 層 init-claude.md 的 upgrade flow 可承擔結構變更 | **需擴充**——v6.0.0 是首次新增頂層 Section（0 + 12.5），需要 metadata 解耦機制（IF-1）。 |

### 1.3 多餘識別

無。`K-12 閉環 Lite` 已在 design/08 規劃階段移除（Q4 用戶確認）。

### 1.4 地基評估

v5.x 的 Section 9-13 認知驗證層支撐得住新增 Section 0 + 12.5。風險：
- **RISK-2** 行數膨脹（v5.23.1 444 行 → v6.0.0 ≤ 550 行，含 P2 瘦身要求）—— DR-3 修正後預算更嚴
- **RISK-1** 已部署專案 migration（K-17 / BC-4/5/6 處理）

兩風險均已有緩解機制，地基判定為**穩固**。

---

## 2 分層結構聲明

| 層 | 內容 | 依賴方向 |
|----|------|---------|
| 方法論文檔層（純功能） | `CLAUDE_TEMPLATE.md` · `.claudedocs/concepts/` · `.claudedocs/standards/` · `.claudedocs/agents/` · `.claudedocs/process/` | 不依賴其他 |
| Skill 部署層（純功能） | `skill/init-claude.md` · `setup.sh` · `deploy-hooks.sh` · `check-version.sh` | 透過 IF-1（metadata）讀方法論文檔層 |
| README 對外層（純功能） | 根 `README.md` · `dev-closed-loop/README.md` | 不依賴其他（單向發佈） |

**硬規則**：Skill 層**不可內嵌方法論內容**。所有版本/結構資訊須透過 metadata（如 IF-1 migration-notes）解耦。

---

## 3 邊界條件（BC-x）

> **DR-5 修正**：原 BC-4（Migration K-17）拆為 BC-4 / BC-5 / BC-6 三個獨立 ID；原 BC-5（Push back K-04）改 BC-7。Phase 5 雙向追溯時各 BC-x 一一對應 K-x.partN，無混淆。

### BC-1 [testable]：Trade-off 顯式宣告（K-09）

**位置**：`CLAUDE_TEMPLATE.md` 開頭（在 Section 1「執行約束」之前）

**內容結構**：
```markdown
## ⚖️ Trade-off 顯式宣告

本方法論偏向**正確性與可追溯性 > 速度**。代價與收益：

代價：
- 微小任務原本 1 分鐘的工作不會走閉環（Section 1 分級保護）
- 中型任務多花 ~30% 時間在設計與審查
- 大型任務多花 ~50-80% 時間在設計、審查、自證

收益：
- 跨產出物矛盾在 commit 前被攔截（Phase 5 自證）
- 設計缺陷在實作前被攔截（Phase 1b 設計審查）
- 失敗模式累積成「長期警惕模式」，下次自動避開
- 認知性誤判（事實前提錯誤）有三層防禦
- LLM 對用戶的義務明確（Section 0 / 12.5，v6.0.0 新增）

不適用情境：
- 拋棄式 prototype（不會留下來的代碼）
- 純探索性實驗（目標還在演化）
- 緊急 hotfix（時間 > 完備性，但須補 learning-log）
```

**行數限制**：≤ 30 行

**同步檔案**：`dev-closed-loop/README.md`（在「這是什麼」之前或之後新增 Trade-off 段，內容語氣調整為對外讀者）

**驗收**：Grep `⚖️ Trade-off 顯式宣告` 在 CLAUDE_TEMPLATE 命中 1 次；dev-closed-loop/README 含對應段落。

---

### BC-2 [testable]：README Karpathy 引用問題陳述（K-15）

**位置**：根 `README.md` 開頭（在「這是什麼」段之前），dev-closed-loop/README.md 同步

**內容結構**（根 README）：
```markdown
## LLM 編碼的根本問題

[Andrej Karpathy 觀察](https://x.com/karpathy/status/2015883857489522876)：

> "The models make wrong assumptions on your behalf and just run along with them without checking. They overcomplicate code and APIs. They sometimes change/remove comments and code they don't sufficiently understand as side effects."

本專案發現的進階問題：
- **跨產出物矛盾**：設計說 5 種錯誤、實作 3 種、測試 2 種——傳統 Code Review 抓不到。
- **認知前提誤判**：基於單一線索就斷言為事實（GS 誤判事件，問題追蹤 #003-#005）。

本工具包是針對這兩層問題的解法：Karpathy 4 原則處理「行為紀律」，閉環方法論處理「跨產出物驗證」。
```

**行數限制**：≤ 25 行

**驗收**：Grep `LLM 編碼的根本問題` 在根 README 與 dev-closed-loop/README 各命中 1 次；URL `karpathy.com/status/2015883857489522876` 命中。

---

### BC-3 [testable]：四原則 cross-cutting 自檢層 — Section 0（K-01）

**位置**：`CLAUDE_TEMPLATE.md` 在 Section 1「執行約束（最高優先級）」之前新增 Section 0

**內容結構**（DR-7 修正：Q1 對映表已加入 Section 12.5）：
```markdown
## 0 四原則橫切自檢層（cross-cutting · v6.0.0 新增）

寫程式 / 設計 / 審查 / 測試**任何階段**，永遠先過 4 個自問。這 4 問是橫切的（cross-cutting），不屬於任一 Phase，每次 Phase 內部都要套用：

- **Q1（Think）**：我這步的假設是什麼？有歧義嗎？需要 push back 嗎？
- **Q2（Simplicity）**：能不能更簡單？不該寫的有沒有寫？資深工程師會說過度設計嗎？
- **Q3（Surgical）**：我這步只動了該動的嗎？style 是否 match 既有？
- **Q4（Goal）**：這步成功的可驗證標準是什麼？

與既有閘門的對映（橫切到具體機制）：

| 原則 | 對映機制 |
|------|---------|
| Q1 Think | Section 9 閘門 A 理解確認 / Section 1b 需求探索 / Section 12 事實主張 / **Section 12.5 push back 義務** |
| Q2 Simplicity | Section 10 合理性審查 / 設計自檢（精簡閉環 步驟 1） |
| Q3 Surgical | Section 9 閘門 B 因果鏈分析 / Section 11 同類掃描 |
| Q4 Goal | BC-x/EH-x 編號 / Phase 4 測試 / 迷你追溯（步驟 4.5） |

**來源**：[andrej-karpathy-skills](https://github.com/forrestchang/andrej-karpathy-skills) Karpathy 4 原則。閉環方法論將此 4 原則從「Phase 切片」升級為「橫切自檢」。
```

**行數限制**：≤ 30 行（含對映表）

**同步檔案**：
- `.claudedocs/concepts/閉環核心理念.md`：在末尾新增「橫切自檢層（v6.0.0 新增）」段，≤ 20 行，引用 Section 0 並說明動機（cross-cutting concerns 不該被切片）
- `.claudedocs/process/五階段閉環流程.md`：在開頭或 Phase 1 之前加一句「⚠️ 注意：CLAUDE_TEMPLATE Section 0 的四原則橫切自檢適用所有 Phase」

**驗收**：Grep `## 0 四原則橫切自檢層` 在 CLAUDE_TEMPLATE 命中 1 次；4 個 Q 項目都存在；對映表 4 列完整（Q1 列含 Section 12.5）；同步檔案兩處有對應引用。

---

### BC-4 [testable]：CLAUDE_TEMPLATE.md 末尾 migration-notes 區塊（K-17.1）

**位置**：CLAUDE_TEMPLATE.md 末尾現有 `<!-- closed-loop v5.23.1 ... -->` 註解區塊**之前**（不取代既有註解，新增獨立區塊）

**內容結構**：見 IF-1 metadata 格式

**行數限制**：≤ 25 行

**驗收**：Grep `migration-notes` 在 CLAUDE_TEMPLATE 末尾命中 1 次；IF-1 規定的所有 key（from-version / to-version / breaking-changes / required-actions / recommended-actions / anchors）齊全。

---

### BC-5 [testable]：skill/init-claude.md migration logic（K-17.2）

**位置**：`skill/init-claude.md` 的 `upgrade` mode 段落

**邏輯**：
1. 偵測目標專案 CLAUDE.md 版本（grep CLAUDE_TEMPLATE 末尾既有 `closed-loop vX.Y.Z` 註解）
2. 若 v5.x → 進入 migration flow：
   - Read CLAUDE_TEMPLATE.md（cache 中的最新版）末尾 migration-notes 區塊
   - 解析 from-version / to-version / breaking-changes / required-actions / anchors（含 position）
   - 顯示摘要 + AskUserQuestion 用戶確認
   - 用戶選 B 智能合併 → 在錨點注入新 Section（按 IF-1 anchor 的 match + position 精確定位）
   - 用戶選 A 全替換 → 警告會丟失客製化 + 確認後執行
   - 用戶選 C 手動 → 印出 diff，用戶自處理
   - 錨點找不到 → 觸發 EH-2 自動降級為策略 C
3. 若 v6.0.0+ → 跳過 migration（既有 upgrade 流程）

**行數限制**：≤ 80 行新增（DR-2v2 修正：IF-1 從 mapping 升級為 list of objects + position 屬性後，bash 解析複雜度增加，從原 ≤ 60 拉到 ≤ 80）

**驗收**：模擬 v5.x → v6.0.0 upgrade flow，三策略均能執行；錨點 grep 結果驗證 anchor.match 確實命中目標 CLAUDE.md。

---

### BC-6 [testable]：版本號 bump（K-17.3）

| 檔案 | 改動 |
|------|------|
| `CLAUDE_TEMPLATE.md` 末尾既有註解 | `closed-loop v5.23.1` → `closed-loop v6.0.0` |
| `dev-closed-loop/README.md` 版本歷史表 | 表頂新增 v6.0.0 條目（描述本次改動） |
| 根 `README.md` 版本歷史表 | 表頂新增 v6.0.0 條目（同步說明） |

**驗收**：三處版本號 grep 結果一致為 v6.0.0；版本歷史表的 v6.0.0 條目描述一致（內容可微調對外/對內語氣，但版本號與重點摘要一致）。

---

### BC-7 [testable]：Push back 義務 — Section 12.5（K-04）

**位置**：`CLAUDE_TEMPLATE.md` Section 12 結尾後、Section 13 之前

**內容結構**（DR-4 修正：加第 5 條觸發場景）：
```markdown
### 12.5 Push Back 義務（v6.0.0 新增 · Karpathy 學習）

以下情境**必須主動反對用戶**，不能順從執行（5 條觸發場景白名單）：

1. **更簡單的替代方案存在**：用戶要求的方案有更簡單的替代且簡單方案不影響功能
2. **命中已知 anti-pattern**：用戶要求的改動會引入「長期警惕模式」（問題追蹤命中）
3. **基於弱證據的決策**：用戶要求基於不充分證據（Section 12 弱證據）的事實做後續決策
4. **任務升級而非順從**：用戶要求一次改動超出該等級任務的合理範圍（中型 ≥ 3 檔案 / ≥ 300 行 → 應升級為大型）
5. **用戶事實前提待驗證**：用戶斷言為「事實」但無證據的關鍵主張，且該主張將作後續行動前提（與 Section 12 對 Claude 自身推論的對稱面；K-14 v6.2.0 將擴充為完整反向質疑機制）

**Push back 輸出格式**：

⚠️ 我建議反對這個做法
├─ 理由：[具體說明，引用 Section 9 / 10 / 12 / 問題追蹤條目]
├─ 替代方案：[X，並說明為何更好]
└─ 若仍要執行原方案：請說「OK 用原方案」

**設計精神**：
- Push back 不是拒絕執行，是「強制讓用戶看到代價後再決定」
- 5 條觸發場景是**白名單**，不在此列的需求應正常執行不要多嘴
- 用戶說「OK 用原方案」即解除 push back，立即執行（Q1 Think 原則：尊重用戶最終判斷）
- **與 Section 12 對稱性**（DR-3v2 修正）：Section 12 對 **Claude 自身推論** 做事實主張閘門（自我驗證）；12.5 第 5 條對 **用戶對 Claude 的事實主張** 做反向閘門（質疑用戶）——兩者構成對稱的雙向認知驗證機制，K-14（v6.2.0）將擴充為完整反向質疑協議

**反模式**：
- ❌ 對所有需求都先 push back（變多嘴）
- ❌ Push back 後不接受用戶最終決定（越權）
- ❌ Push back 沒有具體替代方案（無建設性）
```

**行數限制**：≤ 40 行（DR-4 第 5 條導致從原 35 → 40）

**同步檔案**：
- `.claudedocs/concepts/閉環核心理念.md`：補「主動質疑」段（≤ 15 行），說明 push back 與 Section 13 質疑熔斷的對稱性（用戶質疑 AI / AI 質疑用戶）
- `.claudedocs/standards/產出物格式.md`：新增「Push back 輸出格式」section（≤ 15 行），標準化 12.5 的輸出結構

**驗收**：
- Grep `### 12.5 Push Back 義務` 在 CLAUDE_TEMPLATE 命中 1 次
- 5 條觸發場景齊全（含第 5 條「用戶事實前提」）
- 輸出格式範例存在
- 兩處同步檔案有對應條目

---

## 4 錯誤處理（EH-x）

### EH-1 [testable]：未知版本偵測

**條件**：`init-claude upgrade` 偵測到目標專案 CLAUDE.md 版本既非 v5.x 亦非 v6.x（無版本標記、v4.x 或更舊）

**處理**：
1. 顯示警告：`⚠️ 偵測到非 v5.x / v6.x 版本（或無版本標記），自動 migration 不安全`
2. AskUserQuestion 三選一：
   - 強制全替換（接受丟失客製化）
   - 印出 diff 手動處理
   - Abort

**反模式**：靜默直接覆蓋

---

### EH-2 [testable]：錨點失敗自動降級

**條件**：智能合併（策略 B）讀 IF-1 的 anchor.match 字串後 grep 目標 CLAUDE.md 找不到（用戶可能改了 Section heading）

**處理**：
1. 警告：`⚠️ 智能合併錨點失敗（用戶可能客製化 heading），自動降級為手動 diff 模式`
2. 列出 diff（與 fresh CLAUDE_TEMPLATE 對比）
3. 要求用戶手動處理

**反模式**：靜默 fallback 到策略 A 全替換

---

### EH-3 [testable]：placeholder 未替換

**條件**：deploy 後 grep 仍找到 `{{` 或 `}}`

**處理**：
1. 報錯阻擋部署完成
2. 列出未替換的 placeholder 名稱

---

### EH-4 [testable]：依賴表連動檔案漏改

**條件**：P2 改了 CLAUDE_TEMPLATE 結構但未改對應 .claudedocs 文件（依賴影響表規定）

**處理**：P3 方法論一致性審查偵測 → 產出 R-x high → 斷點 A 回 P2

---

### EH-5 [testable]：行數預算超出（DR-3 修正）

**預算計算**：
- v5.23.1 為 444 行
- BC-1 Trade-off ≤ 30 / BC-3 Section 0 ≤ 30 / BC-7 Section 12.5 ≤ 40 / BC-4 migration-notes ≤ 25 = ≤ 125 行新增
- **P2 瘦身要求（DR-3 強制 + DR-1v2 修正）**：BC-1 ~ BC-7 完成後，P2 必須對 CLAUDE_TEMPLATE 既有最肥段落瘦身 ≥ 25 行（候選：Section 9 因果鏈分析的範例段，約 30 行可壓 25）
- 總預算：444 + 125 - 25 = **544 行 ≤ 550 行**（緩衝 6 行，DR-1v2 修正：原 1 行緩衝過薄 → 6 行）

**條件 + 處理**：
- 行數 ≤ 550 → 通過
- 550 < 行數 ≤ 575 → R-x medium 警告，要求 P2 補瘦身或合理化
- 行數 > 575 → R-x **high** 斷點 A 回 P2

**理由**（DR-3 緩解）：v5.15 才從 606 行瘦身到 361 行，v6.x 系列若無預算控制可能再上看 700+ 行，抵消 v5.15 工作。預算 ≤ 550 比原 575 嚴 25 行，要求 P2 主動瘦身既有 Section 是執行成本的轉嫁（不是新增工作量）。

---

## 5 介面契約（IF-x）

### IF-1：Migration notes metadata 格式（連接方法論文檔層 ↔ Skill 部署層）

**作用**：Skill 層（init-claude.md）讀取 CLAUDE_TEMPLATE.md 末尾的 migration-notes 註解區塊，獲得結構化升級資訊。**這是 v6.0.0 解耦兩層的核心契約。**

**前置條件**：CLAUDE_TEMPLATE.md 末尾**已有** v5.23.1 既有部署註解區塊（不替換它，新增獨立區塊在其前）。

**位置**：CLAUDE_TEMPLATE.md 末尾，HTML comment 內

**Format**（DR-1 修正：anchors 改 list of objects + position 屬性 + 替換 placeholder anchor）：
```html
<!--
migration-notes (read by /dev:init-claude upgrade)

from-version: v5.x
to-version: v6.0.0

breaking-changes:
  - 新增 Section 0「四原則橫切自檢層」
  - 新增 Section 12.5「Push back 義務」
  - 開頭新增「⚖️ Trade-off 顯式宣告」段

required-actions:
  - 部署新 Section 0 / 12.5 / Trade-off 段
  - 確認所有 placeholder 仍正確替換

recommended-actions:
  - 重新閱讀 .claudedocs/concepts/閉環核心理念.md（含 v6.0.0 新增「橫切自檢層」與「主動質疑」段）
  - 重新閱讀 .claudedocs/standards/產出物格式.md（含 v6.0.0 新增 Push back 輸出格式）

anchors:
  - name: section-0
    match: "## ⚠️ 執行約束（最高優先級）"
    position: before
  - name: section-12-5
    match: "### 13. 質疑熔斷協議"
    position: before
  - name: trade-off-section
    match: "## 語言設定"
    position: before
-->
```

**後置條件**：init-claude.md 在 upgrade flow 可透過 grep / sed 解析此區塊的 anchors，定位注入點。

**錯誤契約**：
- 解析失敗（區塊不存在 / 格式錯誤）→ 觸發 EH-1 走未知版本流程
- anchor.match 在目標 CLAUDE.md 找不到 → 觸發 EH-2 降級策略 C

**型別語意**：
- `from-version` / `to-version`：semver 字串
- `breaking-changes` / `required-actions` / `recommended-actions`：YAML list of strings
- `anchors`：YAML list of objects，每個 object 含：
  - `name`：anchor 邏輯名稱（string）
  - `match`：要 grep 的精確字串（**禁止含 `{{PLACEHOLDER}}`，因為部署後 placeholder 已替換**）
  - `position`：注入位置（enum：`before` | `after`）

**DR-1 修正記錄**：原版 `trade-off-section: "# {{PROJECT_NAME}}"` 是 critical bug——`{{PROJECT_NAME}}` 在部署後已被替換為實際專案名（例 `# my-app`），grep 永遠 miss → 智能合併（策略 B）對 Trade-off 段永遠走 EH-2 降級為策略 C。改用 `## 語言設定`（CLAUDE_TEMPLATE.md 既有穩定 heading，無 placeholder）作 anchor，並補 `position: before`。

---

## 6 驗證層級總表

| 設計項 | 驗證層級 | 驗證方式 |
|-------|---------|---------|
| BC-1 ~ BC-7 | [testable] | Grep / 部署 diff / 模擬 upgrade flow |
| EH-1 ~ EH-5 | [testable] | 模擬條件觸發 / Hook 行為驗證 |
| IF-1 | [testable] | metadata 結構可程式化解析 + anchor.match 實際 grep |

無 `[visual-only]` / `[framework-dependent]` 項。本任務領域為「方法論文檔 + Skill 部署」，預設全 testable。

---

## 7 合理性自檢結果

| 項目 | 結果 |
|------|------|
| 一致性 | ✅ Section 0 / 12.5 編號跟既有 Section 1-13 慣例一致；新增段落用既有 markdown 風格 |
| 體驗 | ⚠️ Section 12.5 Push back 可能讓初期感覺 AI 更主動 → 接受（5 條白名單限縮觸發頻率） |
| 比例 | ✅ 5 條 K-x 拆 7 個 BC-x / ≤ 125 行新增 - 20 行瘦身 = 105 淨增 / 7 個檔案改動 → 對 major bump 屬合理規模 |
| 邊界 | ✅ EH-1 ~ EH-5 涵蓋未知版本 / 錨點失敗 / placeholder 漏改 / 漏改連動檔 / 行數超預算 |
| 影響 | ⚠️ 影響所有未來部署 v6.0.0 的專案（已由 BC-4/5/6 K-17 migration 處理） |
| 地基 | ✅ v5.x 認知驗證層支撐得住 v6.0.0 行為哲學層的新增 |
| 執行序（DR-2）| ✅ Section 10 已加硬規則：K-17（BC-4/5/6）必須是 chain 最後三步，避免中間態不一致 |

無項目觸發 AskUserQuestion（所有 ⚠️ 已有對應緩解機制）。

---

## 8 ⛔ 閘門檢查

- [✅] **學習查詢已執行**（問題追蹤 #003 命中、#004/#005 不適用 + learning-log 不存在已標示）
- [✅] **字面證據掃描**：本任務不適用（已在 design/08 完成 Karpathy 字面證據分類）
- [✅] **共用值檢測**：不適用（無 config 處理）
- [✅] **架構體質拆解**已完成（Section 1）
- [✅] **合理性自檢**已通過（Section 7，含 DR-2 執行序硬規則）
- [✅] **所有參數有型別**（IF-1 metadata 型別語意明確，含 anchor.position enum）
- [✅] **BC-x ≥ 2**（共 7 個 BC-x，DR-5 拆分後）
- [✅] **EH-x 符合領域預設**（部署/工具領域必要，5 個 EH-x 涵蓋外部失敗）
- [✅] **涉及 status 變更的 BC-x 有行為約束**（BC-6 版本號變更 → 三處檔案同步約束）
- [N/A] 無 update/tick 迴圈
- [✅] **驗證層級已標注**（全 testable）
- [✅] **分層結構已聲明**（Section 2，三層+硬規則）
- [N/A] 無 PRD（用戶未提供）

**閘門狀態**：全部 ✅ → P1 v2 完成，可進入 P1b 第 2 輪重審。

---

## 9 學習查詢標示

**學習查詢**：問題追蹤命中 [#003]（單線索→事實，已透過 design/08「Karpathy 原文 vs 延伸」分類緩解過度歸因）；[#004, #005] 不適用（純文檔升級無 config / 環境事實處理） / learning-log 不存在（本 repo 首次啟動閉環）

---

## 10 v6.0.0 影響檔案清單（給 P2 implementer）

### ⚠️ 執行順序硬規則（DR-2 修正）

**K-17（BC-4/5/6 — migration-notes 區塊 / init-claude logic / 版本 bump）必須是執行 chain 最後三步**。

**理由**：BC-4 migration-notes 寫「Section 0 / 12.5 已新增」需在 BC-3 / BC-7 完成後才不會有「migration-notes 聲明 vs 實際結構」中間態不一致。

### 執行順序表

| Step | BC | K-x | 主檔案 | 連動檔案 |
|------|-----|-----|--------|---------|
| 1 | BC-1 | K-09 | `dev-closed-loop/CLAUDE_TEMPLATE.md`（新增 Trade-off 段） | `dev-closed-loop/README.md`（同步外部版） |
| 2 | BC-2 | K-15 | `README.md`（根，新增 Karpathy 引用） | `dev-closed-loop/README.md`（同步） |
| 3 | BC-3 | K-01 | `dev-closed-loop/CLAUDE_TEMPLATE.md`（新增 Section 0） | `.claudedocs/concepts/閉環核心理念.md` · `.claudedocs/process/五階段閉環流程.md` |
| 4 | BC-7 | K-04 | `dev-closed-loop/CLAUDE_TEMPLATE.md`（新增 Section 12.5） | `.claudedocs/concepts/閉環核心理念.md`（補「主動質疑」段）· `.claudedocs/standards/產出物格式.md`（新增 Push back 格式） |
| 5 | BC-4 | K-17.1 | `dev-closed-loop/CLAUDE_TEMPLATE.md`（末尾 migration-notes 區塊） | — |
| 6 | BC-5 | K-17.2 | `dev-closed-loop/skill/init-claude.md`（migration logic） | — |
| 7 | BC-6 | K-17.3 | `dev-closed-loop/CLAUDE_TEMPLATE.md`（既有部署註解版本 bump） | `dev-closed-loop/README.md` · `README.md`（版本歷史 v6.0.0 條目） |
| 8（強制）| — | — | `dev-closed-loop/CLAUDE_TEMPLATE.md`（**Section 9 因果鏈分析範例段瘦身 ≥ 25 行**，DR-1v2 修正 — 緩衝拉至 6 行） | — |

### 唯一檔案集合（P3 一致性審查驗收用）

1. `dev-closed-loop/CLAUDE_TEMPLATE.md`
2. `README.md`
3. `dev-closed-loop/README.md`
4. `dev-closed-loop/.claudedocs/concepts/閉環核心理念.md`
5. `dev-closed-loop/.claudedocs/process/五階段閉環流程.md`
6. `dev-closed-loop/.claudedocs/standards/產出物格式.md`
7. `dev-closed-loop/skill/init-claude.md`

= **7 個檔案**（同 v1，DR 修正不增加新檔案）。

---

## 11 P1 → P1b 交接清單（v2 第 2 輪重審）

P1b sub-agent 直接讀本檔（路徑模式，主 agent 不轉述）。**第 2 輪重審重點**：確認 7 條 DR-x 修正都到位：

| DR | 修正內容 | 驗證點 |
|----|---------|-------|
| DR-1 high | IF-1 anchors 改 list of objects + position + trade-off-section 改用 `## 語言設定` | Section 5 IF-1 Format / 「DR-1 修正記錄」段 |
| DR-2 arch-risk | Section 10 加硬規則「K-17 chain 最後」+ 重排執行順序 | Section 10「執行順序硬規則」段 + 執行表 |
| DR-3 arch-risk | 預算 575 → 550，EH-5 上限 600 → 575，加 P2 瘦身 ≥ 20 行強制要求 | Section 4 EH-5 + Section 10 Step 8 |
| DR-4 medium | Section 12.5 加第 5 條觸發「用戶事實前提待驗證」（≤ 4 行輕量，不偷 K-14 scope） | Section 3 BC-7 內容結構 |
| DR-5 medium | 拆 BC-4/5/6/7 獨立 ID（原 BC-4a/4b/4c 各自獨立，原 BC-5 → BC-7） | Section 3 BC 列表（7 個 BC-x） |
| DR-6 medium | 學習查詢標示改「命中 [#003]，[#004, #005] 不適用」 | Section 0 + Section 9 |
| DR-7 low | BC-3 對映表 Q1 列加 Section 12.5 | Section 3 BC-3 內容結構（Q1 列） |

**原審查角度（v1 重點，仍適用）**：

1. CLAUDE_TEMPLATE 行數膨脹預算（v2 改 ≤ 550）是否合理
2. Section 12.5 push back 觸發場景白名單（v2 5 條）是否過寬或過窄
3. 依賴鏈順序（v2 重排為 BC-1 → BC-2 → BC-3 → BC-7 → BC-4 → BC-5 → BC-6）是否真 cycle-free
4. IF-1 metadata 格式（v2 list of objects）是否承擔得起未來 v6.1 / v6.2 / v6.3 擴充
5. Karpathy 原文（A）vs 延伸（B）分類是否在本 P1 規格中守住
6. Step 5b 學習查詢執行檢查（v2 命中 #003 + 不適用 #004/#005 是否合理）
7. Step 5c 反例檢查：「v6.0.0 是 major bump」事實主張的證據是否充分

---

最後修訂：2026-04-26（P1 設計規格 v3，第 2 輪重審通過 + 採用 medium/low 修正 DR-1v2/DR-2v2/DR-3v2，閘門全 ✅，可進 P2 實作）
