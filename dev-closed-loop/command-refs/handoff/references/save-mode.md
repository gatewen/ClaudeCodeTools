# save 模式詳細流程

## 觸發

`/dev:handoff`（不帶參數）、`/dev:handoff save`、`/dev:handoff out`、`/dev:handoff 存`、`/dev:handoff 寫`，或上述任一加 `"備註文字"`。

## 流程

### Step 0：路徑判定（**必做，不可跳過**）

依 `references/path-resolution.md` 判定 `handoff_dir`，並向 user 回報實際路徑（path-resolution.md 中的回報模板）。

不寫死任何專案路徑。所有後續步驟引用 `handoff_dir`，不出現 `~/Ctrl/` 之類的字串。

若 cwd 是 home 或 root → 中止流程，照 path-resolution.md 的 edge case 處理。

### Step 0.5：既存 handoff 偵測與決策（**必做，不可跳過**）

依 `references/conflict-resolution.md` 完整流程處理：

1. Read `<handoff_dir>/handoff.md`（若不存在 → `mode = first_write`，跳到 Step 1）
2. 來源偵測（內部 vs 外部）
3. 內部來源 → 依時戳分級得 `mode`（`silent_overwrite` / `auto_merge` / `silent_overwrite_stale`）
4. 外部來源 → 立即備份 → 嘗試解析 → 得 `mode`（`external_merge` / `external_overwrite`）→ 清理舊 backup

回傳的 `mode` 帶到 Step 4a 決定寫入策略，帶到 Step 6 決定回報訊息。

**絕對不能跳過此步驟直接覆蓋既存檔案**。

### Step 1：對話分析

從當前 session 上下文抓取以下要素，**注意來源優先序**：

| 要素 | 內容 | 來源優先序 |
|------|------|----------|
| **進行中工作** | 未完成的任務，含當前狀態、完成度、下一步 | **TaskList（in_progress + pending）為主**；對話分析僅補充細節（卡點、下一步描述） |
| **已完成項目** | 本 session 內完成的具體事項（標註 commit / 檔案 / PR） | **TaskList（completed）為主**；對話分析補充未進 TaskList 的瑣碎完成事項 |
| **重要決策** | 技術選擇、架構決定，**必須含「為什麼」** | 對話分析 |
| **修改過的檔案** | 本 session 動過的檔案絕對路徑 + 一句描述 | 對話分析（grep file edits） |
| **未解問題** | 阻塞點、待釐清事項、需要 user 決策的問題 | 對話分析 |
| **手動備註** | 若參數含 `"…"`，原文保留並標註為使用者補充 | 參數 |

#### TaskList 為 Source of Truth（重要）

**handoff 的「進行中工作」必須與 TaskList 完全對應**，因為下次 load 時會由 dev:handoff 自動 TaskCreate 重建。任何漂移都會在下次 session 造成混亂。

規則：
- TaskList 中的任務 → 一定要寫進 handoff「進行中工作」
- 對話分析發現的潛在任務但**不在 TaskList 中** → **不要直接寫進 handoff**，而是在 Step 3 提示 user「以下是隱性任務，要不要正式 TaskCreate？」 user 確認後才正式建立並進入下次 save 範圍
- TaskList 為空但對話顯示有未完成工作 → 提示 user「有 X 件事看起來進行中但未 TaskCreate，要不要正式建立追蹤？」

### Step 2：Git 狀態檢查

僅當 cwd 是 git repo 時執行：

```bash
git -C "$PWD" status --short 2>/dev/null
```

- 有 modified / staged → 在 handoff.md 的「⚠️ Git 狀態」區塊列出
- 有 untracked → 同上列出，並標示是否需要 commit
- 不是 repo 或無變更 → 略過此區塊（不要硬寫空區塊）

### Step 3：摘要供使用者確認

以條列方式呈現分析結果，**主動詢問**：

1. 是否要補充備註？
2. 是否有需要修正、合併、刪除的條目？
3. 是否有屬於跨 session 知識的內容應寫入 Memory？（並列出候選）

使用者回應後再進入 Step 4。**不要省略此確認步驟**——除非使用者明確說「直接寫」或帶 `--no-confirm` 之類旗標。

### Step 4：三項寫入

#### 4a. 寫入 `<handoff_dir>/handoff.md`（依 Step 0.5 的 `mode`）

| mode | 動作 |
|------|------|
| `first_write` / `silent_overwrite` / `silent_overwrite_stale` / `external_overwrite` | 直接以模板渲染新內容覆蓋 |
| `auto_merge` / `external_merge` | 依 conflict-resolution.md 的「合併規則」做結構 merge：Read 既存 → 解析區塊 → 與本 session 分析結果合併 → Write 結果 |

