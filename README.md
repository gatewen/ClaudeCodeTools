# ClaudeCodeTools

讓 Claude Code 改程式之前先想清楚兩件事：這一改會牽動誰，我相信的事實是不是真的。

> **定位**：個人工具，對自己嚴格用的。repo 公開可 fork、學習、自用，但未主動推廣，不承諾外部支援，issue 視作者時間回應。MIT 授權（見 `LICENSE`）。
>
> **English** → [README.en.md](README.en.md) · **十分鐘上手** → [dev-closed-loop/QUICKSTART.md](dev-closed-loop/QUICKSTART.md)

## 這是什麼

一份約 125 行的 CLAUDE.md 模板，加三支 hook，加一個一鍵部署指令。裝進專案後，Claude Code 每個 session 會照這份規則做事：

1. **先判任務大小再動手。** 改一行直接改；新模組先出設計、再實作、再逐條確認每條行為契約有實作有測試。
2. **改既有程式碼前先寫出誰會被牽動。** hook 會在每輪指令內第一次改某個原始碼檔時擋一下，要 Claude 先寫 2-4 行因果鏈分析再重試。你在它動手前就看得到推理。
3. **斷言環境事實前先查證據。** 字面證據、反例檢查、共用值三條，來自一次真實的誤判事故。
4. **只在五種情境反對你**，其他時候照做不多嘴。

## 它不是什麼

v3 到 v7 的版本是一套五角色流水線（架構師、程序設計師、檢核師、測試師、自證師）。2026 年 5 月六場對照實驗顯示，對前沿模型而言這套流水線對程式正確性零增益，成本最高是裸寫的 7 倍。v8 把它砍掉，只留實驗指出有價值的部分：把契約寫下來、換一個沒有原推理脈絡的視角審一次、以及上面四條紀律。細節在 [dev-closed-loop/.claudedocs/concepts/閉環核心理念.md](dev-closed-loop/.claudedocs/concepts/閉環核心理念.md)。

## 安裝

```bash
curl -sL https://raw.githubusercontent.com/gatewen/ClaudeCodeTools/main/setup.sh | bash
```

會下載到 `~/.claude/cache/ClaudeCodeTools/`，部署 `/dev:init-claude` 與 `/dev:handoff` 指令，以及四支 workflow 腳本。

> 開發者也可以 `git clone https://github.com/gatewen/ClaudeCodeTools.git && cd ClaudeCodeTools && bash setup.sh`

### 平台支援

| 平台 | 支援 | 說明 |
|------|------|------|
| **macOS** | 主要 | 開發與測試環境，發版前跑完整 smoke 套件 |
| **Linux** | best effort | 應可運作，無 Linux 專屬測試 |
| **Windows** | Git Bash | v7.1 起 repo 可在原生 Windows clone。hook 與 tests 在 Git Bash 下驗證通過。需要 `jq` 或可用的 `python3`（Microsoft Store 的空殼 python 不算）。原生 cmd / PowerShell 不支援 |

執行依賴：`bash 3.2+`、`git`、`curl`，加 `jq` 或 `python3` 其一。

### 關於 `curl | bash`

直接 pipe 到 bash 表示沒有事先檢視程式碼的機會。不放心的話：

```bash
curl -sL https://raw.githubusercontent.com/gatewen/ClaudeCodeTools/main/setup.sh -o /tmp/setup.sh
less /tmp/setup.sh
bash /tmp/setup.sh
```

或 git clone 後本地安裝，或釘住特定 commit SHA：

```bash
SHA=$(curl -sL https://api.github.com/repos/gatewen/ClaudeCodeTools/commits/main | grep '"sha"' | head -1 | sed 's/.*"sha": *"//;s/".*//')
curl -sL https://raw.githubusercontent.com/gatewen/ClaudeCodeTools/${SHA}/setup.sh | bash
```

setup.sh 做的事：下載 tarball、解壓到 `~/.claude/cache/`、複製 2 個 markdown 到 `~/.claude/commands/dev/`、複製 handoff bundle 到 `~/.claude/dev-closed-loop/`、複製 4 個 js 到 `~/.claude/workflows/`、印驗證結果。不改 PATH、不寫 cron、不裝額外軟體。

