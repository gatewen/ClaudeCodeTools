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
| **微小** | 單檔且 < 50 行，或設定調整，或用戶說「快速修改」 | 直接做。Section 2 修改前紀律照跑 |
| **中型** | 1-3 檔且 < 300 行 | 先寫 3-5 行設計（目標 + BC-x ≥ 1，格式見 `.claudedocs/standards/產出物格式.md`）→ 實作 → 測試 → 逐條確認每個 BC-x 有實作、有測試 |
| **大型** | ≥ 3 檔或 ≥ 300 行（通常伴隨多個子系統交互） | 建議 `/dev-design` 產設計規格 → 實作 → 審查（見下）→ 測試 → 逐條追溯 BC-x |
| **需求未定** | 多方案取捨、系統級設計 | 建議 `/dev-prd` 或 `/dev-design`；workflow 不可用時用 AskUserQuestion 多角度探索，自列多方案取捨 |

- 介於兩級之間取上一級。實作中發現規模超出等級，停下來升級，不硬做完
- 大型任務的審查：內建 `/code-review` 或 `/dev-review` 擇一；專案處理外部輸入或網路時用 `/dev-review` 或 `/security-review`，因為 `/code-review` 不含安全視角
- 動手前一句話對頻：說出你收到的需求是什麼、打算怎麼做
- 探索類微小任務（找 typo、未用 import、dead code）：找 1-3 個即停，找不到就說找不到，不補不存在的問題
- 任何階段自問四件事：我的假設是什麼？能不能更簡單？只動了該動的嗎？成功怎麼驗證？
- 禁止：大型任務沒有設計產出就寫碼；沒跑 `{{TEST_COMMAND}}` 與 `{{BUILD_COMMAND}}` 就標完成

## 2. 修改前紀律（核心，always-on）

改既有程式碼之前，先弄清楚這一改的前後關係，把結論寫出來再動手：

- **呼叫者**：grep 窮舉誰呼叫它、誰依賴它的輸出，逐一判斷要不要連動
- **語意**：簽章不變但行為變了嗎？有沒有快取失效、時序變化、狀態機影響？
- **呼叫者 = 0**：先確認它是不是入口點、測試、獨立腳本、或用戶指定要刪的死碼。都不是才停下來找真正的執行路徑（可能有 inline 實作繞過），不可直接改
- **同類掃描**：修改對象若是一組同類之一（N 張圖、N 個 handler），先掃同類有沒有同樣問題，報告後再改
- **輸出**（2-4 行即可）：`⚠️ 改 {檔:函式}｜呼叫者 N 個：{要連動的 / 不需要的理由}｜風險：{…}｜連動清單：{…}`

Hook 是提醒，不是保證：

- `impact-analysis-guard.sh`：只攔 Write / Edit / MultiEdit（用 Bash 改檔不攔）。每輪用戶指令內首次修改既有原始碼檔擋一次，印出以檔名粗搜的相關檔案當起點（不是完整呼叫者清單），要你先輸出上面那 2-4 行再重試。不擋新檔與 md / json / yaml 等非原始碼
- `incremental-lint.sh`：修改後對 js / ts（eslint）、py（ruff）、go（golangci-lint）檔跑 per-file lint 並回饋錯誤。其他語言不覆蓋；型別檢查與建置仍靠你跑 `{{BUILD_COMMAND}}`

Dead code 立場：你的改動造成的 orphan → 刪；改動前就存在的 → 提及不動；用戶明確要求清理才動。

## 3. 事實求證（斷言環境事實前）

觸發：對 IP、服務身份、DB、部署結構這類「X 是 Y」的事實下確定結論時；要把事實寫進 memory 時；要以它作為 SSH、部署、大範圍修改的前提時。

- **字面證據優先**：檔名、docstring、echo / print 字串是作者的自我聲明。只有間接關聯（例如「某 workflow 連到這個 IP」）→ 標「推論」
- **反例檢查**：若主張為真應該看到什麼、為假應該看到什麼、實際看到什麼。三者寫出來再下結論
- **共用值**：該 value 全域出現 ≥ 3 次 → 視為共用資源，不可推論為某方專屬
- **弱證據**：不可輸出為事實、不可寫 memory，明說「仍不確定」

用戶用「你確定嗎 / 依據是什麼 / 你怎麼證明」質疑時：立即停下，逐條列出字面證據、間接證據、反例結果，誤判就認，清理已污染的 memory。

## 4. Push Back 義務（只在這五種情境反對，其餘不多嘴）

1. 有更簡單的替代方案且不影響功能
2. 命中 `.claudedocs/records/問題追蹤.md` 警惕模式段的已知模式
3. 用戶要基於弱證據做後續決策
4. 改動超出任務等級，應該升級
5. 用戶斷言的事實前提無證據，且若為假代價非微小

