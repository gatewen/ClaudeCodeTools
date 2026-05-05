#!/usr/bin/env bash
# assert.sh — minimal assertion helpers for smoke tests
# Source this from each test-*.sh

assert_eq() {
    local actual="$1"
    local expected="$2"
    local msg="${3:-assertion}"
    if [ "$actual" = "$expected" ]; then
        echo "  ✅ $msg"
        return 0
    fi
    echo "  ❌ $msg: expected '$expected', got '$actual'"
    return 1
}

assert_neq() {
    local actual="$1"
    local unexpected="$2"
    local msg="${3:-assertion}"
    if [ "$actual" != "$unexpected" ]; then
        echo "  ✅ $msg"
        return 0
    fi
    echo "  ❌ $msg: expected NOT '$unexpected', got '$actual'"
    return 1
}

assert_file_exists() {
    local path="$1"
    local msg="${2:-file exists: $path}"
    if [ -f "$path" ]; then
        echo "  ✅ $msg"
        return 0
    fi
    echo "  ❌ $msg: file not found"
    return 1
}

assert_contains() {
    local haystack="$1"
    local needle="$2"
    local msg="${3:-contains}"
    case "$haystack" in
        *"$needle"*)
            echo "  ✅ $msg"
            return 0
            ;;
        *)
            echo "  ❌ $msg: '$needle' not found"
            return 1
            ;;
    esac
}
