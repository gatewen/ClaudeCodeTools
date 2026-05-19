# 補強計劃 — 從 closed-loop-autonomy-v2.md 提煉強化點

> **狀態**：Phase A 框架（草案）
> **建立日期**：2026-05-19
> **作者**：Claude Opus 4.7（單 LLM 起草 — 紅線 1 適用，需 cross-source 校準才可進方法論）
> **目的**：對應本 repo 已觀察到的痛點，從 v2 文件挑出**有效的補強**，**不全盤接受**
> **方法**：高標準篩選 → 7 維度評分 → 切解任務 → 逐項閉環

---

## 1. 來源校準

**來源檔**：`/Users/gatewenlee/AI-ClaudeCode/closed-loop-autonomy-v2.md`（2062 行 / 79KB）
**性質**：

- 用戶 self-declaration 為「裡面每一項都是實戰後的結果」（A 級證據 · 2026-05-19 對話）
- 適用範圍：v2 的具體數字（30 閉環 / 17 archetype / 1700 行 learning-log）為 **cross-project baseline**，**不是本 repo self-evidence**
- 引用入本 repo 時須明示 cross-project 來源，不可作為 self-evident 數據呈現

**版本**：v2.0（v1.0 已存在於 repo 根目錄，48KB · 2026-05-19 建立 · self-contained 重構為 v2.0）

---

## 2. 目的聲明

**補強 ≠ 替換**：取對本 repo **已觀察痛點**有用的部分強化既有方法論，**不**導入 v2 整體框架（特別是 Auto-Continuity 全套 + AI 自治決策）。

**判定基準**：對應本 repo 實際存在的證據（learning-log / 問題追蹤 / 對話脈絡），不是 v2 文件講的痛點。

---

## 3. 五條篩選原則

1. **真痛點對應**：對應本 repo 已觀察的痛點（learning-log / 問題追蹤 / 對話記憶有跡可循），不是 v2 講的痛點
2. **不命中 v2 自身問題**：避免引入會自打嘴巴的東西（特別是命中 #007 single-source 評估盲點 / Archetype 1 Negative-Assertion）
3. **規模可控**：單項修改 ≤ 50 行 CLAUDE_TEMPLATE 或對等量；不能讓 547 行膨脹失控
4. **不削弱既有設計**：質疑熔斷協議 / push back 義務 / 長期警惕模式必讀這三條認知驗證 fallback 不能被弱化
5. **可實證**：有量測標準或閉環內可觀察的指標

---

## 4. 四條紅線（hard rules · 不可破）

```
🚫 紅線 1：不採納 single-LLM 自評類機制（避免本 repo 命中 #007）
🚫 紅線 2：不引入 baseline token tax 膨脹（SessionStart 大量灌讀類）
🚫 紅線 3：不削弱質疑熔斷協議（用戶在 loop 是現有認知驗證的最後 fallback）
🚫 紅線 4（meta）：補強計劃自身的執行必須走精簡閉環或完整閉環，避免 dogfooding-1 §5.5 self-irony 重蹈（spec 自身沒跑閉環）
```

---

## 5. 七維度評分系統

| 維度 | 權重 | 評分依據（0-10） |
|------|------|----------------|
| 真痛點對應度 | 25% | 是否對應本 repo 已觀察痛點（有 learning-log / 問題追蹤 / 對話脈絡證據） |
| 不命中 v2 自身問題 | 15% | 是否命中 v2 自身缺陷（命中即扣大量；觸及紅線 = 0 分否決） |
| 規模可控度 | 15% | 修改規模（CLAUDE_TEMPLATE 行數變動 + 連動檔案數量） |
| 不削弱現有設計 | 15% | 副作用評估（對既有閘門 / fallback / 認知驗證的影響） |
| 可實證度 | 10% | 是否有可量測的閉環內或跨閉環指標 |
| ROI | 10% | token 節省 / 品質提升 / 痛點降低幅度 |
| 時機適切 | 10% | 本 repo 當前階段是否需要（baseline 6 閉環 / 對外推廣未啟動） |

**門檻**：

| 加權總分 | 級別 | 處置 |
|---------|------|------|
| ≥ 80 / 100 | A 級 | 採納 → 進入精簡或完整閉環實施 |
| 65 - 79 | B 級 | 條件採納（必附配套：限縮範圍 / 加紅線 / 觀察期） |
| < 65 | 拒絕 | 不採納（理由入「拒絕清單」） |

**評分原則**：

- 任一維度 ≤ 3 分 → 觸發整體 review（不可只看加權總分）
- 紅線檢查若任一觸及 → 否決（不論加權分數）
- 評分必附「為何此分」的一句話依據（避免變成 hand-wavy 數字）

---

## 6. 十候選總覽表

| # | 候選 | 對應 v2 章節 | 初判狀態 | 詳細評分 |
|---|------|-------------|---------|---------|
| **A** | 升格降級機制 | §1.6.4 | ✅ B 級採納待實施 | Phase B → 78.5/100 |
| **E** | 8 條 Anti-patterns | §5.2 | ✅ A 級採納待實施 | Phase C → 81/100 |
| **C** | 機械化驗證去重 | §2.2 + §3.4 | ❌ 拒絕 | Phase D → 60/100 |
| **B** | L1/L2/L3 決策分層（僅取分類定義） | §3.1.2 + §3.2 | ❌ 拒絕（v2 review 後決策） | Phase E → 66/100 + 選項 D 拒絕 |
| G | 17 Archetypes 對映表 | App B | ⏸️ 延後 | — |
| D | spec literal anchor 機制 | §3.4 + §2.3 | ⏸️ 延後 | — |
| F | Methodology Primer（PART I） | PART I | ❌ 拒絕 | — |
| H | 證據鏈 regex hook | §3.3.2 | ❌ 拒絕 | — |
| I | Auto-Continuity 全套 | §3.4 訴求 A | ❌ 拒絕 | — |
| J | 7 維度評分模型（v2 給 L2 自選用） | §3.5.1 | ❌ 拒絕 | — |

> 「初判狀態」基於框架階段的直覺判斷（未跑完整 7 維評分）。Phase B-E 將逐一跑完整評分驗證初判，**若評分結果不達 A/B 門檻，初判會被推翻**。

---

## 7. 採用候選清單（共 4 個 · 詳細評分待 Phase B-E）

### A 級候選（≥ 80/100 預期）

**候選 A — 升格降級機制** → Phase B 評為 B 級 78.5（採納待實施）
- 對應 v2：§1.6.4 Promotion Reversal
- 對應本 repo 痛點：問題追蹤.md 「長期警惕模式」section 升格機制只升不降。當前 7 條（#001-#007），每次 Phase 1 起手 architect 必讀全部，累積後 baseline 線性膨脹。learning-log 已觀察的「降級機制」議題（§1.6.4 v2 文件指出）對齊本 repo 現況。
- 預期修改範圍：問題追蹤.md（新增降級機制段）+ verifier agent（加入降級檢查）+ CLAUDE_TEMPLATE.md Phase 5 升格檢查段對稱補降級檢查

~~**候選 C — 機械化驗證去重**~~ → Phase D 評為拒絕 60（已移入 §9 拒絕清單）

**候選 E — 8 條 Anti-patterns（特別是其中 4 條）**
- 對應 v2：§5.2 Anti-Patterns
- 對應本 repo 痛點：本 repo 缺少明文「自治化反向劃線」。即使不做自治化，這 4 條（「P3 quality 永不降級」「自治不等於黑盒」「為了自治放棄 push back」「自治模式跳過 retrospective」）對本 repo 既有 push back / 配額管理紀律有強化價值。
- 預期修改範圍：CLAUDE_TEMPLATE.md Section 12.5 末尾加「Anti-patterns 反向劃線」副段，或單獨增 Section 13.5

### ~~B 級候選~~ → **無**（候選 B 已拒絕 · 詳見 §9）

~~**候選 B — L1/L2/L3 決策分層**~~ → Phase E 評為 66/100 B 級邊緣 + v2 review 後選項 D 拒絕（已移入 §9 拒絕清單）

---

## 8. 延後清單與啟用條件

| 候選 | 延後理由 | 啟用條件 |
|------|---------|---------|
| **G. 17 Archetypes 對映表** | 本 repo 7 條夠用；對映表的價值在跨 repo 推廣 | 本 repo 啟動對外輸出方法論時（≥ 3 個外部專案採納） |
| **D. spec literal anchor** | 本 repo 規模 547 行 CLAUDE_TEMPLATE 還沒到 spec drift 高頻發生 | 累積 ≥ 3 次跨閉環 spec literal 失準觀察事件 |

---

## 9. 拒絕清單與理由

| 候選 | 拒絕理由 | 觸發的紅線 |
|------|---------|-----------|
| **F. Methodology Primer** | 本 repo 還沒到對外推廣方法論的階段；445 行 onboarding 教學對內部無 ROI | 紅線 2（baseline 膨脹）|
| **H. 證據鏈 regex hook** | regex 對 LLM output 比對誤判率高；過度打斷既有工作流；Section 12 事實主張閘門已是更精準的 LLM 自律機制 | 紅線 3（誤觸發會弱化既有閘門）|
| **I. Auto-Continuity 全套** | 每日日誌系統 + Stop hook 提醒已部分解決跨 session 失憶；auto-/clear 不可逆副作用高；context 自監測在錯誤時間點觸發風險 | 紅線 2 + 紅線 3 |
| **J. 7 維度評分模型（v2 §3.5.1）** | LLM 自評打分本身命中 #007 single-source；分數成為決策依據後反而成為新盲點來源 | 紅線 1 |
| **C. 機械化驗證去重**（Phase D 評分結果 60/100）| 規模 9-10 檔超過單一候選合理範圍 + 本 repo 規模 ROI 不足實證 + 時機未到（需 20+ 閉環累積） + sub-agent 獨立性原則設計張力。詳細評分見 §13 | 紅線 2 + 紅線 3（皆邊緣觸線）|
| **B. L1/L2/L3 決策分層**（Phase E 評 66/100 B 級邊緣 + 選項 D 後拒絕）| Phase E 評為 B 級邊緣（66/100 壓門檻 +1）。Phase G v2 cross-source review 後揭露捆綁實作會撞 600 行上限。選項 D 取消 Phase G + 拒絕候選 B（風險/行數空間不對等）。詳細評分見 §14，選項 D 處置見 §13.5.14 | — |
| **Phase G. 行數優化專案**（v1+v2 兩輪 review needs-attention · 選項 D 後取消）| Phase G v1（A1/B1/B2/B3）Codex review 抓 2 high + 2 medium → v2 重設 → v2 review 再抓 2 high + 1 medium（v1 F1 沒真解決 + Step 5.1 trigger 架構盲點 + 文檔自我矛盾）。連續 2 次 needs-attention = 設計範疇 mismatch。工程改造規模超出原 scope。詳見 §13.5.13/14 | 紅線 2（v1 + v2 兩輪都觸線）|

