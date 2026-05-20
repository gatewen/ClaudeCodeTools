# Phase 5 Part AB — 雙向追溯結果（v6.4.0 A+E 捆綁）

> 審查日期：2026-05-20
> 審查對象：候選 A（升格降級機制 BC-A1~A6 + EH-1~3 + IF-1）+ 候選 E（5 條反向劃線 BC-E1~E6 + IF-2）
> 依據：`.claudedocs/agents/verifier.md` v1.4 步驟 0-10（含 step 9b/9c/9d）
> 範圍特性：純方法論紀律文檔變動，無程式碼，純 markdown

---

## PRD 追溯

N/A — 無 PRD（v6.4.0 為 design/13 補強計劃驅動，非 PRD 驅動）。

---

## 正向追溯表（步驟 1-3）

### 候選 A — 升格降級機制

| ID | 描述 | 驗證層級 | 實作（檔:行）| 測試（驗證方式）|
|----|------|---------|-------------|---------------|
| BC-A1 | 問題追蹤.md 降級機制 section | [testable] | ✅ `問題追蹤.md:35-51`（17 行 · 4 子段：觸發/動作/執行者/復發/EH-3 範圍限縮）| ✅ Phase 4 P4 grep 命中（`### 降級機制` head + n=10 + 2n=20 + m=5 全文字描述）|
| BC-A2 | 條件式紀律 + 歷史條目 sections | [testable] | ✅ `問題追蹤.md:172-186`（13 行 · 兩 section 預設空 + L-2 注釋）| ✅ Phase 4 grep `## 條件式紀律` + `## 歷史條目` 兩 section head 命中 |
| BC-A3 | verifier.md step 9d 降級候選掃描 | [testable] | ✅ `verifier.md:184-196`（13 行 · 6 步驟 + 唯讀屬性 + 無候選明示句）| ✅ Phase 4 grep `**步驟 9d` head + step 10 line 199 同步引用 9d |
| BC-A4 | CLAUDE_TEMPLATE Phase 5 升格段對稱補降級 | [testable] | ✅ `CLAUDE_TEMPLATE.md:386-388`（3 行新增）+ 原 commit bullet 號碼 3→4 line 389 / 4→5 line 390 重編號 | ✅ Phase 4 grep `3. **降級檢查**` 含「兩層教訓架構對稱」+「v6.4.0 新增」標 |
| BC-A5 | 精簡閉環步驟 4.5 對稱補降級 | [testable] | ✅ `CLAUDE_TEMPLATE.md:427-431`（5 行 · 主 agent 自做 · 種子過濾 + n=10 + AskUserQuestion）| ✅ Phase 4 grep `3. **降級檢查**（主 agent 自做` 命中 line 427 |
| BC-A6 | architect 步驟 1.a ⏸️ 條件式標記識別 | [testable] | ✅ `architect.md:18`（單行 inline 子規則）| ✅ Phase 4 grep `**⏸️ 條件式標記識別**（v6.4.0 新增）` 命中；觸發條件邏輯 + 略過邏輯 + 🗄️ archived 一律略過齊全 |

### 候選 E — 5 條反向劃線

| ID | 描述 | 驗證層級 | 實作（檔:行）| 測試（驗證方式）|
|----|------|---------|-------------|---------------|
| BC-E1 | R-1 閘門不可 bypass | [testable] | ✅ `CLAUDE_TEMPLATE.md:322` | ✅ Phase 4 grep `**R-1 閘門不可 bypass**` + 引用 Section 12/13 + 違反例 inline |
| BC-E2 | R-2 cross-source hard requirement | [testable] | ✅ `CLAUDE_TEMPLATE.md:323` | ✅ grep `**R-2 cross-source review` + 4 類檔案 explicit 列舉 + #007 升格根因引用 |
| BC-E3 | R-3 升格/降級/兩層教訓不可 bypass | [testable] | ✅ `CLAUDE_TEMPLATE.md:324` | ✅ grep `**R-3 升格/降級/兩層教訓架構不可 bypass` + 三項 explicit 點名（step 9b / step 9d / architect 起手）|
| BC-E4 | R-4 架構體質拆解 + 合理性自檢不可省略 | [testable] | ✅ `CLAUDE_TEMPLATE.md:325` | ✅ grep `**R-4 架構體質拆解` + architect step 1/step 7 引用 |
| BC-E5 | R-5 連續 ≥ 2 次 needs-attention 強制降級 scope | [testable] | ✅ `CLAUDE_TEMPLATE.md:326` | ✅ grep `**R-5 連續 ≥ 2 次` + 「同一閉環 P1b 連續 ≥ 2 輪」計數窗口 + #007 教訓 inline 引用 |
| BC-E6 | 閉環核心理念.md 升格降級概念段 + 紀律保底層 + 對映表 | [testable] | ✅ `閉環核心理念.md:226-244`（19 行 · 升格降級段 + 紀律保底層段 + 3 欄對映表 + 設計精神段 + K-16 關係澄清段）| ✅ Phase 4 grep 全部 5 段命中；P3 R-3 medium「K-16 關係澄清未實作」**已 in-place 補修**（line 244 `**與 K-16 對照表關係**` 命中）|

