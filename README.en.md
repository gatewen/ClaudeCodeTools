# ClaudeCodeTools

Make Claude Code think about two things before it touches existing code: who depends on this, and is what I believe actually true.

> **Positioning**: a personal tool the author holds themself to. The repo is public and you are welcome to fork, learn from, or use it, but it is not promoted and comes with no support commitment. MIT licensed (see `LICENSE`).
>
> **中文版** → [README.md](README.md)

## What it is

A CLAUDE.md template of about 125 lines, three hooks, and a one-command deployer. Once deployed into a project, every Claude Code session follows these rules:

1. **Size the task before acting.** A one-line fix is just done. A new module gets a short design first, then implementation, then a check that every behavior contract has code and a test.
2. **Write down what a change touches before making it.** A hook blocks the first edit to an existing source file in each turn and asks Claude to write 2-4 lines of impact analysis first. You see the reasoning before the edit lands.
3. **Check evidence before asserting facts about the environment.** Literal evidence, a counter-example check, and a shared-value check, all learned from a real misjudgment incident.
4. **Push back only in five situations**, otherwise do as asked.

## What it is not

Versions 3 through 7 were a five-role pipeline (architect, implementer, reviewer, tester, verifier). Six controlled experiments in May 2026 showed that, for a frontier model, the pipeline gave zero correctness gain at up to 7x the cost. v8 removes it and keeps only what the experiments pointed to: write the contract down, get one review from a context that did not see the original reasoning, and the four disciplines above. Details in `dev-closed-loop/.claudedocs/concepts/閉環核心理念.md` (Chinese).

## Install

```bash
curl -sL https://raw.githubusercontent.com/gatewen/ClaudeCodeTools/main/setup.sh | bash
```

Or clone and run `bash setup.sh`.

| Platform | Support | Notes |
|----------|---------|-------|
| macOS | primary | Full smoke suite runs before each release |
| Linux | best effort | Should work; no Linux-specific tests |
| Windows | Git Bash | Repo clones on native Windows since v7.1. Hooks and tests verified under Git Bash. Needs `jq` or a working `python3` (the Microsoft Store stub does not count). Native cmd / PowerShell unsupported |

Dependencies: `bash 3.2+`, `git`, `curl`, plus one of `jq` or `python3`.

If you would rather not pipe to bash, download `setup.sh`, read it, then run it. It downloads a tarball to `~/.claude/cache/`, copies two markdown commands to `~/.claude/commands/dev/`, one bundle to `~/.claude/dev-closed-loop/`, four workflow scripts to `~/.claude/workflows/`, and prints a verification report. It does not touch PATH, cron, or install software.

## Use

In a project directory, run `/dev:init-claude`. It detects language, framework, test and build commands, asks you to confirm, and deploys CLAUDE.md, five docs, and three hooks.

| Command | Purpose |
|---------|---------|
| `/dev:init-claude status` | Deployment status, version, leftover v7 files |
| `/dev:init-claude upgrade` | Fetch latest from GitHub and upgrade |
| `/dev:init-claude uninstall` | Remove from project |
| `/dev:handoff save` / `load` | Cross-session handoff |
| `/dev-prd` `/dev-design` `/dev-review` `/dev-verify` | Multi-agent workflows (need Claude Code v2.1.154+, paid plan, research preview; CLAUDE.md has a fallback when unavailable) |

## Hooks

| Hook | Trigger | Behavior |
|------|---------|----------|
| `impact-analysis-guard.sh` | First edit to an existing source file per turn | Blocks once, prints a filename-based rough search as a starting point, asks for 2-4 lines of impact analysis, passes on retry. Ignores new files and md / json / yaml. Only intercepts Write / Edit, not Bash |
| `causal-chain-reset.sh` | Every user prompt | Clears this session's markers so each turn re-analyzes. Never blocks |
| `incremental-lint.sh` | After edit | Per-file lint for js / ts, py, go. Other languages not covered |

Hooks are reminders, not guarantees. They guarantee a pause and a visible analysis; correctness still comes from the model and your review. Hooks do not depend on python.

## Version

Current: **v8.0.0** (2026-09-03). Full history in [dev-closed-loop/README.md](dev-closed-loop/README.md) (Chinese).

| Version | Summary |
|---------|---------|
| **v8.0.0** | Slim-down: template 344 → 134 lines, deployed docs 33 → 5, hooks 6 → 3, `/dev:overview` removed. Impact hook narrowed to existing source files, messages via stderr, no python dependency |
| v7.x | Workflow-first refactor, Windows compatibility, handoff hardening |
| v6.x | Karpathy principles, cognitive verification, KPIs, examples |
| v5.x | Five-phase loop, hook system, agent library, auto-update |
