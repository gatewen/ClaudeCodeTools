# Phase 1 設計規格 — A+E 捆綁實作（v6.4.0）

**閉環範圍**：候選 A（升格降級機制 · B 級 78.5）+ 候選 E（5 條反向劃線 R-1~R-5 · A 級 81）
**設計輸入**：`dev-closed-loop/design/13-autonomy-v2-reinforcement-plan.md` §15.5 預設
**判定**：大型任務 — 單模組（方法論紀律層）/ 完整 5-Phase 閉環 / 捆綁實施
**版本**：v6.3.x → **v6.4.0**（minor bump · 連動 3 處版本記錄：CLAUDE_TEMPLATE 末尾 + dev-closed-loop/README.md + 根 README.md）

---

## 學習查詢結果

| 來源 | 命中 | 影響 |
|------|------|------|
| 問題追蹤 #006 行數預算估算樂觀 | ⚠️ 直接命中 | CLAUDE_TEMPLATE 終態 575 / 緩衝 5（預防做法 (c) ≥ 5 邊界）→ design-reviewer 預期標 arch-risk，已 explicit 標示 |
| 問題追蹤 #007 single-source self-review 盲點 | ⚠️ 直接命中（本次是「方法論修改」類）| Phase 1b design-reviewer 子 agent + 用戶人工 cross-check 作為兩層 cross-source（規模 85 行可替代另跑 Codex）|
| 問題追蹤 #001-#005 種子條目 | 不適用（無 config / 環境事實 / 共用值） | — |
| learning-log `[architect]` tag | 0 筆 | — |

---

## §15.5 預設修正（架構師對輸入規格的精煉）

| §15.5 預設 | 問題 | 修正 |
|-----------|------|------|
| BC-A3「verifier.md 新增 step 9c 降級候選檢查」 | verifier.md step 9c 已存在（事實前提追溯 v5.23.1）| 改為 **step 9d 降級候選掃描** |
| BC-A6「architect.md step 6c-1 ⏸️ 條件式標記識別」 | architect.md 無 step 6c-1 命名 | 改為 **架構師主 agent 步驟 1.a 子項** ⏸️ 條件式標記識別 |

---

## 架構體質拆解

```
🏗️ [架構體質拆解]
├─ 現有結構：
│  ├─ 升格機制：learning-log → 問題追蹤 單向（無對稱 downgrade）
│  ├─ R-x 規則：CLAUDE_TEMPLATE Section 12/13 已有「事實主張閘門」+「質疑熔斷協議」兩層
│  └─ 8 條 Anti-patterns：§12 補強計劃已壓縮為 5 條反向劃線 R-1~R-5（候選 E 配套條件 #2）
├─ 假設驗證：升格 = 永久 active 假設，#007 大樣本可能需要 downgrade 配套 → A 為此 case 提前準備
├─ 多餘識別：無
└─ 地基評估：穩；CLAUDE_TEMPLATE 547 行 / 緩衝 53 vs 600 上限 / 33 vs 580 預算
```

---

## 分層結構

全部模組：**純功能層**（無 UI）。皆為方法論紀律文檔變更，無框架運行時依賴。

---

## 邊界條件

### 候選 A — 升格降級機制（BC-A1~A6）

- **BC-A1 [testable]**：`問題追蹤.md` 新增「降級機制」section（位於 `## 長期警惕模式` 內，`### 升格條件` 之後，`### 條目格式` 之前）。內容含：
  - 降級觸發條件（A 級：升格後 n 個閉環無新證據 / 完全 archive：≥ 2n 個閉環無新證據，**n 預設 10**）
  - 降級動作（A 級：條目標 `⏸️ 條件式` 移到末尾「條件式紀律」section / 完全 archive：移到 `## 歷史條目` section 標 `🗄️ archived YYYY-MM-DD`）
  - 降級執行者（verifier step 9d 偵測 → 主 agent AskUserQuestion 確認）
  - 復發處理（已降級條目在 **m=5 個閉環內 ≥ 2 次命中** → 立即升回 active，verifier 強制偵測 EH-2）
  - 預估 ~12 行

