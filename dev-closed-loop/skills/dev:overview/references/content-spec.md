# Content Spec

dev:overview HTML 的所有「給人類看」的文案。Template.html 渲染這些內容；本檔是 source-of-truth 的白話文案。

## 設計原則

1. **白話 + 不出現術語**：BC-x / EH-x / IF-x / DR-x 等技術編號放細節展開內，不出現在 tagline
2. **動詞優先**：「做什麼」用動作開頭
3. **「為什麼」用反向陳述**：「避免 / 抓 / 防止 X 痛點」，讓讀者直覺接到實際問題
4. **長度限制**：tagline ≤ 30 字 / 卡片內每欄 ≤ 60 字 / detail 段落 ≤ 200 字

---

## Hero Section

### Tagline（醒目大標）

> **「開發設計閉環」（Closed-Loop）**
> 讓 Claude Code 跟你協作時走可追溯的五階段流程，
> 不只把程式寫出來，還對自己的產出負責。

### 三卡並排（解決什麼問題 / 給誰用 / 跟普通 Claude 差在哪）

**卡 1：解決什麼問題**

> - 需求講不清楚就直接寫程式
> - 實作偏離原本設計
> - 自己審自己看不見盲點
> - 測試假通過
> - 文件跟程式對不上
> - 換 session 就失憶

**卡 2：給誰用**

> 想要 LLM 協作有品質保證、產出可追溯、跨 session 不失憶的工程師。
>
> 不適合：「快速拋棄式 prototype」「一次性 hack」「不需要可重複的 PoC」

**卡 3：跟普通 Claude 差在哪**

> **普通**：描述需求 → 程式產出
>
> **閉環**：需求 → 規格 → 實作 → 審查 → 測試 → 對齊 → commit（**六個產物全部互相對齊**）

### 4 原則橫切（Hero 底部）

> 動手前先過 4 個自問（橫切每個 Phase）：
>
> - ❓ **Think** — 我假設了什麼？驗證過嗎？
> - ✂️ **Simplicity** — 能更簡單嗎？
> - 🎯 **Surgical** — 只動了該動的嗎？
> - ✅ **Goal** — 成功的可驗證標準是什麼？

### CTA 變體

**Deployed 模式（已部署）**：

> ✓ 你已部署閉環！往下滑看當前狀態 + 進階機制細節 →

**Standalone 模式（未部署）**：

> 💡 還沒部署？一行指令安裝：
>
> ```
> curl -sL https://raw.githubusercontent.com/gatewen/ClaudeCodeTools/main/setup.sh | bash
> ```

---

## §1 五階段閉環（核心 · 預設展開）

### Tagline

> 開發任務不是「直接寫程式」— 走五個專業角色一棒接一棒。每個角色只做一件事，產出可追溯給下一棒，最後一棒檢查大家對得起來。

### 5 個 Phase 卡片內容

每個 phase 卡片預設顯示「編號 + 角色 + 動作」（精簡）；點擊展開「做什麼 / 產出 / 為什麼 / ↗ 深入」。

#### Phase 1 · 架構師 · 設計（indigo）

| 欄位 | 內容 |
|------|------|
| 做什麼 | 把需求「翻譯」成可驗證的設計規格（目標 → 行為條件 → 錯誤處理 → 介面契約） |
| 產出 | 📄 `P1-design-spec.md` |
| 為什麼 | 避免「需求講不清楚就直接寫程式」的常見坑 — 後面 4 棒都靠這個規格對齊 |
| ↗ 深入 | `.claudedocs/agents/architect.md` |

#### Phase 2 · 程式師 · 實作（emerald）

| 欄位 | 內容 |
|------|------|
| 做什麼 | 忠實實作設計規格，過程強制簡化（不寫超出規格的功能） |
| 產出 | 📁 程式碼 + 增量 lint pass |
| 為什麼 | 避免「實作偏離設計」與「越寫越複雜」 |
| ↗ 深入 | `.claudedocs/agents/implementer.md` |

#### Phase 3 · 檢核師 · 審查（violet）

