# Agent 使用指南

## 這份文件的定位

CLAUDE.md 裡已經寫了每個 Phase 該調用哪個 Agent 和約束條件。
這份文件是補充說明：**為什麼這樣選、什麼情況該換、Agent 之間怎麼配合。**

如果你只想知道「該用什麼」，看 CLAUDE.md 的閉環調度規則就夠了。
這份是給想理解選擇邏輯的人看的。

---

## 三類 Agent 的差異

在開始之前，先搞清楚三類 Agent 的差異：

| 類別 | 執行方式 | 上下文 | 適合什麼 |
|------|---------|--------|---------|
| **sc: Skill** | 在當前對話裡執行 | 能看到整個對話歷史 | 需要完整上下文的工作（設計、實作、自証） |
| **superpowers: Skill** | 在當前對話裡執行 | 能看到整個對話歷史 | 有明確流程的專門化工作（TDD、code review） |
| **Task agent** | 開一個獨立子程序 | 只看到你傳給它的 prompt | 可以獨立完成的子任務（安全掃描、品質分析） |

**關鍵差異**：sc/superpowers Skill 看得到前面 Phase 的產出物（因為都在同一個對話裡），Task agent 看不到（你要手動把資料傳給它）。

所以 CLAUDE.md 裡的優先順序是：sc: > superpowers: > Task agent。
只有在「這個工作可以獨立做、不需要前後文」的時候才用 Task agent。

---

## 各 Phase 的選擇邏輯

### Phase 1：架構師 📐

**為什麼 `sc:design` 是首選？**
它會做結構化的技術設計，產出符合閉環需要的設計文件。而且在當前對話中執行，能看到用戶的原始需求。

**什麼時候換別的？**

| 情境 | 改用 | 原因 |
|------|------|------|
| 用戶只有模糊想法 | `sc:brainstorm` → 再 `sc:design` | 先釐清需求再設計，不然設計方向會錯 |
| 要設計整個系統架構 | Task agent `system-architect` | 系統級設計可以獨立思考，不需要對話上下文 |
| 只需要函式級設計 | 不用調 agent，直接做 | 簡單到不值得調 agent |

**要注意的事**：
不管用哪個 agent，都要確保產出物有 BC-x 和 EH-x 編號。這些 agent 預設不會加編號，所以調用時要在 prompt 裡明確要求。

### Phase 2：程序設計師 💻

**為什麼 `sc:implement` 是首選？**
它專門做功能實作，而且在當前對話裡能直接看到 Phase 1 的設計規格。

**什麼時候換別的？**

| 情境 | 改用 | 原因 |
|------|------|------|
| Phase 1 已經產出完整計畫 | `superpowers:executing-plans` | 專門為「有計畫就執行」設計的 |
| 後端 API 實作 | 搭配 Task agent `backend-architect` | 後端專家有更好的 API 設計直覺 |
| 前端元件實作 | 搭配 Task agent `frontend-architect` + Magic MCP | 前端專家 + UI 生成器 |
| Python 專案 | 搭配 Task agent `python-expert` | Python 的慣用寫法和最佳實踐 |

**最重要的約束**：
Agent 的實作必須嚴格對照 Phase 1 的設計規格。`sc:implement` 預設會自己判斷怎麼做最好，但在閉環裡它不能自作主張。CLAUDE.md 裡的約束會覆蓋它的預設行為。

### Phase 2 → 3 之間：code-simplifier 強制優化 🔧

**為什麼加這一步？**

AI 產生程式碼時有個常見問題：**照搬舊碼**。它會把現有程式碼原樣複製過來，不管有沒有更好的寫法。甚至有時候會產出冗長、不一致的程式碼，只因為「能動就好」。

`code-simplifier` 是一個 Task agent，專門做三件事：
1. **清晰度（Clarity）**：讓程式碼一看就懂
2. **一致性（Consistency）**：跟專案風格對齊
3. **可維護性（Maintainability）**：去除不必要的複雜度

