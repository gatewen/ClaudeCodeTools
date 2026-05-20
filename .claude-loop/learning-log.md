# Learning Log

> v6.0.0 升級閉環的事件記錄（per-session 短期工作記憶）
> Branch: feature/v6.0.0-karpathy

---

## 2026-04-26 - [DR 修正] [design-reviewer]

**Phase**: Phase 1b 第 1 輪
**failure_type**: judgment_failure
**問題**：IF-1 metadata 中 `trade-off-section` anchor 用了 `# {{PROJECT_NAME}}` placeholder
**原因**：architect 在 P1 v1 設計 IF-1 時未考慮 placeholder 在部署時已被替換為實際專案名（例 `# my-app`），導致 `init-claude upgrade` 的智能合併（策略 B）grep 永遠 miss → Q3 用戶決策的 migration 機制破功
**怎麼修的**：DR-1 標 high 觸發回退 → P1 v2 改用 `## 語言設定`（既有穩定 heading，無 placeholder）+ anchors 升級為 list of objects 含 `position: before|after` 屬性
**下次注意**：設計 metadata 涉及 grep / sed 字串時，必須確認該字串在部署後（placeholder 替換後）仍成立——**部署生命週期視角檢查**

## 2026-04-26 - [DR 修正] [design-reviewer]

**Phase**: Phase 1b 第 1 輪
**failure_type**: judgment_failure
**問題**：行數預算 575 緩衝過薄（v5.23.1 444 行 + 預估 ~150 = 594，距斷點 600 僅剩 6 行）
**原因**：P1 v1 預算估算太樂觀；v5.15 才從 606 行瘦身到 361 行，v6.x 系列若無預算控制可能再上看 700+ 行抵消 v5.15 工作
**怎麼修的**：DR-3 標 arch-risk → P1 v2 預算 575 → 550，EH-5 上限 600 → 575，加 P2 強制瘦身 ≥ 20 行（後因 DR-1v2 改 ≥ 25 行；實際 P2 壓 33 行）
**下次注意**：行數膨脹要主動瘦身既有 Section（執行成本轉嫁，非新增工作量）；**預算緩衝至少 ≥ 5 行**避免 1 行誤差觸發 R-x

→ 已升格 問題追蹤#006 [2026-04-26]（v6.2.0 升格判定）

## 2026-04-26 - [次生副作用] [design-reviewer]

**Phase**: Phase 1b 第 2 輪
**failure_type**: process_failure
**問題**：DR-3 修正後行數預算 549/550 = **1 行緩衝過薄**（DR-1v2）
**原因**：修正 DR-3 時將預算改 550，但瘦身 ≥ 20 行的數學是 `444+125-20=549`，緩衝只有 1 行 → 1 行誤差就觸發 R-x medium。**這是 DR 修正的次生副作用**，第 1 輪審查抓不到（因為當時還沒寫修正後的數字）
**怎麼修的**：DR-1v2 標 medium → P1 v3 瘦身要求 ≥ 20 → ≥ 25 行，新預算 `444+125-25=544`，緩衝拉到 6 行
**下次注意**：**DR 修正可能引入次生問題（修正傳遞性）**，必須跑 P1b 第 2 輪重審才能抓到；預算緩衝至少 ≥ 5 行；改一個數字時要重新算整套公式

→ 已升格 問題追蹤#006 [2026-04-26]（行數預算面向 · v6.2.0 升格判定，「DR 修正傳遞性」面向仍為觀察項）

## 2026-04-26 - [by-design 接受] [P3 一致性審查]

**Phase**: Phase 3
**failure_type**: judgment_failure（次生）
**問題**：BC-4 migration-notes 區塊 30 行 > P1 v3 規格 25 行（多 5 行）
**原因**：DR-1 將 anchors 升級為 list of objects 後，3 個 anchor 各占 3 行（name/match/position = 9 行 anchors block），但 P1 v3 沒同步調整 BC-4 的行數預算
**怎麼修的**：P3 R-x 標 low + by-design（理由：所有功能性驗收全過 / 510/550 預算仍充足 / anchors block 9 行不可壓縮）→ P5 verifier 確認 by-design 標記合理
**下次注意**：DR 修正會傳遞影響其他 BC-x 的子預算——**修正一處時要 walk 整個 BC list 看是否需同步調整**

---

## 升格候選（≥ 3 次）

**0 立即升格**——以上 4 條皆未達門檻。但有 **2 個累積觀察項**（v6.1.0 P1 啟動前重評）：

1. **「DR 修正傳遞性」模式**：本次 v6.0.0 出現 DR-3 → DR-1v2 / DR-1 → BC-4 by-design 兩次傳遞性。若 v6.1.0/v6.2.0 又出現第 3 次 → 可升格為「長期警惕模式」（觸發情境：DR-x 修正改變既有預算或介面格式時必須 walk 全部相關項目）
2. **「行數預算膨脹週期」模式**：v5.15.0 瘦身 → v6.0.0 又膨脹 → v6.1+ 可能再膨脹。若 v6.x 系列累積 3 次預算超出 → 可升格為「長期警惕模式」（觸發情境：major version 升級必須含 ≥ 1 個瘦身條目作為配額）