### EH-x 錯誤處理

| ID | 描述 | 驗證層級 | 實作位置 | 一致性 |
|----|------|---------|---------|-------|
| EH-1 | n 值（A 級 n=10 / archive 2n=20）為文字描述非常數 | [testable] | `問題追蹤.md:40-41` | ✅ 寫為設計層決策文字描述 · 非機械常數 |
| EH-2 | 復發處理 m=5 個閉環 ≥ 2 次門檻 | [testable] | `問題追蹤.md:49` + `verifier.md:193` | ✅ m=5 / ≥2 次 / 無需用戶確認 / 過敏感原理 4 子項全寫入 |
| EH-3 | 種子條目不適用降級 | [testable] | `問題追蹤.md:51` + `verifier.md:190` | ✅ 過濾邏輯（「升格自 N=0」+「種子條目（外部來源）」雙觸發條件）齊全 |

### IF-x 介面契約

| ID | 描述 | 一致性 |
|----|------|-------|
| IF-1 | 問題追蹤.md ↔ verifier.md n/m 值單一真理源 | ✅ verifier.md line 191「n 值見問題追蹤.md「降級機制」section · 預設 10」/ line 193「m 值見同 section · 預設 5」靜態文字引用 pattern（DR-7 採納）；verifier 不在 runtime 動態 grep |
| IF-2 | CLAUDE_TEMPLATE Section 13.5 R-3 ↔ 升格/降級/兩層教訓三項 | ✅ R-3 line 324 explicit 點名「step 9b（升格候選）/ step 9d（降級候選）/ architect 起手兩層教訓查詢」三項；機械化指向到位 |

**正向追溯統計**：12/12 BC-x ✅ · 3/3 EH-x ✅ · 2/2 IF-x ✅ · 共 **17/17 (100%)** 通過。

---

## 反向追溯（步驟 5-7）

### 步驟 5 — 行為路徑枚舉

**N/A — 純方法論紀律文檔變動**，無公開函式 / 無程式碼路徑。verifier.md `<edge_cases>` 未明確處理「純 markdown 變動」案，但對比 P3 line 64-83（結構安全/依賴方向/語言專屬審查全 N/A）已建立先例。

替代執行：對 5 個修改檔案的「設計-實作對應」做反向 grep——「實作中有無未對映回設計的孤兒變動？」

### 步驟 6 — 反向分析：實作端孤兒變動掃描

| # | 實作位置（grep 來源）| 對應設計項 | 判定 |
|---|---------------------|-----------|------|
| 1 | `問題追蹤.md:35-51` 降級機制 section | BC-A1 | ✅ 已覆蓋 |
| 2 | `問題追蹤.md:172-178` 條件式紀律 section | BC-A2 | ✅ 已覆蓋 |
| 3 | `問題追蹤.md:180-186` 歷史條目 section | BC-A2 | ✅ 已覆蓋 |
| 4 | `verifier.md:184-196` step 9d | BC-A3 | ✅ 已覆蓋 |
| 5 | `verifier.md:198-199` step 10 同步引用 9d | BC-A3（連動修改）| ✅ 已覆蓋（step 10 文字改動是 BC-A3 必要連動，非孤兒）|
| 6 | `CLAUDE_TEMPLATE.md:386-388` Phase 5 降級檢查 | BC-A4 | ✅ 已覆蓋 |
| 7 | `CLAUDE_TEMPLATE.md:427-431` 精簡閉環降級檢查 | BC-A5 | ✅ 已覆蓋 |
| 8 | `architect.md:18` ⏸️ 條件式標記識別 | BC-A6 | ✅ 已覆蓋 |
| 9 | `CLAUDE_TEMPLATE.md:318-326` Section 13.5 R-1~R-5 | BC-E1~E5 | ✅ 已覆蓋 |
| 10 | `閉環核心理念.md:226-228` 升格-降級機制段 | BC-E6（升格降級對稱部分）| ✅ 已覆蓋 |
| 11 | `閉環核心理念.md:230-244` 紀律保底層段 + 對映表 + K-16 澄清 | BC-E6（紀律保底層部分 + P3 R-3 in-place 補修）| ✅ 已覆蓋 |

