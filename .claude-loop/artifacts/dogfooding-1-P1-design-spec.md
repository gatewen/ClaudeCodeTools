# dogfooding-1 — P1 設計規格（精簡六步閉環）

> 日期：2026-04-26
> Branch：main
> 上游：D:\Code\DogFooding\DOGFOODING-RESULT.md（reviewer §6.2 + §6.4，P1 級補強）
> Scope：v6.3.x post-dogfooding patch（不 version bump，標 `dogfooding-1` 供未來追溯）
> **v3 修正（用戶 ultrathink 校準）**：原 P1 只含 §6.2 + §6.4（用戶選 B = P0+P1）→ 用戶 framing 修正為「整份 RESULT 是補強素材」→ 擴含 §6.3 / §6.5 / §6.6 + §8 缺口寫進 design/12
> 配額策略：sub-agent 委派全降級（P1b / P3 主 agent 自審）— 沿 dogfooding §5.3 教訓

---

## 0 學習查詢結果

| 來源 | 結果 |
|------|------|
| 問題追蹤長期警惕模式（6 條） | 命中 [#006]（行數預算）— 沿用預防做法 |
| `.claude-loop/learning-log.md` | dogfooding 完整 retrospective 為 deferred 寫入（本次 milestone closure 一併補） |
| dogfooding RESULT §5 觀察 | §5.6 探索成本盲點 + §3.2 K-11 校準觸發 為主要素材 |

**關鍵教訓**：
- §5.3 配額 ad hoc → 本次主動降級 sub-agent，但仍走完整六步（保留 audit trail）
- §5.6 探索成本失控 → CLAUDE_TEMPLATE Section 1 加 1.5 補 4 條探索邊界

---

## 1 分層結構聲明

純文檔補強。不動 hooks / agents / setup.sh。動：
- CLAUDE_TEMPLATE.md（規則層補 Section 1.5）
- 概念層 baseline 附錄擴充
- design/12 新檔（K-11 校準起點）
- 跨檔同步（兩個 README 版本歷史 / CLAUDE_TEMPLATE 末尾標記 / learning-log）

---

## 2 邊界條件（BC-x）

### BC-D1-1 [testable]：CLAUDE_TEMPLATE.md Section 1.5 探索成本上限

**位置**：`dev-closed-loop/CLAUDE_TEMPLATE.md` Section 1（任務分流表）後，Section 1b（需求探索）前。

**內容**（reviewer §6.2 草案精煉版）：

```
### 1.5 微小任務的探索成本上限（dogfooding-1 補強)

微小任務涉及探索類動作（找 typo / 找未用 import / 找 lint warning / 找 dead code）時，
「直接執行」原則需附加成本上限：
- **候選數量**：找 1-3 個候選即停，**不窮舉**
- **工具呼叫**：grep + read 合計 ≤ 3 次
- **時間盒**：探索階段 token 成本 < 修正成本的 30%
- **找不到顯著候選**：提早回報用戶，**不創造目標**（不退而求其次）

違反此邊界視為「微小任務升級為中型探索任務」，建簡單 TaskList 追蹤成本。
**反例**：dogfooding T1「找 typo」跑 5+ 次 grep / 退而求其次補字 — 本規則直擋。
```

**行數限制**：≤ 16 行（Section 1.5 完整段含 heading）

**驗收 BC-D1-1**：
- grep `### 1.5` 在 CLAUDE_TEMPLATE 命中 1
- grep `候選數量\|工具呼叫\|時間盒\|找不到顯著候選` 在 Section 1.5 各 ≥ 1
- grep `dogfooding T1` 反例引用命中 1

### BC-V7K-1 [testable]：design/12-v7-kpi-calibration.md 新檔

**位置**：`dev-closed-loop/design/12-v7-kpi-calibration.md`（沿 design/01-11 系列）

**內容大綱**：
- 觸發背景（dogfooding 後 baseline 6 ≥ 5 達標）
- 6 樣本實證分析（DR-x / R-x / 升格分布）
- 門檻校準建議（DR-x / R-x 區間 / 升格頻率）
- v7 啟動條件（時間跨度 ≥ 3 個月）
- 後續流程

**行數限制**：80-120 行（沿 design/08-11 範圍）

**驗收 BC-V7K-1**：
- 檔案存在
- 含 ≥ 4 個主 section（背景 / 實證分析 / 校準建議 / 啟動條件）
- 6 樣本表格 ≥ 6 列

### BC-V7K-2 [testable]：方法論運作指標.md baseline 附錄擴充

**位置**：`dev-closed-loop/.claudedocs/concepts/方法論運作指標.md` baseline 附錄表格

**內容**：表格加 2 列（dogfooding T1 / T2）+ 註腳「累積 6 個樣本，DR-x / R-x 區間可初步校準（見 design/12）」

**行數限制**：≤ 113（當前 105 + 8）緩衝 ≥ 5

**驗收 BC-V7K-2**：
- grep `dogfooding T1\|dogfooding T2` 各 ≥ 1
- 表格列數 ≥ 6（v6.0~v6.3 + dogfooding T1/T2 = 6）

### BC-D2-1 [testable]：CLAUDE_TEMPLATE.md「配額管理策略」加主動降級判定流程（§6.3）

**位置**：`dev-closed-loop/CLAUDE_TEMPLATE.md`「配額管理策略」section 內，「降級優先順序」之後加新子段。

**內容**（reviewer §6.3 草案精煉版）：

```
**主動降級判定點**（dogfooding-1 補強 · 對應 dogfooding §5.3 教訓）：

session 開始時應預估剩餘 token vs 預期消耗：
- 估算「主 agent 寫設計 + 子 agent 委派 + 工具呼叫」總和
- 若估算 ≥ 配額 70% → **主動降級開始**（不等真的爆才被迫）
- 降級順序按既定優先：P5 Part AB → P3 安全審查 → P1b → ⛔ P3 品質審查不可降

**Hint**：每個 sub-agent 委派 ~5K-30K token；單次主 agent 設計輸出 ~2K-5K。
session 餘量低於 50K 時即使 P3 都可能撐不過——應提早告知用戶並建議 deferred。
```

**行數限制**：≤ 12 行

**驗收 BC-D2-1**：
- grep `主動降級判定點` 命中 1
- grep `≥ 配額 70%\|餘量低於 50K` 命中各 ≥ 1

### BC-D3-1 [testable]：design-reviewer.md 步驟 4.5 BC↔健康路徑階層對齊審查（§6.5）

**位置**：`dev-closed-loop/.claudedocs/agents/design-reviewer.md` `<instructions>` 步驟 4「驗證式審查」後加步驟 4.5（既有 step 4.5 為 BC ↔ 健康路徑階層 — 沒有就新增）。

**內容**（reviewer §6.5 草案）：

```
**步驟 4.5 — BC ↔ 健康路徑階層對齊審查**（dogfooding-1 補強）

對每個 BC-x：
- 檢查觸發條件涉及的「目標檔案/目錄」是否與健康路徑判定使用同一抽象層次
- 若不同層次 → 標 DR-x medium「BC ↔ 健康路徑階層漂移」
- 例：BC 檢查 `X/`，健康路徑用 `X/Y/`——當 `X/` 存在但 `Y/` 缺失時觸發點漂移

**反例**：dogfooding T2 DR-1（BC-2-2 檢查 `.claude-loop/`，健康路徑檢查 `.claude-loop/artifacts/`）
```

**行數限制**：≤ 10 行

**驗收 BC-D3-1**：
- grep `步驟 4.5` 在 design-reviewer.md 命中 1
- grep `BC ↔ 健康路徑階層` 命中 ≥ 1

### BC-D4-1 [testable]：tester.md 加跨平台環境前置檢查（§6.6）

**位置**：`dev-closed-loop/.claudedocs/agents/tester.md` `<edge_cases>` section 加新段。

**內容**（reviewer §6.6 草案）：

```
**跨平台測試的環境前置檢查**（dogfooding-1 補強）：

執行 EH-x 測試前，若涉及作業系統特性模擬（chmod 權限 / signal handling /
process group / file locking），須先檢查環境支援度：
- 環境不支援 → 標 skip 計入 PASS（環境降級），於迷你追溯註記
- 環境支援 → 正常測試
- **不要**寫死測試 case 期待 100% pass（會在 msys2/容器/受限環境誤報）
```

**行數限制**：≤ 8 行

**驗收 BC-D4-1**：
- grep `跨平台測試的環境前置檢查` 命中 1
- grep `chmod 權限\|signal handling\|file locking` 命中各 ≥ 1

### BC-CROSS-1 [testable]：跨檔同步

**位置**：
- `dev-closed-loop/CLAUDE_TEMPLATE.md` 末尾 closed-loop 註解：保持 v6.3.0（不 version bump）+ 補 dogfooding-1 補丁說明
- `dev-closed-loop/README.md` 版本歷史頂端加註腳（不新增 row，加 sub-bullet）
- 根 `README.md` 微小直通保護段加 1 行 cross-reference 指向 Section 1.5
- `.claude-loop/learning-log.md` 補 dogfooding milestone closure 條目

**行數限制**：CLAUDE_TEMPLATE +2 行 / 兩 README 各 +1 行 / learning-log +30 行

**驗收 BC-CROSS-1**：
- grep `dogfooding-1\|dogfooding 補強` 在跨檔各 ≥ 1
- learning-log 含 `dogfooding milestone closure` 條目

---

## 3 EH-x

純文檔升級無外部 I/O，跳過。

## 4 IF-x

無模組間介面變更。

## 5 設計決策

| 決策 | 選擇 | 理由 |
|-----|------|-----|
| 版本標籤 | dogfooding-1（不 version bump） | v6.x 已正式收尾（design/11），dogfooding 補強是 patch 性質 |
| sub-agent 委派 | 全降級主 agent 自審（P1b / P3）| 配額考量 + 純文檔風險低 + 沿 dogfooding §5.3 教訓 explicit 降級而非 ad hoc |
| 範圍 | reviewer §6.2 + §6.4 兩個 P1 | 用戶選 B 路徑（P0 + P1，不含 P2/P3） |
| Section 1.5 內容 | reviewer §6.2 草案精煉 16 行 | 4 條規則 + 反例引用，避免冗長 |
| design/12 內容 | 6 樣本實證 + 校準建議 + v7 啟動條件 | 不僅是「校準筆記」，是 v7 規劃 entry point |

## 6 行數預算（v3 · 擴含 D-2/D-3/D-4 · 沿 #006 緩衝 ≥ 5）

| 檔案 | 當前 | 上限 | 增量 | 緩衝 |
|------|------|------|------|------|
| CLAUDE_TEMPLATE.md | 540 | ≤ 580 | +30（Section 1.5 +16 / D-2 配額管理 +12 / 末尾 +2）| 10 ✅ |
| `agents/design-reviewer.md` | 248 | ≤ 260 | +10（D-3 步驟 4.5）| 2 ⚠️（純內部 prompt 文件，膨脹風險低）|
| `agents/tester.md` | 201 | ≤ 215 | +8（D-4 跨平台前置）| 6 ✅ |
| 方法論運作指標.md | 105 | ≤ 118 | +8（baseline +2 列 + 註腳）| 5 ✅ |
| design/12（新）| — | 130 | 100-130（含 §8 5 個缺口）| 0-30 buffer ✅ |
| dev-closed-loop/README.md | 149 | ≤ 155 | +3 | 3 ⚠️（小範圍版本標註）|
| 根 README.md | 215 | ≤ 220 | +3 | 2 ⚠️（小範圍版本標註）|
| `.claude-loop/learning-log.md` | — | — | +30 | （無上限）|

**v3 修正記錄**：
- CLAUDE_TEMPLATE 565→580（+10 緩衝，多 D-2 +12）
- 加 design-reviewer.md / tester.md 兩檔（D-3 / D-4 落點）
- design/12 上限 120→130 額外納入 §8 缺口章節
- 4 個檔案緩衝 < 5（design-reviewer / 兩 README / design/12 取決實際）但增量小且 local，by-design 接受

---

## 7 設計自檢（7 問）

| # | 自檢題 | 答 |
|---|-------|-----|
| ① | 更簡單的做法？ | 已採 reviewer §6.2 + §6.4 精煉版，未發明新概念 |
| ② | 影響不相關模組？ | 不影響 hooks / agents / setup.sh |
| ③ | 邊界條件覆蓋？ | 4 條 BC（D1-1 / V7K-1 / V7K-2 / CROSS-1）|
| ④ | 操作流程變複雜？ | Section 1.5 加規則但減少 token 浪費，淨改善 |
| ⑤ | 解法複雜度成正比？ | 是（P1 級補強對應中型閉環）|
| ⑥ | 架構地基穩？ | 沿 v6.x 既有 Section 1 任務分流框架 |
| ⑦ | 資深工程師會說過度設計嗎？ | 無風險（4 條規則簡單明瞭）|

---

## 8 風險清單

| ID | 風險 | 嚴重度 | 緩解 |
|----|------|--------|------|
| RISK-1 | CLAUDE_TEMPLATE 預算緩衝 0 | 中 | P1b 自審觸發 → 上限放寬到 565（緩衝 7）|
| RISK-2 | 方法論運作指標.md 緩衝 0 | 中 | 同上 → 上限放寬到 118（緩衝 5）|
| RISK-3 | sub-agent 委派全降級 → 漏抓設計缺陷 | 中 | 純文檔 + 內容沿 reviewer 草案 + 用戶 review 兜底 |
| RISK-4 | 「dogfooding-1」標籤未來模糊 | 低 | design/12 explicit 標 v7 啟動條件，下次清楚 |

---

## 9 學習查詢結果（最終）

**學習查詢**：問題追蹤命中 [#006]（緩衝 ≥ 5 預防做法）/ learning-log 補 dogfooding milestone closure（本次新增）

---

最後修訂：2026-04-26（dogfooding-1 P1 設計定稿，配額降級全 sub-agent 委派）
