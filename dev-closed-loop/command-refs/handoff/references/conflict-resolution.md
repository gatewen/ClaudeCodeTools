# 衝突處理邏輯（單一真理源）

當 `<handoff_dir>/handoff.md` 已存在時的智能處理規則。

**核心原則：盡量自動處理，不要把選擇推給 user。**

## 核心洞察

`logs/YYYY-MM-DD.md` 是歷史的 source of truth。只要既存 handoff.md 是 dev:handoff 自己寫的，每次 save 內容**早就 append 到當日 log 了**，覆蓋 handoff.md 不會遺失資訊。

例外：**外部來源**（手動寫 / 其他工具產出）的 handoff.md 沒被歸檔 → 覆蓋會真丟資訊 → 必須備份。

## Step 1：來源偵測

掃描既存 handoff.md，找 dev:handoff 模板特徵：

| 特徵 |
|------|
| 標題 `# Session Handoff` |
| `**最後更新**:` 欄位 |
| `**Session 焦點**:` 欄位 |
| `## 進行中工作` 區段 |
| `## 起手式建議` 區段 |

判定：
- **≥ 3 個特徵** → 疑似內部來源（dev:handoff 寫的）
- **< 3 個特徵** → 外部來源（手動 / 其他工具）

⚠️ **此判據是字串啟發式，非確定性 marker**：上述特徵全是 dev:handoff 模板的可見 markdown 字串（標題 / 欄位 / 區段名），外部手寫只要沿用同樣欄位名（≥ 3 個）就會被偽判為內部。目前**沒有任何 machine-readable marker**（HTML 註解 / uuid 等權威標記）能確定區分內外。因此「≥ 3 個特徵」只能視為「疑似內部」，**不可據此跳過備份直接覆蓋**——見 Step 3「保守備份」分支。

## Step 2：時戳分級（僅內部來源）

從 `**最後更新**:` 欄位抽取時戳，與當前時間比對：

| 落差 | 分類 | 預設動作 |
|------|------|---------|
| < 1 小時 | 同 session 多次 save | **安靜覆蓋** |
| 1–24 小時 | 跨 session 接續 | **自動合併** |
| > 24 小時 | 過時內容 | **安靜覆蓋** |

## Step 3：決策樹

```
讀 <handoff_dir>/handoff.md
  ├─ 不存在 → mode = first_write，直接寫，結束
  │
  ├─ 疑似內部來源（≥ 3 字串特徵，但無確定性 marker）
  │    ├─ Step 0: 保守 backup（deterministic cp，無條件先做）
  │    │          理由：marker 缺失，無法確定真內部，疑似外部模仿
  │    │          也走這支 → 先 cp 保命，覆蓋才不可逆地丟資料。
  │    │          cp 是確定性動作，非 LLM heuristic 判斷。
  │    ├─ < 1h   → mode = silent_overwrite
  │    ├─ 1–24h → mode = auto_merge
  │    └─ > 24h  → mode = silent_overwrite_stale
  │
  └─ 外部來源
       ├─ Step A: 自動 backup
       ├─ Step B: 嘗試結構解析
       │    ├─ 成功 → mode = external_merge
       │    └─ 失敗 → mode = external_overwrite
       └─ Step C: backup 清理（保留最近 5 個）
```

> **為何疑似內部也要備份**：來源偵測只有字串啟發式、沒有確定性 marker（見 Step 1 ⚠️）。外部手寫沿用模板欄位名就會被偽判為內部，舊邏輯會跳過備份直接覆蓋/合併、撞時戳分級即安靜覆蓋、不可復原。改採「**缺確定性 marker 時一律保守備份**」：用一次確定性的 `cp` 換掉不可逆的資料遺失風險，代價極小。若未來 PR 在模板埋入 machine-readable marker，可將「marker 存在=確定內部、可安全跳過備份」收窄回原行為。

回傳 `mode` 給 save-mode.md 的 Step 4a 使用。