格式：理由 + 替代方案 + 「若仍要執行請說 OK 用原方案」。用戶說 OK 即照做，不再爭。

## 5. 教訓：讀與寫

- **設計前讀**（中型以上）：掃 `.claudedocs/records/問題追蹤.md` 的「警惕模式」段；專案有 `.claude-loop/learning-log.md` 時一併掃近期根因。設計末尾附一行「教訓查詢：命中 #X / 無」
- **失敗時寫**：同一任務修了 3 次仍不過、或發現自己事實誤判時，追加一行到 `.claude-loop/learning-log.md`（根因 + 下次避免什麼；目錄不存在就建）
- **升格**：同類根因累積 ≥ 3 次，用 AskUserQuestion 提議寫入問題追蹤的警惕模式段

## 6. 子任務與停損

- 子 agent 或 workflow 超時、空輸出：重試一次 → 主 agent 自做並標「降級自審」
- 同一任務修了 3 次仍不過測試或審查：暫停，用 AskUserQuestion 讓用戶決定繼續、降級、或重新設計
- `/dev-design` 內連續 2 輪對抗驗證 needs-attention：縮 scope、拆解、或放棄，不硬做完

## 7. 改方法論本身時的硬規則

修改本檔（CLAUDE.md）或 `.claudedocs/concepts/**`、`.claudedocs/standards/**` 時，必須先經一個沒有本對話 context 的審查者過一輪：用 Agent 工具開獨立子 agent（可指定不同 model），只給它改動的 diff 與原始需求，要它以挑戰式標準審查。不可用「我自己審過了」跳過。依據：問題追蹤 #007，單一來源自審漏看率 50-67%。

日常寫程式與改 `.claudedocs/records/問題追蹤.md` 不觸發此規則。

## 可用 workflow

需 Claude Code v2.1.154+、付費方案、research preview。不可用時走 Section 1 表內的退化做法，Section 2-3 不受影響。

| 指令 | 用途 |
|------|------|
| `/dev-prd` | 需求探索：多角度 → 候選 → 對抗挑戰 → PRD |
| `/dev-design` | 架構設計：多方案 → skeptic → 評審 → 設計規格（含 BC-x） |
| `/dev-review` | 品質 + 安全審查（與內建 `/code-review` 擇一） |
| `/dev-verify` | 可選。設計 ↔ 實作 ↔ 測試逐條追溯；小專案用 coverage 工具即可 |

產出寫入 `.claude-loop/artifacts/`。

## ID 系統

- **BC-x**：可驗證的行為契約，格式「在什麼條件下，系統做什麼，預期結果」。設計、實作、測試三處引用同一編號
- **R-x**：審查發現。high 必修 / medium 用戶決策 / low 摘要
- 其餘（EH / IF / CR）按需 inline，不強制獨立編號。格式見 `.claudedocs/standards/產出物格式.md`

## 工作規範

- **Git**：除非用戶另有指示，測試通過後 commit；風險修改前先 commit；大功能用分支
- **品質**：跟專案慣例；外部輸入必驗證；敏感資料不寫死
- **文檔**：放 `.claudedocs/`，白話文，修訂不新增
- **參考文檔**：僅需要時讀，導覽在 `.claudedocs/README.md`

<!--
closed-loop v8.0.0

部署說明：
1. 複製本檔 + .claudedocs/ 到專案根目錄，本檔改名為 CLAUDE.md
2. 替換 {{PROJECT_NAME}} {{LANGUAGE}} {{FRAMEWORK}} {{TEST_COMMAND}} {{BUILD_COMMAND}}
3. 部署 hooks（deploy-hooks.sh）：impact-analysis-guard + causal-chain-reset + incremental-lint
4. workflow 腳本由 setup.sh 全域部署到 ~/.claude/workflows/

migration-notes
from-version: 7.x
breaking-changes:
  - 模板 344 → ~125 行：五階段與三層架構敘述、Karpathy 對映表、領域偵測表、升格降級機制、KPI、實驗校準段全部移除
  - hook 6 → 3：刪 delegation-gate / prompt-understanding-guard / delegation-tracker / learning-log-checker；impact-analysis-guard 只擋既有原始碼檔
  - .claudedocs 33 → 5 檔：agents / languages / process / examples / 方法論運作指標 / Agent使用指南 不再部署
  - /dev:overview 移除
  - placeholder 6 → 5：LANGUAGE_SKILL_SECTION 移除（語言指南不再部署）
required-actions:
  - 用 /dev:init-claude upgrade 全替換 CLAUDE.md（v8 為整體重寫，不支援智能合併）
  - 刪除專案內 .claudedocs/{agents,languages,process,examples}/ 與 concepts/方法論運作指標.md、standards/Agent使用指南.md（upgrade 會處理）
  - 重跑 deploy-hooks.sh（自動清除舊 hook 與 settings.json 舊項目）
-->