| 欄位 | 內容 |
|------|------|
| 做什麼 | 多面向審查（設計一致性 / 結構安全 / 依賴方向 / 安全性） |
| 產出 | 📄 `P3-quality.md` |
| 為什麼 | 抓「LLM 自己寫自己審」的盲點 — 用獨立 task agent 切斷主執行緒的偏見 |
| ↗ 深入 | `.claudedocs/agents/code-reviewer.md` + `security-reviewer.md` |

#### Phase 4 · 測試師 · 驗證（amber）

| 欄位 | 內容 |
|------|------|
| 做什麼 | 依設計規格設計測試並真的跑（不是「假設應該過」） |
| 產出 | 📄 `P4-deployment-verification.md` |
| 為什麼 | 抓「測試假通過」— 跨平台環境不支援應 skip 不誤報、邊界條件覆蓋 |
| ↗ 深入 | `.claudedocs/agents/tester.md` |

#### Phase 5 · 自證師 · 對齊（rose）

| 欄位 | 內容 |
|------|------|
| 做什麼 | 比對 1-4 棒產出物有沒有矛盾（用 BC-x / EH-x / R-x 編號做精確雙向追溯） |
| 產出 | 📄 `P5AB-bidirectional-tracing.md` |
| 為什麼 | 抓「文字看起來對但對不起來」的隱藏問題 — 設計講了 A 但實作做了 B、測試測了 C |
| ↗ 深入 | `.claudedocs/agents/verifier.md` |

### 視覺特色

- 5 個卡片水平排列，箭頭 → 連接（純視覺不可點）
- 每卡用對應 phase 色 border-top
- 「全部展開」按鈕展開 5 個 phase 細節
- 點任一卡片只展開該卡，其他自動收回

---

## §2 認知驗證層（進階區，預設折疊）

### Tagline

> Claude 容易把「推論」當「事實」。閉環在 3 個位置強制查證。

### Detail

**三層防禦**：

1. **上游**（Phase 1 Step 0a/0b）：**字面證據掃描** — 設計階段優先用 docstring / echo string 等字面證據，不靠推論
2. **中游**（Section 12/13）：**事實主張閘門 + 質疑熔斷協議** — 任何「因為 X 所以 Y」要附 A 級（程式碼）/ B 級（commit history）證據；用戶說「OK」不能跨越事實質疑代價差
3. **下游**（Phase 1b Step 5c + Phase 5 Step 9c）：**Falsification check + 事實前提追溯** — design review 對引用的環境事實做反例提問；自證階段把所有事實主張記入 P5-fact-claims.md

### 為什麼

> 防止「LLM 一句『因為 X 所以 Y』就推下去，但 X 是猜的」

### ↗ 深入

`.claudedocs/concepts/閉環核心理念.md` §「認知驗證」

### 視覺特色

- SVG 三層防禦關係圖（上游 → 中游 → 下游 三個 box 用 dashed line 連接）
- 每層展開 2-3 個具體機制（hover 顯示）

---

## §3 升格降級機制（進階區，預設折疊）

### Tagline

> 同類失誤累積 3 次自動升格成「永久警惕」；無人問津 10 個閉環自動降級。

### Detail

**升格**（v5.22 引入）：
- `learning-log.md`（短期 · session 內）累積事件
- 同類根因 ≥ 3 次 → verifier Phase 5 步驟 9b 偵測候選
- 主 agent 跟用戶確認 → 寫入 `問題追蹤.md` 「永久警惕模式」
- 之後 architect Phase 1 強制必讀

**降級**（v6.4.0 加的對稱機制）：
- 升格後 10 個閉環無新證據 → ⏸️ 條件式紀律（觸發條件命中才適用）
- 20 個閉環無人問津 → 🗄️ archive
- 防誤判：條件式條目若 5 閉環內 2 次命中 → 自動升回

### 為什麼

> 防止教訓清單永久膨脹沒人看 — 教訓要有 lifecycle，沒用的會自動清掉

### ↗ 深入