---

## 2026-04-26 - v6.1.0 milestone closure（無失敗事件）

**Phase**: 整個 v6.1.0 精簡閉環（六步）
**failure_type**: 無（無事件記錄——本次無斷點觸發 / 無 DR-x high / 無熔斷）
**結果**：
- P1 v1（初稿）→ P1b 第 1 輪 6 條 DR 全採用 → P1 v2 → 進步驟 2
- P2 6 條 K-x 實作完成（grep 6/6 命中，CLAUDE_TEMPLATE 510→520 +10 行 ≤ 525 樂觀預算）
- P3 **0 high / 0 arch-risk / 0 medium / 0 low / 0 by-design**（淨——優於 v6.0.0 P3 的 1 low/by-design）
- P4 4/4 部署驗證通過
- 步驟 4.5 迷你追溯 6/6 ✅，閘門全 ✅，可 commit

**觀察項狀態更新**：
- 「DR 修正傳遞性」（v6.0.0 觀察項 1）：v6.1.0 P1b 6 條 DR 採用後**無進一步傳遞副作用**（v6.0.0 DR-3→DR-1v2 模式未重現）→ **觀察項仍存在但 v6.1.0 沒新證據**，繼續累積等到第 3 次再升格判定
- 「行數預算膨脹週期」（v6.0.0 觀察項 2）：v6.1.0 +10 行（v6.0.0 是 +66 行；連續兩次都在合理 minor / major 規模內）→ **膨脹趨勢假設未驗證**，**觀察項可暫停**，重評時機改為下個 major 升級

**下次注意**：精簡閉環六步在小規模 minor 升級下表現極佳（cost 低品質高，比完整 5-Phase 省 ~70% sub-agent 委派 token）；major 升級才需要完整閉環的高 ceremony

---

最後修訂：2026-04-26（v6.0.0 + v6.1.0 升級閉環，4 條事件 + 1 milestone closure，2 觀察項中 1 暫停）

---

## 2026-04-26 - [R-x 修正] [code-reviewer]（方法論一致性審查替代）

**Phase**: 步驟 3（v6.2.0 精簡閉環）
**failure_type**: judgment_failure
**問題**：CLAUDE_TEMPLATE.md 行數超出預算 — 實際 563 行 > P1 v2 預算上限 545 行，超 18 行。
**原因**：P1 v2 估算「+25 行（K-14 第 5 條 5.1-5.4 展開 + migration-notes 條目）」嚴重低估。實際 K-14 第 5 條展開 22 行 + migration-notes-v6.2 區塊 21 行 = +43 行。設計時把 migration-notes-v6.2 看作「條目」幾行就夠，沒算結構化區塊（含 head / extensions / recommended-actions）的真實展開行數。**對應 v6.0.0 教訓 #2「行數膨脹要主動瘦身」未守住**——預算估算過樂觀，緩衝 5 行被吃完還倒貼 18 行。
**怎麼修的**：步驟 2 回退修正 — (a) migration-notes-v6.2 從 21 行 → 6 行 inline patches 風格（省 15 行）；(b) K-14 第 5 條 5.1 由 4 條 bullet → 1 行 prose（省 3 行）；(c) 5.3 對稱性由 4 行表 → 1 行 prose（省 3 行）；(d) 5.4 由 3 條 bullet 合併末尾 prose 段為 inline（省 2 行）；總省 ~23 行 → CLAUDE_TEMPLATE 預期 ≤ 540 行，緩衝 ≥ 5 行。
**下次注意**：**結構化 metadata 區塊（migration-notes / anchors / config）的展開行數是「整段算」不是「一條一行」**。預算估算公式：每個 metadata 區塊單獨估 ≥ 15-20 行（head + body + 3-5 個 sub-section）。design-reviewer 步驟 4 行數預算審查時必須主動 wc -l 主檔當前行數 + 預估增量，不能信任設計者寫的「+N 行」自評。

→ 已升格 問題追蹤#006 [2026-04-26]（v6.2.0 升格判定，第三筆觸發點）

---

## 2026-04-26 - v6.2.0 milestone closure（精簡閉環六步通過）

**Phase**: 整個 v6.2.0 精簡閉環
**failure_type**: 無 milestone-level（步驟 3 R-1 high 已記錄為單獨事件）
**結果**：
- brainstorming → 用戶 4 個決策（K-14 落點 / K-11 套餐 / K-11 門檻 / 順序）
- design/09 + 用戶核可
- P1 v1 → P1b 1 high (DR-1 concepts 緩衝 0) + 1 arch-risk (DR-2 KPI 量測) + 5 medium + 3 low → P1 v2 全採 DR-1/3/4/5/7（DR-6 方案 A）
- P2 實作（K-14/K-10/K-11 + BC-4 跨檔 8 檔）
- P3 步驟 3 R-1 high（CLAUDE_TEMPLATE 563 > 545 預算超 18 行）→ 回步驟 2 壓 23 行（migration-notes-v6.2 21→4 / K-14 第 5 條 22→18）→ 差分審查通過
- P4 部署驗證：placeholder 8/8 + anchors 3/3 + setup.sh 12/12 全 ✅
- 步驟 4.5 迷你追溯 13/13 BC ✅，BC-K11-1 ⚠️ by-design（62 < 80 估算下限但內容完整）