---

## 10. 切解任務索引

| Phase | 任務 | 預期長度 | 產出 | 狀態 |
|-------|------|---------|------|------|
| **A** | 框架草案（本份） | ~150 行 | 本檔（13-...md）| ✅ 完成 |
| **B** | 候選 A（升格降級機制）詳細評分 | ~120 行 | §11 | ✅ 完成 · **B 級 78.5 採納** |
| **C** | 候選 **E**（8 條 Anti-patterns）詳細評分（順序調整：原 D 提前）| ~140 行 | §12 | ✅ 完成 · **A 級 81 採納** |
| **D** | 候選 **C**（機械化驗證去重）詳細評分（順序調整：原 C 延後）| ~100 行 | §13 | ✅ 完成 · **拒絕 60** |
| **G** | ~~插隊：CLAUDE_TEMPLATE.md 行數優化~~ → **❌ 取消**（v1+v2 兩輪 Codex review needs-attention · 選項 D 處置）| ~150 行 | §13.5 + §13.5.12/13/14 | ✅ 流程完成 · **取消決策已下** |
| **E** | 候選 B（L1/L2/L3 部分）詳細評分 → 66/100 B 級邊緣 → 選項 D 拒絕 | ~80 行 | §14 | ✅ 完成 · **拒絕**（v2 review 後決策）|
| **F** | 整合：依賴表 walk + 連動檔案總表 + 實施順序 + 驗證指標基線 | ~50 行 | 本檔追加 §15 | ⏳ 待啟動（最終採納清單 = A + E 二候選） |

**交付節奏**：每 Phase 完成後等用戶確認再進下個。不一次推進。

---

## 11. Phase B — 候選 A：升格降級機制（B 級採納待實施）

> **狀態**：B 級採納（含 4 條配套條件）· 評分 78.5/100 · 2026-05-19 用戶確認

### 11.1 七維度評分

| 維度 | 權重 | 分數 | 一句話依據 |
|------|------|------|----------|
| 真痛點對應度 | 25% | 8/10 | 問題追蹤.md 7 條（#001-#007）都未曾降級 + architect Phase 1 6c-1 必讀條目線性膨脹是結構性痛點；本 repo baseline 6 閉環量未到 immediate ROI |
| 不命中 v2 自身問題 | 15% | 9/10 | 降級觸發是 deterministic 計數（n=10 / n=20 連續 0 復發），不依賴 LLM 評分 |
| 規模可控度 | 15% | 7/10 | ~58 行跨 5 個檔案，跨檔義務偏重 |
| 不削弱現有設計 | 15% | 9/10 | 不影響質疑熔斷 / push back / 認知驗證；降級條目仍在文件中（移到「條件式」section） |
| 可實證度 | 10% | 9/10 | 指標明確：降級率 / 6c-1 token 成本 / 復發率，全 grep 可驗證 |
| ROI | 10% | 6/10 | 短期低（最早觸發降級的 #006 距 n=10 還早）；長期高（結構性預防膨脹） |
| 時機適切 | 10% | 6/10 | 機制可先建，啟用時機未到（無條目達門檻） |

**加權計算**：

```
(8×0.25 + 9×0.15 + 7×0.15 + 9×0.15 + 9×0.10 + 6×0.10 + 6×0.10) × 10
= (2.0 + 1.35 + 1.05 + 1.35 + 0.9 + 0.6 + 0.6) × 10
= 78.5 / 100
```

**級別判定**：78.5 ∈ [65, 79] → **B 級**

### 11.2 初判修正記錄

Phase A 框架（§6 候選總覽表）初判為「✅ A 級」。完整跑完評分後實際為 **B 級（78.5）**。原因：規模 7/10 + ROI 6/10 + 時機 6/10 三項較低拖累整體分。

此即 §16 元紀律第 1 條「不可只憑直覺採納」的功能 — **揭露初判偏誤**。Phase A 的初判表將不修正（保留作為對照證據）。

### 11.3 四條配套條件（採納前提）

1. **dormant 啟用模式**：機制寫進方法論但設「啟用條件」= 任一升格條目達 n=10 連續 0 復發才正式執行降級。本 repo 當前 0 條達門檻 → 機制 dormant，不執行降級
2. **範圍限縮**：種子條目 #001-#005（外部來源，無本 repo learning-log 累積證據）**不適用降級**。只有從本 repo learning-log 真升格的條目（#006、#007，及未來）適用
3. **降級不刪除**：降級 = 標記「⏸️ 條件式」+ 移到問題追蹤.md 末尾「條件式紀律」section。下次復發 → 升回 active
4. **降級檢查機械化**：Phase 5 verifier 加 step 9c 降級檢查（grep learning-log 累積 N 閉環無對應 root cause），不依賴 LLM 判斷

### 11.4 修改方案（5 處）

| # | 檔案 | 改動 | 預估行數 |
|---|------|------|---------|
| 1 | `.claudedocs/records/問題追蹤.md` | 新增「降級機制」section（升格條件後）+「條件式紀律」section（檔案末尾） | +30 |
| 2 | `.claudedocs/agents/verifier.md` | 新增 step 9c「降級候選檢查」 | +15 |
| 3 | `CLAUDE_TEMPLATE.md` Phase 5 升格檢查段（~line 372-377） | 對稱補「降級檢查」一行（指向 verifier step 9c） | +3 |
| 4 | `CLAUDE_TEMPLATE.md` 精簡閉環步驟 4.5 升格檢查段（~line 408-415） | 對稱補「降級檢查」邏輯（主 agent 自做） | +5 |
| 5 | `.claudedocs/agents/architect.md` step 6c-1 邏輯 | 加「⏸️ 條件式」標記識別 — 條件式條目仍讀，視為「弱信號」 | +5 |

**總計**：~58 行跨 5 檔。CLAUDE_TEMPLATE.md 預估 547 → 555（在 v6.3.0 預算 580 內，緩衝 25）

### 11.5 CLAUDE.md 依賴表 walk

按本 repo CLAUDE.md「修改前依賴影響分析」逐改動位置查連動義務：

| 改動位置 | 觸發 CLAUDE.md 列 | 連動檔案 |
|---------|------------------|---------|
| verifier.md step 9c | 第 8 列（agent 步驟變更） | ✓ CLAUDE_TEMPLATE.md Phase 5 段；✓ 五階段閉環流程.md；Agent使用指南.md（調用方式未變，不連動） |
| architect.md step 6c-1 | 第 8 列 | ✓ CLAUDE_TEMPLATE.md Phase 1 / 6c-1 段；✓ 五階段閉環流程.md |
| CLAUDE_TEMPLATE.md Phase 5 段 | 第 1 列（Phase 流程 / 閘門 / 規則） | ✓ 五階段閉環流程.md |
| CLAUDE_TEMPLATE.md 精簡閉環步驟 4.5 | 第 1 列 | ✓ 五階段閉環流程.md |
| 問題追蹤.md 新增 section | 自包含結構新增 | 建議補：閉環核心理念.md 升格 concept 段補對稱「降級」概念（+2 行） |
| 版本號變更（採納實施後） | 第 11 列（版本同步 3 處） | ✓ CLAUDE_TEMPLATE.md 末尾、dev-closed-loop/README.md、根 README.md |

**對外契約檢查**：`test-cross-file-consistency.sh` 等 7 smoke 不含 verifier step 編號斷言 → **不影響**

### 11.6 四條紅線檢查

| 紅線 | 通過？ | 說明 |
|------|-------|------|
| 1. 不採 single-LLM 自評機制 | ✅ | 降級觸發是計數（grep + count），不是 LLM 評分 |
| 2. 不引入 baseline 膨脹 | ✅ | 配套 1 dormant 啟用 → 當前 0 額外執行；活躍後僅 +5 行邏輯 |
| 3. 不削弱質疑熔斷 | ✅ | 與認知驗證 fallback 完全無交集 |
| 4. meta（自身走閉環） | ⏳ 待採納實施 | 採納後實作走精簡閉環六步（5 檔 < 300 行 = 中型範圍）|

### 11.7 採納狀態

✅ **B 級採納待實施**（2026-05-19 用戶決策：選 1 採納 + 4 配套）

**實施時機**：Phase C-E 全部評分完成後，所有採納的候選一起走實作閉環（捆綁規模可能升為大型完整 5-Phase，或單個走精簡六步——依採納總規模判定）。

**實施前再做 cross-source review**（元紀律第 5 條 · 本檔由單 LLM 起草自指紅線 1）。

---

## 12. Phase C — 候選 E：8 條 Anti-patterns（A 級採納待實施）

> **狀態**：A 級採納（含 4 條配套條件）· 評分 81/100 · 2026-05-19 用戶確認

### 12.1 七維度評分