`.claudedocs/records/問題追蹤.md` 升格降級規則

### 視覺特色

- 狀態機圖（learning-log → 永久警惕 → ⏸️ 條件式 → 🗄️ archive，含升回箭頭）
- 4 個狀態節點用不同顏色：active / warning / dim / dark

---

## §4 紀律保底層 R-1~R-5（進階區，預設折疊）

### Tagline

> 當判斷+機械化都失效時，5 條規則任何情況不可 bypass。

### Detail（5 條條列）

- 🔒 **R-1 閘門不可 bypass** — Phase 5 自證沒過不能 commit
- 🔒 **R-2 重大方法論修改強制 cross-source review** — 不能靠單一 LLM 自評（呼應 #007 升格教訓：single-LLM 自評漏看率 50-67%）
- 🔒 **R-3 升格降級不可 bypass** — 不能自己關掉教訓檢查
- 🔒 **R-4 架構體質 + 合理性自檢不可省略** — 設計階段不能跳閘
- 🔒 **R-5 連續 ≥ 2 次 needs-attention → 強制降級 scope** — 累積失誤要強制縮減任務範圍

### 為什麼

> 抓「自治可繞 + 機械化可關，遲早會繞到底」的紅線 — 劃出「自治 + 機械化都不能管的最後底線」

### ↗ 深入

`CLAUDE_TEMPLATE.md` Section 13.5 反向劃線

### 視覺特色

- 5 個 🔒 鎖頭圖示橫排，每個對應一條規則
- 紅色 accent line 暗示「不可跨越」

---

## §5 行為哲學 4 原則細節（進階區，預設折疊）

### Tagline

> Karpathy 4 原則橫切每個 Phase + Push back 義務（5 種情境主動反對用戶）。

### Detail · 4 原則展開

| 原則 | 自問 | 違反案例（對照範例庫） |
|------|------|----------------------|
| ❓ Think | 我假設了什麼？驗證過嗎？ | 默默選一種解讀，沒對用戶說 |
| ✂️ Simplicity | 能更簡單嗎？ | 一個簡單計算用 Strategy pattern |
| 🎯 Surgical | 只動了該動的嗎？ | 修 typo 順手 reformat 一堆 |
| ✅ Goal | 成功的可驗證標準是什麼？ | 「我先 review 再改善」（沒設可驗證標準） |

### Detail · Push back 義務 5 種觸發

Claude 在這 5 種情境會主動反對用戶：

1. 有更簡單的方案
2. 用戶基於弱證據要動
3. 任務超出該等級範圍
4. 規格自相矛盾
5. 用戶事實前提待驗證（與 §2 事實主張閘門對稱）

### 為什麼

> 防止「LLM 對用戶有求必應反而帶錯方向」 — 對用戶有義務反對，不是有求必應

### ↗ 深入

`CLAUDE_TEMPLATE.md` Section 0 + Section 12.5

---

## §6 Hook 系統（進階區，預設折疊）

### Tagline

> 6 個 shell hook 在 Claude Code 動手前/後自動觸發，把方法論變執行不只口號。

### Detail · 6 個 hooks

| Hook | 觸發時機 | 做什麼 |
|------|---------|--------|
| 修改前統一守衛 | PreToolUse Edit/Write | 修改任何檔案前必先做依賴影響分析 |
| 增量驗證 | PostToolUse Edit/Write | 編輯完該檔立即跑 lint |
| 委派前因果鏈閘門 | PreToolUse Task | 委派給 sub-agent 前要寫明因果 |
| 理解確認旗標 | UserPromptSubmit | 確認用戶意圖才行動 |
| 委派追蹤 | PostToolUse Task | 記錄 sub-agent 委派軌跡 |
| 學習日誌提醒 | Stop | Session 結束時提醒寫 daily log |

### 為什麼

> 抓「方法論寫了但執行時忘記」 — 機械化把「應該做」變「沒做就跑不過」

### ↗ 深入

`dev-closed-loop/hooks/` + `dev-closed-loop/deploy-hooks.sh`

