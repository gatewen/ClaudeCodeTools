# Phase 5 Part AB — 雙向追溯報告（v6.0.0）

> 角色：獨立自證審查者（v6.0.0 升級任務 · 唯讀模式）
> 日期：2026-04-26
> Branch：feature/v6.0.0-karpathy
> 上游：P1-design-spec.md v3 + P1b 第 2 輪 + P3 / P4 報告 + 7 個 P2 改動檔案
> 模式：路徑模式直接 Read 全部產出物，不依賴主 agent 轉述

---

## 摘要

| 維度 | 結果 |
|------|------|
| 正向追溯（13 ID） | 13 ✅ / 0 ❌ |
| 反向分析（行為路徑） | 8 條全部對應到 BC-x，0 設計遺漏 / 0 冗餘 |
| arch-risk 緩解（DR-2 / DR-3 / BC-4 by-design） | 3/3 確認緩解（細節見下方判定） |
| Step 9c 事實前提（3 條主張） | 3 強 / 0 中 / 0 弱（詳見 P5-fact-claims.md） |
| 跨 Phase 一致性（R-x = 0 high vs 反向 = 0 未覆蓋） | 一致，純文檔升級的特徵 |
| 是否觸發回退？ | **❌ 不觸發**。所有檢查通過。 |

---

## 步驟 1 — 行為路徑枚舉

v6.0.0 是純文檔 + Skill 邏輯升級，外部可觀察行為集中在：① 文檔讀取（CLAUDE.md / README）、② Skill 部署/升級流程、③ 主 agent runtime 行為（Section 0 / 12.5 觸發）。

| # | 行為路徑 | 觸發者 | 對應 BC |
|---|---------|--------|---------|
| P1 | 用戶讀根 README → 看到 Karpathy 引用 + 跨產出物矛盾陳述 | 用戶 | BC-2 |
| P2 | 用戶讀 dev-closed-loop/README → 看到 Trade-off 宣告 + Karpathy 引用 + v6.0.0 版本歷史條目 | 用戶 | BC-1 同步 + BC-2 同步 + BC-6 同步 |
| P3 | Claude 讀 CLAUDE.md → Section 0 cross-cutting 4 問自檢觸發 | Claude（任一 Phase 內） | BC-3 |
| P4 | 用戶或 Claude 命中 push back 5 條觸發場景 → 主 agent 輸出 ⚠️ 反對格式 | Claude | BC-7 |
| P5a | 用戶執行 `/dev:init-claude upgrade`，cache=v6.0 / deploy=v5.x → 觸發 Step 5 migration flow | 用戶 + Skill | BC-4 + BC-5 |
| P5b | Migration 策略 A 全替換 → 警告丟失客製化後覆蓋 | Skill | BC-5（5.4 A）|
| P5c | Migration 策略 B 智能合併 → 解析 anchors 注入新 Section | Skill | BC-5（5.4 B）+ IF-1 |
| P5d | anchor.match 找不到 → 自動降級策略 C | Skill | EH-2 |
| P5e | 策略 C 手動 diff → 印出 diff | Skill | BC-5（5.4 C）|
| P5f | 部署後驗收 grep `## 0` / `### 12.5` / `## ⚖️ Trade-off` 任一缺失 | Skill | BC-5 5.5 + EH-3 |
| P6 | 用戶 grep CLAUDE_TEMPLATE 末尾「closed-loop v」→ 命中 v6.0.0 / 兩處 README 版本歷史頂列 v6.0.0 | 用戶 / 工具 | BC-6 |
| P7 | Claude 進 Phase 1 讀「五階段閉環流程.md」→ 看到開頭警示行（Section 0 適用所有 Phase） | Claude | BC-3 連動 |
| P8 | Claude 觸發事實主張閘門 → 讀產出物格式.md「Push back 輸出格式」section（Section 12 / 12.5 對稱） | Claude | BC-7 連動 |
| P9 | Claude 讀「閉環核心理念.md」→ 看到「橫切自檢層」+「主動質疑」段（v6.0.0 新增） | Claude | BC-3 連動 + BC-7 連動 |
| P10 | 偵測到非 v5.x / v6.x 版本（v4.x / 無標記）→ EH-1 警告 + AskUserQuestion 三選一 | Skill | EH-1 |

**枚舉完整度檢查**：以上 10 條覆蓋 v6.0.0 引入的全部新行為。**無遺漏路徑**。

---

## 步驟 2 — Part A 正向追溯（從設計 → 實作 → 驗證）

