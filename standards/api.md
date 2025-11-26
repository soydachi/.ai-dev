# Estándares de API

## Principios de diseño

1. **Consistencia**: Mismas convenciones en todos los endpoints
2. **Predecibilidad**: Comportamiento esperado según estándares HTTP
3. **Evolucionabilidad**: Diseño que permite cambios sin romper clientes
4. **Developer Experience**: APIs intuitivas y bien documentadas

## REST

### URLs y recursos

```
# ✅ Recursos en plural, sustantivos
GET    /api/v1/users
GET    /api/v1/users/{id}
POST   /api/v1/users
PUT    /api/v1/users/{id}
PATCH  /api/v1/users/{id}
DELETE /api/v1/users/{id}

# ✅ Recursos anidados (máximo 2 niveles)
GET    /api/v1/users/{userId}/orders
GET    /api/v1/users/{userId}/orders/{orderId}

# ❌ Evitar
GET    /api/v1/getUsers
POST   /api/v1/createUser
GET    /api/v1/users/{userId}/orders/{orderId}/items/{itemId}/details
```

### Métodos HTTP

| Método | Uso | Idempotente | Body |
|--------|-----|-------------|------|
| GET | Obtener recurso(s) | Sí | No |
| POST | Crear recurso | No | Sí |
| PUT | Reemplazar recurso completo | Sí | Sí |
| PATCH | Actualización parcial | No* | Sí |
| DELETE | Eliminar recurso | Sí | No |

### Códigos de estado

```
# Éxito
200 OK              → GET, PUT, PATCH exitosos
201 Created         → POST exitoso (incluir Location header)
204 No Content      → DELETE exitoso

# Redirección
301 Moved Permanently
304 Not Modified    → Cache válido

# Error cliente
400 Bad Request     → Validación fallida
401 Unauthorized    → Sin autenticación
403 Forbidden       → Sin autorización
404 Not Found       → Recurso no existe
409 Conflict        → Conflicto de estado (ej: duplicado)
422 Unprocessable   → Semánticamente inválido
429 Too Many Requests → Rate limit

# Error servidor
500 Internal Error  → Error no manejado
502 Bad Gateway     → Servicio downstream falló
503 Service Unavailable → Mantenimiento/sobrecarga
504 Gateway Timeout → Timeout de upstream
```

### Respuestas

```json
// ✅ Respuesta exitosa (recurso único)
{
  "id": "usr_123",
  "email": "user@example.com",
  "name": "John Doe",
  "createdAt": "2024-01-15T10:30:00Z"
}

// ✅ Respuesta exitosa (colección paginada)
{
  "data": [
    { "id": "usr_123", "name": "John" },
    { "id": "usr_456", "name": "Jane" }
  ],
  "pagination": {
    "page": 1,
    "pageSize": 20,
    "totalItems": 150,
    "totalPages": 8
  }
}

// ✅ Respuesta de error
{
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "Invalid request parameters",
    "details": [
      {
        "field": "email",
        "message": "Must be a valid email address"
      }
    ],
    "traceId": "abc-123-xyz"
  }
}
```

### Query parameters

```
# Paginación
GET /users?page=2&pageSize=20

# Ordenamiento
GET /users?sort=createdAt:desc,name:asc

# Filtrado
GET /users?status=active&role=admin

# Búsqueda
GET /users?q=john

# Campos (sparse fieldsets)
GET /users?fields=id,name,email

# Expansión de relaciones
GET /users/{id}?include=orders,profile
```

### Versionado

```
# ✅ En URL (recomendado para APIs públicas)
/api/v1/users
/api/v2/users

# ✅ En header (APIs internas)
Accept: application/vnd.api+json; version=1

# Política de deprecación
# - Anunciar con 6 meses de anticipación
# - Header Deprecation + Sunset
# - Documentar ruta de migración
```

## GraphQL

### Schema design

