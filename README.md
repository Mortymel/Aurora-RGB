# ✨ ESP32 RGB Studio

**Control inteligente de iluminación LED direccionable con ESP32 y una aplicación móvil Flutter.**

[![Android APK](https://github.com/Mortymel/ESP32-RGB-Studio-/actions/workflows/android-apk.yml/badge.svg)](https://github.com/Mortymel/ESP32-RGB-Studio-/actions/workflows/android-apk.yml)
![Estado](https://img.shields.io/badge/estado-prototipo-orange)
![Hardware](https://img.shields.io/badge/hardware-ESP32--WROOM--32-blue)
![Android](https://img.shields.io/badge/app-Flutter-7C4DFF)

> **Proyecto en desarrollo.** El código Flutter está publicado en este repositorio privado. La compilación APK y la compatibilidad con firmware/hardware real todavía deben validarse. No se debe interpretar la hoja de ruta como una lista de funciones terminadas.

## 🌈 Qué es

ESP32 RGB Studio busca ofrecer una experiencia visual moderna para controlar tiras LED RGB IC desde Android, mediante un microcontrolador ESP32-WROOM-32. El prototipo incorpora una interfaz oscura con acentos violetas y controles de encendido, brillo, color, velocidad y selección de efectos.

La comunicación actual está diseñada para **WiFi local mediante HTTP**. El descubrimiento BLE es experimental; el aprovisionamiento WiFi por Bluetooth aún no está implementado.

## 📱 Funciones y estado

| Función | Estado |
| --- | --- |
| Interfaz Flutter con tema oscuro | Código disponible |
| Control WiFi HTTP | Implementado en cliente; integración pendiente |
| Encendido, brillo, color, efectos y velocidad | Interfaz implementada; hardware pendiente |
| Persistencia de dirección IP y nombre del dispositivo | Código disponible |
| Galería de escenas y escenas personalizadas locales | Código disponible; pruebas pendientes |
| Temporizador de apagado desde la app | Código disponible; requiere app abierta |
| Escaneo de dispositivos BLE | Experimental |
| Configurar WiFi por BLE | Planificado |
| Efectos de música con INMP441 | Planificado |
| Segmentos y escenas | Planificado |
| MQTT / Home Assistant | Planificado |
| WebSocket / OTA | Planificado |

## 🔌 Hardware de referencia

- **ESP32-WROOM-32** clásico.
- **BTF-LIGHTING FCOB RGB IC** a 5 V, 160 píxeles/m × 2 m = **320 píxeles**.
- Consumo nominal previsto de **16 W**; fuente propuesta **5 V / 5 A**, sujeta a comprobación.
- Conversión de nivel lógico recomendada con **74AHCT125**.
- **INMP441** I²S opcional para una etapa posterior.

⚠️ No alimentes la tira desde la placa ESP32. Consulta [cableado y seguridad](docs/HARDWARE.md) antes de conectar componentes.

## 🚀 Generar el APK

1. Abre [GitHub Actions — Android APK](https://github.com/Mortymel/ESP32-RGB-Studio-/actions/workflows/android-apk.yml).
2. Selecciona **Run workflow** en la rama `main`.
3. Espera a que la ejecución termine **en verde**.
4. Descarga el artefacto `ESP32-RGB-Studio-Android-APK` y extrae `app-release.apk`.

No se considera compilación verificada hasta que una ejecución termine correctamente. [Guía detallada](docs/INSTALACION.md).

## 🛠️ Desarrollo local

```bash
git clone https://github.com/Mortymel/ESP32-RGB-Studio-.git
cd ESP32-RGB-Studio-
flutter create --platforms=android --project-name esp32_rgb_studio .
python3 scripts/configure_android.py
flutter pub get
flutter run
```

Requiere Flutter, Android SDK y acceso autorizado a este repositorio privado.

## 📚 Documentación

| Guía | Contenido |
| --- | --- |
| [Instalación](docs/INSTALACION.md) | Compilación CI, APK y conexión |
| [Arquitectura](docs/ARQUITECTURA.md) | Componentes y flujos de comunicación |
| [Hardware](docs/HARDWARE.md) | Materiales, cableado y seguridad |
| [API HTTP](docs/API.md) | Contrato esperado por Flutter |
| [Hoja de ruta](docs/ROADMAP.md) | Fases, tareas y criterios 1.0 |
| [Solución de problemas](docs/SOLUCION-DE-PROBLEMAS.md) | Diagnóstico de build, red y BLE |
| [Investigación UX](docs/INVESTIGACION-UX.md) | Referentes WLED, Govee y Hue; prioridades |
| [Contribuir](CONTRIBUTING.md) | Convenciones y propuestas |
| [Seguridad](SECURITY.md) | Limitaciones y reporte responsable |

## 🧱 Organización del repositorio

```text
.github/workflows/android-apk.yml   CI Android
lib/main.dart                       Interfaz Flutter
lib/device_api.dart                 Cliente HTTP
lib/ble_provisioning.dart           Descubrimiento BLE experimental
scripts/configure_android.py        Permisos Android
docs/                               Documentación técnica
```

## 🔐 Seguridad

La API HTTP local no tiene autenticación ni TLS en el cliente actual. **No publiques puertos de la ESP32 hacia Internet** ni utilices la aplicación en entornos críticos. No almacenes contraseñas ni claves de firma en el repositorio.

## 🗺️ Próximos hitos

El primer objetivo es **obtener un APK reproducible y probarlo con firmware ESP32 real**. Después se priorizarán la estabilidad del control LED, el aprovisionamiento BLE seguro y las integraciones avanzadas. Consulta el [roadmap](docs/ROADMAP.md).

---

**ESP32 RGB Studio** · Prototipo personal de controlador RGB · Documentación en español.

**Licencia:** aún no se ha elegido una licencia de distribución. Al ser un repositorio privado, no se presupone autorización de redistribución.
