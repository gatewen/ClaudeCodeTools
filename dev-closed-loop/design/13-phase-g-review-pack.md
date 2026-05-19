# Phase G Review Pack — CLAUDE_TEMPLATE.md 行數優化方案

> **review 對象**：閉環開發方法論 v6.3.0 → v6.4.0 升級提案
> **要 reviewer 做的事**：對 Phase G 設計做 cross-source review，找出設計者（單一 LLM）可能漏看的風險 / 替代方案 / 反例
> **建立**：2026-05-19 (origin: claude-opus-4-7 session 196883f8 / 觸發於補強計劃 §13.5)
> **不依賴**：本檔 self-contained，reviewer 不需讀其他檔
> **適合 reviewer**：
> - 不同 LLM（GPT / Gemini / Claude 不同版本）
> - 同一 LLM 不同 session（reset context）
> - 人類 maintainer

---

## 1. 背景

### 1.1 本 repo 是什麼

`AI-ClaudeCode` 是「開發設計閉環」方法論的發佈倉庫。核心產物是 `dev-closed-loop/CLAUDE_TEMPLATE.md`，部署到目標專案後成為該專案的 `CLAUDE.md`，作為 Claude Code 執行依據。

### 1.2 CLAUDE_TEMPLATE.md 角色

- **方法論主檔**：含五階段閉環 Phase 1-5 + 精簡六步 + 認知驗證層 + 配額管理 + 紀律規則
- **執行依據**：Claude Code session 啟動時讀取，作為所有開發任務的 hard rule
- **每 session 必讀**：規模直接影響 baseline token 消耗

### 1.3 當前狀態（2026-05-19）

| 指標 | 值 |
|------|-----|
| CLAUDE_TEMPLATE.md 行數 | 547 |
| v6.3.0 預算上限 | 580（緩衝 33） |
| Hard 上限 | 600（緩衝 53） |
| 升格條目 #006 | 「行數預算估算樂觀」（2026-04-26 升格）|
| 用戶 explicit 痛點 | 「目前太長了」（2026-05-19）|

### 1.4 觸發點：為何現在優化

用戶要求對 v2 補強計劃（封閉環自治化升級藍圖 v2.0）做高標準篩選後，已採納 2 個候選 + 待評 1 個：

| 候選 | 評分 | 預期 CLAUDE_TEMPLATE 增量 |
|------|------|--------------------------|
| A 升格降級機制 | 78.5（B 級採納）| +8 |
| E 8 條 Anti-patterns | 81（A 級採納）| +20 |
| B L1/L2/L3 決策分層 | 待評估 | +25（預估）|

捆綁採納後 547 + 53 = **600 行（撞 hard 上限）**。Phase G 是 dependency unblock。

---

## 2. 提案：Phase G 4 項優化

### 2.1 4 項概覽

| 編號 | 優化項 | 改動 | 行數變動 |
|------|-------|------|---------|
| **A1** | 抽出 HTML 註解 metadata 到獨立檔 | line 493-547 → 新檔 `dev-closed-loop/upgrade-notes.md` | -50 |
| **B1** | 「工作規範」段（Git / 品質 / 文檔 3 條目）移至 `.claudedocs/standards/Git工作流.md`（**「問題追蹤」條目保留主檔** · 自審 Finding 1）| line 462-472 部分外移 | -7 |
| **B2** | 「Trade-off 顯式宣告」壓成「代價收益表格 + 不適用情境 prose」（自審 Finding 3）| line 3-23 散文 21 行 → 12 行 | -9 |
| **B3** | 「跨 Session 持久化 + 跨時間語義記憶」併段 | line 448-459 12 行 → 5 行 | -7 |

**CLAUDE_TEMPLATE.md 預期淨變動**：-73 行（547 → 474）

### 2.2 預期效果

| 指標 | 當前 | Phase G 後 |
|------|-----|----------|
| CLAUDE_TEMPLATE.md 行數 | 547 | 474 |
| vs hard 上限 600 緩衝 | 53 | 126 |
| 採納 A+E+B 後 | 撞 600 | 527（緩衝 73）|

### 2.3 修改方案（7 處）

| # | 檔案 | 改動 | 行數變動 |
|---|------|------|---------|
| 1 | `CLAUDE_TEMPLATE.md` | 4 項優化 | -73 |
| 2 | `dev-closed-loop/upgrade-notes.md`（新檔）| 接收 metadata | +60 |
| 3 | `dev-closed-loop/skill/init-claude.md` | Step 5.2 從 upgrade-notes.md 讀 migration-notes | +3 |
| 4 | `.claudedocs/standards/Git工作流.md` | 接收工作規範 3 條目 | +8 |
| 5 | `dev-closed-loop/README.md` + 根 `README.md` | v6.4.0 版本歷史 | +10 |
| 6 | `setup.sh` | 驗證清單加 upgrade-notes.md | +2 |
| 7 | `tests/test-cross-file-consistency.sh` | 新檔結構驗證 | +5 |

