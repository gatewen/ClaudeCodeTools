# Agent 專家庫

閉環方法論的 8 個專家 agent prompt，涵蓋 Phase 1-5 全流程。

## 設計方法論

每個 agent prompt 基於 **prompt-engineer-agentic v4.1** 三層架構設計：

| 層級 | 目的 | 對應 XML tag |
|------|------|-------------|
| Foundation | 定義 *who*：角色身份與能力邊界 | `<role>`, `<scope>` |
| Structure | 定義 *how*：操作步驟與產出格式 | `<input_contract>`, `<instructions>`, `<output_format>` |
| Execution | 防止失敗：驗證、約束、邊界處理 | `<verification>`, `<constraints>`, `<edge_cases>`, `<anti_patterns>` |

閉環特有的擴展：`<severity_system>`（嚴重度分級）和 artifact 路徑指定。

## Agent 分類

| 類型 | 執行方式 | Agent | Phase |
|------|---------|-------|-------|
| **task** | Agent tool 啟動獨立子 agent，無對話 context | design-reviewer, code-reviewer, security-reviewer, verifier | 1b, 3, 3, 5 |
| **inline** | 主 agent 讀取後作為行為指南，保留對話 context | requirements-analyst, architect, implementer, tester | 1b前, 1, 2, 4 |

## 使用方式

**Task agent**（主 agent 在對應 Phase 執行）：
```
1. 讀取 .claudedocs/agents/[agent-name].md
2. 準備 input_contract 要求的資料包
3. 用 Agent tool 發送完整 prompt + 資料包
4. 接收產出物，驗證完整性
```

**Inline agent**（主 agent 在對應 Phase 參考）：
```
1. 讀取 .claudedocs/agents/[agent-name].md
2. 按 <instructions> 指引執行工作
3. 按 <output_format> 產出結果
4. 按 <verification> 自檢後進入下一 Phase
```

## SC/SP 共存規則

- Agent 專家庫提供**基線能力**，無需任何外部依賴即可運作
- 若 SuperClaude/Superpowers Skills 可用，可作為**增強選項**使用
- CLAUDE_TEMPLATE.md 中的 agent 引用以本目錄為主，SC/SP 為備選

## Frontmatter 欄位

```yaml
---
agent: [名稱，與檔名一致]
phase: [對應的 Phase 或 Section]
type: task | inline
description: [一句話描述角色]
input: [需要的輸入資料摘要]
output: [產出物和寫入位置]
version: 1.0
---
```

## 品質標準

每個 agent prompt 必須通過以下檢查（源自 prompt-engineer-agentic spec builder checklist）：

### Foundation
- [ ] `<role>` 定義專業領域、溝通風格、行為傾向
- [ ] `<scope>` 有 3+ 明確職責和 2+ 明確排除

### Structure
- [ ] `<instructions>` 有編號步驟和觸發條件
- [ ] `<output_format>` 有完整欄位定義和範例片段
- [ ] `<input_contract>` 明確列出必要和可選輸入

### Execution
- [ ] `<verification>` 有產出前自檢步驟
- [ ] `<constraints>` 有不可違反的硬規則
- [ ] `<edge_cases>` 有 3+ 可預見的異常場景
- [ ] `<anti_patterns>` 有 3+ 禁止行為及理由

---

最後修訂：2026-03-28