| 維度 | 權重 | 分數 | 一句話依據 |
|------|------|------|----------|
| 真痛點對應度 | 25% | 7/10 | 5/8 條對應強化本 repo 既有紀律（Section 12 / 12.5 / 1.8 配額 / 升格機制 / learning-log）；但本 repo 從未發生「為效率放棄 push back / 跳過 P3」事件，是預防性而非修補性 |
| 不命中 v2 自身問題 | 15% | 10/10 | 反向劃線是 deterministic hard rule，純文字添加零認知性風險 |
| 規模可控度 | 15% | 9/10 | 單檔修改（CLAUDE_TEMPLATE.md）+ 1 連動檔案，預估 +20 行 |
| 不削弱現有設計 | 15% | 10/10 | 純強化既有紀律，無副作用 |
| 可實證度 | 10% | 6/10 | absence-based 量測難（「沒違反」很難當 KPI） |
| ROI | 10% | 6/10 | 短期低（沒違反事件 → 沒明顯收益）；長期中高（防未來引入自治化失守）|
| 時機適切 | 10% | 8/10 | 本 repo 不採自治化，但反向劃線作為「明文化既有紀律」時機 always 適合 |

**加權計算**：

```
(7×0.25 + 10×0.15 + 9×0.15 + 10×0.15 + 6×0.10 + 6×0.10 + 8×0.10) × 10
= (1.75 + 1.5 + 1.35 + 1.5 + 0.6 + 0.6 + 0.8) × 10
= 81 / 100
```

**級別判定**：81 ≥ 80 → **A 級**（剛壓門檻線）

### 12.2 評分系統區分力驗證

候選 A 評分 78.5（B 級）、候選 E 評分 81（A 級剛壓線）。兩個候選相差 2.5 分剛好跨 A/B 級門檻。**評分系統區分力**得到實證：

- 對「初判為強候選」的兩個項目，7 維評分能拉出 A vs B 的差異
- 主要差異維度：規模（候選 A 5 檔 / 候選 E 2 檔）+ 不削弱現有設計（候選 E 純強化，候選 A 仍有少量副作用空間）+ 不命中 v2 問題（候選 E hard rule 是 10，候選 A 計數機制是 9）

評分權重分配（25/15/15/15/10/10/10）暫時保留，**等 Phase D-E 全部評完後若仍區分力足夠，正式定案**。

### 12.3 四條配套條件（採納前提）

1. **重寫去「自治化」前綴**：v2 原文「為了自治...」前綴全部砍掉，通用化為「為了任何效率 / 簡化 / 進度理由...」，避免引入本 repo 不採的 L1/L2/L3 上下文
2. **8 條精選為 5 條**：去重（1+5+8 合併、2+4 合併）+ 去依賴（砍 v2 第 3 條依賴 L1/L2/L3 分層那條，延後到 Phase E）+ 新增本 repo 特有 R-5（spec self-irony 紀律 · 自 dogfooding-1 §5.5）
3. **位置 Section 13.5「反向劃線（紀律保底）」**：放在 Section 13 質疑熔斷後、`{{LANGUAGE_SKILL_SECTION}}` 之前，作為**方法論保底層**。與 Section 0 四原則橫切自檢首尾呼應
4. **連動補閉環核心理念.md**：新增「紀律保底層」概念段（+5 行對映表），讓人類讀者也看到反向劃線

### 12.4 五條反向劃線文字（R-1 ~ R-5）

| # | 原 v2 條目 | 通用化文字 | 對映本 repo 既有紀律 |
|---|-----------|----------|-------------------|
| **R-1** | 1+5+8 合併 | 不可為任何效率 / 簡化 / 進度理由弱化事實主張閘門（Section 12）、push back 義務（Section 12.5）、Phase 5 升格檢查 | Section 12 / 12.5 / Phase 5 |
| **R-2** | 2+4 合併 | Phase 3 quality 永不降級（壓測實證 ROI 最高、100% 攔截率）— 寧 deferred 整個閉環也不降 P3 | Section 1.8 + dogfooding-1 §5.3 |
| **R-3** | 6 | 升格機制 / 降級機制 / 兩層教訓架構不可被任何理由 bypass | 6c-1 / 6c-2 / 候選 A 降級機制 |
| **R-4** | 7 通用化 | BC-x / EH-x / IF-x 編號不可為效率壓縮（合約精確性 > 簡潔）| 產出物格式.md / Phase 1 |
| **R-5** | （新增 · 本 repo 特有）| Spec 設計 / 重大方法論修改自身必走精簡或完整閉環（避免 spec self-irony）| dogfooding-1 §5.5 |

**砍掉**：v2 第 3 條（「不必須 AskUserQuestion」依賴 L1/L2/L3 分層）→ 延後到 Phase E 候選 B 採納後再決定

### 12.5 修改方案（2 處）

| # | 檔案 | 改動 | 預估行數 |
|---|------|------|---------|
| 1 | `CLAUDE_TEMPLATE.md` Section 13 質疑熔斷之後 | 新增 `### 13.5 反向劃線（紀律保底）`，5 條 R-1 ~ R-5 hard rule | +20 |
| 2 | `.claudedocs/concepts/閉環核心理念.md` | 新增「紀律保底層」概念段 + 對映表（首尾呼應四原則橫切自檢） | +5 |

**總計**：~25 行跨 2 檔。CLAUDE_TEMPLATE.md 預估 547 → 567（v6.3.0 預算 580 內，**緩衝 13 行**）

### 12.6 ⚠️ 規模警示：捆綁採納風險

若 **捆綁採納候選 A + E** 一起實作：

- 候選 A 預估 547 → 555（緩衝 25）
- 候選 E 預估 547 → 567（緩衝 13）
- 捆綁 A + E：547 → 575（緩衝僅 **5 行**）→ 命中 **#006「行數預算估算樂觀」**升格條目的觸發信號

**處置**：實作閉環時務必做 `wc -l` 主動驗證（#006 預防做法 b），且每個結構化區塊（migration-notes / anchors / 對映表）單獨估 ≥ 15-20 行（不能當「條目」單行算）

### 12.7 CLAUDE.md 依賴表 walk

| 改動位置 | 觸發 CLAUDE.md 列 | 連動檔案 |
|---------|------------------|---------|
| CLAUDE_TEMPLATE.md 新增 Section 13.5 | 第 1 列（Phase 流程 / 閘門 / 規則）| ✓ 五階段閉環流程.md（無需，因為非 Phase 內規則）→ 跳過 |
| CLAUDE_TEMPLATE.md 新增 Section 13.5 | 第 7 列（結構變更）| ⚠️ skill/init-claude.md：建議新增 `section-13-5` anchor 給未來 upgrade migration 用（+5 行 metadata，非阻擋）|
| 閉環核心理念.md 對映表 | 第 1 列 | 無向上連動 |
| 版本號變更（採納實施後） | 第 11 列 | ✓ 3 處（CLAUDE_TEMPLATE 末尾、dev-closed-loop/README.md、根 README.md）|

**對外契約檢查**：7 smoke 不涉及 Section 編號斷言 → **不影響**

### 12.8 四條紅線檢查

| 紅線 | 通過？ | 說明 |
|------|-------|------|
| 1. 不採 single-LLM 自評機制 | ✅ | 反向劃線是 hard rule，不是評分 |
| 2. 不引入 baseline 膨脹 | ⚠️ 邊緣 | +20 行 / 緩衝 13；捆綁候選 A 後緩衝 5 → 觸發 #006 預防做法 |
| 3. 不削弱質疑熔斷 | ✅ | R-1 反向強化質疑熔斷 |
| 4. meta（自身走閉環） | ⏳ 待採納實施 | 採納後實作走精簡閉環六步（2 檔修改 < 50 行 = 中型偏小範圍）|

### 12.9 採納狀態

✅ **A 級採納待實施**（2026-05-19 用戶決策：選 1 採納 + 4 配套）

**實施時機**：與候選 A 捆綁，或拆開實施依 Phase F 整合決定。**捆綁建議**：兩個候選都觸及 CLAUDE_TEMPLATE.md，捆綁一次閉環省 1 次 wc -l 驗證 + 1 次依賴表 walk。但要承擔規模 5 行緩衝的風險。

---

## 13. Phase D — 候選 C：機械化驗證去重（❌ 拒絕）

> **狀態**：❌ 拒絕 · 評分 60/100 · 2026-05-19 用戶確認

### 13.1 七維度評分

| 維度 | 權重 | 分數 | 一句話依據 |
|------|------|------|----------|
| 真痛點對應度 | 25% | 6/10 | v6.2.0 wc -l 在 design-reviewer + code-reviewer 兩處重複（learning-log 證據）；但本 repo 規模小、實際 token 浪費未量化 — v2 §2.2「5K-15K 浪費」是 cross-project baseline 不是本 repo self-evidence |
| 不命中 v2 自身問題 | 15% | 7/10 | helper 是 deterministic 機械化；但 JSON output 共享機制與「sub-agent 獨立性原則」（避免 self-review 盲點）有設計張力 |
| 規模可控度 | 15% | 4/10 | 預估 ~150-200 行跨 9-10 個檔案，規模顯著超過候選 A（58 行 / 5 檔）與候選 E（25 行 / 2 檔） |
| 不削弱現有設計 | 15% | 7/10 | sub-agent 獨立性原則弱化風險（helper 是 deterministic 輸出可緩解但仍有張力）|
| 可實證度 | 10% | 9/10 | 指標清晰（跨閉環 token 消耗對比 + delegation-log grep 統計重複次數）|
| ROI | 10% | 4/10 | 本 repo 規模收益低（每閉環本來就快，5K-15K 節省不顯著）；實作成本高（150-200 行）|
| 時機適切 | 10% | 5/10 | helper 機制需要先跑 20+ 閉環累積實證才有 ROI；本 repo 還在 6 閉環階段 |

**加權計算**：

```
(6×0.25 + 7×0.15 + 4×0.15 + 7×0.15 + 9×0.10 + 4×0.10 + 5×0.10) × 10
= (1.5 + 1.05 + 0.6 + 1.05 + 0.9 + 0.4 + 0.5) × 10
= 60 / 100
```

**級別判定**：60 < 65 → **拒絕**

### 13.2 初判修正記錄（評分系統第 2 次否決）

