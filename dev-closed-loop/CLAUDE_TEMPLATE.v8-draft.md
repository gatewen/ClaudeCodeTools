# {{PROJECT_NAME}}

## 語言設定

- 所有互動使用繁體中文
- 程式碼註解使用繁體中文

## 專案配置

- **語言**：{{LANGUAGE}}
- **框架**：{{FRAMEWORK}}
- **測試指令**：`{{TEST_COMMAND}}`
- **建置指令**：`{{BUILD_COMMAND}}`

## 1. 任務分級（先判等級，再動手）

| 等級 | 條件 | 做法 |
|------|------|------|
| **微小** | < 50 行 · 單檔 · 設定調整 · 用戶說「快速修改」 | 直接做。Section 2 修改前紀律照跑 |
| **中型** | 單一函式/元件 · 1-3 檔 · < 300 行 | 先寫 3-5 行設計（目標 + BC-x ≥ 1）→ 實作 → 測試 → 逐條確認每個 BC-x 有實作、有測試 |
| **大型** | ≥ 3 檔或 ≥ 300 行，且多個子系統交互 | 建議 `/dev-design` 產設計規格 → 實作 → `/code-review`（或 `/dev-review`）→ 測試 → 逐條追溯 BC-x |
| **需求未定** | 多方案取捨 · 系統級設計 | 建議 `/dev-prd` 或 `/dev-design`；workflow 不可用時用 AskUserQuestion 多角度探索，自列多方案取捨 |

- 動手前一句話對頻：收到什麼、打算怎麼做
- 任何階段自問四件事：我的假設是什麼？能不能更簡單？只動了該動的嗎？成功怎麼驗證？
- 實作中發現規模超出等級 → 停下來升級，不硬做完
- 禁止：大型任務沒有設計產出就寫碼；沒跑測試與建置就標完成

## 2. 修改前紀律（always-on · 承重核）

改既有程式碼之前，先弄清楚這一改的前後關係，把結論寫出來再動手：

- **呼叫者**：grep 窮舉誰呼叫它、誰依賴它的輸出，逐一判斷要不要連動
- **語意**：簽章不變但行為變了嗎？有沒有快取失效、時序變化、狀態機影響？
- **呼叫者 = 0** → 停下來找真正的執行路徑（可能有 inline 實作繞過），不可直接改
- **同類掃描**：修改對象若是一組同類之一（N 張圖、N 個 handler），先掃同類有沒有同樣問題，報告後再改
- **輸出**（2-4 行即可）：`⚠️ 改 {檔:函式}｜呼叫者 N 個：{要連動的 / 不需要的理由}｜風險：{…}｜連動清單：{…}`

Hook `impact-analysis-guard.sh` 會在首次修改既有原始碼檔時擋一次並印出引用者清單。它保證的是「暫停 + 分析可見」，分析的正確性仍靠你。
Hook `incremental-lint.sh` 在每次修改後對該檔跑 lint，有錯即擋，先修再繼續。

Dead code 立場：你的改動造成的 orphan → 刪；改動前就存在的 → 提及不動；用戶明確要求清理才動。

## 3. 事實求證（斷言環境事實前）

對「X 是 Y」類事實（IP / 服務身份 / DB / 部署結構）、要寫進 memory、或作為 SSH / 部署 / 大範圍修改的前提時：

- 先找字面證據（檔名、docstring、echo/print 字串）。只有間接關聯 → 標「推論」
- 該 value 全域出現 ≥ 3 次 → 視為共用資源，不可推論為某方專屬
- 弱證據不可輸出為事實、不可寫 memory，明說「仍不確定」

用戶用「你確定嗎 / 依據是什麼 / 你怎麼證明」質疑時：立即停下，逐條列出證據等級，誤判就認，清理已污染的 memory。

## 4. Push Back 義務（只在這五種情境反對，其餘不多嘴）

1. 有更簡單的替代方案且不影響功能
2. 命中 `.claudedocs/records/問題追蹤.md` 的已知模式
3. 用戶要基於弱證據做後續決策
4. 改動超出任務等級，應該升級
5. 用戶斷言的事實前提無證據，且若為假代價非微小

格式：理由 + 替代方案 + 「若仍要執行請說 OK 用原方案」。用戶說 OK 即照做，不再爭。

## 5. 設計前查教訓

中型以上任務設計前，掃 `.claudedocs/records/問題追蹤.md`，命中的把預防做法納入設計。專案有 `.claude-loop/learning-log.md` 時一併掃近期失敗根因。

## 6. 子任務與斷點

- 子 agent / workflow 超時或空輸出：重試一次 → 主 agent 自做並標「降級自審」
- 同一階段回退累計 3 次：暫停，用 AskUserQuestion 讓用戶決定繼續 / 降級 / 重新設計
- 同一設計連續 2 輪對抗驗證 needs-attention：縮 scope / 拆解 / 放棄，不硬做完

## 7. 方法論修改的硬規則

修改 `CLAUDE_TEMPLATE.md`、`.claudedocs/**`、workflow 腳本，或產出「方法論評估、計畫前提、自評」類認知性內容時，必須經另一個模型或人類 cross-source review，不可用「自審已覆蓋」跳過（問題追蹤 #007：單一來源自審漏看率 50-67%）。

{{LANGUAGE_SKILL_SECTION}}

## 可用 workflow

需 Claude Code v2.1.154+ · 付費方案 · research preview。不可用時走 Section 1 表內的退化做法，Section 2-3 不受影響。

| 指令 | 用途 |
|------|------|
| `/dev-prd` | 需求探索：多角度 → 候選 → 對抗挑戰 → PRD |
| `/dev-design` | 架構設計：多方案 → skeptic → 評審 → 設計規格（含 BC-x） |
| `/dev-review` | 品質 + 安全審查（與內建 `/code-review` 擇一） |
| `/dev-verify` | 可選。設計 ↔ 實作 ↔ 測試逐條追溯；小專案用 coverage 工具即可 |

產出寫入 `.claude-loop/artifacts/`。

## ID 系統

- **BC-x**：可驗證的行為契約。設計、實作、測試三處引用同一編號
- **R-x**：審查發現。high 必修 / medium 用戶決策 / low 摘要
- 其餘（EH / IF / CR）按需 inline，不強制獨立編號

## 工作規範

- **Git**：測試通過後 commit；風險修改前先 commit；大功能用分支
- **品質**：跟專案慣例；外部輸入必驗證；敏感資料不寫死
- **文檔**：放 `.claudedocs/`，白話文，修訂不新增
- **參考文檔**：僅需要時讀，導覽在 `.claudedocs/README.md`

<!--
closed-loop v8.0.0-draft

部署說明：
1. 複製本檔 + .claudedocs/ 到專案根目錄，本檔改名為 CLAUDE.md
2. 替換 {{PROJECT_NAME}} {{LANGUAGE}} {{FRAMEWORK}} {{TEST_COMMAND}} {{BUILD_COMMAND}} {{LANGUAGE_SKILL_SECTION}}
3. 部署 hooks（deploy-hooks.sh）：impact-analysis-guard + incremental-lint
4. workflow 腳本由 setup.sh 全域部署到 ~/.claude/workflows/
-->
