#include <Arduino.h>
#include <WiFi.h>
#include <WebServer.h>
#include <DNSServer.h>
#include <ESPmDNS.h>
#include <Preferences.h>
#include <PubSubClient.h>
#include <ArduinoJson.h>
#include <Adafruit_NeoPixel.h>
#include <time.h>
#include <math.h>
#include <sys/time.h>
#include <driver/gpio.h>
#include "config.h"
#include "web_ui.h"
#include "aurora_ui.h"

const char *EFFECTS[] = {"Color fijo", "Arcoiris", "Barrido arcoiris", "Respiracion",
  "Cometa", "Teatro", "Confeti", "Destellos", "Fuego", "Oceano", "Aurora",
  "Escaner", "Degradado", "Onda de color", "Estrobo", "Atardecer", "Sakura",
  "Bosque", "Lava", "Mar profundo", "Plasma", "Galaxia", "Luciernagas",
  "Lluvia arcoiris", "Meteoros", "Chispas doradas", "Luces navidenas", "Caramelos",
  "Amanecer", "Olas neon", "Doble cometa", "Gradiente vivo"};
constexpr uint8_t EFFECT_COUNT = sizeof(EFFECTS) / sizeof(EFFECTS[0]);
struct Schedule { bool enabled=false, on=true; uint16_t minute=1200; uint8_t days=127; };
struct Settings {
  String ssid=INITIAL_WIFI_SSID, pass=INITIAL_WIFI_PASSWORD;
  String host="", user="", mqttPass="";
  uint16_t port=1883, count=DEFAULT_LED_COUNT;
  uint8_t pin=LED_DATA_PIN;
  int16_t utcOffset=-240;
  bool grb=true, reverse=false, restore=false;
  uint8_t maxBrightness=255;
  uint16_t transition=400;
  Schedule schedules[4];
} cfg;
struct LightState {
  bool on=false;
  uint8_t brightness=32, effect=0, speed=45, r=255, g=120, b=35;
} light;
WebServer server(80);
DNSServer dns;
Preferences prefs;
WiFiClient net;
PubSubClient mqtt(net);
Adafruit_NeoPixel pixels(DEFAULT_LED_COUNT, LED_DATA_PIN, NEO_GRB + NEO_KHZ800);
String deviceId, topic, apName, hostName;
bool apActive=false, dirty=false, publishPending=true, networkPending=false;
uint32_t saveAt=0, networkAt=0, lastWifi=0, lastMqtt=0, lastFrame=0;
uint32_t countdownStartedAt=0, timerDuration=0;
bool timerOn=false;
int64_t lastScheduleMinute=-1;
double phase=0;
float displayedBrightness=0;
uint32_t frame[MAX_LED_COUNT];

bool usablePin(int pin) {
  if(pin<0 || pin>=GPIO_NUM_MAX || !GPIO_IS_VALID_OUTPUT_GPIO(pin)) return false;
  // Reservas habituales de flash, USB nativo y consola serie.
#if CONFIG_IDF_TARGET_ESP32
  if((pin>=6 && pin<=11) || pin==1 || pin==3 || pin==16 || pin==17) return false;
#elif CONFIG_IDF_TARGET_ESP32C6
  if(pin==12 || pin==13 || pin>=24 || pin==16 || pin==17) return false;
#elif CONFIG_IDF_TARGET_ESP32C3
  if((pin>=12 && pin<=19) || pin==20 || pin==21) return false;
#elif CONFIG_IDF_TARGET_ESP32S3
  if((pin>=26 && pin<=37) || pin==19 || pin==20 || pin==43 || pin==44) return false;
#elif CONFIG_IDF_TARGET_ESP32S2
  if((pin>=26 && pin<=32) || pin==19 || pin==20 || pin==43 || pin==44) return false;
#endif
  return true;
}