**統計**：DR-x 1h / 1arch-risk / 5m / 3low | R-x 1h | 步驟 3 回退 ×1 | 預防清單命中 1（行數預算膨脹週期觀察項 — 但失敗，緩衝估算過樂觀）

**v6.0.0 觀察項狀態更新**（這次觸發重評）：
- 「DR 修正傳遞性」（觀察項 1）：v6.2.0 P1b → P1 v2 採 6 條 DR 修正後**無新次生副作用**（差分審查通過無新 R-x）→ 觀察項仍有效但 v6.2.0 沒新證據
- 「行數預算膨脹週期」（觀察項 2）：v6.1.0 標暫停，**但 v6.2.0 R-1 重新激活**——預算估算過樂觀導致 CLAUDE_TEMPLATE 超 18 行 → 累積第 3 次「行數預算估算偏低」根因（v6.0.0 教訓 #2 + v6.0.0 教訓 #3 + v6.2.0 R-1）→ **達升格門檻 ≥ 3 次，待用戶確認**

**下次注意**：精簡閉環六步在 minor 升級下 1 次步驟 3 回退是合理範圍（v6.1.0 0 回退是 outlier）；P1b reviewer 主動 wc -l 而非信任設計者預算估算可避免 R-1 觸發。

---

## 2026-04-26 - v6.3.0 milestone closure（精簡閉環六步通過 · 一次通過無回退）

**Phase**: 整個 v6.3.0 精簡閉環
**failure_type**: 無（無事件記錄）
**結果**：
- brainstorming → 用戶 2 個決策（路徑 = 先 K-07 後 K-13 / K-07 主題 = 5 個 anti-pattern + 部署到目標）
- design/10 + 用戶核可（commit 5323e39）
- P1 v1 → P1b 0 high / 2 arch-risk / 2 medium / 1 low → P1 v2 採 DR-1/3/5 + DR-2/4 入 RISK-8/9（不觸發回退）
- P2 實作（5 個 examples 檔案 84/85/95/100/118 行 + setup.sh 12→17 + 4 處跨檔同步）
- P3 步驟 3 一致性審查全綠（BC-K07-1~6 全部命中 + CLAUDE_TEMPLATE 540 行守住沿 #006 預防做法）
- P4 部署驗證：placeholder 8/8 + anchors 3/3 + setup.sh 17/17 全 ✅
- 步驟 4.5 迷你追溯 6/6 BC ✅，反向追溯所有改動皆對應 K-07

**統計**：DR-x 0h / 2 arch-risk / 2m / 1low | R-x 0 | 步驟 3 回退 0 | 預防清單命中 1（#006「行數預算估算樂觀」CLAUDE_TEMPLATE 增量=0 守住）

**沿用 #006 預防做法驗證**（v6.2.0 升格條目）：
- (a) 結構化區塊單獨估：5 個 examples 檔案分別估 80-120，未寫「總計 500」混淆 ✅
- (b) design-reviewer 步驟 4 主動 wc -l：P1b reviewer 確實主動 wc -l CLAUDE_TEMPLATE 確認 540 屬實 ✅
- (c) 緩衝 ≥ 5 行硬規則：CLAUDE_TEMPLATE 增量 0 → 緩衝保持 5 行 ✅

**v6.0.0 觀察項狀態更新**：
- 「DR 修正傳遞性」（觀察項 1）：v6.3.0 P1b 5 條 DR 採用後**無新次生副作用**（差分審查不需要，全採後直接進步驟 2）→ 連續 v6.1/v6.2/v6.3 三次無新證據，**觀察項可正式結束**
- 「行數預算膨脹週期」（觀察項 2 → 已升格 #006）：v6.3.0 沿用預防做法成功 → #006 第一次驗證有效 ✅

**下次注意**：精簡閉環在「純新增 + 部署清單變動」型 minor 升級下表現最好（v6.3.0 一次通過、0 R-x、cost 約是 v6.2.0 的 60%）；中等量 K-x（3 條）的 v6.2.0 較 1 條 K-x 的 v6.3.0 多 1 次步驟 3 回退，符合預期 cost-quality 比例。

**v6.x 系列盤點**：
- v6.0.0：5 條 K-x（核心結構與哲學）+ 4 條 DR/by-design 教訓
- v6.1.0：6 條 K-x（執行細節）+ 0 失敗
- v6.2.0：3 條 K-x（認知對稱性 + KPI）+ 1 R-1 high → 升格 #006
- v6.3.0：1 條 K-x（對照範例庫）+ 0 失敗（一次通過）
- 累積 14 條 K-x 全部完成 + #006 升格為長期警惕模式 + K-13 緩議

---

## 2026-04-26 - dogfooding-1 milestone closure（dogfooding 試煉 + 方法論補強閉環）

**Phase**: dogfooding 試煉 + dogfooding-1 補強閉環
**failure_type**: §5.6 探索成本失控（judgment_failure）+ §5.5 DOGFOODING.md Y/N 反轉（process_failure · spec 自身沒跑閉環）

