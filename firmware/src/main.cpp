#include <Arduino.h>
#include <WiFi.h>
#include <ESPmDNS.h>
#include <WebServer.h>
#include <Preferences.h>
#include <FastLED.h>
#include <ArduinoJson.h>
#include <PubSubClient.h>

// Verify LED protocol, pixel grouping, data pin and power supply BEFORE connecting hardware.
// Target: ESP32-WROOM-32 + addressable RGB strips with WS2812B-compatible timing.
// Initial WS2812B timing and GRB color order; verify with RGB test before full brightness.
#ifndef LED_PIN
#define LED_PIN 5
#endif
#ifndef LED_COUNT
#define LED_COUNT 1
#endif
#ifndef LED_MAX_MILLIAMPS
#define LED_MAX_MILLIAMPS 3000
#endif
#ifndef LED_MAX_PIXELS
#define LED_MAX_PIXELS 1024
#endif
#define FW_VERSION "0.8.0"
#define API_VERSION 1

CRGB leds[LED_MAX_PIXELS];
uint16_t pixelCount=LED_COUNT;
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
  doc["pixels"] = pixelCount;
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
  prefs.putUShort("pixels",pixelCount);
  String blob = prefs.getString("setup", "");
  if (!blob.isEmpty()) {
    JsonDocument setup;
    if (!deserializeJson(setup, blob) && setup["pixels"].as<int>() != pixelCount) {
      setup["pixels"] = pixelCount;
      blob = ""; serializeJson(setup, blob); prefs.putString("setup", blob);
    }
  }
}
int effectIndex(const String &name) {
  for (int i=0;i<EFFECT_COUNT;i++) if (name.equalsIgnoreCase(effectNames[i])) return i;
  return -1;
}
bool applyControl(JsonVariantConst data) {
  // Validate before applying anything: never silently clamp a hardware setting.
  if (data.as<JsonObjectConst>().containsKey("pixels")) {
    if (!data["pixels"].is<int>() || data["pixels"].as<int>()<1 || data["pixels"].as<int>()>LED_MAX_PIXELS) return false;
    const uint16_t nextCount=data["pixels"].as<int>();
    if (nextCount!=pixelCount) {
      FastLED.clear(true); // Clear the previous length before shortening the strip.
      pixelCount=nextCount;
      FastLED[0].setLeds(leds,pixelCount);
    }
  }
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
  return true;
}
void handleControl() {
  JsonDocument doc;
  if (server.hasArg("plain") && server.header("Content-Type").startsWith("application/json")) {
    if (deserializeJson(doc,server.arg("plain"))) {respondJson("{\"error\":\"invalid_json\"}",400);return;}
  } else {
    for(int i=0;i<server.args();i++){
      String k=server.argName(i),v=server.arg(i);
      if(k=="power") doc[k]=(v=="true"||v=="1");
      else if(k=="pixels") {
        if(v.isEmpty()||v.length()>4){respondJson("{\"error\":\"invalid_pixels\",\"min\":1,\"max\":1024}",400);return;}
        for(unsigned int j=0;j<v.length();j++)if(v[j]<'0'||v[j]>'9'){respondJson("{\"error\":\"invalid_pixels\"}",400);return;}
        doc[k]=v.toInt();
      }
      else if(k=="color") doc[k]=(uint32_t)strtoul(v.c_str(),nullptr,0);
      else if(k=="brightness"||k=="effect"||k=="speed") doc[k]=v.toInt();
    }
  }
  if(!applyControl(doc.as<JsonVariantConst>())){respondJson("{\"error\":\"invalid_pixels\",\"min\":1,\"max\":1024}",400);return;}
  respondJson(jsonState());
}
void handleInfo() {
  JsonDocument doc;
  doc["device_id"]=deviceId;
  doc["name"]=deviceName;
  doc["firmware_version"]=FW_VERSION;
  doc["api_version"]=API_VERSION;
  doc["pixels"]=pixelCount;
  doc["max_pixels"]=LED_MAX_PIXELS;
  doc["led_protocol"]="WS2812B-compatible";
  doc["color_order"]="GRB";
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
#include "provisioning.h"

void render() {
  if(!powerOn||brightness==0){FastLED.clear();FastLED.show();return;}
  fill_solid(leds+pixelCount,LED_MAX_PIXELS-pixelCount,CRGB::Black);
  CRGB base((colorValue>>16)&255,(colorValue>>8)&255,colorValue&255);
  uint8_t t=phase&255;
  switch(effect){
    case 0: fill_solid(leds,pixelCount,base);break;
    case 1: fill_rainbow(leds,pixelCount,t,255/max(1,(int)pixelCount/4));break;
    case 2: fill_solid(leds,pixelCount,base);nscale8_video(leds,pixelCount,beatsin8(12,15,255));break;
    case 3: fadeToBlackBy(leds,pixelCount,55);leds[phase%pixelCount]=base;break;
    case 4: fadeToBlackBy(leds,pixelCount,38);if(random8()<95)leds[random16(pixelCount)]=base;break;
    case 5: for(int i=0;i<pixelCount;i++)leds[i]=HeatColor(qsub8(inoise8(i*27,phase*15),40));break;
    case 6: for(int i=0;i<pixelCount;i++)leds[i]=base;for(int i=0;i<pixelCount;i++)leds[i].nscale8_video(sin8(i*6+phase));break;
    case 7: fill_solid(leds,pixelCount,CRGB::Black);for(int i=0;i<pixelCount;i++)if(i<=phase%pixelCount)leds[i]=base;break;
    case 8: fill_solid(leds,pixelCount,base);nscale8_video(leds,pixelCount,quadwave8(t));break;
    case 9: fadeToBlackBy(leds,pixelCount,20);if(random8()<75)leds[random16(pixelCount)]=CHSV(random8(),200,255);break;
    case 10: fadeToBlackBy(leds,pixelCount,40);for(int j=0;j<8;j++)leds[(phase+j)%pixelCount]=base;break;
    case 11: fill_gradient_RGB(leds,pixelCount,base,CHSV(t,255,255));break;
  }
  FastLED.setBrightness(brightness);
  FastLED.show();
}
void setup() {
  Serial.begin(115200);
  pinMode(0, INPUT_PULLUP);
  prefs.begin("mortys-led",false);
  powerOn=prefs.getBool("power",true);
  brightness=prefs.getUChar("bright",128);
  speed=prefs.getUChar("speed",100);
  effect=constrain(prefs.getUChar("effect",0),0,EFFECT_COUNT-1);
  colorValue=prefs.getUInt("color",0x83D9BC);
  pixelCount=constrain(prefs.getUShort("pixels",LED_COUNT),1,LED_MAX_PIXELS);
  deviceId=String((uint32_t)(ESP.getEfuseMac()&0xFFFFFF),HEX);
  deviceName=prefs.getString("name","Morty's LED");
  JsonDocument setupDoc;
  String setupBlob = prefs.getString("setup", "");
  if (!setupBlob.isEmpty() && !deserializeJson(setupDoc, setupBlob)) {
    deviceName = setupDoc["name"].as<String>();
    pixelCount = constrain(setupDoc["pixels"].as<int>(), 1, LED_MAX_PIXELS);
  }
  mqttBase="mortys-led/"+deviceId;
  mqttHost=prefs.getString("mqtt_host","");
  mqttUser=prefs.getString("mqtt_user","");
  mqttPass=prefs.getString("mqtt_pass","");
  mqttPort=prefs.getUShort("mqtt_port",1883);
  FastLED.addLeds<WS2812B,LED_PIN,GRB>(leds,pixelCount);
  FastLED.setMaxPowerInVoltsAndMilliamps(5,LED_MAX_MILLIAMPS);
  FastLED.clear(true);
  WiFi.persistent(false); // Candidate credentials stay in RAM until our atomic NVS commit.
  WiFi.mode(WIFI_STA);
  String ssid=prefs.getString("ssid",""),pass=prefs.getString("pass","");
  if (!setupDoc.isNull()) { ssid = setupDoc["ssid"].as<String>(); pass = setupDoc["password"].as<String>(); }
  WiFi.setAutoReconnect(true);
  if (!ssid.isEmpty()) {
    WiFi.begin(ssid.c_str(), pass.c_str());
    unsigned long started = millis();
    while (WiFi.status() != WL_CONNECTED && millis() - started < 12000) delay(100);
  }
  if (WiFi.status() == WL_CONNECTED) startMdns();
  else if (ssid.isEmpty()) startProvisioning();
  else Serial.println("WiFi unavailable. Hold BOOT 3 seconds to change network.");
  mqtt.setServer(mqttHost.c_str(),mqttPort);
  mqtt.setBufferSize(1536);
  mqtt.setCallback(mqttMessage);
  server.on("/api/state",HTTP_GET,[]{respondJson(jsonState());});
  server.on("/api/control",HTTP_POST,handleControl);
  server.on("/api/info",HTTP_GET,handleInfo);
  server.on("/api/effects",HTTP_GET,handleEffects);
  server.on("/api/health",HTTP_GET,[]{respondJson("{\"ok\":true}");});
  server.begin();
  Serial.printf("Morty's LED %s | ID %s | IP %s\n",FW_VERSION,deviceId.c_str(),WiFi.localIP().toString().c_str());
}
void loop() {
  handleProvisioning();
  server.handleClient();
  mqttLoop();
  if(millis()-lastFrame >= (uint32_t)map(speed,1,255,85,12)){
    lastFrame=millis();phase++;render();
  }
}

