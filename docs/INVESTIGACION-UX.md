# Investigación de interfaces LED y criterios de producto

Fecha de referencia: octubre de 2026. Investigación de funciones públicas, **no** copia de diseños, marcas, recursos gráficos ni código propietario.

## Referentes

### WLED
Documentación oficial: https://kno.wled.ge/basics/web-ui/

Patrones útiles: control de encendido y brillo accesible, colores, efectos con parámetros, segmentos independientes, presets, playlists, temporizador, estado y configuración de dispositivo. **Decisión:** adoptar organización por tareas y controles de velocidad, escenas y estado; los segmentos requieren API de firmware.

### Govee Home
Sitio oficial: https://eu.govee.com/es-es/pages/govee-home-app

Patrones útiles: catálogo de ambientes, modo DIY, música, gestión de dispositivos y vista orientada a experiencias. **Decisión:** galería visual de escenas, escenas personales y ruta clara hacia música; no afirmar soporte de audio sin firmware.

### Philips Hue
Sitio oficial: https://www.philips-hue.com/en-us/philips-hue-app

Patrones útiles: navegación por habitaciones y zonas, escenas por ambiente, rutinas, agrupación de luces, acceso rápido al control principal. **Decisión:** navegación inferior con inicio/escenas/efectos/ajustes; futura agrupación multi-dispositivo.

## Priorización funcional

| Prioridad | Capacidad | Estado |
| --- | --- | --- |
| P0 | Conectar y mostrar estado real | Cliente implementado; firmware por validar |
| P0 | Encender, brillo, color, efecto, velocidad | Interfaz y comandos disponibles; por probar |
| P0 | APK reproducible | CI configurado; pendiente de éxito |
| P1 | Escenas prediseñadas | Implementado en cliente |
| P1 | Escenas personalizadas locales | Implementado en cliente |
| P1 | Renombrar y configurar IP | Implementado en cliente |
| P1 | Temporizador de apagado | Local y volátil; requiere app abierta |
| P1 | Selector HSV / hexadecimal | Pendiente |
| P1 | Animación realista de tira | Pendiente; preview actual es ilustrativo |
| P2 | Horarios y automatizaciones persistentes | Pendiente de firmware |
| P2 | Segmentos RGBIC | Pendiente de firmware y API |
| P2 | Música | Pendiente de captura y procesamiento |
| P2 | WiFi BLE seguro | Pendiente de firmware y protocolo |
| P2 | Multi-dispositivo y sincronización | Pendiente |
| P3 | MQTT/Home Assistant y OTA | Pendiente |

## Principios de diseño

1. **No simular conectividad:** sin dispositivo, los controles de hardware no deben aparentar éxito.
2. **Capacidades reales:** ocultar o etiquetar como futuras las funciones que el firmware no admite.
3. **Rápido y claro:** acceso a encendido, brillo, colores y escenas desde inicio.
4. **Privacidad por defecto:** control LAN, escenas locales y sin cuenta obligatoria.
5. **Seguridad:** no abrir HTTP sin autenticación a Internet ni enviar claves WiFi por BLE sin protección.
6. **Accesibilidad:** contraste, etiquetas, objetivos táctiles grandes y compatibilidad con texto escalado.

## Próximas iteraciones recomendadas

1. Lograr build verde y prueba física de Android.
2. Congelar contrato de firmware y probar control real.
3. Selector HSV, editor hexadecimal, favoritos y preview vinculada al estado.
4. API de capacidades, segmentos y transiciones.
5. Automatizaciones persistentes, BLE seguro y música.

Los patrones funcionales se inspiran en productos existentes; los componentes visuales y el código de ESP32 RGB Studio son originales.
