#include <stdio.h>

extern int itest1;
extern int itest2;
int idup = 3;

void ftest(void) {
  printf("itest1=%d, itest2=%d, idup=%d\n", itest1, itest2, idup);
}