**未覆蓋路徑**：0 / 11 條（0%）。**反向覆蓋率：100%。無孤兒變動。**

**特別說明**：第 5 列 `verifier.md:198-199` step 10 文字「含步驟 9b 升格候選 + 步驟 9c 事實前提追溯 + 步驟 9d 降級候選 三個 section」是 BC-A3 的必要連動修改（step 10 必須同步引用新增的 step 9d），非孤兒；列出僅為明確「step 10 改動已被設計授權」。

### 步驟 7 — 執行路徑追蹤

純文檔變動無執行路徑可追蹤。挑最複雜的 3 個 BC-x 改追「跨檔引用一致性」：

#### BC-A3 verifier.md step 9d ↔ 問題追蹤.md ↔ CLAUDE_TEMPLATE 多向引用鏈

引用鏈：
- `verifier.md:191` 「n 值見問題追蹤.md「降級機制」section · 預設 10」
  → 指向 `問題追蹤.md:35` `### 降級機制` section head
  → section 內 line 40「n = 10」line 41「2n = 20」文字描述 ✅
- `verifier.md:193` 「m 值見同 section · 預設 5」
  → 同段 line 49「m = 5」+「≥ 2 次」門檻 ✅
- `verifier.md:199` step 10 「含步驟 9b + 步驟 9c + 步驟 9d 三個 section」寫入 `P5AB-bidirectional-tracing.md`
  → 本報告即執行該契約 ✅

**設計意圖一致性**：✅ IF-1「靜態文字引用 pattern」運作正確；驗證 verifier 跑 step 9d 時不需 runtime grep 問題追蹤.md 取 n/m 值。

#### BC-A4 + BC-A5 升格/降級對稱性

完整閉環 Phase 5：升格檢查 (line 383-385) → 降級檢查 (line 386-388) → commit (line 389)
精簡閉環步驟 4.5：升格檢查 (line 421-426) → 降級檢查 (line 427-431) → commit (line 432)

**對稱結構**：兩處皆同序列「升格 → 降級 → commit」，且降級皆走「AskUserQuestion 確認 → 移到條件式紀律 section + Edit learning-log」相同動作鏈。差異點：完整閉環走 verifier sub-agent 偵測，精簡閉環主 agent 自做（design 規格 line 421 explicit 標「跟完整閉環 Phase 5 的分工差異」）。✅ 設計意圖一致。

#### BC-E6 閉環核心理念.md 多概念段疊加

引用鏈：
- line 226「## 升格-降級機制」← 對應 BC-A1/BC-A3（候選 A 連動）
- line 230「## 紀律保底層」+ line 234-241 對映表 ← 對應 CLAUDE_TEMPLATE Section 13.5 R-1~R-5
- line 244「與 K-16 對照表關係」← 對應 P1 設計規格 line 115 explicit 要求「K-07 examples 不觸發連動」（P3 R-3 in-place 補修補上）

**設計意圖一致性**：✅ 三段概念段疊加無互相覆蓋；K-16 關係澄清段（line 244）成功消除「兩個對映表並存」的閱讀歧義。

---

## 檢核修復確認（步驟 4）

### 4a — Phase 3 R-x 修復狀態

| R-x | 嚴重度 | 設計對照 | 修復狀態 | 備註 |
|-----|--------|---------|---------|------|
| R-1 | arch-risk | P1b DR-1 緩衝邊界 | ⚠️ 仍存在（不阻擋 · 跨 Phase 持續追蹤）| 詳見 arch-risk 追蹤 |
| R-2 | arch-risk | P1b DR-2 YAGNI 邊緣 | ⚠️ 仍存在（不阻擋 · 跨 Phase 持續追蹤）| 詳見 arch-risk 追蹤 |
| R-3 | medium | BC-E6 「K-16 關係澄清未實作」設計-實作 drift | ✅ **已修**（`閉環核心理念.md:244`「**與 K-16 對照表關係**」段補入）| 用戶決策 in-place 補修而非接受 drift |
| L-1 | low | BC-A1 17 行 vs 設計 12 行 | ✅ 接受（合理擴充含 EH-3 + 設計引言）| 不阻擋 |
| L-2 | low | 閉環核心理念.md +19 vs 設計 +7 | ✅ 接受（合理擴充含對映表展開 + 設計精神段）| 不阻擋 |

