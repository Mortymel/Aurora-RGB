# Hardware y cableado de Aurora

La tira de referencia del proyecto es RGB direccionable de 5 V, IC XGB1338 similar a WS2812B, 160 píxeles/m y consumo publicado máximo de 8 W/m. La compatibilidad física del IC y la señal debe comprobarse en la tira real.

```text
ESP32 GPIO elegido ---------- DIN de la tira
ESP32 GND --------+---------- GND de la tira
Fuente GND -------+
Fuente +5 V ---------------- VCC de la tira
```

Conecta por DIN siguiendo las flechas. Usa datos cortos y GND común. La tira se alimenta desde la fuente; su corriente no debe circular por la placa. Nunca conectes 5 V a un GPIO ni a 3V3.

Para dos metros: 16 W / 5 V = 3,2 A de consumo máximo publicado. Dimensiona fuente y cables con margen y comprueba caída de tensión al aumentar brillo. El límite de brillo no sustituye una instalación eléctrica adecuada.

GPIO4 es un valor inicial, no una garantía para todas las placas. El firmware filtra varias reservas de flash, USB y consola, pero no conoce todos los periféricos de cada fabricante. D4 no siempre es GPIO4. Comprueba el esquema de tu modelo.

Los binarios publicados son para ESP32-C6 y ESP32 clásico/WROOM genéricos de 4 MB. C3/S2/S3 no tienen binarios verificados en esta entrega. La señal directa de 3,3 V puede funcionar o fallar según la tira y el cableado; no se ha validado físicamente ni se garantiza sin adaptación de nivel.
