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

## 2026-04-26 - [次生副作用] [design-reviewer]

**Phase**: Phase 1b 第 2 輪
**failure_type**: process_failure
**問題**：DR-3 修正後行數預算 549/550 = **1 行緩衝過薄**（DR-1v2）
**原因**：修正 DR-3 時將預算改 550，但瘦身 ≥ 20 行的數學是 `444+125-20=549`，緩衝只有 1 行 → 1 行誤差就觸發 R-x medium。**這是 DR 修正的次生副作用**，第 1 輪審查抓不到（因為當時還沒寫修正後的數字）
**怎麼修的**：DR-1v2 標 medium → P1 v3 瘦身要求 ≥ 20 → ≥ 25 行，新預算 `444+125-25=544`，緩衝拉到 6 行
**下次注意**：**DR 修正可能引入次生問題（修正傳遞性）**，必須跑 P1b 第 2 輪重審才能抓到；預算緩衝至少 ≥ 5 行；改一個數字時要重新算整套公式

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
