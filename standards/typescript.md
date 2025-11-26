# Estándares TypeScript

## Versiones soportadas

- TypeScript 5.x
- Node.js 20 LTS
- ES2022+ target

## Configuración base

```json
// tsconfig.json
{
  "compilerOptions": {
    "target": "ES2022",
    "module": "NodeNext",
    "moduleResolution": "NodeNext",
    "lib": ["ES2022"],
    "outDir": "./dist",
    "rootDir": "./src",
    "strict": true,
    "noUncheckedIndexedAccess": true,
    "noImplicitOverride": true,
    "noPropertyAccessFromIndexSignature": true,
    "exactOptionalPropertyTypes": true,
    "forceConsistentCasingInFileNames": true,
    "skipLibCheck": true,
    "declaration": true,
    "declarationMap": true,
    "sourceMap": true,
    "esModuleInterop": true,
    "resolveJsonModule": true,
    "isolatedModules": true,
    "verbatimModuleSyntax": true,
    "paths": {
      "@/*": ["./src/*"]
    }
  },
  "include": ["src/**/*"],
  "exclude": ["node_modules", "dist"]
}
```

## Estructura de proyecto

```
src/
├── domain/                    # Entidades y lógica de negocio
│   ├── entities/
│   ├── value-objects/
│   ├── errors/
│   └── interfaces/
│
├── application/               # Casos de uso
│   ├── commands/
│   ├── queries/
│   ├── dtos/
│   └── interfaces/
│
├── infrastructure/            # Implementaciones técnicas
│   ├── database/
│   ├── http/
│   ├── messaging/
│   └── config/
│
├── presentation/              # Controllers, handlers
│   ├── http/
│   │   ├── controllers/
│   │   ├── middleware/
│   │   └── routes/
│   └── cli/
│
├── shared/                    # Utilidades compartidas
│   ├── types/
│   ├── utils/
│   └── constants/
│
└── index.ts                   # Entry point
```

## Convenciones de código

### Tipos estrictos

```typescript
// ✅ Tipos explícitos, evitar any
interface User {
  readonly id: string;
  email: string;
  name: string;
  createdAt: Date;
}

// ✅ Unions para estados finitos
type OrderStatus = 'pending' | 'confirmed' | 'shipped' | 'delivered';

// ✅ Branded types para IDs
type UserId = string & { readonly __brand: 'UserId' };
type OrderId = string & { readonly __brand: 'OrderId' };

function createUserId(id: string): UserId {
  return id as UserId;
}

// ✅ Utility types
type CreateUserInput = Omit<User, 'id' | 'createdAt'>;
type UpdateUserInput = Partial<Pick<User, 'name' | 'email'>>;
```

### Funciones

```typescript
// ✅ Parámetros con destructuring y defaults
function createUser({
  email,
  name,
  role = 'user',
}: {
  email: string;
  name: string;
  role?: UserRole;
}): User {
  return { id: generateId(), email, name, role, createdAt: new Date() };
}

// ✅ Overloads cuando tipos varían significativamente
function findUser(id: UserId): Promise<User | null>;
function findUser(email: string): Promise<User | null>;
function findUser(idOrEmail: UserId | string): Promise<User | null> {
  // implementación
}

// ✅ Generic constraints
function getProperty<T, K extends keyof T>(obj: T, key: K): T[K] {
  return obj[key];
}
```

### Result pattern

```typescript
// ✅ Discriminated unions para resultados
type Result<T, E = Error> =
  | { success: true; data: T }
  | { success: false; error: E };

// Helper functions
const ok = <T>(data: T): Result<T, never> => ({ success: true, data });
const err = <E>(error: E): Result<never, E> => ({ success: false, error });

// Uso
async function createUser(input: CreateUserInput): Promise<Result<User, UserError>> {
  const existingUser = await userRepo.findByEmail(input.email);
  if (existingUser) {
    return err({ code: 'EMAIL_EXISTS', message: 'Email already registered' });
  }
  
  const user = await userRepo.create(input);
  return ok(user);
}

// Consumer
const result = await createUser(input);
if (!result.success) {
  // result.error está tipado
  return response.status(400).json(result.error);
}
// result.data está tipado como User
return response.status(201).json(result.data);
```

### Error handling

```typescript
// ✅ Custom errors con información estructurada
class AppError extends Error {
  constructor(
    message: string,
    public readonly code: string,
    public readonly statusCode: number = 500,
    public readonly isOperational: boolean = true,
  ) {
    super(message);
    this.name = this.constructor.name;
    Error.captureStackTrace(this, this.constructor);
  }
}

class NotFoundError extends AppError {
  constructor(resource: string, id: string) {
    super(`${resource} with id ${id} not found`, 'NOT_FOUND', 404);
  }
}

class ValidationError extends AppError {
  constructor(
    message: string,
    public readonly details: { field: string; message: string }[],
  ) {
    super(message, 'VALIDATION_ERROR', 400);
  }
}

// ✅ Type guards
function isAppError(error: unknown): error is AppError {
  return error instanceof AppError;
}
```

### Async patterns