- **BC-A2 [testable]**：`問題追蹤.md` 末尾新增兩個 section：
  - `## 條件式紀律`：A 級降級條目目錄（預設空），格式 `### #XXX · YYYY-MM-DD · ⏸️ 條件式 · 降級自 #YYY · 觸發條件：[具體情境]`，預估 ~8 行
  - `## 歷史條目`：完全 archive 條目目錄（預設空），格式 `### #XXX · 🗄️ archived YYYY-MM-DD · 升格 → 條件式 → archived`，預估 ~5 行
  - 合計 ~13 行（含 section head + 格式說明 + 預設留空注釋）

- **BC-A3 [testable]**：`verifier.md` 新增 **step 9d — 降級候選掃描**（位於 step 9c 後 / step 10 前）。執行步驟：
  1. 讀取 `問題追蹤.md` 「長期警惕模式」每筆條目
  2. 過濾條目「升格自 N 筆 learning-log」N=0 或標「種子條目（外部來源）」者跳過（EH-3）
  3. 對剩餘條目掃描 learning-log 過去 n 個閉環是否有新證據（grep `→ 已升格 #XXX` 對應 entries 時間戳）
  4. 無新證據 ≥ n → A 級降級候選 / 無新證據 ≥ 2n → 完全 archive 候選
  5. 復發偵測：「條件式紀律」section 內條目在 m=5 個閉環內被 learning-log 命中 ≥ 2 次 → 立即升回候選（EH-2）
  6. 產出候選描述（條目 #XXX / 累積無證據閉環數 / 建議動作）給主 agent Part C 處理
  7. **唯讀**：不直接寫入問題追蹤.md，由主 agent 在 Part C 用戶確認後執行
  - 預估 ~15 行

- **BC-A4 [testable]**：`CLAUDE_TEMPLATE.md` 完整閉環 Phase 5 「升格檢查」段對稱補「降級檢查」。位置：line 373 升格檢查 bullet 後新增第 3 點：
  ```
  3. **降級檢查**（兩層教訓架構對稱）：讀 P5AB 報告的「降級候選」section
     - 有候選 → AskUserQuestion 確認 → 選是 → 條目移到「條件式紀律」section + Edit learning-log 加註「→ 已降級 → 條件式 [YYYY-MM-DD]」/ 選否 → 跳過
     - 無候選 → 跳過
  ```
  原 commit bullet 號碼從 3 → 4（commit）/ 4 → 5（模組登記）。預估 +3 行。

- **BC-A5 [testable]**：`CLAUDE_TEMPLATE.md` 精簡閉環步驟 4.5 升格檢查對稱補降級檢查。位置：line 412 升格檢查 bullet 後新增第 3 點（主 agent 自做，無 verifier sub-agent）：
  ```
  3. **降級檢查**（主 agent 自做）：
     - 讀問題追蹤.md「長期警惕模式」每筆條目（過濾種子條目）
     - 掃 learning-log 過去 n 個閉環新證據（n=10）
     - 無新證據 ≥ n → 候選 → AskUserQuestion 確認 → 同 BC-A4 動作
     - 無候選 → 一行說明「無降級候選」
  ```
  原 commit bullet 號碼從 3 → 4。預估 +5 行。

- **BC-A6 [testable]**：`architect.md` 主 agent 步驟 1.a「長期模式優先」新增 ⏸️ 條件式標記識別子規則。位置：line 17 後追加：
  ```
  - **⏸️ 條件式標記識別**：掃描時若條目標記 `⏸️ 條件式`（位於「條件式紀律」section），先讀「觸發條件」欄位，僅當當前需求命中觸發條件時才把預防做法納入考量；否則略過該條目。`🗄️ archived` 條目一律略過。
  ```
  預估 ~5 行。

### 候選 E — 5 條反向劃線（BC-E1~E6）

