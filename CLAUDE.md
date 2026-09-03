# CLAUDE.md

本檔案提供 Claude Code 在此 repo 工作時的指引。

## 語言設定

- 所有互動使用**繁體中文**

## 這個 Repo 是什麼

Claude Code 工具鏈集中管理。核心是「開發設計閉環」方法論 v8：一份不到 200 行的 CLAUDE.md 模板、三支 hook、一個部署指令、四支可選 workflow。這**不是**應用程式專案，沒有 build 可跑；有 `tests/` smoke 套件給 maintainer 用。

v8 的定位（2026-09-03）：v3 到 v7 的五角色流水線經六場對照實驗證明對 correctness 零增益，v8 砍到只剩「改碼前先弄清楚依賴」「斷言事實前先查證據」「換一個 context 審一次」三件事加配套。細節在 `dev-closed-loop/design/15-v8-slim.md`。v8.1（同日）補四項：白話互動、架構與可維護性（含 SSOT 與「重複定義」檢查）、workflow 三級模型分配、dev-design / dev-review 改讀專案 CLAUDE.md 架構規則。細節在 `dev-closed-loop/design/16-v8.1-additions.md`。

## 倉庫結構

- `setup.sh` — 安裝腳本（`curl | bash` 遠端 + 本地雙模式）。部署 `/dev:init-claude`（`~/.claude/commands/dev/init-claude.md`，`{{REPO_PATH}}` 替換為來源路徑）、`/dev:handoff`（shim + bundle）、4 支 workflow 到 `~/.claude/workflows/`；清除 v7 殘留（colon-skill、`/dev:overview`）；驗證部署包 .claudedocs 5/5、hooks 4/4（3 hook + `_helpers.sh`）。
- `dev-closed-loop/CLAUDE_TEMPLATE.md` — 核心產物。5 個 placeholder：`{{PROJECT_NAME}}` `{{LANGUAGE}}` `{{FRAMEWORK}}` `{{TEST_COMMAND}}` `{{BUILD_COMMAND}}`。末尾 HTML 註解含 `closed-loop vX.Y.Z` marker（check-version.sh 與 setup.sh 完成訊息都用 `grep -o 'closed-loop v[0-9.]*'` 抓）與 migration-notes。Section 3 節首有 `<!-- arch-rules -->` 錨點，dev-design / dev-review 靠它定位審查標準；「模型分配」表是 workflow `TIERS` 常數的唯一定義處。
- `dev-closed-loop/skill/init-claude.md` — `/dev:init-claude` 源碼：status / upgrade / uninstall / 部署流程（偵測、確認、填充、複製 `.claudedocs`、清 v7 殘留、deploy-hooks、驗證）。
- `dev-closed-loop/commands/dev/handoff.md` + `command-refs/handoff/`（SKILL.md + 5 references）— `/dev:handoff`。shim 不放顯式 `name:`（指令名由路徑合成）、`description:` 用 `>-` 折疊塊（值含「冒號+空格」在單行純量會壞 YAML）。bundle 內 references 用相對路徑互引，須整包同層部署。
- `dev-closed-loop/hooks/` — `impact-analysis-guard.sh`（PreToolUse Write|Edit|MultiEdit：每輪首次修改既有原始碼檔擋一次，訊息走 stderr）、`causal-chain-reset.sh`（UserPromptSubmit：清本 session marker）、`incremental-lint.sh`（PostToolUse：js/ts/py/go per-file lint）、`_helpers.sh`（`get_project_key` / `get_gate_base` / `json_field` jq→sed / `get_session_key`；`CLOSED_LOOP_NO_JQ=1` 強制走 sed 供測試）。marker 在 `${TMPDIR}/claude-code-tools/<project>/causal-chain/<session>/`。
- `dev-closed-loop/deploy-hooks.sh` — 複製 hook、合併 settings.json（python3 → python → jq）、清除 4 支舊 hook 的腳本與設定項、驗證。
- `dev-closed-loop/workflows/*.js` — dev-prd / dev-design / dev-review / dev-verify。存檔即 `/<name>` slash command（連字號，非冒號）。需 Claude Code v2.1.154+ · 付費 · research preview。腳本不能 import，所以四支頂部各放一份逐字相同的 `TIERS`（模型等級）常數，dev-design / dev-review 另有相同的 `ARCH_RULES`（指路到專案 CLAUDE.md Section 3，不抄規則正文）；cross-file 測試鎖多份一致。
- `dev-closed-loop/.claudedocs/` — 部署到專案的 5 檔：`README.md`、`concepts/閉環核心理念.md`、`standards/產出物格式.md`、`standards/Git工作流.md`、`records/問題追蹤.md`。
- `dev-closed-loop/design/` — 設計歷史 01-16。`history-v7/` 放 v7 以前部署過、v8 不再部署的檔案（agents / languages / process / examples / KPI / Agent使用指南 / v7.1.2 模板）。僅供參考，不要修改。
- `tests/` — smoke 套件，不部署。`bash tests/run.sh`：Phase A shellcheck（缺則 skip）+ Phase B 動態發現 `test-*.sh`。7 個：cross-file-consistency / setup-local / setup-remote-sha / deploy-hooks / hooks-isolation / hooks-exit-codes / bash-compat。`install-pre-commit.sh` 裝寬鬆模式 pre-commit。
- `.claude-loop/` — 本 repo 自己 dogfood 的產物與實驗報告（A–F 對照實驗、對抗評估、handoff）。git 追蹤，僅供參考。
- `closed-loop-autonomy-v2.md` — 2026-05 的自治化藍圖，未採納，留作參考。

