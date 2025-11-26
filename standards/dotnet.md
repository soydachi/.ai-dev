# Estándares .NET

## Versiones soportadas

- .NET 8 LTS (preferido)
- .NET 9 (nuevos proyectos cuando sea LTS)
- C# 12+

## Estructura de proyecto

```
src/
├── Company.Project.Domain/           # Entidades, value objects, interfaces
│   ├── Entities/
│   ├── ValueObjects/
│   ├── Interfaces/
│   ├── Exceptions/
│   └── Events/
│
├── Company.Project.Application/      # Casos de uso, DTOs, validaciones
│   ├── Commands/
│   ├── Queries/
│   ├── DTOs/
│   ├── Validators/
│   ├── Mappers/
│   └── Interfaces/
│
├── Company.Project.Infrastructure/   # Implementaciones técnicas
│   ├── Persistence/
│   │   ├── Configurations/           # EF Core configs
│   │   ├── Repositories/
│   │   └── DbContext.cs
│   ├── Services/
│   └── Extensions/
│
├── Company.Project.Api/              # Controllers, middleware, startup
│   ├── Controllers/
│   ├── Middleware/
│   ├── Filters/
│   └── Program.cs
│
└── Company.Project.Worker/           # Background services (si aplica)

tests/
├── Company.Project.UnitTests/
├── Company.Project.IntegrationTests/
└── Company.Project.ArchTests/        # Tests de arquitectura
```

## Convenciones de código

### Nombrado

```csharp
// ✅ Clases y métodos: PascalCase
public class UserService
{
    public async Task<User> GetUserByIdAsync(Guid userId) { }
}

// ✅ Interfaces: I + PascalCase
public interface IUserRepository { }

// ✅ Variables y parámetros: camelCase
var currentUser = await GetUserAsync(userId);

// ✅ Constantes: PascalCase
public const int MaxRetryCount = 3;

// ✅ Campos privados: _camelCase
private readonly IUserRepository _userRepository;

// ✅ Propiedades: PascalCase
public string Email { get; init; }

// ✅ Async methods: sufijo Async
public async Task<Result> ProcessOrderAsync() { }
```

### Patrones requeridos

#### Result pattern para operaciones fallibles

```csharp
// ✅ Usar Result<T> en lugar de excepciones para flujo de negocio
public sealed record Result<T>
{
    public T? Value { get; }
    public Error? Error { get; }
    public bool IsSuccess => Error is null;
    
    private Result(T value) => Value = value;
    private Result(Error error) => Error = error;
    
    public static Result<T> Success(T value) => new(value);
    public static Result<T> Failure(Error error) => new(error);
}

// Uso
public async Task<Result<User>> CreateUserAsync(CreateUserCommand command)
{
    if (await _userRepository.ExistsByEmailAsync(command.Email))
        return Result<User>.Failure(UserErrors.EmailAlreadyExists);
    
    var user = User.Create(command.Email, command.Name);
    await _userRepository.AddAsync(user);
    
    return Result<User>.Success(user);
}
```

#### Records para DTOs y Value Objects

```csharp
// ✅ Records inmutables para DTOs
public sealed record UserDto(
    Guid Id,
    string Email,
    string Name,
    DateTime CreatedAt
);

// ✅ Records para Value Objects
public sealed record Email
{
    public string Value { get; }
    
    private Email(string value) => Value = value;
    
    public static Result<Email> Create(string value)
    {
        if (string.IsNullOrWhiteSpace(value))
            return Result<Email>.Failure(ValidationErrors.EmailRequired);
            
        if (!IsValidEmail(value))
            return Result<Email>.Failure(ValidationErrors.EmailInvalid);
            
        return Result<Email>.Success(new Email(value));
    }
}
```

#### Entity base class

