# Session Handoff

**最後更新**: 2026-06-01 08:51
**Session 焦點**: 方法論價值的 dogfood 實證 — A–F 六場 correctness 軸耗盡（robust null）→ 用戶推進「高功率 agent 實驗」Stage G（迭代變更攤銷測試）建置中

## 進行中工作

> 📌 **跨 session 提醒**：以下是 file state，不會自動恢復為 TaskList runtime state。新 session 開啟時由 `/dev:handoff load` 自動 TaskCreate 重建。本 session TaskList 全程為空（marathon 調查未開 task），故下次 load 依本區塊重建。

- [ ] **Stage G — 迭代變更攤銷測試（高功率全量，執行中途）**
  - **已完成**：① ~10145 行多模組 `bank` Go codebase 建好（`sandbox/closed-loop-validation/stage-g/before/`，15 test pkg 全綠、vet clean、CTR-A/CTR-B/INV-1~5 結構完整）② 盲產兩份持久 artifact（`session1/MAP.md` 266 行 / `session1/REGISTRY.md` 223 行，在寫變更/oracle 前產 = Codex 時序必修滿足）③ 草擬 6 個變更需求（`FROZEN-CHANGES.md`：G1 新型別 Interest / G2 批次提款查 available / G3 分級利率 / G4 對帳單逐日餘額 / G5 批次轉帳回滾 / G6 跨帳戶型別淨額月報）
  - **下一步（卡在這）**：把 codebase + 6 變更送 Codex 凍結，**且必須讓 Codex 裁一個我發現的公平性問題** → 見下方「未決」#1
  - **之後**：Codex 凍結通過 → 建 golden（6 變更正確實作，驗 oracle）+ held-out 累積 oracle + 架構 rubric → 跑 3 臂 × 6 變更 = 18 runs（arm0 裸寫-careful / arm1 +MAP / arm3 +REGISTRY 完整閉環）→ 每輪 oracle + token 會計 + 期末盲評 → RESULTS.md
  - **成本**：已花 ~1M（建置+artifact）；剩 18 runs 約 ~3–5M（大錢，用戶已授權全量）
  - **Codex 4 必修**（SPEC §11）：6 prompt 凍結 / artifact 先於 oracle 生成(已做) / oracle+rubric 凍結 / token 會計(分邊際 vs 攤銷總)+量化早停（第3輪三臂回歸全0且 arm0 邊際成本未顯著>arm3 → 記「此規模無攤銷」）

## 已完成（本 marathon session · 2026-05-30~06-01）

- ✅ **兩份對抗驗證 workflow 報告**（各 ~2.5M token / 22–26 agents）：
  - `.claude-loop/methodology-value-test-design.md` — 根因定論：裸寫「修A壞B」分歧變數=「B 是否與 A 共置於同一注意力窗」；A–E 先驗刪掉此條件故必平手
  - `.claude-loop/baseline-failure-taxonomy.md` — 三閘（公平可重現/方法論真抓/便宜baseline抓不到）全過清單**為空**；M1–M5 失效模式全死在閘2或閘3
- ✅ **Stage F（Evict-then-Edit，已完成）**：`sandbox/.../stage-f/`，Codex 三輪 v1FAIL→v2REDESIGN→v3APPROVE。結果：B1/B2 三臂平手（arm0 一個 grep 抓回窗外消費點）；唯一分歧 B3 是「需求未指定的設計選擇」污染、且 note=review=ritual 全 3/3、五階段零增量。RESULTS 在 `stage-f/RESULTS.md`
- ✅ **校準寫入**：`learning-log.md`（Stage F 條目）+ `CLAUDE_TEMPLATE.md`（Stage F 追加校準塊）+ memory（`project_dogfood_af_investigation.md`）。**均未 commit**
- ✅ Stage A–E 早於本 session（commit `a61449c`，未 push）

## 重要決策 / 發現