**為什麼是 Task agent 而不是 Skill？**
code-simplifier 的工作是純程式碼層面的，不需要看閉環的上下文。給它程式碼檔案路徑就能獨立做。用 Task agent 還有一個好處：它的優化結果是獨立的判斷，不會被前面對話中「自己寫的程式碼」所影響（避免自己審自己的偏見）。

**嚴格規則（CLAUDE.md 裡有寫，這裡補充說明）**：

| 規則 | 為什麼 | 違反的後果 |
|------|--------|-----------|
| 禁止照搬舊碼 | AI 容易偷懶複製貼上，但舊碼可能有技術債 | Phase 3 的檢核師會標 R-x 要求返工 |
| 三面向必須審查 | 只看「能不能跑」不夠，要看「好不好維護」 | 長期技術債累積，後續修改成本高 |
| 不能改設計行為 | 簡化的是「實作方式」不是「功能規格」 | 改了設計就破壞跟 Phase 1 的一致性 |
| 用戶說保留就保留 | 有時候舊碼有特殊原因要保留 | — |

**什麼時候可以跳過？**
- 用戶明確說「保留原始碼」「不要優化」「照搬就好」
- 除此之外，沒有例外

**調用方式**：
```
Task agent `code-simplifier`
prompt 帶上：
- 新增/修改的檔案路徑
- 專案的程式碼風格慣例（如果有的話）
- 明確指示：「優化程式碼的清晰度、一致性和可維護性，但不改變功能行為」
```

### Phase 3：檢核師 🔍

**為什麼建議用 Task agent？**
Code review 是可以獨立完成的工作——給它程式碼和設計規格，它就能做。而且用 Task agent 可以**平行**跑多個檢核（品質 + 安全同時進行）。

**推薦的組合**：

```
Phase 3 同時啟動：
├── Task agent `superpowers:code-reviewer` — 檢查程式碼品質和設計一致性
└── Task agent `security-engineer` — 檢查安全問題

兩個結果合併成一份檢核報告
```

**什麼時候不用 Task agent？**

| 情境 | 改用 | 原因 |
|------|------|------|
| 程式碼很短（< 50 行） | `sc:analyze --focus quality` | 不值得開 agent，直接分析 |
| 需要看對話中的討論脈絡 | `sc:analyze` | Skill 能看到為什麼這樣設計 |

**傳給 Task agent 的 prompt 要帶什麼**：
必須帶上 Phase 1 的設計規格（含 BC-x、EH-x 編號）和 Phase 2 的程式碼檔案路徑。不帶設計規格的話，agent 只會做一般的 code review，不會檢查設計一致性。

### Phase 4：測試師 🧪

**為什麼 `sc:test` 是首選？**
它能寫測試、跑測試、報告結果，而且看得到前面的設計規格可以做覆蓋率比對。

**什麼時候換別的？**

| 情境 | 改用 | 原因 |
|------|------|------|
| 想用 TDD 流程 | `superpowers:test-driven-development` | 先寫測試再實作的完整 TDD 流程 |
| 需要完整測試策略 | Task agent `quality-engineer` | 包含測試策略規劃、覆蓋率分析 |
| 前端需要 E2E 測試 | Playwright MCP | 真實瀏覽器測試 |

**絕對不能省的步驟**：
用 Bash 實際跑 CLAUDE.md「專案配置」中定義的測試指令。不管用哪個 agent，最後一定要實際執行測試。「寫了測試」跟「測試通過」是兩回事。

### Phase 5：自証師 ✅

**為什麼改成三步走？（v2 更新）**

v1 只有調用兩個 Skill。v2 在前面加了一步：先執行 CLAUDE.md 裡的「自証檢查表」。

原因：`sc:reflect` 和 `superpowers:verification-before-completion` 的預設行為分別是「任務反思」和「跑測試確認完成」，都不是「跨產出物一致性比對」。光靠 CLAUDE.md 的約束文字不一定能覆蓋它們的預設行為。

