# Bash 語言 Skill

> 閉環整合：為 Phase 1-5 提供 Bash/Shell 特定的規範和工具鏈指令。
> 內容來源：wshobson/agents shell-scripting（bash-defensive-patterns + shellcheck-configuration + bats-testing-patterns）、einverne/dotfiles shell-scripting

## 語言偵測觸發

```yaml
檔案模式: ["*.sh", "*.bash"]
配置檔案: ["Makefile", ".shellcheckrc"]
Shebang 識別: ["#!/bin/bash", "#!/usr/bin/env bash", "#!/bin/sh"]
套件關鍵字: ["bash", "shellcheck", "bats"]
```

---

## Phase 1：架構師補充 📐

### 防禦性基礎策略

**每個腳本的起手式**：

```bash
#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

readonly SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
readonly SCRIPT_NAME="$(basename -- "${BASH_SOURCE[0]}")"
```

**旗標說明**：

| 旗標 | 作用 | 設計階段決策點 |
|------|------|--------------|
| `set -E` | ERR trap 在函式中也生效 | 需要細粒度錯誤追蹤時啟用 |
| `set -e` | 任何指令失敗立即退出 | 預設啟用，除非有刻意忽略失敗的需求 |
| `set -u` | 引用未定義變數立即退出 | 預設啟用，配合 `${VAR:-default}` 提供預設值 |
| `set -o pipefail` | pipe 中任一指令失敗即失敗 | 預設啟用，除非需要忽略 pipe 中段失敗 |

**POSIX 相容性決策**：在 Phase 1 決定腳本目標 shell——純 Bash（可用 `[[ ]]`、陣列、process substitution）或 POSIX sh（只用 `[ ]`、無陣列、最大可移植性）。此決策影響 Phase 2 的所有語法選擇。

### 常見 BC-x 模式

| BC 模式 | 說明 | Bash 慣用處理 |
|---------|------|-------------|
| 空值參數 | 必填參數未傳入 | `${1:?錯誤訊息}` 或 `[[ $# -ge N ]]` 檢查 |
| 含空格路徑 | 檔案路徑有空格或特殊字元 | 所有變數加雙引號 `"$var"` |
| 指令不存在 | 依賴的外部工具未安裝 | `command -v tool &>/dev/null` 前置檢查 |
| 空目錄迭代 | glob 無匹配時展開為字面字串 | `shopt -s nullglob` 或檢查檔案存在 |
| 並行競態 | 多個背景程序存取同一資源 | `flock` 檔案鎖或 atomic write（寫暫存再 mv） |

### 常見 EH-x 模式

| EH 模式 | 說明 | Bash 慣用處理 |
|---------|------|-------------|
| 清理失敗 | 腳本中斷後暫存檔殘留 | `trap cleanup EXIT`（EXIT trap 保證執行） |
| 錯誤定位 | 錯誤發生位置難以追蹤 | `trap 'echo "Error on line $LINENO" >&2' ERR` |
| 信號中斷 | Ctrl+C / SIGTERM 未優雅處理 | `trap cleanup SIGTERM SIGINT` + 背景 PID 追蹤 |
| 管線靜默失敗 | 管線中間指令失敗被忽略 | `set -o pipefail` + 逐步檢查 |
| 外部指令逾時 | 網路/IO 操作無限等待 | `timeout` 指令包裝或自訂計時器 |

### 設計模式建議

| 模式 | 適用場景 | 關鍵特徵 |
|------|---------|---------|
| 安全暫存 | 需要暫存檔案的操作 | `mktemp -d` + `trap cleanup EXIT` |
| 冪等設計 | 可重複執行的腳本 | `mkdir -p`、`[ -f ] && return` 避免重複操作 |
| Dry-run | 破壞性操作需要預覽 | `run_cmd()` 包裝函式 + `--dry-run` 旗標 |
| 結構化日誌 | 需要追蹤執行過程 | `log_info/warn/error()` 函式 + 時間戳 |
| 依賴檢查 | 多工具協作的腳本 | `check_dependencies()` 前置驗證 |
| 參數解析 | 接受多種選項的腳本 | `while [[ $# -gt 0 ]]; case` 模式 |

