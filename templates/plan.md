# Implementation plan: {feature-name}

> ID: F-XXX
> Estado: {draft | approved | in-progress | completed | cancelled}
> Creado: {fecha}
> Última actualización: {fecha}

## Resumen ejecutivo

{1-2 párrafos describiendo qué se va a construir y por qué}

## Requisitos

### Funcionales

| ID | Requisito | Prioridad | Fuente |
|----|-----------|-----------|--------|
| RF-01 | | must | |
| RF-02 | | should | |

### No funcionales

| ID | Requisito | Métrica |
|----|-----------|---------|
| RNF-01 | Latencia p99 < 200ms | Medido en X |
| RNF-02 | Disponibilidad 99.9% | Medido en Y |

### Fuera de alcance

- {Qué NO incluye esta implementación}
- {Funcionalidad para futuro}

## Diseño técnico

### Arquitectura

```
{Diagrama ASCII o descripción de componentes}
```

### Componentes afectados

| Componente | Tipo de cambio | Impacto |
|------------|----------------|---------|
| | nuevo | |
| | modificación | |
| | eliminación | |

### Modelo de datos

```typescript
// Nuevas entidades o cambios a existentes
interface NewEntity {
  id: string;
  // ...
}
```

### APIs

```typescript
// Nuevos endpoints o cambios
POST /api/v1/resource
Request: { ... }
Response: { ... }
```

### Dependencias

| Tipo | Nombre | Versión | Justificación |
|------|--------|---------|---------------|
| npm | zod | ^3.22 | Validación de schemas |

## Escenarios (Gherkin)

Ver: `../features/{feature-name}.feature`

### Resumen de escenarios

| ID | Escenario | Complejidad | Dependencias |
|----|-----------|-------------|--------------|
| S-01 | | baja | ninguna |
| S-02 | | media | S-01 |

## Riesgos y mitigaciones

| Riesgo | Probabilidad | Impacto | Mitigación |
|--------|--------------|---------|------------|
| | alta | alto | |

## Plan de implementación

### Orden de escenarios

```
S-01 ──→ S-02 ──→ S-03
              ╲
               ──→ S-04
```

### Estimación

| Escenario | Estimación | Notas |
|-----------|------------|-------|
| S-01 | 2h | |
| S-02 | 4h | Requiere refactor de X |

### Definition of Done

- [ ] Todos los escenarios implementados
- [ ] Tests pasando con cobertura mínima
- [ ] Code review aprobado
- [ ] Documentación actualizada
- [ ] Sin vulnerabilidades de seguridad
- [ ] Métricas/logs implementados

## Notas técnicas

{Decisiones técnicas relevantes, trade-offs, consideraciones}

## Aprobaciones

| Rol | Nombre | Fecha | Estado |
|-----|--------|-------|--------|
| Tech Lead | | | pendiente |
| Product | | | pendiente |