所以現在的流程是：
1. **自証檢查表**（CLAUDE.md 裡的 6 步具體指令）← 這是核心，確保比對真的做了
2. **`sc:reflect --type completion`** ← 補充評估完成度
3. **`superpowers:verification-before-completion`** ← 最終驗證

**為什麼不用 Task agent？**
自証師需要看到 Phase 1-4 的所有產出物，這些都在當前對話裡。用 Task agent 的話，你得把所有產出物都塞進 prompt，很容易漏東西。

**自証檢查表的設計邏輯**：
CLAUDE.md 裡的 6 步檢查表不是「建議」，是「指令」。每一步都要求明確的輸出（✅/❌ 標記），讓 Claude 不能跳過或敷衍。這比純文字的約束（「你必須做 XX」）更可靠，因為：
- 步驟 1 要求列出所有 ID → 建立了比對的基準
- 步驟 2-4 要求逐一標注 ✅/❌ → 不能籠統地說「都做了」
- 步驟 6 要求用固定格式輸出 → 結果可追溯

---

## 上下文傳遞

Phase 之間的產出物怎麼傳？

| 傳遞方式 | 適用場景 | 做法 |
|---------|---------|------|
| 對話內傳遞 | sc/superpowers Skill | 自動看得到，不用特別處理 |
| Prompt 傳遞 | Task agent | 在 Task 的 prompt 裡明確附上前面 Phase 的產出物 |
| 檔案傳遞 | 跨 session | 把產出物寫到 `.claudedocs/記錄/` 裡，下次讀取 |

大部分情況用「對話內傳遞」就好。需要在 prompt 裡手動傳遞的情境：
- Phase 2→3 之間的 `code-simplifier`：帶上修改的檔案路徑和專案風格慣例
- Phase 3 用 Task agent 做平行 code review：帶上設計規格和程式碼路徑

---

## 常見錯誤

| 錯誤 | 為什麼是錯的 | 正確做法 |
|------|------------|---------|
| Phase 1 就用 `sc:implement` | implement 是寫程式碼的，不是做設計的 | 用 `sc:design` |
| Phase 2 完成後跳過 code-simplifier | AI 產生的程式碼可能照搬舊碼或冗長不一致 | 強制調用 code-simplifier 再進 Phase 3 |
| code-simplifier 改了功能行為 | 它只能簡化實作方式，不能改設計規格 | prompt 明確寫「不改變功能行為」 |
| Phase 3 的 code-reviewer 沒給設計規格 | 它會做一般 review 但不會檢查設計一致性 | prompt 裡帶上設計規格 |
| Phase 4 只寫測試沒跑 | 沒有實際執行的測試報告是假的 | 一定要用 Bash 跑 |
| Phase 5 用 Task agent | 會漏看對話裡的產出物上下文 | 用 Skill 在對話中執行 |
| 每個 Phase 都開 `--ultrathink` | Phase 2 寫程式碼不需要深度推理 | Phase 1 和 5 才需要 |

---

## 外部 Skills 資源

### SkillsMP 是什麼

[SkillsMP](https://skillsmp.com/) 是一個社群維護的 Claude Code Skills 市集，從 GitHub 公開倉庫彙整了超過 16 萬個 skills。它不是 Anthropic 官方產品，但對找到好用的社群工具很有幫助。

### 為什麼要用外部 Skills

閉環系統的內建 Agent（sc: / superpowers: / Task agent）已經能覆蓋大部分需求。但在某些場景下，社群 Skills 可以提供更專門化的能力：

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

#### Phase 5：自証師

目前沒有直接對應的社群 Skill。自証（跨產出物一致性驗證）是本閉環系統的獨有概念。CLAUDE.md 裡的自証檢查表就是為這個目的設計的。

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

最後修訂：2026-02-12