通用要求：
- 使用 `references/templates.md` 的 **handoff.md 模板**為渲染基準
- 「最後更新」時戳取系統當前時間，格式 `YYYY-MM-DD HH:MM`
- 若目錄不存在 → `mkdir -p`
- 寫入永遠是「整檔覆蓋」（合併後產生的也是完整新版），**不要 append handoff.md**

#### 4b. Append `<handoff_dir>/logs/YYYY-MM-DD.md`

```bash
mkdir -p "<handoff_dir>/logs"
```

- 若當日檔案不存在 → 建立並先寫入 templates.md 中的 **日誌檔頭**
- Append 一個新的 **日誌條目模板** 區塊（含 HH:MM 時戳）
- 多次 save 時，多個區塊依序累積，**不覆蓋既有內容**

#### 4c. Memory 更新（條件性）

判斷標準：

| ✅ 應寫入 Memory | ❌ 不應寫入 Memory |
|-----------------|-------------------|
| 新確認的使用者偏好或工作方式 | 本 session 完成的具體 task（屬於 log） |
| 新確立的專案決策 + 原因 | 進行中的工作狀態（屬於 handoff） |
| 新踩到的雷 + 規避方法 | 個別檔案修改紀錄 |
| 新的外部資源指引（URL、CLI、API） | 暫時的除錯紀錄 |
| 推翻或修正既有 Memory 的事實 | 已可從 code / CLAUDE.md 推導的資訊 |

寫入規則：
- 走系統內建的 auto-memory 流程（系統 prompt 中已定義 `user`/`feedback`/`project`/`reference` 四種類型）
- **路徑由系統自動決定**（per-project，跟著 cwd 走），dev:handoff 不指定
- 每筆新 memory 為獨立 `.md` 檔，並在 `MEMORY.md` 加一行索引
- 更新既有 memory 時優先 edit 而非新增

### Step 5：驗證寫入

並行檢查（單一 message 多個 Bash 或 Read tool call）：

- `<handoff_dir>/handoff.md` 存在且 size > 0
- `<handoff_dir>/logs/YYYY-MM-DD.md` 含當次新增區塊（grep 時戳）
- 若有 Memory 更新，當前 cwd 對應的 `MEMORY.md` 含對應索引行

任一失敗 → 立即回報並嘗試修復。

### Step 6：回報摘要

固定格式，繁體中文，行數越少越好。第二行 handoff 訊息**依 Step 0.5 的 `mode`** 從 `references/conflict-resolution.md` 的「通知訊息表」選對應字串：

```
📍 路徑模式: <Step 0 判定結果>
<conflict-resolution.md 通知訊息表對應的訊息>
✅ logs/YYYY-MM-DD.md 已 append（HH:MM 區塊）
✅ Memory：更新 N 筆 / 無變更
⚠️ Git 有 X 個未 commit 變更：<簡述>（如有）
```

## 錯誤處理

| 情境 | 處理 |
|------|------|
| cwd 是 home / root | Step 0 已中止，不會到這 |
| `<handoff_dir>/logs/` 不存在 | 自動 `mkdir -p` |
| `<handoff_dir>/handoff.md` 已存在但時戳很舊（>30 天） | 提示「上次交接是 N 天前」，照常覆蓋 |
| 對話極短，沒有實質工作 | 通知「本 session 無實質工作可交接」並中止寫入 |
| Git status 卡住或拒絕 | 跳過 Git 區塊，不阻斷流程 |
| Memory 寫入失敗 | handoff / log 仍照常完成，Memory 失敗單獨回報 |
| 寫入路徑無權限 | 列印錯誤，照 path-resolution.md 詢問是否 fallback 到 [3] |

## Red Flags（絕對不要做）

- ❌ 跳過 Step 0 路徑判定，假設寫到某個固定位置
- ❌ 跳過 Step 0.5 衝突偵測，直接覆蓋既存 handoff
- ❌ 寫死 `~/Ctrl/`、`~/WorkProjects/...` 等任何專案路徑
- ❌ 沒備份就覆蓋外部來源 handoff
- ❌ 把選擇權推給 user（除非真衝突，見 conflict-resolution.md）
- ❌ 不確認直接寫（除非使用者明示）
- ❌ 把本 session 的工作狀態寫進 Memory（汙染長期記憶）
- ❌ 把跨 session 偏好寫進 handoff（會被下次 save 覆蓋）
- ❌ Append 寫到 handoff.md（handoff 永遠是整檔覆蓋）
- ❌ Overwrite 寫到 logs/YYYY-MM-DD.md（log 永遠是 append）
