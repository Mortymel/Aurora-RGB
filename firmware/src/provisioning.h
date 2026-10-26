#pragma once
#include <BLEDevice.h>
#include <BLEServer.h>
#include <BLEUtils.h>
#include <BLESecurity.h>
#include "provisioning_validation.h"
#include <freertos/queue.h>
#include <freertos/semphr.h>

static const char* SETUP_SERVICE = "d973f2e0-b19e-11ee-a506-0242ac120002";
static const char* SETUP_CONFIG = "d973f2e1-b19e-11ee-a506-0242ac120002";
static const char* SETUP_STATUS = "d973f2e2-b19e-11ee-a506-0242ac120002";
constexpr uint32_t SETUP_WINDOW_MS = 600000;
struct SetupCommand { char json[513]; };
QueueHandle_t setupQueue = nullptr;
SemaphoreHandle_t setupRxMutex = nullptr;
ProvisioningLineBuffer setupRx;
BLEServer* setupServer = nullptr;
BLECharacteristic* setupStatus = nullptr;
volatile bool setupOpen = false, setupConnected = false, setupDisconnected = false;
bool setupConnecting = false, setupSucceeded = false, mdnsRunning = false;
uint32_t setupOpenedAt = 0, setupConnectAt = 0, setupSuccessAt = 0;
String setupRequest, candidateSsid, candidatePassword, candidateName;
int candidatePixels = 1;