**所有 medium 已修復或記錄決策。0 high。** ✅

### 4b — 語言指南追溯

N/A — 純 markdown 文檔變動，無程式碼。Phase 3 報告 line 81-85「語言專屬審查 N/A · 依設計規格 line 145 明示」一致。

### 4c — Phase 1b DR-x 修復確認

| DR-x | 嚴重度 | 修復狀態 | 證據 |
|------|--------|---------|------|
| DR-1 | arch-risk | ⚠️ **仍存在**（不修正，跨 Phase 持續追蹤）| P3 R-1 確認延續 |
| DR-2 | arch-risk | ⚠️ **仍存在**（用戶決策「接受全量 A」，跨 Phase 持續追蹤）| P3 R-2 確認延續 |
| DR-3 | medium | ✅ **已 in-place 補修**（P1 line 233 補位置 + 對映表 3 欄結構 + K-16 關係澄清）| P1 修正紀錄 line 232 |
| DR-4 | medium | ✅ **已 in-place 補修**（R-2 補機械化觸發條件 + R-5 補計數窗口 + R-5 補 #007 引用）| P1 修正紀錄 line 234 |
| DR-5 | medium | ✅ **已 in-place 補修**（EH-2 改為 m=5 個閉環 ≥ 2 次命中）| P1 修正紀錄 line 235 |
| DR-6 | medium | ✅ **已 in-place 補修**（BC-E1~E5 補 heading level `### 13.5` h3）| P1 修正紀錄 line 236 |
| DR-7 | medium | ✅ **已 in-place 補修**（IF-1 補操作 pattern + n/m 值兩處同步要求）| P1 修正紀錄 line 237 |
| L-1~L-4 | low | ✅ L-2 採納 / L-4 採納（違反例 inline）/ L-1/L-3 接受 | P3 R-1 line 121-122 確認 L-4 採納 |

**5 個 medium 全部 in-place 補修。2 個 arch-risk 進入跨 Phase 持續追蹤。** ✅

---

## 交叉比對發現（步驟 8）

| # | 來源 | 發現 | 影響 |
|---|------|------|------|
| 1 | 正向 ↔ 反向 | 正向追溯 17/17 ✅ ↔ 反向掃描 0 孤兒變動 | 一致 — 雙向追溯互相驗證設計-實作對齊 |
| 2 | 正向 BC-A3 ↔ verifier.md:199 | step 10 文字「含步驟 9b + 9c + 9d 三 section」與 BC-A3「6 步驟」一致 | step 10 連動修改在 P3 line 36「step 10 已同步在 line 198-199 引用 9d」已記錄 |
| 3 | 反向 line 11 ↔ P3 R-3 | 閉環核心理念.md line 244「與 K-16 對照表關係」存在 → BC-E6 完整實作 | P3 R-3 medium 已修復（in-place 補修成功）|
| 4 | 設計 line 154 ↔ 實作終態 | 設計預估 CLAUDE_TEMPLATE 575 / 緩衝 5 vs 實作終態 574 / 緩衝 6 | 實作低於預估 1 行（BC-E1~E5 inline 違反例節省更多）→ DR-1 緩衝邊界稍有改善但仍在邊界區間 |
| 5 | 設計 line 158 ↔ 實作淨增 | 設計預估全 repo 淨 +85 行 vs 實作淨增 96 行（27+35+14+1+19）| +11 行差，含閉環核心理念.md +19 vs 預估 +7（多 +12 含對映表展開 + 設計精神段 + K-16 澄清段，皆合理擴充）|
| 6 | 反向覆蓋驗證 ↔ R-5 觸發判定 | P1b verdict「不觸發回退」≠ needs-attention，且 P3 verdict「不觸發斷點 A」≠ needs-attention | R-5「連續 ≥ 2 次 needs-attention」**未觸發**——本閉環走在正常路徑 |

**交叉比對結論**：無矛盾發現。BC-A3 step 10 改動 + BC-E6 K-16 澄清段補修兩處皆有設計/補修依據，非孤兒變動。

---

## arch-risk 追蹤狀態（步驟 9）