逐項對映 P1-design-spec.md v3 的 BC-x / EH-x / IF-x 到 P2 實作精確位置：

| ID | P1 設計位置（line） | P2 實作位置（file:line） | P3 / P4 驗收 | 標記 |
|----|---------------------|------------------------|--------------|------|
| **BC-1** Trade-off | P1 line 79-111 | `CLAUDE_TEMPLATE.md:3-22` (`## ⚖️ Trade-off 顯式宣告` 21 行) · `dev-closed-loop/README.md:15-17`（外部精簡版 Trade-off 段） | P3 R-2: 21 ≤ 30 ✅ · P4 Test 4: grep 命中 1 | ✅ |
| **BC-2** README Karpathy | P1 line 115-136 | `README.md:5-15` (`## LLM 編碼的根本問題` + Karpathy URL) · `dev-closed-loop/README.md:3-13` 同步 | P3 R-7: 兩處標題 + URL 全命中 ✅ | ✅ |
| **BC-3** Section 0 cross-cutting | P1 line 140-173 | `CLAUDE_TEMPLATE.md:36-54` (`## 0 四原則橫切自檢層`，4 個 Q + 對映表 4 列含 12.5) · 連動 `concepts/閉環核心理念.md:195-201`「橫切自檢層」段 · 連動 `process/五階段閉環流程.md:3` 開頭警示行 | P3 R-2: 20 ≤ 30 ✅ · P4 Test 4: grep `## 0 四原則橫切自檢層` 命中 1 · 自證複測 9 個 Q-token 命中（4 個獨立 + 5 個對映表/設計精神引用，與規格相符） | ✅ |
| **BC-4** migration-notes 區塊 | P1 line 177-185 | `CLAUDE_TEMPLATE.md:470-499`（HTML comment 區塊 30 行，含 5 keys + 3 anchor objects） | P3 R-2: 30 vs 25 多 5 行（**by-design**，見步驟 6）· P4 Test 3: awk 抽出 5 keys ✅ | ✅（by-design） |
| **BC-5** init-claude migration logic | P1 line 189-207 | `init-claude.md:190-245`（Step 5 v5.x→v6.0.0 Migration Flow，含 5.1 偵測 / 5.2 awk 解析 / 5.3 摘要 / 5.4 三策略 / 5.5 驗收，57 行） | P3 R-2: 57 ≤ 80 ✅ · P4 Test 7: 偵測邏輯 + Test 3: awk 解析 ✅ | ✅ |
| **BC-6** 版本號三處 bump | P1 line 211-219 | `CLAUDE_TEMPLATE.md:502` `closed-loop v6.0.0` · `dev-closed-loop/README.md:114` 版本歷史 v6.0.0 條目（對外詳細版）· `README.md:151` 版本歷史 v6.0.0 條目（對內精簡版） | P3 R-1: 三處 v6.0.0 一致 ✅ | ✅ |
| **BC-7** Section 12.5 Push back | P1 line 223-268 | `CLAUDE_TEMPLATE.md:253-279` (`### 12.5 Push Back 義務`，5 條觸發 + 輸出格式 + 設計精神 + 反模式，28 行) · 連動 `concepts/閉環核心理念.md:203-214`「主動質疑」段 · 連動 `standards/產出物格式.md:673-685`「Push back 輸出格式」section | P3 R-2: 28 ≤ 40 ✅ · P4 Test 4: grep `### 12.5 Push Back 義務` 命中 1 · 自證複測：5 條觸發場景齊全（含第 5 條「用戶事實前提待驗證」） | ✅ |
| **EH-1** 未知版本偵測 | P1 line 274-285 | `init-claude.md:200-201`（5.1 空值/v4.x 分支「警告 + AskUserQuestion 三選一 A/C/Abort」） | P4 Test 7: 邏輯架構正常；P5 確認三選一含 Abort 防靜默覆蓋 | ✅ |
| **EH-2** 錨點失敗自動降級 | P1 line 289-298 | `init-claude.md:233`（5.4 B 第 2 步：`找不到 → 觸發 EH-2 自動降級為策略 C`，含警告訊息） | P4 標明「未實測」（Phase 5 追溯範圍）；自證複測：邏輯路徑明確「降級為策略 C」非「fallback 到策略 A」，符合反模式禁令 | ✅ |
| **EH-3** placeholder 未替換 | P1 line 302-308 | `init-claude.md:243`（5.5 `grep -c "{{" ./CLAUDE.md  # 應為 0` 報錯阻擋） | P4 Test 4: 部署驗收 grep 設計正確 | ✅ |
| **EH-4** 依賴連動漏改 | P1 line 312-316 | P3 流程閘門（非 P2 實作項，由 P3 R-1 dependency 連動審查驗證） | P3 R-1：BC-3 三檔同步 ✅ + BC-7 兩檔同步 ✅ + BC-6 三處版本一致 ✅ | ✅ |
| **EH-5** 行數預算超出 | P1 line 320-333 | P3 流程閘門（非 P2 實作項，由 P3 R-3 行數預算驗證） | P3 R-3：CLAUDE_TEMPLATE 510 ≤ 550，緩衝 40 行 ✅（DR-1v2 修正後拉至 ≥ 25 行瘦身要求） | ✅ |
| **IF-1** migration-notes metadata | P1 line 339-395 | `CLAUDE_TEMPLATE.md:470-499` metadata 區塊 + `init-claude.md:202-235`（awk parser + anchors 迴圈） | P4 Test 2: 三 anchor.match 全在 fresh CLAUDE_TEMPLATE 命中 · P4 Test 3: 5 keys + anchors list of objects 完整可解析 · 自證複測：三 anchor.match 字串均無 `{{PLACEHOLDER}}`（DR-1 修正禁令滿足） | ✅ |