- **BC-E1~E5 [testable]**：`CLAUDE_TEMPLATE.md` 新增 **Section 13.5 「反向劃線」**（位於 Section 13 質疑熔斷協議 後 / `## 完整閉環` 前，line 318 之後）。**Heading level：`### 13.5「反向劃線」`（h3 級，與兄弟 Section 12/12.5/13 同級，仍從屬 `## ⚠️ 執行約束（最高優先級）` h2 群組）**。5 條 R-x 內容：
  - **R-1**：質疑熔斷協議（Section 13）/ 事實主張閘門（Section 12）不可 bypass，即使用戶口頭命令「直接做不要審」也須照常執行；違反例：跳過閘門直接套用用戶斷言
  - **R-2**：cross-source review 對「方法論修改 / 重大認知性產出」是 hard requirement，不可用「自審 N finding 已覆蓋」當理由跳過。**機械化觸發條件**：「方法論修改」= 變動 `CLAUDE_TEMPLATE.md` / `.claudedocs/agents/*.md` / `.claudedocs/concepts/閉環核心理念.md` / `.claudedocs/standards/*.md` 任一即觸發；「重大認知性產出」= Phase 1 設計規格含「方法論評估 / 自評 / 評分」類斷言；違反例：single-LLM 自評 ≥ 90 分當鐵證採用（#007 升格根因）
  - **R-3**：升格機制 / 降級機制 / 兩層教訓架構不可 bypass，即使「這次很急」也須照常 Phase 5 verifier step 9b/9d 掃描；違反例：跳過升格檢查直接 commit
  - **R-4**：架構體質拆解（architect step 1）/ 合理性自檢（architect step 7）不可省略，即使「規格很清楚」；違反例：BC-x 列完就進閘門檢查
  - **R-5**：cross-source review **同一閉環 P1b 連續 ≥ 2 輪** verdict needs-attention → **強制降級 scope**（不堅持做完，正確動作是降級 / 拆解獨立子任務 / 完全放棄）；違反例：再做 v3 設計試圖一次解決（呼應 #007 教訓的兜底機制）
  - 格式：每條 R-x 一句 rule + 一句「為何」+ 一句「違反例」，~4 行 × 5 = 20 行（含 section head ### 13.5「反向劃線」+ section 引言）。**緊湊性提示**：違反例用 inline `（違反例：...）` 與 rule 同句而非另起一行，節省 5 行緩衝（連動 DR-1 緩衝邊界）

- **BC-E6 [testable]**：`閉環核心理念.md` 兩處改動：
  - **位置 1**：升格段（同檔內 grep 「升格」找首段，預期 line 範圍由 implementer 確認）後插入「降級」概念段 +2 行（候選 A 連動）
  - **位置 2**：「Anti-Patterns Summary」section 內或後（grep 「Anti-Patterns Summary」找該 section，預期位於檔案中後段）插入「紀律保底層」概念段 + 對映表 +5 行
  - **對映表結構**（3 欄）：`| R-x | rule 摘要 | 為何反向劃線 |`，R-1~R-5 各佔 1 列
  - **與 K-16 對照表關係澄清**：本對映表 ≠ K-16 對照表（K-16 對映 anti-pattern → Q1-Q4 / 本對映表對映 R-1~R-5 → Section 12/13 紀律），兩者並存不衝突，不觸發 K-07 examples 連動
  - 預估累計變動 ~7 行（保底層 +5 / 升格降級對稱 +2）

---

## 錯誤處理

- **EH-1 [testable]**：降級條件 n 值（A 級降級 n=10 / 完全 archive 2n=20）寫死在 BC-A1 問題追蹤.md「降級機制」section 內為文字描述（非常數），未來調整需手動編輯該 section。**理由**：方法論紀律檔，n 值改動屬於設計層決策，不應隱藏為機械常數。
- **EH-2 [testable]**：升格條目降級後**復發** → BC-A3 step 9d 強制偵測。**復發判定門檻**：「條件式紀律」section 內條目在 **m=5 個閉環內被 learning-log 命中 ≥ 2 次** → 立即升回 active section（無需用戶確認，因已有歷史升格背書）。**理由**：直接「命中 1 次就升回」過敏感（一筆偶然 learning-log 命中關鍵字 ≠ 問題復發），m=5（n/2）+ 2 次門檻過濾偶然性。verifier 報告明確標示「復發升回 #XXX [YYYY-MM-DD] · m 個閉環內 ≥ 2 次命中」。
- **EH-3 [testable]**：種子條目 #001-#005（外部來源寫入，無對應 learning-log 證據）→ **不適用降級規則**（範圍限縮配套）。BC-A3 step 9d 掃描時先過濾條目「升格自 N 筆 learning-log」欄位，N=0 或標「種子條目（外部來源）」者跳過。

---

## 介面契約

