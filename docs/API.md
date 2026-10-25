# Contrato HTTP de referencia (v0.1)

> **Estado:** contrato esperado por el cliente Flutter actual. La implementación de firmware no está publicada en este repositorio y no se ha verificado aquí. Puede requerir adaptación.

## Obtener estado

```http
GET /api/state
```

Ejemplo de respuesta esperado por `LedState.fromJson`:

```json
{
  "power": true,
  "brightness": 128,
  "effect": 0,
  "speed": 100,
  "color": 10494192,
  "pixels": 320,
  "audioLevel": 0,
  "wifi": "connected"
}
```

El cliente utiliza valores predeterminados si faltan ciertos campos, por lo que una respuesta incompleta puede ocultar una incompatibilidad de firmware.

## Enviar comandos

```http
POST /api/control
Content-Type: application/x-www-form-urlencoded

power=true&brightness=128&effect=0&speed=100
```

El cliente también puede enviar `color=0xA020F0`. Se espera un JSON con la misma estructura del estado como respuesta.

| Campo | Tipo esperado | Uso |
| --- | --- | --- |
| `power` | `true` / `false` | Encender o apagar |
| `brightness` | Entero 0–255 | Brillo |
| `effect` | Entero | Identificador de efecto; mapa pendiente de validar |
| `speed` | Entero 1–255 | Velocidad |
| `color` | Texto hexadecimal `0xRRGGBB` | Color |

## Compatibilidad y seguridad

- No hay autenticación en el cliente HTTP actual.
- Usar exclusivamente en una red local confiable; no abrir puertos del router hacia la ESP32.
- Se recomienda versionar el contrato (por ejemplo, `/api/version`) y añadir errores JSON consistentes.
- Los nombres de efectos de la app son ilustrativos hasta verificar su correspondencia con el firmware.
