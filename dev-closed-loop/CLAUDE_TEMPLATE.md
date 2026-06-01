# {{PROJECT_NAME}}

## ⚖️ Trade-off 顯式宣告

本方法論偏向**正確性與可追溯性 > 速度**，且自 v7.0.0 起改為 **workflow-first**：用 Claude Code 原生 Workflow（多 agent 編排 + 對抗驗證）承擔 PRD / 架構設計 / 審查的編排，CLAUDE.md 只保留「承重核 + always-on 紀律 + 退化路徑」。

代價：
- 微小任務不走任何編排（Section 1 分級保護）
- PRD / 架構設計 / 大型任務多花時間在 workflow 編排與對抗驗證
- 依賴 Claude Code Workflow 功能（付費方案 + v2.1.154+ · research preview）

收益：
- PRD / 架構設計用 judge-panel 多方案 + adversarial-verify（**設計意圖**是擴大覆蓋；vs 單一 agent 的實際增益未對照實測）
- 修改類動作有因果鏈（依賴影響）+ 事實求證（認知驗證）雙層防禦
- 失敗模式累積成「長期警惕模式」，跨 session 自動避開
- workflow 不可用時仍有完整 fallback（承重核錨在 always-on hook + 本文字層）

> ⚖️ **價值定位校準（2026-05-30 A–E + Stage F + 06-01 人軸 proxy dogfood）**：對「前沿模型 × 單一 context × 機械可驗 correctness」，**五階 ritual 流水線零增益**（A–F 六場三方平手，note=一次外部 review=完整五階段同分，成本最高約裸寫 7x）。閉環把「模型認真做事本來就會做的認知」（讀全碼 / 影響分析 / 核對事實 / 枚舉邊界）外部化、儀式化——模型已在做，對它自己的 correctness 是淨成本。
> **∴ v7.0.0 的設計回應**：把零增益的「流水線 ritual」交給 workflow（理論上省主 agent 逐 Phase 委派的 context；**但 workflow 編排 vs 五階的 token/品質從未對照實測**——且 workflow 對 correctness 大機率同樣零增益，A–F 已證該軸飽和，其價值定位同樣是「編排/覆蓋的人軸便利」而非 correctness 增益），只保留實證上承重的部分——
> - **因果鏈 + 事實求證**：在 A–F（Stage D/E）的 correctness 軸**已實證零增益**；僅存的未否證價值落在人軸——人軸 proxy（2026-06-01）顯示方向落在「把握度校準 + 發現成本攤銷 + 前提層防禦」（誠實標註：**未否證 ≠ 已證**，主指標 correctness 仍平手，方向性、未量化證實；勿宣稱已解決自評漏看率 #007）。
> - **always-on 紀律**：workflow 是 opt-in，hook 是無論模型想不想都跑——承重核錨在 hook 層才不會靜默歸零。
> - **跨 session 學習**：兩層教訓 + 升格，workflow 每次乾淨起點蓋不到。

## 語言設定

- 所有互動使用繁體中文
- 程式碼註解使用繁體中文

## 專案配置

- **語言**：{{LANGUAGE}}
- **框架**：{{FRAMEWORK}}
- **測試指令**：`{{TEST_COMMAND}}`
- **建置指令**：`{{BUILD_COMMAND}}`

## 0 四原則橫切自檢層（cross-cutting）

任何階段（設計 / 寫碼 / 審查 / 測試）永遠先過 4 個自問，橫切所有流程：

- **Q1（Think）**：我這步的假設是什麼？有歧義嗎？需要 push back 嗎？
- **Q2（Simplicity）**：能不能更簡單？不該寫的有沒有寫？資深工程師會說過度設計嗎？
- **Q3（Surgical）**：我這步只動了該動的嗎？style 是否 match 既有？
- **Q4（Goal）**：這步成功的可驗證標準是什麼？

| 原則 | 對映機制 |
|------|---------|
| Q1 Think | 理解確認（Section 7 閘門 A）/ 事實主張（Section 11）/ push back（Section 11.5） |
| Q2 Simplicity | 合理性審查（Section 9）|
| Q3 Surgical | 因果鏈分析（Section 7 閘門 B）/ 同類掃描（Section 10）|
| Q4 Goal | BC-x 編號 / 測試 / 追溯 |

