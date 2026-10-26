> Firmware 0.8.0: alta WiFi/nombre/píxeles por [Bluetooth GATT v1](BLUETOOTH.md). HTTP local se usa después del alta; ya no existe `/setup`. `/api/control` rechaza valores fuera de rango o con tipos incorrectos antes de aplicar cambios. Rango: píxeles 1–1024, brillo 0–255, velocidad 1–255, efecto 0–11, color RGB 0–0xFFFFFF. El endpoint no tiene autenticación/TLS y requiere red privada.

# Contrato HTTP de referencia (v0.1)

> Implementado en `firmware/src/main.cpp`. La cantidad se configura por controlador desde Android y se conserva en NVS.

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
  "pixels": 60,
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
| `pixels` | Entero 1–1024 | Cantidad de píxeles/grupos direccionables de esta tira |

Ejemplo: `POST /api/control` con `pixels=60` devuelve el estado con `pixels: 60`. También se admite JSON con `{"pixels":60}`. Valores vacíos, fraccionarios, no numéricos o fuera de rango devuelven HTTP 400 sin modificar el estado. `GET /api/info` anuncia `pixels`, `max_pixels`, protocolo y orden de color.

Android guarda la cantidad por controlador y la aplica al conectar cuando difiere del estado. Si la ESP32 está desconectada, la configuración queda guardada en el teléfono y se intenta aplicar en la próxima conexión. Si un firmware antiguo ignora `pixels`, la app muestra un error en vez de darlo por configurado. Los controladores guardados por versiones anteriores no se sobrescriben con una cantidad predeterminada.

## Compatibilidad y seguridad

- No hay autenticación en el cliente HTTP actual.
- Usar exclusivamente en una red local confiable; no abrir puertos del router hacia la ESP32.
- Se recomienda versionar el contrato (por ejemplo, `/api/version`) y añadir errores JSON consistentes.
- Los nombres de efectos de la app son ilustrativos hasta verificar su correspondencia con el firmware.

