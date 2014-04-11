#include "config.h"
#include <time.h>

time_t string_to_time_t(const char * str)
{
#ifdef HAVE_STRPTIME
  struct tm tm;
  char * err;
  strptime(str, "%Y-%m-%d %H:%M:%S", &tm);
  return(mktime(&tm));
#else
  /* FIXME : stub */
  return 0;
#endif /* HAVE_STRPTIME */
}
