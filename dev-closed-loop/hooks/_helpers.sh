#!/usr/bin/env bash
# _helpers.sh — Shared helpers for closed-loop hooks
# Sourced (not executed). Provides project-scoped marker paths to prevent
# cross-project pollution when the same hook system runs on multiple repos.

# Derive a stable, filesystem-safe project key from the current project root.
# Uses CLAUDE_PROJECT_DIR if Claude Code provides it, falls back to PWD.
get_project_key() {
    local project_root="${CLAUDE_PROJECT_DIR:-$(pwd)}"
    printf '%s' "$project_root" | tr '/: ' '___' | tr -dc 'a-zA-Z0-9_.-'
}

# Get the per-project gate base directory.
# Each hook's marker subdirectory should live under this base.
# Example: ${TMPDIR}/claude-code-tools/_Users_foo_myproject/understanding-gate/pending
# (macOS TMPDIR is /var/folders/.../T/, Linux fallback is /tmp)
get_gate_base() {
    local tmp_dir="${TMPDIR:-/tmp}"
    tmp_dir="${tmp_dir%/}"  # strip trailing slash (macOS TMPDIR has one)
    printf '%s/claude-code-tools/%s' "$tmp_dir" "$(get_project_key)"
}
