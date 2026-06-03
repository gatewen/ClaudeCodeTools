---
name: dev:handoff
description: >-
  Use when the user wants to save or load session state for cross-session
  handoff. Triggers include "/dev:handoff", "/dev:handoff save",
  "/dev:handoff load", or phrases like 「換 session」、「session 滿了」、
  「準備收工」、「交接」、「繼續上次」、「上次做到哪」、「handoff」.
  Default action is save when no argument is given. Paths are resolved per
  current working directory (NOT hard-coded to any single project).
  Bundled with dev-closed-loop methodology; functionally equivalent to wt:handoff.
  NOT for: general note-taking, project documentation, or non-session work tracking.
---

# /dev:handoff

本指令的完整流程定義在 bundle。請 **Read 並完整遵循**：

```
~/.claude/dev-closed-loop/handoff/SKILL.md
```

該檔會按需指示你讀取對應 references（皆位於 `~/.claude/dev-closed-loop/handoff/references/`，相對路徑由該檔自身位置解析）。

**參數**：把使用者給的參數（`$ARGUMENTS`）或自然語意原樣套用——無參數＝save 預設；save / load 及其別名（out·存·寫 / in·讀·載）的對照見 bundle 的 SKILL.md。

全程繁體中文。