bool parseTime(const String &s, uint16_t &out) {
  if(s.length()!=5 || s[2]!=':' || !isDigit(s[0]) || !isDigit(s[1]) ||
      !isDigit(s[3]) || !isDigit(s[4])) return false;
  int h=s.substring(0,2).toInt(), m=s.substring(3).toInt();
  if(h>23 || m>59) return false;
  out=h*60+m; return true;
}
String timeText(uint16_t minute) {
  minute%=1440; char b[8]; snprintf(b,sizeof(b),"%02u:%02u",unsigned(minute/60),unsigned(minute%60)); return b;
}
void changed() { dirty=true; saveAt=millis(); publishPending=true; }
void settingsJson(JsonDocument &doc, bool secrets) {
  doc["ssid"]=cfg.ssid; doc["mqtt_host"]=cfg.host; doc["mqtt_port"]=cfg.port;
  doc["mqtt_user"]=cfg.user; doc["count"]=cfg.count; doc["grb"]=cfg.grb; doc["gpio"]=cfg.pin;
  doc["utc_offset"]=cfg.utcOffset;
  doc["reverse"]=cfg.reverse; doc["restore"]=cfg.restore; doc["max_brightness"]=cfg.maxBrightness; doc["transition_ms"]=cfg.transition;
  if(secrets) { doc["wifi_password"]=cfg.pass; doc["mqtt_password"]=cfg.mqttPass; }
  else { doc["wifi_password_set"]=cfg.pass.length()>0; doc["mqtt_password_set"]=cfg.mqttPass.length()>0; }
  JsonArray rows=doc["schedules"].to<JsonArray>();
  for(auto &s:cfg.schedules) {
    JsonObject o=rows.add<JsonObject>(); o["enabled"]=s.enabled; o["on"]=s.on;
    o["time"]=timeText(s.minute); o["days"]=s.days;
  }
}
void saveSettings() {
  JsonDocument d; settingsJson(d,true); String text; serializeJson(d,text);
  prefs.putString("config",text);
}
void loadSettings() {
  JsonDocument d;
  if(!deserializeJson(d,prefs.getString("config","{}"))) {
    cfg.ssid=d["ssid"] | cfg.ssid; cfg.pass=d["wifi_password"] | cfg.pass;
    cfg.host=d["mqtt_host"] | cfg.host; cfg.user=d["mqtt_user"] | cfg.user;
    cfg.mqttPass=d["mqtt_password"] | cfg.mqttPass;
    cfg.port=constrain(d["mqtt_port"] | 1883,1,65535);
    cfg.count=constrain(d["count"] | DEFAULT_LED_COUNT,1,MAX_LED_COUNT);
    int pin=d["gpio"] | LED_DATA_PIN; cfg.pin=usablePin(pin)?pin:LED_DATA_PIN;
    cfg.grb=d["grb"] | true; cfg.utcOffset=constrain(d["utc_offset"] | -240,-720,840);
    cfg.reverse=d["reverse"] | false; cfg.restore=d["restore"] | false;
    cfg.maxBrightness=constrain(d["max_brightness"] | 255,1,255); cfg.transition=constrain(d["transition_ms"] | 400,0,5000);
    JsonArray a=d["schedules"].as<JsonArray>();
    for(size_t i=0;i<a.size() && i<4;i++) {
      cfg.schedules[i].enabled=a[i]["enabled"] | false;
      cfg.schedules[i].on=a[i]["on"] | true;
      cfg.schedules[i].days=(a[i]["days"] | 127)&127;
      parseTime(a[i]["time"] | "20:00",cfg.schedules[i].minute);
    }
  }
  JsonDocument s;
  if(!deserializeJson(s,prefs.getString("light","{}"))) {
    light.brightness=constrain(s["brightness"] | 32,0,255);
    light.effect=constrain(s["effect"] | 0,0,EFFECT_COUNT-1);
    light.speed=constrain(s["speed"] | 45,1,100);
    light.on=cfg.restore && (s["on"] | false);
    light.r=constrain(s["r"] | 255,0,255); light.g=constrain(s["g"] | 120,0,255);
    light.b=constrain(s["b"] | 35,0,255);
  }
  // Arranque apagado: evita encendidos inesperados tras un corte de energia.
}
void saveLight() {
  JsonDocument d; d["on"]=light.on; d["brightness"]=light.brightness; d["effect"]=light.effect;
  d["speed"]=light.speed; d["r"]=light.r; d["g"]=light.g; d["b"]=light.b;
  String text; serializeJson(d,text); prefs.putString("light",text); dirty=false;
}
void setPower(bool on) { light.on=on; changed(); }
bool applyLight(JsonVariantConst d, String &error) {
  if(!d.is<JsonObjectConst>()) { error="Se espera un objeto JSON"; return false; }
  // Validate the complete command before mutating state (HTTP and MQTT).
  for(const char *key : {"brightness", "speed"}) {
    if(!d[key].isNull() && (!d[key].is<int>() || d[key].as<int>()<(String(key)=="speed"?1:0) || d[key].as<int>()>(String(key)=="speed"?100:255))) {
      error="Brillo o velocidad fuera de rango"; return false;
    }
  }
  if(!d["color"].isNull()) {
    if(!d["color"].is<JsonObjectConst>()) { error="Color invalido"; return false; }
    for(const char *key : {"r", "g", "b"}) {
      if(!d["color"][key].isNull() && (!d["color"][key].is<int>() || d["color"][key].as<int>()<0 || d["color"][key].as<int>()>255)) {
        error="Canal RGB fuera de rango"; return false;
      }
    }
  }
  int effect=light.effect;
  if(!d["effect"].isNull()) {
    effect=-1;
    if(d["effect"].is<const char*>()) {
      for(int i=0;i<EFFECT_COUNT;i++) if(String(EFFECTS[i])==d["effect"].as<String>()) effect=i;
    } else if(d["effect"].is<int>()) effect=d["effect"].as<int>();
    if(effect<0 || effect>=EFFECT_COUNT) { error="Efecto desconocido"; return false; }
  }
  if(!d["state"].isNull() && d["state"]!="ON" && d["state"]!="OFF") {
    error="state debe ser ON u OFF"; return false;
  }
  if(!d["state"].isNull()) light.on=d["state"]=="ON";
  if(!d["brightness"].isNull()) light.brightness=constrain(d["brightness"].as<int>(),0,255);
  if(!d["speed"].isNull()) light.speed=constrain(d["speed"].as<int>(),1,100);
  if(d["color"].is<JsonObjectConst>()) {
    if(!d["color"]["r"].isNull()) light.r=constrain(d["color"]["r"].as<int>(),0,255);
    if(!d["color"]["g"].isNull()) light.g=constrain(d["color"]["g"].as<int>(),0,255);
    if(!d["color"]["b"].isNull()) light.b=constrain(d["color"]["b"].as<int>(),0,255);
  }
  if(light.effect!=effect) { phase=0; pixels.clear(); memset(frame,0,sizeof(frame)); }
  light.effect=effect; changed(); return true;
}
void lightJson(JsonDocument &d) {
  d["state"]=light.on?"ON":"OFF"; d["brightness"]=light.brightness;
  d["color_mode"]="rgb";
  d["color"]["r"]=light.r; d["color"]["g"]=light.g; d["color"]["b"]=light.b;
  d["effect"]=EFFECTS[light.effect]; d["speed"]=light.speed;
}
void publishState() {
  if(!mqtt.connected()) return;
  JsonDocument d; lightJson(d); String text; serializeJson(d,text);
  if(mqtt.publish((topic+"/state").c_str(),text.c_str(),true)) publishPending=false;
}
void discovery() {
  JsonDocument d;
  d["name"]="Tira LED"; d["unique_id"]=deviceId+"_light"; d["schema"]="json";
  d["command_topic"]=topic+"/set"; d["state_topic"]=topic+"/state";
  d["availability_topic"]=topic+"/availability";
  d["brightness"]=true; d["brightness_scale"]=255; d["effect"]=true;
  d["supported_color_modes"].to<JsonArray>().add("rgb");
  JsonArray effects=d["effect_list"].to<JsonArray>(); for(auto e:EFFECTS) effects.add(e);
  d["device"]["identifiers"].to<JsonArray>().add(deviceId);
  d["device"]["name"]="Controlador LED "+deviceId;
  d["device"]["manufacturer"]="DIY"; d["device"]["model"]="ESP32 LEDWeb";
  d["device"]["sw_version"]="1.3.0";
  if(WiFi.status()==WL_CONNECTED) d["device"]["configuration_url"]="http://"+WiFi.localIP().toString();
  String text; serializeJson(d,text);
  mqtt.publish(("homeassistant/light/"+deviceId+"/config").c_str(),text.c_str(),true);
}
void mqttMessage(char *incoming, byte *payload, unsigned int length) {
  String t(incoming);
  if(t=="homeassistant/status") {
    if(length==6 && memcmp(payload,"online",6)==0) { discovery(); publishPending=true; }
    return;
  }
  if(t!=topic+"/set" || length>2048) return;
  JsonDocument d; if(deserializeJson(d,payload,length)) return;
  String error; applyLight(d.as<JsonVariantConst>(),error);
}
void startAP() {
  if(apActive) return;
  WiFi.softAP(apName.c_str(),AP_PASSWORD);
  dns.start(53,"*",WiFi.softAPIP()); apActive=true;
  Serial.printf("\nAP: %s | Clave: %s | http://192.168.4.1\n",apName.c_str(),AP_PASSWORD);
}
void configureNetwork() {
  if(mqtt.connected()) {
    mqtt.publish((topic+"/availability").c_str(),"offline",true); mqtt.disconnect();
  }
  net.stop(); mqtt.setServer(cfg.host.c_str(),cfg.port); lastMqtt=millis()-15000;
  configTime(cfg.utcOffset*60,0,"pool.ntp.org","time.cloudflare.com");
  if(cfg.ssid.length()) { WiFi.disconnect(); WiFi.begin(cfg.ssid.c_str(),cfg.pass.c_str()); }
  else { WiFi.disconnect(); startAP(); }
  lastWifi=millis(); networkPending=false;
}
bool authorized() {
  if(server.authenticate(WEB_USER,WEB_PASSWORD)) return true;
  server.requestAuthentication(); return false;
}
void sendJson(JsonDocument &d, int status=200) {
  String text; serializeJson(d,text); server.sendHeader("Cache-Control","no-store");
  server.send(status,"application/json; charset=utf-8",text);
}
void fail(const String &message,int status=400) {
  JsonDocument d; d["error"]=message; sendJson(d,status);
}
bool readBody(JsonDocument &d) {
  if(!server.header("Content-Type").startsWith("application/json")) { fail("Se requiere application/json",415); return false; }
  if(server.arg("plain").length()>8192) { fail("Peticion demasiado grande",413); return false; }
  if(deserializeJson(d,server.arg("plain")) || !d.is<JsonObject>()) { fail("JSON invalido"); return false; }
  return true;
}
void setupWeb() {
  const char *headers[]={"Content-Type"}; server.collectHeaders(headers,1);
  auto aurora=[](){
    if(!authorized()) return;
    server.sendHeader("Content-Encoding","gzip");
    server.sendHeader("Cache-Control","no-store");
    server.sendHeader("X-Content-Type-Options","nosniff");
    server.sendHeader("X-Frame-Options","DENY");
    server.send_P(200,"text/html; charset=utf-8",reinterpret_cast<const char*>(AURORA_UI),sizeof(AURORA_UI));
  };
  server.on("/",HTTP_GET,aurora);
  server.on("/aurora",HTTP_GET,aurora);
  server.on("/classic",HTTP_GET,[](){ if(authorized()) server.send_P(200,"text/html; charset=utf-8",WEB_UI); });
  server.on("/api/state",HTTP_GET,[](){
    if(!authorized()) return;
    JsonDocument d; lightJson(d); d["id"]=deviceId; d["count"]=cfg.count;
    d["version"]="1.3.0"; d["rssi"]=WiFi.RSSI(); d["uptime"]=millis()/1000; d["free_heap"]=ESP.getFreeHeap(); d["hostname"]=hostName;
    d["ip"]=WiFi.status()==WL_CONNECTED?WiFi.localIP().toString():WiFi.softAPIP().toString();
    d["wifi"]=WiFi.status()==WL_CONNECTED; d["mqtt"]=mqtt.connected(); d["ap"]=apActive;
    time_t now=time(nullptr); d["clock_valid"]=now>1700000000;
    if(now>1700000000) { struct tm t; localtime_r(&now,&t); char text[32]; strftime(text,sizeof(text),"%Y-%m-%d %H:%M:%S",&t); d["clock"]=text; }
    d["timer_remaining"]=timerDuration?(timerDuration-min(timerDuration,uint32_t(millis()-countdownStartedAt)))/1000:0;
    JsonArray a=d["effects"].to<JsonArray>(); for(auto e:EFFECTS) a.add(e); sendJson(d);
  });
  server.on("/api/light",HTTP_POST,[](){
    if(!authorized()) return; JsonDocument d; if(!readBody(d)) return;
    String error; if(!applyLight(d.as<JsonVariantConst>(),error)) { fail(error); return; }
    JsonDocument out; lightJson(out); sendJson(out);
  });
  server.on("/api/config",HTTP_GET,[](){
    if(!authorized()) return; JsonDocument d; settingsJson(d,false); d["max_count"]=MAX_LED_COUNT;
    d["chip"]=ESP.getChipModel();
    JsonArray pins=d["available_pins"].to<JsonArray>();
    for(int pin=0;pin<49;pin++) if(usablePin(pin)) pins.add(pin);
    sendJson(d);
  });
  server.on("/api/config",HTTP_POST,[](){
    if(!authorized()) return; JsonDocument d; if(!readBody(d)) return;
    // Validar toda la peticion antes de modificar la configuracion.
    if(d["count"].isNull() || !d["count"].is<int>() || d["count"].as<int>()<1 || d["count"].as<int>()>MAX_LED_COUNT) { fail("Cantidad de pixeles fuera de rango"); return; }
    if(!d["gpio"].is<int>() || !usablePin(d["gpio"].as<int>())) { fail("GPIO reservado o no valido como salida"); return; }
    if(!d["mqtt_port"].is<int>() || d["mqtt_port"].as<int>()<1 || d["mqtt_port"].as<int>()>65535) { fail("Puerto MQTT invalido"); return; }
    if(!d["utc_offset"].is<int>() || d["utc_offset"].as<int>()< -720 || d["utc_offset"].as<int>()>840) { fail("Zona horaria invalida"); return; }
    if(d["ssid"].as<String>().length()>32 || d["wifi_password"].as<String>().length()>63 || d["mqtt_host"].as<String>().length()>128 || d["mqtt_user"].as<String>().length()>128 || d["mqtt_password"].as<String>().length()>128) { fail("Campo demasiado largo"); return; }
    JsonArray rows=d["schedules"].as<JsonArray>();
    if(rows.size()!=4) { fail("Se requieren cuatro horarios"); return; }
    uint16_t times[4];
    for(int i=0;i<4;i++) {
      if(!parseTime(rows[i]["time"] | "",times[i]) || !rows[i]["days"].is<int>() || rows[i]["days"].as<int>()<1 || rows[i]["days"].as<int>()>127) { fail("Horario o dias invalidos"); return; }
    }
    for(int i=0;i<4;i++) for(int j=i+1;j<4;j++) {
      if((rows[i]["enabled"] | false) && (rows[j]["enabled"] | false) && times[i]==times[j] && (rows[i]["days"].as<int>() & rows[j]["days"].as<int>()) && (rows[i]["on"] | true)!=(rows[j]["on"] | true)) { fail("Horarios contradictorios: misma hora y dia con acciones opuestas"); return; }
    }
    if((!d["max_brightness"].isNull() && (!d["max_brightness"].is<int>() || d["max_brightness"].as<int>()<1 || d["max_brightness"].as<int>()>255)) || (!d["transition_ms"].isNull() && (!d["transition_ms"].is<int>() || d["transition_ms"].as<int>()<0 || d["transition_ms"].as<int>()>5000))) { fail("Limite de brillo o transicion invalidos"); return; }
    cfg.reverse=d["reverse"] | cfg.reverse; cfg.restore=d["restore"] | cfg.restore;
    cfg.maxBrightness=d["max_brightness"] | cfg.maxBrightness; cfg.transition=d["transition_ms"] | cfg.transition;
    bool reconnect=cfg.ssid!=d["ssid"].as<String>() || cfg.host!=d["mqtt_host"].as<String>() || cfg.port!=d["mqtt_port"].as<int>() || cfg.user!=d["mqtt_user"].as<String>() || d["wifi_password"].as<String>().length() || d["mqtt_password"].as<String>().length() || (d["clear_wifi_password"] | false) || (d["clear_mqtt_password"] | false) || cfg.utcOffset!=d["utc_offset"].as<int>();
    cfg.count=d["count"]; cfg.pin=d["gpio"]; cfg.grb=d["grb"] | true; cfg.utcOffset=d["utc_offset"];
    cfg.ssid=d["ssid"].as<String>(); cfg.host=d["mqtt_host"].as<String>();
    cfg.user=d["mqtt_user"].as<String>(); cfg.port=d["mqtt_port"];
    if(d["clear_wifi_password"] | false) cfg.pass="";
    if(d["wifi_password"].as<String>().length()) cfg.pass=d["wifi_password"].as<String>();
    if(d["clear_mqtt_password"] | false) cfg.mqttPass="";
    if(d["mqtt_password"].as<String>().length()) cfg.mqttPass=d["mqtt_password"].as<String>();
    for(int i=0;i<4;i++) {
      cfg.schedules[i].enabled=rows[i]["enabled"] | false; cfg.schedules[i].on=rows[i]["on"] | true;
      cfg.schedules[i].minute=times[i]; cfg.schedules[i].days=rows[i]["days"];
    }
    pixels.clear(); pixels.show(); pixels.setPin(cfg.pin); pixels.updateType((cfg.grb?NEO_GRB:NEO_RGB)+NEO_KHZ800);
    pixels.updateLength(cfg.count); pixels.clear(); memset(frame,0,sizeof(frame)); phase=0;
    saveSettings();
    // No repetir un horario al editar dentro de su mismo minuto.
    if(reconnect) { networkPending=true; networkAt=millis(); startAP(); }
    JsonDocument out; out["ok"]=true; out["reconnecting"]=reconnect; sendJson(out);
  });
  server.on("/api/timer",HTTP_POST,[](){
    if(!authorized()) return; JsonDocument d; if(!readBody(d)) return;
    if(!d["minutes"].is<int>() || d["minutes"].as<int>()<0 || d["minutes"].as<int>()>10080) { fail("Temporizador: 0 a 10080 minutos"); return; }
    timerDuration=d["minutes"].as<uint32_t>()*60000UL; countdownStartedAt=millis(); timerOn=d["on"] | false;
    JsonDocument out; out["ok"]=true; sendJson(out);
  });
  server.on("/api/clock",HTTP_POST,[](){
    if(!authorized()) return; JsonDocument d; if(!readBody(d)) return;
    int64_t epoch=d["epoch"] | int64_t(0);
    if(epoch<1700000000LL || epoch>4102444800LL) { fail("Fecha fuera de rango"); return; }
    timeval value={time_t(epoch),0}; settimeofday(&value,nullptr);
    JsonDocument out; out["ok"]=true; sendJson(out);
  });
  server.onNotFound([](){ if(authorized()) fail("Ruta no encontrada",404); });
  server.begin();
}