**dogfooding 試煉結果**（D:\Code\DogFooding 跑）：
- T1 微小直通 ✅ — 但 §5.6 抓出探索成本失控盲點
- T2 精簡六步 ✅ — 0 high / 3 medium 用戶延後
- T3 大型 5-Phase ⏸️ deferred — 配額考量
- 質化 5 Y/N → 1 N (Q3) 健康閾值內

**主要發現**：
- **§5.6（最重要 · 元發現）**：CLAUDE_TEMPLATE Section 1 微小任務「直接執行」沒涵蓋探索類動作（找 typo / 找 dead code 等）token 成本失控盲點 → dogfooding-1 補 Section 1.5 探索成本上限
- §5.1 BC↔健康路徑階層漂移：design-reviewer 缺檢查項 → 補步驟 4.5
- §5.3 配額 ad hoc：主動降級無正規規範 → 補配額管理判定點
- §5.4 跨平台環境降級：tester 缺前置檢查 → 補 edge_cases 段
- §5.5 DOGFOODING.md Y/N 反轉：spec 自身沒跑閉環（process_failure · self-irony）→ Phase A 直通修

**dogfooding-1 補強動作**（本次 commit）：
- Phase A：DogFooding/DOGFOODING.md Y/N + 6 處路徑修正（直通，無 commit 因非 git）
- Phase B：精簡六步閉環（配額降級 sub-agent 全 inline）
  - CLAUDE_TEMPLATE.md Section 1.5（D-1）+ 主動降級判定點（D-2）+ migration-notes-dogfooding-1 + closed-loop 標記
  - design-reviewer.md 步驟 4.5（D-3）
  - tester.md 跨平台環境前置（D-4）
  - 方法論運作指標.md baseline + dogfooding T1/T2（V7K-2）
  - design/12-v7-kpi-calibration.md（V7K-1，含 §8 5 個缺口提醒）
  - 兩個 README 加 dogfooding-1 patch row

**統計**：DR-x 0h（P1b 自審無觸發）/ R-x 0h（P3 自審無觸發）/ 預算守住（CLAUDE_TEMPLATE 540→561 ≤ 580 緩衝 19）

**沿用 #006 預防做法驗證**：(a) 每檔單獨估行數 ✅ (b) reviewer wc -l 主動 ✅（雖 P1b 自審但仍 wc -l）(c) 緩衝 ≥ 5 ✅（兩 README + design-reviewer 緩衝 < 5 by-design 接受）

**升格候選**：
- §5.6 探索成本失控 = 首次觀察 → 不到升格門檻（≥ 3 次）但已在 CLAUDE_TEMPLATE Section 1.5 處理
- §5.5 DOGFOODING.md self-irony = 首次觀察 → 同上

**v7 啟動條件**（本次 design/12 explicit 列）：
1. ✅ K-11 baseline ≥ 5 個閉環（已達 6）
2. ❌ 時間跨度 ≥ 3 個月（當前 1 個月）
3. ❌ T3 大型 5-Phase 實戰樣本 ≥ 1
4. ❌ 跨 session / 跨模組 / 跨 repo 樣本各 ≥ 1
5. ❌ §8 5 個缺口中 ≥ 3 個已補上

**最早 v7 啟動時機**：2026-07-26（3 個月後）+ 中間補 1-2 次 dogfooding。

**下次注意**：
- 下次 dogfooding spec 自身須走精簡六步閉環（避免 §5.5 self-irony 重蹈）
- §5.6 探索成本上限規則需在實戰中驗證有效性（dogfooding-2 必跑）
- §8 5 個缺口至少補 3 個才能啟 v7

---

## 2026-05-04 - [single-source 評估盲點] [評分任務 · 非閉環]

**Phase**: 評分任務（認知性產出，套用 Section 12 事實主張閘門）
**failure_type**: judgment_failure
**問題**：cc_recommand（同一 LLM 自評本專案）給 ClaudeCodeTools 的評分 83.8/100，三個扣分敘述完整且自評項挑得合理。但 codex_recommand（不同視角）對同一 codebase 評估時補上 5 個 cc_recommand **完全沒提到的**具體 bug：無 LICENSE / `/tmp/claude-*` marker 跨專案污染 / 依賴敘述矛盾 / 文檔數量三套說法 / `.DS_Store`。
**原因**：single-LLM 自評的視角缺乏「外部紅隊」效應——cc_recommand 套用的 9 維評分框架是 LLM 自己選的，框架本身已經編碼了「對自己有利的盲區」。同時用同一 LLM 對同一專案評分時，它會把「未抓到的 bug」當成「不存在的 bug」，沒有獨立來源無法揭露。
**怎麼修的**：用戶提供 codex_recommand → 4 階段執行（衛生修補 b86d34a / hook isolation 461c1cc / SHA tracking fa390e4 + 階段 2-3 tests/）→ 分數推到 86.5 並建立 7 smoke 防回歸。
**下次注意**：對「方法論本身的評估」「自評」「review」類認知性產出，single-LLM 視角不夠，最好搭配 ≥ 1 個獨立來源（不同 LLM、人類、或同一 LLM 不同 session 的盲評）。Section 12 事實主張閘門對「我的方法論評分是 X」這類斷言應視為 B 級證據（單來源），標註「待 cross-source 驗證」。

