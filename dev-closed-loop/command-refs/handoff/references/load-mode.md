# load 模式詳細流程

## 觸發

`/dev:handoff load`、`/dev:handoff in`、`/dev:handoff 讀`、`/dev:handoff 載`。

## 流程

### Step 0：路徑判定（**必做，不可跳過**）

依 `references/path-resolution.md` 判定 `handoff_dir`，並向 user 回報實際路徑。

不寫死任何專案路徑。後續所有 Read 操作都基於 `handoff_dir`。

若 cwd 是 home 或 root → 中止，照 path-resolution.md 的 edge case 處理。

### Step 1：並行讀取三項來源

**單一 message 多個 Read tool call**（速度優先）：

1. `<handoff_dir>/handoff.md`
2. `<handoff_dir>/logs/YYYY-MM-DD.md`（今日；若不存在，改讀最近一篇 — 用 `ls -t <handoff_dir>/logs/*.md | head -1`）
3. 當前 cwd 對應的 `MEMORY.md`（檢查是否有新增；路徑由系統 auto-memory 決定，無需手動拼）

讀取後**不要逐字回傳給使用者**，只做摘要。

> handoff 一律以磁碟（git / MEMORY / handoff.md / TaskList）為準、不依賴對話 context；故即使本 session 經歷過 /compact，load 重建仍從耐久層取材。

### Step 2：時間落差計算

從 handoff.md 的「最後更新」時戳對比系統當前時間：

| 落差 | 描述方式 |
|------|---------|
| < 1 小時 | 「剛剛交接過（X 分鐘前）」 |
| 1–8 小時 | 「X 小時前交接」 |
| 8–24 小時 | 「今天稍早（HH:MM）交接」 |
| 1–7 天 | 「N 天前（YYYY-MM-DD）交接」 |
| > 7 天 | ⚠️「上次是 YYYY-MM-DD，已過 N 天，內容可能過時」 |

### Step 3：對話式摘要呈現

使用 `references/templates.md` 的 **load 摘要模板**。

要素優先順序：
1. 路徑模式（Step 0 結果）+ 上次交接時間 + 落差
2. Session 焦點（一句話）
3. **進行中工作**（高亮，含下一步）
4. 上次已完成的重點（壓縮成 1–2 句）
5. **起手式建議**（明確可執行）
6. ⚠️ Git 未 commit 變更（若 handoff.md 有記錄）

### Step 4：起手式建議 + 確認

最後一段必須是**可以一句話回答的問題**，例如：

> 「依交接內容，下一步是先驗證 Y 是否可行。要不要直接從這裡接手？」

讓使用者用「好」或「不，先做 X」就能決定方向。

### Step 5：相關 Memory 篩選

只挑與當前 handoff 焦點相關的 Memory 提及（避免 dump 全部）：
- handoff 提到的檔案、技術、決策 → 對應的 memory 短引一句
- 通用偏好（如「全程繁體中文」）→ 不需重述

### Step 6：TaskList 重建（**強制 forcing function，不可跳過**）

handoff「進行中工作」是 **file state**；Claude Code 的 TaskList 是 **runtime state**。新 session 開啟時 TaskList 為空，必須由本步驟把 file state 還原為 runtime state，否則任務追蹤會失效、後續工作無法 TaskUpdate 標記、下次 save 時對話分析會跟實際狀態漂移。

> **重建前必做 · freshness 查證（強制紀律）**：若 cwd 是 git repo，重建每個「進行中」task 前，先 `git status --short`、並對該項涉及檔跑 `git diff`，確認是「**真未做**」還是「**已做未提交**」；若已做則轉 R-2 審查 / commit，**不要**無腦照 handoff 字面重建（會破壞性覆蓋已完成工作）。觸發只在實質程式碼變更時提示，排除 `.claude-loop/` 這類 session churn。advisory-only、fail-open：非 git repo 或 git 不可用就跳過此查證、不擋流程。

#### 流程

1. 呼叫 `TaskList` 檢查當前狀態
2. 解析 handoff「進行中工作」區塊，抽出每項：
   - `subject`：任務標題
   - `description`：當前狀態 + 下一步 + 卡點，串成一段
   - `activeForm`（選用）：「進行 <subject> 中」格式