Phase A 框架（§6 候選總覽表）初判為「✅ A 級」。完整跑完評分後實際為 **拒絕（60）**。

**評分系統第 2 次否決初判**：

| Phase | 候選 | Phase A 初判 | 實際評分 | 偏差幅度 |
|-------|------|------------|---------|---------|
| Phase B | A 升格降級 | A 級 | B 級 78.5 | -1.5 跨門檻 |
| Phase D | C 機械化驗證 | A 級 | **拒絕 60** | -20 跨 2 門檻 |
| Phase C | E 8 Anti-patterns | A 級 | A 級 81 | 確認 |

候選 C 偏差最大（從 A 級直接掉到拒絕）。系統嚴格度得到第 2 次實證 — **初判不可信，必跑完整 7 維評分**。

### 13.3 拒絕理由

1. **規模超出單一候選合理範圍**（4/10）：9-10 檔修改 / 150-200 行新增，比候選 A 大 3 倍、比候選 E 大 8 倍
2. **本 repo 規模 ROI 不足**（4/10）：5K-15K token 節省是 cross-project baseline，本 repo baseline 6 閉環 + 每個閉環本來就快，收益不顯著
3. **時機未到**（5/10）：helper 機制需 20+ 閉環累積實證才有 ROI，本 repo 還在 6 閉環階段
4. **設計張力**（不削弱 7/10）：sub-agent 獨立性原則 vs 共享 helper output 有少量但無法完全消除的張力

### 13.4 觸發的紅線

| 紅線 | 觸發狀態 |
|------|---------|
| 1. 不採 single-LLM 自評 | ✅ 不觸發 |
| 2. 不引入 baseline 膨脹 | ⚠️ 觸線（9-10 檔大規模修改） |
| 3. 不削弱質疑熔斷 | ⚠️ 觸線（sub-agent 獨立性原則弱化）|
| 4. meta（自身走閉環） | — N/A（拒絕無實施）|

### 13.5 縮小版 C-mini 評估記錄

評分過程中提出「只做 wc -l 行數預算 helper」縮小版替代方案：
- 範圍：~40 行跨 3 檔
- 預估評分：~75.5/100 → B 級（潛在採納）

**用戶決策**：不採縮小版，整體拒絕。

理由（用戶選項 1）：
- 縮小版的「行數預算 helper」其實已被 **#006 升格條目預防做法 (b)** 涵蓋（「design-reviewer 步驟 4 行數預算審查強制 wc -l」）
- 縮小版的 marginal 價值是「把人類執行的紀律 tool 化」— 有限
- 留候選 B 等 Phase E 評完，整體採納清單更清晰

### 13.6 後續處置

- ✅ 候選 C 從 §7 採用候選清單移除
- ✅ 候選 C 加入 §9 拒絕清單
- ✅ §6 候選總覽表狀態更新為「❌ 拒絕」
- ⏸️ Phase E 候選 B（L1/L2/L3 決策分層）待用戶確認後啟動

---

## 13.5. Phase G — CLAUDE_TEMPLATE.md 行數優化（插隊 dependency unblock · 採納待實施）

> **狀態**：採納待實施 · 2026-05-19 用戶決策（選 1）
> **性質**：**非 v2 候選評估** — 內部結構維護工作，為解套候選 A+E+B 捆綁觸頂而插隊
> **目標**：CLAUDE_TEMPLATE.md 547 → **~472 行**（節省 75 / 緩衝 v6.3.0 上限 580 拉到 108）
> **計劃版本**：v6.3.0 → **v6.4.0**（minor 升級 · metadata 結構性變動）

### 13.5.1 為何插隊（非 7 維評分對象）

7 維評分系統的適用範圍是「**評估 v2 外部素材**」。Phase G 性質不同：
- 非 v2 候選 — 是**內部結構維護**（CLAUDE_TEMPLATE 行數 / metadata 位置 / cross-reference 整理）
- 觸發點：用戶 explicit 痛點「CLAUDE_TEMPLATE.md 太長」（2026-05-19 對話）

不跑 7 維評分，改用「價值 vs 風險」評估：

| 維度 | 評估 |
|------|------|
| 解套效果 | 高 — 候選 A+E+B 捆綁 +53 行從撞 600 變成壓 525（緩衝 75 行）|
| 結構性投資 | 高 — 為 v6.x 後續升級留出空間 |
| 規模 | 中 — 7 檔修改 / CLAUDE_TEMPLATE -75 / 其他檔 +90 / 全 repo 淨 +15 |
| 風險 | 中 — init-claude.md upgrade flow 結構性變動（雙寫策略緩解）|
| 用戶痛點對應 | 高 — explicit 標明「太長」優先級高於候選 B 評分 66 |

### 13.5.2 4 項優化方案

| 編號 | 優化項 | 改動位置 | 行數變動 |
|------|-------|---------|---------|
| **A1** | 抽出 HTML 註解 metadata 到獨立檔 | line 493-547 → 新檔 `dev-closed-loop/upgrade-notes.md` | -50 |
| **B1** | 「工作規範」移至 `.claudedocs/standards/Git工作流.md` | line 462-472 → 保留 1 行 cross-reference | -9 |
| **B2** | 「Trade-off 顯式宣告」壓成單表格 | line 3-23 散文 21 行 → 表格 12 行 | -9 |
| **B3** | 「跨 Session 持久化 + 跨時間語義記憶」併段 | line 448-459 12 行 → 5 行 | -7 |

**CLAUDE_TEMPLATE.md 淨變動**：-75 行（547 → 472）

### 13.5.3 修改方案（7 處）

| # | 檔案 | 改動 | 行數 |
|---|------|------|------|
| 1 | `CLAUDE_TEMPLATE.md` | 4 項優化（A1+B1+B2+B3）| -75 |
| 2 | `dev-closed-loop/upgrade-notes.md`（新檔）| 接收 metadata（v5→v6 / v6.2 / dogfooding-1 / v6.4.0）+ 頭部說明 | +60 |
| 3 | `dev-closed-loop/skill/init-claude.md` | Step 5.2 從 `upgrade-notes.md` 讀 migration-notes | +3 |
| 4 | `.claudedocs/standards/Git工作流.md` | 接收工作規範詳細條目 | +10 |
| 5 | `dev-closed-loop/README.md` + 根 `README.md` | v6.4.0 版本歷史條目 | +10 |
| 6 | `setup.sh` | 驗證清單加 `upgrade-notes.md` 存在性 | +2 |
| 7 | `tests/test-cross-file-consistency.sh` | 新檔結構驗證 + 確認 CLAUDE_TEMPLATE 內無遺留 metadata | +5 |

**全 repo 淨變動**：+15 行（CLAUDE_TEMPLATE -75 / 其他 +90）

### 13.5.4 CLAUDE.md 依賴表 walk

| 改動 | 觸發列 | 連動 |
|------|-------|------|
| CLAUDE_TEMPLATE.md 結構變更 | 第 1, 3, 7, 11 列 | ✓ skill/init-claude.md Step 5；✓ 三處版本歷史 |
| 新建 upgrade-notes.md | 第 9 列（檔案增刪）| ✓ setup.sh 驗證清單；✓ dev-closed-loop/README.md 目錄結構 |
| 工作規範移至 Git工作流.md | 第 1 列 | ✓ Git工作流.md 接收 + CLAUDE_TEMPLATE 留 cross-reference |
| 對外契約 | 第 12 列 | ✓ test-cross-file-consistency.sh：grep 'closed-loop v' 仍命中 |

**對外契約檢查**：
- `grep 'closed-loop v'` → 仍命中（保留版本標記）✅
- `init-claude status` → 仍 work（依賴版本標記非 metadata 位置）✅
- `init-claude upgrade` → 改讀 upgrade-notes.md，**Phase 4 須模擬驗證**⚠️

### 13.5.5 4 條紅線檢查

| 紅線 | 通過？ | 說明 |
|------|-------|------|
| 1. 不採 single-LLM 自評 | ✅ | 純結構整理 |
| 2. 不引入 baseline 膨脹 | ✅✅✅ | **反向操作 — 減少 75 行 baseline**（最強通過）|
| 3. 不削弱質疑熔斷 | ✅ | Section 12/12.5/13 規則內容不動 |
| 4. meta（自身走閉環） | ⏳ 採納後 | 走**大型完整 5-Phase 閉環**（dogfooding-1 §5.5 + 候選 E R-5 精神）|

### 13.5.6 實施計劃：大型完整 5-Phase 閉環

任務分級：7 檔 ≥ 3 → 大型；CLAUDE_TEMPLATE 是核心、其他衍生 → 單模組。走「大型任務 — 單模組」流程。

| Phase | 動作 |
|-------|------|
| Phase 1 | architect 設計 BC-1~BC-7 + EH-1~EH-3 + IF-1~IF-2 + 分層 + 行數預期表 |
| Phase 1b | design-reviewer 評風險（特別 init-claude.md upgrade flow 破裂 + Trade-off 壓縮失 onboarding 友善）|
| Phase 2 | **雙寫策略**：複製 metadata 到新檔不刪原 → 改 init-claude.md → 本地驗證 → atomic 刪 CLAUDE_TEMPLATE 內 metadata |
| Phase 3 | code-reviewer cross-file 一致性 + 安全審查跳過（純結構無新攻擊面）|
| Phase 4 | 7 smoke + bash setup.sh 重部署本地驗 + 模擬 init-claude upgrade 模式 |
| Phase 5 | verifier 雙向追溯 + 升格檢查 |

預估 ~110K token total。

### 13.5.7 風險評估 + 緩解策略

| 風險 | 等級 | 緩解 |
|------|------|------|
| init-claude.md upgrade flow 破裂 | 🔴 主要 | 雙寫策略（13.5.6 Phase 2）+ Phase 4 模擬驗證 + atomic 切換失敗可 rollback |
| Trade-off 表格化失 onboarding 友善 | 🟡 中等 | 保留「核心訊息 prose」（偏向 / 不適用情境），只壓重複的代價收益清單 |
| 工作規範外移 cross-reference 漏失 | 🟢 低 | Phase 3 grep 確認 CLAUDE_TEMPLATE 末尾有 cross-reference 行 |
| CLAUDE_TEMPLATE 壓過頭 | 🟢 低 | Phase 4 wc -l 驗 472 ± 5，超出由 verifier Phase 5 標 V-x |

