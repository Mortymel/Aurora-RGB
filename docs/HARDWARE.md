# Hardware y cableado

## Componentes previstos

| Elemento | Referencia |
| --- | --- |
| Microcontrolador | ESP32-WROOM-32 clásico |
| Tira | RGB direccionable compatible con WS2812B / GRB; sin marca obligatoria |
| Cantidad | 1–1024 píxeles por controlador, indicada al añadir o editar la ESP32 en Android |
| Consumo | Depende de la tira, cantidad y brillo; medir y consultar al fabricante |
| Fuente | Externa, con tensión y corriente adecuadas a la tira; binario actual preparado para 5 V |
| Adaptador lógico recomendado | 74AHCT125, de 3,3 V a 5 V |
| Micrófono opcional | INMP441 I²S, aún no integrado |

**Importante:** verificar protocolo, orden de color, tensión y corriente real. Cuenta píxeles/grupos direccionables, que pueden agrupar varios LED físicos. La cantidad se guarda en Android y en la ESP32. Otros protocolos, RGBW y tiras analógicas requieren un controlador distinto; no basta cambiar la cantidad.

## Conexión conceptual

```text
Fuente 5 V (+) ─────────────► +5V tira LED
Fuente GND ─────┬───────────► GND tira LED
                └───────────► GND ESP32
ESP32 GPIO ──► 74AHCT125 ──► DIN tira LED
                ↑ 5 V
```

El binario publicado utiliza GPIO 5 y orden GRB. El cableado debe coincidir; cambia y recompila el controlador si tu tira requiere otro protocolo u orden.

## Recomendaciones de seguridad

1. Alimentar la tira directamente desde una fuente de 5 V adecuada, **no** desde el pin 5 V o 3,3 V de la placa ESP32.
2. Compartir tierra entre ESP32, fuente, adaptador lógico y tira.
3. Verificar polaridad antes de encender. No conectar ni desconectar cables bajo tensión.
4. Colocar un fusible apropiado cerca de la salida de la fuente y usar conductores adecuados a la corriente.
5. Considerar inyección de alimentación en ambos extremos para reducir caída de tensión; comprobar diferencias de potencial antes de conectar.
6. Mantener cables de señal cortos; una resistencia serie en datos y un condensador de filtrado pueden mejorar robustez según la tira.
7. Proteger la fuente y las conexiones frente a cortocircuitos, humedad y calor. Si no tienes experiencia con alimentación de varios amperios, solicita revisión de un técnico.

## Micrófono INMP441 (futuro)

El INMP441 utiliza I²S (BCLK, WS, SD, alimentación y tierra). La asignación de pines y la configuración del canal deben documentarse cuando se implemente la captura de audio en firmware.
