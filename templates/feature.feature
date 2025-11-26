# language: es
@feature-id @tag-categoria
Feature: {Nombre descriptivo de la funcionalidad}
  Como {rol/persona}
  Quiero {acción/capacidad}
  Para {beneficio/valor}

  Descripción:
    {Contexto adicional sobre la funcionalidad.
    Incluir cualquier información relevante que ayude
    a entender el propósito y alcance.}

  Reglas de negocio:
    - {Regla 1}
    - {Regla 2}

  Background:
    Given {precondición común a todos los escenarios}
    And {otra precondición si aplica}

  # ============================================
  # Escenarios del camino feliz
  # ============================================

  @S-001 @happy-path
  Scenario: {Descripción clara del escenario exitoso}
    Given {contexto inicial}
    And {contexto adicional si necesario}
    When {acción del usuario/sistema}
    And {acción adicional si necesaria}
    Then {resultado esperado}
    And {verificación adicional}

  @S-002 @happy-path
  Scenario Outline: {Escenario con múltiples variantes}
    Given {contexto con <variable>}
    When {acción con <input>}
    Then {resultado con <expected>}

    Examples:
      | variable | input | expected |
      | valor1   | x     | y        |
      | valor2   | a     | b        |

  # ============================================
  # Escenarios de error y edge cases
  # ============================================

  @S-003 @error-handling
  Scenario: {Descripción del caso de error}
    Given {contexto que llevará a error}
    When {acción que falla}
    Then {mensaje de error esperado}
    And {estado del sistema tras el error}

  @S-004 @edge-case
  Scenario: {Descripción del caso límite}
    Given {contexto especial/límite}
    When {acción en condición límite}
    Then {comportamiento esperado}

  # ============================================
  # Escenarios de seguridad (si aplica)
  # ============================================

  @S-005 @security
  Scenario: {Usuario sin permisos intenta acción}
    Given {usuario sin el permiso requerido}
    When {intenta realizar la acción}
    Then {acceso denegado}
    And {evento de seguridad registrado}