## 操作方式

**安裝**：`curl -sL https://raw.githubusercontent.com/gatewen/ClaudeCodeTools/main/setup.sh | bash`，或 clone 後 `bash setup.sh`。
**使用**：專案目錄執行 `/dev:init-claude`。
**更新**：`/dev:init-claude upgrade`（curl 安裝者）或 `git pull && bash setup.sh`（clone 者）。handoff 與 workflow 由 setup.sh 部署，upgrade 不會重裝它們。
**依賴**：bash 3.2+、git、curl，加 jq 或 python3 其一。可選：claude-mem。

## 編輯規範

### 修改前先查依賴表

這個 repo 的檔案之間有內容層級的依賴，沒有編譯器抓不一致。改任何檔案前先查下表，在回應中列出受影響的連動檔，一起改完，最後 `bash tests/run.sh`。

| 改動位置 | 必須同步檢查 |
|---------|-------------|
| `CLAUDE_TEMPLATE.md` 規則內容 | `.claudedocs/concepts/閉環核心理念.md`（人類版說明須一致）· `QUICKSTART.md` · 根 README「這是什麼」段 |
| `CLAUDE_TEMPLATE.md` placeholder 增刪 | `skill/init-claude.md` Step 4 替換表 + Step 1.5 提取表 · 模板末尾部署說明 |
| `CLAUDE_TEMPLATE.md` 對 hook 的描述 | `hooks/*.sh` 實際行為（描述不可超過腳本做的事，見 v7.0.1 教訓）· 根 README hook 表 |
| `CLAUDE_TEMPLATE.md` ID 系統 / 產出格式 | `.claudedocs/standards/產出物格式.md` |
| **版本號** | **模板末尾 `closed-loop vX.Y.Z` marker（source of truth）**· 模板 migration-notes · `dev-closed-loop/README.md` 版本歷史 · 根 README 版本表 · `tests/test-cross-file-consistency.sh` Check 5 會比對 marker 與兩份 README |
| `hooks/*.sh` 增刪或行為變更 | `deploy-hooks.sh`（HOOK_FILES / LEGACY_HOOKS / 兩套合併腳本 / 驗證）· `setup.sh` HOOK_FILES · `skill/init-claude.md`（status 表、uninstall 清單、Step 4b、Step 5）· `tests/test-deploy-hooks.sh` `tests/test-hooks-exit-codes.sh` `tests/test-cross-file-consistency.sh` · 根 README hook 表 · 模板 Section 2 |
| `.claudedocs/` 檔案增刪 | `setup.sh` EXPECTED_FILES · `skill/init-claude.md` Step 5 · `.claudedocs/README.md` · `tests/test-cross-file-consistency.sh`（Check 2 反向檢查：目錄內不得有未宣告檔）· 本檔倉庫結構 |
| `workflows/*.js` | `setup.sh` WORKFLOW_FILES · 模板「可用 workflow」表 · `tests/test-setup-local.sh` Check 5.7（meta.name + node --check）· meta.name 改動連動 slash 指令名 · `TIERS` / `ARCH_RULES` 改一份要改全部（cross-file Check 6 / 7） |
| **模板「模型分配」表**（等級 → model / effort） | 四支 `workflows/*.js` 頂部 `TIERS` 常數（逐字相同）· cross-file Check 6 比對 low / mid / high 三列 |
| **模板 Section 3 條目名、`<!-- arch-rules -->` 錨點** | `workflows/dev-design.js` `dev-review.js` 的 `ARCH_RULES` 索引名（逐字相同）· cross-file Check 7 |
| **模板 Section 2 輸出格式**（`⚠️ 改 …｜…`） | `hooks/impact-analysis-guard.sh` 從 `${CLAUDE_PROJECT_DIR:-.}/CLAUDE.md` 讀「**輸出**」行印出（grep 必須 `\|\| true`，腳本是 `set -e`），找不到才用腳本內 fallback 字串；改格式時同步 fallback · `tests/test-hooks-exit-codes.sh` 三情境（無 CLAUDE.md / 無輸出行 / 模板）都要 exit 2 且 stderr 含格式行 · `.claudedocs/standards/產出物格式.md` 設計規格「觸及」行 |
| **模板行數** | 對外文檔只寫「不到 200 行」（根 README、README.en、`dev-closed-loop/README.md`、`QUICKSTART.md`、本檔），不寫確切數字；cross-file Check 8 鎖上限。確切行數只出現在版本歷史列（歷史紀錄，不回改） |
| `commands/dev/handoff.md` 或 `command-refs/handoff/*` | `setup.sh` 部署與驗證清單 · `tests/test-setup-local.sh` Check 5.5 |
| `setup.sh` 陣列數量、hook marker 路徑 namespace、deploy-hooks settings.json keywords | `tests/test-*.sh` 對應斷言 |