**正向追溯結論**：13 ✅ / 0 ❌。每一項均能在 P2 改動的 7 個檔案中精確定位 file:line，無「設計但未實作」的缺漏。

---

## 步驟 3 — Part B 反向分析（從實作 → 設計覆蓋度）

對步驟 1 枚舉的 10 條外部行為路徑反推設計來源：

| 路徑 | 實作落點 | 對應設計 ID | 判定 |
|------|---------|------------|------|
| P1 根 README Karpathy 引用 | `README.md:5-15` | BC-2 | 對應 |
| P2 dev-closed-loop README Trade-off + Karpathy 同步 | `dev-closed-loop/README.md:3-17` | BC-1 同步 + BC-2 同步 + BC-6 v6.0.0 條目 | 對應 |
| P3 Section 0 cross-cutting 4 問 | `CLAUDE_TEMPLATE.md:36-54` | BC-3 | 對應 |
| P4 Push back 5 條觸發 + 輸出格式 | `CLAUDE_TEMPLATE.md:253-279` | BC-7 | 對應 |
| P5a Migration flow 入口（5.1 偵測）| `init-claude.md:194-201` | BC-5（含 EH-1）| 對應 |
| P5b 策略 A 全替換 | `init-claude.md:230` | BC-5 5.4 A | 對應 |
| P5c 策略 B 智能合併 + IF-1 anchors | `init-claude.md:231-235` + `CLAUDE_TEMPLATE.md:489-498` | BC-5 5.4 B + IF-1 | 對應 |
| P5d 錨點失敗降級 | `init-claude.md:233` | EH-2 | 對應 |
| P5e 策略 C 手動 diff | `init-claude.md:236` | BC-5 5.4 C | 對應 |
| P5f 部署驗收 grep | `init-claude.md:238-245` | BC-5 5.5 + EH-3 | 對應 |
| P6 三處 v6.0.0 版本號 | `CLAUDE_TEMPLATE.md:502` + 兩處 README | BC-6 | 對應 |
| P7 process/五階段閉環流程.md 開頭警示 | line 3 | BC-3 連動 | 對應 |
| P8 standards/產出物格式.md「Push back 輸出格式」 | line 673-689 | BC-7 連動 | 對應 |
| P9 concepts/閉環核心理念.md「橫切自檢層」+「主動質疑」 | line 195-214 | BC-3 連動 + BC-7 連動 | 對應 |
| P10 EH-1 未知版本三選一 | `init-claude.md:200-201` | EH-1 | 對應 |

**反向分析結論**：10 條行為路徑（細分至 P5a-P5f 共 15 條落點）**全部對應到 BC-x / EH-x / IF-x**。

- 0 個 **設計遺漏**（無「實作有但設計未說」的隱性決策）
- 0 個 **冗餘文檔段落**（無「P2 順手寫但 P1 沒要求」的 drive-by changes，與 P3 R-8 反模式偵測結果一致）

---

## 步驟 4 — 交叉比對（正向 vs 反向）

