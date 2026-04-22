# {{PROJECT_NAME}}

## 語言設定

- 所有互動使用繁體中文
- 程式碼註解使用繁體中文

## 專案配置

- **語言**：{{LANGUAGE}}
- **框架**：{{FRAMEWORK}}
- **測試指令**：`{{TEST_COMMAND}}`
- **建置指令**：`{{BUILD_COMMAND}}`

## ⚠️ 執行約束（最高優先級）

收到任何非微小的任務時，**禁止直接開始寫程式碼**。必須先判定等級再執行對應流程。

### 1. 判定任務等級（必做）

| 等級 | 條件 | 要求的流程 |
|------|------|-----------|
| **微小** | < 50 行 · 單檔修改 · 設定調整 · 用戶說「快速修改」 | 直接執行 |
| **中型** | 新增單一函式/元件 · 1-3 檔案 · < 300 行 | 精簡閉環（設計→設計快審→實作→品質審查→測試驗證→迷你追溯） |
| **大型** | 新模組/功能 · (≥ 3 檔案或 ≥ 300 行) 且有多個交互子系統 · 用戶說「完整閉環」 | 完整五階段閉環（Phase 1→5） |

### 1b. 需求探索（中型 + 大型 · 可選）

需求描述不夠具體（缺少明確範圍、技術路線、或行為預期）時，用 AskUserQuestion 詢問用戶是否要先探索需求。用戶選否 → 跳到 Section 2。
**用戶選是 → Claude 主動從多角度分析，整理為選項讓用戶選擇**：
- 至少涵蓋 3 個角度，每個角度產出**具體選項**（非分析報告），用 AskUserQuestion 呈現：
  - **範圍界定**：MVP vs 完整版的切分建議，讓用戶選邊界
  - **替代方案**：2-3 種技術路線的取捨比較，讓用戶選方向
  - **邊界情境**：容易忽略的極端/並發/異常情境，讓用戶決定是否納入
  - **架構影響**：對現有系統的衝擊範圍，讓用戶確認可接受的影響
- 可多輪迭代直到需求收斂
- **產出**：明確的需求陳述（含範圍、關鍵行為、已決定的技術方向），作為 Phase 1 的輸入

### 2. TaskCreate 拆解（中型 + 大型必做）

**大型任務 — 單模組**：建 6 個 Phase 任務 + blockedBy 鏈：
`[P1-設計] → [P1b-設計審查] → [P2-實作] → [P3-檢核] → [P4-測試] → [P5-自證]`

**大型任務 — 多模組**：每個模組建 `[P1] → [P1b] → [P2] → [P3] → [P4]` 鏈，有 IF-x 依賴的模組按依賴順序執行（被依賴方先完成 P2）。所有模組完成 P4 後 → 統一 `[P5-整合自證]`（blockedBy 所有 P4）。
**單模組 vs 多模組判定**：子系統共享核心狀態物件且 API 邊界不清晰 → 視為單模組；子系統有獨立狀態且透過明確介面溝通 → 視為多模組。

**中型任務** — 建 6 個任務 + blockedBy 鏈：
`[設計] → [設計快審] → [實作] → [品質審查] → [測試驗證] → [迷你追溯]`

**每步上限**：最多 2-3 個檔案或 ~300 行程式碼。有強型別依賴的檔案（拆開會導致增量驗證失敗）可捆綁在同一步，即使超過 3 檔。

### 3. ⛔ 禁止跳過的閘門

- ⛔ **禁止**沒有設計產出就寫程式碼
- ⛔ **禁止**沒有驗證就標完成
- ⛔ **禁止**單次回應寫完所有檔案

### 4. 逐步執行（必做）

- 按順序，一次只做一個步驟
- 每完成一步，用 TaskUpdate 標記 completed
- blockedBy 未解除前，禁止將該任務設為 in_progress
- **activeForm 即時更新**：調用 agent 前，用 TaskUpdate 更新當前任務的 `activeForm` 為 agent 名稱（例如 `"🔍 code-reviewer 品質審查中..."`），讓用戶在 spinner 即時看到哪個 agent 在執行
- **斷點狀態回退**：斷點觸發回退時，用 TaskUpdate 將回退目標任務設回 `in_progress`（activeForm 標注修正原因），並將當前任務設回 `pending`（description 標注等待原因）
- **升級機制**：實作過程中若發現實際規模超出當前等級（精簡閉環的檔案數 ≥ 3 或行數 ≥ 300），暫停當前流程，升級為完整閉環（已完成的設計保留為 Phase 1 基礎，從 Phase 2 繼續）

