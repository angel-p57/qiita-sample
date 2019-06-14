#include "tbase.h"
#include <stdbool.h>
#include <stdio.h>
#include <stdlib.h>

static bool lib_initialized = false;

__attribute__((constructor))
static void init(void) {
  puts("tbase: initializing...");
  lib_initialized = true;
  puts("tbase: initialized.");
}

void use_tbase(void) {
  if ( !lib_initialized ) {
    puts("tbase: not initialized yet, aborted.");
    abort();
  }
  puts("tbase: used.");
}
