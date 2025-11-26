# Guía de Contribución

¡Gracias por tu interés en contribuir a `.ai-dev`! Este documento explica cómo puedes participar en el desarrollo del framework.

## Tabla de Contenidos

- [Código de Conducta](#código-de-conducta)
- [¿Cómo puedo contribuir?](#cómo-puedo-contribuir)
- [Configuración del entorno](#configuración-del-entorno)
- [Flujo de trabajo](#flujo-de-trabajo)
- [Guía de estilo](#guía-de-estilo)
- [Proceso de revisión](#proceso-de-revisión)

## Código de Conducta

Este proyecto sigue el [Código de Conducta](CODE_OF_CONDUCT.md). Al participar, aceptas cumplirlo.

## ¿Cómo puedo contribuir?

### Reportar bugs

Si encuentras un bug:

1. Busca en los [issues existentes](https://github.com/soydachi/.ai-dev/issues) para evitar duplicados
2. Si no existe, [crea un nuevo issue](https://github.com/soydachi/.ai-dev/issues/new?template=bug_report.md) usando la plantilla de bug
3. Incluye toda la información posible: pasos para reproducir, comportamiento esperado vs actual

### Sugerir mejoras

¿Tienes una idea para mejorar el framework?

1. Revisa los [issues y discussions](https://github.com/soydachi/.ai-dev/issues) para ver si ya se propuso
2. [Abre un feature request](https://github.com/soydachi/.ai-dev/issues/new?template=feature_request.md) describiendo tu propuesta
3. Sé específico sobre el problema que resuelve y cómo beneficia a la comunidad

### Añadir o mejorar estándares

Los estándares técnicos son el corazón de este framework. Puedes:

- **Mejorar estándares existentes**: Corregir errores, añadir ejemplos, actualizar versiones
- **Añadir nuevos estándares**: Para lenguajes, frameworks o prácticas no cubiertas
- **Traducir estándares**: Ayudar a que el framework sea accesible en más idiomas

### Mejorar documentación

La documentación siempre puede mejorar:

- Corregir typos o errores gramaticales
- Añadir ejemplos más claros
- Mejorar la estructura o navegación
- Traducir a otros idiomas

### Contribuir templates

Los templates en `templates/` deben ser útiles y reutilizables:

- Mejorar templates existentes basándote en tu experiencia
- Proponer nuevos templates para casos de uso comunes

## Configuración del entorno

1. **Fork** el repositorio en tu cuenta de GitHub

2. **Clona** tu fork localmente:
   ```bash
   git clone https://github.com/TU-USUARIO/.ai-dev.git
   cd .ai-dev
   ```

3. **Añade el upstream** para mantenerte sincronizado:
   ```bash
   git remote add upstream https://github.com/soydachi/.ai-dev.git
   ```

4. **Crea una rama** para tu contribución:
   ```bash
   git checkout -b tipo/descripcion-corta
   # Ejemplos:
   # git checkout -b feat/standard-rust
   # git checkout -b fix/typo-readme
   # git checkout -b docs/improve-examples
   ```

## Flujo de trabajo

### 1. Sincroniza tu fork

Antes de empezar, asegúrate de tener la última versión:

```bash
git fetch upstream
git checkout main
git merge upstream/main
```

### 2. Crea tu rama

Usa prefijos descriptivos:
- `feat/` - Nueva funcionalidad o estándar
- `fix/` - Corrección de errores
- `docs/` - Mejoras de documentación
- `refactor/` - Reestructuración sin cambio funcional
- `chore/` - Tareas de mantenimiento

### 3. Haz tus cambios

- Sigue la [guía de estilo](#guía-de-estilo)
- Mantén los cambios enfocados (un tema por PR)
- Actualiza documentación relacionada si es necesario

### 4. Commit tus cambios

Usamos [Conventional Commits](https://www.conventionalcommits.org/):

```bash
git commit -m "feat(standards): add Rust development standard"
git commit -m "fix(templates): correct Gherkin syntax in feature template"
git commit -m "docs(readme): improve quick start section"
```

Formato: `tipo(alcance): descripción`

Tipos válidos:
- `feat`: Nueva funcionalidad
- `fix`: Corrección de bug
- `docs`: Solo documentación
- `style`: Formato, sin cambios de código
- `refactor`: Refactoring sin cambio funcional
- `test`: Añadir o corregir tests
- `chore`: Mantenimiento

### 5. Push y Pull Request

```bash
git push origin tu-rama
```

Luego, abre un Pull Request en GitHub siguiendo la plantilla.

## Guía de estilo

### Markdown

- Usa encabezados jerárquicos (`#`, `##`, `###`)
- Incluye tabla de contenidos en documentos largos
- Usa bloques de código con el lenguaje especificado
- Líneas de máximo 120 caracteres (excepto URLs y tablas)
- Una línea en blanco entre secciones

### Estándares técnicos (`standards/*.md`)

Cada estándar debe seguir esta estructura:

```markdown
# Nombre del Estándar

Descripción breve del propósito.

## Versiones soportadas

- Version X.Y (recomendada)
- Version X.Z (mínima)

## Principios

1. Principio uno
2. Principio dos

## Configuración base

[Configuración mínima requerida]

## Estructura de proyecto

[Organización de directorios]

## Convenciones

### Nombrado
[Reglas de nombrado]

### Patrones
[Patrones recomendados]

## Anti-patrones

[Qué evitar]

## Referencias

- [Enlace 1](url)
- [Enlace 2](url)
```

### Templates (`templates/*.md`)

- Incluye comentarios explicativos con `<!-- -->`
- Usa placeholders claros como `{nombre-feature}`, `[descripción]`
- Mantén la compatibilidad con el flujo de trabajo del framework

### Idioma

- El framework está en **español** por defecto
- Los ejemplos de código pueden estar en inglés (convención de la industria)
- Mantén consistencia dentro de cada archivo

## Proceso de revisión

### ¿Qué esperamos en un PR?

1. **Descripción clara**: Explica qué cambia y por qué
2. **Cambios enfocados**: Un tema por PR
3. **Sin conflictos**: Sincroniza con `main` antes de abrir
4. **Documentación actualizada**: Si tu cambio lo requiere

### Tiempos de respuesta

- **Primera respuesta**: Intentamos revisar en 48-72 horas
- **Revisiones adicionales**: Depende de la complejidad

### Criterios de aceptación

- [ ] Sigue la guía de estilo
- [ ] No rompe compatibilidad sin justificación
- [ ] Añade valor claro al framework
- [ ] Documentación clara y completa

### Después del merge

Tu contribución aparecerá en el próximo release. ¡Gracias por contribuir!

## ¿Preguntas?

- Abre un [Discussion](https://github.com/soydachi/.ai-dev/discussions) para preguntas generales
- Abre un [Issue](https://github.com/soydachi/.ai-dev/issues) para bugs o feature requests

---

¡Gracias por hacer `.ai-dev` mejor para todos!
