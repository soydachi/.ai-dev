# Implementation Plans

Cada feature tiene su propio directorio con:

```
plans/
└── {feature-id}-{nombre}/
    ├── plan.md        # Diseño técnico completo
    ├── decisions.md   # ADRs específicos del feature
    └── progress.md    # Estado de implementación
```

## Ciclo de vida

1. **Draft**: Plan en borrador, abierto a cambios
2. **Approved**: Plan aprobado, listo para implementar
3. **In Progress**: Implementación activa
4. **Completed**: Todos los escenarios completados
5. **Cancelled**: Descartado (documentar razón)

## Crear nuevo plan

```bash
# Copiar template
cp -r templates/plan-template plans/F-XXX-nombre-feature/

# O pedir al agente
/plan nueva-funcionalidad
```