---

## 3. 實施計劃：大型完整 5-Phase 閉環

| Phase | 動作 |
|-------|------|
| Phase 1 | architect 設計 BC-1~BC-7 + EH-1~EH-3 + IF-1~IF-2 + 分層 + 行數預期表 |
| Phase 1b | design-reviewer 評風險 |
| Phase 2 | **雙寫策略**：複製 metadata 到新檔不刪原 → 改 init-claude.md → 本地驗證 → atomic 刪 CLAUDE_TEMPLATE 內 metadata |
| Phase 3 | code-reviewer cross-file 一致性 + 安全審查跳過（純結構整理）|
| Phase 4 | 7 smoke + bash setup.sh 重部署本地驗 + **模擬 v6.x → v6.4.0 + v5.x → v6.4.0 升級**（自審 Finding 4）|
| Phase 5 | verifier 雙向追溯 + 升格檢查 |

預估總 cost：~110K token

---

## 4. 自審已發現的 4 個 issue（同 LLM 同 session 自審）

| Finding | 修正 |
|---------|------|
| **F1** B1 工作規範段內「問題追蹤」是 Section 6c 對映，**不該外移** | B1 從抽 4 條目改為抽 3 條目（Git / 品質 / 文檔），行數變動 -9 → -7 |
| **F2** B2 壓 Trade-off 時必須保留「## 語言設定」heading（anchor `trade-off-section` 用此 match 字串）| §13.5.7 風險表加「anchor match 字串相容性」緩解 |
| **F3** Trade-off 「不適用情境」prose 不該全壓表格 | B2 改為「代價收益表格 + 不適用情境 prose」 |
| **F4** Phase 4 須測 v5.x → v6.4.0 跨多版本升級，不只 v6.x internal | §13.5.6 Phase 4 補測試動作 |

**自審局限**：以上是「同 LLM 同 session 自審」能找到的明顯 gap。找不到「未知未知」的 fundamental blindspot，仍需 cross-source review。

---

## 5. 給 reviewer 的 questions

### 5.1 4 項優化有遺漏的副作用嗎？

特別檢查：
- A1 抽 metadata 對 `init-claude.md` Step 5 v5→v6 Migration Flow 是否有 edge case？
- B1 抽工作規範到 `Git工作流.md`，這個 standards 檔的角色是給人類讀的，會不會破壞既有「.claudedocs 是給人類，CLAUDE_TEMPLATE 是給 Claude」的分層原則？
- B2 Trade-off 表格化是否會失去某個我沒看到的訊息密度？
- B3 持久化併段是否會失去 detail？

### 5.2 抽 metadata 對 init-claude.md upgrade flow 真的零風險？