| 比對維度 | 結果 |
|---------|------|
| 正向 ❌ 數量 | 0 |
| 反向「遺漏設計」數量 | 0 |
| 反向「冗餘」數量 | 0 |
| 兩向是否互補（即正向缺失 ↔ 反向冗餘）？ | N/A（兩邊皆 0，無互補關係需檢查） |
| 是否有「正向 ✅ 但反向找不到對應路徑」？ | 否。所有 13 ID 都映射到至少 1 條外部行為路徑 |

**結論**：v6.0.0 設計-實作 mapping 完美一一對應。Surgical 原則（Karpathy Q3）落實——P2 沒有越界。

---

## 步驟 5 — 跨 Phase 一致性驗證

按 CLAUDE_TEMPLATE Phase 5 Part C「⛔ 跨 Phase 一致性」要求比對：

- **Phase 3 R-x 統計**：0 high · 0 arch-risk · 0 medium · 1 low（BC-4 30 行 vs 規格 25 行，by-design）
- **Phase 5 反向分析未覆蓋路徑**：0 個

判定：**R-x ≥ 3 但反向 = 0** 不成立（R-x=1 low）；**R-x = 0 但反向發現多** 不成立（反向=0）。**兩數相符**：v6.0.0 是純文檔升級，scope 由 P1 嚴格管控（7 個檔案明確列入「唯一檔案集合」），P2 嚴守 Surgical → P3 R-x 低 + P5 反向覆蓋完整 → 跨 Phase 自洽。

**不要求重做反向，不要求 P3 重審**。

---

## 步驟 6 — arch-risk / by-design 追蹤

### DR-2（P1b v1 arch-risk）：K-17 chain 中間態不一致

**P1b v1 提報**：BC-1→2→3→4→5→6 順序下，BC-4 寫 migration-notes 時 BC-7（K-04 Push back）尚未寫入，產生 migration-notes 聲明「Section 12.5 已新增」但實際結構未到位的中間態。

**v3 修正**：
1. P1 Section 10 line 455-461 加「⚠️ 執行順序硬規則」段，明確「K-17（BC-4/5/6）必須是 chain 最後三步」
2. 執行順序表（line 462-472）重排為 BC-1 → BC-2 → BC-3 → **BC-7** → BC-4 → BC-5 → BC-6
3. P1b 第 2 輪確認 cycle-free（BC-4 描述新結構需先有結構 BC-3/BC-7；BC-5 解析 anchors 需先有 BC-4；BC-6 版本 bump 不依賴他者）

**P5 實際確認**：
- BC-4 migration-notes line 477-479 列出 breaking-changes：「新增 Section 0 / 新增 Section 12.5 / 新增 Trade-off 段」——這 3 句必須在 BC-3 (Section 0) / BC-7 (Section 12.5) / BC-1 (Trade-off) 都實作後才會「真實」
- 在當前 commit 候選的工作樹中：Section 0（line 36-54）✅ + Section 12.5（line 253-279）✅ + Trade-off（line 3-22）✅ + migration-notes（line 470-499）✅ — **同檔案的不同段落同時存在，無中間態問題**
- git status 顯示 7 個檔案皆為「modified」未 commit，工作樹是原子單位 → BC-4 寫的內容跟實際結構自始一致，未產生中間態

**緩解判定**：✅ **真消除**。執行順序硬規則 + cycle-free + 工作樹原子提交三重保證。

---

### DR-3（P1b v1 arch-risk）：行數預算過薄

**P1b v1 提報**：原預算 v5.23.1 (444) + 新增 (125) - 瘦身 (20) = 549 ≤ 550，緩衝僅 1 行 brittle。

**v3 修正**（DR-3v2 採用 P1b 第 2 輪建議方案 1）：
- 強制瘦身 ≥ 20 → ≥ 25 行
- EH-5 上限 600 → 575
- 預算目標 549 → 544，緩衝 6 行

**P5 實際確認**：
- 當前 CLAUDE_TEMPLATE.md 實際行數 **510**（P3 R-3 + 自證 wc -l 雙重確認）
- 規格上限 550 → 緩衝 **40 行**（不是規劃的 6 行，遠超預期）
- 為何更寬鬆？P3 R-3 解釋：「BC-x 各項都比上限有空間」（BC-1 21/30、BC-3 20/30、BC-4 30/25 多但其他都低、BC-7 28/40、BC-5 不在 CLAUDE_TEMPLATE 計）—— 實際淨增 66 行 vs 規劃 100 行

