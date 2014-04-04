#include <time.h>
#include <sys/time.h>

char str[256];

char * timeval_to_string(struct timeval *tv)
{
  struct tm *now;
  time_t result;
  result = tv -> tv_sec;
  now = localtime(&result);
  strftime(str, 255, "%Y-%m-%d %H:%M:%S", now);
  return str;
}