init-claude.md Step 5 用 awk 解析 CLAUDE_TEMPLATE.md 的 HTML 註解區塊（pattern `<!--$/.../`-->`）取得 migration-notes。改讀 `upgrade-notes.md` 時：
- 新檔的 HTML 註解結構是否與 awk 邏輯相容？
- 多個 migration-notes 區塊（v5→v6 / v6.2 / dogfooding-1 / v6.4.0）共存於新檔時，awk 是否能正確分辨？
- 如果用戶卡在某中間版本（v6.1.0）升 v6.4.0，是否要依序套用 v6.2 → v6.4.0 的 migrations？

### 5.3 雙寫策略有沒有 edge case？

Phase 2 流程：
1. 複製 metadata 到 upgrade-notes.md（不刪 CLAUDE_TEMPLATE 內）
2. 改 init-claude.md 從新路徑讀
3. Phase 4 驗證
4. Atomic 刪 CLAUDE_TEMPLATE 內 metadata

**Edge case**：
- 步驟 3 失敗後 rollback，留 upgrade-notes.md 新檔在 repo 內是否有 side effect？
- 步驟 4 atomic 刪如果只刪一部分（partial failure），如何 detect？

### 5.4 7 處修改有沒有更小規模做到同樣效果？

可選替代方案：
- 不抽 metadata 到新檔，僅壓縮 metadata 內部？（例：v5→v6 / v6.2 / dogfooding-1 三段 merge 為 v6.x cumulative migration-notes）
- 只做 A1 不做 B1+B2+B3（節省 50 行也許足夠了）？
- 是否有比「雙寫策略」更輕量的 atomic 切換方式？

### 5.5 §13.5.9「為何不更激進」論述合理嗎？

我列了 3 個被拒絕的更激進方案：
- 抽 Section 6-13 各細節到 .claudedocs/process/ — 拒絕：破壞主檔即執行依據原則
- 完全重寫 CLAUDE_TEMPLATE 結構 — 拒絕：高風險 accumulated 紀律會散失
- 抽 Section 12 / 12.5 / 13 認知驗證層 — 拒絕：弱化核心 fallback

reviewer 同意這 3 個都該拒絕嗎？有沒有第 4 個方案被忽略？

### 5.6 「保守 4 項是最大 ROI / 最小風險交點」這個判定是否真成立？

我宣稱 A1+B1+B2+B3 是「最大 ROI / 最小風險交點」。reviewer 從 outside-in 看，是否同意？或是某個 finer-grained 組合更好？

### 5.7 跨 LLM platform 是否有相容性問題？

本 repo 設計時假設 Claude Code 是 primary，但 init-claude.md 邏輯應該也能在 Codex / Gemini CLI / 其他平台 work（透過 cat or @import）。Phase G 改動是否影響跨平台相容性？

---

## 6. 要 reviewer 給的輸出

### 6.1 判定（3 選 1）

- **採納**：4 項優化方案合理，可進入實施階段
- **修改**：某些優化項需調整（請指出哪幾項 + 怎麼改）
- **拒絕**：方向錯，建議重設計（請指出根本問題）

### 6.2 主要風險識別

reviewer 看到的 3 大風險（按優先級）：
1.
2.
3.

### 6.3 替代方案建議

reviewer 看到的更好替代方案（如有）：

### 6.4 自審 4 finding 是否充分？

我列的 F1-F4 是否漏看了第 5 個明顯 issue？

---

## 7. 附錄：CLAUDE_TEMPLATE.md 結構盤點（547 行）

| 區段 | 行數 | 性質 |
|------|-----|------|
| Trade-off 顯式宣告（line 3-23）| 21 | 教學 / 期待管理（B2 目標）|
| 語言設定 + 專案配置（line 24-35）| 12 | placeholder |
| Section 0 四原則橫切（line 36-54）| 19 | 紀律 |
| Section 1-5 任務分級 + 流程（line 56-127）| 70 | 執行 |
| Section 6 / 6b / 6c（line 128-192）| 65 | 領域 / 模組 / 教訓查詢 |
| Section 7 / 8（line 193-205）| 13 | 失敗處理 + 熔斷 |
| Section 9 / 9b / 10 / 11 / 11.5（line 206-246）| 41 | 修改前紀律 |
| Section 12（line 247-263）| 17 | 認知驗證 |
| Section 12.5 Push Back（line 265-298）| 34 | 認知驗證（已壓縮一次）|
| Section 13 質疑熔斷（line 299-312）| 14 | 認知驗證 |
| 完整閉環 Phase 1-5（line 319-364）| 46 | 執行步驟 |
| 精簡閉環六步（line 367-404）| 38 | 執行步驟 |
| 配額管理策略（line 407-431）| 25 | 降級規則 |
| 模組登記 / 產出物格式（line 434-446）| 13 | cross-ref |
| 跨 Session 持久化 + 跨時間語義記憶（line 448-459）| 12 | B3 目標 |
| 工作規範（line 462-472）| 11 | B1 目標 |
| 參考文檔 + 補充文檔（line 474-490）| 17 | cross-ref |
| HTML 註解 metadata（line 493-547）| 55 | A1 目標 |

---

## 8. 附錄：HTML 註解 metadata 完整內容（A1 抽出對象）

當前 line 493-547 內容類型：

1. **`closed-loop v6.3.0` 版本標記**（部署 + status 偵測用，保留主檔）
2. **migration-notes（v5.x → v6.0.0）**：含 breaking-changes / required-actions / recommended-actions / anchors 列表（3 個 anchor）
3. **migration-notes-v6.2**：簡單條目格式（no breaking）
4. **dogfooding-1 patch**（2026-04-26）：簡單條目格式

A1 抽出策略：
- 保留主檔：`<!-- closed-loop v6.4.0 -->` 一行（用於 grep 'closed-loop v' 仍命中）
- 抽到 upgrade-notes.md：上述 2-4 三組區塊 + 未來 v6.4.0 自己的 migration-notes

---

**Review 結束後**：請把判定 + 風險 + 替代方案 + Finding 補充回給 setup session 的用戶，由用戶決定是否進入 Phase G 實施。
