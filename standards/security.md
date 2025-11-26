# Estándares de seguridad

## Principios

1. **Defense in depth**: Múltiples capas de protección
2. **Least privilege**: Mínimos permisos necesarios
3. **Secure by default**: Configuración segura sin esfuerzo adicional
4. **Fail secure**: En caso de error, denegar acceso

## Gestión de secretos

### Prohibido

```typescript
// ❌ NUNCA hacer esto
const API_KEY = 'sk-1234567890abcdef';
const connectionString = 'postgres://user:password@host/db';
```

### Requerido

```typescript
// ✅ Variables de entorno
const apiKey = process.env.API_KEY;
if (!apiKey) throw new Error('API_KEY is required');

// ✅ Gestores de secretos
const secret = await secretManager.getSecret('api-key');
```

### Pre-commit

Herramientas obligatorias para detectar secretos:
- TruffleHog
- git-secrets
- detect-secrets

```yaml
# pre-commit hook
- repo: https://github.com/trufflesecurity/trufflehog
  hooks:
    - id: trufflehog
```

## Validación de inputs

### Siempre validar

```typescript
// ✅ Schema validation con tipos
import { z } from 'zod';

const CreateUserSchema = z.object({
  email: z.string().email().max(255),
  name: z.string().min(1).max(100),
  age: z.number().int().min(0).max(150).optional(),
});

function createUser(input: unknown) {
  const validated = CreateUserSchema.parse(input);
  // Ahora validated tiene tipos seguros
}
```

### Sanitización

```typescript
// Para HTML
import DOMPurify from 'dompurify';
const safeHtml = DOMPurify.sanitize(userInput);

// Para SQL - usar SIEMPRE parámetros
const result = await db.query(
  'SELECT * FROM users WHERE id = $1',
  [userId] // ✅ Parametrizado
);

// ❌ NUNCA concatenar
const result = await db.query(`SELECT * FROM users WHERE id = ${userId}`);
```

## Autenticación y autorización

### Tokens

```typescript
// ✅ JWT con expiración corta
const token = jwt.sign(payload, secret, { expiresIn: '15m' });

// ✅ Refresh tokens con rotación
const refreshToken = generateSecureToken();
await storeRefreshToken(userId, refreshToken, { expiresIn: '7d' });
```

### Passwords

```typescript
// ✅ Bcrypt con cost factor apropiado
import bcrypt from 'bcrypt';
const SALT_ROUNDS = 12;
const hash = await bcrypt.hash(password, SALT_ROUNDS);

// ✅ Comparación en tiempo constante
const isValid = await bcrypt.compare(inputPassword, storedHash);
```

### Autorización

```typescript
// ✅ Verificar permisos explícitamente
async function deleteUser(requesterId: string, targetId: string) {
  const requester = await userRepo.findById(requesterId);
  
  if (!requester.hasPermission('user:delete')) {
    throw new ForbiddenError('Insufficient permissions');
  }
  
  if (requester.id !== targetId && !requester.isAdmin) {
    throw new ForbiddenError('Cannot delete other users');
  }
  
  await userRepo.delete(targetId);
}
```

## Headers de seguridad

```typescript
// Helmet.js para Express/NestJS
import helmet from 'helmet';

app.use(helmet({
  contentSecurityPolicy: {
    directives: {
      defaultSrc: ["'self'"],
      scriptSrc: ["'self'"],
      styleSrc: ["'self'", "'unsafe-inline'"],
    },
  },
  hsts: {
    maxAge: 31536000,
    includeSubDomains: true,
  },
}));
```

## Logging seguro

```typescript
// ✅ Nunca loggear datos sensibles
logger.info('User login', {
  userId: user.id,
  email: maskEmail(user.email), // j***@example.com
  ip: request.ip,
});

// ❌ NUNCA
logger.info('User login', {
  password: user.password,
  token: user.authToken,
  creditCard: user.creditCard,
});
```

### Datos a excluir de logs

- Passwords
- Tokens (JWT, API keys)
- Números de tarjeta
- SSN/DNI
- Datos médicos
- PII sin enmascarar

## Dependencias

### Auditoría regular

```bash
# npm
npm audit
npm audit fix

# yarn
yarn audit

# pnpm
pnpm audit
```

### CI obligatorio

```yaml
# En pipeline
- name: Security audit
  run: npm audit --audit-level=high
  
- name: Snyk scan
  run: snyk test --severity-threshold=high
```

### Actualización de dependencias

- Revisar semanalmente
- Automatizar con Dependabot/Renovate
- No ignorar vulnerabilidades altas/críticas

## OWASP Top 10 - Checklist

| # | Vulnerabilidad | Mitigación |
|---|----------------|------------|
| 1 | Broken Access Control | Verificar permisos en cada endpoint |
| 2 | Cryptographic Failures | Usar algoritmos modernos, nunca custom |
| 3 | Injection | Parametrizar queries, validar inputs |
| 4 | Insecure Design | Threat modeling en diseño |
| 5 | Security Misconfiguration | Defaults seguros, auditar configs |
| 6 | Vulnerable Components | Audit + actualizar dependencias |
| 7 | Auth Failures | MFA, rate limiting, sesiones seguras |
| 8 | Software/Data Integrity | Verificar firmas, CI/CD seguro |
| 9 | Logging Failures | Loggear eventos de seguridad |
| 10 | SSRF | Validar/restringir URLs externas |

## Checklist para el agente

Antes de entregar código, verificar:

- [ ] ¿Sin secretos hardcodeados?
- [ ] ¿Inputs validados con schema?
- [ ] ¿Queries parametrizadas?
- [ ] ¿Autorización verificada?
- [ ] ¿Datos sensibles excluidos de logs?
- [ ] ¿Errores no exponen información interna?
- [ ] ¿Dependencias sin vulnerabilidades conocidas?