```csharp
public abstract class Entity<TId> where TId : notnull
{
    public TId Id { get; protected init; } = default!;
    
    private readonly List<IDomainEvent> _domainEvents = [];
    public IReadOnlyList<IDomainEvent> DomainEvents => _domainEvents.AsReadOnly();
    
    protected void RaiseDomainEvent(IDomainEvent domainEvent)
        => _domainEvents.Add(domainEvent);
    
    public void ClearDomainEvents() => _domainEvents.Clear();
}
```

### Dependency Injection

```csharp
// ✅ Registrar por interfaz
services.AddScoped<IUserRepository, UserRepository>();
services.AddScoped<IUserService, UserService>();

// ✅ Extension methods para organizar
public static class ServiceCollectionExtensions
{
    public static IServiceCollection AddApplicationServices(
        this IServiceCollection services)
    {
        services.AddScoped<IUserService, UserService>();
        services.AddScoped<IOrderService, OrderService>();
        return services;
    }
    
    public static IServiceCollection AddInfrastructureServices(
        this IServiceCollection services, 
        IConfiguration configuration)
    {
        services.AddDbContext<AppDbContext>(options =>
            options.UseSqlServer(configuration.GetConnectionString("Default")));
            
        services.AddScoped<IUserRepository, UserRepository>();
        return services;
    }
}

// En Program.cs
builder.Services
    .AddApplicationServices()
    .AddInfrastructureServices(builder.Configuration);
```

### ASP.NET Core Controllers

```csharp
[ApiController]
[Route("api/v1/[controller]")]
[Produces("application/json")]
public class UsersController : ControllerBase
{
    private readonly IUserService _userService;
    
    public UsersController(IUserService userService)
        => _userService = userService;
    
    /// <summary>
    /// Obtiene un usuario por ID
    /// </summary>
    [HttpGet("{id:guid}")]
    [ProducesResponseType(typeof(UserDto), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ProblemDetails), StatusCodes.Status404NotFound)]
    public async Task<IActionResult> GetById(Guid id, CancellationToken ct)
    {
        var result = await _userService.GetByIdAsync(id, ct);
        
        return result.IsSuccess
            ? Ok(result.Value)
            : NotFound(result.Error.ToProblemDetails());
    }
    
    [HttpPost]
    [ProducesResponseType(typeof(UserDto), StatusCodes.Status201Created)]
    [ProducesResponseType(typeof(ValidationProblemDetails), StatusCodes.Status400BadRequest)]
    public async Task<IActionResult> Create(
        [FromBody] CreateUserRequest request,
        CancellationToken ct)
    {
        var result = await _userService.CreateAsync(request.ToCommand(), ct);
        
        return result.IsSuccess
            ? CreatedAtAction(nameof(GetById), new { id = result.Value.Id }, result.Value)
            : BadRequest(result.Error.ToValidationProblemDetails());
    }
}
```

### Entity Framework Core

```csharp
// ✅ Configuración separada por entidad
public class UserConfiguration : IEntityTypeConfiguration<User>
{
    public void Configure(EntityTypeBuilder<User> builder)
    {
        builder.ToTable("Users");
        
        builder.HasKey(u => u.Id);
        
        builder.Property(u => u.Email)
            .HasMaxLength(255)
            .IsRequired();
        
        builder.HasIndex(u => u.Email)
            .IsUnique();
        
        // Value Object
        builder.OwnsOne(u => u.Address, address =>
        {
            address.Property(a => a.Street).HasMaxLength(200);
            address.Property(a => a.City).HasMaxLength(100);
        });
    }
}

// ✅ Repository pattern
public class UserRepository : IUserRepository
{
    private readonly AppDbContext _context;
    
    public UserRepository(AppDbContext context) => _context = context;
    
    public async Task<User?> GetByIdAsync(Guid id, CancellationToken ct = default)
        => await _context.Users
            .Include(u => u.Orders)
            .FirstOrDefaultAsync(u => u.Id == id, ct);
    
    public async Task<bool> ExistsByEmailAsync(string email, CancellationToken ct = default)
        => await _context.Users.AnyAsync(u => u.Email == email, ct);
    
    public void Add(User user) => _context.Users.Add(user);
}
```

### Validación con FluentValidation

