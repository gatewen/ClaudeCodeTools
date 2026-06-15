# 路徑判定邏輯（單一真理源）

所有路徑（handoff、log）皆以**當前 cwd** 為基準，**不寫死任何專案路徑**。Memory 跟著系統 auto-memory 走，dev:handoff 不額外處理路徑。

## 判定流程

依序檢查，**先匹配先用**：

```
讀取 cwd（pwd 或 $PWD）
↓
[1] 若 <cwd>/.claude-loop/ 存在
    → handoff_dir = <cwd>/.claude-loop
[2] 若 <cwd>/CLAUDE.md 內規範了 handoff 位置
    （grep 關鍵字：handoff、交接、claude-loop、session-level）
    → handoff_dir = CLAUDE.md 指定的位置
[3] fallback
    → handoff_dir = ~/.claude/projects/<cwd-encoded>
```

## cwd 編碼規則

把 cwd 全路徑的 `/` 與 `_` 全部替換成 `-`（含開頭那個 `/`）：

```bash
encoded=$(echo "$PWD" | sed 's|[/_]|-|g')
```

範例：
| cwd | encoded |
|-----|---------|
| `/Users/gatewenlee/Ctrl` | `-Users-gatewenlee-Ctrl` |
| `/Users/gatewenlee/WorkProjects/UK_Wrok` | `-Users-gatewenlee-WorkProjects-UK-Wrok` |

⚠️ 須同時轉 `/` 與 `_`；此為 best-effort 啟發式，權威來源是 `~/.claude/projects/` 既有目錄的實際存在性——load 時若拼出的 slug 目錄不存在，應 glob `~/.claude/projects/` 找實際匹配再採用，避免落孤兒目錄。

## 最終路徑表

| 用途 | 路徑 |
|------|------|
| handoff.md | `<handoff_dir>/handoff.md` |
| 當日日誌 | `<handoff_dir>/logs/YYYY-MM-DD.md` |
| Memory | 由系統 auto-memory 自動處理，**不要在 dev:handoff 內手動指定** |

## 三種典型情境

### A. UK_Wrok（已有 .claude-loop/）

```
cwd: /Users/gatewenlee/WorkProjects/UK_Wrok
判定: [1] .claude-loop/ 存在 ✓
handoff → /Users/gatewenlee/WorkProjects/UK_Wrok/.claude-loop/handoff.md
logs    → /Users/gatewenlee/WorkProjects/UK_Wrok/.claude-loop/logs/YYYY-MM-DD.md
```

### B. Ctrl（無特殊規範）

```
cwd: /Users/gatewenlee/Ctrl
判定: [1] 無 .claude-loop/ → [2] CLAUDE.md 無 handoff 規範 → [3] fallback
handoff → ~/.claude/projects/-Users-gatewenlee-Ctrl/handoff.md
logs    → ~/.claude/projects/-Users-gatewenlee-Ctrl/logs/YYYY-MM-DD.md
```

### C. 全新專案

```
cwd: /some/new/project
判定: 同 B，走 fallback
handoff → ~/.claude/projects/-some-new-project/handoff.md
logs    → ~/.claude/projects/-some-new-project/logs/YYYY-MM-DD.md
```

## 路徑回報

**save 或 load 開始時，必須先回報實際使用的路徑**，避免 user surprise：

```
📍 cwd: <full cwd>
   模式: <「沿用 .claude-loop/」 | 「CLAUDE.md 規範」 | 「fallback 隱藏路徑」>
   handoff → <handoff path>
   logs    → <logs dir>
```

## Edge cases

| 情境 | 處理 |
|------|------|
| cwd 是 `$HOME` 或 `/` | 警告「不適合在 home/root 跑 handoff」，要求使用者 cd 到專案再試，**中止流程**。**比對前先正規化**（解 symlink / 去尾斜線），別純字串比：`real=$(cd "$PWD" && pwd -P)`，再以 `real` 與 `$HOME` / `/` 比對。⚠️ 注意 shell 運算子優先序——`[ ] || [ ]` 後接 `&& abort` 會讓 `&&` 只綁到第二個 test，須加括號或拆寫：`if [ "$real" = "$HOME" ] \|\| [ "$real" = "/" ]; then abort; fi`（或 `{ [ ... ] \|\| [ ... ]; } && abort`） |
| fallback slug 目錄不存在（load 模式） | 編碼為 best-effort，可能與既有目錄不符；**load 時先枚舉 `~/.claude/projects/` 比對**（glob 找實際匹配的 slug），找到就採用實際目錄，避免讀到孤兒目錄 |
| fallback 路徑的目錄不存在（save 模式） | 自動 `mkdir -p ~/.claude/projects/<cwd-encoded>/logs`（save 才建立，不在 load 誤觸發 mkdir） |
| `.claude-loop/` 存在但無 handoff.md（規範存在但首次使用） | handoff_dir = `<cwd>/.claude-loop`，視為首次寫入並建立檔案 |
| CLAUDE.md 規範路徑但該路徑無法寫入（權限/不存在） | 警告、列印實際錯誤、問 user 是否 fallback 到 [3] |
| 同時有 `.claude-loop/` 和 CLAUDE.md 規範另一處 | 以 `.claude-loop/` 為準（[1] 優先序高於 [2]），但回報時提及衝突 |

## 不要做

- ❌ 不要寫死 `~/Ctrl/`、`~/WorkProjects/...` 等任何特定專案路徑
- ❌ 不要把 handoff 寫到 `~/.claude/skills/`、`~/.claude/plugins/` 等系統目錄
- ❌ 不要為 Memory 重新發明路徑（系統已掛載對的）
- ❌ 不要在 user 不知情下偷偷切換路徑模式（必須回報）
