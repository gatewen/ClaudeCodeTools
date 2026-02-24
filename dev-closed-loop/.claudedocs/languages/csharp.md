# C# 語言 Skill

> 閉環整合：為 Phase 1-5 提供 C# 特定的規範和工具鏈指令。
> 內容來源：Jeffallan/claude-skills C# Developer（3,624 ⭐）+ Aaronontheweb/dotnet-skills（408 ⭐）

## 語言偵測觸發

```yaml
檔案模式: ["*.cs", "*.cshtml", "*.razor"]
配置檔案: ["*.csproj", "*.sln", "Directory.Build.props", "global.json"]
套件關鍵字: ["dotnet", "NuGet", "Microsoft.NET"]
```

---

## Phase 1：架構師補充 📐

### 型別系統指南

**參數與回傳值定義**：

```csharp
// ✅ 用 Result pattern 表達可失敗操作
public Result<ProcessedOrder, OrderError> ProcessOrder(Order order)

// ✅ 用 record 定義不可變資料模型（C# 10+）
public record Order(string Id, decimal Amount, IReadOnlyList<OrderItem> Items);

// ✅ 用 discriminated union 模擬（sealed hierarchy）
public abstract record ApiResponse<T>;
public record Success<T>(T Data) : ApiResponse<T>;
public record Error<T>(AppError Error) : ApiResponse<T>;
public record Loading<T>() : ApiResponse<T>;

// ✅ 用 interface 定義行為契約
public interface IOrderProcessor
{
    Task<ProcessedOrder> ProcessAsync(Order order, CancellationToken ct = default);
    ValidationResult Validate(Order order);
}
```

**Modern C# 特性（C# 12+）**：

| 技術 | 適用場景 | 範例 |
|------|---------|------|
| Primary Constructors | 簡化依賴注入 | `class Service(IRepo repo)` |
| Collection Expressions | 集合初始化 | `int[] nums = [1, 2, 3];` |
| Raw String Literals | 多行字串/嵌入語法 | `"""{"key": "value"}"""` |
| Required Members | 強制初始化 | `public required string Name { get; init; }` |
| Pattern Matching | 複雜條件判斷 | `order is { Amount: > 0, Items.Count: > 0 }` |
| `record struct` | 值型別不可變資料 | `record struct Point(int X, int Y);` |

### 常見 BC-x 模式

| BC 模式 | 說明 | C# 慣用處理 |
|---------|------|-----------|
| Null 值 | Nullable reference types | 啟用 `<Nullable>enable</Nullable>` + `?` 標記 |
| 空集合 | 空 List/Array | `Array.Empty<T>()` 或 `[]` + 判空 |
| 字串處理 | null/empty/whitespace | `string.IsNullOrWhiteSpace()` |
| 非同步取消 | CancellationToken | 所有 async 方法接受 `CancellationToken` |
| 數值溢位 | 整數/浮點溢位 | `checked` 關鍵字 或 `decimal` 型別 |
| Dispose 遺漏 | 資源未釋放 | `using` statement + `IAsyncDisposable` |

### 常見 EH-x 模式

| EH 模式 | 說明 | C# 慣用處理 |
|---------|------|-----------|
| 自訂例外 | 業務邏輯錯誤 | 繼承 `Exception`，加 `[Serializable]` |
| 例外過濾 | 選擇性捕獲 | `catch (HttpRequestException ex) when (ex.StatusCode == 404)` |
| 全域處理 | 未捕獲例外 | ASP.NET: Exception Middleware / `IExceptionHandler` |
| 驗證錯誤 | 輸入資料不合法 | FluentValidation + `ValidationException` |
| 重試機制 | 暫時性錯誤 | Polly: `Policy.Handle<HttpRequestException>().RetryAsync(3)` |

### 設計模式建議

| 模式 | 適用場景 | 關鍵特徵 |
|------|---------|---------|
| Repository + Unit of Work | 資料存取 | `IRepository<T>` + `IUnitOfWork` |
| Mediator (MediatR) | CQRS / 命令處理 | `IRequest<T>` + `IRequestHandler` |
| Options Pattern | 配置管理 | `IOptions<T>` + DI 註冊 |
| Builder | 複雜物件建構 | Fluent API + `Build()` |
| Strategy | 動態切換演算法 | `interface` + DI 註冊 |

---

## Phase 2：程序設計師補充 💻

### 編碼慣例

```yaml
命名規則:
  命名空間: PascalCase（對應目錄結構）
  類別/Record: PascalCase
  方法: PascalCase
  屬性: PascalCase
  參數: camelCase
  私有欄位: _camelCase
  常數: PascalCase
  Interface: IPascalCase（I 前綴）
  泛型參數: T 或 TPascalCase

程式碼風格:
  - 使用 file-scoped namespaces（C# 10+）
  - 啟用 Nullable reference types
  - var 用於型別明顯時，型別不明確時寫完整型別
  - 優先用 pattern matching 而非 if-else 串
  - async 方法名稱加 Async 後綴
```