---

## Phase 2：程序設計師補充 💻

### 編碼慣例

```yaml
命名規則:
  變數: lower_snake_case
  常數/環境變數: UPPER_SNAKE_CASE
  函式: lower_snake_case（動詞前綴：validate_、process_、check_、handle_）
  檔案: kebab-case.sh
  readonly 標記: 不會變的變數用 readonly 或 local -r

引號規則:
  - 所有變數引用必須加雙引號："$var"、"${array[@]}"
  - 例外：算術運算 $(( )) 內部、[[ ]] 的右側模式匹配
  - 字面字串用單引號：'no expansion here'

函式結構:
  - 用 local 宣告函式內變數（避免污染全域）
  - 用 local -r 標記函式內常數
  - 前幾行驗證參數，失敗立即 return 1
  - 錯誤訊息輸出到 stderr：echo "ERROR: ..." >&2

輸出規則:
  - 正常輸出 → stdout
  - 錯誤/日誌 → stderr（>&2）
  - 不要用 echo 輸出二進位資料，用 printf
```

### 專案結構

```
project/
├── bin/              # 主要可執行腳本
│   └── main.sh
├── lib/              # 共用函式庫（source 引入）
│   ├── logging.sh
│   ├── validation.sh
│   └── utils.sh
├── tests/            # BATS 測試
│   ├── test_main.bats
│   ├── test_helper.sh
│   └── fixtures/     # 測試用靜態資料
├── configs/          # 配置檔案
├── .shellcheckrc     # ShellCheck 設定
└── Makefile          # 任務入口
```

### 工具鏈指令

| 用途 | 指令 | 說明 |
|------|------|------|
| **增量驗證（lint）** | `shellcheck -x "$FILE"` | Phase 2 每完成一個檔案執行 |
| **語法檢查** | `bash -n script.sh` | 不執行，只驗語法 |
| **格式化** | `shfmt -w -i 4 -ci script.sh` | 統一縮排和格式（需安裝 shfmt） |
| **全專案 lint** | `find . -name '*.sh' -print0 \| xargs -0 -P4 shellcheck` | 並行檢查所有腳本 |

### ShellCheck 設定

```bash
# .shellcheckrc — 專案級設定
shell=bash
enable=avoid-nullary-conditions
enable=require-variable-braces
# external-sources=true  # 若有 source 外部檔案
```

### 核心防禦模式

**安全暫存檔案**：
```bash
trap 'rm -rf -- "$TMPDIR"' EXIT
TMPDIR=$(mktemp -d) || { echo "ERROR: Failed to create temp dir" >&2; exit 1; }
```

**穩健的參數解析**：
```bash
while [[ $# -gt 0 ]]; do
    case "$1" in
        -v|--verbose) VERBOSE=true; shift ;;
        -o|--output)  OUTPUT="$2"; shift 2 ;;
        -h|--help)    usage; exit 0 ;;
        --)           shift; break ;;
        *)            echo "ERROR: Unknown option: $1" >&2; usage; exit 1 ;;
    esac
done
```

**依賴檢查**：
```bash
check_dependencies() {
    local -a missing=()
    local -a required=("jq" "curl" "shellcheck")

    for cmd in "${required[@]}"; do
        command -v "$cmd" &>/dev/null || missing+=("$cmd")
    done

    if [[ ${#missing[@]} -gt 0 ]]; then
        echo "ERROR: Missing commands: ${missing[*]}" >&2
        return 1
    fi
}
```

**結構化日誌**：
```bash
log_info()  { echo "[$(date +'%Y-%m-%d %H:%M:%S')] INFO:  $*" >&2; }
log_warn()  { echo "[$(date +'%Y-%m-%d %H:%M:%S')] WARN:  $*" >&2; }
log_error() { echo "[$(date +'%Y-%m-%d %H:%M:%S')] ERROR: $*" >&2; }
```

---

## Phase 3：檢核師補充 🔍

### 語言專屬審查清單

