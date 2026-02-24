# Go 語言 Skill

> 閉環整合：為 Phase 1-5 提供 Go 特定的規範和工具鏈指令。
> 內容來源：Jeffallan/claude-skills Go Pro（3,624 ⭐）+ Effective Go

## 語言偵測觸發

```yaml
檔案模式: ["*.go"]
配置檔案: ["go.mod", "go.sum"]
套件關鍵字: ["module", "require"]
```

---

## Phase 1：架構師補充 📐

### 型別系統指南

**參數與回傳值定義**：

```go
// ✅ 用多回傳值表達錯誤（Go 慣用法）
func ProcessOrder(ctx context.Context, order Order) (ProcessedOrder, error)

// ✅ 用 interface 定義行為契約
type OrderProcessor interface {
    Process(ctx context.Context, order Order) (ProcessedOrder, error)
    Validate(order Order) error
}

// ✅ 用 Functional Options 處理可選配置
type Option func(*Config)
func WithTimeout(d time.Duration) Option {
    return func(c *Config) { c.Timeout = d }
}
func NewClient(opts ...Option) *Client
```

**型別設計原則**：

| 技術 | 適用場景 | 範例 |
|------|---------|------|
| Struct embedding | 組合行為（非繼承） | `type Server struct { *http.Server }` |
| Interface 隱式實作 | 解耦合，依賴抽象 | 不用 `implements` 關鍵字 |
| Generics 約束 | 型別安全的通用容器/演算法 | `func Map[T, U any](s []T, f func(T) U) []U` |
| 自訂型別 | 語義化原始型別 | `type UserID int64` |
| Enum 模擬 | `iota` + `String()` 方法 | `type Status int; const (Active Status = iota)` |

### 常見 BC-x 模式

| BC 模式 | 說明 | Go 慣用處理 |
|---------|------|-----------|
| nil 指標 | nil pointer dereference | 回傳前檢查 nil，用 value type 優先 |
| 空 slice | nil slice vs 空 slice | `len(s) == 0` 統一檢查 |
| Context 取消 | 超時或手動取消 | `select { case <-ctx.Done(): }` |
| 並行競態 | goroutine 資料競爭 | `sync.Mutex`、channel、`-race` 偵測 |
| 零值語義 | struct 零值是否有效 | 設計零值有意義或用 constructor |

### 常見 EH-x 模式

| EH 模式 | 說明 | Go 慣用處理 |
|---------|------|-----------|
| 多層錯誤 | 錯誤上下文遺失 | `fmt.Errorf("process order: %w", err)` wrapping |
| 自訂錯誤型別 | 需要程式化判斷錯誤類型 | 實作 `error` interface + `errors.Is/As` |
| panic 恢復 | 不可預期的 panic | `defer func() { if r := recover(); r != nil {} }()` |
| 資源洩漏 | goroutine/connection 未關閉 | `defer close()` + context 取消 |

### 設計模式建議

| 模式 | 適用場景 | 關鍵特徵 |
|------|---------|---------|
| Functional Options | 可選配置的函式/建構子 | `WithXxx(v)` 函式回傳 `Option` |
| Interface Composition | 組合小 interface 成大 interface | `io.ReadWriter = io.Reader + io.Writer` |
| Worker Pool | 並行任務處理 | goroutine pool + channel 排隊 |
| Fan-out/Fan-in | 平行處理後合併結果 | 多 goroutine → 單一 channel 收集 |
| Pipeline | 資料流式處理 | channel 串接多個處理階段 |
| Repository | 資料存取抽象 | interface 定義 + struct 實作 |

---

## Phase 2：程序設計師補充 💻

### 編碼慣例

```yaml
命名規則:
  套件: 全小寫單字（不用底線或混合大小寫）
  匯出: PascalCase（大寫開頭）
  未匯出: camelCase（小寫開頭）
  Interface: 行為名詞（Reader, Writer, Closer）
  檔案: snake_case.go
  測試檔案: xxx_test.go
  常數: PascalCase 或 camelCase（依匯出與否）

錯誤處理:
  - 永遠處理 error，不用 `_` 忽略
  - 錯誤訊息小寫開頭，不加句點
  - 用 %w wrap 錯誤以保留鏈

Import 順序:
  1. 標準庫
  2. 外部套件
  3. 專案內部套件
  （各組之間空行分隔）
```

### 專案結構

```
project/
├── cmd/             # 主程式入口（main packages）
│   └── server/
│       └── main.go
├── internal/        # 私有套件（不對外匯出）
│   ├── handler/     # HTTP handler
│   ├── service/     # 業務邏輯
│   ├── repository/  # 資料存取
│   └── model/       # 資料模型
├── pkg/             # 可公開使用的套件
├── api/             # API 定義（OpenAPI, protobuf）
├── configs/         # 配置檔案
├── go.mod
└── go.sum
```

### 工具鏈指令

| 用途 | 指令 | 說明 |
|------|------|------|
| **增量驗證（lint）** | `golangci-lint run ./...` | Phase 2 每完成一個檔案執行 |
| **格式化** | `gofmt -w .` 或 `goimports -w .` | Go 強制統一格式 |
| **建置** | `go build ./...` | 編譯所有套件 |
| **競態偵測** | `go build -race ./...` | 偵測資料競態 |
| **靜態分析** | `go vet ./...` | 官方靜態分析工具 |

### 並行模式

**Worker Pool**：
```go
func workerPool(ctx context.Context, jobs <-chan Job, results chan<- Result, workers int) {
    var wg sync.WaitGroup
    for i := 0; i < workers; i++ {
        wg.Add(1)
        go func() {
            defer wg.Done()
            for job := range jobs {
                select {
                case <-ctx.Done():
                    return
                case results <- process(job):
                }
            }
        }()
    }
    wg.Wait()
    close(results)
}
```

