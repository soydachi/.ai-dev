# Sistema de desarrollo asistido por IA

Framework para desarrollo de software con agentes IA de forma metódica, trazable y escalable.

## Problema que resuelve

Sin planificación, la IA te lleva por el camino que ella elige. El resultado: horas de contexto perdido, código incoherente y frustración. Este framework garantiza que la IA trabaje bajo un roadmap metódico donde tú mantienes el control.

## Principio fundamental

> La conversación con la IA es efímera. Este directorio es permanente.
> Todo lo que importa debe estar aquí, no en el chat.

## Inicio rápido

### 1. Configura tu proyecto

```bash
# Copia .ai-dev/ a la raíz de tu proyecto
cp -r .ai-dev/ /ruta/a/tu/proyecto/

# Edita el contexto con tu información
cd /ruta/a/tu/proyecto/.ai-dev
# Edita CONTEXT.md con tu stack y estado actual
```

### 2. Inicia sesión con el agente

Al comenzar cualquier sesión con IA, usa este prompt:

```
Lee .ai-dev/AGENT.md y .ai-dev/CONTEXT.md antes de empezar.
```

### 3. Comandos disponibles

| Comando | Acción |
|---------|--------|
| `/status` | Muestra estado actual del proyecto |
| `/next` | Continúa con el siguiente escenario pendiente |
| `/plan {feature}` | Inicia planificación de nuevo feature |
| `/review` | Ejecuta revisión de calidad |
| `/sync` | Actualiza todos los archivos de estado |
| `/reset` | Regenera CONTEXT.md desde el código |

## Estructura del framework

```
.ai-dev/
├── AGENT.md                    # Instrucciones para el agente IA
├── CONTEXT.md                  # Estado actual del proyecto
├── TASKS.md                    # Backlog y tareas en progreso
│
├── standards/                  # Estándares y convenciones
│   ├── code.md                 # Principios generales de código
│   ├── quality.md              # Testing, coverage, linting
│   ├── security.md             # Seguridad y OWASP
│   ├── observability.md        # Logs, métricas, tracing
│   ├── api.md                  # Diseño de APIs REST/GraphQL
│   ├── dotnet.md               # C#, .NET, ASP.NET Core
│   ├── typescript.md           # TypeScript, Node.js
│   ├── python.md               # Python, FastAPI, Django
│   ├── frontend.md             # React, React Native
│   ├── infrastructure.md       # Terraform, Bash, PowerShell
│   └── cloud-azure.md          # Azure, AKS, servicios cloud
│
├── plans/                      # Implementation plans por feature
│   └── {feature-id}/
│       ├── plan.md             # Diseño técnico
│       ├── decisions.md        # ADRs (Architecture Decision Records)
│       └── progress.md         # Estado de implementación
│
├── features/                   # Especificaciones Gherkin
│   └── *.feature
│
└── templates/                  # Plantillas reutilizables
    ├── plan.md
    ├── decision.md
    ├── progress.md
    └── feature.feature
```

## Flujo de trabajo

```
┌─────────────────────────────────────────────────────────────────┐
│  1. ONBOARDING                                                  │
│     Agente lee AGENT.md + CONTEXT.md + standards relevantes     │
└────────────────────────────┬────────────────────────────────────┘
                             │
                             ▼
┌─────────────────────────────────────────────────────────────────┐
│  2. PLANIFICACIÓN                                               │
│     - Usuario describe idea en lenguaje natural                 │
│     - Agente propone features en Gherkin                        │
│     - Se crea plan en plans/{feature}/plan.md                   │
│     - Se documentan decisiones en decisions.md                  │
└────────────────────────────┬────────────────────────────────────┘
                             │
                             ▼
┌─────────────────────────────────────────────────────────────────┐
│  3. VALIDACIÓN                                                  │
│     - Features aprobados se persisten en features/*.feature     │
│     - Se actualiza TASKS.md con escenarios                      │
│     - Plan marcado como "approved"                              │
└────────────────────────────┬────────────────────────────────────┘
                             │
                             ▼
┌─────────────────────────────────────────────────────────────────┐
│  4. IMPLEMENTACIÓN                                              │
│     Por cada escenario:                                         │
│     - Marcar "en progreso" en TASKS.md                          │
│     - Proponer approach → validar → implementar                 │
│     - Crear tests basados en Gherkin                            │
│     - Marcar "completado" → actualizar progress.md              │
└────────────────────────────┬────────────────────────────────────┘
                             │
                             ▼
┌─────────────────────────────────────────────────────────────────┐
│  5. CIERRE                                                      │
│     - Actualizar CONTEXT.md con cambios relevantes              │
│     - Feature marcado como "completed"                          │
│     - Identificar siguiente prioridad                           │
└─────────────────────────────────────────────────────────────────┘
```

