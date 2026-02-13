# 研究報告：大型專案是否需要上層管理 Agent？

> 研究日期：2026-02-14
> 研究問題：dev-closed-loop 的三層閉環設計在大型多模組專案中是否足夠？是否需要專案協調者？
> 研究深度：deep（結構分析 + 業界實踐 + 專家驗證）

---

## 執行摘要

**結論：現有閉環在大型專案中有 7 個結構性缺口，需要加入「專案協調者」橫切機制。**

現有的三層閉環（函式→模組→框架）是嚴格的 bottom-up 設計。在單模組或小型專案中運作良好，但大型多模組專案的現實是 **top-down + bottom-up 混合**——先定義介面契約，再各自開發，最後整合驗證。這個結構性矛盾是所有問題的根源。

業界已有成熟的解法：Google 的 Coordinator/Dispatcher 模式、Microsoft 的 Supervisor 模式、MetaGPT 的 Project Manager Agent，以及 Claude Code 自己的 Agent Teams（實驗性功能）。這些都指向同一個方向：**大型多 Agent 系統需要一個協調層**。

---

## 一、現有閉環的 7 個結構性缺口

### 缺口 1：介面契約定義時機倒置 (HIGH)

**現狀**：MD-x（模組依賴契約）只在框架層級才定義。
**問題**：模組開發時就需要知道彼此的介面。等到框架閉環才發現不相容，兩個模組可能都要重做。

```
Auth 模組 期望 User 模組回傳 { id, email, role }
User 模組 實際只回傳 { id, name }
兩邊各自的閉環都通過了 → 框架閉環才爆
```

**根因**：閉環是 bottom-up 設計，但介面契約需要 top-down 先行。

### 缺口 2：跨模組變更傳播的黑洞 (HIGH)

**現狀**：無跨模組通知機制。
**問題**：模組 A 在 Phase 3 觸發斷點 A，修正後介面從 `getUser(id)` 改為 `getUser(id, options)`。依賴 A 的模組 B、C 完全不知道，繼續基於舊介面開發。

**需要**：介面變更時的「漣漪分析」(ripple analysis)——誰受影響、影響多大、自動通知。

### 缺口 3：並行開發無協調 (HIGH)

**現狀**：假設模組獨立開發，沒有排程機制。
**問題**：模組 B 依賴模組 A 的介面。A 還在 Phase 2 迭代中，B 就基於 A 的「暫定」介面開始了 Phase 1 設計。如果 A 後來改了介面，B 的整個設計規格失效。

**需要**：依賴感知的調度——先穩定被依賴方的介面，再讓依賴方開始。

### 缺口 4：跨 Session 狀態丟失 (MEDIUM)

**現狀**：所有閉環狀態只存在於對話記憶中。
**問題**：大型專案需要 5-10 個 session。Session 1 完成了模組 A 的閉環，Session 2 開始做模組 B 時，模組 A 的設計規格和自証結果需要從某處讀回。目前沒有定義持久化的機制和格式。

### 缺口 5：專案全局進度不可見 (MEDIUM)

**現狀**：可見性規則只覆蓋單一閉環的 5 Phase。
**問題**：「專案有 8 個模組，其中 3 個方法閉環通過、2 個模組閉環通過、1 個正在 Phase 3 有斷點」——這種全局狀態無處可見。

### 缺口 6：自証的規模爆炸 (MEDIUM)

**現狀**：框架層級 Phase 5 需驗證所有 MD-x + 繼承的 MC-x/EP-x。
**問題**：10 個模組 × 平均 (5 MC-x + 3 EP-x) = 80 個繼承 ID + 10-15 個 MD-x = 近 100 個 ID。單次自証在 LLM 上下文中不可靠。

### 缺口 7：缺少介面凍結機制 (LOW)

**問題**：大型專案中，模組介面需要經歷：草案 → 審核 → 凍結 → 實作。一旦凍結，修改需要正式的變更流程。目前閉環中沒有「介面生命週期」的概念。

---

## 二、業界多 Agent 編排的最新實踐

### 2.1 Google 的 8 種多 Agent 設計模式

Google Agent Development Kit (ADK) 團隊發布了 8 種模式的分類框架：

