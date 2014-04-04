#include <time.h>
typedef struct timespec sml_timer_t;
void cgettime(int* a) {
  sml_timer_t t;
  clock_gettime(CLOCK_REALTIME, &(t));
  a[0] = t.tv_sec;
  a[1] = t.tv_nsec;
}

