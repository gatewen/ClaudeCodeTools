# K-13 自循環模式評估結果（不做）

> 決策日期：2026-04-26
> 上游：design/08 v6.3.0 milestone「K-13 緩議」+ design/10 v6.3.0 K-07-only 規劃
> 觸發：v6.3.0 K-07 完成後啟動的 K-13 brainstorming session
> 用戶決策（2026-04-26）：不做 K-13，視為與既有斷點 B 重疊
> 結果：K-13 從 v6.x 規劃移除，**v6.x 系列在 v6.3.0 正式結束**

---

## 決策摘要

K-13「Karpathy 自循環模式」（受「LLMs are exceptionally good at looping」洞察啟發）原規劃在 v6.3.0 補充。design/08 line 91 已標 RISK-6「跟斷點 B 狀態機衝突」中等風險，要求先 brainstorm 釐清。

K-07 完成後啟動 brainstorming，分析既有斷點 A/B 機制 vs K-13 預期行為，**4 個未解問題在分析「跟斷點 B 重疊度」時自動消解**——既有機制已涵蓋 K-13 預期效果。

決議：**v6.x 不做 K-13**。

---

## K-13 vs 既有斷點機制對比

| 維度 | K-13 自循環（Karpathy 啟發） | 既有斷點 A（CLAUDE_TEMPLATE Section 3 / Phase 3） | 既有斷點 B（Phase 4） |
|------|---------------------------|------------------------------------------|--------------------|
| 觸發條件 | implementer / tester 內部失敗 | Phase 3 R-x high | Phase 4 測試失敗 |
| 行為 | 內部 N 輪自修 → N 輪後失敗升格 | 回 Phase 2 修正 + 重跑 P3（差分審查）| 程式碼 bug → 回 P2 重跑 P3+P4 / 測試設計問題 → P4 原地修 |
| 終止條件 | 自循環設計值（如 3 輪）| 修到無 R-x high | 測試全綠 |
| 失敗計數 | 每輪 inner loop 計 1 | 每次 P2↔P3 round-trip 計 1 | 每次 P2↔P3↔P4 round-trip 計 1 |
| 升格機制 | 達循環上限 → 升斷點 B？升熔斷？ | 累積 3 次（含全部斷點）→ 熔斷協議（CLAUDE_TEMPLATE Section 8）| 同左 |

**重疊判定**：K-13 跟斷點 A/B 都做「失敗 → 修 → 重試」這件事。差異只在「inner loop 還是 outer loop」——但實際運作上：
- inner loop（K-13）需在 implementer.md / tester.md 各加 self-loop 邏輯 + 輪次計數
- outer loop（既有斷點）已透過 Phase 之間 round-trip + 熔斷協議實現

兩套機制達成相同目的（最多 3 輪修正後升人介入）但 K-13 增加了 **agent prompt 複雜度**和 **self-loop 跟 outer loop 之間的失敗計數溝通協議**。

---

## 為什麼「不做」是正確選擇

### 1. 重複建設

熔斷協議（CLAUDE_TEMPLATE Section 8）已 explicit 規範：
> 同一 Phase 的斷點累計觸發 **3 次** → 暫停流程，**先追加學習日誌**，再用 AskUserQuestion 報告情況

這已是 Karpathy「3 輪自修正」精神的閉環版實現。再加 K-13 inner loop 等於在現有 outer loop 之上疊加另一層計數，實際效果一樣但複雜度加倍。

### 2. 符合 Karpathy Q2 Simplicity（已用 K-07 02 案例自我驗證）

K-07 02-simplicity-first.md 案例：「Strategy pattern 處理單一計算」是過度設計。K-13 inner loop 在 implementer / tester agent 加 self-loop 機制，但既有 outer loop 已能處理同樣場景——這就是「未發生的需求 + 預先抽象」的典型 anti-pattern。

選「不做」即是用 v6.3.0 K-07 自身的方法論精神審視 K-13。