| 模式 | 描述 | 與閉環的對應 |
|------|------|------------|
| **Sequential Pipeline** | 流水線，每個 Agent 傳遞輸出 | 現有閉環的 5 Phase 就是這個模式 |
| **Coordinator/Dispatcher** | 中央調度，路由到專業 Agent | **缺少的專案協調者** |
| **Parallel Fan-Out/Gather** | 平行執行，結果聚合 | 模組並行開發的潛在方案 |
| **Hierarchical Decomposition** | 高層分解任務，向下委派 | 框架→模組→函式的拆解 |
| **Generator and Critic** | 生成 + 驗證 | Phase 2（生成）+ Phase 3（檢核） |
| **Iterative Refinement** | 生成-檢核-修正循環 | 斷點觸發的回退迭代 |
| **Human-in-the-Loop** | 人類審批閘門 | 斷點 A/B 的概念 |
| **Composite Pattern** | 混合以上多種模式 | **目標架構** |

**關鍵洞察**：現有閉環主要用了 Sequential Pipeline + Generator-Critic + Human-in-the-Loop。缺少的是 **Coordinator/Dispatcher**（中央協調）和 **Parallel Fan-Out/Gather**（模組並行）。

### 2.2 Microsoft 的 Supervisor 模式

Microsoft Agent Framework 的建議：

- **Orchestrator 角色**：中央協調者，管理請求流、上下文保持、生命週期管理
- **Agent Registry**：動態發現和元資料管理
- **Supervisor 層級**：supervisor → agent group 的階層組織
- **跨 Agent 一致性**：版本化策略 + 狀態機管理 dev/test/prod 環境
- **變更影響管理**：同時版本化 agent 元資料和 orchestrator 配置

### 2.3 MetaGPT：模擬整個軟體公司

MetaGPT 直接用 AI Agent 模擬軟體公司結構：

- **Product Manager** Agent → 需求和用戶故事
- **Architect** Agent → 系統架構設計
- **Project Manager** Agent → 任務拆分和分配
- **Engineer** Agents → 程式碼實作

其中 **Project Manager Agent** 的角色就是我們討論的「專案協調者」——接收架構、拆分任務、分配給工程師、監控完成度。

### 2.4 Claude Code Agent Teams（實驗性功能）

**這是最直接相關的發現。** Claude Code 在 2026 年初已經推出了 Agent Teams 功能：

| 元件 | 角色 |
|------|------|
| **Team Lead** | 主 Claude Code session，建立團隊、分配任務、協調工作 |
| **Teammates** | 獨立的 Claude Code instances，各自處理被分配的任務 |
| **Task List** | 共享的任務清單，支援依賴關係和自動解鎖 |
| **Mailbox** | Agent 之間的訊息系統 |

關鍵能力：
- **Delegate Mode**：Lead 只做協調，不寫程式碼（即「專案經理」模式）
- **Plan Approval**：Teammates 提交計畫，Lead 審批後才能實作
- **Task Dependencies**：任務間有依賴關係，自動管理解鎖
- **TeammateIdle / TaskCompleted Hooks**：品質閘門

**限制**：實驗性功能、Windows Terminal 不支援 split pane、一個 session 只能一個 team、不支援 nested teams。

### 2.5 跨模組一致性的業界方案

| 方案 | 描述 |
|------|------|
| **Shared State (Whiteboard)** | LangGraph/ADK：Agent 共享狀態做為協調白板 |
| **MCP (Anthropic)** | 標準化工具暴露協議，Agent 可發現和調用 |
| **A2A (Google)** | Agent 發布 "Agent Card"（技能、I/O 格式），做為介面契約和廣告 |
| **Git Worktree 隔離** | 每個 Agent 在獨立 git worktree 工作，測試通過才合併 |
| **Event Sourcing** | 事件溯源保證所有 Agent 的知識即時一致 |

---

## 三、專案協調者的設計方案

### 3.1 定位

**不是第四個「層級」，而是一個橫切（cross-cutting）的協調機制。**

它在所有層級之上運作，但不介入單一閉環的 5 Phase 執行。就像 Google 的 Coordinator/Dispatcher 模式——負責路由和協調，不負責具體工作。

### 3.2 核心職責