### 5. 可見性（必做）

- **TaskCreate**：觸發閉環時立即建立任務鏈（大型 6 個 / 中型 6 個），讓用戶看到進度
- **Phase 標記**：進入/離開每個 Phase 時輸出 `═══ 📐 Phase 1：架構師 | 開始 ═══` 格式標記
- **Agent 宣告**：調用 Agent 時輸出 `→ 調用 ...`，完成時輸出 `← ... 完成：[摘要]`
- **Agent 活動日誌**：每次 agent 調用完成後，追加一條記錄到 `.claude-loop/agent-activity.md`（格式見產出物格式.md）。記錄：時間、agent 名稱、Phase、輸入摘要、產出摘要、狀況
- **Agent 學習查詢**：調用 agent 前，若 `.claude-loop/learning-log.md` 存在，用 Grep 搜尋 `[{agent-name}]` 標籤的條目，將相關教訓傳給 agent（inline 直接參考，task 附加到資料包）

### 6. 領域偵測與規則預設（Phase 1 前自動判定）

根據專案語言、框架、imports 自動偵測領域，套用對應預設。用戶可覆蓋（例如「使用遊戲開發預設」）。

| 領域 | 偵測信號 | EH-x | 安全審查 | 驗證層級預設 | 單檔上限 |
|------|---------|------|---------|------------|---------|
| 遊戲開發 | macroquad/bevy/godot/unity/Canvas 遊戲迴圈 | 可選 | 可跳過 | 預設 `[framework-dependent]`，例外標注 | 400 行 |
| 後端 API | express/fastapi/gin/actix/HTTP handler | 必要 | 必要 | 預設 `[testable]`，無需標注 | 300 行 |
| 前端 SPA | React/Vue/Angular + 無後端 | 條件判定 | 條件判定 | 混合，須逐項標注 | 300 行 |
| CLI 工具 | clap/commander/argparse + 無 GUI | 條件判定 | 條件判定 | 預設 `[testable]`，無需標注 | 300 行 |
| 系統程式 | 網路/unsafe/檔案 I/O 密集 | 必要 | 必要 | 預設 `[testable]`，無需標注 | 300 行 |

**未匹配時**用後端 API 預設（最嚴格）。
**「預設 `[testable]`，無需標注」**：該領域的 BC-x/EH-x 視為 `[testable]`，只有例外（渲染/動畫等）才需標注 `[visual-only]` 或 `[framework-dependent]`。
**「條件判定」**：按 Phase 1/Phase 3 中的具體條件判斷。

### 6b. 模組資產查詢（Phase 1 前 · 條件式）

`.claude-loop/module-registry.md` 存在時執行，不存在則跳過（專案初期尚無已登記模組）。

讀取 module-registry.md，根據當前需求判斷有無可複用的功能層。在畫面輸出：

```
🔍 [模組資產查詢]
├─ 當前需求：{一句話描述}
├─ 已有模組：{列出相關模組}
├─ 可複用：{哪些功能層可直接使用}
└─ 需新建：{需設計的新模組或新 UI 層}
```

- 有可複用功能層 → Phase 1 設計規格標注「複用 [模組名] 功能層」，只設計新增功能或 UI 層
- 無可複用 → 正常設計，但在分層聲明中考慮未來複用性

### 6c. 兩層教訓查詢（Phase 1 前）

兩層架構分工：**長期警惕模式**（跨閉環，問題追蹤.md）+ **learning-log**（session 內，per-閉環）。Phase 1 起手式按以下順序查詢：

#### 6c-1 長期警惕模式（**必讀，永遠不可跳過**）

讀取 `.claudedocs/records/問題追蹤.md`「長期警惕模式」section。這是累積 ≥ 3 次升格的高頻模式，每次 Phase 1 必過。掃描每筆條目的「觸發情境」與當前需求比對，命中的條目把「預防做法」納入本次設計考量。在畫面輸出：