### 13.5.8 對候選 A+E+B 捆綁的解套效果

| 情境 | CLAUDE_TEMPLATE 終態 | 緩衝（vs 600 上限）|
|------|--------------------|------------------|
| 當前（v6.3.0）| 547 | 53 |
| 採納 A+E+B 不優化 | 600 | **0**（撞上限）|
| **Phase G 完成（v6.4.0）** | 472 | 128 |
| **Phase G + 採納 A+E+B** | 525 | **75** |
| 未來再 +20 行 minor 升級 | 545 | 55 |

**結構性解套**：Phase G 完成後，後續候選實作 + v6.x 升級皆有充裕緩衝。

### 13.5.9 為何不更激進（設計透明度）

考慮過更激進方案，但拒絕：

| 拒絕方案 | 理由 |
|---------|------|
| 把 Section 6-13 各細節全抽到 `.claudedocs/process/` | 破壞「主檔即 LLM 執行依據」原則 — Claude 不該每次都要查多個檔才執行紀律 |
| 完全重寫 CLAUDE_TEMPLATE 結構 | 高風險 — accumulated 紀律會散失 / 升級 migration 機制全壞 |
| 把 Section 12 / 12.5 / 13 認知驗證層全抽 | 認知驗證是核心 fallback（紅線 3），抽走會弱化 |

**保守 4 項（A1+B1+B2+B3）是「最大 ROI / 最小風險」交點**：
- 抽 metadata：對 LLM 執行 0 影響
- 抽工作規範：本來就有 `.claudedocs/standards/` 的散落對應
- 壓 Trade-off：是 onboarding 段非執行段
- 併持久化：是 cross-reference 段非執行依據

### 13.5.10 採納狀態

✅ **採納待實施**（2026-05-19 用戶決策：選 1 — 接受 Phase G 插隊優化 A1+B1+B2+B3）

**實施順序**：
1. Phase G 完成（CLAUDE_TEMPLATE 474 行 · 修正自 472）
2. 回 Phase E 評候選 B（補強計劃流程繼續）
3. Phase F 整合（補強計劃收尾）
4. 採納清單實施閉環（候選 A + E + 可能 B）

**實施前 cross-source review**（元紀律第 5 條）— Phase G 觸及核心主檔，建議用戶 cross-check 或另一 LLM session 盲評。

### 13.5.11 自審補強（devil's advocate review · 2026-05-19）

用戶選 2「先做 cross-source review 再實施」後，做兩件事：
1. **獨立 review pack**：產出 `dev-closed-loop/design/13-phase-g-review-pack.md`（~250 行 self-contained），給外部 reviewer（不同 LLM / reset session / 人類）用
2. **同 LLM 同 session 自審**：用 devil's advocate 角度挑 §13.5 設計，找出 4 個 finding

#### 4 個 finding 與修正

| Finding | 詳述 | 修正 |
|---------|------|------|
| **F1** B1 範圍錯估 | line 462-472「工作規範」段含 4 條目，其中「問題追蹤」是 Section 6c 兩層教訓架構對映 — 屬執行紀律不該外移 | B1 從抽 4 條目改為抽 3 條目（Git / 品質 / 文檔），行數變動 **-9 → -7** |
| **F2** anchor match 兼容性 | B2 壓 Trade-off 時必須保留「## 語言設定」heading（CLAUDE_TEMPLATE.md anchors 列表 `trade-off-section` 用此 match 字串）| §13.5.7 風險表新增「anchor match 字串相容性」緩解 |
| **F3** B2 不該全壓表格 | Trade-off「不適用情境」prose 部分是給人類 onboarding 用，全壓表格失去場景判斷易讀性 | B2 改為「代價收益壓表格 + 不適用情境保留 prose」（節省幅度不變）|
| **F4** Phase 4 測試缺跨多版本 | §13.5.6 Phase 4 動作只想到 v6.x → v6.4.0 internal migration，**未考慮 v5.x 用戶直接跳 v6.4.0** | §13.5.6 Phase 4 補測試動作「+ 模擬 v5.x → v6.4.0 跨多版本升級」|

#### 行數估計修正

| 項目 | 原估 | 修正後 |
|------|------|-------|
| A1 抽 metadata | -50 | -50（不變）|
| B1 抽工作規範 | -9 | **-7** |
| B2 壓 Trade-off | -9 | -9（不變，「不適用」prose 保留節省幅度不變）|
| B3 併持久化 | -7 | -7（不變）|
| **CLAUDE_TEMPLATE.md 淨變動** | **-75（547 → 472）** | **-73（547 → 474）** |
| 採納 A+E+B 後 | 525 | **527** |
| 緩衝（vs 600）| 75 | **73** |

#### 自審局限明示

同 LLM 同 session 自審本質仍 single-source（命中 #007 預防做法警告）：
- ✅ 能找：obvious 設計遺漏（如 F1「問題追蹤」段不該外移）
- ❌ 不能找：「未知未知」的 fundamental blindspot

**cross-source review 仍是必要**，自審只是 pre-filter。獨立 review pack 已產出，等待 reviewer 回饋後才進入 Phase G 實施。

#### Phase G 啟動條件（修正後）

- ✅ 用戶 explicit 同意採納（已完成 2026-05-19）
- ✅ 自審 devil's advocate review 完成（已完成 2026-05-19）
- ✅ 獨立 review pack 產出（已完成 2026-05-19）
- ✅ **cross-source review 完成**（Codex adversarial-review · 2026-05-19 · verdict: needs-attention · 詳見 §13.5.12）
- ⛔ **Phase G v1 設計需重設**（Codex 抓到 2 high + 2 medium finding）→ 啟動條件變更為 Phase G v2 設計完成後再評
- ⏳ Phase G v2 設計（已在 §13.5.12 列出方向）→ 用戶確認後啟動 Phase 1 architect

### 13.5.12 Cross-Source Review 結果（Codex Adversarial Review · 2026-05-19）

**Review 來源**：Codex CLI `adversarial-review`（不同 LLM 視角，工具：codex-companion.mjs · thread 019e3ef3-5f68-79d1-a8ff-260758b79258）
**Verdict**：**needs-attention** — 不建議出貨，建議重大修正
**Codex 摘要**：「Phase G 目前會破壞既有升級相容性，並把原本每 session 必讀的安全/品質/持久化紀律移到不保證載入的文件；A1/B1/B3 需要重設邊界與測試」

#### Codex 4 個 finding 與我自審對照

| # | 嚴重度 | Codex finding 主題 | 我自審是否發現 |
|---|-------|------------------|--------------|
| **F1** | 🔴 high | A1 抽 metadata 破壞**已安裝 v6.3 Skill** 升級相容性（用戶選「當前對話繼續升級」會讀不到 migration-notes）| ❌ **完全沒發現** |
| **F2** | 🔴 high | B1 把「外部輸入必驗證 / 敏感資料不寫死 / 測試覆蓋」**安全/品質硬規則**移出 always-read 主檔 | ⚠️ 部分發現（我只見「問題追蹤」一條，Codex 見「品質 + 安全 + 文檔放哪」全部）|
| **F3** | 🟡 medium | upgrade-notes 缺**版本選擇 schema** — 現有 awk parser 是 silent bug（實測同時輸出 v5→v6 + v6.2 區塊）| ⚠️ 部分發現（我提到要測，Codex 指出現在就壞著）|
| **F4** | 🟡 medium | B3 未鎖住持久化 **3 個不變式**（`.claude-loop/artifacts/` / `P1-design-spec.md` / direct-read no-summary）| ❌ **完全沒發現** |

#### 揭露的 3 個結構性盲點

**盲點 1：跨版本 Skill 相容性（F1）**

我設計時假設「新 cache 配新 Skill」一起更新。但 `init-claude.md` Step 5.4 有「繼續在當前對話中升級」選項 — 這條路徑會用**舊 Skill 跑新 cache**。舊 Skill 期待從 `CLAUDE_TEMPLATE.md` awk migration-notes，新 cache 卻把 metadata 移走 → migration 失效。

**盲點 2：安全規則的「載入保證」維度（F2）**

我把「載入保證」誤判為「cross-reference 完整性」。`CLAUDE_TEMPLATE.md` 是 **always-read**，`.claudedocs/standards/` **不是**。把「外部輸入必驗證 / 敏感資料不寫死」移到 standards 等於**降級安全防線**到「希望模型有讀」— 這不是規模整理，是 silent risk 注入。

**盲點 3：現存 awk parser silent bug（F3）**

我以為 awk parser 是 work 的。Codex 實測**現在就壞著** — 同時輸出 v5→v6 + v6.2 區塊。A1 不解決會把問題放大（v6.4 加進去後 v5.x、v6.1、v6.3 升級都可能拿到不屬於自己的 notes）。

#### Phase G v2 重設方案

| 原 v1 設計 | v2 修正 | 行數變動 |
|-----------|---------|---------|
| **A1** 抽 metadata（-50）| **A1' 改「雙寫 + 版本化 schema parser + backward-compat stub」**：先建 `from-version` / `to-version` / `applies-to` schema 修現存 silent bug；保留過渡 stub 在 `CLAUDE_TEMPLATE.md`（給舊 Skill 用）；同時加回歸測試（舊 v6.3 Skill 升新 v6.4 cache）| -30~-40（保留 stub）|
| **B1** 抽工作規範（-7）| **B1' 砍掉**或極度縮小：只移「Git commit message 格式」純風格條目；**品質 + 安全 + 文檔放哪 + 問題追蹤都保留主檔** | -2~-3（或 0）|
| **B2** 壓 Trade-off（-9）| **保留 v1 設計**：純 onboarding 段壓表格無 risk | -9 |
| **B3** 併持久化（-7）| **B3' 砍掉**：A1' 已夠省行數；強制保留 3 個不變式（`.claude-loop/artifacts/` 必建 / `P1-design-spec.md` 必寫 / Sub-Agent 直接讀檔不經主 agent 轉述）| 0 |
| Phase 3 安全審查跳過 | **不跳**：對 instruction 降級 / migration parser / 舊 Skill 相容性做安全/回滾審查 | — |

