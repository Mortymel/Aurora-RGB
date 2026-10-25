# Auditoría técnica y de producto — Morty's LED

**Fecha:** 25 de octubre de 2026 · **Versión objetivo:** 0.4.0+4.

## Alcance y método

Revisión del código Flutter, cliente HTTP, almacenamiento, flujo de navegación, script Android, CI y documentación del repositorio. Se incorporó retroalimentación de capturas reales de Android. **No se ha realizado una prueba instrumental de rendimiento, análisis de accesibilidad automatizado ni ensayo con hardware físico.** El éxito de GitHub Actions confirma compilación y análisis estático, no una experiencia fluida ni compatibilidad eléctrica.

## Hallazgos y decisiones

| Severidad | Hallazgo | Acción / estado |
| --- | --- | --- |
| Alta | No había selector horizontal de varias tiras en inicio | Carrusel con PageView y nombre editable, incorporado en 0.4.0 |
| Alta | Respuestas de conexión podían actualizar el dispositivo equivocado | Contador de generación de conexión y verificación de instancia HTTP |
| Alta | El firmware no forma parte del repositorio | Plan de firmware v0.2 en [FIRMWARE-PLAN.md](FIRMWARE-PLAN.md) |
| Alta | MQTT/Home Assistant se presenta sin firmware MQTT | Sección informativa y contrato; integración pendiente |
| Alta | HTTP local sin autenticación ni cifrado | No exponer a Internet; autenticación y protección en roadmap |
| Media | Pantalla inicial con vista previa ornamental grande | Sustituida por tarjetas de dispositivos y control directo |
| Media | Múltiples llamadas HTTP por acciones consecutivas | Pendiente: serialización, coalescing y debounce de comandos |
| Media | `PageController` creado dentro de build | Pendiente: controlador persistente y prueba de gestos |
| Media | Reconexión y actualización periódica | Mejorada protección de peticiones obsoletas; pendiente backoff |
| Media | Persistencia en `shared_preferences` | Adecuada para nombres e IP; **no** para credenciales MQTT |
| Media | BLE solo escanea, no aprovisiona WiFi | Mantener etiquetado como experimental |
| Media | Android permite cleartext globalmente | Restringir tráfico y definir modelo de confianza en futura versión |
| Media | CI no ejecuta pruebas de widgets o integración | Agregar tests y simulador ESP32 |
| Baja | Textos demasiado explicativos y genéricos | Simplificación progresiva de textos y navegación |
| Baja | Identidad visual sin icono propio | Pendiente: icono de launcher, splash y guía visual |

## Rendimiento: siguientes acciones medibles

1. Medir frames y jank en Flutter DevTools en un Android físico de gama media.
2. Separar estado por dispositivo, limitar repintados y conservar PageController.
3. Aplicar debounce de 100–200 ms a controles continuos y limitar tráfico de red.
4. Evitar `setState` del árbol entero en cada lectura de estado.
5. Sustituir el polling fijo por WebSocket cuando exista firmware compatible.
6. Comprobar cambios de dispositivo durante solicitudes HTTP lentas y desconexiones.

## Seguridad y privacidad

- Nunca almacenar contraseñas de WiFi/MQTT en preferencias simples.
- El aprovisionamiento BLE requiere prueba de posesión y sesión protegida.
- No publicar puertos HTTP ni MQTT sin TLS/autenticación hacia Internet.
- Firmware OTA solo con imágenes firmadas y recuperación ante fallos.

## Pruebas obligatorias antes de declarar estable

- [ ] Añadir dos o más tiras, renombrarlas, reiniciar la app y comprobar persistencia.
- [ ] Deslizar rápidamente entre tiras, también con una fuera de línea.
- [ ] Confirmar que un comando nunca se envía al dispositivo equivocado.
- [ ] Probar brillo, color, encendido, velocidad y escenas con firmware real.
- [ ] Revisar orientación, tamaño de texto, teclado y accesibilidad.
- [ ] Medir frames y uso de memoria en teléfono físico.
- [ ] Validar MQTT Discovery con Mosquitto y Home Assistant.
- [ ] Verificar actualización desde la versión anterior sin perder dispositivos.

## Criterio de publicación

Se permite compartir un APK de pruebas cuando CI esté verde. Una versión estable exige las pruebas anteriores y un firmware compatible documentado.
