#include <wchar.h>
#include "bridge.h"

unsigned int __bridge_WEOF() {
  return WEOF;
}

unsigned int __bridge_fgetwc(FILE* stream) {
  return fgetwc(stream);
}