| 來源 | ID | 描述 | 當前狀態 | Phase 5 處置 |
|------|-----|------|---------|--------------|
| Phase 1b | DR-1 | CLAUDE_TEMPLATE 緩衝 5 行命中 #006 預防做法 (c)「緩衝 ≥ 5 行硬規則」下界 | ⚠️ **仍存在**（實作後緩衝 6，超過下界 1 行，但仍在邊界）| 列入跨 Phase 持續追蹤；v6.5.x 規劃時評估「反向劃線抽到 `.claudedocs/standards/reverse-discipline.md` 獨立檔」選項 |
| Phase 1b | DR-2 | 升格機制大樣本未驗證即補對稱降級（YAGNI 邊緣），當前實際作用對象 = 0 | ⚠️ **仍存在**（用戶決策接受全量 A）| 列入跨 Phase 持續追蹤；等 ≥ 5 個非種子升格樣本累積後重評 |
| Phase 3 | R-1 | DR-1 緩衝邊界追蹤項持續存在（沿 DR-1）| ⚠️ **仍存在** | 同 DR-1 處置 |
| Phase 3 | R-2 | DR-2 YAGNI 邊緣追蹤項持續存在（沿 DR-2）| ⚠️ **仍存在** | 同 DR-2 處置 |

**重要說明**：DR-1 + DR-2 **不是「未修正」**——是已 explicit 標明的 arch-risk 跨 Phase 知識追蹤項。P1b 用戶決策「接受全量 A 並記錄不阻擋」，本閉環不回退。Phase 5 verifier 的職責是把這 2 條 + Phase 3 對應 R-1/R-2 沿用條目納入「未來閉環重評清單」，避免遺忘。

**新增 arch-risk**：0 條。本閉環無新發現的架構風險。

---

## 事實前提追溯（步驟 9c · v5.23.1）

**Step 9c 不適用，無外部事實引用**。

設計規格 line 16「種子 #001-#005 不適用（無 config / 環境事實 / 共用值）」+ P1b line 33「設計規格未引用任何環境事實斷言」+ P1 閘門檢查 line 203-204「字面證據掃描：不適用 / 共用值檢測：不適用」三方一致確認。

本閉環全部 12 條 BC-x + 3 條 EH-x + 2 條 IF-x 皆屬「方法論紀律純邏輯設計」，無「服務 X 在 IP Y」「DB 在 Z 機器」「API 走 HTTPS」類環境事實斷言。

**V-10 判定**：N/A。

---

## 升格候選掃描（步驟 9b · 兩層教訓架構支撐）

### 掃描範圍

讀取 `.claude-loop/learning-log.md` 全檔（332 行 · 共 8 個 `→ 已升格` marker + 多個 milestone closure / 升格實證條目）。

### 已升格條目對照（問題追蹤.md「長期警惕模式」section）

| 條目 | 升格日期 | 已升格根因 | learning-log 對應條目數 |
|------|---------|-----------|------------------------|
| #006 行數預算估算樂觀 | 2026-04-26 | 行數膨脹 / 緩衝不足 | 3 筆（line 21-26, 31-37, 86-91）+ 後續 v6.3.0 / dogfooding-1 驗證實證 |
| #007 Single-Perspective Self-Review Blind Spot | 2026-05-05 | single-LLM 自評盲點 | 3 筆（line 207-214, 219-226, 230-239）+ 2 筆升格後實證（line 260-283, 287-323）|

### 根因聚類（未升格條目）

從 learning-log 第 1-332 行掃描，根因關鍵字分組：

| 根因類型 | 累積次數 | 來源 |
|---------|---------|------|
| 結構化區塊估算（已升格 #006 涵蓋） | 已歸 #006 | 不重算 |
| 跨 LLM 視角 / cross-source 漏看（已升格 #007 涵蓋） | 已歸 #007 | 不重算 |
| 依賴表 walk 遺漏（已歸 #007 預防做法 (b)） | 已歸 #007 | 不重算 |
| placeholder 部署生命週期視角檢查 | **1 次**（line 12-15 IF-1 anchor `{{PROJECT_NAME}}` placeholder 在部署時被替換）| 未達 ≥ 3 次門檻 |
| DR 修正傳遞性 / 次生副作用 | **2 次**（line 29-35 v6.0.0 DR-3 → DR-1v2 / line 41-46 DR-1 → BC-4 by-design）+ v6.1/6.2/6.3 連續無新證據（line 71, 111, 139）→ 觀察項已正式結束 | 已正式結束（非升格候選）|
| 探索成本失控（§5.6 dogfooding） | **1 次**（line 164-187）| 未達門檻；已在 CLAUDE_TEMPLATE Section 1.5 預防做法處理 |
| spec self-irony（§5.5 DOGFOODING.md Y/N 反轉） | **1 次**（line 168）| 未達門檻 |

### #006 累計實證紀錄（本閉環新增證據鏈追蹤）