## 使用

在專案目錄開 Claude Code，輸入：

```
/dev:init-claude
```

它會偵測語言、框架、測試與建置指令，問你確認後，把 CLAUDE.md、5 份文檔、3 支 hook 部署到專案。之後每個 session 自動生效。

| 指令 | 做什麼 |
|------|--------|
| `/dev:init-claude status` | 看部署狀態、版本、是否有 v7 殘留 |
| `/dev:init-claude upgrade` | 從 GitHub 下載最新版並升級 |
| `/dev:init-claude uninstall` | 從專案移除 |
| `/dev:handoff save` / `load` | 跨 session 交接進度 |
| `/dev-prd` `/dev-design` `/dev-review` `/dev-verify` | 多 agent workflow（需 Claude Code v2.1.154+、付費方案、research preview；開不了時 CLAUDE.md 有退化做法） |

## Hook

| Hook | 觸發 | 做什麼 |
|------|------|--------|
| `impact-analysis-guard.sh` | 每輪指令內首次修改既有原始碼檔 | 擋一次，印出以檔名粗搜的相關檔案當起點，要 Claude 先寫 2-4 行因果鏈分析再重試。不擋新檔、md、json、yaml；只攔 Write / Edit，Bash 改檔不攔 |
| `causal-chain-reset.sh` | 每個用戶指令 | 清本 session 的因果鏈 marker，讓每輪重新分析一次。不阻擋、無關鍵字判斷 |
| `incremental-lint.sh` | 修改後 | 對 js / ts、py、go 檔跑 per-file lint 並回饋錯誤。其他語言不覆蓋 |

hook 是提醒，不是保證。它保證的是「暫停一次、分析可見」，分析對不對仍靠模型和你的眼睛。hook 不依賴 python，JSON 解析用 jq，沒有 jq 時退 sed。

## 目錄結構

```
ClaudeCodeTools/
├── README.md / README.en.md
├── CLAUDE.md                      ← 給 Claude Code 看的 repo 維護指引
├── setup.sh                       ← 安裝腳本（curl 遠端 + 本地雙模式）
├── tests/                         ← maintainer 用的 smoke test，不部署
└── dev-closed-loop/
    ├── CLAUDE_TEMPLATE.md         ← 核心產物，~125 行，5 個 placeholder
    ├── QUICKSTART.md
    ├── skill/init-claude.md       ← /dev:init-claude 源碼
    ├── commands/dev/handoff.md    ← /dev:handoff shim
    ├── command-refs/handoff/      ← handoff bundle（SKILL.md + 5 references）
    ├── hooks/                     ← 3 支 hook + _helpers.sh
    ├── workflows/                 ← 4 支 workflow 腳本
    ├── deploy-hooks.sh · check-version.sh
    ├── .claudedocs/               ← 部署到專案的 5 份文檔
    │   ├── README.md
    │   ├── concepts/閉環核心理念.md
    │   ├── standards/產出物格式.md · Git工作流.md
    │   └── records/問題追蹤.md
    └── design/                    ← 設計歷史 01-15；history-v7/ 放 v7 以前部署過的文檔
```

## 版本

目前 **v8.0.0**（2026-09-03）。完整版本歷史在 [dev-closed-loop/README.md](dev-closed-loop/README.md#版本歷史)。

| 版本 | 重點 |
|------|------|
| **v8.0.0** | 瘦身：模板 344 → 134 行、部署包 33 → 5 檔、hook 6 → 3 支、移除 `/dev:overview`。因果鏈 hook 收窄為只擋既有原始碼檔、訊息改走 stderr、不依賴 python。理由見 `design/15-v8-slim.md` |
| v7.x | workflow-first 重構、Windows 相容、handoff 強化 |
| v6.x | Karpathy 行為哲學、認知驗證、KPI、對照範例 |
| v5.x | 五階段閉環、hook 系統、agent 專家庫、自動更新 |
