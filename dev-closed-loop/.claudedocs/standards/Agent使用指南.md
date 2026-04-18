# Agent 使用指南

## 這份文件的定位

CLAUDE.md 裡已經寫了每個 Phase 該調用哪個 Agent 和約束條件。
這份文件是補充說明：**為什麼這樣選、什麼情況該換、Agent 之間怎麼配合。**

如果你只想知道「該用什麼」，看 CLAUDE.md 的閉環調度規則就夠了。
這份是給想理解選擇邏輯的人看的。

---

## Agent 專家庫（v5.14.0 新增）

`.claudedocs/agents/` 目錄包含 8 個專家 agent prompt，覆蓋 Phase 1-5 全流程。每個 prompt 基於 **prompt-engineer-agentic v4.1** 三層架構設計（Foundation → Structure → Execution），是閉環方法論的完整能力，無需任何外部依賴。

| Agent | Phase | 類型 | 用途 |
|-------|-------|------|------|
| requirements-analyst | Section 1b | inline | 需求探索（多角度分析+選項生成） |
| architect | Phase 1 | inline | 設計規格產出（BC-x/EH-x/IF-x） |
| design-reviewer | Phase 1b | task | 設計審查（挑戰式+架構體質+分層） |
| implementer | Phase 2 | inline | 按設計規格實作+增量驗證 |
| code-reviewer | Phase 3 | task | 品質審查（設計一致性+結構安全） |
| security-reviewer | Phase 3 | task | 安全審查（輸入驗證/注入/認證/暴露） |
| tester | Phase 4 | inline | BC-x/EH-x 覆蓋測試+實際執行 |
| verifier | Phase 5 | task | 雙向追溯+交叉比對+arch-risk 追蹤 |

**使用方式**：見 `.claudedocs/agents/README.md`。

---

## 兩類 Agent 的差異

| 類別 | 執行方式 | 上下文 | 適合什麼 |
|------|---------|--------|---------|
| **Agent 專家庫（inline）** | 主 agent 讀取後按指引執行 | 保留完整對話歷史 | Phase 1/2/4 需要對話上下文的工作 |
| **Agent 專家庫（task）** | Agent tool 啟動獨立子 agent | 只看到 prompt 和資料包 | Phase 1b/3/5 獨立審查工作 |

**關鍵差異**：inline agent 看得到前面 Phase 的產出物（在同一對話裡），task agent 看不到（主 agent 要把資料包傳給它）。

**Task agent 名稱說明**：本文件中提到的 Task agent 名稱（如 `code-simplifier`、`quality-engineer`）是角色描述而非固定 ID。調用時在 Task prompt 中描述對應角色的專長即可，Claude Code 會自動匹配合適的 agent 行為。

---

## 各 Phase 的 Agent 說明

### Phase 1：架構師 📐（`architect.md` · inline）

主 agent 讀取 `architect.md` 後按 `<instructions>` 的 8 個步驟執行。產出物是 BC-x/EH-x/IF-x 設計規格，含分層結構聲明和驗證層級標注。

需求模糊時，先讀 `requirements-analyst.md` 做多角度需求探索，收斂後再進入架構設計。

**要注意**：architect agent 已內建 BC-x/EH-x 編號和閘門檢查，不需要額外提醒。

### Phase 2：程序設計師 💻（`implementer.md` · inline）

主 agent 讀取 `implementer.md` 後按指引逐檔實作。核心約束：嚴格按設計規格、增量 lint 驗證、完成後觸發 Task `code-simplifier`。

### Phase 2 → 3 之間：code-simplifier 強制優化 🔧

AI 產生程式碼時有個常見問題：**照搬舊碼**。`code-simplifier` 是 Task agent，專門做三件事：
1. **清晰度（Clarity）**：讓程式碼一看就懂
2. **一致性（Consistency）**：跟專案風格對齊
3. **可維護性（Maintainability）**：去除不必要的複雜度

**為什麼是 Task agent？**
純程式碼層面的工作，不需要看閉環上下文。獨立判斷避免「自己審自己」的偏見。

| 規則 | 為什麼 | 違反的後果 |
|------|--------|-----------|
| 禁止照搬舊碼 | AI 容易偷懶複製貼上，但舊碼可能有技術債 | Phase 3 的檢核師會標 R-x 要求返工 |
| 三面向必須審查 | 只看「能不能跑」不夠，要看「好不好維護」 | 長期技術債累積 |
| 不能改設計行為 | 簡化的是「實作方式」不是「功能規格」 | 破壞跟 Phase 1 的一致性 |
| 用戶說保留就保留 | 有時候舊碼有特殊原因要保留 | — |

