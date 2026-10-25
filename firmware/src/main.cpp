#include <Arduino.h>
#include <WiFi.h>
#include <WebServer.h>
#include <Preferences.h>
#include <FastLED.h>
#include <ArduinoJson.h>
#include <PubSubClient.h>

// Verify LED protocol, pixel grouping, data pin and power supply BEFORE connecting hardware.
// Target: classic ESP32-WROOM-32 with a WS2812-compatible 5 V data strip.
#ifndef LED_PIN
#define LED_PIN 5
#endif
#ifndef LED_COUNT
#define LED_COUNT 320
#endif
#ifndef LED_MAX_MILLIAMPS
#define LED_MAX_MILLIAMPS 3000
#endif
#define FW_VERSION "0.1.0-dev"
#define API_VERSION 1

CRGB leds[LED_COUNT];
WebServer server(80);
Preferences prefs;
WiFiClient wifiClient;
PubSubClient mqtt(wifiClient);
String deviceId, deviceName, mqttBase;
String mqttHost, mqttUser, mqttPass;
uint16_t mqttPort = 1883;
bool powerOn = true;
uint8_t brightness = 128, speed = 100, effect = 0;
uint32_t colorValue = 0x83D9BC;
uint32_t lastFrame = 0, lastMqttTry = 0, lastWifiTry = 0;
uint16_t phase = 0;
const char *effectNames[] = {"Fijo","Arcoiris","Respirar","Cometa","Chispas","Fuego","Olas","Barrido","Pulso","Confeti","Meteoros","Gradiente"};
constexpr uint8_t EFFECT_COUNT = sizeof(effectNames) / sizeof(effectNames[0]);

