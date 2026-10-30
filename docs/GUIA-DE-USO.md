# Guía de uso de Aurora 1.1.1

[Instalación](INSTALACION.md) · [Índice](README.md) · [Soluciones](SOLUCION-DE-PROBLEMAS.md)

## Antes de empezar

Para controlar una tira, instala LEDWeb 1.3 y conecta teléfono y placa a la misma red. Probar sin placa abre una demo: no controla hardware ni contacta un broker. Sus horarios se evalúan mientras la app está activa; los horarios reales los ejecuta la ESP32.

## Mi luz

El botón superior enciende/apaga el controlador seleccionado. Toca su nombre para cambiar de dispositivo o añadir otro.

Toca la esfera para abrir la rueda. Arrastra por el borde para elegir tono; hacia el centro reduce saturación hasta blanco. Los colores rápidos son atajos. Ajuste preciso contiene RGB y HEX. La opción Vista en vivo envía cambios a la tira con frecuencia limitada; desactívala si quieres preparar un color antes de aplicarlo. Aplicar color confirma Color fijo y enciende la luz. La esfera representa el color seleccionado y no mide el brillo físico.

Intensidad solicita brillo de 0 a 255 y Velocidad modifica el ritmo del efecto. Si la placa tiene un brillo máximo configurado, la salida física no superará ese límite. Deshacer recupera el estado confirmado anterior de la luz; no es un historial de cambios de otras apps.

Guardar este ambiente conserva efecto, RGB, brillo y velocidad en el teléfono (hasta 50). Quitar un controlador o desinstalar la app no borra la configuración de la ESP32, pero puede eliminar datos locales de la app.

## Efectos

Busca por nombre, usa categorías y marca la estrella para favoritos. Toca una tarjeta para aplicar. Las muestras son estáticas; no son una simulación ni una reproducción exacta de la tira. El catálogo carga las tarjetas conforme aparecen para reducir trabajo al desplazarse. Algunos efectos usan la paleta propia del efecto y otros el color elegido por ti.

Los ambientes guardados aparecen al abrir Favoritos. Tócalos para recuperarlos; la papelera elimina el ambiente del teléfono.

## Horarios y cuenta atrás

Sincroniza el reloj y elige el desfase UTC del lugar. Es fijo: si cambia el horario de verano debes ajustarlo manualmente. Hay cuatro reglas semanales; toca la hora para editar, elige encender/apagar, días y activa la regla. Lunes corresponde al primer día de la máscara. Las órdenes opuestas en el mismo minuto y días solapados se rechazan.

El horario de encendido usa el ambiente seleccionado, no una escena distinta por regla. Funciona con la app cerrada si la ESP32 está alimentada y tiene hora válida.

El temporizador es una sola acción dentro de 1–10080 minutos. Permite encender o apagar y se puede cancelar. No es una hora del día ni un horario repetitivo. Se pierde al reiniciar la placa.

## Ajustes

| Opción | Qué cambia |
|---|---|
| Mis controladores | Selección, alta manual y búsqueda en la LAN |
| IP y credenciales | Dirección/usuario/contraseña con los que el teléfono entra en la ESP32 |
| Tira y dispositivo | Nombre local, número de píxeles, GPIO de salida y RGB/GRB |
| Control y recuperación | Inversión de dirección, máximo de brillo, transición de encendido/apagado y recuperación tras un corte; necesita LEDWeb 1.3 |
| Wi-Fi | Red a la que se conecta la ESP32; puede cambiar su IP |
| Home Assistant / MQTT | Conexión de la ESP32 al broker |
| Diagnóstico | IP, versión, Wi-Fi, reloj, MQTT, memoria y tiempo encendida |
| Apariencia | Clara, oscura o según el sistema |

Contraseña configurada significa que la placa ya guarda una clave. Cambiar permite escribir otra; no editarla conserva la actual. Red abierta y MQTT sin autenticación son elecciones explícitas para redes/brokers que realmente los admiten.

La recuperación del estado tras un corte es opcional; inicialmente la placa arranca apagada. Los cambios de luz se persisten después de 1,5 s sin cambios: un corte inmediato puede recuperar un estado anterior. La transición suaviza encender/apagar, no todos los cambios de escena.

## Si algo falla

Comprueba el dispositivo seleccionado, alimentación, IP, misma LAN y credenciales. Usa Diagnóstico y la [tabla de soluciones](SOLUCION-DE-PROBLEMAS.md). Si Efectos iba lento, instala 1.1.1 o posterior; esta corrección no exige reflashear la placa. La firma del APK sigue siendo de prueba: consulta la guía antes de desinstalar para resolver un conflicto de firma.