### 視覺特色

- 6 個 hook 圖示 + 對映「觸發時機」流程圖

---

## §7 Agent 專家庫（8 agents · 進階區，預設折疊）

### Tagline

> 5 階段 + Phase 1b 的角色由 8 個專用 agent prompt 擔綱，不靠通用 LLM。

### Detail · 8 個 agents

| Agent | Phase | 類型 | 特色 |
|-------|-------|------|------|
| requirements-analyst | 1b 前 | inline | 蘇格拉底式引導 + 多角度選項 |
| architect | 1 | inline | 設計規格 + 架構體質 + 閘門 |
| design-reviewer | 1b | task | 挑戰式 + 驗證式 + 分層審查 |
| implementer | 2 | inline | 設計忠實實作 + 增量 lint + 簡化 |
| code-reviewer | 3 | task | 設計一致性 + 結構安全 + 依賴方向 |
| security-reviewer | 3 | task | 5 面向（輸入/注入/認證/暴露/依賴） |
| tester | 4 | inline | 驗證層級分層 + 實際執行 |
| verifier | 5 | task | 9 步驟雙向追溯 + 交叉比對 |

### 為什麼

> 防止「一個通用 LLM 同時扮 5 個角色容易混淆」 — 每個 phase 用專用 prompt 強化角色聚焦

### ↗ 深入

`.claudedocs/agents/` 目錄（含 README）

---

## §8 對照範例（5 anti-patterns · 進階區，預設折疊）

### Tagline

> 列出 5 個 LLM 常犯錯誤的對照範本，給 reviewer / architect 查閱。

### Detail · 5 個 examples

1. **01 Think Before Coding** — Q1 違反：默默選一種解讀，沒對用戶說
2. **02 Simplicity First** — Q2 違反：一個簡單計算用 Strategy pattern
3. **03 Surgical Changes** — Q3 違反：修 typo 順手 reformat 一堆
4. **04 Goal-Driven Execution** — Q4 違反：「我先 review 再改善」（沒設可驗證標準）
5. **05 Cross-Artifact Mismatch** — 閉環特色：設計 / 實作 / 測試對齊缺失

每檔 5 段結構：場景 / 錯誤示範 / 原則診斷 / 修正版本 / 關鍵限制

### 為什麼

> 抓「LLM 自評時自己是同一個 LLM 容易看不見的盲點」 — 對照範例讓 reviewer agent 有外部錨點，不依靠主 LLM 的自我反省

### ↗ 深入

`.claudedocs/examples/` 5 個 anti-pattern 文件

---

## §9 兩層教訓架構（learning-log + 問題追蹤 · 進階區，預設折疊）

### Tagline

> 短期事件記 learning-log，跨閉環高頻問題升格成「永久警惕模式」。

### Detail

**Short-term — learning-log**（per-session）：
- 每個 session 的事件記錄
- 含 failure_type / root cause / 怎麼修的 / 下次注意
- 不入問題追蹤的小事件留這裡觀察

**Long-term — 問題追蹤「永久警惕模式」**（跨閉環）：
- 同類根因 ≥ 3 次升格條目
- architect Phase 1 強制必讀
- 含 v6.4.0 加的降級機制（無人問津自動降）

### 為什麼

> 防止「教訓寫了沒人看」 — 兩層分工避免單檔變太長，重要的升格成「強制必讀」

### ↗ 深入

`.claude-loop/learning-log.md` + `.claudedocs/records/問題追蹤.md`

### 視覺特色

- 兩層架構圖（short-term ↔ long-term 雙向箭頭 + 升格 / 降級流向）

---

## §10 工具鏈（dev:handoff + dev:init-claude · 進階區，預設折疊）

### Tagline

> 兩個 Skill 包進方法論：`/dev:handoff` 跨 session 交接 + `/dev:init-claude` 一鍵部署 / 升級。

### Detail · 指令對映