→ 已升格 問題追蹤#007 [2026-05-05]（用戶於今日 session 確認升格 · 第 1 筆證據）

---

## 2026-05-05 - [single-source 評估盲點] [接續執行計畫前的審查漏看]

**Phase**: 階段 3 開工前（接續 2026-05-04 規劃）
**failure_type**: judgment_failure
**問題**：階段 3 原計畫（2026-05-04 寫）含「拆分 CLAUDE_TEMPLATE Section 12/13 至子檔」，動機寫「降低 onboarding 成本」。今日接續執行時我**直接準備按計畫做**，沒有重新審查前提。直到收集事實基礎時才發現：(a) Claude 不需 onboarding（每次都全讀）、(b) 人類 maintainer 大概率不讀 CLAUDE_TEMPLATE、(c) 認知驗證層的設計意圖是「主檔顯著呈現以提高 trigger 率」，拆出反向違背。
**原因**：跨 session 接續執行時，預設信任「之前 session 寫的計畫」是高風險的 single-source 盲點——同一 LLM 在不同 session 寫的計畫對「下一個 session 的 LLM」來說仍是 single-source。沒有主動套用 architect Step 0a 對「計畫前提」做事實主張閘門驗證，等於跳過了對 prior planning 的審查。
**怎麼修的**：開工前主動 ultrathink → 列 5 個替代方案 → 走 Push back（Section 12.5 變體 1 方案爭議）→ 用戶選方案 E + C → 純壓縮 -19 行 + 平台/curl|bash 文檔，避免動核心架構。
**下次注意**：接續執行跨 session 計畫時，在開工前必須主動跑：(1) Step 0a 對「計畫的核心前提」做字面證據掃描——這個前提是基於什麼證據？(2) 主動引用 Section 12.5 第 5 條對待用戶事實前提的反向質疑機制——「用戶寫的計畫」也屬於需驗證的事實前提之一。
→ 已升格 問題追蹤#007 [2026-05-05]（用戶於今日 session 確認升格 · 第 2 筆證據）

---

## 2026-05-05 - [single-source 評估盲點] [intra-session 多 commit 後依賴表盲區]

**Phase**: 階段 2-3 + 階段 3 + 方案 C 七 commit 完成後
**failure_type**: judgment_failure（依賴表 walk 遺漏）
**問題**：今日連續做了 7 個 commit（階段 1 + 2-1 + 2-2 + 2-3 批 1/2/3 + 階段 3 + 方案 C + learning-log），完成後沒主動跑 CLAUDE.md 依賴表第 11 列「版本變更要同步 3 處」檢查。兩個 README 版本歷史 entry 仍停在 2026-04-26 v6.3.x dogfooding-1 patch，repo 對外訊號失準。用戶問「README 奇怪嗎」時，我列了 6 個 H 假設（H1-H6 結構/順序/disclaimer/CHANGELOG/Hook 位置/子段順序）**全部沒命中真因**——直到用戶明確指出「我們有更新版本的記錄嗎」才意識到漏更新。
**原因**：(1) 7 commit 跨多種類型（infrastructure / 文檔 / 壓縮 / 記錄）後，沒主動 walk 依賴表確認哪些列被觸發；(2) 對自己工作的 self-review 走「結構合理性」維度，沒走「依賴表機械式檢查」維度——前者主觀偏誤大，後者剛好是預防工具；(3) 用戶質疑後也沒先檢查依賴表，反而生成 6 個假設用「自己的視角」猜，再次落入 single-source 推論。
**怎麼修的**：用戶第二次提示「指版本記錄」後立刻定位到依賴表第 11 列；補 2 個 README 版本歷史 entry（v6.3.x infrastructure-patch）涵蓋今日 7 commit；commit 7df0e03。
**下次注意**：(1) 多 commit 工作完成時主動跑依賴表 walk——對每個改動位置查 CLAUDE.md 表所有列；(2) 用戶提示「奇怪」「不對」「漏了什麼」類質疑時，**先 walk 依賴表**再生成假設；(3) 同 session 內累積 commit 時設立檢查點：commit ≥ 3 後做一次 mid-session 依賴表 walk，避免最後一次性盲區。

→ 已升格 問題追蹤#007 [2026-05-05]（用戶於今日 session 確認升格 · 第 3 筆證據 · 達門檻觸發升格）

---

## 升格紀錄 — #007 single-source 評估盲點 (✅ 已升格 2026-05-05)

| # | 日期 | 事件 | 視角來源 |
|---|------|------|---------|
| 1 | 2026-05-04 | cc_recommand 漏看 5 bug，codex 補回 | 跨 LLM（cc → codex）|
| 2 | 2026-05-05 早段 | 接續執行 2026-05-04 計畫前未審查前提 | 跨 session（同一 LLM 不同時間）|
| 3 | 2026-05-05 晚段 | 7 commit 後沒跑依賴表 walk + 用戶質疑時 6 H 假設皆未命中真因 | intra-session（同一 LLM 同一 session）|