void startMdns() {
  if (mdnsRunning) MDNS.end();
  mdnsRunning = MDNS.begin(("mortys-" + deviceId).c_str());
  if (mdnsRunning) {
    MDNS.addService("http", "tcp", 80);
    MDNS.addServiceTxt("http", "tcp", "app", "mortys-led");
    MDNS.addServiceTxt("http", "tcp", "id", deviceId.c_str());
  }
}
void setSetupStatus(const char* state, const char* error = "") {
  if (!setupStatus) return;
  JsonDocument doc;
  doc["version"] = 1; doc["state"] = state; doc["request_id"] = setupRequest;
  doc["device_id"] = deviceId;
  if (*error) doc["error"] = error;
  if (strcmp(state, "connected") == 0) {
    doc["ip"] = WiFi.localIP().toString(); doc["name"] = deviceName; doc["pixels"] = pixelCount;
  }
  String out; serializeJson(doc, out);
  setupStatus->setValue(out.c_str()); // Polling reads avoid notification MTU truncation.
}
class SetupSecurity : public BLESecurityCallbacks {
  uint32_t onPassKeyRequest() override { return 0; }
  void onPassKeyNotify(uint32_t) override {}
  bool onConfirmPIN(uint32_t) override { return false; }
  bool onSecurityRequest() override { return setupOpen; }
  void onAuthenticationComplete(esp_ble_auth_cmpl_t result) override {
    if (!result.success && setupServer) setupServer->disconnect(setupServer->getConnId());
  }
};
class SetupServerCallbacks : public BLEServerCallbacks {
  void onConnect(BLEServer*) override { setupConnected = true; }
  void onDisconnect(BLEServer*) override {
    setupConnected = false; setupDisconnected = true;
    if (xSemaphoreTake(setupRxMutex, pdMS_TO_TICKS(100)) == pdTRUE) {
      setupRx.reset(); xSemaphoreGive(setupRxMutex);
    }
  }
};
class SetupWriteCallbacks : public BLECharacteristicCallbacks {
  void onWrite(BLECharacteristic* characteristic) override {
    if (!setupOpen) return;
    std::string chunk = characteristic->getValue();
    if (xSemaphoreTake(setupRxMutex, pdMS_TO_TICKS(100)) != pdTRUE) return;
    if (chunk.size() == 1 && chunk[0] == '!') {
      setupRx.reset();
      xSemaphoreGive(setupRxMutex);
      characteristic->setValue("");
      return;
    }
    for (char c : chunk) {
      if (setupRx.push(c)) {
        SetupCommand command = {};
        memcpy(command.json, setupRx.data, strlen(setupRx.data) + 1);
        xQueueSend(setupQueue, &command, 0);
        memset(command.json, 0, sizeof(command.json));
      }
    }
    xSemaphoreGive(setupRxMutex);
    characteristic->setValue(""); // Do not retain credentials in the readable GATT value.
  }
};
void startProvisioning() {
  if (setupConnecting) return;
  if (!setupServer) {
    setupQueue = xQueueCreate(1, sizeof(SetupCommand));
    setupRxMutex = xSemaphoreCreateMutex();
    if (!setupQueue || !setupRxMutex) { Serial.println("BLE setup: insufficient memory"); return; }
    BLEDevice::init(("MortysLED-" + deviceId).c_str());
    BLEDevice::setEncryptionLevel(ESP_BLE_SEC_ENCRYPT);
    BLEDevice::setSecurityCallbacks(new SetupSecurity());
    BLESecurity* security = new BLESecurity();
    security->setAuthenticationMode(ESP_LE_AUTH_REQ_SC_BOND);
    security->setCapability(ESP_IO_CAP_NONE);
    security->setInitEncryptionKey(ESP_BLE_ENC_KEY_MASK | ESP_BLE_ID_KEY_MASK);
    security->setRespEncryptionKey(ESP_BLE_ENC_KEY_MASK | ESP_BLE_ID_KEY_MASK);
    setupServer = BLEDevice::createServer();
    setupServer->setCallbacks(new SetupServerCallbacks());
    BLEService* service = setupServer->createService(SETUP_SERVICE);
    BLECharacteristic* config = service->createCharacteristic(SETUP_CONFIG, BLECharacteristic::PROPERTY_WRITE);
    config->setAccessPermissions(ESP_GATT_PERM_WRITE_ENCRYPTED);
    config->setCallbacks(new SetupWriteCallbacks());
    setupStatus = service->createCharacteristic(SETUP_STATUS, BLECharacteristic::PROPERTY_READ);
    setupStatus->setAccessPermissions(ESP_GATT_PERM_READ_ENCRYPTED);
    service->start();
    BLEDevice::getAdvertising()->addServiceUUID(SETUP_SERVICE);
    BLEDevice::getAdvertising()->setScanResponse(true);
    BLEDevice::getAdvertising()->setMinPreferred(0x06);
    BLEDevice::getAdvertising()->setMinPreferred(0x12);
  }
  xQueueReset(setupQueue);
  if (xSemaphoreTake(setupRxMutex, pdMS_TO_TICKS(100)) == pdTRUE) { setupRx.reset(); xSemaphoreGive(setupRxMutex); }
  setupRequest = ""; setupSucceeded = false; setupDisconnected = false;
  setupOpenedAt = millis(); setupOpen = true;
  setSetupStatus("ready");
  BLEDevice::startAdvertising();
  Serial.println("Bluetooth setup open for 10 minutes. Hold BOOT 3 seconds to reopen.");
}
void restoreWifi() {
  String ssid = prefs.getString("ssid", ""), password = prefs.getString("pass", "");
  String saved = prefs.getString("setup", "");
  JsonDocument doc;
  if (!saved.isEmpty() && !deserializeJson(doc, saved)) {
    ssid = doc["ssid"].as<String>(); password = doc["password"].as<String>();
  }
  WiFi.disconnect();
  if (!ssid.isEmpty()) WiFi.begin(ssid.c_str(), password.c_str());
}
void handleProvisioning() {
  static uint32_t buttonAt = 0;
  static bool buttonHandled = false, wifiWasConnected = false;
  if (digitalRead(0) == LOW) {
    if (!buttonAt) buttonAt = millis();
    if (!buttonHandled && millis() - buttonAt >= 3000) { buttonHandled = true; startProvisioning(); }
  } else { buttonAt = 0; buttonHandled = false; }
  const bool wifiConnected = WiFi.status() == WL_CONNECTED;
  if (wifiConnected && !wifiWasConnected) startMdns();
  wifiWasConnected = wifiConnected;
  if (!setupOpen) return;
  if (setupDisconnected) {
    setupDisconnected = false;
    if (!setupSucceeded) BLEDevice::startAdvertising();
  }
  SetupCommand command = {};
  if (setupQueue && xQueueReceive(setupQueue, &command, 0) == pdTRUE && !setupConnecting && !setupSucceeded) {
    JsonDocument doc;
    auto parsed = deserializeJson(doc, command.json);
    memset(command.json, 0, sizeof(command.json));
    setupRequest = doc["request_id"].is<const char*>() ? doc["request_id"].as<String>() : "";
    const JsonString ssid = doc["ssid"].as<JsonString>(), password = doc["password"].as<JsonString>(), name = doc["name"].as<JsonString>();
    bool requestValid = setupRequest.length() >= 1 && setupRequest.length() <= 32;
    for (char c : setupRequest) if (!isalnum((unsigned char)c) && c != '-') requestValid = false;
    if (parsed || !requestValid || !doc["version"].is<int>() || doc["version"].as<int>() != 1 || !doc["pixels"].is<int>() ||
        !validSetupFields(ssid.c_str(), ssid.size(), password.c_str(), password.size(), name.c_str(), name.size(), doc["pixels"].as<int>())) {
      setSetupStatus("error", "invalid_config");
    } else {
      candidateSsid = ssid.c_str(); candidatePassword = password.c_str(); candidateName = name.c_str(); candidatePixels = doc["pixels"].as<int>();
      setupConnecting = true; setupConnectAt = millis();
      setSetupStatus("connecting");
      WiFi.disconnect(); WiFi.begin(candidateSsid.c_str(), candidatePassword.c_str());
    }
  }
  memset(command.json, 0, sizeof(command.json));
  if (setupConnecting) {
    if (WiFi.status() == WL_CONNECTED && WiFi.SSID() == candidateSsid) {
      // One NVS key commits credentials, name and count together, only after WiFi succeeds.
      JsonDocument saved;
      saved["ssid"] = candidateSsid; saved["password"] = candidatePassword;
      saved["name"] = candidateName; saved["pixels"] = candidatePixels;
      String blob; serializeJson(saved, blob);
      if (prefs.putString("setup", blob) == 0) {
        setSetupStatus("error", "storage_failed"); restoreWifi();
      } else {
        deviceName = candidateName;
        FastLED.clear(true); pixelCount = candidatePixels; FastLED[0].setLeds(leds, pixelCount);
        prefs.putString("name", deviceName); persist();
        setupSucceeded = true; setupSuccessAt = millis();
        startMdns(); setSetupStatus("connected");
      }
      blob = ""; candidatePassword = ""; setupConnecting = false;
    } else if (millis() - setupConnectAt >= 25000) {
      setupConnecting = false; candidatePassword = "";
      setSetupStatus("error", "wifi_failed"); restoreWifi();
    }
  }
  if (!setupConnecting && ((setupSucceeded && millis() - setupSuccessAt >= 60000) || (!setupSucceeded && millis() - setupOpenedAt >= SETUP_WINDOW_MS))) {
    setupOpen = false; BLEDevice::stopAdvertising();
    if (setupConnected) setupServer->disconnect(setupServer->getConnId());
    xQueueReset(setupQueue);
  }
}