## 合併規則（結構 merge）

針對相同區塊類型，套用不同合併策略：

| 區塊 | 策略 | 說明 |
|------|------|------|
| Session 焦點 | **覆蓋** | 焦點會變，以本 session 為準 |
| 進行中工作 | **覆蓋** | 最新狀態取代舊狀態 |
| 已完成項目 | **累積去重** | 既存 + 新增，依條目文字去重 |
| 重要決策 / 發現 | **累積** | 決策只增不減，保留軌跡 |
| 修改過的檔案 | **累積去重** | 依 path 去重 |
| 手動備註 | **累積分區** | 既存區塊保留，新備註另起區塊（含時戳） |
| Git 狀態 | **覆蓋** | 即時快照 |
| 起手式建議 | **覆蓋** | 依新進行中工作重新生成 |

實作：Read 既存 + 對話分析 + 模板，由 Claude 直接 Write 結果（不需 script）。

## 疑似內部來源的保守備份（Step 0）

來源偵測沒有確定性 marker（見 Step 1 ⚠️），「疑似內部」可能其實是外部手寫沿用了模板欄位名。為避免偽判內部 → 跳過備份 → 撞時戳分級安靜覆蓋 → 不可復原，**疑似內部來源在進入時戳分級（silent_overwrite / auto_merge / silent_overwrite_stale）之前，無條件先做一次確定性備份**：

```bash
ts=$(date +%Y%m%d-%H%M)
cp "<handoff_dir>/handoff.md" "<handoff_dir>/handoff.md.internal-$ts"
```

備份檔命名：`handoff.md.internal-YYYYMMDD-HHMM`（與外部來源的 `external-` 前綴分開，互不干擾各自的清理 glob）。

- **`cp` 是確定性動作、非 LLM heuristic 判斷**——不依賴「字串命中=內部」這種不可靠推論，只依賴「檔案存在就先複製一份」這個無爭議事實。
- 備份完成後，再依時戳分級決定 mode 並覆蓋/合併。即使後續分級判斷有誤，原檔已在 backup。
- 安靜執行，不通知 user（與外部備份一致，不把選擇推給 user）。

> 備註：本步驟刻意**不**做並行 session 競態偵測/告警。無鎖的 LLM spec 對「另一 session 是否正在寫」給不出可靠保證，硬寫告警會變成無法兌現的承諾。並行限制仍歸「已知限制」section 誠實揭露。

### Backup 清理（疑似內部）

與外部來源對稱，保留最近 5 個 `internal-` backup（守衛會額外保住本次剛建的 `$ts`，故磁碟上最多 6 個——刻意多留一個的安全偏差）：

```bash
# 守衛：先排除本次剛建的 $ts backup（避免時鐘偏移／ls 排序異常誤刪剛建檔），再從其餘歷史檔刪掉超出最近 5 個者
ls -t "<handoff_dir>"/handoff.md.internal-* 2>/dev/null | grep -v "internal-${ts}\$" | tail -n +6 | xargs rm -f 2>/dev/null
```

glob 限定 `handoff.md.internal-*`，不波及 `external-` 系列；排在備份+寫入完成之後執行。

## 外部來源處理

### Step A：自動備份

```bash
ts=$(date +%Y%m%d-%H%M)
cp "<handoff_dir>/handoff.md" "<handoff_dir>/handoff.md.external-$ts"
```

備份檔命名：`handoff.md.external-YYYYMMDD-HHMM`

**先備份再做任何事**，確保即使後續處理失敗也不丟資料。

### Step B：嘗試結構解析

判斷既存內容是否為可識別的 markdown 結構：
- 含 `## 標題` 或 `# 標題` → 嘗試擷取區塊，套用「合併規則」
- 純文字 / 無結構 → 視為「無法解析」，寫入新版（backup 已保留）

合併時**手動備註區塊優先保留**（user 手寫內容珍貴）。