```csharp
public class CreateUserRequestValidator : AbstractValidator<CreateUserRequest>
{
    public CreateUserRequestValidator()
    {
        RuleFor(x => x.Email)
            .NotEmpty().WithMessage("Email es requerido")
            .EmailAddress().WithMessage("Email inválido")
            .MaximumLength(255);
        
        RuleFor(x => x.Name)
            .NotEmpty()
            .MinimumLength(2)
            .MaximumLength(100);
        
        RuleFor(x => x.Password)
            .NotEmpty()
            .MinimumLength(8)
            .Matches("[A-Z]").WithMessage("Debe contener mayúscula")
            .Matches("[a-z]").WithMessage("Debe contener minúscula")
            .Matches("[0-9]").WithMessage("Debe contener número");
    }
}
```

### Logging estructurado

```csharp
public class UserService : IUserService
{
    private readonly ILogger<UserService> _logger;
    
    public async Task<Result<User>> CreateUserAsync(CreateUserCommand command)
    {
        _logger.LogInformation(
            "Creating user with email {Email}",
            command.Email.MaskEmail()); // Nunca loggear email completo
        
        try
        {
            // ... implementación
            
            _logger.LogInformation(
                "User created successfully. UserId: {UserId}",
                user.Id);
            
            return Result<User>.Success(user);
        }
        catch (Exception ex)
        {
            _logger.LogError(
                ex,
                "Failed to create user. Email: {Email}",
                command.Email.MaskEmail());
            
            throw;
        }
    }
}
```

### Configuración tipada

```csharp
// ✅ Options pattern
public class JwtSettings
{
    public const string SectionName = "Jwt";
    
    public required string Secret { get; init; }
    public required string Issuer { get; init; }
    public required string Audience { get; init; }
    public int ExpirationMinutes { get; init; } = 60;
}

// Registro
services.Configure<JwtSettings>(
    configuration.GetSection(JwtSettings.SectionName));

// Uso
public class TokenService
{
    private readonly JwtSettings _settings;
    
    public TokenService(IOptions<JwtSettings> options)
        => _settings = options.Value;
}
```

## Testing

```csharp
// ✅ Arrange-Act-Assert claro
public class UserServiceTests
{
    private readonly Mock<IUserRepository> _userRepoMock = new();
    private readonly UserService _sut;
    
    public UserServiceTests()
    {
        _sut = new UserService(_userRepoMock.Object);
    }
    
    [Fact]
    public async Task CreateUserAsync_WhenEmailExists_ReturnsFailure()
    {
        // Arrange
        var command = new CreateUserCommand("existing@test.com", "John");
        _userRepoMock
            .Setup(r => r.ExistsByEmailAsync(command.Email, default))
            .ReturnsAsync(true);
        
        // Act
        var result = await _sut.CreateUserAsync(command);
        
        // Assert
        result.IsSuccess.Should().BeFalse();
        result.Error.Should().Be(UserErrors.EmailAlreadyExists);
    }
    
    [Theory]
    [InlineData("")]
    [InlineData(" ")]
    [InlineData(null)]
    public async Task CreateUserAsync_WhenEmailEmpty_ReturnsValidationError(string? email)
    {
        // Arrange
        var command = new CreateUserCommand(email!, "John");
        
        // Act
        var result = await _sut.CreateUserAsync(command);
        
        // Assert
        result.IsSuccess.Should().BeFalse();
        result.Error.Code.Should().Be("VALIDATION_ERROR");
    }
}
```

## Checklist para el agente

Al escribir código .NET:

- [ ] Usa records para DTOs y Value Objects
- [ ] Result pattern para operaciones de negocio
- [ ] Async/await con CancellationToken
- [ ] ILogger<T> estructurado
- [ ] Validación con FluentValidation
- [ ] Configuración con Options pattern
- [ ] EF Core con configuraciones separadas
- [ ] Extension methods para DI
- [ ] XML docs en APIs públicas
- [ ] Tests con Arrange-Act-Assert