```graphql
# ✅ Tipos claros y específicos
type User {
  id: ID!
  email: String!
  name: String!
  orders(first: Int, after: String): OrderConnection!
  createdAt: DateTime!
}

# ✅ Conexiones para paginación (Relay spec)
type OrderConnection {
  edges: [OrderEdge!]!
  pageInfo: PageInfo!
  totalCount: Int!
}

type OrderEdge {
  node: Order!
  cursor: String!
}

type PageInfo {
  hasNextPage: Boolean!
  hasPreviousPage: Boolean!
  startCursor: String
  endCursor: String
}
```

### Queries y Mutations

```graphql
# ✅ Queries descriptivas
type Query {
  user(id: ID!): User
  users(filter: UserFilter, first: Int, after: String): UserConnection!
  me: User!
}

# ✅ Mutations con input types y payloads
type Mutation {
  createUser(input: CreateUserInput!): CreateUserPayload!
  updateUser(input: UpdateUserInput!): UpdateUserPayload!
  deleteUser(id: ID!): DeleteUserPayload!
}

input CreateUserInput {
  email: String!
  name: String!
  role: UserRole = USER
}

type CreateUserPayload {
  user: User
  errors: [UserError!]!
}

type UserError {
  field: String
  message: String!
  code: ErrorCode!
}
```

### Errores

```graphql
# ✅ Errores tipados en payload (errores de negocio)
mutation {
  createUser(input: { email: "invalid" }) {
    user { id }
    errors {
      field
      message
      code
    }
  }
}

# Errores de sistema van en errors[] del response
{
  "data": null,
  "errors": [
    {
      "message": "Internal server error",
      "extensions": {
        "code": "INTERNAL_ERROR",
        "traceId": "abc-123"
      }
    }
  ]
}
```

## Headers estándar

### Request

```
Authorization: Bearer <token>
Content-Type: application/json
Accept: application/json
Accept-Language: es-ES
X-Request-ID: <uuid>           # Correlación
X-Idempotency-Key: <uuid>      # Para POST idempotentes
```

### Response

```
Content-Type: application/json
X-Request-ID: <uuid>           # Echo del request
X-RateLimit-Limit: 1000
X-RateLimit-Remaining: 999
X-RateLimit-Reset: 1640000000
Cache-Control: max-age=3600
ETag: "abc123"
```

## Rate limiting

```yaml
# Configuración típica
default:
  requests: 1000
  window: 1h

authenticated:
  requests: 10000
  window: 1h

by_endpoint:
  POST /api/v1/auth/login:
    requests: 5
    window: 1m
  POST /api/v1/uploads:
    requests: 10
    window: 1h
```

## Documentación

### OpenAPI 3.x obligatorio

```yaml
openapi: 3.0.3
info:
  title: User Service API
  version: 1.0.0
  description: |
    API para gestión de usuarios.
    
    ## Autenticación
    Bearer token en header Authorization.
    
    ## Rate Limits
    1000 requests/hora para usuarios autenticados.

paths:
  /users:
    get:
      summary: Lista usuarios
      operationId: listUsers
      tags: [Users]
      parameters:
        - $ref: '#/components/parameters/PageParam'
      responses:
        '200':
          description: Lista paginada de usuarios
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/UserList'
```

### Requerimientos de documentación

- [ ] Descripción de cada endpoint
- [ ] Ejemplos de request/response
- [ ] Códigos de error posibles
- [ ] Autenticación requerida
- [ ] Rate limits aplicables

## Checklist para el agente

Al diseñar/implementar APIs:

- [ ] URLs usan sustantivos en plural
- [ ] Métodos HTTP semánticamente correctos
- [ ] Códigos de estado apropiados
- [ ] Respuestas de error consistentes
- [ ] Paginación en colecciones
- [ ] Versionado definido
- [ ] Headers estándar implementados
- [ ] Rate limiting configurado
- [ ] OpenAPI spec actualizada
- [ ] Validación de inputs
