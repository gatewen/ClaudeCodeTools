# 委派審查 Prompt 範本

子 agent 委派時使用的 Task prompt 範本。CLAUDE.md 中的閘門和規則是硬性約束，本文件提供完整的 prompt 內容。

---

## Phase 1b：設計審查 Task Prompt

**Task prompt 必須包含**：
- 角色：「你是獨立設計審查者，與設計者無關，不知道設計過程中的推理」
- 挑戰式標準：是否有更簡單的替代方案？BC-x 數量與功能複雜度是否匹配（過多=過度設計，過少=覆蓋不足）？有無設計不足？
- 架構體質標準：新設計是建立在穩固的基礎上，還是在脆弱/過時的架構上繼續堆疊？現有模組的存在理由還成立嗎？有沒有可以一起移除的多餘層級？這個架構能支撐未來的擴展嗎？（體質問題 → 標 arch-risk 或 high）
- 驗證式標準：每個 BC-x 的預期行為是否可測試？EH-x 是否覆蓋外部失敗（網路/IO/權限/並發）？資源建立/釋放是否配對？互斥狀態是否用 union/enum 而非多 boolean？若有 update/tick 迴圈：執行順序是否已定義？（未定義 → 直接標 high）
- 輸出格式：DR-x + 嚴重度（high/arch-risk/medium/low）+ 問題描述 + 建議修正
- 寫入指令：「將完整審查報告寫入 `.claude-loop/artifacts/P1b-design-review.md`」

**審查包**（主 agent 在發送 Task 前準備）：
- Phase 1 設計規格全文（BC-x/EH-x/IF-x 清單）
- 原始需求描述（用戶的任務說明，或 PRD 原文）
- 專案結構摘要：
  - 一層目錄結構（`ls` 或 `tree -L 2` 產出）
  - 每個現有關鍵模組的一句話職責（從 README 或程式碼推斷）
  - 現有 IF-x 介面契約清單（若有跨模組依賴）

---

## Phase 3：品質審查 Task Prompt

**Task prompt 必須包含**：
- 角色：「你是獨立品質檢核師，與實作者無關，不知道實作過程中的推理」
- 輸入：Phase 1 設計規格 + Phase 2 程式碼檔案路徑（子 agent 用 Read 自行讀取）+ 語言指南 Phase 3 段落（若有）
- 審查規則：比對設計與實作一致性 + 結構安全（資源生命週期配對/錯誤靜默/非法狀態組合）+ 語言專屬審查（標 `[語言名]`）+ 跨模組資料流追蹤（拆分邊界的資料過濾/轉換是否保持下游模組預期的語意）+ 合理性審查（實作結果從使用者角度看是否合理：操作流程有無變複雜？多個功能組合使用時體驗是否順暢？有無引入不必要的效率退步？）
- 輸出：R-x + 嚴重度（high/arch-risk/medium/low/by-design）+ 問題描述 + 建議修正
- 寫入指令：「將完整檢核報告寫入 `.claude-loop/artifacts/P3-quality-review.md`」

---

## Phase 3：安全審查 Task Prompt

**Task prompt 必須包含**：
- 角色：「你是獨立安全檢核師」
- 輸入：Phase 2 程式碼檔案路徑
- 審查規則：輸入驗證 / 注入風險 / 認證授權 / 敏感資料暴露 / 依賴安全
- 輸出：R-x + 嚴重度 + 問題描述 + 建議修正
- 寫入指令：「將完整檢核報告寫入 `.claude-loop/artifacts/P3-security-review.md`」

---

## Phase 5 Part AB：雙向追溯 Task Prompt

**Task prompt 必須包含**：
- 角色：「你是獨立自証審查者（雙向追溯），與開發者無關，不知道開發過程」
- 正向追溯規則：對每個 BC-x/EH-x，在程式碼中找到對應實作（標 ✅/❌ + 檔案:行數），在測試中找到對應案例（標 ✅/❌ + 測試名稱）。`[visual-only]` 和 `[framework-dependent]` 項的測試欄位標注驗證方式而非測試名稱
- 反向分析規則：識別所有行為路徑（正常/錯誤/邊界）→ 逐一對應 BC-x/EH-x → 未對應的標記 `[遺漏設計]`（應有 BC-x 但未定義）或 `[多餘程式碼]`（不該存在的行為）
- 交叉比對規則：正向發現 ❌ 時，立即在反向分析中確認該 BC-x 附近是否有相關行為路徑；反向發現未覆蓋路徑時，立即在正向追溯中確認是否有對應設計項
- arch-risk 追蹤規則：逐一確認 Phase 1b 和 Phase 3 標記的 arch-risk 項目，評估是否在後續 Phase 中已緩解或仍存在
- 路徑追蹤：挑最複雜 2-3 個 BC-x，追蹤 入口→處理→出口 完整路徑，比對設計意圖
- 輸出格式：正向追溯表（逐項 ✅/❌ + 證據位置）+ 反向未覆蓋路徑清單 + arch-risk 追蹤狀態 + 執行路徑追蹤結果 + 交叉比對發現
- 寫入指令：「將完整雙向追溯結果寫入 `.claude-loop/artifacts/P5AB-bidirectional-tracing.md`」

**驗證包**（主 agent 準備）：
- Phase 1 設計規格全文（BC-x/EH-x/IF-x 清單，含驗證層級標注）
- Phase 1b DR-x 審查報告（含 arch-risk 項目清單）
- Phase 3 R-x 檢核報告（含 arch-risk 項目清單）
- Phase 2 程式碼檔案路徑清單（子 agent 用 Read 自行讀取比對）
- Phase 4 測試檔案路徑清單（子 agent 用 Read 自行讀取比對）
- PRD 分解表（若有）
- 語言指南部署狀態

**檢查步驟**：
0. 若有 PRD 分解：逐一確認每個 PRD#n 有 ≥ 1 個對應 BC-x/EH-x（✅/❌）。有 ❌ → 標記回退
1. 從 Phase 1 列出所有 BC-x、EH-x、IF-x（若有）→ **基準清單**
2. 逐一確認 Phase 2 有對應實作（✅/❌）。IF-x 需確認函式簽名與契約一致
3. 逐一確認 Phase 4 有對應測試或驗證方式（✅/❌）。`[testable]` 項需有自動化測試；`[visual-only]`/`[framework-dependent]` 項需有標注的替代驗證方式
4. Phase 3 的 high/medium R-x 是否已修（✅/❌）
4b. 若已部署語言指南：Phase 3 R-x 報告是否包含語言專屬項（帶 `[語言名]` 標記）？（✅/❌）
4c. Phase 1b 的 DR-x high 是否已修正（✅/❌）？medium 的用戶決策是否有記錄（✅/❌）？
5. 閱讀 Phase 2 程式碼，找出不被任何 BC-x/EH-x 覆蓋的行為路徑。有 → 判定是遺漏設計還是多餘程式碼
6. 挑最複雜的 2-3 個 BC-x，沿程式碼追蹤執行路徑，驗證行為與設計意圖一致
7. 交叉比對步驟 1-4（正向）與步驟 5-6（反向）的結果，標記矛盾或互補的發現
8. 逐一確認 Phase 1b 和 Phase 3 標記的 arch-risk 項目的當前狀態

**產出**：雙向追溯結果，寫入 `.claude-loop/artifacts/P5AB-bidirectional-tracing.md` 並回傳給主 agent。

---

最後修訂：2026-03-21（v5.10.0）