### 專案結構

```
Solution/
├── src/
│   ├── Project.Domain/          # 領域模型、介面
│   │   ├── Models/
│   │   ├── Interfaces/
│   │   └── Exceptions/
│   ├── Project.Application/     # 業務邏輯、Use Cases
│   │   ├── Commands/
│   │   ├── Queries/
│   │   └── Services/
│   ├── Project.Infrastructure/  # 資料存取、外部服務
│   │   ├── Data/
│   │   ├── Repositories/
│   │   └── Services/
│   └── Project.Api/             # Web API 入口
│       ├── Controllers/
│       ├── Middleware/
│       └── Program.cs
├── tests/
│   ├── Project.UnitTests/
│   ├── Project.IntegrationTests/
│   └── Project.FunctionalTests/
├── Directory.Build.props        # 共用建置設定
└── Solution.sln
```

### 工具鏈指令

| 用途 | 指令 | 說明 |
|------|------|------|
| **增量驗證（lint）** | `dotnet build --warnaserrors` | Phase 2 每完成一個檔案執行 |
| **格式化** | `dotnet format` | 程式碼格式統一 |
| **建置** | `dotnet build` | 編譯整個方案 |
| **建置（release）** | `dotnet build -c Release` | 優化編譯 |
| **分析器** | `dotnet build /p:TreatWarningsAsErrors=true` | 所有警告視為錯誤 |

### ASP.NET Core 模式

**Minimal API（推薦）**：
```csharp
var app = builder.Build();

app.MapGet("/orders/{id}", async (int id, IOrderService service, CancellationToken ct) =>
{
    var order = await service.GetByIdAsync(id, ct);
    return order is not null ? Results.Ok(order) : Results.NotFound();
});
```

**依賴注入**：
```csharp
builder.Services.AddScoped<IOrderRepository, SqlOrderRepository>();
builder.Services.AddScoped<IOrderService, OrderService>();
builder.Services.Configure<OrderOptions>(builder.Configuration.GetSection("Orders"));
```

### Entity Framework Core 模式

```csharp
// DbContext 配置
public class AppDbContext(DbContextOptions<AppDbContext> options) : DbContext(options)
{
    public DbSet<Order> Orders => Set<Order>();

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        modelBuilder.ApplyConfigurationsFromAssembly(typeof(AppDbContext).Assembly);
    }
}

// Repository 模式
public class OrderRepository(AppDbContext db) : IOrderRepository
{
    public async Task<Order?> GetByIdAsync(int id, CancellationToken ct = default)
        => await db.Orders
            .Include(o => o.Items)
            .FirstOrDefaultAsync(o => o.Id == id, ct);
}
```

---

## Phase 3：檢核師補充 🔍

### 語言專屬審查清單

| 項目 | 嚴重度 | 檢查重點 |
|------|--------|---------|
| Nullable 未啟用 | high | `<Nullable>enable</Nullable>` 必須啟用 |
| `async void` | high | 除了事件處理器，禁止 `async void`，用 `async Task` |
| 缺少 CancellationToken | medium | 所有 async IO 方法必須接受 CancellationToken |
| `Task.Result` / `.Wait()` | high | 禁止同步等待異步，改用 `await` |
| 未 Dispose 資源 | high | `IDisposable` 物件必須用 `using` |
| `catch (Exception)` | medium | 避免捕獲所有例外，指定具體例外型別 |
| 未使用的 DI 服務 | low | 移除未使用的服務註冊 |

### 安全反模式

| 反模式 | 風險 | 修正方式 |
|--------|------|---------|
| SQL 字串拼接 | SQL injection | EF Core LINQ 或參數化查詢 |
| `dynamic` 型別 | 型別安全破壞 | 用泛型或強型別 |
| 未驗證使用者輸入 | XSS / 注入 | `[FromBody]` + FluentValidation |
| 密鑰在 appsettings | 機密洩露 | User Secrets / Azure Key Vault |
| CORS 開放 `*` | CSRF | 限制允許的 Origin |
| 未設定 HTTPS | 中間人攻擊 | `app.UseHttpsRedirection()` |

### 效能反模式