| 項目 | 嚴重度 | 檢查重點 |
|------|--------|---------|
| 未加引號的變數 | high | `$var` 必須寫成 `"$var"`，防止 word splitting 和 glob 展開 |
| 缺少 strict mode | high | 腳本開頭必須有 `set -Eeuo pipefail` |
| eval 使用 | high | 禁止 `eval "$user_input"`，用陣列或安全替代方案 |
| 未處理的 trap | high | 有暫存檔案/背景程序的腳本必須有 EXIT trap |
| 錯誤訊息到 stdout | medium | 錯誤訊息必須 `>&2` 輸出到 stderr |
| 解析 ls 輸出 | medium | 用 `find` + `-print0` 或 glob 替代 `ls` 解析 |
| 硬編碼路徑 | medium | 用 `SCRIPT_DIR` 變數和 `$HOME` 替代絕對路徑 |
| 函式缺少 local | low | 函式內變數必須用 `local` 宣告，避免全域污染 |

### ShellCheck 重點規則

| 規則 | 嚴重度 | 說明 | 修正方式 |
|------|--------|------|---------|
| SC2086 | high | 變數未加引號 | `"$var"` |
| SC2181 | medium | 間接檢查 `$?` | `if command; then` 直接檢查 |
| SC2009 | medium | `ps \| grep` 查程序 | 用 `pgrep -f` 替代 |
| SC2012 | medium | 解析 `ls` 輸出 | 用 `find` 或 glob |
| SC2015 | medium | `&& \|\|` 代替 if-else | 用完整 `if-then-else` |
| SC2016 | low | 單引號內不會展開變數 | 改用雙引號或確認刻意 |
| SC3043 | low | `local` 在 POSIX sh 中未定義 | POSIX 模式下避免使用 |

### 安全反模式

| 反模式 | 風險 | 修正方式 |
|--------|------|---------|
| `eval "$input"` | 指令注入 | 用陣列存指令，直接 `"${cmd[@]}"` 執行 |
| 未驗證使用者輸入用於路徑 | Path traversal | 白名單驗證 + `realpath` 檢查 |
| `rm -rf "$dir/"` 且 dir 可能為空 | 刪除根目錄 | 先 `[[ -n "$dir" ]]` 檢查 |
| 密鑰硬編碼在腳本中 | 機密洩露 | 環境變數或外部 secret manager |
| 暫存檔用固定名稱 | 競態條件、符號連結攻擊 | `mktemp` 產生隨機名稱 |
| `curl \| bash` | 遠端程式碼執行 | 先下載再檢查後執行 |

### 效能反模式

| 反模式 | 影響 | 修正方式 |
|--------|------|---------|
| 迴圈中重複 fork 子程序 | 效能瓶頸 | 用內建指令（`${var//pattern/replace}`）替代 `sed` |
| `cat file \| grep` | 無用 cat（UUOC） | `grep pattern file` 直接讀檔 |
| 逐行讀取大檔案在 while 迴圈中 | 緩慢 | 用 `awk` 或 `sed` 批次處理 |
| 未使用並行 | 長時間循序操作 | `xargs -P` 或背景程序 + `wait` |

### 結構安全

| 項目 | 嚴重度 | 檢查重點 |
|------|--------|---------|
| 資源未清理 | high | `mktemp` 必有對應 `trap cleanup EXIT`，背景程序必有 `wait` 或 `kill` |
| 分支窮舉缺失 | medium | `case` 語句必有 `*) die "unknown" ;;` 兜底，禁止靜默忽略未知選項 |
| 錯誤靜默吞掉 | high | `set -Eeuo pipefail` 全覆蓋，禁止 `2>/dev/null` 吞掉關鍵錯誤，管線每段需可追蹤 |
| 全域變數污染 | medium | 函式內變數必須 `local` 宣告，常數用 `readonly`，禁止隱式全域副作用 |

---

## Phase 4：測試師補充 🧪

### 測試框架與指令

| 用途 | 工具 | 指令 |
|------|------|------|
| **單元測試** | BATS（推薦） | `bats tests/` |
| **覆蓋率** | kcov + BATS | `bats --tap tests/ && kcov coverage/ tests/` |
| **靜態分析** | ShellCheck | `shellcheck *.sh` |
| **語法驗證** | Bash 內建 | `bash -n script.sh` |
| **並行測試** | BATS | `bats --jobs 4 tests/` |

