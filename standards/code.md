# Estándares de código

## Principios generales

1. **Claridad sobre cleverness**: El código se lee más de lo que se escribe
2. **Explícito sobre implícito**: Preferir verbosidad clara a magia oculta
3. **Fail fast**: Validar inputs al inicio, fallar ruidosamente
4. **Single responsibility**: Una función/clase, un propósito

## Estructura de proyecto

```
src/
├── domain/           # Entidades y lógica de negocio pura
├── application/      # Casos de uso, orquestación
├── infrastructure/   # Implementaciones técnicas (DB, APIs, etc)
├── presentation/     # Controllers, handlers, CLI
└── shared/           # Utilidades compartidas
```

## Convenciones de nombrado

| Elemento | Convención | Ejemplo |
|----------|------------|---------|
| Archivos | kebab-case | `user-repository.ts` |
| Clases | PascalCase | `UserRepository` |
| Funciones | camelCase | `findUserById` |
| Constantes | SCREAMING_SNAKE | `MAX_RETRY_COUNT` |
| Variables | camelCase | `currentUser` |
| Tipos/Interfaces | PascalCase con prefijo I opcional | `User`, `IUserService` |

## Patrones requeridos

### Manejo de errores

```typescript
// ✅ Correcto: Errores tipados y específicos
class UserNotFoundError extends Error {
  constructor(public readonly userId: string) {
    super(`User not found: ${userId}`);
    this.name = 'UserNotFoundError';
  }
}

// ❌ Incorrecto: Errores genéricos
throw new Error('Something went wrong');
```

### Inyección de dependencias

```typescript
// ✅ Correcto: Dependencias inyectadas
class UserService {
  constructor(private readonly userRepo: IUserRepository) {}
}

// ❌ Incorrecto: Dependencias hardcodeadas
class UserService {
  private userRepo = new PostgresUserRepository();
}
```

### Funciones puras cuando sea posible

```typescript
// ✅ Correcto: Sin side effects
function calculateTotal(items: Item[]): number {
  return items.reduce((sum, item) => sum + item.price, 0);
}

// ❌ Incorrecto: Modifica estado externo
function calculateTotal(items: Item[]): number {
  globalState.lastCalculation = Date.now(); // side effect
  return items.reduce((sum, item) => sum + item.price, 0);
}
```

## Imports

Orden obligatorio:

1. Built-in modules
2. External dependencies
3. Internal modules (por capa: domain → application → infrastructure)
4. Relative imports

```typescript
// 1. Built-in
import { readFile } from 'fs/promises';

// 2. External
import { Injectable } from '@nestjs/common';
import { z } from 'zod';

// 3. Internal
import { User } from '@/domain/entities/user';
import { IUserRepository } from '@/domain/repositories/user.repository';

// 4. Relative
import { mapToDto } from './mappers';
```

## Comentarios

```typescript
// ✅ Explica el "por qué", no el "qué"
// Usamos retry exponencial porque el servicio externo tiene rate limiting agresivo
await retryWithBackoff(() => externalService.call());

// ❌ Comenta lo obvio
// Incrementa el contador
counter++;
```

## Async/Await

```typescript
// ✅ Correcto: Parallel cuando es posible
const [users, orders] = await Promise.all([
  userRepo.findAll(),
  orderRepo.findAll()
]);

// ❌ Incorrecto: Serial innecesario
const users = await userRepo.findAll();
const orders = await orderRepo.findAll();
```

## Validación de inputs

```typescript
// ✅ Correcto: Validar al inicio
function createUser(input: unknown): User {
  const validated = CreateUserSchema.parse(input); // Falla aquí si es inválido
  return new User(validated);
}

// ❌ Incorrecto: Validación implícita/tardía
function createUser(input: any): User {
  return new User(input.name, input.email); // Puede fallar en cualquier momento
}
```

## Máximos recomendados

| Métrica | Límite | Razón |
|---------|--------|-------|
| Líneas por función | 30 | Legibilidad |
| Parámetros por función | 4 | Considerar objeto de opciones |
| Niveles de anidación | 3 | Complejidad cognitiva |
| Complejidad ciclomática | 10 | Testabilidad |

## Anti-patrones prohibidos

- `any` sin justificación documentada
- Callbacks anidados (callback hell)
- Mutación de parámetros de entrada
- Strings mágicos (usar enums/constantes)
- Catch vacíos que silencian errores
- Imports circulares
