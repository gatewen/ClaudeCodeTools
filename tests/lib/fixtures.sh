#!/usr/bin/env bash
# fixtures.sh — temporary directory management with auto-cleanup
# Source this from each test-*.sh that needs isolated temp dirs

# shellcheck disable=SC2034  # populated by make_tmpdir, drained by trap
_CLEANUP_DIRS=()

# Create a temp dir; auto-removed when the calling shell exits.
make_tmpdir() {
    local dir
    dir=$(mktemp -d)
    _CLEANUP_DIRS+=("$dir")
    printf '%s' "$dir"
}

_cleanup_tmpdirs() {
    local d
    for d in "${_CLEANUP_DIRS[@]:-}"; do
        if [ -n "$d" ] && [ -d "$d" ]; then
            rm -rf "$d"
        fi
    done
}

trap _cleanup_tmpdirs EXIT