**升格動作完成**：
- ✅ `.claudedocs/records/問題追蹤.md` 加 #007 entry（5 段：模式 / 觸發情境 / 預防做法 / 檢測信號 / 歷史證據）
- ✅ 3 條 learning-log 事件各加註「→ 已升格 問題追蹤#007」
- ✅ architect Phase 1 從下次起必讀 #007 預防做法

**升格意義**：架構性盲點，跨「LLM / session / intra-session」三層皆已驗證。今後對「方法論評估 / 計畫前提 / 自評 / 多 commit 工作收尾」類產出，CLAUDE_TEMPLATE Phase 1 architect Step 0a 必須跑 cross-source 驗證 + 依賴表 walk 機械式檢查。

---

## #007 升格後實戰實證 — 2026-05-19 補強計劃 Phase G self-review

**Phase**: 補強計劃 §13.5 Phase G「CLAUDE_TEMPLATE.md 行數優化」設計 self-review
**failure_type**: judgment_failure（single-source 盲點實證）

**問題**：對 Phase G 設計做自審找到 4 個 finding（B1 範圍縮小 / anchor 兼容性 / B2 部分壓 prose 保留 / Phase 4 補測 v5→v6.4 跨多版本），但漏看 3 個結構性盲點：

| 盲點 | 嚴重度 | 內容 |
|------|-------|------|
| 跨版本 Skill 相容性 | 🔴 high | 已安裝 v6.3 Skill 用戶走「當前對話繼續升級」會讀不到 migration-notes |
| 安全/品質規則「載入保證」維度 | 🔴 high | B1 把「外部輸入必驗證 / 敏感資料不寫死」移出主檔等於降級安全防線到「希望模型有讀」|
| 現存 awk parser silent bug | 🟡 medium | 多 migration-notes 區塊共存時無版本過濾，當前已會同時輸出 v5→v6 + v6.2 |

**原因**：同 LLM 同 session 自審本質是 single-source — 設計者視角 = 審查者視角，看不到「設計者沒主動檢查的維度」。我看 cross-reference 完整性，Codex 看「主檔 = always-read 保證」這個更深層維度；我假設新 cache+新 Skill 配對更新，沒考慮舊 Skill 跑新 cache 路徑。

**怎麼修的**：用 Codex CLI 跑 `adversarial-review`（不同 LLM 視角 cross-source 驗證），verdict needs-attention · 抓到 2 high + 2 medium。Phase G 設計重設：B1 砍掉 / B3 砍掉 / A1 改「雙寫 + 版本化 schema parser + backward-compat stub」/ B2 保留 / Phase 3 強制做安全/回滾審查。詳見 `dev-closed-loop/design/13-autonomy-v2-reinforcement-plan.md` §13.5.12。

**下次注意**：
1. **cross-source review 是 hard requirement 不是 optional**：對「方法論修改的設計」「重大認知性產出」類產出，不能用「自審 N finding 已覆蓋」當理由跳過
2. **自審範圍局限**：同 LLM 同 session 自審只能找「已知未知」的明顯 gap，找不到「未知未知」的結構性盲點
3. **本次量化證據**：單視角漏看率 = 50%（4 個高/中等 finding 中，2 個 high 完全未被自審捕獲）
4. **適用同類規則**：架構設計（v6.x 主檔變動）/ 方法論評估（如 `/sc:analyze` 自評）/ KPI 校準 / 行數預算重設 / 認知驗證層修改 等皆應強制 cross-source review

**意義**：這是 #007 升格後**第一次實戰驗證**，量化證明 cross-source review 對結構性盲點的捕獲率（同 LLM 同 session 0/2，不同 LLM 2/2）。建議未來方法論修改類產出的 Phase 1b 設計快審加 cross-source 強制要求。

---

## #007 升格後實戰實證 #2 — 2026-05-19 Phase G v2 self-review

**Phase**: 補強計劃 Phase G **v2** 重設方案 self-review（第 2 輪）
**failure_type**: judgment_failure（#007 升格後第 2 次實證）

**問題**：對 Phase G v1 被 Codex review 否決後，做了 v2 重設方案。v2 review pack 內 §4 explicit 列「我已想到的風險」4 條（雙寫 drift / stub sunset / 版本化複雜度 / fallback 優先級）。Codex 第 2 次 adversarial-review 仍 verdict needs-attention，抓到 3 個 finding：

| Finding | 嚴重度 | v1 沒解決 / v2 新盲點 |
|---------|-------|--------------------|
| F1' Legacy stub 太簡（舊 Skill 還需 breaking-changes / required-actions / recommended-actions）| 🔴 high | **v1 F1 沒真解決** |
| F2' v6.x cumulative migrations 觸發不到（init-claude.md Step 5 hard-coded v5.x · line 199 跳過 v6.0.0+）| 🔴 high | v2 新發現的架構盲點 |
| F3' Parse-failure fallback 規則文檔自我矛盾（§2.1.2 vs §4.4 寫相反規則）| 🟡 medium | v2 新發現的文檔內部一致性盲點 |

