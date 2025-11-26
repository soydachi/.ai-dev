# Contexto del proyecto

> Última actualización: [FECHA]
> Actualizado por: [humano|agente]

<!--
INSTRUCCIONES: Completa esta plantilla con la información de tu proyecto.
Elimina los comentarios y ejemplos cuando lo configures.
-->

## Resumen

[Descripción breve del proyecto en 2-3 líneas. Ejemplo:]
API de gestión de pagos para el sistema de e-commerce. Maneja procesamiento de transacciones, 
reembolsos y conciliación con proveedores externos.

## Stack tecnológico

| Capa | Tecnología |
|------|------------|
| Lenguaje | [ej: C# 12 / TypeScript 5.x / Python 3.12] |
| Runtime | [ej: .NET 8 / Node 20 LTS / Python 3.12] |
| Framework | [ej: ASP.NET Core 8 / NestJS 10 / FastAPI] |
| Base de datos | [ej: PostgreSQL 16 / SQL Server 2022 / MongoDB 7] |
| Cache | [ej: Redis 7] |
| Mensajería | [ej: Azure Service Bus / RabbitMQ / Kafka] |
| Infraestructura | [ej: Azure AKS / Azure App Service / AWS ECS] |
| CI/CD | [ej: Azure Pipelines / GitHub Actions] |
| Observabilidad | [ej: Application Insights / Datadog / Prometheus+Grafana] |

## Arquitectura actual

```
[Incluir diagrama ASCII o descripción de alto nivel. Ejemplo:]

┌─────────────┐     ┌─────────────┐     ┌─────────────┐
│   API GW    │────▶│   App API   │────▶│  PostgreSQL │
└─────────────┘     └──────┬──────┘     └─────────────┘
                          │
                          ▼
                   ┌─────────────┐
                   │ Service Bus │
                   └──────┬──────┘
                          │
                          ▼
                   ┌─────────────┐
                   │   Worker    │
                   └─────────────┘
```

## Estado actual

### Feature activo

- **ID**: [F-XXX o "ninguno"]
- **Plan**: `plans/[feature-id]/plan.md`
- **Progreso**: [X/Y escenarios completados]
- **Bloqueadores**: [ninguno | lista de bloqueadores]

### Últimos cambios significativos

| Fecha | Cambio | Impacto |
|-------|--------|---------|
| [YYYY-MM-DD] | [descripción] | [componentes afectados] |

## Deuda técnica conocida

| ID | Descripción | Prioridad | Ubicación |
|----|-------------|-----------|-----------|
| DT-001 | [descripción del problema] | [alta/media/baja] | [archivo:línea o módulo] |

## Dependencias externas

| Servicio | Propósito | Estado | Documentación |
|----------|-----------|--------|---------------|
| [nombre] | [para qué se usa] | [operativo/degradado] | [link] |

## Variables de entorno requeridas

```bash
# Configuración de base de datos
DATABASE_URL=
DATABASE_MAX_CONNECTIONS=

# Autenticación
JWT_SECRET=
JWT_EXPIRATION_MINUTES=

# Servicios externos
PAYMENT_PROVIDER_API_KEY=
PAYMENT_PROVIDER_URL=

# Observabilidad
APPLICATIONINSIGHTS_CONNECTION_STRING=
```

## Convenciones específicas del proyecto

[Cualquier convención que difiera de los estándares generales o sea específica de este proyecto]

## Notas para el agente

[Cualquier contexto especial que el agente deba conocer para esta sesión. Ejemplos:]
- El módulo de pagos tiene tests flaky que a veces fallan por timeout
- No modificar nada en /legacy sin consultar primero
- Las migraciones de DB deben ser backward compatible
