# 接手測試（人軸 proxy）— 預登記草案（PRE-REGISTER）

> 反 p-hacking 鐵律：本檔在開跑前凍結。平手 = 有效否證，照實記 null，不准換 codebase/變更重跑直到出現想要的結果。
> 狀態：**草案，待用戶核准 + Codex 凍結**。日期 2026-06-01。

## 0. 命題（測什麼）

報告 §8 實驗 I 的 agent-可執行 proxy：**閉環產出的 artifact（MAP/REGISTRY/設計規格/因果鏈表）對「零對話 context 的接手者」是否承重。**

與 A–F 正交：A–F 測**產出者**會不會自己重 grep（給完整 context）；本測測**接手者**有沒有被 artifact 從漣漪 bug 中救到（零 context）。這是 A–F 從未覆蓋、且 agent 能誠實執行的人軸核心。

## 1. 基底 codebase

重用 `sandbox/closed-loop-validation/stage-g/before/`（10145 行多模組 bank，15 模組全綠、vet clean）。

## 2. 🔴 污染前置處理（公平性前提，必須先做且凍結）

現狀：189 處非測試碼註解直接洩漏跨模組漣漪地圖（INV-x 不變式 + CTR-B「新增型別改四處」窮舉點）。**不 strip → 裸碼臂內建 artifact → 必平手且結論無效。**

**Strip 規則（凍結，不得開跑後再改）**：
- **刪除**：任何指名 `INV-[0-9]` / `CTR-[A-Z]` 標識的註解、任何明示「新增 X 需同步修改 Y/此處與 Z 形成對比/窮舉消費點」的跨模組漣漪指引。
- **保留**：函式/型別的常規 doc comment（描述「這個函式做什麼」），只要不洩漏「改這要連動別處」。
- 產出 `before-stripped/`，**兩臂共用同一份 stripped 碼**（差異只在有無 artifact）。
- strip 後跑 `go build ./... && go test ./...` 確認仍全綠（strip 只動註解，不動碼，必須通過）。
- strip diff 交 Codex 審「有沒有 strip 過頭（誤刪正常 doc）或 strip 不足（漏洩漏點）」。

## 3. 變更任務（凍結，選最會踩跨模組漣漪者）

**T = 新增一個交易型別並讓它正確流經系統**（複刻 CTR-B 漣漪結構）。
- 候選：新增「逾期罰息 PenaltyInterest」型別，要求它正確出現在 ledger 記帳 + reporting 報表 + reconcile 月報 + export 匯出（= CTR-B 的窮舉消費點，但 strip 後接手者看不到這份清單）。
- 漣漪本質：漏接任一消費點 → 該型別金額在某報表「靜默消失/不計入」，編譯照過、單測照過（除非 held-out oracle 測到）。
- 最終任務描述在凍結後寫入 `handoff-test/TASK.md`，**6 個臂共用同一字面任務**。

## 4. 臂設計（3 臂 × N 重複，凍結）

零對話 context 的 fresh agent（每臂獨立 session，不互通）：

| 臂 | 拿到什麼 | 測的假設 |
|----|---------|---------|
| **arm0 裸碼** | `before-stripped/` + TASK.md | 接手者自己探索，無 artifact |
| **arm1 +MAP** | arm0 + `session1/MAP.md`（架構導覽） | 一份架構圖是否夠 |
| **arm2 +完整 artifact** | arm1 + REGISTRY.md + 設計規格 + 因果鏈/消費點表 | 完整閉環 artifact 是否承重 |

- **N**：每臂跑 **3 次**（共 9 runs），看穩定性。token 預算硬上限 **2M**，超過即停並記「未完成」。
- 公平：三臂 prompt 模板除「附帶 artifact」段外逐字相同；同一 model tier。

## 5. Oracle（凍結，先於跑臂生成）

- **held-out 測試**：在新型別應出現的**每個消費點**各寫 1 條斷言（ledger/reporting/reconcile/export 至少 4 條），驗「PenaltyInterest 金額正確計入該報表」。
- **主指標（oracle 可判）**：漏接消費點數 = 幾條 held-out 斷言 fail（0 = 完美，越高越糟）。
- **次指標**：是否破壞既有 15 模組測試（回歸）；完成 token 數。
- Oracle 在臂開跑**前**凍結並交 Codex 確認「斷言是否真能抓到靜默漏接、有無洩漏答案」。

## 6. 判定門檻（凍結，先寫死才不算 p-hacking）