```typescript
// ✅ Parallel cuando es posible
const [users, orders] = await Promise.all([
  userRepo.findAll(),
  orderRepo.findAll(),
]);

// ✅ Promise.allSettled para operaciones independientes
const results = await Promise.allSettled([
  sendEmail(user),
  updateAnalytics(user),
  notifySlack(user),
]);

const failures = results.filter(
  (r): r is PromiseRejectedResult => r.status === 'rejected'
);
if (failures.length > 0) {
  logger.warn('Some notifications failed', { failures });
}

// ✅ Retry con backoff exponencial
async function withRetry<T>(
  fn: () => Promise<T>,
  options: { maxAttempts?: number; baseDelay?: number } = {},
): Promise<T> {
  const { maxAttempts = 3, baseDelay = 1000 } = options;
  
  for (let attempt = 1; attempt <= maxAttempts; attempt++) {
    try {
      return await fn();
    } catch (error) {
      if (attempt === maxAttempts) throw error;
      const delay = baseDelay * Math.pow(2, attempt - 1);
      await sleep(delay);
    }
  }
  throw new Error('Unreachable');
}
```

### Zod para validación

```typescript
import { z } from 'zod';

// ✅ Schemas reutilizables
const emailSchema = z.string().email().max(255).toLowerCase();
const passwordSchema = z
  .string()
  .min(8)
  .regex(/[A-Z]/, 'Must contain uppercase')
  .regex(/[a-z]/, 'Must contain lowercase')
  .regex(/[0-9]/, 'Must contain number');

const createUserSchema = z.object({
  email: emailSchema,
  password: passwordSchema,
  name: z.string().min(2).max(100),
});

type CreateUserInput = z.infer<typeof createUserSchema>;

// ✅ Validación en controllers
async function handleCreateUser(req: Request, res: Response) {
  const parseResult = createUserSchema.safeParse(req.body);
  
  if (!parseResult.success) {
    return res.status(400).json({
      code: 'VALIDATION_ERROR',
      details: parseResult.error.flatten().fieldErrors,
    });
  }
  
  const user = await userService.create(parseResult.data);
  return res.status(201).json(user);
}
```

### NestJS patterns

```typescript
// ✅ Module organization
@Module({
  imports: [
    TypeOrmModule.forFeature([User]),
    ConfigModule,
  ],
  controllers: [UsersController],
  providers: [UsersService, UsersRepository],
  exports: [UsersService],
})
export class UsersModule {}

// ✅ DTOs con class-validator
export class CreateUserDto {
  @IsEmail()
  @MaxLength(255)
  email!: string;

  @IsString()
  @MinLength(2)
  @MaxLength(100)
  name!: string;
}

// ✅ Controllers
@Controller('users')
@UseInterceptors(LoggingInterceptor)
export class UsersController {
  constructor(private readonly usersService: UsersService) {}

  @Get(':id')
  @HttpCode(HttpStatus.OK)
  async findOne(@Param('id', ParseUUIDPipe) id: string): Promise<UserDto> {
    const user = await this.usersService.findById(id);
    if (!user) {
      throw new NotFoundException(`User ${id} not found`);
    }
    return UserDto.fromEntity(user);
  }
}
```

## Testing

```typescript
import { describe, it, expect, vi, beforeEach } from 'vitest';

describe('UserService', () => {
  let userService: UserService;
  let userRepoMock: MockedObject<IUserRepository>;

  beforeEach(() => {
    userRepoMock = {
      findById: vi.fn(),
      findByEmail: vi.fn(),
      create: vi.fn(),
    };
    userService = new UserService(userRepoMock);
  });

  describe('createUser', () => {
    it('should create user when email is unique', async () => {
      // Arrange
      const input: CreateUserInput = {
        email: 'test@example.com',
        name: 'John',
      };
      userRepoMock.findByEmail.mockResolvedValue(null);
      userRepoMock.create.mockResolvedValue({ id: '1', ...input });

      // Act
      const result = await userService.createUser(input);

      // Assert
      expect(result.success).toBe(true);
      expect(result.data).toEqual(expect.objectContaining({ email: input.email }));
      expect(userRepoMock.create).toHaveBeenCalledWith(input);
    });

    it('should return error when email exists', async () => {
      // Arrange
      const input: CreateUserInput = { email: 'existing@example.com', name: 'John' };
      userRepoMock.findByEmail.mockResolvedValue({ id: '1', ...input });

      // Act
      const result = await userService.createUser(input);

      // Assert
      expect(result.success).toBe(false);
      expect(result.error?.code).toBe('EMAIL_EXISTS');
    });
  });
});
```

## ESLint config

```javascript
// eslint.config.js
import eslint from '@eslint/js';
import tseslint from 'typescript-eslint';

export default tseslint.config(
  eslint.configs.recommended,
  ...tseslint.configs.strictTypeChecked,
  {
    languageOptions: {
      parserOptions: {
        project: true,
        tsconfigRootDir: import.meta.dirname,
      },
    },
    rules: {
      '@typescript-eslint/no-unused-vars': ['error', { argsIgnorePattern: '^_' }],
      '@typescript-eslint/explicit-function-return-type': 'error',
      '@typescript-eslint/no-explicit-any': 'error',
      '@typescript-eslint/strict-boolean-expressions': 'error',
      '@typescript-eslint/no-floating-promises': 'error',
    },
  },
);
```

## Checklist para el agente

Al escribir código TypeScript:

- [ ] strict mode habilitado
- [ ] No usar any (usar unknown si es necesario)
- [ ] Tipos explícitos en funciones públicas
- [ ] Result pattern para operaciones fallibles
- [ ] Zod/class-validator para validación
- [ ] Custom errors con código y contexto
- [ ] Async/await con manejo de errores
- [ ] Tests con mocks tipados
- [ ] ESLint sin warnings
