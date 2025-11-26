# Estándares de observabilidad

## Tres pilares

```
┌─────────────┐  ┌─────────────┐  ┌─────────────┐
│   Logs      │  │  Métricas   │  │   Traces    │
│  (eventos)  │  │ (agregados) │  │ (requests)  │
└─────────────┘  └─────────────┘  └─────────────┘
       │                │                │
       └────────────────┼────────────────┘
                        │
                   Correlación
                   (trace_id)
```

## Logging

### Niveles

| Nivel | Uso | Ejemplo |
|-------|-----|---------|
| ERROR | Fallos que requieren acción | Conexión DB fallida |
| WARN | Anomalías que no bloquean | Retry exitoso tras fallo |
| INFO | Eventos de negocio significativos | Usuario creado |
| DEBUG | Detalles técnicos para troubleshooting | Query ejecutada |

### Formato estructurado

```typescript
// ✅ JSON estructurado
logger.info('User created', {
  event: 'user.created',
  userId: user.id,
  email: maskEmail(user.email),
  duration_ms: 45,
  trace_id: context.traceId,
});

// ❌ Strings concatenados
logger.info(`User ${user.id} created with email ${user.email}`);
```

### Campos obligatorios

```typescript
interface LogEntry {
  timestamp: string;      // ISO 8601
  level: string;          // error|warn|info|debug
  message: string;        // Descripción legible
  service: string;        // Nombre del servicio
  trace_id?: string;      // Correlación distribuida
  span_id?: string;       // Span actual
  
  // Contextuales
  user_id?: string;
  request_id?: string;
  duration_ms?: number;
  error?: {
    name: string;
    message: string;
    stack?: string;       // Solo en non-prod
  };
}
```

### Eventos a loggear

| Evento | Nivel | Campos adicionales |
|--------|-------|-------------------|
| Request recibido | INFO | method, path, user_id |
| Request completado | INFO | method, path, status, duration_ms |
| Autenticación exitosa | INFO | user_id, method |
| Autenticación fallida | WARN | reason, ip |
| Error de negocio | WARN | error_code, context |
| Error de sistema | ERROR | error, stack (non-prod) |
| Conexión externa | DEBUG | service, duration_ms |

## Métricas

### Tipos

| Tipo | Uso | Ejemplo |
|------|-----|---------|
| Counter | Eventos acumulativos | requests_total |
| Gauge | Valores actuales | active_connections |
| Histogram | Distribuciones | request_duration_seconds |
| Summary | Percentiles precalculados | response_size_bytes |

### Métricas RED (para servicios)

```
R - Rate:     Requests por segundo
E - Errors:   Tasa de errores
D - Duration: Latencia de requests
```

```typescript
// Prometheus ejemplo
const httpRequestsTotal = new Counter({
  name: 'http_requests_total',
  help: 'Total HTTP requests',
  labelNames: ['method', 'path', 'status'],
});

const httpRequestDuration = new Histogram({
  name: 'http_request_duration_seconds',
  help: 'HTTP request duration',
  labelNames: ['method', 'path'],
  buckets: [0.01, 0.05, 0.1, 0.5, 1, 5],
});
```

### Métricas USE (para recursos)

```
U - Utilization: % de uso del recurso
S - Saturation:  Cola de trabajo pendiente
E - Errors:      Errores del recurso
```

### Labels

```typescript
// ✅ Labels de baja cardinalidad
http_requests_total{method="GET", status="200"}
http_requests_total{method="POST", status="201"}

// ❌ Labels de alta cardinalidad (evitar)
http_requests_total{user_id="12345"}  // Millones de series
http_requests_total{request_id="..."}  // Infinitas series
```

## Tracing distribuido

### Propagación de contexto

```typescript
// Middleware para propagar trace context
function tracingMiddleware(req, res, next) {
  const traceId = req.headers['x-trace-id'] || generateTraceId();
  const spanId = generateSpanId();
  
  // Almacenar en async context
  context.run({ traceId, spanId }, () => {
    res.setHeader('x-trace-id', traceId);
    next();
  });
}
```

### Spans

```typescript
// ✅ Spans con información útil
const span = tracer.startSpan('db.query', {
  attributes: {
    'db.system': 'postgresql',
    'db.operation': 'SELECT',
    'db.table': 'users',
  },
});

try {
  const result = await db.query(sql);
  span.setStatus({ code: SpanStatusCode.OK });
  return result;
} catch (error) {
  span.setStatus({ code: SpanStatusCode.ERROR, message: error.message });
  span.recordException(error);
  throw error;
} finally {
  span.end();
}
```

### Qué instrumentar

| Operación | Prioridad | Atributos clave |
|-----------|-----------|-----------------|
| HTTP entrante | Alta | method, path, status |
| HTTP saliente | Alta | method, url, status |
| Database | Alta | operation, table |
| Cache | Media | operation, hit/miss |
| Queue | Media | operation, queue_name |
| Funciones críticas | Baja | custom |

## Health checks

### Endpoints requeridos

```typescript
// /health - Liveness (¿está vivo?)
GET /health
Response: { status: 'ok' }

// /ready - Readiness (¿puede recibir tráfico?)
GET /ready
Response: { 
  status: 'ok',
  checks: {
    database: 'ok',
    cache: 'ok',
    externalApi: 'degraded'  // No bloquea, pero alertar
  }
}
```

### Patrones

```typescript
// ✅ Health check con timeout
async function checkDatabase(): Promise<HealthStatus> {
  const timeout = 5000;
  try {
    await Promise.race([
      db.query('SELECT 1'),
      sleep(timeout).then(() => { throw new Error('Timeout') }),
    ]);
    return { status: 'ok' };
  } catch (error) {
    return { status: 'error', message: error.message };
  }
}
```

## Alertas

### Principios

1. **Actionable**: Cada alerta debe tener una acción clara
2. **Urgente**: Si no es urgente, no es alerta (es log)
3. **Específica**: Incluir contexto para diagnóstico rápido

### Ejemplos

```yaml
# ✅ Alerta actionable
- alert: HighErrorRate
  expr: rate(http_requests_total{status=~"5.."}[5m]) > 0.1
  for: 5m
  labels:
    severity: critical
  annotations:
    summary: "High error rate detected"
    runbook: "https://wiki/runbooks/high-error-rate"

# ❌ Alerta no actionable
- alert: CPUHigh
  expr: cpu_usage > 80
  # ¿Y qué hago? Puede ser normal bajo carga
```

## Checklist para el agente

Al implementar código, incluir:

- [ ] Logs estructurados en puntos clave
- [ ] Propagación de trace_id
- [ ] Métricas RED para endpoints HTTP
- [ ] Health check si es servicio independiente
- [ ] Manejo de errores que preserve contexto
