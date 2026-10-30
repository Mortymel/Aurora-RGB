# Aurora para Android — Flutter

## Actualización 1.0.1

Catálogo con tarjetas y muestras de colores/patrones generadas por el renderizador de cada efecto. La esfera mantiene su volumen y usa texto sin emoji. Los formularios ocultan contadores de caracteres y muestran las contraseñas guardadas como «Contraseña configurada», con una acción «Cambiar». Las redes abiertas y MQTT sin autenticación se eligen explícitamente; dejar un campo sin editar conserva la clave existente.

Aplicación nativa nueva e independiente, con el diseño Aurora. **No es una WebView ni un acceso directo a la página web.** Su identificador Android es `com.mortymel.aurora_led`; puede coexistir con la app anterior.

## Funciones

- Mi luz: esfera con volumen que conserva el RGB, colores rápidos, brillo, velocidad, encendido y temporizador.
- Efectos: 32 efectos de LEDWeb, previsualización animada aproximada, categorías, búsqueda, favoritos y hasta 50 ambientes guardados.
- Horarios: cuatro reglas semanales ejecutadas por la ESP32, sincronización de reloj y zona UTC fija.
- Ajustes: número de píxeles, GPIO admitidos por la placa, RGB/GRB, Wi-Fi y MQTT con guía para Home Assistant.
- Varios controladores por IP o nombre `.local`, edición de credenciales y eliminación del teléfono.
- Contraseñas en almacenamiento protegido de Android; copias de seguridad de los datos desactivadas.
- Modo demo integrado para probar todas las pantallas sin placa. La vista previa solo aparece en Mi luz y Efectos.
- Tema claro, oscuro o automático. Vista previa detenida cuando el sistema solicita reducir animaciones.

## Conectar tu ESP32

1. Instala **LEDWeb 1.2** en la placa. El firmware antiguo de Morty's LED 0.8 utiliza otra API y no es compatible con esta app.
2. Conecta el teléfono al AP `LEDWeb-…`. La clave inicial es `tiraesp32`, salvo que la hayas cambiado al compilar.
3. Abre Aurora → Añadir ESP32. Usa `192.168.4.1`, usuario `admin` y la contraseña configurada en el firmware (inicial: `tiraesp32`).
4. En Ajustes → Wi-Fi, guarda tu red de 2,4 GHz. Vuelve a conectar el teléfono a esa red.
5. Obtén la nueva IP de la ESP32 en el router/monitor serie y actualízala en Ajustes → IP y credenciales. Conviene reservar esa IP en el router.

La app habla directamente con el controlador mediante HTTP JSON y autenticación Basic. No requiere nube ni un servidor adicional. MQTT es una conexión entre ESP32 y broker; la app configura los datos del broker a través del controlador.

## Ejecutar y compilar

Herramienta verificada: Flutter 3.47.8 / Dart 3.13.7. Android mínimo 7.0 (API 24), destino API 36 en este SDK. Para compilar localmente se necesita también Android SDK y Java 17.

```sh
cd apps/aurora_flutter
flutter create --platforms=android --org com.mortymel --project-name aurora_led --no-pub .
python scripts/configure_android.py
flutter pub get --enforce-lockfile
flutter analyze
flutter test
flutter run
# APK optimizado para pruebas:
flutter build apk --release
```

El APK queda en `build/app/outputs/flutter-apk/app-release.apk`. El workflow `.github/workflows/aurora-android.yml` ejecuta análisis, pruebas y compilación, comprueba la firma y publica el APK con SHA-256 como artefacto de Actions.

**Firma de prueba:** la configuración generada por Flutter firma este APK con la clave de depuración del entorno. No es una publicación en Google Play. Una compilación hecha en otro entorno puede tener otra firma y exigir desinstalar la anterior (se perderán sus datos locales). Para distribución y actualizaciones estables hay que configurar y conservar una clave de firma propia fuera del repositorio.

## Estructura

`models.dart`: protocolo y validación. `device_api.dart`: HTTP con timeout, sin redirecciones ni reintentos de órdenes. `controller.dart`: estado, aislamiento de dispositivos, persistencia y sondeo. `app_store.dart`: almacenamiento protegido. `screens.dart` y `editors.dart`: widgets nativos. `light_visuals.dart`: esfera y efectos dibujados por Flutter.

## Comprobaciones y límites

Consulta [AUDIT.md](AUDIT.md). Las pruebas usan el motor de Flutter y servidores HTTP locales/simulados. No sustituyen una prueba en tu teléfono con la tira y un broker real.

Referencias oficiales: [Flutter](https://docs.flutter.dev/), [almacenamiento protegido](https://pub.dev/packages/flutter_secure_storage), [Android: seguridad de red](https://developer.android.com/privacy-and-security/security-config).
