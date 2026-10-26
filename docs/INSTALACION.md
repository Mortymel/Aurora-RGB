# Instalación — 0.8.0

1. Comprueba placa ESP32-WROOM-32, flash de 4 MB y tira compatible con WS2812B/GRB. Desconecta la tira durante el flasheo.
2. Abre https://mortymel.github.io/ESP32-RGB-Studio-/ desde Chrome o Edge de escritorio y conecta USB con un cable de datos. Instala firmware 0.8.0; si borras la flash se pierden los datos anteriores.
3. Descarga el artefacto Android APK de la ejecución exitosa para 0.8.0+9. Descomprime e instala `app-release.apk`.
4. Abre **Añadir tira → Buscar por Bluetooth**, selecciona `MortysLED-…` y completa WiFi de **2,4 GHz**, contraseña, nombre y cantidad de píxeles. Acepta el emparejamiento Bluetooth de Android.
5. Espera confirmación. La app añade la IP devuelta por la placa. Para controlarla, el teléfono debe estar en la misma red WiFi.

No necesitas escribir una IP para dar de alta una ESP32 nueva. **Ya está conectada al WiFi** permite recuperar una placa ya configurada mediante mDNS o entrada manual.

BOOT pulsado 3 segundos después del arranque reabre el modo Bluetooth durante 10 minutos. No hace falta borrar ni reflashear para cambiar de router. No mantengas BOOT mientras conectas la alimentación: ese gesto puede activar el cargador de arranque.

Solo una contraseña validada por conexión se guarda. Ante error se mantienen las credenciales anteriores. La app anterior y el firmware anterior no soportan el protocolo de alta 0.8.0: actualiza ambos.

El APK utiliza firma de desarrollo; si Android muestra conflicto de firma, puede ser necesario desinstalar la versión anterior. Esto borra controladores y escenas guardados en el teléfono. La ESP32 conserva su configuración y puede volver a añadirse por WiFi.

Consulta [Bluetooth](BLUETOOTH.md), [hardware](HARDWARE.md) y [auditoría](AUDITORIA.md) para límites y validación pendiente.
