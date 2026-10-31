# Pruebas técnicas de Aurora 1.2.1 y LEDWeb 1.3.0

Esta lista corresponde a la app Android nativa. La demostración del chat no descubre ni controla una ESP32 real.

## Antes de instalar

- Usa el APK de Aurora 1.2.1 y firmware LEDWeb 1.3.0 de la familia correcta: ESP32-C6 o ESP32 clásico/WROOM. No intercambies sus binarios.
- Las imágenes fusionadas de prueba son para flash de 4 MB y dirección 0x0. La prueba de compilación no identifica la flash real de una placa desconocida.
- Para tu tira de 2 metros, comienza con 320 píxeles. GPIO4 es el valor inicial; comprueba que está disponible en tu placa.
- Alimenta la tira a 5 V y une GND de fuente, tira y ESP32. DIN recibe los datos. No alimentes los 2 metros a través del pin de la placa.

## Recorrido de instalación

1. Instala el firmware y arranca el ESP32. En una primera instalación sin red guardada, conéctate a su punto de acceso LEDWeb-…; las claves iniciales del firmware genérico son `tiraesp32` y el usuario HTTP es `admin`.
2. Abre Aurora, Mis luces y Añadir luz. La búsqueda comienza automáticamente. Si tu teléfono/router no permite el descubrimiento, usa Introducir IP manualmente y `192.168.4.1` desde el punto de acceso.
3. En el engranaje de esa luz, configura Wi-Fi. Vuelve a conectar el teléfono a esa misma red de 2,4 GHz. Si cambia la IP, búscala de nuevo o actualiza IP y acceso al controlador.
4. Selecciona la luz para controlarla. El engranaje configura solo esa ESP32; la pestaña Ajustes contiene las preferencias de la app.

## Comprobaciones con la placa

| Prueba | Resultado esperado |
|---|---|
| Abrir el selector superior y cerrarlo | Regresas a la misma luz y pestaña. |
| Engranaje → MQTT → flecha de regreso | Una sola ventana; regresas a la configuración de la misma tira. |
| Encender, apagar y cambiar brillo | Responde el ESP32 seleccionado. No aparece un aviso de éxito innecesario. |
| Colores rojo, verde, azul y blanco | Coinciden con la tira. Si rojo/verde se intercambian, revisa RGB/GRB en su engranaje. |
| Arrastrar la rueda y aplicar | La esfera refleja el RGB seleccionado. El modo Vista en vivo es optativo. |
| Abrir y recorrer los 32 efectos | El catálogo usa tarjetas estáticas y carga progresiva; comprueba fluidez en tu teléfono. |
| Añadir una segunda ESP32 y modificar su MQTT | La primera mantiene su configuración y sigue seleccionada al terminar de editar. |
| Cerrar y volver a abrir Aurora | Recupera los controladores y preferencias guardados. |
| Programar apagado dentro de 1 minuto y cerrar la app | El temporizador se ejecuta en el ESP32. |
| Horario próximo, reloj válido y día correcto | Se ejecuta en el ESP32 aunque la app esté cerrada. UTC es fijo. |
| Desconectar y reconectar el Wi-Fi | La app muestra el fallo y recupera el estado; no repite escrituras fallidas. |
| Reiniciar el ESP32 | Arranca apagado salvo que se activara recuperación. La cuenta atrás se pierde al reiniciar. |

## Home Assistant / MQTT

En el engranaje de cada luz, abre Home Assistant / MQTT. Si Mosquitto se ejecuta en Home Assistant, el servidor es la IP de ese equipo; el puerto del broker suele ser 1883, no 8123. Usa las credenciales del broker, no la clave Wi-Fi.

Con el broker y la integración MQTT de Home Assistant operativos, el firmware publica el descubrimiento y estado de esa ESP32. Comprueba encendido, brillo, color y efecto desde ambos lados. Apaga una ESP32 y comprueba disponibilidad sin afectar a la otra. El nombre de la luz en Aurora es local a la app; puedes nombrar la entidad por separado en Home Assistant.

## Evidencia y límites

Las pruebas automatizadas verifican HTTP, autenticación, errores, aislamiento de dispositivos y navegación con simuladores/servidores locales. Las compilaciones comprueban código y formato de los binarios. No se ha confirmado físicamente la tira XGB1338, la señal de datos de 3,3 V, el router, el broker ni el teléfono del usuario.

Registra modelo de placa, capacidad flash, GPIO, número de píxeles, teléfono/Android y resultados antes de considerar el conjunto validado en hardware.

## Si aparece JSON invalido al enviar órdenes

Aurora 1.2.1 corrige la longitud del cuerpo HTTP que requiere el ESP32. Instala el APK actualizado; no hace falta borrar la configuración ni volver a instalar LEDWeb 1.3.0 por este fallo. Repite encendido, apagado, brillo, efecto y temporizador.
