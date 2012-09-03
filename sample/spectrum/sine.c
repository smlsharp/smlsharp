/*
 * sine.c
 *
 * @copyright (c) 2006-2007, Tohoku University.
 * @author UENO Katsuhiro
 * @version $Id: sine.c,v 1.2 2007/04/02 09:42:29 katsu Exp $
 */

#include <math.h>
#include <stdio.h>
#include <stdlib.h>
#include <limits.h>

#define PI 3.141592653549793238462643383279
#define SAMPLE_RATE 44100

int main(int argc, char **argv)
{
  int hz = 441.0;
  int r = 0;
  int n;
  short sample[2];

  if (argc > 1)
    hz = strtol(argv[1], NULL, 10);

  for (;;) {
    n = sin(hz * 2 * PI * r / SAMPLE_RATE) * 32768 * 0.8;
    if (n > SHRT_MAX) n = SHRT_MAX;
    if (n < SHRT_MIN) n = SHRT_MIN;
    sample[0] = n;
    sample[1] = n;
    fwrite(sample, sizeof(short), 2, stdout);
    r++;
    if (r > 44100) r = 0;
  }

  return 0;
}