#### 修正後行數估計

| 情境 | CLAUDE_TEMPLATE.md | 緩衝（vs 600） |
|------|------------------|----------------|
| 當前（v6.3.0） | 547 | 53 |
| Phase G v2 完成（保守估）| 547 - 39 = **508** | 92 |
| Phase G v2 + 採納候選 A+E | 508 + 28 = 536 | 64 |
| Phase G v2 + 採納候選 A+E+B | 508 + 53 = 561 | **39** |

**評估**：v2 設計緩衝 39 行雖比 v1 設計（緩衝 75）低，但**零 high-risk finding** + 修了 awk silent bug，淨價值更高。

#### 紅線檢查更新（v2）

| 紅線 | v1 結果 | v2 結果 |
|------|--------|---------|
| 1. 不採 single-LLM 自評 | ✅ | ✅ |
| 2. 不引入 baseline 膨脹 | ✅✅✅ | ✅✅（仍是 -39 反向操作） |
| 3. 不削弱質疑熔斷 | ✅ | ✅ |
| **3'. 不削弱安全/品質防線** | ❌（v1 未識別此維度）| ✅（v2 強制安全條目保留主檔）|
| **3''. 不破壞既有升級相容性** | ❌（v1 未識別此維度）| ✅（v2 雙寫 + stub 策略）|
| 4. meta（自身走閉環） | ⏳ | ⏳ + **Phase 3 強制做安全/回滾審查** |

#### 元層面收穫

這份 Codex review 是 **#007「Single-Perspective Self-Review Blind Spot」升格後第一次實戰驗證**：

- 同 LLM 同 session 自審：4 個 finding · 全部偏 surface-level
- 不同 LLM cross-source review：4 個 finding · 含 **2 high 結構性盲點**
- **單視角漏看率 = 50%**（2/4 high finding 未被自審捕獲）

這是 #007 預防做法的決定性證據 — 對「方法論修改的設計」類產出，cross-source review 是 **hard requirement 不是 optional**。已記入 `.claude-loop/learning-log.md` 作為 #007 升格後實證。

#### v2 啟動 checkpoint

- ✅ Phase G v1 v2 修正方向已列（§13.5.12）
- ✅ **v2 設計再做一輪 cross-source review**（Codex adversarial-review 第 2 次 · 2026-05-19）— 詳見 §13.5.13
- ⛔ **v2 設計仍 needs-attention**（v1 F1 沒真解決 + 2 個新盲點）→ 不進 Phase G v3，改採選項 D 處置（§13.5.14）

### 13.5.13 v2 Cross-Source Review 結果（Codex 第 2 次 adversarial-review · 2026-05-19）

**Verdict**：**needs-attention** — 「No-ship: v2 still does not make the migration path safe. The legacy compatibility fix is incomplete, and the new parser/fallback design can silently skip required upgrade data.」

#### 3 個 finding

| # | 嚴重度 | 主題 |
|---|-------|------|
| **F1'** | 🔴 high | Legacy stub 只留 anchors 太激進 — 舊 v6.3 Skill Step 5.2/5.3 期待 `breaking-changes` / `required-actions` / `recommended-actions` 欄位，沒這些會 silent empty summary。**v1 F1 沒真解決** |
| **F2'** | 🔴 high | v6.x cumulative migrations 觸發不到 — `init-claude.md` Step 5 hard-coded `v5.x → v6.0.0`，**v6.0.0+ deployment 跳過 migration flow 走 normal overwrite**。A1' 設計的新 parser 路徑根本不會啟動 |
| **F3'** | 🟡 medium | Parse-failure fallback **文檔自我矛盾**：§2.1.2「解析失敗或檔案不存在 → fallback stub」vs §4.4「只在檔案不存在時 fallback，解析失敗應報錯」 |

#### 我自審 §4「我已想到的風險」vs Codex 3 finding 對照

| 我列的 §4 風險 | 對應 Codex finding | 命中度 |
|--------------|------------------|------|
| §4.1 雙寫 drift | — | ❌ 沒命中（Codex 看 stub 內容完整性，不是 drift）|
| §4.2 stub sunset 時機 | — | ❌ 沒命中 |
| §4.3 版本化 schema 累積邏輯 | F2' (high) | ⚠️ **方向接近但深度不足**（我看「拓樸排序」表面，Codex 看「trigger 條件根本沒被觸發」根因）|
| §4.4 stub fallback 優先級 | F3' (medium) | ⚠️ **方向命中但自相矛盾**（同份文件 §2.1.2 vs §4.4 寫法相反，沒回讀）|

**F1' 完全沒命中** — 我沒去 grep `init-claude.md` 實際 awk 抓什麼欄位。

#### 3 個 v2 盲點類型

1. **「v1 finding 表面修正不徹底」**（F1'）：以為「stub 保留 anchors」就修了 v1 F1，沒讀舊 Skill 程式碼
2. **「沒讀核心程式碼路徑」**（F2'）：設計新 parser 但沒查 `init-claude.md` Step 5.1 trigger（line 199 hard-coded `v5.x`）
3. **「文檔自我矛盾沒回讀」**（F3'）：同份 review pack 兩處規則寫法相反

#### 元層面：#007 升格後第 2 次實戰驗證

| 維度 | v1 review | v2 review | 累積 |
|------|----------|----------|------|
| 自審 finding | 4 個（surface）| 4 個（含「我已想到的風險」§4）| — |
| Codex finding | 4 個（2 high + 2 medium）| 3 個（2 high + 1 medium）| — |
| **自審漏看率** | 50% | **67%** | **平均 58%** |
| Verdict | needs-attention | **needs-attention**（Codex 明示「Do not enter Phase G implementation」）| 連續 2 次拒絕 |

**強烈訊號**：當問題深度超出單次設計能掌握的範圍時，正確做法是**降級 scope 不是堅持做完**。

### 13.5.14 處置決策：選項 D — 取消 Phase G + 拒絕候選 B（最保守）

**決策時間**：2026-05-19（用戶選 D）

#### 決策邏輯

1. **連續 2 次 cross-source review needs-attention** = 設計範疇 mismatch 的強訊號
2. **v3 設計成本不對等**：要動 `init-claude.md` Step 5.1 trigger（核心 upgrade flow）+ 新 schema parser + legacy stub 完整保留 — 已變成獨立工程改造 PR 規模，**不該夾帶在「行數優化」內**
3. **拆解選項 C 也仍引入 awk parser 改造**，工作量不對等於 -9 行收益
4. **縮小採納範圍直接解根本痛點**：拒絕候選 B 後 547+28=575（緩衝 5 vs 580 預算 / 25 vs 600 上限），完全跳過 Phase G 風險

#### 最終採納清單

| 候選 | 級別 | 評分 | 最終狀態 |
|------|------|------|---------|
| **A** 升格降級 | B 級 | 78.5 | ✅ 採納待實施 |
| **E** 8 條 Anti-patterns | A 級 | 81 | ✅ 採納待實施 |
| ~~**B** L1/L2/L3 決策分層~~ | B 級邊緣 | 66 | ❌ **拒絕**（v2 review 後決策 · 風險與行數空間不對等）|
| ~~**Phase G** 行數優化~~ | — | — | ❌ **取消**（v1+v2 兩輪 review needs-attention · 工程改造規模超出原 scope）|

#### CLAUDE_TEMPLATE.md 行數規劃

| 情境 | 行數 | 緩衝 vs 580 預算 | 緩衝 vs 600 上限 |
|------|-----|-----------------|----------------|
| 當前 v6.3.0 | 547 | 33 | 53 |
| **採納 A+E（最終）**| **575** | **5** | **25** |

**緩衝 5 行警示**：命中 #006「行數預算估算樂觀」升格條目觸發信號。實作閉環時必跑 wc -l 主動驗證（#006 預防做法 b）。

#### 後續獨立任務（與本補強計劃解耦）

| 任務 | 觸發來源 | 優先級 | 範圍 |
|------|---------|------|------|
| awk parser silent bug 修復 | v1 F3 + v2 F3' | 中 | 純 bug fix · 純 `init-claude.md` Step 5.2 awk 條件加 version filter |
| v6.x cumulative migration trigger | v2 F2' | 中 | `init-claude.md` Step 5.1 trigger 改 `deployed < cache + has migration path` |
| CLAUDE_TEMPLATE.md 行數壓力（後續長期）| 用戶 explicit 痛點 | 低 | 留待 v7.0.0 大重設時統一處理（不再 piecemeal）|

這 3 個獨立任務**不夾帶在候選 A+E 實作閉環**，各自獨立評估走自己的閉環。

#### 選項 D 紅線檢查

| 紅線 | 通過？ | 說明 |
|------|-------|------|
| 1. 不採 single-LLM 自評 | ✅ | 純拒絕決策，無評分機制 |
| 2. 不引入 baseline 膨脹 | ⚠️ 邊緣 | 採納 A+E 後 575（緩衝 5）— 命中 #006 觸發信號但仍在預算內 |
| 3. 不削弱質疑熔斷 | ✅ | 完全跳過任何認知驗證層修改 |
| 4. meta（自身走閉環） | ⏳ 採納後 | 候選 A + E 捆綁走精簡閉環六步（中型範圍）|

---

## 14. Phase E — 候選 B：L1/L2/L3 決策分層（❌ 拒絕 · 選項 D 後）

> **狀態**：❌ 拒絕 · 評分 66/100（B 級邊緣，壓門檻 +1）· 2026-05-19 用戶決策（選項 D）

### 14.1 七維度評分