**v6.1+ 膨脹空間判定**：
- 510 → 575 還有 65 行空間（v6.1.0 K-02/K-03/K-05/K-06/K-08/K-16 規劃 6 條，design/08 line 67-72）
- 風險點：v5.15 才從 606 → 361 瘦身過，若 v6.1+ 沒守住預算可能再走「膨脹 → 大瘦身」週期
- 緩解：DR-3 立下的「執行順序表 Step 8 強制瘦身」紀律可延續到 v6.1+

**緩解判定**：✅ **真消除（且超預期）**。實際緩衝 40 行 >> 規劃 6 行，v6.0.0 落地壓力遠低於預警值。但 v6.1.0 啟動前須重新評估累積膨脹趨勢。

---

### BC-4 by-design（P3 R-1 low）：migration-notes 30 行 vs 規格 25 行

**P3 提報理由**：
1. DR-1 將 anchors 升級為 list of objects + position 後，3 個 anchor 各占 3 行 = 9 行
2. 加上 5 keys 各自 2-3 行內容，總體比原預估多 5 行
3. 功能性驗收全過（5 keys 完整、3 anchor.match 全 grep 命中、awk 解析正常）
4. 若硬瘦身會降低可讀性、影響 init-claude.md Step 5.2 awk parser 對多行 YAML-like 結構的解析

**P5 親自驗證**（步驟 4 的 awk 範圍 470-500 抽出實際內容）：
- HTML comment wrapper 占 2 行（`<!--` 與 `-->`）
- 註解標題 + 空行占 2 行
- from-version / to-version 占 3 行（含空行）
- breaking-changes（標題 + 3 條 + 空行）占 5 行
- required-actions（標題 + 2 條 + 空行）占 4 行
- recommended-actions（標題 + 2 條 + 空行）占 4 行
- anchors（標題 + 3 個 object × 3 行）占 10 行
- 總計：2+2+3+5+4+4+10 = **30 行**（與 P3 計數一致）

**理論最低瘦身極限**：
- anchors 改回 flat dict（如 `section-0: "## ⚠️ ..."`）→ 從 10 行 → 4 行（節省 6 行）但 **觸發 DR-1 反模式**（無 position 屬性 + 無 name），是 P1b v1 已被修正的 high 風險
- 多條清單合併為單行（如 `breaking-changes: ["A", "B", "C"]`）→ 節省 3 行但破壞 init-claude.md 5.2 的 awk parser（按 `b ~ /migration-notes/` 多行字串模式匹配）

**by-design 標記合理性**：
- ✅ 5 行超出是 DR-1 高品質修正的**自然成本**（anchors 從 dict 升 list of objects）
- ✅ 強行瘦身會引入新 bug（DR-1 已被修過的 placeholder anchor 風險）或 BC-5 parser 重寫
- ✅ 510 / 550 總行數預算下 5 行絕對值對全檔無影響（< 1%）

**判定**：✅ **by-design 標記合理**，建議保留。Phase 5 不要求 P2 修正。

---

## 步驟 7 — Step 9c 事實前提追溯

**v6.0.0 的 3 條核心事實主張詳細追溯見 `P5-fact-claims.md`**。本節摘要：

| 主張 | 評級 |
|------|------|
| 「v6.0.0 是 major bump」 | 強（A 級結構性論證 + 原則性條件，反例通過） |
| 「Karpathy 4 原則來自 forrestchang/andrej-karpathy-skills」 | 強（A 級字面引用 + URL，反例通過） |
| 「v6.0.0 不偷 K-14 scope」 | 強（A 級 design/08 milestone 規劃 + BC-7 第 5 條輕量化標註，反例通過） |

3 條全為 **強**，無弱證據主張需要處置。**不觸發回退**。

---

## 升格候選（learning-log → 長期警惕模式）

掃描本次 v6.0.0 所有 Phase 的事件，識別「達 ≥ 3 次需升格」的高頻問題模式：

| 候選模式 | 出現次數 | 來源 | 是否升格 |
|---------|---------|------|---------|
| 「DR 修正引入新副作用（傳遞性）」 | 2（DR-1 → DR-2v2 / DR-3 → DR-1v2）| P1b v2 第 2 輪 | < 3，**不升格**，但建議 architect 在 v6.1+ 設計時主動檢查「修一個方向太緊」的次生風險 |
| 「migration anchor 用 placeholder 字串」 | 1（DR-1）| P1b v1 high | < 3，**不升格**，已透過「anchor.match 禁止含 `{{PLACEHOLDER}}`」規則寫入 IF-1 規格 |
| 「行數預算膨脹週期」 | 2（v5.15 606→361 / v6.0.0 444→510）| design/08 RISK-2 + P3 R-3 | < 3，但**建議 v6.1+ 啟動前重新評估**。若 v6.1.0 / v6.2.0 累積後 ≥ 3 次膨脹則升格 |
| 「by-design 標記合理性需 Phase 5 二度確認」 | 1（BC-4）| P3 R-1 + P5 步驟 6 | < 3，**不升格** |