```
🛡️ [長期警惕模式] {N} 筆已升格條目
├─ 命中條目：{#XXX [模式名] - 預防做法}
└─ 無命中：{已掃 N 筆，無相關前車之鑑}
```

#### 6c-2 learning-log 補充（條件式）

`.claude-loop/learning-log.md` 存在時讀取，不存在則跳過。掃描近期事件條目，找出與當前需求相關的失敗根因和誤判模式。在畫面輸出：

```
📚 [學習日誌] {N} 筆記錄
├─ 相關教訓：{與當前需求相關的近期失敗根因}
└─ 高頻問題：{出現 ≥ 3 次但未升格的問題類型 → 提示 Phase 5 升格時應確認}
```

- 有相關教訓 → Phase 1 設計時主動考慮（例如：歷史上 resource cleanup 常遺漏 → 本次設計 EH-x 時特別標注 cleanup）
- 條目 ≥ 5 且未做過模式分析 → 提示用戶，同意後執行（格式見產出物格式.md）

#### 6c-3 強制標示

設計規格末尾必須附一行學習查詢結果：
- 「**學習查詢**：問題追蹤命中 [#XXX, #YYY] / learning-log 命中 N 筆 / 全無相關前車之鑑」三選一

### 7. 子 agent 失敗處理（全域規則）

子 agent（Phase 1b/3/5 的 Task 委派）超時、輸出為空、或明顯不完整時：
1. **第一次失敗**：重試一次（相同 prompt）
2. **第二次失敗**：主 agent 自行執行相同審查（標記「降級自審」）
3. 降級自審的結果在 Phase 5 產出物驗證中標記，不視為缺失但記錄品質降級

### 8. 斷點熔斷（全域規則）

同一 Phase 的斷點累計觸發 **3 次** → 暫停流程，**先追加學習日誌**（標記 `[circuit-breaker]`，記錄累積的失敗模式），再用 AskUserQuestion 報告情況，由用戶決定：
- 繼續嘗試修正
- 降級為精簡閉環完成剩餘工作
- 重新設計（回 Phase 1 重新開始）

### 9. 修改前守衛（Hook 阻擋式雙閘門 + 理解確認）

每次 Edit/Write/MultiEdit 前，PreToolUse Hook 執行兩道閘門，任一未通過即阻擋（exit 2）：

- **閘門 A — 理解確認**：UserPromptSubmit Hook 偵測到修改意圖時設旗標，首次修改被擋住。你必須先在畫面輸出：

```
🟠 收到：[一句話摘要用戶的意圖]
🟠 打算：[一句話說明要做什麼]
```

純問答不觸發。連續對話已對頻可省略，方向變化時必須重新確認
- **閘門 B — 因果鏈分析**：首次修改某檔案時阻擋。你必須輸出因果鏈分析區塊：

```
⚠️ [因果鏈分析] 修改 {檔案名}:{函式名}
├─ 根因：{為什麼要改這個檔案}
├─ 呼叫者（grep 結果 N 個，逐一分析）：
│   ├─ {檔案:行號} — {呼叫端函式名}
│   │   影響：{這個呼叫者會受什麼影響，含語意變化}
│   │   需連動：{是/否} — {是→具體改什麼；否→為什麼不影響}
│   ├─ {檔案:行號} — {呼叫端函式名}
│   │   影響：{同上}
│   │   需連動：{同上}
│   └─ （每個 grep 結果都展開，不可省略）
│   呼叫者 = 0 → ⛔ 停，先找真正的執行路徑
├─ 隱性風險：{不會立即報錯但行為可能改變：快取失效/時序變化/語意漂移}
└─ 決策：{連動更新清單，或逐條說明為什麼不需要}
```

兩道閘門同時觸發時合併為一次阻擋。輸出後重試同一修改操作，Hook 自動放行。
禁止只寫「已分析」或「無影響」一筆帶過——用戶必須能從輸出中理解推導過程。

**深度規則**（不只看表面引用）：
1. **追溯根因**：從需求或 bug 追到「為什麼要改這個檔案」
2. **穿透呼叫鏈**：A→B→C，改 C 不能只看 B，要看是否波及 A
3. **語意影響**：簽章沒變但回傳值語意變了（如「含稅」→「未稅」），不會觸發編譯錯誤但會造成 bug
4. **狀態與時序**：初始化順序、事件時機、快取策略的改變是否影響下游
5. **邊界條件**：驗證規則改變後，上游極端值是否還能正確處理
6. **呼叫者存在性**：修改函式前，grep 確認呼叫者清單。呼叫者 = 0 → ⛔ 禁止修改，先找真正的執行路徑（executor/orchestrator 層可能有 inline 實作繞過模組）

**場景分流**：閉環 Phase 2/4 中可省略根因（Phase 1 已定義）但仍須輸出影響和決策 | 斷點回退/非閉環修改須完整分析 | Hook 列出引用檔案時逐一確認是否需連動修改並說明推導 | 修改函式的錯誤處理/降級/fallback 邏輯時，必須完整執行第 6 條（呼叫者存在性）

### 9b. 委派前因果鏈閘門（Hook 阻擋式）

修改型 Agent 委派前，PreToolUse Hook 自動攔截（exit 2），要求主 agent 先輸出：

```
📋 [委派前因果鏈分析]
├─ 預期修改檔案：{逐一列出}
├─ 每個檔案的影響：{簡要}
└─ 範圍邊界：{不該被碰的東西}
```

- 唯讀型委派（設計審查、品質檢核、安全檢核、追溯）自動放行
- 閉環 Phase 2 可省略根因（Phase 1 已定義）但仍須列出檔案和影響
- 輸出後重試委派，Hook 自動放行
- **委派後檢查**：subagent 完成後，主 agent 比對實際修改 vs 預期範圍，超出預期 → 補做因果鏈分析

### 10. 合理性審查（所有改動適用）

每次改動後自問：① 一致性 ② 體驗 ③ 比例 ④ 可操作性 ⑤ 整合性。閉環 Phase 1/3 已含；微小任務一句話；連續 3 改動後整合檢查。不合理 → 主動告知。

### 11. 同類掃描（修改指令觸發）

修改對象屬同類之一 → 掃描同類是否有同樣問題，報告後才執行。獨一無二的對象不觸發。步驟：抽出模式 → 列舉同類 → 比對 → 報告 → 確認後執行。

### 12. 事實主張閘門（認知性產出適用 · v5.23.0 新增）

**觸發場景**（任一觸發即執行）：
- 將推論寫入 memory（特別是 `type: project` 的專案事實）
- 向用戶輸出「X 是 Y」類確定語氣結論（含環境事實：IP / DB 位置 / 服務身份 / 部署結構）
- 作為後續行動（SSH / DB 操作 / 部署 / 大範圍修改）的事實前提

**輸出格式**（簡化版，詳細表格見 `.claudedocs/standards/產出物格式.md`「事實主張閘門」section）：

```
🔵 [事實主張] {主張內容}
├─ 🟢 A 級證據（literal / self-declaration）：{檔:行 + 原文} 或「無」
├─ 🟡 B 級證據（間接 / 相關性）：{來源摘要} 或「無」
├─ 🔴 反例檢查：若為真應觀察到 {X}；若為假會觀察到 {Y}；實際觀察 {Z}
├─ 🔄 共用值檢查：value 出現 {N} 次 → {私有 / 共用判讀}
└─ 決策：強（≥ 1 A 級 + 反例通過）/ 中（僅 B 級但反例通過）/ 弱（反例未通過或不足）
```

**處置**：
- **強** → 可寫 memory（frontmatter `evidence_level: strong`）、可給用戶確定答案
- **中** → 標注「推論」，用戶確認後才寫 memory（`evidence_level: medium` + `verified_by_user: true`）
- **弱** → **不可輸出為事實**，必須明說「仍不確定」+ 不寫 memory

此閘門優先級高於 Phase 流程——任何 Phase 的 agent 在觸發場景都必過。歷史教訓見 `.claudedocs/records/問題追蹤.md` #003 / #004 / #005。

### 13. 質疑熔斷協議（Challenge Circuit Breaker · v5.23.0 新增）

用戶以下列**白名單句式**提問時，當下工作**立即熔斷**，強制重審：

- 「你怎麼證明 X」
- 「你確定 X 嗎」
- 「依據是什麼」
- 「X 和 Y 真的有關嗎」

**熔斷觸發後必做**（不可跳過）：

1. **停止推論**：不要急著回答或維護原結論
2. **列出證據**：與被質疑主張相關的全部證據，逐條分 A / B / 反例級（見 Section 12 格式）
3. **誠實承認**：發現是誤判就認，不要 rationalize；發現站得住就清晰說明證據等級
4. **污染清理**：若相關 memory 已寫入且證據等級不足 → 立即更正或加註「[已標記疑慮，待驗證 YYYY-MM-DD]」
5. **learning-log 追加**：標記 `[事實誤判]`（格式見產出物格式.md），failure_type 預設 judgment_failure

**設計精神**：認知驗證的上游機制（Section 12 + Phase 1 Step 0a/0b）若全失效，靠用戶質疑救回。閉環不應依賴此機制——正常情況下 Section 12 就該攔下——但此機制存在本身即是對認知謙卑的承認（見 `.claudedocs/concepts/閉環核心理念.md`「認知驗證」）。

---

{{LANGUAGE_SKILL_SECTION}}

## 完整閉環（Phase 1-5）

> 大型任務觸發。每個 Phase 的閘門是硬性約束，禁止跳過。

### Phase 1：架構師 📐

**Agent**：讀取 `.claudedocs/agents/architect.md`，按其「調用方式」和 `<instructions>` 執行。需求模糊 → 先讀 `requirements-analyst.md`。
**語言指南**：若已部署，讀取 Phase 1 段落。
**常見缺陷預防**：首次使用閉環或不熟悉的領域時，讀取 `.claudedocs/process/五階段閉環流程.md` 末尾清單。
**設計規格持久化**：閘門通過後，將設計規格寫入 `.claude-loop/artifacts/P1-design-spec.md`（後續 Phase 的 Sub-Agent 從此檔案讀取，不經主 agent 轉述）。
**⛔ 閘門**：architect.md 步驟 8 定義的全部項目。全部 ✅ → 進 Phase 1b。

### Phase 1b：設計審查 🔬

**Agent**：讀取 `.claudedocs/agents/design-reviewer.md`，按其「調用方式」啟動獨立子 agent。
**跳過條件**：用戶說「跳過設計審查」→ 直接進 Phase 2（Phase 5 標記「用戶跳過」）。
**⛔ 閘門**：有 DR-x high → 回 Phase 1 修正後重跑 1b（全量重審，最多 3 輪）| arch-risk → 記錄不阻擋 | medium/low → AskUserQuestion 讓用戶決定 | 全無問題 → 進 Phase 2。

### Phase 2：程序設計師 💻

**Agent**：讀取 `.claudedocs/agents/implementer.md`，按其「調用方式」和 `<instructions>` 執行。語言指南若有則讀 Phase 2 段落。
**增量驗證**：每完成一個檔案立即 `{{LINT_COMMAND}}`。
**設計文件同步**：BC-x 預期行為改變 / 函式簽名改變 → 同步設計規格（不改 ID），同時更新 `.claude-loop/artifacts/P1-design-spec.md`。純重命名/風格/helper 不觸發。
**⛔ 閘門**：無語法錯誤 ∧ 設計項都有實作 ∧ code-simplifier 已執行 → 進 Phase 3。

### Phase 3：檢核師 🔍

**品質審查**：讀取 `.claudedocs/agents/code-reviewer.md`，按其「調用方式」啟動獨立子 agent。
**安全審查**：按領域預設（見 Section 6）。跳過條件：無網路 · 無敏感資料 · 無檔案寫入 · 無 unsafe/eval · 無第三方認證全滿足。不跳過時讀取 `security-reviewer.md` 按其「調用方式」啟動。
**R-x 嚴重度**：high→斷點 A | arch-risk→記錄不阻擋 | medium→建議修 | low→合併摘要。`by-design` 不計入。
**⛔ 斷點 A**：有 high → TaskUpdate P2 回 `in_progress`（activeForm: `"修正 R-x high..."`）+ P3 回 `pending` → 修正後重跑 Phase 3（差分審查，安全審查不重跑）。
**學習日誌**（斷點觸發時）：R-x high 根因記錄到 `.claude-loop/learning-log.md`，標題標記 `[code-reviewer]` 或 `[security-reviewer]`（問題→原因→教訓）。

### Phase 4：測試師 🧪

**Agent**：讀取 `.claudedocs/agents/tester.md`，按其「調用方式」和 `<instructions>` 執行。語言指南若有則讀 Phase 4 段落。
**⛔ 斷點 B**：失敗 → 程式碼 bug：TaskUpdate P2 回 `in_progress`（activeForm: `"修正測試失敗..."`）+ P3/P4 回 `pending`（重跑 3+4）| 測試設計問題：P4 原地修正。
**學習日誌**（斷點觸發時）：失敗根因記錄到 `.claude-loop/learning-log.md`，標題標記 `[tester]`（問題→原因→教訓）。

### Phase 5：自證師 ✅

**語言指南**：若已部署，先讀 Phase 5 段落。
**Part AB — 雙向追溯**：讀取 `.claudedocs/agents/verifier.md`，按其「調用方式」啟動獨立子 agent。
**Part C — 整體評估**（主 agent）：
- **⛔ 產出物驗證**：Glob 確認 `.claude-loop/artifacts/` 有 P1-design-spec、P1b（跳過除外）、P3-quality、P3-security（跳過除外）、P5AB。缺漏 → 回退
- **⛔ 委派呼叫驗證**：讀取 `.delegation-log`。缺失但產出物存在 → 以產出物為準
- 收集 Part AB 結果 → 跑 `{{VERIFY_SEQUENCE}}`（多模組必做）→ 全 ✅ / 有 ❌ + 回退建議
- **⛔ 跨 Phase 一致性**：比對 Phase 3 R-x 數量與 Phase 5 反向分析未覆蓋路徑數量。若 R-x ≥ 3 但未覆蓋路徑 = 0 → 判定原因：(a) R-x 皆為品質問題非設計遺漏（合理，記錄理由）；(b) 反向分析可能不夠深入 → 要求 verifier 重做反向分析
**回退規則**：設計-實作不一致→P2（嚴重→P1）| 測試不足→P4 | 檢核未修→P2 | DR-x high 未修→P1 | 產出物缺漏→對應 Phase
**通過後**：
1. 學習日誌 → `.claude-loop/learning-log.md`（格式見產出物格式.md）
2. **升格檢查**（兩層教訓架構）：讀 P5AB 報告的「升格候選」section
   - 有候選 → 對每個候選用 AskUserQuestion 確認 → 用戶選是 → 寫入 `.claudedocs/records/問題追蹤.md`「長期警惕模式」section + Edit learning-log 對應條目加註「→ 已升格 問題追蹤#XXX」/ 用戶選否 → Edit learning-log 對應條目加註「[已評估不升格 - YYYY-MM-DD]」（避免下次重複問）
   - 無候選 → 跳過（learning-log 條目未達 ≥ 3 次門檻）
   - 流程細節見產出物格式.md「長期警惕模式」section
3. commit（learning-log + 問題追蹤更新一併包含）
4. 模組登記（中型以上或用戶要求）

---

## 精簡閉環（中型任務）

> 中型任務觸發。六步流程：設計→設計快審→實作→品質審查→測試驗證→迷你追溯。

**步驟 1 — 設計**：簡要設計規格（目標 | 函式簽名與型別 | BC-x ≥ 1 | EH-x/驗證層級按領域預設 | 分層聲明）。語言指南若有則參考 Phase 1 段落。module-registry.md 存在時先查可複用功能層。
**設計自檢**：① 更簡單的做法？② 影響不相關模組？③ 邊界條件覆蓋？④ 操作流程變複雜？⑤ 解法複雜度成正比？⑥ 架構地基穩？不確定 → AskUserQuestion。
**設計規格持久化**：自檢通過後，將設計規格寫入 `.claude-loop/artifacts/P1-design-spec.md`（後續步驟的 Sub-Agent 從此檔案讀取）。

**步驟 1b — 設計快審（單輪）**：讀取 `design-reviewer.md`，按其「調用方式」啟動子 agent。**只跑 1 輪**：有 high → 主 agent 直接修正設計後進步驟 2；無 high → 直接進步驟 2。

**步驟 2 — 實作**：同 Phase 2 規則。每完成一個檔案立即 `{{LINT_COMMAND}}`。全部完成後調用 Task `code-simplifier`。設計文件同步規則同完整閉環（含同步更新 `P1-design-spec.md`）。

**步驟 3 — 品質審查**：讀取 `code-reviewer.md`，按其「調用方式」啟動子 agent（不含安全審查）。有 R-x high → 追加學習日誌（標記 `[code-reviewer]`）→ 回步驟 2 修正 → 重跑步驟 3（差分審查）。無 high → 進步驟 4。

**步驟 4 — 測試驗證**：
- 確認每個 `[testable]` BC-x/EH-x 有對應測試；`[visual-only]`/`[framework-dependent]` 項在報告中列出驗證方式
- 若已部署語言指南，抽查 Phase 3 審查清單的 high 項目（≤ 3 項快速檢查）
- 用 Bash 執行 `{{VERIFY_SEQUENCE}}`
- 全通過 → 進步驟 4.5；失敗 → **先追加學習日誌（標記 `[tester]`，問題→原因→教訓）** → 回步驟 2 修正

**步驟 4.5 — 迷你追溯**（主 agent 執行，不委派）：
測試通過後、commit 前，主 agent 逐項確認設計-實作-測試的覆蓋鏈。格式見 `.claudedocs/standards/產出物格式.md` 迷你追溯 section。
核心：每個 BC-x/EH-x 附 ✅/❌ + 檔案:行號（實作）+ 測試名稱。R-x medium 用 AskUserQuestion 問用戶決策。
**⛔ 閘門**：正向覆蓋有 ❌ → 禁止 commit | R-x medium → 必須經用戶決策 | 全 ✅ 且 medium 已決策 → commit

**迷你追溯通過後**：
1. 學習日誌 → 追加本次閉環完整條目到 `.claude-loop/learning-log.md`，格式見產出物格式.md
2. **升格檢查**（主 agent 自做，無 verifier sub-agent — 跟完整閉環 Phase 5 的分工差異）：
   - 讀 `.claude-loop/learning-log.md` 全部條目，按「原因」段關鍵字分組計數
   - 比對 `.claudedocs/records/問題追蹤.md`「長期警惕模式」section，找出未升格且 ≥ 3 次的根因
   - 有候選 → 對每個候選用 AskUserQuestion 確認 → 用戶選是 → 寫入問題追蹤.md「長期警惕模式」+ Edit learning-log 對應條目加註「→ 已升格 #XXX」/ 用戶選否 → Edit learning-log 加註「[已評估不升格 - YYYY-MM-DD]」
   - 無候選 → 一行說明「無升格候選（最高頻根因 N 次未達 3 次門檻）」
   - 流程細節見產出物格式.md「長期警惕模式」section
3. commit（learning-log + 問題追蹤更新一併包含）
4. 模組登記（用戶要求時）→ 格式見「模組登記格式」section

---

## 配額管理策略

> 多階段連續開發時，子 agent 委派配額可能在 session 後半段耗盡。以下策略防止被迫全降級。

**分配策略**（session 開始時評估）：
- 若 session 可完成所有階段 → 全部走完整閉環
- 若配額不足以完成所有完整閉環 → 前 N 階段完整，後續精簡
- 精簡降級時明確標記「配額降級」，不影響閘門邏輯

**降級優先順序**（先降低價值的）：
1. P5 Part AB → 主 agent 自審（省最多 token）
2. P3 安全審查 → 跳過（前提：滿足跳過條件）
3. P1b → 降為單輪不回退（精簡模式）
4. P3 品質審查 → ⛔ **不可降級**（壓測實證：ROI 最高的 Phase，100% 攔截率）

---

## 模組登記格式

> 登記條件：中型以上閉環 **或** 用戶要求。格式和更新規則見 `.claudedocs/standards/產出物格式.md` 模組登記 section。

---

## 產出物格式

進入需要產出的 Phase 時，讀取 `.claudedocs/standards/產出物格式.md` 取得完整模板和 ID 編號系統（BC-x/EH-x/R-x/DR-x/IF-x/CR-x）。

---

## 跨 Session 持久化

**觸發條件**：模組數 ≥ 3 且有跨模組依賴 | 預計多 Session | 用戶說「啟用持久化」
**委派產出物**：完整閉環必建 `.claude-loop/artifacts/`，子 agent 審查產出寫入此目錄。
**設計規格持久化**：Phase 1 設計規格必須寫入 `.claude-loop/artifacts/P1-design-spec.md`（Sub-Agent 從此檔案直接讀取，不經主 agent 轉述，避免轉述遺漏）。多模組持久化時另存 `.claude-loop/modules/{name}/design-spec.md`。
詳細規則：[跨 Session 持久化](.claudedocs/process/跨Session持久化.md) | [介面契約與變更管理](.claudedocs/process/介面契約與變更管理.md)

## 跨時間語義記憶（claude-mem · 可選）

若 `mcp__plugin_claude-mem_mcp-search__search` 可用：Phase 1 前 `search` 查歷史決策 | Phase 5 後 `save_memory` 保存架構決策/教訓 | 斷點回退時 `save_memory` 記錄踩坑。保存原則：存「為什麼」和「下次避免什麼」。不可用則跳過。

---

## 工作規範

- **Git**：自證通過後 commit（message 帶自證摘要）| 風險修改前先 commit | 大功能用分支 | 斷點觸發時先 commit 標 `[斷點X]`
- **品質**：跟專案慣例 | `[testable]` BC-x/EH-x 100% 自動化測試覆蓋 | 外部輸入必驗證 | 敏感資料不寫死
- **文檔**：放 `.claudedocs/`、白話文、修訂不新增、專業眼光不討好
- **問題追蹤**：兩層教訓架構（見 `.claudedocs/records/問題追蹤.md`）：
  - 「長期警惕模式」section：跨閉環高頻模式，由 Phase 5 verifier 升格機制（≥ 3 次 + 用戶確認）寫入，architect Phase 1 必讀
  - 「單一 incident 記錄」section：一次性 Bug 或踩坑事件，用戶或 agent 主動記錄

## 參考文檔

> ⛔ 以下文檔**禁止主動讀取**。僅在觸發條件成立時才讀取，違反將浪費 token 預算。

| 文檔 | 觸發條件（僅此條件下讀取） |
|------|--------------------------|
| [產出物格式](.claudedocs/standards/產出物格式.md) | 進入 Phase 1/3/4/5、精簡閉環步驟 4.5、或需要學習日誌/模式分析模板時 |
| [Agent 專家庫](.claudedocs/agents/) | 進入 Phase 1b/3/5 委派子 agent，或 Phase 1/2/4 需要行為指引時 |
| [Agent 使用指南](.claudedocs/standards/Agent使用指南.md) | ⛔ 用戶明確詢問 Agent 配合方式時才讀 |
| [五階段流程](.claudedocs/process/五階段閉環流程.md) | ⛔ CLAUDE.md 已含完整 Phase 描述，僅用戶要求更多細節時才讀 |
| [跨 Session 持久化](.claudedocs/process/跨Session持久化.md) | 模組 ≥ 3 且啟用持久化時 |
| [介面契約與變更管理](.claudedocs/process/介面契約與變更管理.md) | 跨模組 API 依賴時 |

## 📖 補充文檔

`.claudedocs/` 目錄含核心文檔（10 份）、Agent 專家庫（9 份）和語言指南（按偵測結果部署）。閱讀順序見 [.claudedocs/README.md](.claudedocs/README.md)。

<!--
closed-loop v5.23.0

部署說明：
1. 複製 CLAUDE_TEMPLATE.md + .claudedocs/ 到專案根目錄
2. CLAUDE_TEMPLATE.md 重新命名為 CLAUDE.md
3. 替換所有 {{PLACEHOLDER}} 為實際值：
   {{PROJECT_NAME}} {{LANGUAGE}} {{FRAMEWORK}} {{TEST_COMMAND}} {{BUILD_COMMAND}} {{LINT_COMMAND}} {{VERIFY_SEQUENCE}} {{LANGUAGE_SKILL_SECTION}}
4. Claude Code 會自動讀取並遵循閉環調度規則
-->