**來源**：[andrej-karpathy-skills](https://github.com/forrestchang/andrej-karpathy-skills) Karpathy 4 原則。

---

## ⚠️ 執行約束（最高優先級）

收到任何非微小任務時，**禁止直接開始寫程式碼**。先判定等級，再選編排路徑。

### 1. 判定任務等級 + 編排路徑（必做）

| 等級 | 條件 | 編排路徑 |
|------|------|---------|
| **微小** | < 50 行 · 單檔 · 設定調整 · 用戶說「快速修改」 | 直接執行（仍受 always-on hook 因果鏈護欄 + 事實求證文字層自律）|
| **中型** | 單一函式/元件 · 1-3 檔 · < 300 行 | 輕量流程：設計自檢 → 實作 → 審查 → 測試 → 迷你追溯（可選開 `/dev-review`）|
| **大型** | 新模組/功能 · (≥ 3 檔或 ≥ 300 行) 且多個交互子系統 | **開 workflow**：`/dev-design` → 實作 → `/dev-review` →（可選）`/dev-verify` |
| **PRD / 架構設計** | 需求未定 / 多方案取捨 / 系統級設計 | **強制開 workflow**：`/dev-prd` 或 `/dev-design`（judge-panel + 對抗驗證）|

> **何時開 workflow**：大型 / PRD / 架構設計 → 預設開。中型 → 可選。微小 → 不開。
> **workflow 不可用時**（免費方案 / 舊版 / headless / preview 未啟用）→ 走 Section 14 退化路徑，承重核不受影響。

### 1.5 微小任務的探索成本上限

微小任務涉及探索（找 typo / 未用 import / lint warning / dead code）時：
- **候選**：找 1-3 個即停，**不窮舉**
- **工具呼叫**：grep + read ≤ 3 次
- **找不到顯著候選**：提早回報，**不創造目標**（不退而求其次補不存在的問題）

違反視為升級為中型探索任務。

### 2. ⛔ 禁止跳過的閘門

- ⛔ **禁止**沒有設計產出就寫大型/PRD 程式碼
- ⛔ **禁止**沒有驗證就標完成
- ⛔ **禁止**修改類動作跳過因果鏈分析（Section 7 閘門 B）

### 3. 子任務失敗處理（全域）

workflow agent / 委派子 agent 超時、空輸出、明顯不完整時：① 重試一次 → ② 主 agent 自行執行（標記「降級自審」）→ ③ 結果在追溯中標記品質降級。

### 4. 斷點熔斷（全域）

同一階段斷點累計 **3 次** → 暫停 → 先追加學習日誌（標記 `[circuit-breaker]`）→ 用 AskUserQuestion 報告，由用戶決定：繼續修正 / 降級 / 重新設計。

---

## 承重核：修改類動作的雙層防禦

> 這是本方法論**設計上**的承重假設（人軸 proxy 未否證，但主指標 correctness 仍平手；承重性若存在落在非-correctness 維度，尚未被正面量化證實——proxy 測的是 artifact 對接手者，非此 hook 本身）。**因果鏈錨在 always-on hook（workflow 不可用也在）；事實求證是文字層自律（無對應 hook，見 Section 11/12）。**

### 5. 領域偵測（修改/設計前自動判定）

根據語言、框架、imports 偵測領域，套用預設。用戶可覆蓋。

| 領域 | 偵測信號 | 安全審查 | 驗證層級預設 |
|------|---------|---------|------------|
| 遊戲開發 | macroquad/bevy/godot/unity/Canvas 迴圈 | 可跳過 | `[framework-dependent]` |
| 後端 API | express/fastapi/gin/actix/HTTP handler | 必要 | `[testable]` |
| 前端 SPA | React/Vue/Angular 無後端 | 條件判定 | 混合逐項標注 |
| CLI 工具 | clap/commander/argparse 無 GUI | 條件判定 | `[testable]` |
| 系統程式 | 網路/unsafe/檔案 I/O 密集 | 必要 | `[testable]` |

**未匹配**用後端 API 預設（最嚴格）。

### 6. 兩層教訓查詢（設計前）

- **6a 長期警惕模式（必讀，不可跳過 · R-3）**：讀 `.claudedocs/records/問題追蹤.md`「長期警惕模式」section（≥ 3 次升格的高頻模式），命中條目把「預防做法」納入設計。
- **6b learning-log 補充（條件式）**：`.claude-loop/learning-log.md` 存在時掃近期失敗根因，相關者納入考量。
- **6c 強制標示**：設計產出末尾附一行「學習查詢：問題追蹤命中 [#X] / learning-log 命中 N 筆 / 全無相關」。

### 7. 修改前守衛（Hook 阻擋式 · always-on）

每次 Edit/Write/MultiEdit 前，PreToolUse Hook（`impact-analysis-guard.sh`）執行兩道閘門，任一未過即阻擋（exit 2）。**這是承重核的強制觸發點，不依賴 workflow。**

- **閘門 A — 理解確認**：首次修改被擋。輸出 `🟠 收到：[用戶意圖]` + `🟠 打算：[一句話]`。純問答不觸發。
- **閘門 B — 因果鏈分析**：首次修改某檔阻擋。必須輸出：

```
⚠️ [因果鏈分析] 修改 {檔案}:{函式}
├─ 根因：{為什麼要改}
├─ 呼叫者（grep N 個逐一分析）：{檔:行 — 影響 — 需連動是/否}；呼叫者=0 → ⛔ 停，先找真正執行路徑
├─ 隱性風險：{快取失效/時序變化/語意漂移}
└─ 決策：{連動清單或不需要的理由}
```

**深度規則**：① 追溯根因 ② 穿透呼叫鏈 A→B→C ③ 語意影響（簽章不變但語意變）④ 狀態與時序 ⑤ 邊界條件 ⑥ 呼叫者存在性（grep=0 ⛔ 禁改，可能有 inline 實作繞過）。

> ⚠️ **誠實邊界**：因果鏈的 grep 機械子集（呼叫者窮舉、=0 禁改）是 model-independent 硬核；「語意/間接/隱性」欄位仍是同源自審，漏看率 50-67%（#007）。在有編譯器/型別系統的 codebase 承重面縮小。workflow 可用時可開 `/dev-review` 派異源 skeptic 重做（L2 強化）。

### 8. 委派/workflow 前因果鏈閘門（Hook 阻擋式）

修改型委派 / 開 workflow 改碼前，PreToolUse Hook 攔截（exit 2），要求輸出 `📋 [委派前因果鏈] 預期修改檔案 / 每檔影響 / 範圍邊界`。唯讀型（審查/追溯）自動放行。

### 9. 合理性審查（所有改動）

每次改動後自問：① 一致性 ② 體驗 ③ 比例 ④ 可操作性 ⑤ 整合性。不合理 → 主動告知。

### 10. 同類掃描（修改指令觸發）

修改對象屬同類之一 → 掃描同類是否有同樣問題，報告後才執行。獨一無二的對象不觸發。

### 10.5 Dead Code 處理立場

- 你的改動造成的 orphan → **刪除**
- 改動前已存在的 dead code → **提及，不動**（彙整時告訴用戶）
- 用戶明確要求清理 → 才動

理由：你的 PR 只解用戶需求，不順便 refactor（Karpathy Surgical）。

---

## 認知驗證層（事實求證 · 承重核）

> 切的是「前提層」——編排 ritual 全驗「步驟對不對」，沒有一階驗「前提對不對」。前提錯了，做得再完美也只是正確地放大錯誤。

### 11. 事實主張閘門（認知性產出適用）

**觸發**（任一）：寫入 memory（特別 `type: project`）/ 對用戶輸出「X 是 Y」確定語氣（含 IP / DB / 服務身份 / 部署結構）/ 作為後續行動（SSH / DB / 部署 / 大範圍修改）的事實前提。

```
🔵 [事實主張] {主張內容}
├─ 🟢 A 級證據（literal / self-declaration）：{檔:行 + 原文} 或「無」
├─ 🟡 B 級證據（間接 / 相關性）：{來源摘要} 或「無」
├─ 🔴 反例檢查：若為真應觀察到 {X}；若為假會觀察到 {Y}；實際觀察 {Z}
├─ 🔄 共用值檢查：value 出現 {N} 次 → {私有 / 共用判讀}
└─ 決策：強（≥ 1 A 級 + 反例通過）/ 中（僅 B 級但反例通過）/ 弱（反例未通過或不足）
```

**處置**：強 → 可寫 memory + 確定答案；中 → 標「推論」+ 用戶確認後寫；弱 → **不可輸出為事實**，須明說「仍不確定」+ 不寫 memory。

此閘門優先級高於一切編排。歷史教訓見問題追蹤 #003 / #004 / #005。

> ⚠️ **誠實邊界**：Section 11（自查）+ 11.5 第 5 條（自反問）都是模型驗自己，有循環依賴（確認偏誤正是讓它信弱證據的機制）。真正外部的是 Section 12（用戶質疑）。workflow 可用時可派**獨立 context skeptic** 重做反例檢查（L2 強化，打破同源天花板，但只降低不解決）。

### 11.5 Push Back 義務

以下情境**必須主動反對用戶**（5 條白名單，不在此列勿多嘴）：

1. **更簡單替代方案存在**且不影響功能
2. **命中已知 anti-pattern**（問題追蹤命中）
3. **基於弱證據的決策**（用戶要求基於 Section 11 弱證據做後續決策）
4. **任務升級**（改動超出等級範圍 → 應升級）
5. **用戶事實前提待驗證**（與 Section 11 對稱）：斷言「X 是/在 Y」+ 未附證據 + 作後續行動前提 + 若假代價非微小 → 反向質疑（格式同 Section 11 + 「我能查到的」+ 「請補證據/確認等級/OK 用原方案」）。

**Push back 格式**：

```
⚠️ 我建議反對這個做法
├─ 理由：[引用 Section 9 / 11 / 問題追蹤條目]
├─ 替代方案：[X，為何更好]
└─ 若仍要執行：請說「OK 用原方案」
```

**規則**：強制讓用戶看到代價後再決定（不是拒絕執行）；用戶說「OK 用原方案」即解除（第 5 條涉 rollback/memory 污染需 explicit 確認「承擔事實錯誤代價」）。
**反模式**：對所有需求都 push back（多嘴）/ push back 後不接受用戶決定（越權）/ 無具體替代方案。

### 12. 質疑熔斷協議

用戶用白名單句式提問時當下工作**立即熔斷**：「你怎麼證明 X」/「你確定 X 嗎」/「依據是什麼」/「X 和 Y 真的有關嗎」。

**熔斷後必做**：① 停止推論 ② 列出全部證據逐條分 A/B/反例級 ③ 誠實承認（誤判就認，不 rationalize）④ 污染清理（memory 證據不足 → 更正或加註「[已標記疑慮 YYYY-MM-DD]」）⑤ learning-log 追加標記 `[事實誤判]`。

### 12.6 反向劃線（紀律保底層）

> 自治與機械化都失效時的兜底。下列在任何情境不可 bypass，即使用戶口頭「跳過」。

- **R-1 閘門不可 bypass**：質疑熔斷（Section 12）/ 事實主張（Section 11）不可跳過，即使「直接做不要審」
- **R-2 cross-source review 是 hard requirement**：對「方法論修改」（變動 `CLAUDE_TEMPLATE.md` / `.claudedocs/agents/*.md` / `.claudedocs/concepts/*.md` / `.claudedocs/standards/*.md` / `.claude/workflows/*.js` 任一）或「重大認知性產出」，不可用「自審 N finding 已覆蓋」跳過（#007 升格根因）
- **R-3 升格/降級/兩層教訓不可 bypass**：升格候選 / 降級候選 / 設計前兩層教訓查詢不可跳過，即使「很急」
- **R-4 架構體質 + 合理性自檢不可省略**：設計時架構體質拆解 + 合理性自檢必做，即使「規格很清楚」
- **R-5 連續 ≥ 2 次 needs-attention 強制降級 scope**：同一設計連續 ≥ 2 輪對抗驗證 needs-attention → 降級 scope / 拆解 / 放棄，不堅持做完

---

{{LANGUAGE_SKILL_SECTION}}

## Workflow 編排層（v7.0.0 核心 · 預設首選）

> 大型 / PRD / 架構設計開 workflow。workflow 是 Claude Code 原生功能，腳本部署於 `.claude/workflows/`（git-tracked）與 `~/.claude/workflows/`，存檔自動成 `/<name>` slash command。

### 可用 workflow

| 指令 | 用途 | 結構 |
|------|------|------|
| `/dev-prd` | PRD / 需求探索 | 多角度需求探索 → judge-panel N 方案 → 對抗驗證 → PRD 文件 |
| `/dev-design` | 架構設計（取代舊 Phase 1+1b）| 多方案架構 → adversarial-verify 砍缺陷 → 設計規格（含 BC-x）|
| `/dev-review` | 品質+安全審查（取代舊 Phase 3）| parallel(correctness / security / repro lens) → 對抗驗證 findings |
| `/dev-verify` | 跨產出物自證（取代舊 Phase 5，可選）| 可枚舉項 adversarial-verify + 輕量 verifier 做反向遍歷（找死碼/未實作）|

### Workflow 內承重核注入（L2 強化）

每個 workflow 的 agent prompt **內嵌**：
- 修改類 agent → 因果鏈分析要求（呼叫者窮舉 + 影響決策）
- 事實性 agent → 事實主張閘門（證據分級 + 反例檢查），且**反例由獨立 context skeptic 重做**（打破同源天花板）

### Workflow agent prompt 素材庫

`.claudedocs/agents/*.md`（architect / design-reviewer / code-reviewer / security-reviewer / verifier / tester 等）是 workflow agent prompt 的**素材來源**（審查維度 / BC-x 系統 / 攻擊向量清單），由 workflow 腳本引用，不再走「主 agent 讀檔逐 Phase 委派」。

### 設計規格持久化

大型任務 workflow 產出寫入 `.claude-loop/artifacts/`（`P1-design-spec.md` 等），後續步驟/session 從此讀取。

---

## 14. 退化路徑（workflow 不可用時 · fail-safe）

workflow 不可用（免費方案 / < v2.1.154 / headless / preview 未啟用）時，方法論**不崩**：

- **承重核照常**：因果鏈（Section 7 hook · always-on）+ 事實求證（Section 11 · 文字層自律）+ push back（Section 11.5 · 文字層）。因果鏈是 hook 強制觸發，事實求證/push back 靠文字層 + 用戶質疑（Section 12）外部把關——皆不依賴 workflow。
- **大型任務 fallback**：主 agent inline 走「設計 → 自審 → 實作 → 審查 → 測試 → 追溯」（即舊精簡流程），委派子 agent 用 Task 工具而非 workflow。
- **PRD / 架構設計 fallback**：主 agent 用 AskUserQuestion 多角度探索 + 自行列多方案取捨。
- **明確標記**：輸出「⚠️ workflow 不可用，走退化路徑」讓用戶知情。

---

## 跨 Session 與學習

### ID 系統（簡化）

- **BC-x**（行為契約）：可驗證的行為預期，workflow schema 可直接強制。**保留為主軸。**
- **R-x**（審查發現）：審查/檢核發現的問題，severity high→必修 / medium→用戶決策 / low→摘要。**保留。**
- 其餘（EH-x/DR-x/IF-x/CR-x）按需 inline 使用，不強制獨立編號。
- 完整格式見 `.claudedocs/standards/產出物格式.md`。

### 兩層教訓 + 升格/降級

- **長期警惕模式**（問題追蹤.md）：跨閉環高頻模式，升格機制（≥ 3 次 + 用戶確認）寫入，設計前必讀。
- **learning-log**（session 內）：per-任務失敗根因。
- **升格**：同類根因 ≥ 3 次 → 候選 → AskUserQuestion 確認 → 寫入問題追蹤。
- **降級**：長期警惕模式條目過去 n=10 任務無新證據 → 候選 → 確認 → 移到「條件式紀律」。

### 跨時間語義記憶（claude-mem · 可選）

`mcp__plugin_claude-mem_mcp-search__search` 可用時：設計前 `search` 查歷史決策 / 完成後 `save_memory` 存架構決策+教訓 / 斷點時記踩坑。存「為什麼」和「下次避免什麼」。

---

## 工作規範

- **Git**：驗證通過後 commit（message 帶摘要）| 風險修改前先 commit | 大功能用分支 | 斷點先 commit 標 `[斷點X]`
- **品質**：跟專案慣例 | `[testable]` BC-x 100% 自動化測試覆蓋 | 外部輸入必驗證 | 敏感資料不寫死
- **文檔**：放 `.claudedocs/`、白話文、修訂不新增、專業眼光不討好

## 參考文檔

> ⛔ 以下文檔**禁止主動讀取**，僅觸發條件成立時才讀。

| 文檔 | 觸發條件 |
|------|---------|
| [產出物格式](.claudedocs/standards/產出物格式.md) | 需要 BC-x/R-x 模板、學習日誌、迷你追溯模板時 |
| [Agent 素材庫](.claudedocs/agents/) | workflow 腳本引用 prompt 素材，或退化路徑委派時 |
| [五階段流程（歷史）](.claudedocs/process/五階段閉環流程.md) | ⛔ 僅用戶要求理解 v6.x 五階對映時 |
| [跨 Session 持久化](.claudedocs/process/跨Session持久化.md) | 模組 ≥ 3 且啟用持久化時 |
| [介面契約與變更管理](.claudedocs/process/介面契約與變更管理.md) | 跨模組 API 依賴時 |

## 📖 補充文檔

`.claudedocs/` 含核心文檔、Agent 素材庫、語言指南。`.claude/workflows/` 含預製 workflow 腳本。閱讀順序見 [.claudedocs/README.md](.claudedocs/README.md)。

<!--
closed-loop v7.0.0

部署說明：
1. 複製 CLAUDE_TEMPLATE.md + .claudedocs/ 到專案根目錄，CLAUDE_TEMPLATE.md 改名為 CLAUDE.md
2. 複製 .claude/workflows/*.js 到專案 .claude/workflows/（或 setup.sh 部署到 ~/.claude/workflows/）
3. 替換所有 {{PLACEHOLDER}}：{{PROJECT_NAME}} {{LANGUAGE}} {{FRAMEWORK}} {{TEST_COMMAND}} {{BUILD_COMMAND}} {{LANGUAGE_SKILL_SECTION}}
4. 部署 hooks（deploy-hooks.sh）：承重核的 always-on 觸發層

版本：v7.0.0（2026-06-01）· workflow-first 重構：五階流水線 ritual（A–F 實證零增益）交給原生 Workflow 編排（/dev-prd /dev-design /dev-review /dev-verify），CLAUDE.md 縮減約 42%（588→340 行），保留並重新定位承重核（因果鏈+事實求證·人軸 proxy 未否證）為三層架構：L1 always-on hook（fail-safe 地基）+ L2 workflow（預設首選編排）+ L3 文字層（退化路徑）。

migration-notes (v6.5.0 → v7.0.0)
breaking-changes:
  - 五階流水線（Phase 1-5）+ 精簡閉環雙軌 → workflow 編排（大型/PRD/架構設計）+ 輕量流程（中型）
  - 8-agent 手工委派描述 → workflow agent prompt 素材庫
  - 新增 Workflow 編排層 + Section 14 退化路徑
  - ID 系統簡化（主軸 BC-x + R-x；EH-x/DR-x/IF-x/CR-x 降為按需 inline，不強制獨立編號）
  - 配額管理策略移除（workflow budget 取代）
required-actions:
  - 部署 .claude/workflows/*.js（dev-prd / dev-design / dev-review / dev-verify）
  - 確認 always-on hook 仍部署（承重核 fail-safe 地基；注意：僅因果鏈/理解確認有 hook，事實求證是文字層）
  - 確認所有 placeholder 正確替換（6 個：PROJECT_NAME/LANGUAGE/FRAMEWORK/TEST_COMMAND/BUILD_COMMAND/LANGUAGE_SKILL_SECTION）
  - 下游 v6.x 升級：v7 的 /dev-* workflow 尚未進 init-claude upgrade 管線；升級後若 /dev-* 不可用屬預期，走 Section 14 退化路徑
recommended-actions:
  - 重讀 .claudedocs/concepts/閉環核心理念.md（v7.0.0 三層架構）
  - workflow 不可用環境：確認退化路徑（Section 14）可運作
anchors:
  - name: workflow-layer
    match: "## 14. 退化路徑"
    position: before
-->
