# v8.0.0 瘦身：評估結論與砍法

> 決策日期：2026-09-03
> 決策者：用戶授權「全程由你決定」，執行者 Claude Fable 5.1
> 上游：`.claude-loop/methodology-adversarial-review.md`（2026-05-30 對抗評估）、`baseline-failure-taxonomy.md`（三閘全過清單為空）、A–F 六場 dogfood（correctness 零增益）
> 性質：breaking。模板 344 → ~110 行，部署包 33 → 5 檔，hook 6 → 3 支，`/dev:overview` 移除

---

## 1. 問題

v7.0.0 已經承認五階段流水線對程式正確性零增益，成本最高 7 倍，但回應方式是「把儀式搬進 workflow」，沒有真的刪東西。每個部署專案仍然帶著：

| 部署物 | v7.1.2 | 每 session 成本 |
|--------|--------|----------------|
| CLAUDE_TEMPLATE.md | 344 行 / 25 KB | 每輪載入 context |
| .claudedocs | 33 檔 / ~8000 行 | 佔專案目錄，多數無人讀 |
| hooks | 6 支 | 每次 Edit 多一回合 |
| agent prompt 素材庫 | 8 檔 / 2037 行 | 零引用（grep 4 個 workflow 腳本對 `agents/` 命中 0） |
| 語言指南 | 6 檔 / 2185 行 | 內容為模型訓練資料已有的常識 |

## 2. 評估方法

以「這一代前沿模型作為執行者」的視角，對每個機制問兩件事：沒有它會不會做出更差結果；每次執行付出多少 context 與回合。並用事實查證校正描述與實作的落差（例如 hook 宣稱「素材庫由 workflow 引用」實為零引用；hook 把引用者清單印在 stdout 而 exit 2 時模型只看 stderr）。

完整評估對話記錄在 maintainer 的 daily log `2026-09-03.md`。

## 3. 結論：必要 / 不必要

**保留**
- 任務分級（何時花編排成本）
- 修改前紀律：呼叫者窮舉、語意漂移、呼叫者為 0 停手、同類掃描、dead code 立場。hook 保留但收窄
- 事實求證三條原則 + 質疑熔斷
- push back 五條白名單（價值是限制多嘴，不是補強不足）
- 設計前掃問題追蹤
- R-2 跨來源審查（唯一有量化證據）、R-5 連續 needs-attention 縮 scope
- 增量 lint hook（唯一提供地面真值的 hook）
- workflow 四支（可選；dev-verify 改單 agent 追溯）
- handoff、setup.sh、tests

**砍**
- Karpathy 四原則對映表 → 一行自問
- 領域偵測表、微小任務探索上限、R-1 / R-3 / R-4
- 升格降級機制（n=10 / m=5 / 2n=20；四個月升格 2 條、降格 0 條）
- KPI 運作指標（從未客觀量測）
- 模板內給人看的實驗校準與誠實邊界段（每輪載入卻在告訴模型「這些規則零增益」）
- delegation-gate、prompt-understanding-guard（harness 已要求動手前說明意圖）、delegation-tracker（v6 詞彙、寫沒人讀的 log）、learning-log-checker（每次 commit 叫人 amend）
- agents / languages / process / examples 部署
- `/dev:overview`（會渲染六 hook 五階段的舊內容，更新 46 KB HTML 成本高於個人工具的價值）
- `{{LANGUAGE_SKILL_SECTION}}` placeholder

## 4. 因果鏈：降級不是砍

用戶立場：改碼前必須先清楚前後關係才不會改壞。同意。砍的是 hook 的三個實作問題：擋所有檔案（含 md / json / 新檔）、grep 用檔名主幹搜太粗、擋一次後無條件放行卻宣稱機械保證。

保留的價值是「分析在落地前對人可見」與「長 session 後段的強制暫停」，後者 A–F 沒測過，是未否證。

收窄後：只擋既有原始碼檔首次修改、marker 依 session 隔離、每輪由 `causal-chain-reset.sh` 重置、訊息全走 stderr（模型才看得到）、要求輸出縮為 2-4 行。

## 5. 順手修掉的問題

- hook 與 deploy-hooks 不再依賴 python（jq → sed 後援；deploy 加 jq 第三段）。Windows 上 python3 常為 Store 空殼，v7 在該環境部署不起來。
- 舊專案升級時 deploy-hooks 自動清除已刪 hook 的腳本與 settings.json 項目。
- init-claude 的 `grep -oP` 在 macOS 不可用，改 `grep -o` + sed。
- init-claude 的 migration awk parser 比對 `v7.x` 對 `7.1.2` 永遠不匹配，v8 改為明確的版本判斷。

## 6. 誠實邊界

- 本次評估與砍法是單一模型單一 session 的判斷。R-2 要求跨來源審查：v8 模板草稿由同模型的獨立 context 子 agent 審過一輪（不是跨 LLM）。建議 merge 前再用另一個模型過一次。
- workflow 對 correctness 的增益同樣未實測。保留是因為運行時成本為零、且「多方案 + 新鮮 context 批評」是單一 context 做不到的事，不是因為有證據。
- `dev-review` 與 Claude Code 內建 `/code-review` 疑似重疊，未實跑比較。模板寫「擇一」。

## 7. 還原路徑

所有砍掉的內容在 git 歷史（v7.1.2，commit `ab04a9d`）與 `design/history-v7/` 都找得到。`/dev:overview` 整包可從 `git show ab04a9d:dev-closed-loop/command-refs/overview/` 取回。