| 指令 | 場景 |
|------|------|
| `/dev:init-claude` | 部署閉環到當前專案（含偵測語言 / 框架 / 指令） |
| `/dev:init-claude status` | 健康檢查 + 升級偵測 |
| `/dev:init-claude upgrade` | 從 GitHub 拉最新版 + 智能合併 |
| `/dev:init-claude uninstall` | 反向移除（保留 .claude-loop/） |
| `/dev:handoff save` | 寫當前 session 狀態（File state） |
| `/dev:handoff load` | 接續上個 session 狀態（重建 TaskList runtime state） |

### 為什麼

> 抓「方法論很好但部署 / 上手成本高 / 換 session 失憶」 — 工具鏈把方法論從「文件」變成「可執行」

### ↗ 深入

`dev-closed-loop/skill/init-claude.md` + `dev-closed-loop/skills/dev:handoff/SKILL.md`

---

## §11 語言指南（TS/Py/Go/Rust/C#/Bash · 進階區，預設折疊）

### Tagline

> 6 個語言專屬指南，把 Phase 1-5 閘門翻成語言慣例。

### Detail · 6 語言對映

| 語言 | 主要工具鏈 |
|------|-----------|
| TypeScript | tsc + eslint + vitest + react testing library |
| Python | mypy + ruff + pytest |
| Go | go vet + golangci-lint + go test |
| Rust | cargo check + clippy + cargo test |
| C# | dotnet format + xunit + nullable enabled |
| Bash | shellcheck + bats |

每個語言指南內含 Phase 1-5 對應的語言慣例 + 工具鏈呼叫範例 + R-x 編號示例。

### 為什麼

> 防止「同一閘門對 TS 跟 Python 操作方式完全不同」 — 語言指南把抽象閘門變具體指令

### ↗ 深入

`.claudedocs/languages/` 6 個語言文件

---

## CTA 區（底部）

### 共通

- 📦 **GitHub Repo**：[gatewen/ClaudeCodeTools](https://github.com/gatewen/ClaudeCodeTools)
- 📚 **設計史**：`design/01-13`（給有興趣的人深入閱讀）

### Deployed 變體

| 想做的 | 怎麼做 |
|--------|--------|
| 啟動下個閉環 | 自然語言描述任務即可（如「實作 X 功能」） |
| 看部署的文件 | 開啟 `.claudedocs/README.md` |
| 跨 session 接續 | `/dev:handoff save` 然後新 session `/dev:handoff load` |
| 升級到最新 | `/dev:init-claude upgrade` |
| 看當前部署狀態 | `/dev:init-claude status` |

### Standalone 變體

```
未部署？三步開始：

1. 安裝（一行）：
   curl -sL https://raw.githubusercontent.com/gatewen/ClaudeCodeTools/main/setup.sh | bash

2. 在你的專案目錄執行：
   /dev:init-claude

3. 開始用閉環：自然語言描述任務即可
```

---

## 部署狀態區（Deployed 模式才出現 · 3 個 group）

### Group 1：版本

```
版本：v{{DEPLOYMENT_VERSION}}（部署於 {{DEPLOYMENT_DATE}} · 距今 {{DEPLOYMENT_DAYS_AGO}} 天）
{{DEPLOYMENT_UPGRADE_STATUS}}
```

### Group 2：啟用功能

```
核心文檔  {{DEPLOYMENT_CORE_DOCS_COUNT}} / 17
Agent 專家庫  {{DEPLOYMENT_AGENTS_COUNT}} / 8
Hook  {{DEPLOYMENT_HOOKS_COUNT}} / 6
語言指南  {{DEPLOYMENT_LANGUAGE_LIST}}（若空則「未部署」）
對照範例  {{DEPLOYMENT_EXAMPLES_COUNT}} / 5
```

### Group 3：累積活動

```
Learning log 條目  {{DEPLOYMENT_LEARNING_LOG_COUNT}} 筆
永久警惕條目  {{DEPLOYMENT_ESCALATED_RANGE}}
```

> 若 `{{DEPLOYMENT_LEARNING_LOG_COUNT}}` = 0 或對應檔案不存在 → 顯示「— 尚無紀錄（新部署）」
