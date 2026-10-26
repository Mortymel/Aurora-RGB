#pragma once
#include <stddef.h>
#include <string.h>

// Byte limits match the BLE JSON protocol and ESP32 WiFi constraints.
inline bool validSetupFields(const char* ssid, size_t ssidSize,
                            const char* password, size_t passwordSize,
                            const char* name, size_t nameSize, int pixels) {
  return ssid && password && name && ssidSize >= 1 && ssidSize <= 32 &&
    (passwordSize == 0 || (passwordSize >= 8 && passwordSize <= 63)) &&
    nameSize >= 1 && nameSize <= 48 && pixels >= 1 && pixels <= 1024 &&
    strlen(ssid) == ssidSize && strlen(password) == passwordSize && strlen(name) == nameSize;
}

class ProvisioningLineBuffer {
 public:
  char data[513] = {};
  size_t size = 0;
  bool overflow = false;
  // The caller consumes data immediately when true; next byte starts a new line.
  bool push(char c) {
    if (c == '\n') {
      bool complete = !overflow && size > 0;
      data[size] = 0;
      size = 0;
      overflow = false;
      return complete;
    }
    if (c == 0 || size >= 512) { overflow = true; return false; }
    if (!overflow) data[size++] = c;
    return false;
  }
  void reset() { size = 0; overflow = false; data[0] = 0; }
};