| 維度 | 權重 | 分數 | 一句話依據 |
|------|------|------|----------|
| 真痛點對應度 | 25% | 5/10 | 本 repo「該不該打斷用戶」判定散落各 Section（1b/8/12/12.5/Phase 1b/3/5），但 v6.x 系列 AQ 平均 0-4 次/閉環，沒明顯「過度問」實證 |
| 不命中 v2 自身問題 | 15% | 9/10 | 配套砍掉 §3.5 自治決策（7 維評分 / explainability / override），純取 L1/L2/L3 分類定義無認知性風險 |
| 規模可控度 | 15% | 8/10 | 單檔 +20-25 行 + 既有 Section 散修 5-10 行 |
| 不削弱現有設計 | 15% | 8/10 | 純強化既有規則的索引層；小風險：未來誤把「L1 白名單」當「閉門清單」 |
| 可實證度 | 10% | 6/10 | 指標可定但 absence-based 量測難 |
| ROI | 10% | 4/10 | 短期低 + 本 repo 不採自治化價值打折 |
| 時機適切 | 10% | 6/10 | 純 L1 白名單時機 always 適合，但本 repo 階段價值有限 |

**加權計算**：

```
(5×0.25 + 9×0.15 + 8×0.15 + 8×0.15 + 6×0.10 + 4×0.10 + 6×0.10) × 10
= (1.25 + 1.35 + 1.2 + 1.2 + 0.6 + 0.4 + 0.6) × 10
= 66 / 100
```

**級別判定**：66 ∈ [65, 79] → **B 級**（壓門檻線 +1，**邊緣 B 級**）

### 14.2 為何最終拒絕

評分過 65 門檻原本可採納，但 Phase G v2 review 後揭露捆綁實作會撞 600 行上限風險：

| 情境 | CLAUDE_TEMPLATE.md | 緩衝 |
|------|------------------|------|
| 採納 A+E（最終）| 575 | 5（已 ⚠️ 命中 #006 紅旗）|
| 採納 A+E+B | 600 | **0**（撞 hard 上限）|

**選項 D 處置邏輯**：
- 候選 B 真痛點對應 5/10 + ROI 4/10 → 採納價值有限
- 採納會直接撞 600 行 hard 上限
- 拒絕 marginal cost 低（不影響任何既有 fallback）

**用戶決策**：選項 D — 拒絕候選 B（v2 review 後）

### 14.3 評分系統 4 個候選分佈實證

候選 B 評分 66，與 A（78.5）/ C（60）/ E（81）合計**漂亮跨 4 個級別門檻**：

| 候選 | 評分 | 級別 | 距門檻 |
|------|------|------|------|
| C | 60 | 拒絕 | -5 |
| **B** | **66** | **B 邊緣** | **+1（壓 65 門檻線）**|
| A | 78.5 | B | -1.5（差 A 級門檻 80）|
| E | 81 | A | +1（過 A 門檻）|

**評分系統區分力第 3 次實證**：4 個候選**沒有任何兩個落在同一分區**，系統能精確跨門檻分類。

---

## 15. Phase F — 整合（補強計劃流程收尾）

> **狀態**：✅ 完成（2026-05-19 用戶選 1 進入 Phase F · 補強計劃流程全部結束）
> **採納清單**：候選 A（升格降級機制 · B 級 78.5）+ 候選 E（8 條 Anti-patterns · A 級 81）共 2 候選

### 15.1 最終採納清單盤點

| 候選 | 級別 | 評分 | 配套 |
|------|------|------|------|
| **A** 升格降級機制 | B 級 | 78.5 | 4 條（dormant 啟用 / 範圍限縮種子條目 / 不刪除移到條件式 section / 機械化檢查 by verifier）|
| **E** 8 條 Anti-patterns | A 級 | 81 | 4 條（重寫去自治化前綴 / 8→5 條精選 / Section 13.5 位置 / 連動閉環核心理念.md）|

**拒絕清單**（共 7 個）：B / C / F / H / I / J + Phase G — 詳見 §9
**延後清單**（共 2 個）：G（17 Archetypes）/ D（spec anchor）— 詳見 §8

### 15.2 連動檔案總表

| # | 檔案 | 候選 A 增量 | 候選 E 增量 | 合計 | 性質 |
|---|------|-----------|-----------|------|------|
| 1 | `CLAUDE_TEMPLATE.md` | +8（P5 +3 / 精簡步驟 4.5 +5）| +20（Section 13.5 五條反向劃線）| **+28** | 核心執行依據 |
| 2 | `.claudedocs/records/問題追蹤.md` | +30（降級機制 + 條件式紀律 sections）| 0 | +30 | 紀律檔 |
| 3 | `.claudedocs/agents/verifier.md` | +15（step 9c 降級候選檢查）| 0 | +15 | agent prompt |
| 4 | `.claudedocs/agents/architect.md` | +5（step 6c-1「⏸️ 條件式」標記識別）| 0 | +5 | agent prompt |
| 5 | `.claudedocs/concepts/閉環核心理念.md` | +2（升格段補對稱「降級」概念）| +5（紀律保底層 + 對映表）| +7 | 概念檔 |

**全 repo 淨變動**：**+85 行**跨 5 檔
**CLAUDE_TEMPLATE.md 終態**：547 + 28 = **575**（緩衝 5 vs 580 預算 ⚠️ / 25 vs 600 上限）

### 15.3 CLAUDE.md 依賴表 walk（合併兩候選）

| 改動 | 觸發列 | 連動檔案 |
|------|-------|---------|
| CLAUDE_TEMPLATE.md Phase 5 + 精簡步驟 4.5（A）| 第 1 列 | ✓ 五階段閉環流程.md |
| CLAUDE_TEMPLATE.md Section 13.5 新增（E）| 第 1 列 + 第 7 列 | ⚠️ skill/init-claude.md：建議新增 `section-13-5` anchor 給未來 upgrade 用 |
| 問題追蹤.md 結構變更（A）| 第 1 列 + concepts 對映 | ✓ 閉環核心理念.md「升格段補對稱降級」（已含在合計 +2 行）|
| verifier.md / architect.md prompt 變更（A）| 第 8 列 | ✓ CLAUDE_TEMPLATE.md 對應 Phase 描述（已含在合計 +8）|
| 版本號 v6.3.0 → v6.4.0 | 第 11 列 | ✓ 3 處（CLAUDE_TEMPLATE 末尾、dev-closed-loop/README.md、根 README.md）|

**對外契約檢查**：7 smoke 不涉及 verifier step / Section 編號斷言 → **不影響**

### 15.4 實施順序判定

**任務分級**：5 檔 ≥ 3 觸發大型門檻；單模組（皆屬方法論紀律層）
**判定**：**大型任務 — 單模組** 完整 5-Phase 閉環（保守判定 · 觸及核心執行依據）

**捆綁 A+E vs 拆分**：採**捆綁實施**。理由：
- 兩候選都觸及 CLAUDE_TEMPLATE.md，捆綁省 1 次依賴表 walk + 1 次 wc -l 驗證
- 575 行預算 atomic verification（單獨 547+8 或 547+20 看不到真實終態）
- 候選 E R-3「升格機制 / 降級機制 / 兩層教訓架構不可 bypass」與候選 A 降級機制直接相關，捆綁保證 R-3 對映正確

**6 個 Phase 任務 + blockedBy 鏈**：`[P1-設計] → [P1b-設計審查] → [P2-實作] → [P3-檢核] → [P4-測試] → [P5-自證]`

### 15.5 Phase 1 設計範圍預覽

#### BC-x 預設

候選 A 部分：
- **BC-A1**：問題追蹤.md 新增「降級機制」section
- **BC-A2**：問題追蹤.md 新增「條件式紀律」section（檔案末尾）
- **BC-A3**：verifier.md 新增 step 9c「降級候選檢查」
- **BC-A4**：CLAUDE_TEMPLATE.md Phase 5 升格段對稱補「降級檢查」
- **BC-A5**：CLAUDE_TEMPLATE.md 精簡步驟 4.5 升格段對稱補（主 agent 自做）
- **BC-A6**：architect.md step 6c-1 加「⏸️ 條件式」標記識別

候選 E 部分：
- **BC-E1~5**：CLAUDE_TEMPLATE.md 新增 Section 13.5「反向劃線」R-1~R-5（5 條 hard rule）
- **BC-E6**：閉環核心理念.md 新增「紀律保底層」概念段 + 對映表

#### EH-x 預設

- **EH-1**：降級條件 n 值（A 級 10 / 完全 archive 20）可調整 → 硬編在問題追蹤.md「降級機制」section 內
- **EH-2**：升格條目降級後復發 → 立即升回 active（verifier 偵測 + AskUserQuestion）
- **EH-3**：種子條目 #001-#005 learning-log 無對應 → **不適用降級規則**（範圍限縮配套）

#### IF-x 預設

- **IF-1**：問題追蹤.md「降級機制」section ↔ verifier.md step 9c 介面契約（n 值定義 + 觸發條件）
- **IF-2**：CLAUDE_TEMPLATE.md Section 13.5 R-3 ↔ 問題追蹤.md 升格/降級機制 cross-reference 契約

#### 分層 + 驗證層級

純功能層（無 UI）· 全部 `[testable]`

#### 行數預算

CLAUDE_TEMPLATE.md +28（緩衝 5 vs 580 預算 ⚠️ 命中 #006 紅旗）/ 其他檔合計 +57 / 全 repo 淨 +85

**#006 預防做法強制執行**：
- (a) 結構化區塊（Section 13.5 五條 / 問題追蹤.md 降級 section）單獨估 ≥ 15-20 行
- (b) design-reviewer 步驟 4 強制 wc -l 主檔當前行數 + 預估增量
- (c) 緩衝 5 < 5 行硬規則 → ⚠️ 預期被 design-reviewer 標 arch-risk，記錄不阻擋

### 15.6 驗證指標基線（K-11 健康指標連動）