跳過條件：用戶明確說「保留原始碼」「不要優化」。除此之外，沒有例外。

### Phase 3：檢核師 🔍（`code-reviewer.md` + `security-reviewer.md` · task）

兩個 Task agent 可**平行**啟動：

```
Phase 3 同時啟動：
├── code-reviewer.md — 品質審查（設計一致性 + 結構安全 + 依賴方向 + 合理性）
└── security-reviewer.md — 安全審查（輸入驗證 / 注入 / 認證 / 暴露 / 依賴）
```

每個 agent 的 `<input_contract>` 已定義需要什麼輸入。code-reviewer 需要設計規格 + 程式碼路徑；security-reviewer 只需要程式碼路徑。

### Phase 4：測試師 🧪（`tester.md` · inline）

主 agent 讀取 `tester.md` 按指引執行。核心：每個 `[testable]` BC-x/EH-x 有對應測試、實際用 Bash 跑測試和建置指令。

**絕對不能省**：用 Bash 實際執行測試。「寫了測試」跟「測試通過」是兩回事。

### Phase 5：自證師 ✅（`verifier.md` · task + 主 agent 彙整）

分兩段：
- **Part AB**：讀取 `verifier.md` 啟動 Task agent，執行 10 步驟雙向追溯（行為路徑枚舉+正向+反向+交叉比對+arch-risk 追蹤）
- **Part C**：主 agent 彙整 Part AB 結果 + 委派產出物驗證 + 全專案回歸測試

**為什麼 Part AB 用 Task agent？**
切斷主對話的推理 context，確保獨立性。verifier agent 的 `<input_contract>` 已定義完整的驗證包內容。

**為什麼 Part C 不用 Task agent？**
Part C 需要看到 Phase 1-4 的所有產出物做最終彙整，這些在當前對話裡。

---

## 上下文傳遞

Phase 之間的產出物怎麼傳？

| 傳遞方式 | 適用場景 | 做法 |
|---------|---------|------|
| 對話內傳遞 | inline agent（Phase 1/2/4） | 自動看得到，不用特別處理 |
| Prompt 傳遞 | task agent（Phase 1b/3/5） | 按 `<input_contract>` 準備資料包 |
| 檔案傳遞 | 跨 session | 把產出物寫到 `.claude-loop/` 裡，下次讀取 |

inline agent 在對話中執行，自動看到前面 Phase 的產出物。task agent 需要主 agent 按 `<input_contract>` 準備資料包——每個 agent 的 contract 已明確定義需要什麼。

### claude-mem 語義記憶（可選）

claude-mem 不是 Agent，是 MCP 插件，但與上下文傳遞有關。

- `.claude-loop/` 存的是「產出物」（設計規格、自證結果）
- claude-mem 存的是「經驗」（架構決策理由、踩坑教訓、慣例約定）

**在閉環中的使用時機**：

| 時機 | 動作 | 為什麼 |
|------|------|--------|
| Phase 1 前 | `search` 查詢相關歷史 | 避免重蹈覆轍、參考歷史決策 |
| Phase 5 通過後 | `save_memory` 保存決策和教訓 | 為未來的閉環累積經驗 |
| 斷點 A/B 回退時 | `save_memory` 記錄踩坑 | 同類錯誤不犯第二次 |

不可用時跳過以上步驟，閉環照常運作。

---

## 常見錯誤

| 錯誤 | 為什麼是錯的 | 正確做法 |
|------|------------|---------|
| Phase 1 讀了 `implementer.md` | implementer 是寫程式碼的，不是做設計的 | 讀 `architect.md` |
| Phase 2 完成後跳過 code-simplifier | AI 產生的程式碼可能照搬舊碼或冗長不一致 | 強制調用 code-simplifier 再進 Phase 3 |
| code-simplifier 改了功能行為 | 它只能簡化實作方式，不能改設計規格 | prompt 明確寫「不改變功能行為」 |
| Phase 3 的 code-reviewer 沒給設計規格 | 它會做一般 review 但不會檢查設計一致性 | 按 `<input_contract>` 帶上設計規格 |
| Phase 4 只寫測試沒跑 | 沒有實際執行的測試報告是假的 | 一定要用 Bash 跑 |
| Phase 5 Part C 用 Task agent | 會漏看對話裡的產出物上下文 | Part C 由主 agent 在對話中執行 |
| 每個 Phase 都開 `--ultrathink` | Phase 2 寫程式碼不需要深度推理 | Phase 1 和 5 才需要 |