## Archivos clave

### AGENT.md

Instrucciones que definen cómo debe comportarse el agente IA. Incluye:
- Protocolo de inicio de sesión
- Principios operativos (no improvisar, documentar, mantener alcance)
- Flujo de trabajo detallado
- Formato de respuestas
- Checklist de calidad

### CONTEXT.md

Fuente de verdad del estado del proyecto:
- Stack tecnológico
- Arquitectura actual
- Feature activo y progreso
- Deuda técnica conocida
- Notas para el agente

### TASKS.md

Sistema Kanban simplificado:
- Tareas en progreso
- Backlog priorizado
- Completadas (últimas 10)
- Bloqueadores activos

## Estándares disponibles

### Generales
- `code.md` - Principios, estructura, nombrado, patrones
- `quality.md` - Testing, cobertura, linting, code review
- `security.md` - OWASP, secretos, validación, autenticación
- `observability.md` - Logging, métricas, tracing, alertas

### Por tecnología
- `dotnet.md` - C#, .NET 8+, ASP.NET Core, Entity Framework
- `typescript.md` - TypeScript, Node.js, NestJS
- `python.md` - Python 3.11+, FastAPI, async patterns
- `frontend.md` - React, React Native, estado, componentes
- `api.md` - REST, GraphQL, versionado, documentación
- `infrastructure.md` - Terraform, Bash, PowerShell, YAML
- `cloud-azure.md` - Azure, AKS, servicios, networking

## Ventajas vs desarrollo ad-hoc con IA

| Aspecto | Sin framework | Con framework |
|---------|---------------|---------------|
| Contexto | Se pierde entre sesiones | Persistido en archivos |
| Decisiones | Implícitas en chat | ADRs documentados |
| Estándares | Cada vez diferente | Consistentes y auditables |
| Recovery | Empezar de cero | Retomar donde quedó |
| Colaboración | Imposible | Múltiples devs + agentes |
| Trazabilidad | Ninguna | Plan → Feature → Code |

## Personalización

### Añadir estándares propios

```bash
# Crea nuevo estándar
touch .ai-dev/standards/mi-estandar.md

# Referéncialo en AGENT.md si es obligatorio
```

### Modificar templates

Los templates en `templates/` son punto de partida. Ajústalos a las necesidades de tu equipo.

### Integrar con CI/CD

```yaml
# Ejemplo: validar que CONTEXT.md esté actualizado
- script: |
    if ! grep -q "$(date +%Y-%m)" .ai-dev/CONTEXT.md; then
      echo "CONTEXT.md no actualizado este mes"
      exit 1
    fi
```

## FAQ

**¿Funciona con cualquier IA?**
Sí. Claude, GPT-4, Gemini, Copilot. El framework es agnóstico.

**¿Puedo usarlo en proyectos existentes?**
Sí. Copia `.ai-dev/`, edita `CONTEXT.md` con el estado actual y comienza.

**¿Cuánto tiempo toma la planificación inicial?**
~30 minutos. El ahorro posterior es de horas.

**¿Es obligatorio Gherkin?**
Recomendado pero no obligatorio. Puedes usar otro formato de especificación.

## Soporte

Para mejoras o issues, contacta al equipo de Platform Engineering.