- **artifact 承重**：arm2（或 arm1）漏接數**顯著低於** arm0（跨 3 次重複方向一致，非單次波動）→ 結論「閉環 artifact 對接手者承重」→ §4 承重核正當性**升級為已證**，支持混合派保留 artifact 層。
- **null（預期之一）**：三臂漏接數無一致差異 → 「artifact 對接手者亦零增益」→ 連人軸 proxy 也 null → **§4 整個保留理由失去地基，方法論應退極小派**。照實記，不換任務重跑。
- **MAP=完整 artifact**：若 arm1≈arm2 但都 > arm0（即「一份架構圖就夠，完整 REGISTRY 無邊際」）→ 支持「瘦身：只留 MAP，砍 REGISTRY/ID 系統」。

## 7. Claude 誠實預判（開跑前登記，事後不得竄改）

- strip 後，arm0 接手者大概率仍能靠 `go test` 紅燈 + grep 找到部分消費點，但**漏接 reconcile/export 這類遠端消費點**機率高於有 artifact 臂——這是 artifact 唯一可能勝出的點。
- 風險：若 held-out 測試太密集（每個消費點都有現成測試），arm0 跑一次 `go test` 就全紅 → 自己補齊 → 平手（這會讓測試退化成「測試覆蓋率」而非「artifact 價值」）。**故 oracle 必須是 held-out（接手者跑不到的），這條是測試成立的命門。**

## 8. 凍結檢查清單（全勾才開跑）

- [x] strip 完成 + go test 全綠（28 來源檔 + 17 測試檔，~120 處洩漏註解刪除，非測試碼殘留=1 執行期錯誤訊息）
- [x] held-out oracle 抽離 + **實測驗證**：wired→PASS、未接線 Penalty→FAIL 並精準指出四消費點（leak-probe 確認 oracle 區分能力有效）
- [x] TASK.md 凍結（三臂共用字面）— 見 §9
- [x] 判定門檻 §6 已寫死
- [x] 預判 §7 已登記
- [x] token 硬上限 2M 設定

## 9. 開跑前的設計決策記錄（2026-06-01，用戶核准，凍結）

### 決策 D1：oracle 抽離範圍
held-out 只移出「迴圈 AllTypes 偵測消費點涵蓋」的測試（`TestCTRB_AllConsumersCoverAllTypes` + `TestCTRB_ExportConsumesType`）。保留 CTR-A 測試 + 寫死值業務邏輯測試 + baseline 型別數斷言（後者只洩漏「型別數變了」不洩漏「漏接哪個消費點」）。
→ **scope 警告**：移出 oracle = 測「無 exhaustiveness 測試網的 legacy」regime = artifact 的最有利情境之一。若連此都 null → 強 null；若贏 → 結論 scope 限「缺完整性測試的 codebase」。

### 決策 D2（用戶核准）：MissingTypes() 保留原樣
四消費點各自暴露 public `MissingTypes()` 方法 → arm0 grep 一下即得四消費點清單（與 MAP/REGISTRY 給 arm1/arm2 的答案等價）。**保留原樣，接受「有自我文件化的 codebase」regime。**
→ 這是**最不利 artifact 的選擇**：arm0 能靠 grep MissingTypes 自我發現四消費點。若 artifact 在此仍贏 → 結論很硬；若平手 → 強 null「codebase 自帶完整性基礎設施時 artifact 零增益」。**這正是本 repo（依賴影響表）的真實情境。**

### 決策 D3：artifact 即答案鑰匙（已知且接受）
MAP.md §3 直接列「新增 TransactionType 必改的 5 個地方」+ file:line；REGISTRY IF-2 同。所以實驗結構 = arm0（stripped 碼，自我發現）vs arm1（+架構圖含消費點表）vs arm2（+完整 REGISTRY）。這正是「artifact 對零-context 接手者是否承重」最乾淨的測法，符合測試目的。

### 任務 T（凍結）：見 §10 TASK.md 全文。新增 Penalty（逾期罰息）型別並讓它正確流經系統。漣漪結構複刻 CTR-B（已用 leak-probe 驗證：未接線時四消費點靜默失效）。

## 10. TASK.md（三臂共用字面，凍結於 handoff-test/TASK.md）

見 `sandbox/closed-loop-validation/stage-g/handoff-test/TASK.md`。三臂 prompt 模板除「附帶 artifact」段外逐字相同。