**結論**：本次 v6.0.0 升級**無立即升格候選**（皆未達 ≥ 3 次門檻）。建議架構師（architect.md）在 v6.1.0 P1 設計前讀此節，主動檢查「DR 修正傳遞性」與「行數預算膨脹週期」兩個低頻但有累積趨勢的模式。

---

## 提交前自檢

| 自檢項 | 狀態 |
|--------|------|
| 13 個 ID 全部追溯到 file:line | ✅ |
| 行為路徑枚舉覆蓋 v6.0.0 全部新增行為 | ✅（10 條，含 P5 6 子路徑）|
| Part A 與 Part B 雙向比對完成 | ✅ |
| 跨 Phase 一致性（R-x vs 反向）已驗證 | ✅ |
| arch-risk / by-design 三條獨立判定 | ✅（全部 ✅ 緩解） |
| Step 9c 事實前提追溯（強/中/弱）| ✅（3 強 / 0 弱，詳見 P5-fact-claims.md）|
| 升格候選掃描完成 | ✅（0 立即候選，2 累積觀察項）|
| 唯讀模式（未修改任何檔案） | ✅ |

---

## 對 Phase 1-4 的回退判定

**❌ 不觸發回退**。

- 設計-實作一致性：✅（13/13 對應）
- 測試覆蓋（部署驗證）：✅（P4 7/7 通過）
- 檢核未修：✅（P3 0 high，1 low by-design 已合理化）
- DR-x 處理狀態：✅（v1 7 條全到位，v2 3 條全採用）
- 產出物完整性：✅（P1-design-spec / P1b / P3 / P4 全在 `.claude-loop/artifacts/`，本次新增 P5AB + P5-fact-claims）
- 跨 Phase 一致性：✅（R-x = 1 low / 反向 = 0，純文檔升級特徵）

**結論**：v6.0.0 雙向追溯通過，可進入 Phase 5 Part C（主 agent 整體評估 + commit）。

---

## 審查者立場聲明

本審查嚴格依 verifier.md「獨立自證審查者」規範執行：

1. **不依賴主 agent 轉述**：路徑模式直接 Read 全部 5 個產出物（P1 / P1b / P3 / P4 / design/08）+ 7 個 P2 改動檔案
2. **不知道開發過程的推理**：本審查只看設計結果與實作落點，不看 P2 implementer 的選擇理由
3. **未修改任何檔案**：唯讀執行，僅產出本報告 + P5-fact-claims.md
4. **親自 grep / awk 驗證關鍵事實**：CLAUDE_TEMPLATE.md 行數（510）/ 三 anchor.match 命中 / migration-notes 區塊內容 / Section 0 4 個 Q 完整性 / BC-7 5 條觸發場景齊全 / 三處 v6.0.0 版本號

**對 v6.0.0 的整體判定**：

> **v6.0.0 是本 repo 自 v5.x 系列以來執行最乾淨的 major bump**。設計-實作 mapping 13/13 完美對應，0 設計遺漏 + 0 冗餘 + 0 反模式。P1b 兩輪重審 + DR 修正全部到位。唯一的 by-design 標記（BC-4 30 vs 25 行）是 DR-1 高品質升級的合理代價，不是缺失。

**留給 v6.1.0 設計階段的兩個觀察項**（非阻擋級）：

1. **DR 修正傳遞性**：v6.0.0 兩次出現「修一個方向太緊→引入次生問題」（DR-1→DR-2v2 / DR-3→DR-1v2），建議 architect.md 在 P1 設計時加自檢「我這個修正會不會在另一個維度造成新限制？」
2. **行數預算累積**：v6.0.0 510 行已用掉 v5.23.1 (444) + 66 行新增。v6.1+ 6 條 K-x 若無預算控制可能再次觸發 v5.15 級瘦身。建議 v6.1.0 P1 啟動前重新評估累積膨脹趨勢。

---

最後修訂：2026-04-26（Phase 5 Part AB 雙向追溯完成 · 13 ✅ 0 ❌ · 不觸發回退 · 可進 Part C）