按 verifier 額外重點關注 #3 要求，追溯 #006 升格後實證證據鏈：

| 證據 # | 日期 | 事件 | 結果 |
|--------|------|------|------|
| 升格觸發 1 | 2026-04-26 | v6.0.0 教訓 #2（575 緩衝 6）| 升格基礎 |
| 升格觸發 2 | 2026-04-26 | v6.0.0 教訓 #3（550 緩衝 1）| 升格基礎 |
| 升格觸發 3 | 2026-04-26 | v6.2.0 R-1（545 超 18 → 步驟 3 high 回退）| 升格基礎（達 ≥ 3 門檻）|
| 升格後實證 1 | 2026-04-26 | v6.3.0 沿用預防做法成功（CLAUDE_TEMPLATE 增量 = 0，緩衝守住）| #006 第一次驗證有效 ✅（line 140）|
| 升格後實證 2 | 2026-04-26 | dogfooding-1（CLAUDE_TEMPLATE 540→561 緩衝 19）沿用 (a)(b)(c) 全達標 | #006 第二次驗證有效（line 183）|
| 升格後實證 3 | **2026-05-20**（本閉環）| **v6.4.0 P3 R-1 line 121-133 命中 #006 預防做法 (c) 邊界**——終態 574 緩衝 6，比預估 575 緩衝 5 多 1 行；P1b DR-1 + P3 R-1 全程引用 #006 預防做法做為審查依據；P2 實作端 BC-E1~E5 採 inline 違反例（L-4 採納）節省 11 行守住預算 | **#006 第三次驗證有效**（本閉環）✅ |

**#006 累計實證**：3 筆升格基礎 + 3 筆升格後實證 = **共 6 筆證據**（升格後實證 #3 是本閉環新增）。

**判定**：#006 升格機制持續發揮作用，無需降級。

### #007 累計實證紀錄

按同樣方法追溯 #007 升格後實證證據鏈：

| 證據 # | 日期 | 事件 | 結果 |
|--------|------|------|------|
| 升格觸發 1 | 2026-05-04 | cc_recommand 83.8 漏看 5 bug，codex 補回（line 207-214）| 升格基礎 |
| 升格觸發 2 | 2026-05-05 早段 | 接續執行 2026-05-04 計畫前未審查前提（line 219-226）| 升格基礎 |
| 升格觸發 3 | 2026-05-05 晚段 | 7 commit 後沒跑依賴表 walk（line 230-239）| 升格基礎（達 ≥ 3 門檻）|
| 升格後實證 1 | 2026-05-19 | 補強計劃 Phase G v1 self-review 漏看率 50%（line 260-283）| #007 第一次驗證有效 ✅ |
| 升格後實證 2 | 2026-05-19 | Phase G v2 self-review 漏看率 67%（line 287-323）| #007 第二次驗證有效 ✅ |
| 升格後實證 3 | **2026-05-20**（本閉環）| **v6.4.0 P1b 子 agent + 用戶人工 cross-check 兩層 cross-source review 機制（設計規格 line 15 explicit 引用 #007 預防做法 (a)）；P1b 0 high → 沒有觸發 R-5「連續 ≥ 2 次 needs-attention」**——cross-source review 預防做法成功應用 | **#007 第三次驗證有效**（本閉環）✅ — 屬「預防做法成功應用」而非「失敗實證」 |

**#007 累計實證**：3 筆升格基礎 + 2 筆失敗實證 + 1 筆成功實證 = **共 6 筆證據**。

### R-5 觸發判定

按 verifier 重點關注 #7 要求檢查：

- P1b verdict（`.claude-loop/artifacts/P1b-design-review.md` line 18）：「**判定：不觸發回退到 Phase 1**。0 high → 可進 Phase 2」
- P3 verdict（`.claude-loop/artifacts/P3-quality.md` line 24）：「**判定**：不觸發斷點 A。可進 Phase 4」

**判定結論**：本閉環 P1b 第 1 輪即「不觸發回退」，**非 needs-attention**。R-5「同一閉環 P1b 連續 ≥ 2 輪 verdict needs-attention」**未觸發**——本閉環走在 cross-source review 預防做法成功應用的路徑上，反而為 #007 預防做法增加正向實證。

### 升格候選結論

**0 個新升格候選**——learning-log 中未升格根因最高頻為「DR 修正傳遞性」(2 次但已正式結束於 v6.3.0)；其他單筆觀察項皆未達 ≥ 3 次門檻。

