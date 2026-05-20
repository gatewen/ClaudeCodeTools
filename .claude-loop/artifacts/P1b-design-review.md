# Phase 1b — 設計審查報告（v6.4.0 A+E 捆綁實作）

> 審查日期：2026-05-20
> 審查對象：`.claude-loop/artifacts/P1-design-spec.md`（v6.4.0 A+E 捆綁）
> 依據：`.claudedocs/agents/design-reviewer.md` 步驟 1-6
> 範圍：候選 A（升格降級機制 BC-A1~A6 + EH-1~3 + IF-1）+ 候選 E（5 條反向劃線 BC-E1~E6 + IF-2）

---

## 審查摘要

- 審查的 BC-x 數量：**12**（BC-A1~A6 · BC-E1~E6）
- 審查的 EH-x 數量：**3**（EH-1/2/3）
- 審查的 IF-x 數量：**2**（IF-1/2）
- 發現：**0 high / 2 arch-risk / 5 medium / 3 low**

**判定：不觸發回退到 Phase 1**。0 high → 可進 Phase 2。建議用戶 in-place 順手補 DR-3/4/6/7 medium 修正後再進 Phase 2 以降低 design-implementation drift 風險。

---

## Step 5b — 學習查詢執行檢查

設計規格 line 213 標示：「**學習查詢**：問題追蹤命中 [#006, #007] / learning-log [architect] 0 筆 / 種子 #001-#005 不適用」✅

抽查驗證：
- **#006 命中（行數預算）**：設計規格 line 14「⚠️ 直接命中 / 緩衝 5（預防做法 (c) ≥ 5 邊界）→ design-reviewer 預期標 arch-risk，已 explicit 標示」✅ 引用 #006 預防做法 (c)
- **#007 命中（self-review 盲點）**：設計規格 line 15「本次是『方法論修改』類 / Phase 1b design-reviewer 子 agent + 用戶人工 cross-check 作為兩層 cross-source」✅ 引用 #007 預防做法 (a) cross-source review
- **種子 #001-#005**：設計規格 line 16「不適用（無 config / 環境事實 / 共用值）」—抽查 #003 line 71「Phase 1 架構師 Step 0a 字面證據掃描 + Step 0b 共用值檢測」確實只適用於 config / 環境事實處理；本任務純方法論文檔變更，分類合理。✅

✅ Step 5b 通過。

## Step 5c — 事實前提反例檢查（Falsification Check）

設計規格未引用任何環境事實斷言（無「服務 X 在 IP Y」「DB 在 Z 機器」「API 走 HTTPS」類）。閘門檢查 line 196「字面證據掃描：不適用」line 197「共用值檢測：不適用」對齊。

**Step 5c 不適用（無外部事實引用）**。

---

## 審查結果

### DR-1 [arch-risk] — 緩衝 5 行命中 #006 硬規則邊界，1 行誤差即觸發違規

**問題**：

設計規格 line 154 自評「CLAUDE_TEMPLATE.md 終態：547 + 28 = 575（緩衝 5 vs 580 預算 ⚠️）」恰好命中 #006「預防做法 (c) 緩衝 ≥ 5 行硬規則」的下界。

歷史教訓鏈（#006 line 98）：
- v6.0.0 教訓 #2：575 緩衝 6 → DR-3 標 arch-risk
- v6.0.0 教訓 #3：550 緩衝 1 → DR-1v2 medium 次生副作用
- v6.2.0 R-1：545 超 18 → 步驟 3 high 回退

設計規格中 BC-E1~E5 預估「~4 行 × 5 = 20 行（含 section head + section 引言）」。實際展開 5 條 R-x 含 markdown formatting（粗體 / 連結文字 / 違反例縮排）通常 1 條會佔 5-6 行而非 4 行。若實際變成 25-30 行（+5 ~ +10），CLAUDE_TEMPLATE 終態變 580-585（緩衝 0 或負）→ 觸發 #006 R-x medium / high。再加 BC-A4 「3 點降級檢查」實際展開含 bullet + 程式碼塊估算偏 1-2 行 → 容易破線。

**風險評估**：

- **長期**：+85 行後緩衝從 v6.3.x 的 ~33 降為 5。未來任何 minor 變動都可能觸發 #006 medium，本機制本身會強化未來 minor 升級的審查負擔
- **短期**：本閉環 Phase 2 實作完跑 `wc -l` 若超 580 將觸發 R-x medium 回 Phase 2 重做

設計者 line 170 已 explicit 自評「已知 arch-risk / 記錄不阻擋」—**符合 #006 自審紀律，沒有違反**，但確實在邊界。

**建議**（不阻擋，但 Phase 2 / Phase 5 必跟）：

1. **Phase 2 實作完強制 wc -l**：implementer 完成 CLAUDE_TEMPLATE 變動立即 `wc -l CLAUDE_TEMPLATE.md` 驗收，若 ≥ 581 不交 Phase 3，先重構（壓縮 BC-A4 程式碼塊 / 把 R-x 違反例收摺為 inline 描述）
2. **Phase 5 verifier step 9 arch-risk 追蹤**：將本 DR-1 列入 P5AB arch-risk 追蹤清單，提示 v6.5.x 規劃時主動考慮把「反向劃線」抽到 `.claudedocs/standards/reverse-discipline.md` 獨立檔（騰出 ~20 行緩衝）
3. **Phase 1 不要求修正**：本 DR 屬「arch-risk 不觸發回退」性質，設計者**不可在 Phase 2 認為 +28 是 hard cap**—實際可能 +25 ~ +33，需保留調整空間並在實作時取最緊湊寫法

---

### DR-2 [arch-risk] — 升格機制大樣本未驗證即補對稱降級，YAGNI 邊緣案

**問題**：

升格機制 v5.22.x 引入，截至 v6.3.x 只有 **#007 一個樣本實際升格**（#001-#005 為種子條目 EH-3 排除；#006 也是升格但時間距現在僅一個多月）。本次直接補「對稱降級」機制（+30 行問題追蹤.md / +15 行 verifier step 9d / +5 行 architect 步驟 1.a / +8 行 CLAUDE_TEMPLATE Phase 5 + 精簡 4.5）。

設計規格 line 38「升格 = 永久 active 假設，#007 大樣本可能需要 downgrade 配套 → A 為此 case 提前準備」表明設計者意識到此問題。然而：

- #007 升格至今僅約 15 天（2026-05-05 → 2026-05-20），尚無「長期 active 但失去現實證據」的實證案例
- 唯一非種子升格 #006 同樣才 24 天，更不可能用上降級
- 種子條目 #001-#005 EH-3 已明確排除降級規則 → **本機制當前實際可作用對象 = 0**

**資深工程師視角**（K-02 senior engineer test）：
> 「先讓升格機制跑滿一年累積 ≥ 5 個樣本，再看哪些真的需要降級，那時設計才有實證根據。現在就建對稱機制是預備未來可能的需求—典型 YAGNI 違反，且 n=10 / 2n=20 門檻、復發定義、condition section 結構都基於假設而非實證。」

**風險評估**：

中性。降級機制本身設計合理（EH-3 種子條目排除、EH-2 復發自動升回、verifier step 9d 唯讀掃描），結構上不會壞事。但：
- **過早優化成本**：+60 行（A 部分總和）為一個目前作用對象 = 0 的機制
- **未來修正成本**：等真的有降級需求時，可能發現現在設計的門檻 / 復發定義 / structure 不對—屆時要重新設計反而比現在拖延 6 個月後從實證設計成本高
- **但有「對稱性」+「假設失效預防」價值**：升格機制本身不刪除條目，若假設真失效會造成「永遠不清理」問題（K-11 健康指標難以維持綠燈）

**建議**（用戶判定方向）：

1. **接受**：用戶判定「對稱性 + 預防 #007 假設失效」價值 > YAGNI 成本（合理選項，設計規格 line 167 line 38 已論述）
2. **降規模**：BC-A1/A2 縮減為「降級機制 stub」（只寫條件式 section 預留 + 一句說明，不寫 verifier 偵測邏輯），等真有需求再補 BC-A3/A6—預期可省 ~40 行
3. **延後**：抽出候選 A 整體，先做候選 E 紀律保底層（已有 #007 一個樣本足以證明 R-2/R-5 必要）

設計規格 line 167「升格機制成熟，補對稱 downgrade 是擴展」自評「地基穩」**部分成立**—升格機制機械化部分穩，但「降級需求的實證」未成熟。

---

### DR-3 [medium] — BC-E6 「閉環核心理念.md 變動位置不明」設計鬆綁

**問題**：

設計規格 line 111 BC-E6：「閉環核心理念.md 新增『紀律保底層』概念段 + 對映表（指向 CLAUDE_TEMPLATE Section 13.5 五條 R-x）。同檔再補升格段對稱『降級』概念段（候選 A 連動）。預估累計變動 ~7 行（保底層 +5 / 升格降級對稱 +2）。」

問題：
- **變動位置未指定 line 或 section**：implementer Phase 2 拿到後不知道放哪個 section。閉環核心理念.md 228 行內結構（升格段在哪、Anti-Patterns Summary 在哪、保底層應該插哪）未在設計規格 explicit 標明
- **對映表結構未指定**：「對映表」是 5 列（R-1~R-5）× 幾欄？至少需要「R-x | rule 摘要 | 為何反向劃線」3 欄，或還是別的格式？implementer 可能用不同格式造成 design-implementation drift
- **與 K-07/K-16 對照關係未澄清**：CLAUDE.md「依賴影響分析」表第 12 列「對照範例 K-07 修改」對映表變動觸發，若本對映表 = K-16 對照表升級版可能還需同步 K-07 examples/；設計規格 line 175-188 依賴表 walk 沒列這個

**建議修正**：

1. Phase 1 補位置（一行即可）：「BC-E6 變動位置：閉環核心理念.md 升格段（line N）後插入降級概念段 2 行；Anti-Patterns Summary section（line M）內或後插入保底層概念段 + 對映表 5 行」—不寫死 line 但點出 section
2. 對映表結構 explicit 範本（即使一行也好）：「| R-x | rule 摘要 | 為何反向劃線 |」3 欄
3. 評估是否觸及 K-07 對照表升級—若不觸及在依賴表 walk 中標「BC-E6 對映表 ≠ K-16 對照表（兩者目的不同：K-16 表的是 anti-pattern 對映 Q1-Q4 / 保底層對映表是 R-1~R-5 vs Section 12/13 的對映）」消除歧義

---

### DR-4 [medium] — R-2 vs R-5 邊界互補但定義不夠機械化

**問題**：

設計規格 line 108：
- **R-2**：cross-source review 對「方法論修改 / 重大認知性產出」是 hard requirement，不可用「自審 N finding 已覆蓋」當理由跳過（#007 升格根因）
- **R-5**：cross-source review 連續 ≥ 2 次 verdict needs-attention → 強制降級 scope

**關係分析**：
- R-2 是「前置門檻」（必須做 cross-source review）
- R-5 是「結果處置」（review 做了但持續 needs-attention 時的兜底）

兩者**邏輯互補不重複**，符合「漏判前置 + 漏判後置」的雙保險。但有兩個 medium 級隙縫：

**問題 1**：R-2 「方法論修改 / 重大認知性產出」定義不明—哪些算「重大」？本次 A+E 捆綁 +85 行算重大嗎？v6.3.x infrastructure-patch（7 commits 都在閉環核心理念 / 問題追蹤等紀律檔）算重大嗎？沒有可機械化判定的觸發條件 → 容易被 LLM 自評「這次不算重大」繞過（剛好就是 #007 的失誤模式自身）。

**問題 2**：R-5 「連續 ≥ 2 次 needs-attention」的計數窗口不清楚。是同一個 P1b 兩輪都 needs-attention 嗎？還是橫跨多個閉環的同類議題兩次都 needs-attention？設計規格沒指明，implementer 寫進 CLAUDE_TEMPLATE 時可能含糊措辭。

**建議修正**：

1. **R-2 補機械化觸發條件**：「方法論修改」= 變動 `CLAUDE_TEMPLATE.md` / `.claudedocs/agents/*.md` / `.claudedocs/concepts/閉環核心理念.md` / `.claudedocs/standards/*.md` 之一即觸發；「重大認知性產出」= Phase 1 設計規格含「方法論評估 / 自評 / 評分」類斷言。給 R-2 一個 grep 級門檻避免主觀繞過
2. **R-5 補計數窗口定義**：「同一閉環 P1b 連續 ≥ 2 輪 needs-attention」（如本次第 2 輪修正後若仍 needs-attention 就強制降級）vs「同一議題橫跨閉環 ≥ 2 次」—設計規格選一個並寫明
3. **可選**：R-5 vs #007 升格教訓的引用，目前 R-2 引用 #007（line 108 「#007 升格根因」），R-5 沒引用任何條目—補一句「（呼應 #007 教訓的兜底機制）」加強紀律一致性

---

### DR-5 [medium] — BC-A6 + EH-2 復發機制成本未評估

**問題**：

設計規格 line 119 EH-2「升格條目降級後復發 → 立即升回 active」 + BC-A3 step 9d 第 5 步「復發偵測：condition section 內條目又被 learning-log 命中 → 立即升回候選」。

問題：每次 verifier step 9d 執行都要：
1. 掃 `## 長期警惕模式` section 全部條目（找升格候選）
2. 掃 `## 條件式紀律` section 全部條目（找復發）
3. 比對 learning-log 過去 n=10 個閉環 entries（時間戳對比 + 關鍵字匹配）

樂觀估計每次掃描 ~10 個條目 × ~50 個 learning-log entries = 500 次比對。token 消耗未量化。**且每個閉環 Phase 5 都會跑**—成本累積。

對比現有 step 9b（升格候選掃描）：只掃 learning-log 一份檔，~50 entries 分組計數—更輕。

**建議修正**：

1. **量化評估**：Phase 2 實作 verifier step 9d 後跑一次完整 dry-run，量測：(a) step 9d 平均 token 消耗；(b) 與 step 9b 對比比率—若 ≥ 3 倍 step 9b，DR-2 的 YAGNI 風險更顯著（記入 K-11 Phase 1 6c-1 token 成本指標）
2. **復發偵測門檻可調**：EH-2 直接「命中 1 次就升回」可能過敏感（一次偶然 learning-log 命中關鍵字並不等於問題復發）。建議改為「condition section 內條目在 m 個閉環內被 learning-log 命中 ≥ 2 次」，m 可設 = n / 2 = 5，避免一筆偶然 entry 觸發回升
3. **記入 P5 arch-risk 追蹤**：「verifier step 9d 成本 vs step 9b 比率」列入 K-11 額外指標（line 930 已預列「Phase 1 6c-1 token 成本 / 復發率」—順帶補上 step 9d token 比率）

---

### DR-6 [medium] — BC-E1~E5 Section 13.5 heading level 未指定，破壞 h2/h3 階層風險

**問題**：

實際 CLAUDE_TEMPLATE.md 中 Section 12 / 12.5 / 13 都是 `### 12.` / `### 12.5` / `### 13.`（h3 級別），它們都在 `## ⚠️ 執行約束（最高優先級）`（line 56，h2）之下。設計規格 line 103 寫「新增 **Section 13.5「反向劃線」**（位於 Section 13 質疑熔斷協議 後 / `## 完整閉環` 前，line 318 之後）」—邏輯位置正確，但**未指定 heading level**。

若 implementer 誤寫成 `## 13.5 反向劃線`（h2 級別），會造成：
- 與兄弟 `## ⚠️ 執行約束` 同層 → 視覺上把 13.5 抽離出「執行約束」群組
- 後續 `## 完整閉環` 不會成為 13.5 的隔斷
- markdown anchor 變動 → 未來 init-claude.md anchor 系統（line 521 `match: "### 13. 質疑熔斷協議"`）的智能合併會錯位

**建議修正**：

1. 設計規格 line 109 補一句「Heading level：`### 13.5「反向劃線」`（h3 級，與兄弟 Section 12/12.5/13 同級，仍從屬 `## ⚠️ 執行約束（最高優先級）`）」
2. **anchor 系統一致性檢查**：BC-A4 / BC-A5 對 Phase 5 升格段 + 精簡 4.5 內容的修改，需確認不破壞 line 521 `match: "### 13. 質疑熔斷協議"` 字串。實際上 BC-A4 動 line 373 / BC-A5 動 line 412 都離 line 521 很遠，理論上不影響—但建議 Phase 2 完工後跑一次 `grep -n "### 13. 質疑熔斷協議" CLAUDE_TEMPLATE.md` 確認 anchor 仍唯一命中

---

### DR-7 [medium] — IF-1 n 值「單一真理源」設計但 verifier.md step 9d 仍會出現重複描述

**問題**：

設計規格 line 127 IF-1：「n 值在問題追蹤.md 內為單一真理源，verifier.md step 9d 引用該值不寫死」。

但 BC-A3 step 9d 描述（line 70-72）：
> 3. 對剩餘條目掃描 learning-log 過去 **n 個閉環**是否有新證據
> 4. 無新證據 **≥ n** → A 級降級候選 / 無新證據 **≥ 2n** → 完全 archive 候選

step 9d 在 verifier.md 中需要說「過去 n 個閉環」「≥ n」「≥ 2n」這幾個地方—**雖然不寫死數字 10**，但概念上仍重複了 n / 2n 的判定門檻定義。IF-1 期望的「不寫死」實際操作是：verifier.md 寫「依問題追蹤.md『降級機制』section 定義的 n 值」之類的指引—implementer 容易：

- **誤實作 A**：直接寫「過去 10 個閉環」「≥ 10」「≥ 20」（IF-1 違反，雙真理源）
- **誤實作 B**：寫「依問題追蹤.md n 值」但每次 verifier 執行需先 grep 問題追蹤.md 取 n（增加運行成本，且邏輯複雜化）

IF-1 「不變式：n 值在問題追蹤.md 內為單一真理源」沒給 implementer 具體操作 pattern。

**建議修正**：

IF-1 補一行操作指引：「verifier.md step 9d 文字寫『過去 n 個閉環（n 值見問題追蹤.md「降級機制」section）』—**靜態文字引用**，verifier 不在 runtime 動態 grep n 值（避免增加運行成本）；n 值若調整需手動同步問題追蹤.md + verifier.md 兩處—CR-x 介面契約變更要求兩處皆觸發。」

這樣 IF-1 從「不變式 + 違反後果」升級為「不變式 + 違反後果 + 操作 pattern」，避免 implementer 含糊處理。

---

### low 級摘要

- **L-1 BC-A1「降級執行者」描述比例**：BC-A1 預估 12 行可能不夠（細節包含 4 個 sub-bullet + 復發處理），實作時注意
- **L-2 BC-A2「條件式紀律 / 歷史條目」section 預設留空注釋**：預設空 section 視覺上可能讓人疑惑「這 section 為什麼存在」—建議補 1 行明示「（目前無條目，待第一筆降級觸發後填入）」當 placeholder
- **L-3 `閉環核心理念.md` 變動 +7 行對該檔 228 行而言比例 ~3%**：低風險，文檔擴充自然
- **L-4 BC-E1~E5「為何 + 違反例」格式緊湊性**：~4 行/條 在實際 markdown 包含粗體 + 縮排違反例會偏緊；建議 implementer 寫作時把「違反例」用 inline `（例：...）` 縮成同一句而非另起一行，可節省 5 行（與 DR-1 緩衝邊界相關）

---

## 步驟覆蓋自檢

| 步驟 | 完成 | 備註 |
|------|------|------|
| 步驟 1 — 需求理解 | ✅ | 已讀 P1-design-spec.md 全文 + 補強計劃 §15.1~§15.7 + 親自 Read CLAUDE_TEMPLATE.md / verifier.md / architect.md / 閉環核心理念.md / 問題追蹤.md 驗證關鍵事實 |
| 步驟 2 — 挑戰式審查 | ✅ | 12 條 BC-x 逐條評估，DR-2 對候選 A 整體做 YAGNI 挑戰，DR-3/4/6 對細節挑戰 |
| 步驟 3 — 架構體質審查 | ✅ | 緩衝 5 邊界（DR-1）+ 機制實證樣本 = 0（DR-2）+ §15.5 預設修正合理性檢查（架構師 step 9c→9d / step 6c-1→步驟 1.a 修正皆正確）|
| 步驟 4 — 驗證式審查 | ✅ | 12 BC-x 皆 [testable]、3 EH-x 覆蓋外部依賴 / 復發 / 範圍邊界、2 IF-x 跨檔契約 |
| 步驟 4.5 — BC ↔ 健康路徑階層 | ✅ | BC-A3 step 9d / BC-A6 步驟 1.a 同抽象層次（單檔 section 內條目掃描）、無漂移 |
| 步驟 5 — 分層審查 | ✅ | 全純功能層無 UI，無依賴方向問題 |
| 步驟 5b — 學習查詢執行 | ✅ | #006 命中（DR-1）+ #007 命中（cross-source review 機制本身）皆有設計引用 |
| 步驟 5c — 事實前提反例檢查 | ✅ | 標「Step 5c 不適用，無外部事實引用」 |
| 步驟 6 — 撰寫報告 | ✅ | 本檔 |

---

## §15.5 預設修正合理性確認

設計規格 line 21-27「§15.5 預設修正」表 2 處修正：

| 預設 | 問題 | 修正 | 審查判定 |
|------|------|------|---------|
| BC-A3 verifier step 9c | step 9c 已存在（事實前提追溯 v5.23.1，verifier.md line 159）| 改 step 9d | ✅ **正確且必要**—9c 不可佔用 |
| BC-A6 architect step 6c-1 | architect.md 無 step 6c-1 命名 | 改主 agent 步驟 1.a 子項（line 17）| ✅ **正確**—主 agent 步驟 1.a 確存在 |

**無其他 §15.5 細節需修正**。架構師對輸入規格的精煉到位。

## 緩衝 5 行邊界判定

依 #006 預防做法 (c)「緩衝 ≥ 5 行硬規則」設計**未違反**（5 等於下限）。但屬「在邊界上」狀態，標 **DR-1 arch-risk**，**不阻擋本閉環**。設計者 line 170 已 explicit 自評符合 #006 自審紀律。

---

## 對 Phase 1 回退判定

**0 high → 不觸發回退**。

**建議流程**：

1. **必跟（記入 P5 arch-risk）**：DR-1（緩衝邊界）+ DR-2（YAGNI 邊緣）
2. **建議用戶 in-place 補修正**（顯著降低 Phase 2 design-implementation drift 風險）：
   - DR-3：BC-E6 補位置 + 對映表結構（low cost · ~3 行）
   - DR-4：R-2 補機械化觸發條件 + R-5 補計數窗口（low cost · ~2 行）
   - DR-6：BC-E1~E5 補 heading level explicit（low cost · 一句）
   - DR-7：IF-1 補操作指引（low cost · 一句）
3. **可選**：DR-5（復發機制成本）—Phase 2 量測一次即可，不必 Phase 1 預先補

若用戶確認 DR-3/4/6/7 補修正 4 條後可直接進 Phase 2 不需第 2 輪重審。若全部接受不修，亦可直接進 Phase 2（皆非阻擋級）。

---

## 審查者立場聲明

本審查嚴格依 design-reviewer.md 規範執行 full-sweep（全量重審），並親自 Grep / Read 驗證關鍵事實：

- CLAUDE_TEMPLATE.md 547 行 ✅（`wc -l` 驗證）
- verifier.md step 9 / 9b / 9c / 10 結構 ✅
- architect.md 主 agent 步驟 1.a「長期模式優先」存在（line 17）✅
- 閉環核心理念.md 228 行 ✅
- 問題追蹤.md #006 / #007 條目內容 ✅
- CLAUDE_TEMPLATE.md line 521 init-claude anchor 系統 ✅
- Section 12 / 12.5 / 13 為 h3 級 ✅（影響 DR-6）

**整體判定**：本設計**結構性合理**，2 個 arch-risk 都是 explicit 標明的已知 trade-off（緩衝邊界 + YAGNI 邊緣），5 個 medium 是「設計補強空間」非「設計錯誤」。配合 cross-source review（#007 預防做法 (a)）的本次 Phase 1b 子 agent + 用戶人工 cross-check 兩層機制，本設計可進 Phase 2。

設計者最值得肯定的點：(a) Phase 1 起手即 explicit 兩個 ⚠️（line 164 比例 / line 166 影響）符合 push back 義務和事實主張閘門精神；(b) §15.5 預設修正快速精煉到位；(c) 依賴影響分析 walk 涵蓋 7 列觸發，僅 BC-E6 對映表與 K-16 對照表關係未澄清為 medium gap。

---

**P1b 完成 → 可進 Phase 2（建議先補 DR-3/4/6/7 medium 後再進）**

最後修訂：2026-05-20（v6.4.0 A+E 捆綁 P1b 第 1 輪審查完成，0 high → 不觸發回退）
