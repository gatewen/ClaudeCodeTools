# ClaudeCodeTools

> 中文版本 → [README.md](README.md) · 30-min quick start → [dev-closed-loop/QUICKSTART.md](dev-closed-loop/QUICKSTART.md)

**Personal Claude Code harness distilled from real trial-and-error.** A closed-loop methodology + 6 enforced Hooks + deployable Skill, aimed at making Claude write more reliable code.

> **Positioning**: This is a personal hardcore-discipline toolkit, not a team-grade framework. Tasks under 50 lines / single-file get a fast-pass; only medium and large tasks go through the full closed loop.

## The problem

[Andrej Karpathy's observation](https://x.com/karpathy/status/2015883857489522876):

> "The models make wrong assumptions on your behalf and just run along with them without checking. They overcomplicate code and APIs. They sometimes change/remove comments and code they don't sufficiently understand as side effects."

Two deeper issues this toolkit addresses:
- **Cross-artifact mismatch**: Design says 5 errors, impl handles 3, tests cover 2 — traditional Code Review can't catch this
- **Cognitive premise misjudgment**: Asserting facts based on a single clue (the "GS misjudgment" incident, see issue tracker #003-#005)

## Install

```bash
curl -sL https://raw.githubusercontent.com/gatewen/ClaudeCodeTools/main/setup.sh | bash
```

Downloads to `~/.claude/cache/ClaudeCodeTools/` and deploys the `/dev:init-claude` Skill.

> Developers can also: `git clone https://github.com/gatewen/ClaudeCodeTools.git && cd ClaudeCodeTools && bash setup.sh`

## Use

In any project directory, open Claude Code and run:

```
/dev:init-claude
```

It auto-detects your project (language / framework / test commands), confirms with you, then deploys the closed-loop CLAUDE.md + supporting docs into your repo. Claude will then automatically follow the closed loop on every session.

| Command | Action |
|---------|--------|
| `/dev:init-claude status` | Check deployment status, version, health |
| `/dev:init-claude upgrade` | Pull latest version from GitHub, one-click upgrade |
| `/dev:init-claude uninstall` | Remove closed loop from project |

## How the methodology works

Five-phase closed loop runs automatically per feature:

```
Phase 1  Architect         Write design spec, define interfaces and test strategy
Phase 2  Programmer        Implement to spec; auto-runs code-simplifier after
Phase 3  Code Reviewer     Line-by-line check that code matches spec
Phase 4  Tester            Run tests, validate performance
Phase 5  Verifier          Cross-reference all 4 phases for contradictions
```

Phase 5 is the unique part — it uses an ID system (BC-x for boundary conditions, EH-x for error handling, R-x for review findings) to precisely trace whether design ↔ code ↔ tests ↔ review reports are all aligned. Traditional CI/CD checks each phase independently; this checks across phases.

The v6.x series adds three layers on top:
- **Behavioral philosophy** (v6.0/v6.1): Karpathy's 4 principles as cross-cutting self-checks (Think / Simplicity / Surgical / Goal) + Claude push-back duty in 5 scenarios (small/medium/large tasks)
- **Cognitive verification** (v5.23 + v6.2): fact-claim gate + challenge circuit-breaker + reverse fact-challenge protocol
- **Health metrics + anti-pattern examples** (v6.2/v6.3): 3 indicators with 3-zone thresholds + 5 anti-pattern reference cases

## Six automation Hooks

Deployed alongside, these enforce discipline at the harness level (not relying on Claude's self-discipline):

- **Pre-edit guard** (file modifications): blocks edits without prior understanding-confirmation + impact-chain analysis
- **Pre-delegation gate** (Agent calls): blocks modifying Agent calls without expected-impact statement
- **Understanding flag** (user prompt): detects modify intent, sets flag for the pre-edit guard
- **Incremental lint** (post-edit): runs project lint on changed files
- **Delegation tracker** (post-delegation): records Agent calls automatically
- **Learning-log reminder** (post-commit): checks that learning-log.md is included in commits

## Learn more

- **30-min onboarding**: [dev-closed-loop/QUICKSTART.md](dev-closed-loop/QUICKSTART.md)
- **Full methodology**: [dev-closed-loop/.claudedocs/](dev-closed-loop/.claudedocs/)
- **Design history (v3 → v6.x)**: [dev-closed-loop/design/](dev-closed-loop/design/)
- **Health metrics doc**: [dev-closed-loop/.claudedocs/concepts/方法論運作指標.md](dev-closed-loop/.claudedocs/concepts/方法論運作指標.md)

## License

MIT
