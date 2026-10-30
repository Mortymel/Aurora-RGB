# Aurora — iluminación ESP32 desde Android

Aurora es una app Android nativa hecha con Flutter, acompañada por el firmware LEDWeb y un instalador USB desde el navegador. El control funciona en tu red local; no necesita un servicio en la nube.

**Versiones de referencia:** Aurora Android **1.1.0**, LEDWeb **1.3.0**. Documentación revisada el **30 de octubre de 2026**.

## Empezar

1. [Instala LEDWeb con el web flasher](https://mortymel.github.io/ESP32-RGB-Studio-/) desde Chrome/Edge de escritorio y un cable USB de datos.
2. Descarga el APK del workflow [Aurora Flutter Android](https://github.com/Mortymel/ESP32-RGB-Studio-/actions?query=workflow%3A%22Aurora+Flutter+Android%22). El artefacto se llama `Aurora-Flutter-Android-1.1.0`; contiene el APK y su SHA-256. GitHub puede pedir iniciar sesión y los artefactos caducan a los 30 días. No hay una publicación en Google Play.
3. Conecta el teléfono a `LEDWeb-…` (clave inicial `tiraesp32`). En Aurora añade `192.168.4.1`, usuario `admin` y esa contraseña, salvo que las cambiaste al compilar.
4. Configura tu Wi-Fi de 2,4 GHz y actualiza la IP del controlador con la asignada por el router. También puedes buscar controladores en el Wi-Fi.

[Guía de instalación](docs/INSTALACION.md) · [Solución de problemas](docs/SOLUCION-DE-PROBLEMAS.md) · [Home Assistant](docs/MQTT-HOME-ASSISTANT.md)

## Funciones entregadas

- Encendido, apagado, brillo, velocidad, rueda táctil de color y colores rápidos. RGB/HEX queda en ajuste preciso.
- Color en vivo con envíos limitados y deshacer el último cambio.
- 32 efectos, tarjetas de vista previa, búsqueda, categorías, favoritos y hasta 50 ambientes.
- Cuatro horarios semanales, sincronización del reloj, desfase UTC fijo y cuenta atrás de hasta siete días.
- Varios controladores, búsqueda mDNS, alta manual por IP, edición de credenciales y recuperación de conexión.
- Configuración Wi-Fi y MQTT con descubrimiento de Home Assistant.
- LEDWeb 1.3: límite de brillo, transición de encendido/apagado de 0 a 5 s, dirección invertida, recuperación opcional del estado persistido y diagnóstico.
- Tema claro/oscuro/automático y demo nativa. La vista previa aparece solo en Mi luz y Efectos.

## Código y organización

| Componente | Ubicación y estado |
|---|---|
| App Android actual | [`apps/aurora_flutter` en la rama de Aurora](https://github.com/Mortymel/ESP32-RGB-Studio-/tree/codex/aurora-flutter-android/apps/aurora_flutter); su integración está en [PR #1](https://github.com/Mortymel/ESP32-RGB-Studio-/pull/1). No se presupone fusionada en main. |
| Firmware actual | [`ledweb/firmware/LEDWeb`](ledweb/firmware/LEDWeb) en main |
| Interfaz alojada en la placa | [`ledweb/app/aurora`](ledweb/app/aurora) |
| Web flasher actual | [`web-flasher/aurora`](web-flasher/aurora) |
| Compilar/publicar firmware | `.github/workflows/aurora-flasher.yml` |
| Compilar APK | `aurora-android.yml` en la rama de la app |

Los directorios raíz `lib/`, `test/`, `firmware/`, el `pubspec.yaml` raíz y el instalador raíz anterior son código heredado. No son los puntos de entrada de Aurora. Su API y aprovisionamiento no deben mezclarse con los actuales.

## Documentación

[Índice completo](docs/README.md) · [Arquitectura](docs/ARQUITECTURA.md) · [API](docs/API.md) · [Hardware](docs/HARDWARE.md) · [Auditoría](docs/AUDITORIA.md) · [Seguridad](SECURITY.md) · [Contribuir](CONTRIBUTING.md) · [Cambios](CHANGELOG.md)

## Estado de validación

16 pruebas Flutter aprobadas, análisis sin incidencias, APK compilado con firma de prueba y SHA-256 verificado. LEDWeb 1.3 compilado para ESP32-C6 y ESP32 clásico; imágenes y hashes públicos verificados. Instalador comprobado en Chrome, con diseño móvil/escritorio sin desbordamiento.

Falta validación en el teléfono, router, ESP32, tira XGB1338 y broker reales. HTTP/MQTT local no cifran el tráfico. No se incluyen OTA, grupos, segmentos, widgets ni firma estable de distribución. Consulta la auditoría antes de interpretar una compilación como una prueba física.