**Rate Limiter**：
```go
limiter := rate.NewLimiter(rate.Every(time.Second), 10) // 10 req/s
if err := limiter.Wait(ctx); err != nil {
    return fmt.Errorf("rate limit: %w", err)
}
```

---

## Phase 3：檢核師補充 🔍

### 語言專屬審查清單

| 項目 | 嚴重度 | 檢查重點 |
|------|--------|---------|
| 錯誤忽略 `_` | high | 禁止 `_, _ = someFunc()`，所有 error 必須處理 |
| goroutine 洩漏 | high | 確認所有 goroutine 有結束機制（context/done channel） |
| 競態條件 | high | 共享可變狀態必須有 mutex 或 channel 保護 |
| nil map 寫入 | high | 寫入前必須 `make(map...)` 初始化 |
| defer 在迴圈中 | medium | 迴圈中的 defer 會累積，改用立即函式 |
| interface 過大 | medium | 單一 interface 不超過 3-5 個方法 |
| context 未傳遞 | medium | 所有 IO 操作應接受 `context.Context` |

### 安全反模式

| 反模式 | 風險 | 修正方式 |
|--------|------|---------|
| SQL 字串拼接 | SQL injection | 用 prepared statement + `$1` 參數 |
| 未驗證輸入用於路徑 | Path traversal | `filepath.Clean()` + 白名單驗證 |
| 硬編碼密鑰 | 機密洩露 | 環境變數 + vault |
| 未設定 HTTP timeout | DoS | `http.Client{Timeout: 30 * time.Second}` |
| `crypto/md5` 用於安全 | 弱雜湊 | 用 `crypto/sha256` 或 `bcrypt` |

### 效能反模式

| 反模式 | 影響 | 修正方式 |
|--------|------|---------|
| 頻繁小 allocation | GC 壓力 | `sync.Pool`、預分配 slice |
| 字串大量拼接 | O(n²) | `strings.Builder` |
| 不必要的 reflect | 執行速度慢 | 用泛型或程式碼生成替代 |
| 未設定 buffer | IO 效能差 | `bufio.Reader/Writer` |

---

## Phase 4：測試師補充 🧪

### 測試框架與指令

| 用途 | 工具 | 指令 |
|------|------|------|
| **單元測試** | testing（標準庫） | `go test ./...` |
| **覆蓋率** | testing | `go test -cover ./...` |
| **詳細覆蓋率** | testing | `go test -coverprofile=coverage.out ./... && go tool cover -html=coverage.out` |
| **競態偵測** | testing | `go test -race ./...` |
| **基準測試** | testing | `go test -bench=. ./...` |
| **模糊測試** | testing | `go test -fuzz=FuzzXxx ./...` |
| **斷言庫** | testify（推薦） | `require.Equal(t, expected, actual)` |

### 測試模式

**Table-Driven Tests（Go 核心測試模式）**：
```go
func TestProcessOrder(t *testing.T) {
    tests := []struct {
        name     string
        input    Order
        want     ProcessedOrder
        wantErr  error
        specID   string // BC-x / EH-x 對應
    }{
        {
            name:   "BC-1: empty order",
            input:  Order{},
            wantErr: ErrEmptyOrder,
            specID: "BC-1",
        },
        {
            name:   "EH-1: invalid amount",
            input:  Order{Amount: -1},
            wantErr: ErrInvalidAmount,
            specID: "EH-1",
        },
        {
            name:   "happy path",
            input:  validOrder,
            want:   expectedResult,
            specID: "",
        },
    }
    for _, tt := range tests {
        t.Run(tt.name, func(t *testing.T) {
            got, err := ProcessOrder(context.Background(), tt.input)
            if tt.wantErr != nil {
                require.ErrorIs(t, err, tt.wantErr)
                return
            }
            require.NoError(t, err)
            require.Equal(t, tt.want, got)
        })
    }
}
```

**基準測試**：
```go
func BenchmarkProcessOrder(b *testing.B) {
    order := validOrder
    for i := 0; i < b.N; i++ {
        ProcessOrder(context.Background(), order)
    }
}
```

### Mock/Stub 模式

```go
// Interface-based mock（推薦）
type mockRepository struct {
    findByIDFunc func(ctx context.Context, id int64) (*User, error)
}

func (m *mockRepository) FindByID(ctx context.Context, id int64) (*User, error) {
    return m.findByIDFunc(ctx, id)
}

// 使用
repo := &mockRepository{
    findByIDFunc: func(ctx context.Context, id int64) (*User, error) {
        return &User{ID: id, Name: "test"}, nil
    },
}
service := NewUserService(repo)
```

---

## Phase 5：自証師補充 ✅

### 驗證指令

Phase 5 自証時依序執行：

```bash
# 1. 靜態分析（驗程式碼品質）
go vet ./...

# 2. Lint 檢查（驗編碼規範）
golangci-lint run ./...

# 3. 建置（驗編譯正確）
go build ./...

# 4. 競態偵測建置
go build -race ./...

# 5. 測試（驗邏輯正確性 + 競態）
go test -race -cover ./...
```

### 品質指標

| 指標 | 目標 | 工具 |
|------|------|------|
| 編譯通過 | 0 error | `go build` |
| 靜態分析 | 0 warning | `go vet` + `golangci-lint` |
| 測試覆蓋率 | BC/EH 100% | `go test -cover` |
| 競態偵測 | 0 race | `go test -race` |
| 基準測試 | 無回歸 | `go test -bench` |

---

最後修訂：2026-02-24