| 反模式 | 影響 | 修正方式 |
|--------|------|---------|
| LINQ `.ToList()` 過早 | 記憶體 | 延遲到需要時才具體化 |
| N+1 查詢 | 資料庫壓力 | `.Include()` 或 projection |
| 大量字串拼接 | GC 壓力 | `StringBuilder` 或 `string.Create` |
| 未使用 `ValueTask` | 不必要的 allocation | 同步完成路徑用 `ValueTask<T>` |
| Boxing | GC 壓力 | 泛型約束避免 `object` |
| 未使用 Compiled Query | EF 重複編譯 | `EF.CompileAsyncQuery<>()` |

---

## Phase 4：測試師補充 🧪

### 測試框架與指令

| 用途 | 工具 | 指令 |
|------|------|------|
| **單元測試** | xUnit（推薦）/ NUnit | `dotnet test` |
| **覆蓋率** | coverlet | `dotnet test --collect:"XPlat Code Coverage"` |
| **整合測試** | WebApplicationFactory | `dotnet test --filter Category=Integration` |
| **模擬** | NSubstitute / Moq | 內嵌於測試專案 |
| **基準測試** | BenchmarkDotNet | 獨立基準測試專案 |
| **快照測試** | Verify | 自動管理 expected output |

### 測試模式

**基礎結構（xUnit）**：
```csharp
public class ProcessOrderTests
{
    private readonly IOrderService _service;
    private readonly IOrderRepository _mockRepo;

    public ProcessOrderTests()
    {
        _mockRepo = Substitute.For<IOrderRepository>();
        _service = new OrderService(_mockRepo);
    }

    // BC-1: 邊界條件
    [Fact]
    public async Task ProcessOrder_EmptyOrder_ThrowsEmptyOrderException()
    {
        var order = new Order();
        await Assert.ThrowsAsync<EmptyOrderException>(
            () => _service.ProcessAsync(order));
    }

    // EH-1: 錯誤處理
    [Fact]
    public async Task ProcessOrder_InvalidAmount_ThrowsInvalidAmountException()
    {
        var order = new Order { Amount = -1m };
        await Assert.ThrowsAsync<InvalidAmountException>(
            () => _service.ProcessAsync(order));
    }

    // 正常路徑
    [Fact]
    public async Task ProcessOrder_ValidOrder_ReturnsProcessedOrder()
    {
        var order = CreateValidOrder();
        _mockRepo.SaveAsync(Arg.Any<Order>(), Arg.Any<CancellationToken>())
            .Returns(Task.CompletedTask);

        var result = await _service.ProcessAsync(order);

        Assert.Equal(OrderStatus.Processed, result.Status);
    }
}
```

**Theory（參數化測試）**：
```csharp
[Theory]
[InlineData(0, typeof(EmptyOrderException))]      // BC-1
[InlineData(-1, typeof(InvalidAmountException))]   // BC-2
[InlineData(1e10, typeof(OverflowException))]      // BC-3
public async Task ProcessOrder_InvalidAmounts_ThrowsExpectedException(
    decimal amount, Type expectedExceptionType)
{
    var order = new Order { Amount = amount };
    await Assert.ThrowsAsync(expectedExceptionType,
        () => _service.ProcessAsync(order));
}
```

**整合測試（WebApplicationFactory）**：
```csharp
public class OrderApiTests(WebApplicationFactory<Program> factory)
    : IClassFixture<WebApplicationFactory<Program>>
{
    [Fact]
    public async Task GetOrder_ExistingId_ReturnsOk()
    {
        var client = factory.CreateClient();
        var response = await client.GetAsync("/orders/1");
        response.EnsureSuccessStatusCode();
    }
}
```

### Mock/Stub 模式

```csharp
// NSubstitute（推薦）
var repo = Substitute.For<IOrderRepository>();
repo.GetByIdAsync(1, Arg.Any<CancellationToken>())
    .Returns(new Order { Id = 1, Amount = 100m });

var service = new OrderService(repo);
var result = await service.GetOrderAsync(1);

await repo.Received(1).GetByIdAsync(1, Arg.Any<CancellationToken>());
```

---

## Phase 5：自証師補充 ✅

### 驗證指令

Phase 5 自証時依序執行：

```bash
# 1. 格式檢查
dotnet format --verify-no-changes

# 2. 建置（啟用所有警告為錯誤）
dotnet build --warnaserrors

# 3. 測試
dotnet test

# 4. 覆蓋率
dotnet test --collect:"XPlat Code Coverage"
```

### 品質指標

| 指標 | 目標 | 工具 |
|------|------|------|
| 編譯通過 | 0 error, 0 warning | `dotnet build --warnaserrors` |
| Nullable 啟用 | 全專案 | `.csproj` 設定 |
| 測試覆蓋率 | BC/EH 100% | `coverlet` |
| 格式一致 | 0 diff | `dotnet format` |
| 分析器通過 | 0 warning | `.editorconfig` + analyzers |

---

最後修訂：2026-02-24