void writeState(JsonDocument &doc) {
  doc["power"] = powerOn;
  doc["brightness"] = brightness;
  doc["effect"] = effect;
  doc["speed"] = speed;
  doc["color"] = colorValue;
  doc["pixels"] = LED_COUNT;
  doc["audioLevel"] = 0;
  doc["wifi"] = WiFi.status() == WL_CONNECTED ? "connected" : "ap";
}
String jsonState() {
  JsonDocument doc;
  writeState(doc);
  String output; serializeJson(doc, output); return output;
}
void respondJson(const String &body, int code=200) {
  server.sendHeader("Cache-Control","no-store");
  server.send(code,"application/json",body);
}
void publishState() {
  if (!mqtt.connected()) return;
  JsonDocument doc;
  doc["state"] = powerOn ? "ON" : "OFF";
  doc["brightness"] = brightness;
  doc["color_mode"] = "rgb";
  JsonObject rgb = doc["color"].to<JsonObject>();
  rgb["r"] = (colorValue >> 16) & 255;
  rgb["g"] = (colorValue >> 8) & 255;
  rgb["b"] = colorValue & 255;
  doc["effect"] = effectNames[effect];
  String payload; serializeJson(doc,payload);
  mqtt.publish((mqttBase+"/state").c_str(),payload.c_str(),true);
}
void persist() {
  prefs.putBool("power",powerOn);
  prefs.putUChar("bright",brightness);
  prefs.putUChar("speed",speed);
  prefs.putUChar("effect",effect);
  prefs.putUInt("color",colorValue);
}
int effectIndex(const String &name) {
  for (int i=0;i<EFFECT_COUNT;i++) if (name.equalsIgnoreCase(effectNames[i])) return i;
  return -1;
}
void applyControl(JsonVariantConst data) {
  if (data["power"].is<bool>()) powerOn = data["power"].as<bool>();
  if (data["state"].is<const char*>()) powerOn = String(data["state"].as<const char*>()).equalsIgnoreCase("ON");
  if (data["brightness"].is<int>()) brightness = constrain(data["brightness"].as<int>(),0,255);
  if (data["speed"].is<int>()) speed = constrain(data["speed"].as<int>(),1,255);
  if (data["effect"].is<int>()) effect = constrain(data["effect"].as<int>(),0,EFFECT_COUNT-1);
  else if (data["effect"].is<const char*>()) {
    int id=effectIndex(data["effect"].as<String>());
    if(id>=0) effect=id;
  }
  if (data["color"].is<uint32_t>()) colorValue = data["color"].as<uint32_t>() & 0xFFFFFF;
  else if (data["color"].is<JsonObjectConst>()) {
    JsonObjectConst c=data["color"].as<JsonObjectConst>();
    colorValue=((uint32_t)constrain(c["r"].as<int>(),0,255)<<16) |
      ((uint32_t)constrain(c["g"].as<int>(),0,255)<<8) | constrain(c["b"].as<int>(),0,255);
  }
  persist();
  lastFrame=0;
  publishState();
}
void handleControl() {
  JsonDocument doc;
  if (server.hasArg("plain") && server.header("Content-Type").startsWith("application/json")) {
    if (deserializeJson(doc,server.arg("plain"))) {respondJson("{\"error\":\"invalid_json\"}",400);return;}
  } else {
    for(int i=0;i<server.args();i++){
      String k=server.argName(i),v=server.arg(i);
      if(k=="power") doc[k]=(v=="true"||v=="1");
      else if(k=="color") doc[k]=(uint32_t)strtoul(v.c_str(),nullptr,0);
      else if(k=="brightness"||k=="effect"||k=="speed") doc[k]=v.toInt();
    }
  }
  applyControl(doc.as<JsonVariantConst>());
  respondJson(jsonState());
}
void handleInfo() {
  JsonDocument doc;
  doc["device_id"]=deviceId;
  doc["name"]=deviceName;
  doc["firmware_version"]=FW_VERSION;
  doc["api_version"]=API_VERSION;
  doc["pixels"]=LED_COUNT;
  doc["ip"]=WiFi.localIP().toString();
  JsonArray caps=doc["capabilities"].to<JsonArray>();
  caps.add("power");caps.add("brightness");caps.add("rgb");caps.add("speed");caps.add("effects");caps.add("mqtt");
  String out;serializeJson(doc,out);respondJson(out);
}
void handleEffects() {
  JsonDocument doc;
  JsonArray arr=doc["effects"].to<JsonArray>();
  for(int i=0;i<EFFECT_COUNT;i++){JsonObject e=arr.add<JsonObject>();e["id"]=i;e["name"]=effectNames[i];}
  String out;serializeJson(doc,out);respondJson(out);
}
void handleSetup() {
  if (WiFi.getMode()!=WIFI_AP && WiFi.getMode()!=WIFI_AP_STA) {server.send(403,"text/plain","Setup only in AP mode");return;}
  String ssid=server.arg("ssid"),password=server.arg("password");
  if(ssid.isEmpty()||ssid.length()>32||password.length()>63){server.send(400,"text/plain","Invalid WiFi settings");return;}
  prefs.putString("ssid",ssid);prefs.putString("pass",password);
  server.send(200,"text/plain","Saved. Rebooting.");
  delay(300);ESP.restart();
}
void mqttMessage(char *topic,byte *payload,unsigned int length) {
  if(length>512)return;
  String raw;raw.reserve(length+1);
  for(unsigned int i=0;i<length;i++)raw+=(char)payload[i];
  JsonDocument doc;
  if(deserializeJson(doc,raw))return;
  applyControl(doc.as<JsonVariantConst>());
}
void publishDiscovery() {
  JsonDocument doc;
  doc["name"]=deviceName;
  doc["unique_id"]="mortys_led_"+deviceId;
  doc["schema"]="json";
  doc["command_topic"]=mqttBase+"/set";
  doc["state_topic"]=mqttBase+"/state";
  doc["availability_topic"]=mqttBase+"/availability";
  doc["brightness"]=true;
  doc["effect"]=true;
  doc["supported_color_modes"][0]="rgb";
  JsonArray list=doc["effect_list"].to<JsonArray>();
  for(const char *e:effectNames)list.add(e);
  JsonObject device=doc["device"].to<JsonObject>();
  device["identifiers"][0]="mortys_led_"+deviceId;
  device["name"]=deviceName;
  device["manufacturer"]="Morty's LED";
  device["model"]="ESP32-WROOM-32";
  device["sw_version"]=FW_VERSION;
  String payload;serializeJson(doc,payload);
  mqtt.publish(("homeassistant/light/mortys_led_"+deviceId+"/config").c_str(),payload.c_str(),true);
}
void mqttLoop() {
  if(WiFi.status()!=WL_CONNECTED||mqttHost.isEmpty())return;
  if(!mqtt.connected()){
    if(millis()-lastMqttTry<10000)return;
    lastMqttTry=millis();
    bool ok=mqtt.connect(("mortys-"+deviceId).c_str(),mqttUser.c_str(),mqttPass.c_str(),
      (mqttBase+"/availability").c_str(),0,true,"offline");
    if(ok){
      mqtt.publish((mqttBase+"/availability").c_str(),"online",true);
      mqtt.subscribe((mqttBase+"/set").c_str());
      publishDiscovery();publishState();
    }
  }else mqtt.loop();
}
void render() {
  if(!powerOn||brightness==0){FastLED.clear();FastLED.show();return;}
  CRGB base((colorValue>>16)&255,(colorValue>>8)&255,colorValue&255);
  uint8_t t=phase&255;
  switch(effect){
    case 0: fill_solid(leds,LED_COUNT,base);break;
    case 1: fill_rainbow(leds,LED_COUNT,t,255/max(1,LED_COUNT/4));break;
    case 2: fill_solid(leds,LED_COUNT,base);nscale8_video(leds,LED_COUNT,beatsin8(12,15,255));break;
    case 3: fadeToBlackBy(leds,LED_COUNT,55);leds[phase%LED_COUNT]=base;break;
    case 4: fadeToBlackBy(leds,LED_COUNT,38);if(random8()<95)leds[random16(LED_COUNT)]=base;break;
    case 5: for(int i=0;i<LED_COUNT;i++)leds[i]=HeatColor(qsub8(inoise8(i*27,phase*15),40));break;
    case 6: for(int i=0;i<LED_COUNT;i++)leds[i]=base;for(int i=0;i<LED_COUNT;i++)leds[i].nscale8_video(sin8(i*6+phase));break;
    case 7: fill_solid(leds,LED_COUNT,CRGB::Black);for(int i=0;i<LED_COUNT;i++)if(i<=phase%LED_COUNT)leds[i]=base;break;
    case 8: fill_solid(leds,LED_COUNT,base);nscale8_video(leds,LED_COUNT,quadwave8(t));break;
    case 9: fadeToBlackBy(leds,LED_COUNT,20);if(random8()<75)leds[random16(LED_COUNT)]=CHSV(random8(),200,255);break;
    case 10: fadeToBlackBy(leds,LED_COUNT,40);for(int j=0;j<8;j++)leds[(phase+j)%LED_COUNT]=base;break;
    case 11: fill_gradient_RGB(leds,LED_COUNT,base,CHSV(t,255,255));break;
  }
  FastLED.setBrightness(brightness);
  FastLED.show();
}
void setup() {
  Serial.begin(115200);
  prefs.begin("mortys-led",false);
  powerOn=prefs.getBool("power",true);
  brightness=prefs.getUChar("bright",128);
  speed=prefs.getUChar("speed",100);
  effect=constrain(prefs.getUChar("effect",0),0,EFFECT_COUNT-1);
  colorValue=prefs.getUInt("color",0x83D9BC);
  deviceId=String((uint32_t)(ESP.getEfuseMac()&0xFFFFFF),HEX);
  deviceName=prefs.getString("name","Morty's LED");
  mqttBase="mortys-led/"+deviceId;
  mqttHost=prefs.getString("mqtt_host","");
  mqttUser=prefs.getString("mqtt_user","");
  mqttPass=prefs.getString("mqtt_pass","");
  mqttPort=prefs.getUShort("mqtt_port",1883);
  FastLED.addLeds<WS2812B,LED_PIN,GRB>(leds,LED_COUNT);
  FastLED.setMaxPowerInVoltsAndMilliamps(5,LED_MAX_MILLIAMPS);
  FastLED.clear(true);
  WiFi.mode(WIFI_STA);
  String ssid=prefs.getString("ssid",""),pass=prefs.getString("pass","");
  if(!ssid.isEmpty()){WiFi.begin(ssid.c_str(),pass.c_str());unsigned long started=millis();while(WiFi.status()!=WL_CONNECTED&&millis()-started<12000)delay(100);}
  if(WiFi.status()!=WL_CONNECTED){WiFi.mode(WIFI_AP_STA);WiFi.softAP(("MortysLED-"+deviceId).c_str());}
  mqtt.setServer(mqttHost.c_str(),mqttPort);
  mqtt.setBufferSize(1536);
  mqtt.setCallback(mqttMessage);
  server.on("/api/state",HTTP_GET,[]{respondJson(jsonState());});
  server.on("/api/control",HTTP_POST,handleControl);
  server.on("/api/info",HTTP_GET,handleInfo);
  server.on("/api/effects",HTTP_GET,handleEffects);
  server.on("/api/health",HTTP_GET,[]{respondJson("{\"ok\":true}");});
  server.on("/setup",HTTP_GET,[]{
    server.send(200,"text/html","<meta name='viewport' content='width=device-width'><h2>Morty's LED</h2><p>WiFi inicial (solo en el punto de acceso del dispositivo)</p><form method='POST'><input name='ssid' placeholder='Nombre de red'><input type='password' name='password' placeholder='Contrasena'><button>Guardar</button></form>");
  });
  server.on("/setup",HTTP_POST,handleSetup);
  server.begin();
  Serial.printf("Morty's LED %s | ID %s | IP %s\n",FW_VERSION,deviceId.c_str(),WiFi.localIP().toString().c_str());
}
void loop() {
  server.handleClient();
  mqttLoop();
  if(millis()-lastFrame >= (uint32_t)map(speed,1,255,85,12)){
    lastFrame=millis();phase++;render();
  }
}