### Step C：Backup 清理

保留最近 5 個歷史 backup（守衛會額外保住本次剛建的 `$ts`，故磁碟上最多 6 個——刻意多留一個的安全偏差）：

```bash
# 守衛：先排除本次剛建的 $ts backup（避免時鐘偏移／ls 排序異常誤刪剛建檔），再從其餘歷史檔刪掉超出最近 5 個者
ls -t "<handoff_dir>"/handoff.md.external-* 2>/dev/null | grep -v "external-${ts}\$" | tail -n +6 | xargs rm -f 2>/dev/null
```

安靜執行，不通知 user。**清理排在備份+寫入完成之後**，且絕不刪本次剛建的 `$ts` backup（守衛已排除）——清理步驟本身不得成為自造的資料遺失來源。

## 通知訊息表

依 `mode` 給簡短訊息（在 save-mode.md 的 Step 6 回報時使用）：

| mode | 訊息 |
|------|------|
| `first_write` | `✅ handoff 已建立（首次）` |
| `silent_overwrite` | `✅ handoff 已更新（同 session 第 N 次，原檔已保守備份至 handoff.md.internal-YYYYMMDD-HHMM）` |
| `auto_merge` | `🔄 偵測到 X 小時前的交接，已合併（已完成累積 N 項、決策保留 Y 項，原檔已保守備份至 handoff.md.internal-YYYYMMDD-HHMM）` |
| `silent_overwrite_stale` | `✅ handoff 已覆蓋（上次交接 N 天前，歷史在 logs/，原檔已保守備份至 handoff.md.internal-YYYYMMDD-HHMM）` |
| `external_merge` | `🔀 偵測到外部 handoff，已合併內容，原檔備份至 handoff.md.external-YYYYMMDD-HHMM` |
| `external_overwrite` | `⚠️ 偵測到外部 handoff 但無法解析，已寫入新版，原檔備份至 handoff.md.external-YYYYMMDD-HHMM` |

## 何時才問 user（exception only）

**唯一**會問的情境：結構合併時同一條目兩邊內容**衝突**且本 session 沒有明顯覆蓋意圖。

例如：
- 既存「進行中：任務 A — 完成 60%，下一步 X」
- 本 session 也提到任務 A 但「完成 40%，下一步 Y」（明顯倒退或衝突）

此時呈現兩邊內容，問「保留 A / B / 都保留」。

**極少觸發** — 大部分 case 規則已能自動處理。

## Red Flags

- ❌ 把選擇權推給 user（除非真衝突）
- ❌ 沒備份就覆蓋外部來源
- ❌ 把「≥ 3 字串特徵」當確定性 marker、據此跳過備份直接覆蓋（無確定性 marker → 疑似內部也要先保守 cp 備份）
- ❌ 把覆蓋當預設行為而不偵測（即使疑似內部來源也要先判時戳、且先備份）
- ❌ 合併時丟失 user 手寫備註
- ❌ Backup 堆到無限多（必須清理）
- ❌ 問 user「要不要合併」「要不要備份」這類本該自動的問題

## 已知限制（假設單人單寫）

本流程**假設同一 `<handoff_dir>` 同時只有一個 session 在 save**。並行情境未加鎖：

- **並行 save 競態**：同 cwd 兩 session 幾乎同時 save，handoff.md 是整檔覆蓋、無鎖 → **後寫覆蓋前寫（last-writer-wins）**，前一個 session 的進行中/起手式可能遺失。（logs/ 是 append，相對安全；風險集中在 handoff.md。）
- **緩解**：save 前若懷疑有另一 session 正在同一專案寫，先確認；或以最新一次 save 為準（歷史仍在 logs/）。
- 時戳異常（欄位損毀無法抽取、未來時戳/時鐘偏移導致負落差）時，時戳分級無對應分支 → fallback 視為 `silent_overwrite`（內部來源覆蓋安全，歷史在 logs/）。