**自審 §4「我已想到的風險」對 Codex 3 finding 的命中**：
- §4.3 vs F2'：方向接近但深度不足（我看「拓樸排序」表面，Codex 看「trigger 條件根本沒被觸發」根因）
- §4.4 vs F3'：方向命中但**自相矛盾**（同份文件兩處寫法相反，沒回讀）
- F1' 完全沒命中（沒去 grep init-claude.md 實際 awk 抓什麼欄位）

**原因**（3 種盲點類型）：
1. **「v1 finding 表面修正」陷阱**：以為「stub 保留 anchors」就修了 v1 F1，沒讀舊 Skill 實際讀取的欄位
2. **「沒讀核心程式碼路徑」**：設計新 parser 但沒查 Step 5.1 trigger 邏輯（init-claude.md line 199 寫死 v5.x）
3. **「文檔自我矛盾沒回讀」**：同份 review pack §2.1.2 vs §4.4 寫法相反，沒做自我一致性檢查

**怎麼修的**：用戶採選項 D — **取消 Phase G 整體** + **拒絕候選 B**（B 級邊緣 66） + 只採納候選 A+E。最終 CLAUDE_TEMPLATE 547+28=575（緩衝 5 vs 580 預算 / 25 vs 600 上限）。awk parser silent bug + Step 5.1 trigger 改造留作後續獨立任務，與本補強計劃解耦。詳見 `dev-closed-loop/design/13-autonomy-v2-reinforcement-plan.md` §13.5.13/14。

**下次注意**：
1. **自審漏看率從 50% → 67% 第 2 次連續被 cross-source 拉回**：強烈訊號「結構性盲點」會反覆出現，**不能用「再做一輪自審」當解方**
2. **「我已想到的風險」段是陷阱**：寫在文件裡的「風險表」反而讓人（包含設計者）認為「已 cover」，實際上 67% 漏看的還在
3. **連續 2 次 cross-source review needs-attention = 設計範疇 mismatch**：當問題深度超出單次設計能掌握的範圍時，正確做法是「**降級 scope / 拆解獨立子任務 / 完全放棄**」，**不是再做 v3 設計**
4. **適用同類規則**：當 cross-source review 連續 ≥ 2 次 needs-attention 時，設計者應主動降級 scope（不堅持做完），這應該寫進 CLAUDE_TEMPLATE.md 或候選 E 的 R-5 反向劃線範圍

**累積證據**：
- 同 LLM 同 session 自審：v1 50% 漏看率 / v2 67% 漏看率（平均 58%）
- 不同 LLM cross-source：v1 抓到 2 high + 2 medium / v2 抓到 2 high + 1 medium
- **連續 2 次 verdict needs-attention** — 第 2 次明示「Do not enter implementation」

→ #007 升格後**第 2 次**實戰驗證（累積：實證 #1 v1 review + 實證 #2 v2 review）

---

## 2026-05-20 - v6.4.0 milestone closure（候選 A+E 捆綁完整 5-Phase 閉環）

**Phase**: 整個 v6.4.0 完整 5-Phase 閉環
**failure_type**: 無 milestone-level（P1b 5 medium + P3 1 medium 皆 in-place 補修，無斷點觸發）

**結果**：
- handoff load 接續 → Phase 1 architect inline 產出 P1 設計規格（12 BC + 3 EH + 2 IF · 學習查詢 #006 + #007 雙命中）
- 架構師對 §15.5 預設兩處精煉修正：BC-A3 step 9c → step 9d（避免與既有「事實前提追溯」衝突）/ BC-A6 step 6c-1 → 主 agent 步驟 1.a 子項（命名歸位）
- P1b design-reviewer task agent → 0 high / 2 arch-risk（DR-1 緩衝邊界 / DR-2 YAGNI 邊緣）/ 5 medium / 3 low → 用戶 AskUserQuestion 決定 A 全量 + 4 medium 全補 + DR-5 復發機制改 m=5 ≥ 2 次
- P2 implementer inline 實作 5 檔變動：CLAUDE_TEMPLATE 547→574（緩衝 6）/ 問題追蹤 158→193 / verifier 382→396 / architect 307→308 / 閉環核心理念 228→247 / 全 repo 淨 +96（預期 +85 超 11 行，主因 migration-notes 區塊先 13 行後壓 6 行）
- 中間 #006 預防做法觸發點：CLAUDE_TEMPLATE 第一次寫到 581 破預算 1 行 → 應用 v6.2.0 R-1 經驗將 migration-notes 區塊 13 行 inline 壓到 6 行 → 574（緩衝 6 守住）
- P3 code-reviewer task agent → 0 high / 2 arch-risk（沿 P1b DR-1/2）/ 1 medium（R-3 BC-E6 K-16 關係澄清缺）/ 2 low → R-3 in-place 補修 2 行
- P4 tester：7/7 smoke PASS + grep 全 BC/EH/IF 命中
- P5 verifier task agent → BC/EH/IF 對映率 17/17 = 100% / 0 孤兒變動 / step 9b 0 升格 / step 9c 不適用 / step 9d 0 降級候選（首次運作 self-irony 印證 DR-2 YAGNI 預測）/ R-5 未觸發

