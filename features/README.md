# Features

Este directorio contiene las especificaciones Gherkin del proyecto.

## Convenciones

- Un archivo `.feature` por funcionalidad
- Nombrado: `{feature-id}-{nombre-descriptivo}.feature`
- Usar tags para categorizar: `@api`, `@ui`, `@integration`
- Escenarios numerados: `@S-001`, `@S-002`

## Estructura de tags

```
@F-001          # ID del feature
@epic-xxx       # Epic/iniciativa padre
@api            # Categoría técnica
@priority-high  # Prioridad
@wip            # Work in progress (no ejecutar en CI)
```