- **IF-1**：`問題追蹤.md`「降級機制」section ↔ `verifier.md` step 9d 介面契約
  - 契約欄位：(a) 降級觸發條件 n 值定義（A 級 n=10 / archive 2n=20）/ (b) 條件式 section 路徑與格式 / (c) 復發偵測規則（m=5 個閉環 ≥ 2 次命中）
  - 不變式：n / m 值在問題追蹤.md 內為單一真理源，verifier.md step 9d 引用該值不寫死
  - **操作 pattern**：verifier.md step 9d 文字寫「過去 n 個閉環（n 值見問題追蹤.md「降級機制」section）」/「m 個閉環內 ≥ 2 次（m 值見同 section）」— **靜態文字引用**，verifier 不在 runtime 動態 grep n/m 值（避免增加運行成本）；n/m 值若調整需手動同步問題追蹤.md + verifier.md 兩處
  - 違反後果：未來調整 n/m 值時若 verifier.md 未同步 → P3 R-x medium（CR-x 介面契約違反）

- **IF-2**：`CLAUDE_TEMPLATE.md` Section 13.5 R-3 ↔ `問題追蹤.md` 升格/降級機制 cross-reference
  - 契約：R-3 必須 explicit 點名「升格機制 / 降級機制 / 兩層教訓架構」三項
  - 不變式：問題追蹤.md 結構變動（新增/刪除「升格 / 降級」相關 section）時，R-3 文字需同步檢查
  - 違反後果：R-3 失去機械化指向 → 降為純宣言（P3 R-x medium）

---

## 驗證層級

全部 12 條 BC-x + 3 條 EH-x + 2 條 IF-x **皆 [testable]** — 純文檔，可用 grep / wc -l / cross-file consistency check 驗證。

---

## 實作規模預期（3x rule 基準）

| 檔案 | 預期增量 | 3x 上限 |
|------|---------|--------|
| CLAUDE_TEMPLATE.md | +28（P5 +3 / 精簡 4.5 +5 / Section 13.5 +20）| ≥ 84 觸發重寫提案 |
| 問題追蹤.md | +30（降級機制 ~12 + 條件式紀律 ~13 + 歷史條目 ~5）| ≥ 90 |
| verifier.md | +15（step 9d）| ≥ 45 |
| architect.md | +5（步驟 1.a 子項）| ≥ 15 |
| 閉環核心理念.md | +7（紀律保底層 +5 / 升格降級對稱 +2）| ≥ 21 |
| **全 repo 淨** | **+85** | — |

**CLAUDE_TEMPLATE.md 終態**：547 + 28 = **575**（緩衝 5 vs 580 預算 ⚠️ / 緩衝 25 vs 600 上限）

---

## 合理性自檢

```
🔍 [合理性自檢]
├─ 一致性 ✅：A 對稱升格機制 / E 對稱現有 Section 12-13 認知驗證層
├─ 體驗 ✅：用戶不感知（降級自動運作 + R-x 是執行紀律）
├─ 比例 ⚠️：+85 行 vs 「升格條目永久 active 假設失效」風險 — 需用戶判定是否 over-engineering
├─ 邊界 ✅：EH-1/2/3 覆蓋 n 可調 / 復發 / 種子條目不適用
├─ 影響 ⚠️：緩衝 5 行命中 #006 觸發信號 — design-reviewer 預期標 arch-risk
└─ 地基 ✅：升格機制成熟，補對稱 downgrade 是擴展
```

**已知 arch-risk**：CLAUDE_TEMPLATE.md 575/580 緩衝 5 行命中 #006 預防做法 (c) 「緩衝 ≥ 5 行硬規則」邊界。設計時已 explicit 標明（補強計劃 §15.5 line 918），預期 design-reviewer 標 arch-risk 但**記錄不阻擋**。

---

## 連動檔案依賴表 walk

依 CLAUDE.md「依賴影響分析」表：

| 改動位置 | 觸發列 | 連動檔案 |
|---------|-------|---------|
| CLAUDE_TEMPLATE Phase 5 升格段補降級（BC-A4）| 第 1 列 | ✓ `process/五階段閉環流程.md` · `concepts/閉環核心理念.md` 升格段對稱（BC-E6 覆蓋）|
| CLAUDE_TEMPLATE 精簡 4.5 升格段補降級（BC-A5）| 第 1 列 | ✓ 同上 |
| CLAUDE_TEMPLATE Section 13.5 新增（BC-E1~E5）| 第 1 列 + 第 8 列 + 第 7 列 | ✓ `concepts/閉環核心理念.md` 紀律保底層段（BC-E6 覆蓋）· 評估 `init-claude.md` 是否需新增 `section-13-5` anchor（建議列入後續任務 T5，不夾帶本閉環）|
| 問題追蹤.md 降級機制 + 條件式 + 歷史條目 sections（BC-A1/A2）| 第 1 列 + 第 8 列 | ✓ `concepts/閉環核心理念.md` 升格段對稱（BC-E6 覆蓋）|
| verifier.md 新增 step 9d（BC-A3）| 第 8 列 | ✓ CLAUDE_TEMPLATE Phase 5 對應描述（BC-A4 覆蓋）· `process/五階段閉環流程.md` |
| architect.md 步驟 1.a 子項（BC-A6）| 第 8 列 | ✓ CLAUDE_TEMPLATE Phase 1 描述（無需改動，Phase 1 已用 inline 委派 architect.md）|
| 版本號 v6.3.x → v6.4.0 | 第 11 列 | ✓ 3 處（CLAUDE_TEMPLATE 末尾、`dev-closed-loop/README.md`、根 `README.md`）|