**新增實證紀錄**（屬「實證追加」而非「新升格」）：
- 為 **#006** 累積第 3 次升格後實證（v6.4.0 本閉環 #006 預防做法 (c) 邊界 + DR-1 跨 Phase 追蹤）
- 為 **#007** 累積第 3 次升格後實證（v6.4.0 本閉環 cross-source review 預防做法成功應用，未觸發 R-5）

主 agent Part C 應在 commit 後 Edit learning-log 為本次 v6.4.0 closure 新增 milestone entry，明標 #006 + #007 第 3 次實證。

---

## 降級候選掃描（步驟 9d · v6.4.0 新增 · 首次運作 ⚠️ self-irony 觀察）

### 掃描範圍

讀取 `.claudedocs/records/問題追蹤.md`「長期警惕模式」section 全部 7 條條目（#001-#007）。降級機制 n=10 個閉環無新證據 → A 級降級候選 / 2n=20 → 完全 archive 候選。

### 條目逐條判定

| 條目 | 升格日期 | 升格自 N 筆 | EH-3 過濾 | 過去 n=10 閉環新證據 | 判定 |
|------|---------|------------|----------|---------------------|------|
| #001 絕對負面陳述需證據 | 2026-04-18 | 種子條目（外部 reel_core 案）| ✅ **跳過** | N/A | 種子條目，EH-3 範圍限縮 |
| #002 Existence-vs-Routing 框架錯置 | 2026-04-18 | 種子條目（外部 reel_core 案）| ✅ **跳過** | N/A | 同上 |
| #003 單線索 → 事實 | 2026-04-22 | 種子條目（外部 GS 誤判事件）| ✅ **跳過** | N/A | 同上 |
| #004 忽視字面證據 | 2026-04-22 | 種子條目（外部 GS 誤判事件）| ✅ **跳過** | N/A | 同上 |
| #005 共用值私有化 | 2026-04-22 | 種子條目（外部 GS 誤判事件）| ✅ **跳過** | N/A | 同上 |
| #006 行數預算估算樂觀 | 2026-04-26（24 天前）| 升格自 3 筆 learning-log | ❌ 適用降級規則 | v6.3.0 / dogfooding-1 / v6.4.0（本閉環 P3 R-1）3 筆 + 升格基礎 3 筆 = **近 5 個閉環內持續有新證據** | ✅ **無降級候選**（active 條目持續有現實證據）|
| #007 Single-Perspective Self-Review Blind Spot | 2026-05-05（15 天前）| 升格自 3 筆 learning-log | ❌ 適用降級規則 | Phase G v1 + v2（2026-05-19）+ 本閉環 cross-source review 預防做法應用 = **近 3 個閉環內持續有新證據** | ✅ **無降級候選**（active 條目持續有現實證據）|

### 復發偵測（條件式紀律 section）

讀取 `問題追蹤.md:172-178` 「## 條件式紀律」section → **目前無條目**（line 178「（目前無條目，待第一筆降級觸發後填入）」）。

→ 無復發偵測對象。

### 降級候選結論

**0 個降級候選 · 0 個完全 archive 候選 · 0 個復發升回候選**。

按 verifier.md step 9d 規範明示：「無降級候選（active 條目皆有近 n 閉環新證據 / 條件式條目無 m 內 ≥ 2 次命中）」。

### ⚠️ Self-Irony 觀察（首次運作 meta 層）

按 verifier 重點關注 #6 要求 explicit 標明：

**本閉環首次運作降級機制（step 9d / BC-A3 / BC-A4 / BC-A5）**，且本次掃描的**作用對象 = 0**：
- 種子條目 #001-#005 全被 EH-3 範圍限縮過濾
- 非種子升格條目 #006 + #007 升格時間都太近（24 天 / 15 天 << n=10 閉環 ≈ 數月），且都持續有新證據
- 條件式紀律 section 預設空 → 復發偵測無對象

這 explicit 印證了 **P1b DR-2「YAGNI 邊緣」arch-risk 的擔憂**：「降級機制當前實際作用對象 = 0」+「+96 行為一個目前無作用對象的機制提前佈建」。

**Meta 觀察**：
1. **降級機制首次運作即「無作用對象」**——P3 R-2 line 138-148 + P1b DR-2 line 70-100 預測準確
2. **但這不代表設計失敗**——機制本身結構穩固（種子條目過濾正確，n/m 門檻邏輯通暢，唯讀屬性遵守）
3. **真正的考驗在未來**：等 ≥ 5 個非種子升格樣本累積後（最早 2026-07-26 起，按 v7 啟動條件累積時序估算），#006 / #007 + 後續升格條目才會開始進入 n=10 閉環門檻
4. **本閉環應該 record 而非藏起來這個 meta 觀察**——「**首次運作即 0 作用**」是 #007 升格教訓「self-review 漏看率」對方法論本身的反向印證：降級機制不是「設計時直覺認為有用」（self-review），而是「等實證累積足夠樣本後才能判定是否值得 +96 行」（cross-source 等實證）

