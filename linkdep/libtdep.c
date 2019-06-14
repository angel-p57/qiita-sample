#include "tbase.h"
#include "tdep.h"
#include <stdio.h>

__attribute__((constructor))
static void init(void) {
  puts("tdep: initializing...");
  use_tbase();
  puts("tdep: initialized.");
}

void use_tdep(void) {
  puts("tdep: used.");
}