| 指標 | baseline | v6.4.0 目標 | 健康判定 |
|------|---------|-----------|---------|
| DR-x high / 閉環 | 0~1 | ≤ 1 | 🟢 |
| R-x high / 閉環 | 0 | 0 | 🟢 |
| 升格觸發 / 月 | 0 | 0（啟用降級機制非升格）| 🟢 |
| CLAUDE_TEMPLATE.md 行數 | 547 | **575 ± 2** | ⚠️ 緩衝 5 |
| 7 smoke 結果 | 7/7 PASS | 7/7 PASS | 🟢 |

額外指標（候選 A 啟用後追蹤）：升格條目降級率 / Phase 1 6c-1 token 成本 / 復發率

### 15.7 紅線最終檢查（A+E 捆綁）

| 紅線 | 結果 | 說明 |
|------|------|------|
| 1. 不採 single-LLM 自評 | ✅ | 兩候選皆 deterministic 規則 |
| 2. 不引入 baseline 膨脹 | ⚠️ 邊緣 | 緩衝 5 命中 #006 觸發信號 |
| 3. 不削弱質疑熔斷 | ✅ | R-1 反向強化質疑熔斷 |
| 4. meta（自身走閉環）| ⏳ | 大型完整 5-Phase 閉環 |

### 15.8 後續獨立任務記錄（與本補強計劃解耦）

3 個由 Codex review 衍生的獨立任務，**不夾帶在候選 A+E 實作閉環**：

| 任務 | 來源 | 觸發條件 |
|------|------|---------|
| **T1**：awk parser silent bug 修復 | v1 F3 + v2 F3' | 立即可做 · `init-claude.md` Step 5.2 awk 加 version filter · ~30 行 |
| **T2**：v6.x cumulative migration trigger | v2 F2' | T1 完成後 · Step 5.1 改 `deployed < cache + has migration path` · ~50 行 |
| **T3**：CLAUDE_TEMPLATE.md 行數重設 | 用戶 explicit 痛點 | 留待 v7.0.0 大重設統一處理 |

**獨立任務原則**：各自獨立評估 + 各自跑閉環 + 建議寫進 `design/14-T1.md` / `design/15-T2.md` / `design/16-T3.md`

### 15.9 補強計劃流程完成宣告

✅ **本補強計劃（Phase A 框架 → Phase F 整合）流程完成**（2026-05-19）

**累計產出**：

| Phase | 產出 | 規模 |
|-------|------|------|
| A | 框架（10 候選 + 7 維評分 + 4 紅線）| ~150 行 |
| B | 候選 A 評分 → B 級 78.5 採納 | ~120 行 |
| C | 候選 E 評分 → A 級 81 採納 | ~140 行 |
| D | 候選 C 評分 → 拒絕 60 | ~100 行 |
| G | Phase G 設計（v1 + 自審 + v1 review + v2 重設 + v2 review + 選項 D 取消）| ~350 行 |
| E | 候選 B 評分 → 66 邊緣 + 選項 D 拒絕 | ~80 行 |
| F | 整合（本段）| ~150 行 |

**全檔行數**：~1090 行（補強計劃.md）+ 233 行（v1 review pack）+ 361 行（v2 review pack）+ ~50 行（learning-log 兩條實證 entry）= **~1734 行設計記錄**

**評分系統 3 次否決初判**：候選 A（A→B）/ 候選 C（A→拒絕）/ Phase G（無 finding → 2 輪 review 拒絕 + 取消）— 系統嚴格度充分實證

**#007 第 1+2 次實證**：累積漏看率 50%+67%（平均 58%）— cross-source review 是必要性的決定性證據

### 15.10 下一步：採納清單實施階段

補強計劃結束 = 採納清單 A+E 進入**實施階段**（與本設計檔解耦）。

實施建議：
1. **另開新 session** 啟動候選 A+E 捆綁實作大型完整 5-Phase 閉環（避免本 session 累積過多 context）
2. **必要前置**：實施前 cross-source review 元紀律最終驗證 — 但這次規模小（5 檔 / 85 行），可由用戶人工 cross-check 替代另跑 Codex

---

## 16. 元紀律（補強計劃自身的閘門）

1. **每個 A 級候選必過 7 維評分**：不可只憑直覺採納，必須跑完整評分並列「為何此分」依據
2. **每個候選須附 CLAUDE.md 依賴表 walk**：對每個改動位置查 CLAUDE.md 第 1-12 列連動義務（修改前必做）
3. **採納後實作走閉環**：A 級走精簡閉環六步；多個 A 級捆綁成大型則走完整 5-Phase
4. **就地修訂**：本檔修訂不分檔，新章節追加；舊章節有修正用 `~~舊~~` + `> ⚠️ [HH:MM update] 新` 格式
5. **cross-source 校準**：本檔由單 LLM 起草（紅線 1 自指），實施前需 cross-source review（用戶 cross-check / 另一 LLM session / 同 LLM 不同 session 盲評三選一）後才正式進方法論
6. **K-11 健康指標連動**：採納後的修改實施過程跟蹤 DR-x high / R-x high / 升格觸發三指標，若任一指標朝紅區飄 → 暫停採納，回到本檔修訂

---

## 17. 後續行動 checkpoint

**本份（Phase A）完成後等用戶確認下列事項**：

1. 7 維評分系統的權重分配是否合理（25/15/15/15/10/10/10 = 100）
2. 4 條紅線是否完整（要不要加 / 刪 / 改）
3. 10 候選的初判狀態是否同意（特別是 B 級候選 B 的「僅取分類定義」邊界）
4. 切解任務 Phase B-F 的順序是否合理（建議按 ROI 序：A 升格降級 → E 8 Anti-patterns（規模最小）→ C 機械化驗證 → B L1/L2/L3）

**確認後啟動 Phase B**（候選 A 升格降級機制詳細評分）。

---

**版本歷史**：

| 版本 | 日期 | 變動 |
|------|------|------|
| Phase A | 2026-05-19 | 框架建立（10 候選總覽 + 7 維評分 + 4 條紅線 + 切解任務索引）|
| Phase B | 2026-05-19 | 候選 A（升格降級機制）詳細評分 → B 級 78.5/100 + 4 配套條件，採納待實施。初判 A 級被完整評分推翻（規模 7 / ROI 6 / 時機 6 拖累）|
| Phase C | 2026-05-19 | 候選 E（8 條 Anti-patterns）詳細評分 → A 級 81/100 + 4 配套條件（重寫去自治化 / 8→5 條精選 / Section 13.5 / 連動概念檔）。**評分系統區分力驗證**：候選 A 78.5 (B) vs 候選 E 81 (A) 跨門檻 |
| Phase D | 2026-05-19 | 候選 C（機械化驗證去重）詳細評分 → **拒絕 60/100**（規模 4 / ROI 4 / 時機 5）。**評分系統第 2 次否決初判**：Phase A 初判 A 級 → 實際拒絕，跨 2 級門檻。縮小版 C-mini 評估後用戶決定整體拒絕（marginal 價值已被 #006 預防做法涵蓋）|
| Phase G | 2026-05-19 | **插隊優化專案** — 用戶 explicit 痛點「CLAUDE_TEMPLATE.md 太長」觸發專業核檢。設計完成 4 項優化（A1 抽 metadata / B1 抽工作規範 / B2 壓 Trade-off / B3 併持久化），CLAUDE_TEMPLATE 547 → 472（-75 行），結構性解套候選 A+E+B 捆綁觸頂風險。採納待實施 · v6.3.0 → v6.4.0 minor 升級 |
| Phase G self-review | 2026-05-19 | 用戶選 2「先做 cross-source review 再實施」。產出兩件：(1) 獨立 review pack 檔 `design/13-phase-g-review-pack.md` 給外部 reviewer 用；(2) devil's advocate 自審找 4 個 finding（B1 範圍縮小 / anchor 兼容性 / B2 部分壓 prose 保留 / Phase 4 補測 v5→v6.4.0 跨多版本）。行數估計修正：CLAUDE_TEMPLATE 547 → **474**（-73 行）|
| Phase G cross-source | 2026-05-19 | Codex `adversarial-review` 完成 · verdict **needs-attention**。抓到 2 high（跨版本 Skill 相容性 / 安全規則載入保證）+ 2 medium（awk silent bug / 持久化不變式）。Phase G v1 設計**重設為 v2**：B1 砍 / B3 砍 / A1 改「雙寫 + 版本化 schema + stub」/ B2 保留 / Phase 3 不跳安全審查。修正後行數 547 → ~508（緩衝 92）。**單視角漏看率 = 50%** — #007 升格後第一次實戰驗證，已記入 `.claude-loop/learning-log.md` |
| Phase G v2 cross-source | 2026-05-19 | Codex 第 2 次 `adversarial-review` 完成 · verdict **仍 needs-attention**。抓到 3 個 finding（F1' v1 F1 沒真解決 / F2' v6.x cumulative trigger 沒啟動 / F3' 文檔自我矛盾）· Codex 明示「Do not enter Phase G implementation」· **連續 2 次 needs-attention** |
| Phase E + 選項 D | 2026-05-19 | Phase E 評候選 B → **66/100 B 級邊緣**。v2 review 後綜合判定 → 用戶採選項 D 處置：**取消 Phase G** + **拒絕候選 B**（風險/行數空間不對等）+ 只採納候選 A+E（547+28=**575**，緩衝 5 vs 580 預算）。awk silent bug + Step 5.1 trigger 改造留作後續獨立任務（與本補強計劃解耦）。**#007 第 2 次實證**漏看率 67%，平均 58%。Phase E/G 流程完成，下一步進 Phase F 整合 |
| Phase F | 2026-05-19 | 整合完成（§14 + §15）。最終採納清單 = 候選 A + E。連動 5 檔 / 全 repo 淨 +85 行 / CLAUDE_TEMPLATE 547→575（緩衝 5 ⚠️ 命中 #006）。判定大型完整 5-Phase 閉環 + 捆綁實施。BC-A1~A6 / BC-E1~E6 / EH-1~3 / IF-1~2 預設給未來 architect。**補強計劃流程全部結束** — 進入採納清單實施階段（與本設計檔解耦，建議另開 session）|