### 測試模式

**基礎結構**：
```bash
#!/usr/bin/env bats

# 載入被測腳本的函式
setup() {
    source "${BATS_TEST_DIRNAME}/../lib/utils.sh"
    TMPDIR=$(mktemp -d)
    export TMPDIR
}

teardown() {
    rm -rf "$TMPDIR"
}

# BC-1: 空值參數
@test "validate_input: returns 1 on empty argument" {
    run validate_input ""
    [ "$status" -eq 1 ]
    [[ "$output" == *"ERROR"* ]]
}

# EH-1: 檔案不存在
@test "process_file: returns 1 on missing file" {
    run process_file "/nonexistent/file.txt"
    [ "$status" -eq 1 ]
    [[ "$output" == *"not found"* ]]
}

# 正常路徑
@test "process_file: processes valid file correctly" {
    echo "test data" > "$TMPDIR/input.txt"
    run process_file "$TMPDIR/input.txt"
    [ "$status" -eq 0 ]
    [[ "$output" == *"success"* ]]
}
```

**錯誤條件測試**：
```bash
@test "script fails with permission denied" {
    touch "$TMPDIR/readonly.txt"
    chmod 000 "$TMPDIR/readonly.txt"
    run process_file "$TMPDIR/readonly.txt"
    [ "$status" -ne 0 ]
    chmod 644 "$TMPDIR/readonly.txt"  # 清理
}

@test "script shows usage on invalid option" {
    run main.sh --invalid-option
    [ "$status" -ne 0 ]
    [[ "$output" == *"Usage:"* ]]
}
```

### Mock/Stub 模式

```bash
# 指令 stub — 建立假的外部指令
setup() {
    STUBS_DIR="$TMPDIR/stubs"
    mkdir -p "$STUBS_DIR"
    export PATH="$STUBS_DIR:$PATH"
}

create_stub() {
    local cmd="$1" output="$2" code="${3:-0}"
    cat > "$STUBS_DIR/$cmd" <<EOF
#!/bin/bash
echo "$output"
exit $code
EOF
    chmod +x "$STUBS_DIR/$cmd"
}

@test "handles curl failure gracefully" {
    create_stub curl "Connection refused" 7
    run fetch_data "https://example.com"
    [ "$status" -eq 1 ]
    [[ "$output" == *"ERROR"* ]]
}
```

```bash
# 函式 mock — 覆蓋被測腳本中的函式
setup() {
    source "${BATS_TEST_DIRNAME}/../bin/deploy.sh"
}

@test "deploy skips in dry-run mode" {
    # 覆蓋真實的 deploy 函式
    actual_deploy() { echo "SHOULD NOT RUN"; return 1; }
    export -f actual_deploy

    DRY_RUN=true run deploy_to_server
    [ "$status" -eq 0 ]
    [[ "$output" == *"DRY RUN"* ]]
}
```

### CI/CD 整合

```yaml
# GitHub Actions
- name: Install BATS
  run: npm install --global bats

- name: Run ShellCheck
  run: find . -name '*.sh' -exec shellcheck {} \;

- name: Run BATS tests
  run: bats tests/
```

---

## Phase 5：自證師補充 ✅

### 驗證指令

Phase 5 自證時依序執行：

```bash
# 1. 語法檢查（驗語法正確）
bash -n bin/*.sh lib/*.sh

# 2. ShellCheck 靜態分析（驗程式碼品質 + 安全）
shellcheck bin/*.sh lib/*.sh

# 3. 測試（驗邏輯正確性）
bats tests/

# 4. 若有 Makefile 的 build target
make build  # 或跳過（Bash 無需編譯）
```

### 品質指標

| 指標 | 目標 | 工具 |
|------|------|------|
| ShellCheck 通過 | 0 error、0 warning | `shellcheck --severity=warning` |
| 測試覆蓋率 | BC/EH 100% | `bats tests/` 全部 pass |
| 語法檢查 | 0 error | `bash -n` 所有腳本 |
| 嚴格模式 | 所有腳本啟用 | grep 檢查 `set -Eeuo pipefail` |

---

最後修訂：2026-02-24
