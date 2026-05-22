# 開發設計閉環

## LLM 編碼的根本問題

[Andrej Karpathy 觀察](https://x.com/karpathy/status/2015883857489522876)：

> "The models make wrong assumptions on your behalf and just run along with them without checking. They overcomplicate code and APIs. They sometimes change/remove comments and code they don't sufficiently understand as side effects."

本專案發現的進階問題：
- **跨產出物矛盾**：設計說 5 種錯誤、實作 3 種、測試 2 種——傳統 Code Review 抓不到
- **認知前提誤判**：基於單一線索就斷言為事實（GS 誤判事件，問題追蹤 #003-#005）

本方法論是針對這兩層問題的解法：Karpathy 4 原則處理「行為紀律」，閉環方法論處理「跨產出物驗證」。

## ⚖️ Trade-off 宣告

本方法論偏向**正確性與可追溯性 > 速度**。微小任務不走閉環（直通保護），中型任務多花 ~30% 時間在設計/審查，大型任務多花 ~50-80%。換來的是跨產出物矛盾在 commit 前被攔截、認知誤判有三層防禦、失敗模式自動累積避開。**不適用於拋棄式 prototype 與緊急 hotfix。**

## 這是什麼

一套軟體開發的品質保證方法。核心概念是：每寫一段程式碼，都要經過五個角色的驗證（架構師 → 程序設計師 → 檢核師 → 測試師 → 自證師），最後由自證師確認所有產出物之間沒有矛盾，才算完成。

## 文件結構

這個目錄分成兩個部分：

### 實作（拿去用的）

| 文件 | 說明 |
|------|------|
| `CLAUDE_TEMPLATE.md` | CLAUDE.md 自包含模板（含 Agent 調度規則、閘門、學習日誌、活動日誌、Task 可見性） |
| `.claudedocs/` | 技術文檔（11 核心 + 9 agent prompt + 5 anti-pattern 範例），給人類閱讀 |
| `.claudedocs/agents/` | Agent 專家庫（8 個專家 prompt），Phase 觸發時按需載入 |
| `.claudedocs/languages/` | 語言 Skills（6 語言：TS/Py/Go/Rust/C#/Bash），部署時只複製偵測到的語言 |
| `skill/init-claude.md` | Skill 源碼（由 setup.sh 部署到 `~/.claude/commands/dev/`） |
| `skills/dev:handoff/` | 配套 Skill（跨 session 交接，由 setup.sh 部署到 `~/.claude/skills/dev:handoff/`，等價 `wt:handoff`） |
| `hooks/` | 6 個 Hook 腳本（修改守衛、委派前閘門、理解確認、增量 lint、委派追蹤、學習日誌提醒） |
| `deploy-hooks.sh` | 一鍵部署 Hook 系統（複製腳本 + 合併 settings.json + 驗證） |
| `check-version.sh` | 版本檢查工具（快取/部署/遠端一次比完，輸出 key=value） |

### 設計歷史（了解這套方法怎麼來的）

| 文件 | 說明 |
|------|------|
| `design/01_原始構想.md` | 最初的閉環設計想法，包含 9 個角色、4 個層級 |
| `design/02_深度分析.md` | 對原始構想的問題分析和改進方向 |
| `design/03_落地路線圖.md` | 5 個 Phase 的執行計畫 |
| `design/04_Skill設計規劃.md` | `dev:init-claude` Skill 的設計藍圖 |
| `design/05-research-methodology-analysis.md` | 方法論比較分析 |
| `design/06-analysis-deep-review.md` | 方法論深度檢討 |
| `design/07-research-project-orchestrator.md` | 專案協調者研究 |

## 使用方式

最簡單的方法是裝好 Skill 後直接跑指令：

```
/dev:init-claude          ← 部署閉環到專案
/dev:init-claude status   ← 查看部署狀態
/dev:init-claude upgrade  ← 從 GitHub 下載最新版
```

安裝方式見根目錄 README。

手動部署也可以：複製 `CLAUDE_TEMPLATE.md` + `.claudedocs/` 到專案根目錄，改名為 `CLAUDE.md`，替換所有 `{{PLACEHOLDER}}`。

## .claudedocs 目錄結構

```
.claudedocs/
├── README.md               ← 閱讀順序指南
├── agents/                 ← Agent 專家庫（8 個專家 prompt）
│   ├── README.md
│   ├── requirements-analyst.md  ← 需求探索
│   ├── architect.md             ← Phase 1 設計
│   ├── design-reviewer.md       ← Phase 1b 設計審查
│   ├── implementer.md           ← Phase 2 實作
│   ├── code-reviewer.md         ← Phase 3 品質審查
│   ├── security-reviewer.md     ← Phase 3 安全審查
│   ├── tester.md                ← Phase 4 測試
│   └── verifier.md              ← Phase 5 雙向追溯
├── concepts/
│   └── 閉環核心理念.md      ← 這套方法在幹嘛、為什麼有用
├── process/
│   ├── 五階段閉環流程.md     ← 實際怎麼跑，每個階段做什麼
│   ├── 層級擴展.md          ← 從函式到模組到框架怎麼串
│   ├── 跨Session持久化.md   ← 大型專案怎麼跨 Session 保存狀態
│   └── 介面契約與變更管理.md  ← 跨模組 API 怎麼定義和追蹤變更
├── standards/
│   ├── Agent使用指南.md      ← 每個階段該用什麼工具
│   ├── Git工作流.md          ← 閉環跟 Git 怎麼配合
│   └── 產出物格式.md         ← 每個階段要交什麼東西
├── records/
│   └── 問題追蹤.md           ← 遇到問題怎麼記錄
└── languages/               ← 語言特定指南
    ├── README.md
    ├── typescript.md
    ├── python.md
    ├── go.md
    ├── rust.md
    ├── csharp.md
    └── bash.md
```

## 閱讀建議

- 想**了解背景**：從 `design/01_原始構想` → `design/02_深度分析` → `design/03_落地路線圖` 讀
- 想**直接用**：從 `CLAUDE_TEMPLATE.md` 開始，搭配 `.claudedocs/` 裡的文檔
- 想**看閱讀順序**：看 `.claudedocs/README.md`

## 版本歷史

| 版本 | 重點 |
|------|------|
| **v6.4.0** | **升格降級機制 + 紀律保底層**（補強計劃 §13 候選 A+E 捆綁採納 · 完整 5-Phase 閉環實作 · 2026-05-20）——候選 A（升格機制對稱降級）：問題追蹤.md 新增「降級機制」section（n=10 個閉環無新證據 → ⏸️ 條件式降級 / 2n=20 → 🗄️ archive / 復發 m=5 ≥ 2 次命中自動升回）+「條件式紀律」+「歷史條目」3 sections + verifier.md step 9d「降級候選掃描」+ architect.md 步驟 1.a 加 ⏸️ 條件式標記識別 + CLAUDE_TEMPLATE Phase 5 + 精簡 4.5 升格段對稱補降級。候選 E（5 條反向劃線）：CLAUDE_TEMPLATE Section 13.5「反向劃線」R-1 閘門不可 bypass / R-2 cross-source review 是 hard requirement（機械化觸發：方法論文件變動或重大認知性產出）/ R-3 升格降級不可 bypass / R-4 架構體質 + 合理性自檢不可省略 / R-5 連續 ≥ 2 次 needs-attention 強制降級 scope（呼應 #007）+ 閉環核心理念.md 新增「升格-降級機制」+「紀律保底層」兩段（含 R-1~R-5 對映表）。**P1b 0 high / 2 arch-risk（緩衝邊界 / YAGNI 邊緣）/ 5 medium 全採 in-place**：DR-1 緩衝邊界（574/580 緩衝 6）/ DR-2 用戶選接受全量 / DR-3-7 全補。**全 repo 淨 +85 行 / 5 檔變動** / CLAUDE_TEMPLATE 547→574 |
| **v6.3.x infrastructure-patch** | **infrastructure 補強 + 公開發佈友善度**（不 version bump · 來源 2026-05-04 cc_recommand vs codex 跨視角評估揭露的補強需求）——新增 `tests/` 套件（run.sh Phase A shellcheck + Phase B 7 smoke + lib/assert + lib/fixtures + 寬鬆模式 pre-commit · 11 檔 39 sub-checks）含三條回歸防線：cross-file-consistency（防 codex 揭露的跨檔數字 / 依賴 / 版本不一致）/ hooks-isolation（防階段 2-1 marker 跨專案污染回歸）/ setup-remote-sha（防階段 2-2 SHA tracking 回歸）+ test-bash-compat 第一次跑就抓到 4 處我自己違反 `${VAR}` 大括號規則的 bash 3.2 全形括號陷阱（self-dogfooding）+ setup.sh 加 `SETUP_TARBALL_URL` / `SETUP_SHA_URL` env var override 供測試 mock（純 additive，預設值不變）+ README / README.en.md 加平台支援表 + 遠端 `curl` 安裝安全考量段（3 替代方案 + setup.sh 行為邊界透明）+ CLAUDE_TEMPLATE Section 12/12.5/13 **純壓縮** 566→547 行（移 3 處對稱性重複 + bullet → inline；架構名稱與 cross-ref 不變，依賴表第 8 列不觸發 sync · 維持認知驗證層留主檔的 v5.23/v6.2 設計意圖）+ learning-log 補 2 條 single-source 盲點事件 + #007 升格候選追蹤段（2/3 樣本 · 禁止跳過第 3 次直接升格）|
| **v6.3.x dogfooding-1 patch** | **方法論補強**（不 version bump · 來源 dogfooding 試煉 retrospective）——CLAUDE_TEMPLATE Section 1.5 微小任務探索成本上限（4 條規則防 T1「找 typo」探索成本失控盲點）+ 配額管理主動降級判定點（≥ 70% 配額即降級）+ design-reviewer 步驟 4.5 BC↔健康路徑階層對齊審查 + tester 跨平台環境前置檢查（msys2 chmod 失效應 skip 不誤報）+ KPI baseline 附錄擴 dogfooding T1/T2 兩列（累積 6 ≥ 5 校準門檻）+ 新增 design/12 v7 校準起點（含 §8 5 個缺口提醒）|
| **v6.3.0** | **對照範例庫**（Karpathy 1 條 K-x · K-13 緩議）——BC-1（K-07）新增 `.claudedocs/examples/` 目錄含 5 個 anti-pattern 對照檔案（仿 Karpathy EXAMPLES.md 形式）：01-think-before-coding（Q1 Think 違反 · 默默選一種解讀）/ 02-simplicity-first（Q2 Simplicity · Strategy pattern 處理單一計算）/ 03-surgical-changes（Q3 Surgical · 修 typo 順手 reformat）/ 04-goal-driven-execution（Q4 Goal · 我先 review 再改善）/ 05-cross-artifact-mismatch（閉環特色 · 設計實作測試對齊缺失）。每檔 5 段結構（場景 / 錯誤示範 / 原則診斷 / 修正版本 / 關鍵限制）共 482 行內容。setup.sh EXPECTED_FILES 12→17，部署到目標供 reviewer / architect 按需查閱。**P1b 0 high / 2 arch-risk / 2 medium / 1 low — 不觸發回退**：DR-1（design/10 與 P1 的 migration-notes-v6.3 分歧）+ DR-3 跨 4 處 v6.3.0 + setup.sh 條件式 + DR-5 行數 prose/code 比例皆採納；DR-2 K-x 變動需同步 examples/ + DR-4 緩衝零容錯入 RISK-8/RISK-9。**K-13（自循環模式）緩議**到 K-07 完成後 brainstorm（4 個未解的狀態機問題）。CLAUDE_TEMPLATE 行數無變動（保持 540 行，沿用 #006 預防做法）|
| **v6.2.0** | **認知對稱性 + 運作指標**（Karpathy 3 條 K-x）——BC-1（K-14）Section 12.5 第 5 條從觸發點展開為完整反向質疑協議（5.1 4 條觸發場景 + 5.2 反向質疑輸出格式 + 5.3 對稱性表 + 5.4 解除條件分支處理「OK 不能跨越事實質疑代價差」）+ standards Push back 重組為兩變體（變體 1 = 1-4 條方案爭議 / 變體 2 = 第 5 條事實前提質疑）+ concepts「主動質疑」段擴為三方對稱表（Claude→自己 / Claude→用戶 / 用戶→Claude）+ BC-2（K-10）standards 開頭新增 ID ↔ 失誤類型對應表（7 列 BC/EH/R/R-style/DR/IF/CR × 4 欄常見/邊界 failure_type）+ BC-3（K-11）新增 `concepts/方法論運作指標.md`（精簡 3 指標 = DR-x high / R-x high / 升格觸發次數 + 三區間門檻健康/警示/危險 + 觀察期校準至 v7）+ BC-4 跨檔同步（CLAUDE_TEMPLATE migration-notes-v6.2 + setup.sh EXPECTED_FILES 11→12 + .claudedocs/README 第 12 項閱讀順序）。**P1b 採納 DR-1 high 修正**（concepts 緩衝 0→10 行）+ DR-3-DR-7 全採（5.4 分支處理 / standards 變體重組 / BC-4 兩段式驗收 / K-10 表壓 ≤ 18 行）+ DR-2 arch-risk 入 RISK-9（量測義務推 v6.3.0）。**精簡閉環 dogfooding**：六步流程含 P1b 1 high 觸發回退修正後通過 |
| **v6.1.0** | **執行細節打磨**（Karpathy 6 條 K-x）——BC-1（K-02）資深工程師審視（設計自檢第 7 問 + architect Step 8 + design-reviewer 步驟 2）+ BC-2（K-03）3x rule 重寫觸發（architect 末尾新增實作規模估算與重寫條件）+ BC-3（K-05）Dead Code 立場 Section 11.5（採 Karpathy「mention but don't delete」+ code-reviewer anti_pattern）+ BC-4（K-06）R-style 獨立子類別（code-reviewer 步驟 5.5 + 產出物格式 R-x 編號表）+ BC-5（K-08）Goal 轉換 architect 步驟 1.5（命令式→可驗證目標對照表 + CLAUDE_TEMPLATE 步驟 1 補句）+ BC-6（K-16）Anti-Patterns Summary 對照表（閉環核心理念末尾，仿 Karpathy EXAMPLES.md）。**精簡閉環 dogfooding**：六步流程含 P1b 6 條 DR 全採用 / P3 0 high/medium/low（淨）/ P4 4/4 部署驗證。CLAUDE_TEMPLATE 510→520 行（預算 525） |
| **v6.0.0** | **Karpathy 行為哲學整合**——CLAUDE_TEMPLATE Section 0「四原則橫切自檢層」（Q1 Think / Q2 Simplicity / Q3 Surgical / Q4 Goal cross-cutting，對映既有 Section 9-12.5 閘門）+ Section 12.5「Push back 義務」（5 條觸發場景白名單，含「用戶事實前提待驗證」與 Section 12 對稱）+ 開頭「⚖️ Trade-off 顯式宣告」+ 兩處 README 加 Karpathy 引用問題陳述 + IF-1 `migration-notes` metadata（list of objects + position 屬性，連接方法論文檔層 ↔ Skill 部署層）+ `skill/init-claude.md` 加 v5.x→v6.0.0 智能合併 migration logic（策略 A 全替換 / B 智能合併 / C 手動 diff）。**定位升級**：實作 + 認知方法論 → **實作 + 認知 + 行為哲學**（LLM 對用戶的義務明確）。源起於 [forrestchang/andrej-karpathy-skills](https://github.com/forrestchang/andrej-karpathy-skills) 4 原則整合 |
| v5.23.1 | 認知驗證層 P2（完整閉合）——design-reviewer 步驟 5c「Falsification Check」（對設計規格引用的環境事實做反例提問 + 證據等級檢查 + 共用值檢測回溯，弱證據 DR-x medium，反例未通過 DR-x high）+ verifier 步驟 9c「事實前提追溯」（Phase 1b Step 5c 的下游把關，產出 `.claude-loop/artifacts/P5-fact-claims.md`，V-10 嚴重度映射回退規則）+ AI-ClaudeCode/CLAUDE.md 依賴表追加「認知驗證層」+「`.claudedocs/agents/*`」兩列。三層防禦（上游 Step 0a/0b → 中游 Section 12/13 → 下游 Step 5c + 9c）完整閉合 |
| v5.23.0 | 認知驗證層 P1——CLAUDE_TEMPLATE Section 12「事實主張閘門」（觸發場景 + A/B 級證據 + 反例檢查 + 共用值檢查 + 強/中/弱決策 + evidence_level memory 標注）+ Section 13「質疑熔斷協議」（4 條白名單句式強制熔斷 + 5 步重審必做 + 污染清理）+ 閉環核心理念新增「認知驗證」三層防禦說明 + 五階段閉環流程 Phase 1 加入 Step 0a/0b 觸發引用 + 產出物格式新增「事實主張閘門」結構化表格。**定位升級**：從「實作方法論」擴展為「認知 + 實作方法論」，`/sc:analyze /sc:troubleshoot` 類分析任務也可走同一閉環 |
| v5.22.3 | 認知驗證層 P0——architect Step 0a 字面證據掃描（檔名 token + docstring + echo/print 字串，A 級優先於推論）+ Step 0b 共用值檢測（N≥3 強烈共用訊號，防止把共用資源私有化推論）+ 問題追蹤 3 條認知性種子條目（#003 單線索→事實 / #004 忽視字面證據 / #005 共用值私有化）+ learning-log 新增 `[事實誤判]` 事件類型。**P1/P2 待補**：事實主張閘門 + 質疑熔斷協議 + Phase 5 事實前提追溯。源起於 GS 誤判事件（2026-04-22 外部經驗反思） |
| v5.22.2 | 為實戰驗證建立證據面——learning-log 事件條目新增 `failure_type` 4 類欄位（process_failure / judgment_failure / verification_failure / tooling_failure，按因果順序排列）+ 模式分析格式增加 failure_type 分布表（哪類佔比高決定下一版優化方向）+ 新增 `process/實戰驗證流程.md` retrospective 模板（含主觀規則疲勞調查欄）。**純工具升級，不動任何 phase 規則行為**——目的是讓下一版方法論升級從直覺驅動轉為證據驅動 |
| v5.22.1 | 升格機制覆蓋擴大——design-reviewer 步驟 5b 學習查詢執行檢查（架構獨立性原則：主 agent 自我約束的關鍵動作需獨立 reviewer 把關）+ 精簡閉環迷你追溯加入升格檢查（主 agent 自做掃描+AskUserQuestion+寫入，跟完整閉環 verifier sub-agent 分工不同；理由：日常 80-90% 為精簡閉環，learning-log 累積主要在此，不能只在完整閉環觸發升格） |
| v5.22.0 | 兩層教訓架構——`learning-log.md` 短期工作記憶 + `問題追蹤.md` 長期警惕模式 + 升格機制（同類根因 ≥ 3 次 + Phase 5 verifier 偵測候選 + 主 agent AskUserQuestion 確認 + 升格寫入並標記）+ architect Phase 1 必讀長期模式 + reel_core 案兩條種子條目（絕對負面陳述需證據 / existence-vs-routing 框架錯置） |
| v5.21.1 | 術語修正——「自証」→「自證」（繁中正寫），跨 23 個活檔案統一替換 105 處（design/ 設計歷史保留原始術語作為時間快照） |
| v5.21.0 | 防轉述遺漏——設計規格持久化為 `P1-design-spec.md`（必須，不再是建議）+ 4 個 task agent 改為路徑模式（Sub-Agent 直接 Read 原始產出物，主 agent 不轉述內容）+ input_contract 每項標明讀取方式 + 路徑完整性校驗 |
| v5.20.0 | 反偷懶三措施——因果鏈呼叫者逐條展開（格式強制每個 grep 結果分析影響）+ Phase 5 行為路徑枚舉前置（建立反向分析分母）+ 跨 Phase 一致性驗證（R-x 數 vs 未覆蓋路徑數交叉比對） |
| v5.19.0 | 因果鏈分析第 6 條「呼叫者存在性」——修改函式前 grep 確認呼叫者，呼叫者=0 禁止修改 + tester 行為變化驗證 edge case + verifier 修改點存在性檢查 |
| v5.18.0 | Hook 系統修正 + 委派前閘門——因果鏈 marker 每輪重置 + 短指令偵測擴充 + delegation-gate.sh（修改型 Agent 委派前強制因果鏈分析） |
| v5.17.1 | 升級系統 SHA 追蹤——下載時記錄 commit SHA + 版本同但 SHA 異時警告 + status 顯示 SHA |
| v5.17.0 | Agent 調用精確化——自文檔化調用方式 + 活動日誌 + learning-log agent 標籤 + Task activeForm + 斷點回退可見性 |
| v5.16.0 | 回顧式學習自動化——失敗驅動學習日誌 + 模式分析 + PostToolUse Hook 檢查 |
| v5.15.0 | 精簡閉環迷你追溯（步驟 4.5）+ CLAUDE_TEMPLATE 認知負荷降低（606→361 行，-40%） |
| v5.14.0 | Agent 專家庫（8 個自包含 agent prompt），方法論自包含無外部依賴 |
| v5.13.0 | 全 Hook 阻擋式升級：因果鏈守衛 + 理解確認守衛均為 block 機制（雙閘門合併阻擋） |
| v5.12.0 | 理解確認守衛 Hook + 全 Hook 橙色可見性（防不對頻，用戶輸入即觸發理解確認） |
| v5.11.0 | 同類掃描（修改時橫向掃描同類項目，避免只修冰山一角） |
| v5.10.1 | 模板瘦身：子 agent prompt 移至 .claudedocs，模板 512→448 行（-12.5%） |
| v5.10.0 | 架構體質拆解（第一性原理：設計前拆解現有架構假設，審查架構擴展能力） |
| v5.9.0 | 合理性審查（Phase 1 自檢 + Phase 3 審查維度 + 非閉環通用規則） |
| v5.8.0 | 因果鏈分析可見性 + 深度規則（畫面輸出推導過程，穿透呼叫鏈/語意/時序/邊界） |
| v5.7.0 | 自動更新系統 + 三位數版本制（curl 安裝、upgrade 模式、GitHub 版本偵測） |
| v5.6.0 | 因果鏈守衛 Hook（修改前自動提醒做影響分析） |
| v5.5.0 | 領域偵測、架構風險嚴重度、Phase 5 雙向合併、測試分層 |
| v5.3.0 | 委派追蹤 Hook（Agent 呼叫自動記錄） |
| v5.2.0 | 委派產出物強制寫入 .claude-loop/artifacts/ |
| v5.1.0 | 依賴影響分析規則 |
| v5.0.0 | 獨立子 agent 架構 + PRD 需求分解 + 增量驗證 Hook |
| v4.0 | Gen 3 重寫（601→185 行）+ 升級機制 |
| v3.x | Skill 系統、跨 Session 持久化、介面契約、claude-mem 整合 |
