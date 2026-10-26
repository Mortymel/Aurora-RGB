# Arquitectura — 0.8.0

`App Android → BLE cifrado → ESP32 → WiFi de 2,4 GHz → HTTP local → control LED`

- `lib/add_device_wizard.dart`: interfaz del alta BLE, formulario, errores, cancelación y confirmación.
- `lib/ble_provisioning.dart`: permisos por SDK, escaneo por servicio, emparejamiento, escritura fragmentada y consulta de estado.
- `lib/provisioning_protocol.dart`: contrato, límites y validación de la respuesta; sin guardar la contraseña en el modelo persistente.
- `lib/lan_device_wizard.dart`: alternativa para placas ya conectadas al WiFi, con mDNS o entrada manual.
- `lib/main.dart`: controladores, estado, escenas y temporizador local ligado a su controlador original.
- `firmware/src/provisioning.h`: GATT y máquina de estados no bloqueante; cola entre callback BLE y bucle principal. Los cambios WiFi, FastLED y NVS se realizan en el bucle principal.
- `firmware/src/provisioning_validation.h`: validación y ensamblado de bytes compartidos con pruebas C++ de escritorio.
- `firmware/src/main.cpp`: HTTP, FastLED, efectos, persistencia y MQTT opcional existente.

La placa solo guarda la configuración nueva después de obtener conexión. Una entrada NVS agrupa SSID, contraseña, nombre y píxeles; futuras modificaciones de longitud sincronizan esa entrada. El resto del estado LED permanece en preferencias. Identidad basada en los 48 bits de la MAC, no únicamente en un prefijo compartido.

Las preferencias del teléfono contienen identidad, IP, nombre y píxeles; nunca la contraseña del WiFi. La IP es la asignada por DHCP: si cambia, se requiere redescubrimiento por WiFi o edición. No existe conexión a nube.

El temporizador se ejecuta en el teléfono: no sobrevive al cierre del proceso ni debe interpretarse como horario persistente de firmware. El modo música, segmentos y OTA no están implementados. La app no configura aún el broker MQTT.

Las pruebas de widgets utilizan un transporte BLE sustituible para reproducir éxito, error y respuestas tardías. Estas pruebas no simulan radio, pila Bluetooth de Android, consumo real de RAM ni temporización física de la tira. Ver [auditoría](AUDITORIA.md).