- **A–F 六場合併定論**：對「前沿模型 + agent-to-agent + 機械可驗 correctness」，閉環淨成本零增益（含 Stage F 打「B 不在窗」也 null）。價值若有，歸「持久化 + 外部視角」通用動作，**非五階段 ritual**（note=review=ritual 同分多次重現）
- **因果鏈/事實求證的天花板 = context 窗**：窗內裸寫自會做（D/E/F 證），窗外它倆也搆不到 → 把 B 拉回窗的是 grep（通用），非 ritual
- **唯一未測 = 「人」軸**：人類接手/稽核成本、可「證明」覆蓋、弱執行者護欄（需非-correctness-oracle 指標）
- **用戶立場（2026-05-31）**：認為實驗仍「無法體現價值」、表現不夠；提兩方向（1 大型可維護 / 2 legacy 因果鏈+事實求證安全改）；選執行者=自主 agent(A)；Codex 判 Stage G「公平但低功率，4–5K 會被 grep 攤平」後，**用戶選「直接上 10–20K 高功率全量」**接受 ~5–9M 成本
- **反 p-hacking 鐵律**（整輪共識，已預登記）：目標非「設計到方法論贏」；平手是有效否證資料點，不准換種子/codebase 重跑
- **Claude 預判（誠實）**：Stage G 大概率仍平手或訊號歸「一份圖」(arm1≈arm3)；MAP 與 REGISTRY 又雙雙抓到 CTR-B = 再次預示 arm1≈arm3

## 修改過的檔案（未 commit）

- `dev-closed-loop/CLAUDE_TEMPLATE.md` — Stage F 追加校準塊（「B 不在窗」也 null + 人軸）
- `.claude-loop/learning-log.md` — Stage F 條目 + footer
- `sandbox/closed-loop-validation/stage-{f,g}/**` — gitignored 實驗產物
- memory：`project_dogfood_af_investigation.md` + MEMORY.md 索引

## 未決問題

1. **🔴 Stage G 公平性待 Codex 裁**：build agent 把 `INV-x/CTR-x` 詞彙**寫進 codebase 註解**（消費點旁直接寫「新增型別改這四處」）→ arm0 讀檔被白送答案 → 可能全臂平手但非任何臂能力所致（同 Stage D 自我說明耦合）。**下次第一件事：送 Codex 凍結時明問它「要不要 strip 這些 trap 註解」**。strip 才是公平的 legacy regime
2. **a61449c + Stage F 校準未 push/未合 main**：branch `methodology/dogfood-ae-calibration` 領先 main 2 個邏輯變更（a61449c 已 commit、Stage F 校準未 commit）。等整輪結束一起決定 commit/push/歸檔
3. **`.claude-loop/` 多份報告 + demo HTML 未追蹤**：methodology-*.md ×3 + dev-overview-*-demo.html ×2，決定歸檔或清

## 起手式建議

1. 新 session 先 `/dev:handoff load` 接續（會 TaskCreate 重建 Stage G 進行中項）
2. **直接續 Stage G**：送 `before/` + `FROZEN-CHANGES.md` 給 Codex 凍結，**務必同時問註解污染**（未決#1）。Codex 過 + 處理註解 → 建 golden+oracle → 跑 18 runs
3. 跑前確認 Codex 4 必修全落實（SPEC §11）+ 預登記早停判準
4. 若用戶想轉向：A–F 已給 robust null，可改「萃取承重原語瘦身方法論」（人軸 / 持久圖 + 測試 + 一次 review），不再燒 correctness

## ⚠️ Git 狀態

branch `methodology/dogfood-ae-calibration`：
- **2 個未 commit 方法論變更**：`CLAUDE_TEMPLATE.md` + `.claude-loop/learning-log.md`（Stage F 校準）
- **a61449c 未 push**（領先 origin/main 1 commit，A–E 校準）
- 未追蹤：`.claude-loop/{methodology-value-test-design,baseline-failure-taxonomy,methodology-adversarial-review}.md` + 2 個 dev-overview demo HTML + handoff/logs（session 私有）
- sandbox/ 全 gitignored
- **未決：整輪結束後一次決定 commit/push/歸檔策略**