| # | 職責 | 解決的缺口 | 業界對應 |
|---|------|-----------|---------|
| 1 | **介面契約登記簿** | 缺口 1：時機倒置 | Google A2A 的 Agent Card |
| 2 | **依賴圖譜與調度** | 缺口 3：無協調 | Microsoft Supervisor |
| 3 | **變更傳播與漣漪分析** | 缺口 2：通知黑洞 | Microsoft 變更影響管理 |
| 4 | **閉環狀態持久化** | 缺口 4：狀態丟失 | Claude Code Agent Teams 的 Task List |
| 5 | **全局進度儀表板** | 缺口 5：不可見 | MetaGPT Project Manager |
| 6 | **介面凍結與變更控制** | 缺口 7：無凍結機制 | Microsoft 版本化策略 |

自証規模爆炸（缺口 6）通過「分層自証 + 持久化」來解決——協調者將框架自証拆分為多個子驗證，每個子驗證從持久化的檔案讀取，不依賴對話記憶。

### 3.3 不做的事

- 不介入單一閉環的 5 Phase 執行（Phase 1-5 的 Agent 調用不變）
- 不取代自証師的一致性驗證（自証的機制不變，只是輸入來源改為檔案）
- 不做程式碼級的決策（只做模組間的協調，不做模組內的設計）

### 3.4 與現有閉環的整合流程

```
專案協調者（持續運作，橫切所有層級）
│
├── 【開發前】Session 0：專案規劃
│     ├── 定義模組劃分和職責
│     ├── 定義介面契約（IF-x）並登記
│     ├── 建立依賴圖譜
│     ├── 決定開發順序（拓撲排序）
│     └── 凍結核心介面
│
├── 【開發中】Session 1~N：模組閉環
│     ├── 按依賴順序觸發模組閉環
│     ├── 被依賴模組優先（先穩定介面）
│     ├── 獨立模組可並行（用 Agent Teams 或 subagent）
│     ├── 每個閉環完成後 → 持久化產出物到 .claude-loop/
│     ├── 斷點觸發介面變更 → 通知協調者 → 漣漪分析 → 通知受影響模組
│     └── 持續更新全局進度
│
└── 【開發後】Session N+1：框架整合
      ├── 所有介面已預先驗證（壓力大減）
      ├── 框架自証從 .claude-loop/ 讀取各模組的自証結果
      └── 分層驗證：MD-x → 繼承的 MC-x/EP-x → 最終判定
```

### 3.5 新增的 ID 前綴

| 前綴 | 含義 | 層級 | 說明 |
|------|------|------|------|
| IF-x | 介面凍結 (Interface Freeze) | 專案 | 跨模組的介面契約定義 |
| CR-x | 變更請求 (Change Request) | 專案 | 對已凍結介面的變更記錄 |

### 3.6 持久化目錄結構

```
.claude-loop/                        ← 閉環狀態持久化根目錄
├── project-state.md                 ← 全局狀態：模組列表、依賴圖、進度儀表板
├── interfaces/                      ← 介面契約登記簿
│   ├── IF-1_auth-user.md            ← Auth ↔ User 介面契約
│   ├── IF-2_order-payment.md        ← Order ↔ Payment 介面契約
│   └── ...
├── modules/                         ← 各模組的閉環產出物
│   ├── user/
│   │   ├── design-spec.md           ← 最新的設計規格（Phase 1 產出）
│   │   ├── self-verify.md           ← 最新的自証結果（Phase 5 產出）
│   │   └── status.md                ← 閉環狀態（哪個 Phase、通過/回退）
│   ├── auth/
│   │   ├── design-spec.md
│   │   ├── self-verify.md
│   │   └── status.md
│   └── ...
└── changes/                         ← 變更記錄
    ├── CR-1_user-interface-change.md ← 變更記錄：User 模組介面變更
    └── ...
```

### 3.7 實作路徑建議

考慮到 Claude Code Agent Teams 已經提供了底層基礎設施（Task List、Mailbox、Delegate Mode），最務實的實作路徑是：