3. 依當前 TaskList 狀態分支：

| TaskList 狀態 | 動作 |
|--------------|------|
| **空** | 為每個進行中項目呼叫 `TaskCreate`，安靜執行 |
| **已有 task 且 subject 與 handoff 一致** | 略過（安靜，避免重複） |
| **已有 task 但內容跟 handoff 不同** | 列出兩邊差異，問 user：(1) 清空重建 (2) Append handoff 項目 (3) 略過不重建 |

4. 回報訊息：

| 情境 | 訊息 |
|------|------|
| 典型新 session、TaskList 為空 | `📋 已 TaskCreate 重建 N 個進行中任務（id: x–y）` |
| handoff 進行中為空 | `📋 無進行中任務，TaskList 不需重建` |
| 重複 load、TaskList 已一致 | `📋 TaskList 已同步（既有 N 項與 handoff 一致）` |
| 有衝突且 user 選擇後 | `📋 已與既有 task 合併：<清空重建 / append / 略過>` |

#### Edge cases

| 情境 | 處理 |
|------|------|
| handoff「進行中工作」區塊不存在或為空 | 明確回報「無 task 需重建」，**仍然要回報**（讓 user 確認不是漏做） |
| 區塊格式損毀無法解析 | 警告、列出原文、請 user 手動處理 |
| 個別 TaskCreate 失敗 | 列印錯誤、繼續處理其他項目、最後彙總回報哪些成功哪些失敗 |
| user 選擇「略過不重建」 | 仍要在回報明確標示「TaskList 未重建，後續追蹤需手動」 |

## 應該做 vs 不應該做

| ✅ 做 | ❌ 不做 |
|------|--------|
| 對話式摘要（人類好懂） | Dump 完整 handoff.md 給使用者看 |
| 用時間落差感讓人快速進入狀況 | 列出所有 Memory 條目 |
| 主動建議下一步 | 等使用者問「然後呢」 |
| 篩選相關 memory | 逐字背誦日誌 |
| 標記過時警告（>7 天） | 假裝資料一定還有效 |
| 路徑判定回報在最前面 | 讓 user 不知道讀的是哪個 handoff |

## 錯誤處理

| 情境 | 處理 |
|------|------|
| cwd 是 home / root | Step 0 已中止，不會到這 |
| `<handoff_dir>/handoff.md` 不存在 | 回應：「在 `<handoff_dir>` 找不到 handoff 檔案。可能是這個專案首次跑 dev:handoff，或從未存檔過。需要直接開始新工作嗎？」 |
| handoff.md 存在但時戳 > 30 天 | 強烈警告：「上次交接是 30+ 天前，內容很可能已過時，是否仍要套用？或從頭開始？」 |
| 今日無日誌但 handoff 存在 | 用 handoff 為主，日誌 fallback 找最近一篇並提示「日誌最近一次是 YYYY-MM-DD」 |
| handoff.md 格式損毀（無法解析） | 原樣列出內容、警告格式異常，建議使用者人工判讀 |
| MEMORY.md 讀取失敗 | 略過 Memory 區塊，照常輸出 handoff 摘要 |
| 路徑模式（Step 0）疑似錯誤（例如 user 期望讀 .claude-loop/ 但被導向 fallback） | 主動提示「目前走 fallback 模式，若期望讀 .claude-loop/handoff.md 請先建立該目錄」 |

## Red Flags（絕對不要做）

- ❌ 跳過 Step 0 路徑判定
- ❌ 跳過 Step 6 TaskList 重建（即使 handoff 進行中為空也要明確回報「不需重建」）
- ❌ 寫死讀取路徑為 `~/Ctrl/...`
- ❌ 把 handoff.md 整份貼回對話（浪費 context）
- ❌ 跳過時戳檢查直接套用很舊的 handoff
- ❌ 不主動建議下一步，讓使用者自己想
- ❌ 忽略 Git 未 commit 警告（很可能是上次留下的關鍵狀態）
- ❌ 把 TaskList 重建當「可選」 — 它是 forcing function，**唯有** user 主動選擇略過時才能不執行