uint32_t rgb(uint8_t r,uint8_t g,uint8_t b) { return pixels.Color(r,g,b); }
uint32_t hsv(float hue,uint8_t sat=255,uint8_t value=255) {
  hue-=floorf(hue); return pixels.ColorHSV(uint16_t(hue*65535),sat,value);
}
uint32_t selected(float scale=1) { return rgb(light.r*scale,light.g*scale,light.b*scale); }
uint32_t blendColors(uint32_t a,uint32_t b,float t) {
  t=constrain(t,0.0f,1.0f);
  return rgb(((a>>16)&255)*(1-t)+((b>>16)&255)*t,
    ((a>>8)&255)*(1-t)+((b>>8)&255)*t,(a&255)*(1-t)+(b&255)*t);
}
uint32_t paletteColor(uint8_t palette,float position) {
  static const uint32_t palettes[][4]={
    {0x21004b,0xd81b68,0xff732b,0xffd09a}, // Atardecer
    {0x4d164f,0xd84f9f,0xffa6c6,0xffe8d7}, // Sakura
    {0x001c12,0x00683f,0x59b943,0xb5db5c}, // Bosque
    {0x150005,0x8a0613,0xff3e08,0xffc02a}, // Lava
    {0x01071e,0x042f6b,0x007eaa,0x5cebd8}, // Mar profundo
    {0x8b0010,0xe52b21,0xffe8ba,0x07824b}, // Navidad
    {0xff428d,0xffdce9,0x7ee8ee,0xf9f4ff}, // Caramelos
    {0x180e44,0x9d306e,0xff7d4d,0xffe8b0}  // Amanecer
  };
  float p=(position-floorf(position))*4; int index=int(p); float t=p-index;
  t=t*t*(3-2*t); // Interpolacion suave entre colores.
  return blendColors(palettes[palette][index],palettes[palette][(index+1)%4],t);
}
void fade(uint8_t amount) {
  for(int i=0;i<cfg.count;i++) {
    uint32_t c=pixels.getPixelColor(i);
    pixels.setPixelColor(i,rgb(((c>>16)&255)*amount/255,((c>>8)&255)*amount/255,(c&255)*amount/255));
  }
}
void render() {
  uint32_t now=millis(); if(uint32_t(now-lastFrame)<25) return;
  float dt=min(uint32_t(now-lastFrame),uint32_t(100))/1000.0f; lastFrame=now;
  float target=light.on?min(light.brightness,cfg.maxBrightness):0;
  if(cfg.transition==0) displayedBrightness=target;
  else { float step=255.0f*dt*1000/cfg.transition; displayedBrightness += constrain(target-displayedBrightness,-step,step); }
  uint8_t outputBrightness=min(int(roundf(displayedBrightness)),int(cfg.maxBrightness));
  if(outputBrightness==0) {
    pixels.clear(); memset(frame,0,sizeof(frame)); pixels.show(); return;
  }
  for(int i=0;i<cfg.count;i++) pixels.setPixelColor(i,frame[i]);
  phase+=dt*(0.08f+light.speed*0.025f);
  float p=phase-floor(phase), wave=(sinf(phase*2*PI)+1)*0.5f;
  int head=int(p*cfg.count);
  switch(light.effect) {
    case 0: pixels.fill(selected()); break;
    case 1: pixels.fill(hsv(p)); break;
    case 2: for(int i=0;i<cfg.count;i++) pixels.setPixelColor(i,hsv(float(i)/cfg.count+p)); break;
    case 3: pixels.fill(selected(0.03f+wave*0.97f)); break;
    case 4: {
      pixels.clear(); int tail=max(4,int(cfg.count/8));
      for(int j=0;j<tail;j++) pixels.setPixelColor((head-j+cfg.count)%cfg.count,selected(powf(1.0f-float(j)/tail,2))); break;
    }
    case 5: for(int i=0;i<cfg.count;i++) pixels.setPixelColor(i,(i+int(phase*8))%3==0?selected():0); break;
    case 6: fade(220); for(int j=0;j<max(1,int(cfg.count/80));j++) pixels.setPixelColor(random(cfg.count),hsv(random(65536)/65536.0f)); break;
    case 7: fade(180); for(int j=0;j<max(1,int(cfg.count/50));j++) pixels.setPixelColor(random(cfg.count),selected()); break;
    case 8: for(int i=0;i<cfg.count;i++) {
      float x=float(i)/cfg.count;
      float heat=0.5f+0.25f*sinf(x*24-phase*3)+0.15f*sinf(x*51+phase*2)+random(-3,4)*0.01f;
      heat=constrain(heat,0.0f,1.0f); pixels.setPixelColor(i,rgb(255*heat,170*heat*heat,20*heat*heat*heat));
    } break;
    case 9: for(int i=0;i<cfg.count;i++) {
      float w=(sinf(float(i)/cfg.count*4*PI+phase*2)+1)*0.5f;
      pixels.setPixelColor(i,hsv(0.48f+0.18f*w,230,50+205*w));
    } break;
    case 10: for(int i=0;i<cfg.count;i++) {
      float w=(sinf(float(i)/cfg.count*3*PI+phase)+1)*0.5f;
      pixels.setPixelColor(i,hsv(0.30f+0.48f*w,235,20+180*w));
    } break;
    case 11: {
      pixels.clear(); float pos=wave*(cfg.count-1); float width=max(2,int(cfg.count/20));
      for(int i=0;i<cfg.count;i++) pixels.setPixelColor(i,selected(max(0.0f,1-fabsf(i-pos)/width))); break;
    }
    case 12: for(int i=0;i<cfg.count;i++) pixels.setPixelColor(i,selected(0.1f+0.9f*float(i)/max(1,int(cfg.count-1)))); break;
    case 13: for(int i=0;i<cfg.count;i++) pixels.setPixelColor(i,selected(0.05f+0.95f*(sinf(float(i)*4*PI/cfg.count-phase*2*PI)+1)*0.5f)); break;
    case 14: pixels.fill((uint32_t(phase*4)%2)==0?selected():0); break;
    case 15: case 16: case 17: case 18: case 19:
      for(int i=0;i<cfg.count;i++) {
        float x=float(i)/cfg.count;
        float pos=x*0.7f+phase*0.045f+0.12f*sinf(x*2*PI-phase*0.6f);
        pixels.setPixelColor(i,paletteColor(light.effect-15,pos));
      } break;
    case 20: // Plasma: interferencia de dos ondas de color.
      for(int i=0;i<cfg.count;i++) {
        float x=float(i)/cfg.count;
        float v=(sinf(x*12+phase*1.8f)+sinf(x*21-phase*1.1f))*0.25f+0.5f;
        pixels.setPixelColor(i,hsv(v*0.8f+phase*0.04f,235,150+105*v));
      } break;
    case 21: // Nebulosa azul-violeta con estrellas que titilan suavemente.
      for(int i=0;i<cfg.count;i++) {
        float x=float(i)/cfg.count;
        uint32_t c=blendColors(0x08052b,0x4c126a,(sinf(x*15+phase*.4f)+1)*.5f);
        uint32_t hash=uint32_t(i)*2654435761UL;
        float star=powf((sinf(phase*1.6f+(hash%1000)*.01f)+1)*.5f,6);
        if(hash%19==0) c=blendColors(c,0xdceaff,star);
        pixels.setPixelColor(i,c);
      } break;
    case 22:
      for(int i=0;i<cfg.count;i++) {
        uint32_t sample=(i+uint32_t(phase*7))%cfg.count;
        uint32_t hash=sample*2654435761UL;
        float glow=powf((sinf(phase*1.7f+(hash%1000)*.01f)+1)*.5f,3);
        pixels.setPixelColor(i,hash%17==0?blendColors(0x000502,0xc5ff3b,glow):0x000201);
      } break;
    case 23: case 24:
      for(int i=0;i<cfg.count;i++) {
        float x=float(i)/cfg.count; uint32_t c=0;
        int streams=light.effect==23?7:3;
        for(int j=0;j<streams;j++) {
          float head=fmodf(phase*(.12f+j*.027f)+float(j)/streams,1.0f);
          float distance=fmodf(head-x+1.0f,1.0f);
          float glow=powf(max(0.0f,1-distance/(light.effect==23?.10f:.24f)),3);
          uint32_t streak=hsv(float(j)/streams+phase*.03f,light.effect==23?255:130);
          c=blendColors(c,streak,glow);
        }
        pixels.setPixelColor(i,c);
      } break;
    case 25:
      fade(235);
      for(int j=0;j<max(1,int(cfg.count/100));j++)
        if(random(3)==0) pixels.setPixelColor(random(cfg.count),rgb(255,random(100,220),random(5,45)));
      break;
    case 26: case 27:
      for(int i=0;i<cfg.count;i++) pixels.setPixelColor(i,paletteColor(light.effect==26?5:6,float(i)/cfg.count*3-phase*.08f));
      break;
    case 28:
      for(int i=0;i<cfg.count;i++) pixels.setPixelColor(i,paletteColor(7,float(i)/cfg.count*.3f+phase*.025f));
      break;
    case 29:
      for(int i=0;i<cfg.count;i++) {
        float x=float(i)/cfg.count;
        float v=powf((sinf(x*6*PI-phase*2)+1)*.5f,2);
        pixels.setPixelColor(i,hsv(x*.5f+phase*.06f,255,15+240*v));
      } break;
    case 30:
      for(int i=0;i<cfg.count;i++) {
        float x=float(i)/cfg.count;
        float a=powf(max(0.0f,1-fmodf(p-x+1.0f,1.0f)/.22f),3);
        float b=powf(max(0.0f,1-fmodf(1-p-x+1.0f,1.0f)/.22f),3);
        pixels.setPixelColor(i,blendColors(selected(a),rgb(light.b,light.r,light.g),b));
      } break;
    case 31:
      for(int i=0;i<cfg.count;i++) {
        float x=float(i)/cfg.count;
        float t=(sinf(x*2*PI-phase*.7f)+1)*.5f;
        pixels.setPixelColor(i,blendColors(hsv(phase*.025f),hsv(phase*.025f+.38f),t));
      } break;
  }
  // Conservar el fotograma sin escalar: evita perder precision en las estelas.
  for(int i=0;i<cfg.count;i++) {
    uint32_t c=pixels.getPixelColor(i); frame[i]=c;
    pixels.setPixelColor(i,rgb(((c>>16)&255)*outputBrightness/255,
      ((c>>8)&255)*outputBrightness/255,(c&255)*outputBrightness/255));
  }
  if(cfg.reverse) for(int i=0;i<cfg.count/2;i++) { uint32_t c=pixels.getPixelColor(i); pixels.setPixelColor(i,pixels.getPixelColor(cfg.count-1-i)); pixels.setPixelColor(cfg.count-1-i,c); }
  pixels.show();
}
void handleClock() {
  if(timerDuration && uint32_t(millis()-countdownStartedAt)>=timerDuration) { timerDuration=0; setPower(timerOn); }
  time_t now=time(nullptr); if(now<1700000000) return;
  int64_t minute=now/60; if(minute==lastScheduleMinute) return;
  lastScheduleMinute=minute; struct tm t; localtime_r(&now,&t);
  // Bit 0 lunes ... bit 6 domingo. Si coinciden, prevalece la ultima fila.
  int day=(t.tm_wday+6)%7;
  for(auto &s:cfg.schedules) if(s.enabled && (s.days&(1<<day)) && s.minute==t.tm_hour*60+t.tm_min) setPower(s.on);
}
void setup() {
  Serial.begin(115200); prefs.begin("ledweb",false); loadSettings();
  pixels.setPin(cfg.pin); pixels.updateType((cfg.grb?NEO_GRB:NEO_RGB)+NEO_KHZ800); pixels.updateLength(cfg.count);
  pixels.begin(); pixels.clear(); pixels.show();
  WiFi.mode(WIFI_AP_STA); WiFi.setSleep(false);
  String mac=WiFi.macAddress(); mac.replace(":",""); mac.toLowerCase();
  deviceId="ledweb_"+mac.substring(6); topic="ledweb/"+deviceId; apName="LEDWeb-"+mac.substring(8);
  hostName=deviceId; hostName.replace('_','-'); WiFi.setHostname(hostName.c_str());
  net.setConnectionTimeout(1000);
  mqtt.setBufferSize(4096); mqtt.setSocketTimeout(1); mqtt.setKeepAlive(30); mqtt.setCallback(mqttMessage);
  configureNetwork(); setupWeb(); MDNS.begin(hostName.c_str()); MDNS.addService("http","tcp",80); MDNS.addServiceTxt("http","tcp","app","aurora"); MDNS.addServiceTxt("http","tcp","version","1.3.0");
  Serial.printf("\nLEDWeb | GPIO %d | %u pixeles | usuario web %s\n",cfg.pin,cfg.count,WEB_USER);
}
void loop() {
  server.handleClient(); if(apActive) dns.processNextRequest();
  uint32_t now=millis();
  if(networkPending && uint32_t(now-networkAt)>750) configureNetwork();
  if(WiFi.status()!=WL_CONNECTED && uint32_t(now-lastWifi)>20000) {
    startAP(); lastWifi=now; if(cfg.ssid.length()) WiFi.reconnect();
  }
  static bool hadWifi=false;
  bool hasWifi=WiFi.status()==WL_CONNECTED;
  if(hasWifi && !hadWifi) Serial.printf("WiFi conectado: http://%s | http://%s.local\n",WiFi.localIP().toString().c_str(),hostName.c_str());
  hadWifi=hasWifi;
  if(hasWifi && cfg.host.length() && !networkPending && !mqtt.connected() && uint32_t(now-lastMqtt)>=15000) {
    lastMqtt=now;
    if(mqtt.connect(deviceId.c_str(),cfg.user.length()?cfg.user.c_str():nullptr,cfg.user.length()?cfg.mqttPass.c_str():nullptr,
      (topic+"/availability").c_str(),1,true,"offline")) {
      mqtt.subscribe((topic+"/set").c_str()); mqtt.subscribe("homeassistant/status");
      discovery(); mqtt.publish((topic+"/availability").c_str(),"online",true); publishPending=true;
    }
  }
  mqtt.loop(); if(publishPending) publishState();
  handleClock(); render();
  if(dirty && uint32_t(millis()-saveAt)>1500) saveLight();
  delay(1);
}
