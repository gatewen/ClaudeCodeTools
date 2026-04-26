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
