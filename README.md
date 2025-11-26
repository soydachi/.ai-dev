<div align="center">

# .ai-dev

### Framework para desarrollo de software con agentes IA

[![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](LICENSE)
[![PRs Welcome](https://img.shields.io/badge/PRs-welcome-brightgreen.svg)](CONTRIBUTING.md)
[![GitHub issues](https://img.shields.io/github/issues/soydachi/.ai-dev)](https://github.com/soydachi/.ai-dev/issues)
[![GitHub stars](https://img.shields.io/github/stars/soydachi/.ai-dev)](https://github.com/soydachi/.ai-dev/stargazers)
[![Contributor Covenant](https://img.shields.io/badge/Contributor%20Covenant-2.1-4baaaa.svg)](CODE_OF_CONDUCT.md)

**Desarrollo metódico, trazable y escalable con agentes IA**

[Inicio Rápido](#inicio-rápido) •
[Documentación](#estructura-del-framework) •
[Contribuir](CONTRIBUTING.md) •
[Estándares](#estándares-disponibles)

</div>

---

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

## Compatibilidad

Este framework es **agnóstico** y funciona con cualquier agente IA:

| Agente | Compatibilidad |
|--------|----------------|
| Claude | Excelente |
| GPT-4 / ChatGPT | Excelente |
| GitHub Copilot | Excelente |
| Gemini | Excelente |
| Otros LLMs | Buena |

## Contribuir

¡Las contribuciones son bienvenidas! Hay muchas formas de ayudar:

- Reportar bugs o sugerir mejoras
- Añadir nuevos estándares técnicos
- Mejorar la documentación existente
- Traducir a otros idiomas
- Compartir tu experiencia usándolo

Lee la [guía de contribución](CONTRIBUTING.md) para comenzar.

### Good First Issues

¿Primera vez contribuyendo? Busca issues etiquetados con:

[![good first issue](https://img.shields.io/github/labels/soydachi/.ai-dev/good%20first%20issue)](https://github.com/soydachi/.ai-dev/issues?q=is%3Aissue+is%3Aopen+label%3A%22good+first+issue%22)
[![help wanted](https://img.shields.io/github/labels/soydachi/.ai-dev/help%20wanted)](https://github.com/soydachi/.ai-dev/issues?q=is%3Aissue+is%3Aopen+label%3A%22help+wanted%22)

## Contributors

<a href="https://github.com/soydachi/.ai-dev/graphs/contributors">
  <img src="https://contrib.rocks/image?repo=soydachi/.ai-dev" alt="Contributors" />
</a>

## Comunidad

- [Discussions](https://github.com/soydachi/.ai-dev/discussions) - Preguntas, ideas y conversaciones
- [Issues](https://github.com/soydachi/.ai-dev/issues) - Reportar bugs o sugerir features

## Licencia

Este proyecto está bajo la licencia Apache 2.0 - ver el archivo [LICENSE](LICENSE) para más detalles.

---

<div align="center">

**¿Te ha sido útil?** Dale una estrella y compártelo

[![Star History Chart](https://api.star-history.com/svg?repos=soydachi/.ai-dev&type=Date)](https://star-history.com/#soydachi/.ai-dev&Date)

</div>