主 agent Part C 應該在 commit message 或 README 版本歷史中 explicit 提及這個 self-irony，避免「永遠不會用到的功能默默存在」的技術債堆積。

---

## 總結

### 量化指標

| 指標 | 結果 |
|------|------|
| 正向追溯通過率 | **17/17 (100%)** — 12 BC-x + 3 EH-x + 2 IF-x 全部 ✅ |
| 反向追溯孤兒變動 | **0/11 (0%)** — 所有實作變動皆對映回設計項 |
| 反向覆蓋率 | **100%** |
| arch-risk | **2 項仍存在**（DR-1 / DR-2，沿 Phase 3 R-1 / R-2，跨 Phase 持續追蹤）/ **0 新增** |
| Phase 1b DR-x medium 修復 | **5/5 已 in-place 補修**（DR-3/4/5/6/7）|
| Phase 3 R-x medium 修復 | **1/1 已 in-place 補修**（R-3 K-16 關係澄清）|
| 事實前提追溯（V-10）| **不適用**（純邏輯設計，無環境事實引用）|
| 升格候選 | **0 個新升格** + #006 / #007 各新增 1 筆實證（屬實證追加，非新升格）|
| 降級候選 | **0 個降級** + 0 個 archive + 0 個復發升回 ⚠️ **首次運作即 0 作用對象**（self-irony · DR-2 預測準確）|
| R-5 觸發判定 | **未觸發**（P1b verdict 不觸發回退，非 needs-attention）|

### 整體判定

✅ **通過 — 可進 Part C**

依據：
1. 正向追溯 100% + 反向覆蓋 100% → 設計-實作雙向對齊
2. 5 個 medium DR-x + 1 個 medium R-x 全部 in-place 補修
3. 2 個 arch-risk（DR-1 + DR-2）已明確標識為跨 Phase 持續追蹤項，非「未修正」
4. 步驟 9c 不適用（純邏輯設計）
5. 步驟 9b 無新升格 + 為 #006/#007 各新增 1 筆實證
6. 步驟 9d 首次運作 0 作用對象，self-irony 已 explicit record（驗證 DR-2 預測準確）

### 主 agent Part C 處置建議

1. **commit 動作**：批准進 commit · 將 5 個修改檔案 + P1/P1b/P3/P5AB 4 個 artifacts 一併納入 commit
2. **learning-log 更新**（Edit 而非 sub-agent）：
   - 為本閉環新增 v6.4.0 milestone closure entry
   - 在 entry 中 explicit 標 **#006 第 3 次實證**（DR-1 邊界 + P3 R-1）+ **#007 第 3 次實證**（cross-source review 預防做法成功應用）
   - 為「降級機制首次運作 0 作用對象」the self-irony 寫入專段 record（避免技術債）
3. **commit message 建議**：
   - 主標：「v6.4.0：升格降級機制（候選 A）+ 5 條反向劃線 R-1~R-5（候選 E）」
   - 內文需提及：A+E 捆綁 / 拒絕 B+G / Codex 雙輪 review 已記錄 / #006 + #007 第 3 次實證 / 降級機制首次運作 0 作用對象的 self-irony
4. **版本同步檢查**（依 CLAUDE.md 第 11 列依賴表 walk）：3 處版本記錄必須一併更新
   - CLAUDE_TEMPLATE.md 末尾註解
   - dev-closed-loop/README.md 版本歷史
   - 根 README.md 版本歷史
5. **無回退觸發**：可直接進 Part C 升格/降級確認 + commit

### 跨 Phase arch-risk 持續追蹤（傳遞給未來閉環）

| arch-risk | 來源 | 重評時機 |
|-----------|------|---------|
| DR-1 / R-1 緩衝邊界 | P1b / P3 | v6.5.x 規劃時主動評估「反向劃線抽出獨立檔」選項 |
| DR-2 / R-2 降級機制 YAGNI 邊緣 | P1b / P3 | 等 ≥ 5 個非種子升格樣本累積後（最早 2026-07-26 後）重評 |

---

最後修訂：2026-05-20（Phase 5 Part AB 雙向追溯 · v6.4.0 A+E 捆綁 · step 9d 首次運作）