**統計**：
- DR-x 0h / 2 arch-risk / 5m / 3low → 5 medium 全 in-place 採納
- R-x 0h / 2 arch-risk（沿 P1b）/ 1m → R-3 in-place 補修
- 斷點觸發 0 / 行數預算守住（574/580 緩衝 6）
- cross-source review = P1b sub-agent + 用戶人工 in-place 修正（符合 #007 預防做法 a + 規模 85 行可替代另跑 Codex 的設計判定）

**沿用 #006 預防做法驗證**（v6.2.0 升格條目第 3 次實證）：
- (a) 結構化區塊單獨估：migration-notes-v6.4 區塊估太樂觀（設計 0 行預估 → 實作展開 13 行 → 應用 v6.2.0 R-1 經驗壓回 6 行）—**部分失敗 → 部分補救**
- (b) reviewer 主動 wc -l：design-reviewer 主動 wc -l 標 DR-1 arch-risk ✅
- (c) 緩衝 ≥ 5 行硬規則：實作中 wc -l 觸發壓縮回 574 緩衝 6 守住 ✅

**沿用 #007 預防做法驗證**（v6.4.0 升格後第 3 次實戰實證）：
- (a) cross-source review hard requirement：P1b sub-agent 不同視角 + 用戶人工 in-place 修正 ✅
- (b) 依賴表 walk：設計規格 「連動檔案依賴表 walk」section 7 列觸發完整 ✅
- (c) 計畫前提字面證據掃描：架構師對 §15.5 預設兩處不一致主動精煉（step 9c 衝突 / step 6c-1 命名不存在）→ 證明 architect 起手主動審查預設前提的能力 ✅

**#006 累積實證紀錄**（從 v6.2.0 升格起）：
- 第 1 次：v6.3.0 對照範例庫（+5 examples · CLAUDE_TEMPLATE 增量 0 守住）
- 第 2 次：v6.3.x infrastructure-patch（純壓縮 566→547 緩衝充足）
- 第 3 次：v6.4.0 A+E 捆綁（574/580 緩衝 6 守住 · 過程中觸發 1 次壓縮重做）

**#007 累積實證紀錄**（從 v6.2.0 → 含 #007 升格後跑的所有閉環）：
- 第 1 次（升格實證 #1）：補強計劃 Phase G v1 self-review 漏看率 50%
- 第 2 次（升格實證 #2）：補強計劃 Phase G v2 self-review 漏看率 67%（觸發 R-5 → 取消 Phase G）
- 第 3 次（升格實證 #3）：v6.4.0 A+E 捆綁 cross-source review 成功應用（P1b sub-agent 抓 2 arch-risk + 5 medium，無連續 needs-attention，R-5 未觸發）

**v6.4.0 首次運作 Self-Irony 觀察**（meta layer · 升格降級機制本身）：
- 本閉環首次運作 step 9d 降級候選掃描，作用對象 = 0
- P1b DR-2「YAGNI 邊緣」預測準確 — 升格機制當前實際可降級對象 = 0（#001-#005 EH-3 過濾 / #006+#007 升格時間 < n=10 閉環）
- 自帶 self-irony：本閉環是「為了應對 #007 升格教訓」而採納候選 A+E 的，但 #007 本身就是「給尚未發生的問題提前準備機制」的反面教材（YAGNI）
- 用戶決策（接受全量）優先於 reviewer 警告 — 紀錄此 trade-off 待 ≥ 5 個非種子升格樣本累積後重評

**下次注意**：
1. **結構化 metadata 區塊（migration-notes / anchors）的展開行數預估**：#006 已升格但本次仍踩到 → 預估時 metadata block 必須單獨估 6-15 行 inline 風格 / 15-25 行展開式風格
2. **首次運作 self-irony 是 explicit 設計**：當新機制本身無作用對象時不應視為「失敗」— 是「待啟動」狀態。建議 v6.5.x+ 追蹤指標「step 9d 候選數」是否在 6 個月後 > 0
3. **R-5 計數窗口開始計時**：本次 P1b 為「第 1 輪 needs-attention（即使 0 high 仍有 5 medium）」嗎？嚴格定義是「verdict needs-attention」即 LLM 自評 needs-attention 字串。本次 verdict 是「不觸發回退」非 needs-attention，所以未進 R-5 計數

---

最後修訂：2026-05-20（v6.4.0 milestone closure · 候選 A+E 捆綁完整 5-Phase 閉環 · #006 + #007 第 3 次實證 · step 9d 首次運作 self-irony 0 作用對象）

之前修訂：2026-05-19（追加 #007 升格後第 2 次實戰實證 · Phase G v2 self-review · 漏看率 67% · 用戶選項 D 取消 Phase G）

之前修訂：2026-05-19（追加 #007 升格後第一次實戰實證 · 補強計劃 Phase G self-review · 單視角漏看率 50%）

更早修訂：2026-05-05（升格 #007 single-source 評估盲點 · 第 3 樣本記入 + 3 條事件加升格 marker + 升格紀錄段更新）