---

## 外部 Skills 資源

### SkillsMP 是什麼

[SkillsMP](https://skillsmp.com/) 是一個社群維護的 Claude Code Skills 市集，從 GitHub 公開倉庫彙整了超過 16 萬個 skills。它不是 Anthropic 官方產品，但對找到好用的社群工具很有幫助。

### 為什麼要用外部 Skills

閉環的 Agent 專家庫已覆蓋全流程。但在某些場景下，社群 Skills 可以提供更專門化的能力：

- Phase 1：更好的架構決策記錄工具
- Phase 3：語言專屬的 code review 規則
- Phase 4：特定框架的測試生成器
- 跨 Phase：專門化的安全掃描工具

### 各 Phase 推薦的 Skills

#### Phase 1：架構師

| Skill 名稱 | 用途 | 備註 |
|-----------|------|------|
| `planning-architect` | 從需求到設計的完整工作流 | 適合複雜系統設計 |
| `adr` | 架構決策記錄（Architecture Decision Records） | 記錄為什麼這樣設計 |
| `project-planner` | 需求收集到規格的問答式流程 | 適合需求模糊時 |
| `roadmap-generator` | 分階段路線圖生成 | 適合大功能規劃 |

#### Phase 2：程序設計師

搜尋對應語言的 skill 即可，例如：
- Python 專案 → 搜尋 `python best practices`
- TypeScript → 搜尋 `typescript patterns`
- Go → 搜尋 `go conventions`

#### Phase 3：檢核師

| Skill 名稱 | 用途 | 備註 |
|-----------|------|------|
| `code-review-excellence` (by wshobson) | 分級 code review，帶優先順序標籤 | 🔴 blocking / 🟡 important / 🟢 nit 分級系統跟閉環的 high/medium/low 對應 |
| `secure-code-guardian` | OWASP Top 10 安全護欄 | 專注安全面向 |
| `security-review` | 安全審計：漏洞、合規、敏感資料 | 可搭配 security-engineer agent |
| `python-quality-checker` | Python 綜合品質檢查 | 格式、型別、lint、安全、複雜度 |

#### Phase 4：測試師

| Skill 名稱 | 用途 | 備註 |
|-----------|------|------|
| `test-master` | 跨領域測試策略與覆蓋分析 | 適合需要完整測試策略時 |
| `frontend-testing` | Vitest + React Testing Library 測試生成 | 前端專用 |
| `test-generation` | 自動生成測試案例 | 通用測試生成 |

#### Phase 5：自證師

目前沒有直接對應的社群 Skill。自證（跨產出物一致性驗證）是本閉環系統的獨有概念。CLAUDE.md 裡的自證檢查表就是為這個目的設計的。

### 安全注意事項

**這很重要，不要跳過。**

根據 [SmartScope 的分析](https://smartscope.blog/en/blog/skillsmp-marketplace-guide/)，SkillsMP 上約 **26.1% 的 skills 含有至少一項潛在漏洞**，5.2% 顯示惡意意圖的模式。

使用前的檢查清單：

1. **看 GitHub 星級**：優先選 ≥ 10 星的。低星級不一定差（可能是新的或小眾的），但高星級通常代表有更多人檢查過
2. **看原始碼**：特別注意有沒有 `bash` 工具的任意命令執行、有沒有往外部發送資料
3. **先在非正式環境測**：不要直接在生產專案裡啟用未測試的 skill
4. **注意權限**：有些 skill 會要求 docker、bash 等高權限操作
5. **優先用官方的**：Anthropic 官方的 skills（`github.com/anthropics/skills`）比社群的更安全

### 怎麼安裝 Skills

```bash
# 個人全域 skill（所有專案都能用）
~/.claude/skills/skill-name.md

# 專案專屬 skill（只有該專案能用）
.claude/skills/skill-name.md
```

從 SkillsMP 找到 skill 後，點進去看 GitHub 原始碼，把 `.md` 檔案複製到對應位置即可。

---

最後修訂：2026-03-28（v5.14.0 Agent 專家庫重寫）