### 靜態規則

- `CLAUDE_TEMPLATE.md` 必須保留 5 個 `{{PLACEHOLDER}}`，且除此之外不得出現 `{{`（init-claude 用它檢查殘留；註解裡提到 placeholder 名稱時不加大括號）。
- `.claudedocs/` 維持 5 檔。要加檔案先問「Claude 需要讀它嗎、人會讀它嗎」，兩個都不是就放 `design/`。
- `hooks/` 內容含反斜線時用 Write 工具寫，不用 Bash heredoc（本機 Bash 工具層會吃掉一層反斜線，見 2026-09-03 日誌）。含反斜線的測試輸入先寫成 fixture 檔再 `< fixture` 餵。
- hook 腳本不得依賴 python；JSON 解析用 `_helpers.sh` 的 `json_field`。
- `design/` 與 `design/history-v7/` 只增不改。
- `tests/` 不被 setup.sh 部署。commit 前 `bash tests/run.sh`，macOS 與 Windows Git Bash 皆應 7/7 通過（remote-sha 測試在有 `cygpath` 時自動把 file:// 轉成 Windows 路徑）。
- 改方法論內容（模板、`.claudedocs/concepts`、`.claudedocs/standards`）前，用 Agent 工具開一個沒有本對話 context 的獨立子 agent 審一輪（問題追蹤 #007）。
- **SSOT**：任何會出現在兩處以上的數值、清單、對照表、格式字串，先問能不能只定義一處；不能就讓一處產生另一處（如 setup.sh 從模板 marker 讀版本）；再不能就在 `tests/test-cross-file-consistency.sh` 加一致性檢查。只寫進上面的依賴表不算處理完，依賴表是「靠人記得」，SSOT 的最後一層（問題追蹤 #008）。

## 每日日誌（maintainer 與 Claude 的協作脈絡）

> 僅限這個 repo，個人脈絡不進 git。

**何時寫**：達成決策、用戶糾正你、session 結束前補 TL;DR。
**寫去哪**：`~/.claude/projects/<repo-slug>/memory/daily/YYYY-MM-DD.md`。`<repo-slug>` 是工作目錄絕對路徑把分隔符換成 `-`，例如 Windows `I:\ai_code\ClaudeCodeTools` → `I--ai-code-ClaudeCodeTools`。不存在就建，存在就 append。
**寫什麼**：用戶要求、拍板的事與理由、糾正與修正方向、為什麼選 A 不選 B。不寫逐字對話、不寫沒成立的猜測、不寫純查詢。
**修正**：同檔內 `~~舊結論~~` 加 `> ⚠️ [HH:MM update] 新結論`。昨天的反悔不去動昨天的檔，以最新為準。