| 階段 | 做什麼 | 依賴 |
|------|--------|------|
| **v1：持久化先行** | 在 CLAUDE_TEMPLATE.md 中加入 `.claude-loop/` 目錄結構和持久化規則 | 無（純文檔更新） |
| **v2：介面契約** | 加入 IF-x/CR-x 的定義格式和 Session 0 的規劃流程 | v1 |
| **v3：協調者 Agent** | 定義專案協調者的具體行為（可能是一個新的 Skill 或 CLAUDE.md 段落） | v2 |
| **v4：Agent Teams 整合** | 利用 Claude Code Agent Teams 功能實現真正的並行模組開發 | v3 + Agent Teams 穩定版 |

---

## 四、風險與考量

### 4.1 複雜度成本

加入專案協調者會增加方法論的複雜度。對於 2-3 個模組的中型專案，可能過度設計。

**建議**：像閉環本身的觸發條件一樣，設定觸發閾值——「模組數 ≥ 3 且模組間有介面依賴」時才啟用專案協調者。

### 4.2 Token 消耗

Agent Teams 的 token 消耗是單一 session 的數倍（每個 teammate 都是獨立的 Claude instance）。

**建議**：優先用 subagent（較輕量），只有在需要 teammate 之間互相溝通時才用 Agent Teams。

### 4.3 Windows 限制

Agent Teams 的 split pane 模式不支援 Windows Terminal。本 repo 在 Windows 上開發。

**建議**：v1-v3 不依賴 Agent Teams，純粹靠 CLAUDE.md 的指令和 `.claude-loop/` 的持久化。v4 等 Agent Teams 穩定且支援 Windows 後再整合。

### 4.4 方法論膨脹風險

CLAUDE_TEMPLATE.md 已經 455 行。加入專案協調者可能使其膨脹到 600+ 行，影響 LLM 的遵循度。

**建議**：專案協調者的規則放在獨立的 `.claudedocs/process/專案協調.md`，CLAUDE_TEMPLATE.md 只加一個簡短的觸發條件和指引連結。

---

## 五、結論與建議

### 回答核心問題

> 以目前這個開發閉環設計真的夠用嗎？

**單模組 / 小型專案（≤ 2 模組）：夠用。** 三層閉環的 bottom-up 設計在這個規模下運作良好。

**大型多模組專案（≥ 3 模組，有介面依賴）：不夠用。** 有 7 個結構性缺口，其中 3 個是 HIGH 嚴重度。

> 還是需要有一個更上層的管理 agent 來監看整個情況？

**需要，但不是第四個「層級」。** 是一個橫切的「專案協調者」機制，負責：
1. 開發前定義介面契約（top-down）
2. 開發中協調並行、傳播變更
3. 開發後簡化框架自証

### 優先行動建議

1. **短期（可立即做）**：定義 `.claude-loop/` 持久化目錄結構，在 CLAUDE_TEMPLATE.md 中加入跨 session 狀態保存規則
2. **中期**：設計 IF-x/CR-x 介面契約格式，加入 Session 0 專案規劃流程
3. **長期**：整合 Claude Code Agent Teams，實現真正的多 Agent 並行模組開發

---

## 參考來源

- [Google's 8 Multi-Agent Design Patterns (InfoQ, 2026/01)](https://www.infoq.com/news/2026/01/multi-agent-design-patterns/)
- [Microsoft: Designing Multi-Agent Intelligence](https://developer.microsoft.com/blog/designing-multi-agent-intelligence)
- [Claude Code Agent Teams Documentation](https://code.claude.com/docs/en/agent-teams)
- [MetaGPT: Multi-Agent Software Development](https://github.com/FoundationAgents/MetaGPT)
- [LangGraph Multi-Agent Orchestration Guide](https://latenode.com/blog/ai-frameworks-technical-infrastructure/langgraph-multi-agent-orchestration/)
- [CrewAI vs AutoGen Comparison (SparkCo, 2025)](https://sparkco.ai/blog/crewai-vs-autogen-multi-agent-orchestration-2025)
- [Google ADK Multi-Agent Patterns](https://developers.googleblog.com/developers-guide-to-multi-agent-patterns-in-adk/)
- [Agent Interoperability Protocols Survey (arXiv)](https://arxiv.org/html/2505.02279v1)

---

*研究完成。本報告為分析和建議，不含實作程式碼。下一步由用戶決定。*