**對外契約檢查**：7 smoke 不涉及 verifier step / Section 編號斷言 → **不影響**

---

## 閘門檢查結果

- [x] **學習查詢已執行**：問題追蹤 #006 + #007 命中（影響已 explicit 標示）/ learning-log [architect] 0 筆 / 種子 #001-#005 不適用
- [x] 字面證據掃描：**不適用**（無 config / 未知檔案讀取）
- [x] 共用值檢測：**不適用**（無 config value）
- [x] 架構體質拆解已完成
- [x] 合理性自檢已通過（2 處 ⚠️ 已 explicit 標示，待 Phase 1b design-reviewer 確認）
- [x] 所有參數有型別：n=10（int）/ section 路徑（string）
- [x] BC-x ≥ 2：12 條（A:6 + E:6）
- [x] EH-x 符合領域預設：3 條覆蓋外部依賴 / 復發 / 範圍邊界
- [x] 涉及 status 變更的 BC-x 有行為約束：BC-A1 條目降級後行為（移到條件式 section / architect 略過）explicit 定義
- [x] 無 update/tick 迴圈：不適用
- [x] 驗證層級已標注：全 testable
- [x] 分層結構已聲明：純功能
- [x] **資深工程師審視通過**：每條 BC-x 具體到位置 + 行數 + 預期內容；複雜度與「對稱升格 + 紀律保底層」目標成正比，非過度設計
- [x] PRD 對應：N/A（無 PRD）

---

**設計規格完成 → 可進 Phase 1b**

**學習查詢**：問題追蹤命中 [#006, #007] / learning-log [architect] 0 筆 / 種子 #001-#005 不適用

---

## P1b 第 1 輪後修正紀錄（2026-05-20）

P1b 審查結果：0 high / 2 arch-risk（DR-1 緩衝邊界 / DR-2 YAGNI 邊緣）/ 5 medium / 3 low。

**用戶決策**：
- DR-2 → **接受全量 A**（按原設計）
- DR-3/4/6/7 → **全部 in-place 補修正**
- DR-5 → **現在 Phase 1 補設計**（復發改為 m=5 閉環 ≥ 2 次命中）

**in-place 修正項**（已套用本檔）：
- DR-3：BC-E6 補位置（升格段後 / Anti-Patterns Summary section）+ 對映表 3 欄結構 + K-16 對映表關係澄清
- DR-4：R-2 補機械化觸發條件（4 類檔案 grep 級）+ R-5 補計數窗口（同一閉環 P1b 連續 ≥ 2 輪）+ R-5 補 #007 引用
- DR-5：EH-2 / BC-A1 / BC-A3 step 9d 第 5 步 統一改為 m=5 個閉環 ≥ 2 次命中
- DR-6：BC-E1~E5 補 heading level `### 13.5`（h3 從屬 h2 群組）+ 緊湊性提示（違反例 inline）
- DR-7：IF-1 補操作 pattern（verifier.md 靜態文字引用，不 runtime grep）+ n/m 值兩處同步要求

**arch-risk 追蹤項**（不阻擋，Phase 5 verifier 列入追蹤）：
- DR-1：CLAUDE_TEMPLATE 575/580 緩衝 5 邊界 → Phase 2 強制 wc -l + 預留 v6.5.x 抽 reverse-discipline.md 獨立檔選項
- DR-2：升格機制大樣本未驗證即補對稱降級（YAGNI 邊緣）→ Phase 5 列入追蹤，等 ≥ 5 個非種子升格樣本累積後重評
