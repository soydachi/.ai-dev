# Política de Seguridad

## Versiones Soportadas

| Versión | Soportada          |
| ------- | ------------------ |
| 1.x     | :white_check_mark: |

## Reportar una Vulnerabilidad

Agradecemos que nos ayudes a mantener `.ai-dev` seguro.

### ¿Qué reportar?

Aunque este proyecto es principalmente documentación y templates, te pedimos que reportes:

- Contenido en estándares que pueda llevar a prácticas inseguras
- Ejemplos de código que contengan vulnerabilidades
- Configuraciones por defecto que representen riesgos de seguridad
- Cualquier contenido que pueda comprometer la seguridad de proyectos que usen este framework

### ¿Cómo reportar?

**Para vulnerabilidades de seguridad**, por favor:

1. **NO** abras un issue público
2. Envía un mensaje privado a través de [GitHub Security Advisories](https://github.com/soydachi/.ai-dev/security/advisories/new)
3. O contacta directamente al mantenedor vía GitHub

### ¿Qué incluir en el reporte?

- Descripción clara del problema
- Ubicación del contenido afectado (archivo, línea)
- Impacto potencial en proyectos que usen el framework
- Sugerencia de corrección (si la tienes)

### Proceso de respuesta

1. **Confirmación**: Recibirás confirmación en 48 horas
2. **Evaluación**: Evaluaremos el impacto y prioridad
3. **Corrección**: Prepararemos un fix
4. **Disclosure**: Coordinaremos la divulgación responsable
5. **Crédito**: Te daremos crédito (si lo deseas) una vez publicado el fix

### Divulgación responsable

Te pedimos que:

- Nos des tiempo razonable para corregir antes de divulgar públicamente
- No explotes la vulnerabilidad más allá de lo necesario para demostrarla
- No accedas a datos de otros usuarios

## Mejores prácticas de seguridad

Al usar este framework en tus proyectos, recuerda:

### Secretos y credenciales

- Nunca incluyas secretos en archivos `.ai-dev/`
- Usa variables de entorno o secret managers
- Revisa el estándar `standards/security.md`

### Información sensible

- `CONTEXT.md` no debe contener credenciales
- Los planes en `plans/` no deben incluir tokens o API keys
- Revisa antes de hacer push a repositorios públicos

### Pre-commit hooks recomendados

Configura herramientas para detectar secretos antes del commit:

```bash
# TruffleHog
pip install trufflehog

# git-secrets
brew install git-secrets
git secrets --install
git secrets --register-aws

# detect-secrets
pip install detect-secrets
detect-secrets scan
```

## Contacto

Para preguntas sobre seguridad que no sean vulnerabilidades, abre un [Discussion](https://github.com/soydachi/.ai-dev/discussions).

---

¡Gracias por ayudar a mantener `.ai-dev` seguro!
