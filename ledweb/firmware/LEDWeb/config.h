#pragma once

// Ajusta este GPIO al pin libre real de tu placa (numero GPIO, no numero fisico).
// GPIO4 es solo el valor inicial: comprueba el esquema de tu placa.
#define LED_DATA_PIN 4
#define DEFAULT_LED_COUNT 320
#define MAX_LED_COUNT 1600

// Credenciales de la pagina web y del punto de acceso inicial.
// Cambialas ANTES de cargar el firmware. Minimo 8 caracteres en AP_PASSWORD.
#define WEB_USER "admin"
#define WEB_PASSWORD "tiraesp32"
#define AP_PASSWORD "tiraesp32"

// Opcional: valores de red iniciales; despues pueden cambiarse desde la web.
#define INITIAL_WIFI_SSID ""
#define INITIAL_WIFI_PASSWORD ""

// Archivo local opcional, excluido de Git, para sobrescribir estos valores.
#if __has_include("config.local.h")
#include "config.local.h"
#endif