### 3. 風險 vs 回報失衡

design/08 RISK-6 標 K-13「跟斷點 B 狀態機衝突」中等風險。完整 brainstorm + 設計 + 實作 + 測試的 cost ≥ v6.2.0 規模（+ 認知對稱性 + KPI），但 outcome 只是「重複實現 outer loop」——回報不對稱。

### 4. v6.x 系列已收斂

v6.0 → v6.1 → v6.2 → v6.3 = 5 + 6 + 3 + 1 = **15 條 K-x 全部完成**（K-12 已移除 / K-13 不做 / K-07-K-11 + K-14-K-17 全做）。v6.x 主軸（行為哲學 + 認知對稱性 + 健康指標 + 對照範例）在 v6.3.0 自然收尾，無 K-13 不影響整體完整性。

---

## v6.x 系列盤點

| 版本 | K-x 範圍 | 主軸 |
|------|---------|------|
| v6.0.0 | K-01 / K-04 / K-09 / K-15 / K-17（5 條）| 核心結構與哲學（Section 0 + push back + Trade-off + README + migration）|
| v6.1.0 | K-02 / K-03 / K-05 / K-06 / K-08 / K-16（6 條）| 執行細節（senior test + 3x rule + dead code + R-style + Goal 轉換 + Anti-Patterns）|
| v6.2.0 | K-10 / K-11 / K-14（3 條）| 認知對稱性 + 運作指標（ID↔失誤類型 + KPI + 反向質疑協議）|
| v6.3.0 | K-07（1 條 · K-13 緩議後決議不做）| 對照範例庫（5 個 anti-pattern 對照檔）|
| **累計** | **15 條 K-x（K-12 移除 / K-13 不做）** | **行為哲學 + 認知 + KPI + 範例 完整層** |

**從 design/08 規劃的 17 條 K-x 中**：
- ✅ 完成 15 條：K-01-K-11 + K-14-K-17
- ❌ 移除 2 條：K-12（v6.0.0 規劃時已決議移除）/ K-13（v6.3.0 brainstorm 後決議不做）

達成率：15/17 = 88%；剔除事後評估不做的，可視為「全部該做的都做了」100%。

---

## 後續：v7 是否重評 K-13？

**v7 重評觸發條件**（如有）：

1. **K-11 KPI 累積數據**：v6.2.0 ~ v6.3.x 觀察期累積 ≥ 5 個閉環後，若 R-x high / DR-x high 數據顯示「Phase 2/4 反覆失敗 → 用戶介入頻率高」 → 可能重啟 K-13 評估「inner loop 是否能減少用戶介入」
2. **新範式出現**：若 LLM 能力大幅升級（如 multi-agent self-debate），K-13 可能在不同形態下重新評估
3. **本方法論其他擴充與 K-13 整合的機會**：例如 v7 加「自動化 prototype mode」，K-13 inner loop 可作為 prototype mode 子能力

**不重評的條件**：
- v7 主軸跟 K-13 無關（如純文檔升級 / 規則簡化 / Hook 系統重構）
- KPI 數據顯示既有 outer loop 已足夠（升格觸發頻率在健康區間 1-3/月）

---

## v6.x 結束

**branch 狀態**：`feature/v6.0.0-karpathy` 含 v6.0/v6.1/v6.2/v6.3 + design/08-11 共 4 個 milestone + 4 個設計文件 + K-13 評估。

**下一步選項**（用戶決定）：
1. 合併 `feature/v6.0.0-karpathy` → `main`（v6.x 系列上岸）
2. 暫停等 K-11 KPI 累積數據（v6.2.0 ~ v6.3.x 為觀察期，≥ 6 個月或 ≥ 5 個閉環後重評）
3. 啟動 v7 規劃（含 KPI 校準 + 規則簡化 + 可能新主題）

---

最後修訂：2026-04-26（K-13 評估結果定稿，不做；v6.x 系列在 v6.3.0 正式結束）
