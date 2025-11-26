# Estándares de calidad

## Testing

### Pirámide de tests

```
        /\
       /  \      E2E (pocos, críticos)
      /----\
     /      \    Integración (moderados)
    /--------\
   /          \  Unitarios (muchos, rápidos)
  /------------\
```

### Cobertura mínima

| Capa | Cobertura | Razón |
|------|-----------|-------|
| Domain | 90% | Lógica de negocio crítica |
| Application | 80% | Orquestación de casos de uso |
| Infrastructure | 60% | Integración con externos |
| Presentation | 40% | Mapeo y validación |

### Estructura de tests

```typescript
describe('UserService', () => {
  describe('createUser', () => {
    it('should create user when input is valid', async () => {
      // Arrange
      const input = { name: 'John', email: 'john@example.com' };
      
      // Act
      const result = await service.createUser(input);
      
      // Assert
      expect(result.name).toBe('John');
    });

    it('should throw UserAlreadyExistsError when email is taken', async () => {
      // Arrange
      const input = { name: 'John', email: 'existing@example.com' };
      mockRepo.findByEmail.mockResolvedValue(existingUser);
      
      // Act & Assert
      await expect(service.createUser(input))
        .rejects
        .toThrow(UserAlreadyExistsError);
    });
  });
});
```

### Nombrado de tests

```typescript
// ✅ Formato: should {resultado esperado} when {condición}
it('should return empty array when no users exist')
it('should throw ValidationError when email is invalid')
it('should retry 3 times when external service fails')

// ❌ Evitar
it('works correctly')
it('test createUser')
it('error handling')
```

### Mocking

```typescript
// ✅ Mock solo lo necesario
const mockRepo = {
  findById: jest.fn(),
  save: jest.fn(),
};

// ❌ No mockear implementación interna
jest.mock('./internal-helper'); // Solo si es absolutamente necesario
```

## Linting y formateo

### Configuración requerida

```json
// .eslintrc.json mínimo
{
  "extends": ["eslint:recommended"],
  "rules": {
    "no-unused-vars": "error",
    "no-console": "warn",
    "eqeqeq": "error",
    "no-var": "error",
    "prefer-const": "error"
  }
}
```

### Pre-commit hooks

Obligatorios:
- Lint
- Format check
- Type check
- Tests afectados

```bash
# Ejemplo con husky + lint-staged
npx lint-staged
```

## Code review checklist

### Funcionalidad

- [ ] ¿Cumple los criterios de aceptación del escenario Gherkin?
- [ ] ¿Maneja casos edge documentados?
- [ ] ¿Los errores son informativos y accionables?

### Código

- [ ] ¿Sigue los estándares de `code.md`?
- [ ] ¿Sin código duplicado significativo?
- [ ] ¿Nombrado claro y consistente?
- [ ] ¿Complejidad justificada?

### Tests

- [ ] ¿Cobertura adecuada para la capa?
- [ ] ¿Tests legibles y mantenibles?
- [ ] ¿Casos negativos cubiertos?

### Seguridad

- [ ] ¿Sin secretos hardcodeados?
- [ ] ¿Inputs validados?
- [ ] ¿Sin vulnerabilidades obvias (SQL injection, XSS, etc)?

### Documentación

- [ ] ¿Comentarios donde son necesarios?
- [ ] ¿README actualizado si aplica?
- [ ] ¿CHANGELOG actualizado?

## Métricas de calidad

### Automatizadas (CI)

| Métrica | Umbral | Herramienta |
|---------|--------|-------------|
| Cobertura | Ver por capa | Jest/Vitest |
| Complejidad | < 10 | ESLint |
| Duplicación | < 3% | SonarQube |
| Vulnerabilidades | 0 críticas | Snyk/npm audit |

### Manuales (review)

- Legibilidad (subjetivo pero importante)
- Alineación arquitectónica
- Potencial de reutilización
