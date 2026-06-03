---
name: dev:overview
description: Use when the user wants a visual / human-friendly overview of the dev-closed-loop methodology, especially as an onboarding aid for newcomers. Triggers include "/dev:overview", "/dev:overview gen", or phrases like "介紹方法論"、"閉環是什麼"、"方法論有什麼功能"、"給我看 overview"、"overview"、"介紹"、"幫我看一下這個方法論". Produces a self-contained HTML file with light/dark toggle, three-layer-architecture + workflow visual flow, advanced-mechanism collapsible sections, and current-deployment status (if deployed). NOT for: editing methodology content (that's manual editing of CLAUDE_TEMPLATE.md), deploying methodology (that's /dev:init-claude), cross-session handoff (that's /dev:handoff).
---

# /dev:overview

本指令的完整流程定義在 bundle。請 **Read 並完整遵循**：

```
~/.claude/dev-closed-loop/overview/SKILL.md
```

該檔會按需指示你讀取對應 references（皆位於 `~/.claude/dev-closed-loop/overview/references/`，含 `template.html` 與內容/對映/視覺規格，相對路徑由該檔自身位置解析）。

**參數**：把使用者給的參數（`$ARGUMENTS`，如 `gen`）原樣套用。

全程繁體中文。
