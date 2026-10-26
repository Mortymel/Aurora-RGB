#include <cassert>
#include <string>
#include "../firmware/src/provisioning_validation.h"
int main() {
  assert(validSetupFields("red", 3, "password", 8, "Salon", 5, 1));
  assert(validSetupFields("red", 3, "", 0, "Salon", 5, 1024));
  assert(!validSetupFields("red", 3, "short", 5, "Salon", 5, 60));
  assert(!validSetupFields("red", 3, "password", 8, "Salon", 5, 0));
  assert(!validSetupFields("red", 3, "password", 8, "Salon", 5, 1025));
  assert(!validSetupFields(nullptr, 0, "", 0, "Salon", 5, 1));
  const char nul[] = {'a', 0, 'b', 0};
  assert(!validSetupFields(nul, 3, "", 0, "a", 1, 1));
  ProvisioningLineBuffer line;
  const std::string json = "{\"name\":\"Salón\"}";
  for (char c : json) assert(!line.push(c));
  assert(line.push('\n')); assert(json == line.data);
  assert(!line.push('\n')); // Empty framing reset is ignored.
  for (int i = 0; i < 512; ++i) assert(!line.push('x'));
  assert(line.push('\n')); assert(strlen(line.data) == 512);
  for (int i = 0; i < 513; ++i) line.push('x');
  assert(!line.push('\n')); // Oversize input cannot become a truncated command.
  line.push('o'); line.push('k'); assert(line.push('\n')); assert(std::string(line.data) == "ok");
  line.push('a'); line.push(0); line.push('b'); assert(!line.push('\n'));
  line.push('a'); line.reset(); assert(!line.push('\n'));
  return 0;
}
