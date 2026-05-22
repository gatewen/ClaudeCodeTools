# ClaudeCodeTools

讓 Claude Code 寫出更可靠的程式碼。

> **定位**：個人 hardcore 修煉工具——對自己嚴格的閉環方法論，不適合直接套到團隊。給用戶的 cognitive overhead 已被任務分流屏蔽，日常 80% 工作不會被打擾（見下方「微小任務直通保護」）。
>
> **公開狀態**：repo 公開可 fork / 學習 / 自用，但**未主動推廣**——不承諾外部支援、不主動接受功能 PR、issue 視作者時間回應。如果發現 bug 或想討論方法論，歡迎開 issue 但不保證 SLA。**MIT 授權**（見根目錄 `LICENSE`）。
>
> **English version** → [README.en.md](README.en.md) · **30-min quick start** → [dev-closed-loop/QUICKSTART.md](dev-closed-loop/QUICKSTART.md)

## LLM 編碼的根本問題

[Andrej Karpathy 觀察](https://x.com/karpathy/status/2015883857489522876)：

> "The models make wrong assumptions on your behalf and just run along with them without checking. They overcomplicate code and APIs. They sometimes change/remove comments and code they don't sufficiently understand as side effects."

本專案發現的進階問題：
- **跨產出物矛盾**：設計說 5 種錯誤、實作 3 種、測試 2 種——傳統 Code Review 抓不到
- **認知前提誤判**：基於單一線索就斷言為事實（GS 誤判事件，問題追蹤 #003-#005）

本工具包是針對這兩層問題的解法：Karpathy 4 原則處理「行為紀律」，閉環方法論處理「跨產出物驗證」。

---

這個工具包的核心是「開發設計閉環」——一套品質保證方法。簡單來說，每段程式碼都會經過五個角色的檢查（架構師 → 程序設計師 → 檢核師 → 測試師 → 自證師），最後由自證師確認所有產出物沒有矛盾，才算完成。

裝好之後，你只要在專案目錄裡跑一行指令，Claude Code 就會自動按照這套流程工作。

## 微小任務直通保護（你日常 80% 的工作不走閉環）

不是每件事都會被「閉環」拖慢。系統內建三段任務分流：

| 任務等級 | 條件 | Claude 怎麼做 |
|---------|------|------------|
| **微小** | < 50 行 / 單檔修改 / 設定調整 / 你說「快速修改」 | **直通** — 直接寫，無閉環 overhead |
| **中型** | 1-3 檔案 / < 300 行 / 新增單一函式或元件 | 精簡六步閉環（設計 → 設計快審 → 實作 → 品質審 → 測試 → 迷你追溯） |
| **大型** | ≥ 3 檔案 / ≥ 300 行 / 新模組或多子系統 | 完整 5-Phase 閉環（含獨立子 agent 委派） |

**結果**：修個 typo / 改個 config / 補個 type hint 不會啟動閉環。閉環只在「值得保護的工作量」上 pay 成本。判定規則由 CLAUDE.md `Section 1` 定義，不靠 AI 自由心證。

> 進一步了解任務分流場景 → [dev-closed-loop/QUICKSTART.md](dev-closed-loop/QUICKSTART.md)

## 安裝

打開終端機，貼上這行：

```bash
curl -sL https://raw.githubusercontent.com/gatewen/ClaudeCodeTools/main/setup.sh | bash
```

這會自動下載所有檔案到 `~/.claude/cache/ClaudeCodeTools/`，並把 Skill 部署好。

> **開發者？** 也可以用 `git clone https://github.com/gatewen/ClaudeCodeTools.git && cd ClaudeCodeTools && bash setup.sh`

### 平台支援

| 平台 | 支援等級 | 說明 |
|------|---------|------|
| **macOS** | ✅ 主要支援 | 開發 / 測試環境，每次發版前跑過完整 smoke 套件（`bash tests/run.sh`）|
| **Linux** | ⚠️ Best effort | 大部分功能應可運作，但無 Linux 專屬測試。遇問題請開 issue |
| **Windows** | ❌ 不直接支援 | 需透過 WSL2（在 WSL 內視為 Linux）。原生 cmd / PowerShell 不支援 |

執行依賴：`bash 3.2+`（macOS 預設）/ `python3` / `git` / `curl`。

### 🛡️ 關於 `curl | bash` 的安全考量

直接 pipe 到 bash 表示**沒有事先檢視程式碼的機會**。如果信任度不足，建議改用以下其一：

**方案 A（推薦）：先看再執行**

```bash
curl -sL https://raw.githubusercontent.com/gatewen/ClaudeCodeTools/main/setup.sh -o /tmp/setup.sh
less /tmp/setup.sh           # 看一下做了什麼
bash /tmp/setup.sh
```

**方案 B：git clone 後本地安裝**

```bash
git clone https://github.com/gatewen/ClaudeCodeTools.git
cd ClaudeCodeTools
bash setup.sh                # 可先 less setup.sh
```

**方案 C：釘住特定 commit SHA**（極度謹慎場景）

```bash
SHA=$(curl -sL https://api.github.com/repos/gatewen/ClaudeCodeTools/commits/main | grep '"sha"' | head -1 | sed 's/.*"sha": *"//;s/".*//')
echo "Pinning to ${SHA}"
curl -sL https://raw.githubusercontent.com/gatewen/ClaudeCodeTools/${SHA}/setup.sh | bash
```

> setup.sh 約 350 行。主要動作：下載 tarball、解壓到 `~/.claude/cache/`、複製 1 個 markdown 檔到 `~/.claude/commands/dev/`、印驗證結果。**不**修改 PATH、不寫 cron、不裝額外軟體。

### 前置依賴

閉環自帶 Agent 專家庫（`agents/` 9 檔 = 8 個 agent prompt + 1 個 README 索引），**不依賴外部工具**即可完整運作。Task agent（`code-simplifier` 等）是 Claude Code 內建功能。

以下是可選的增強工具，有的話體驗更好，沒有也不影響閉環流程：

| 工具 | 做什麼用的 | 怎麼裝 |
|------|-----------|--------|
| **SuperClaude** _(可選)_ | `sc:*` 系列分析 / 設計 / 改進指令 | `pipx install superclaude && superclaude install` |
| **Superpowers** _(可選)_ | `superpowers:*` 系列 TDD / debugging skills | Claude Code 插件：`superpowers@claude-plugins-official` |
| **claude-mem** _(可選)_ | 跨對話的語義記憶（Phase 前查歷史決策、Phase 後保存教訓） | Claude Code 插件：`claude-mem` |

## 使用

安裝完成後，在任何專案目錄開 Claude Code，輸入：

```
/dev:init-claude
```

它會自動偵測你的專案（語言、框架、測試指令等），問你確認後，把閉環的 CLAUDE.md 和文檔部署到專案裡。之後 Claude Code 每次啟動都會自動遵循閉環流程。

### 其他指令

| 指令 | 做什麼 |
|------|--------|
| `/dev:init-claude status` | 看目前的部署狀態、版本、健康度 |
| `/dev:init-claude upgrade` | 從 GitHub 下載最新版，一鍵升級 |
| `/dev:init-claude uninstall` | 把閉環從專案移除 |

## 更新

不用手動 pull。直接在 Claude Code 裡跑：

```
/dev:init-claude upgrade
```

它會從 GitHub 抓最新版本到快取，更新 Skill，然後引導你升級目前的專案。

> 用 git clone 安裝的人也可以照傳統方式：`git pull && bash setup.sh`

## 閉環是怎麼運作的

每次開發一個功能，Claude 會自動跑五個階段：

```
Phase 1  架構師    寫設計規格，定義介面和測試策略
Phase 2  程序設計師  照規格寫程式碼，寫完自動跑 code-simplifier 優化
Phase 3  檢核師    逐行檢查程式碼是否符合規格，產出審查報告
Phase 4  測試師    跑測試、驗證效能，產出測試報告
Phase 5  自證師    交叉比對前四個階段的產出物，找出矛盾
```

Phase 5 是這套方法的特色——它用編號系統（BC-x / EH-x / R-x）精確追溯每個宣稱，確保設計、程式碼、審查報告、測試報告之間完全一致。

### 自動化 Hook

部署時會一起裝六個 Hook，在背景自動幫你做品質把關：

| Hook | 什麼時候觸發 | 做什麼 |
|------|------------|--------|
| **修改前統一守衛** | 修改檔案之前 | **阻擋**修改，雙閘門：①理解確認（對頻）②因果鏈分析（影響評估），合併為一次 block |
| **委派前因果鏈閘門** | 呼叫 Agent 之前 | **阻擋**修改型 Agent 委派，要求先分析預期修改範圍和影響 |
| **理解確認旗標** | 用戶提交指令時 | 偵測修改意圖，設定旗標 + 清理因果鏈/委派閘門 marker |
| **增量驗證** | 修改檔案之後 | 自動對改過的檔案跑 lint |
| **委派追蹤** | 呼叫 Agent 之後 | 自動記錄 Agent 的任務和結果 |
| **學習日誌提醒** | git commit 之後 | 檢查 learning-log.md 是否在 commit 中，未包含則提醒 |

## 目錄結構

```
ClaudeCodeTools/
├── README.md                         ← 你在看的這個
├── CLAUDE.md                         ← 給 Claude Code 看的 repo 指引
├── setup.sh                          ← 安裝腳本（支援 curl 遠端 + 本地雙模式）
└── dev-closed-loop/
    ├── CLAUDE_TEMPLATE.md            ← 閉環模板（核心產物）
    ├── skill/
    │   └── init-claude.md            ← /dev:init-claude 指令的源碼
    ├── skills/
    │   └── dev:handoff/              ← /dev:handoff 配套 Skill（跨 session 交接，等價 wt:handoff）
    ├── deploy-hooks.sh                ← 一鍵部署 Hook 系統（腳本保證，不靠 AI 自律）
    ├── check-version.sh              ← 版本檢查工具（快取/部署/遠端一次比完）
    ├── hooks/
    │   ├── impact-analysis-guard.sh  ← 修改前統一守衛（雙閘門阻擋）
    │   ├── delegation-gate.sh        ← 委派前因果鏈閘門（修改型 Agent 阻擋）
    │   ├── prompt-understanding-guard.sh ← 理解確認旗標 + marker 清理
    │   ├── incremental-lint.sh       ← 增量驗證
    │   ├── delegation-tracker.sh     ← 委派追蹤
    │   └── learning-log-checker.sh   ← 學習日誌提醒
    ├── .claudedocs/                  ← 給人看的技術文檔
    │   ├── agents/                   ← Agent 專家庫（8 個 agent prompt + 1 索引 README，共 9 檔）
    │   ├── concepts/                 ← 核心理念
    │   ├── process/                  ← 流程說明
    │   ├── standards/                ← 工具和格式規範
    │   ├── records/                  ← 問題追蹤
    │   └── languages/               ← 語言指南（TS/Py/Go/Rust/C#/Bash）
    └── design/                       ← 設計歷史（01-07），了解方法怎麼演變的
```

## 支援的語言

部署時會自動偵測你的專案語言，載入對應的語言指南：

| 語言 | lint 指令 | 完整驗證序列 |
|------|----------|------------|
| TypeScript | `npx tsc --noEmit && npx eslint src/` | tsc + eslint + vitest + build |
| Python | `ruff check src/` | mypy + ruff + pytest |
| Go | `go vet ./... && golangci-lint run` | vet + lint + build + test |
| Rust | `cargo clippy -- -D warnings` | fmt + clippy + build + test |
| C# | `dotnet build --warnaserrors` | format + build + test |
| Bash | `shellcheck *.sh` | syntax + shellcheck + bats |

沒有對應語言指南的專案也能用——只是少了語言特定的 lint 規則，閉環流程一樣會跑。

## 版本歷史

| 版本 | 重點 |
|------|------|
| **v6.4.1** | 散佈基礎建設 patch：新增 `dev:handoff` 配套 Skill（跨 session 交接）—— 從個人版 `wt:handoff` fork 為等價版本，隨方法論一鍵部署到 `~/.claude/skills/dev:handoff/`。功能與 wt:handoff 等價（三層分工 + cwd 路徑判定 + auto_merge 衝突處理 + TaskList 雙向同步），未來可能加 methodology-aware 增強（phase 進度 / 升格 status / learning-log 摘要等），Phase 2 觸發後決定。setup.sh +30 行部署與驗證，CLAUDE_TEMPLATE 不動，DR-1 緩衝邊界 580/580 維持 |
| **v6.4.0** | 兩件加強：(1) 升格機制變對稱 — 跨閉環高頻問題升格成「永久警惕」後，若 10 個閉環沒新證據會自動降到「條件式紀律」（觸發條件命中才適用），降到無人問津 20 個閉環會 archive；條件式條目若 5 個閉環內 2 次命中會自動升回（防誤判降級）。意義：升格條目不再永久膨脹，方法論教訓清單會自我清理。(2) 5 條「反向劃線」（紀律保底層）— 當自治判斷 + 機械化都失效時，5 條規則任何情況下不可 bypass，包括「重大方法論修改強制 cross-source review」（呼應 #007 升格教訓：single-LLM 自評漏看率 50-67%）。意義：劃出「自治可繞、機械化可關，但這 5 條不行」的紅線 |
| **v6.3.x infrastructure-patch** | 公開發佈友善度提升 + dogfooding 帶出的回歸防線：(1) 新增 `tests/` 7 smoke 自動防回歸（cross-file 一致性 / hook 跨專案 marker 隔離 / setup.sh 遠端 SHA tracking · 39 sub-checks · 寬鬆模式 pre-commit）(2) README 加平台支援表（macOS 主要 / Linux best effort / Windows 需 WSL）+ 遠端 `curl` 安裝安全考量段（3 替代方案 + setup.sh 行為邊界透明告知）(3) CLAUDE_TEMPLATE Section 12/12.5/13 純壓縮 566→547 行回到預算 (4) learning-log 補 #007「single-source 評估盲點」候選追蹤 2/3 樣本 |
| **v6.3.x dogfooding-1 patch** | 用方法論跑 1 微小 + 1 中型試煉後發現 6 個盲點，全部補上：微小任務不該無止境找 typo（加探索成本上限）/ Claude 在 token 不夠時要主動降級（不要等爆掉）/ 設計時的 BC 條件跟健康路徑要在同一抽象層次 / 跨平台測試環境不支援應 skip 不誤報 / KPI 累積 6 樣本達 v7 校準門檻 / 新增 v7 校準起點文件 |
| **v6.3.0** | 加了 5 個對照範例（如「Claude 默默選一種解讀」「修 typo 順手 reformat 一堆」），讓 review 時可對照查 Claude 是否犯常見錯誤。部署的文檔從 12 個增加為 17 個 |
| **v6.2.0** | 三個強化：(1) 用戶斷言「X 是 Y」當作後續行動前提時，Claude 會反問「我能查到的證據是 Z，要不要先確認」（避免基於錯誤前提行動）；(2) 加「失誤類型速查表」幫人快速判定錯誤是「流程沒走完」還是「判斷錯方向」；(3) 訂 3 個健康指標監測方法論運作（如同類失誤是否反覆出現） |
| **v6.1.0** | 六個執行細節改善：(1) 設計時必問「資深工程師會說過度設計嗎」；(2) 程式碼超合理長度 3 倍時觸發重寫提案；(3) 改 bug 時不順手清理舊有 dead code（採 Karpathy 立場）；(4) style 不一致跟程式碼問題分開記，避免擾亂；(5) 「修 bug」翻譯成「跑 X 測試通過」這種可驗證目標；(6) 加了常見 anti-patterns 速查表 |
| **v6.0.0** | 引入 Karpathy 行為哲學：每個工作階段都先過 4 個自問（我的假設是什麼？能更簡單嗎？只動了該動的嗎？成功的可驗證標準是什麼？）；Claude 在 5 種情境會主動反對用戶（如有更簡單方案、用戶基於弱證據要動、要做的事超出該等級任務範圍）；README 開頭加「⚖️ Trade-off 宣告」明說這方法論偏向正確 > 速度，不適合拋棄式 prototype。源自 [forrestchang/andrej-karpathy-skills](https://github.com/forrestchang/andrej-karpathy-skills) 4 原則 |
| v5.23.1 | 認知驗證層 P2（完整閉合）——design-reviewer 步驟 5c Falsification Check（對設計引用的環境事實做反例提問 + 證據等級檢查 + 共用值檢測，弱證據 DR-x medium / 反例未通過 DR-x high）+ verifier 步驟 9c 事實前提追溯（產出 `P5-fact-claims.md` + V-10 severity 映射）+ AI-ClaudeCode/CLAUDE.md 依賴表 2 新列。三層防禦閉合（上游 Step 0a/0b → 中游 Section 12/13 → 下游 Step 5c + 9c） |
| v5.23.0 | 認知驗證層 P1——CLAUDE_TEMPLATE Section 12 事實主張閘門（A/B 級證據 + 反例檢查 + 共用值檢查 + 強/中/弱決策 + memory `evidence_level` frontmatter）+ Section 13 質疑熔斷協議（4 條白名單句式強制熔斷 + 5 步重審）+ 閉環核心理念新增「認知驗證」三層防禦概念 + 產出物格式新增事實主張閘門結構化表格。定位升級：從實作方法論擴展為認知 + 實作方法論，`/sc:analyze`、`/sc:troubleshoot` 類分析任務可走同一閉環 |
| v5.22.3 | 認知驗證層 P0——architect Step 0a 字面證據掃描（檔名 token / docstring / echo-print 字串，A 級優先於推論）+ Step 0b 共用值檢測（N≥3 強烈共用訊號，防止把共用資源私有化推論）+ 問題追蹤 3 條認知性種子（#003 單線索→事實 / #004 忽視字面證據 / #005 共用值私有化）+ learning-log 新增 `[事實誤判]` 事件類型。源起於 GS 誤判事件經驗反思 |
| v5.22.2 | 為實戰驗證建立證據面——learning-log 加 `failure_type` 4 類欄位 + 模式分析加類型分布 + 新增 `實戰驗證流程.md` retrospective 模板（含主觀規則疲勞調查）。純工具升級，不動 phase 規則，目的是讓下一版方法論升級從直覺驅動轉為證據驅動 |
| v5.22.1 | 升格機制覆蓋擴大——design-reviewer 步驟 5b 學習查詢執行檢查（補閉環獨立性漏洞）+ 精簡閉環迷你追溯加入升格檢查（主 agent 自做，補日常 80-90% 工作的累積落差） |
| v5.22.0 | 兩層教訓架構——`learning-log.md` 短期工作記憶 + `問題追蹤.md` 長期警惕模式 + 升格機制（同類根因 ≥ 3 次 + Phase 5 verifier 偵測候選 + 主 agent AskUserQuestion 確認 + 升格寫入並標記）+ architect Phase 1 必讀長期模式 + reel_core 案兩條種子條目 |
| v5.21.1 | 術語修正——「自証」→「自證」（繁中正寫），跨 23 個活檔案統一替換 105 處（design/ 設計歷史保留原始術語作為時間快照） |
| v5.21.0 | 防轉述遺漏——設計規格持久化為 `P1-design-spec.md`（必須）+ 4 個 task agent 改為路徑模式（Sub-Agent 直接 Read 原始產出物，主 agent 不轉述） + input_contract 每項標明讀取方式 + 路徑完整性校驗 |
| v5.20.0 | 反偷懶三措施——因果鏈呼叫者逐條展開 + Phase 5 行為路徑枚舉前置 + 跨 Phase 一致性驗證 |
| v5.19.0 | 因果鏈分析「呼叫者存在性」——修改函式前 grep 確認呼叫者，呼叫者=0 禁止修改 |
| v5.18.0 | Hook 系統修正 + 委派前閘門——因果鏈 marker 每輪重置 + 短指令偵測擴充 + 新增 delegation-gate.sh（修改型 Agent 委派前強制因果鏈分析） |
| v5.17.1 | 升級系統 SHA 追蹤——下載時記錄 commit SHA + 版本同但 SHA 異時警告 + status 顯示 SHA |
| v5.17.0 | Agent 調用精確化——自文檔化調用方式 + 活動日誌 + learning-log agent 標籤 + Task activeForm + 斷點回退可見性 |
| v5.16.0 | 回顧式學習自動化——失敗驅動學習日誌（即時捕獲 + commit 前寫入 + Hook 檢查）+ 模式分析 |
| v5.15.0 | 精簡閉環迷你追溯（步驟 4.5 正向覆蓋表）+ CLAUDE_TEMPLATE 認知負荷降低（606→361 行，-40%） |
| v5.14.0 | Agent 專家庫（8 個自包含 agent prompt），方法論自包含無外部依賴 |
| v5.13.0 | 全 Hook 阻擋式升級：因果鏈守衛 + 理解確認守衛均為 block 機制（雙閘門合併阻擋） |
| v5.12.0 | 理解確認守衛 Hook + 全 Hook 橙色可見性（防不對頻，用戶輸入即觸發理解確認） |
| v5.11.0 | 同類掃描（修改時橫向掃描同類項目，避免只修冰山一角） |
| v5.10.1 | 模板瘦身：子 agent prompt 移至 .claudedocs，模板 512→448 行（-12.5%） |
| v5.10.0 | 架構體質拆解（第一性原理：設計前拆解現有架構假設，審查架構擴展能力） |
| v5.9.0 | 合理性審查（Phase 1 自檢 + Phase 3 審查維度 + 非閉環通用規則） |
| v5.8.0 | 因果鏈分析可見性 + 深度規則（畫面輸出推導過程，穿透呼叫鏈/語意/時序/邊界） |
| v5.7.0 | 自動更新系統 + 三位數版本制（curl 安裝、`upgrade` 模式、GitHub 版本偵測） |
| v5.6.0 | 因果鏈守衛 Hook（修改前自動提醒做影響分析） |
| v5.5.0 | 領域偵測、架構風險嚴重度、Phase 5 雙向合併、測試分層 |
| v5.3.0 | 委派追蹤 Hook（Agent 呼叫自動記錄） |
| v5.2.0 | 委派產出物強制寫入 .claude-loop/artifacts/ |
| v5.1.0 | 依賴影響分析規則 |
| v5.0.0 | 獨立子 agent 架構 + PRD 需求分解 + 增量驗證 Hook |
| v4.0 | Gen 3 重寫（601→185 行）+ 升級機制 |
| v3.x | Skill 系統、跨 Session 持久化、介面契約、claude-mem 整合 |

## 想了解更多

- **快速上手**：裝好後直接跑 `/dev:init-claude`，看它怎麼偵測你的專案
- **理解原理**：讀 `dev-closed-loop/.claudedocs/concepts/閉環核心理念.md`
- **看完整流程**：讀 `dev-closed-loop/.claudedocs/process/五階段閉環流程.md`
- **設計歷史**：`dev-closed-loop/design/` 裡有從構想到實作的完整記錄

## License

MIT
