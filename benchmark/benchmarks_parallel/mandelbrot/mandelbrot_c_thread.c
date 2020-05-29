#include <stdio.h>
#include <stdlib.h>
#include <sys/time.h>
#include "thread_c.h"

static int repeat = 10;
static int size = 2048;
static int cutOff = 8;

static const double x_base = -2.0;
static const double y_base = 1.25;
static const double side = 2.5;
static const int maxCount = 1024;
static double delta; /* = side / size */
static unsigned char *image;

static int
loopV(int x, int y, int w, int h)
{
	int iterations = 0;
	int i, j, count;
	double c_re, c_im, z_re, z_im, z_re_sq, z_im_sq, re, im;
	for (i = 0; i < h; i++) {
		c_im = y_base - delta * (i + y);
		for (j = 0; j < w; j++) {
			c_re = x_base + delta * (j + x);
			z_re = c_re, z_im = c_im;
			for (count = 0; count < maxCount; count++) {
				z_re_sq = z_re * z_re;
				z_im_sq = z_im * z_im;
				if (z_re_sq + z_im_sq > 4.0) {
					image[j + x + size * (i + y)] = 1;
					break;
				}
				re = z_re_sq - z_im_sq + c_re;
				im = 2.0 * z_re * z_im + c_im;
				z_re = re, z_im = im;
			}
			iterations += count;
		}
	}
	return iterations;
}

static int mandelbrot(int x, int y, int w, int h);
struct mandelbrot_env {
	int x, y, w, h;
};
static void *
mandelbrot_fn(void *arg)
{
	const struct mandelbrot_env *e = arg;
	return RET(mandelbrot(e->x, e->y, e->w, e->h));
}

static int
mandelbrot(int x, int y, int w, int h)
{
	if (w <= cutOff && h <= cutOff) {
		return loopV(x, y, w, h);
	} else if (w >= h) {
		int w2 = w / 2;
		struct mandelbrot_env e = {x + w2, y, w - w2, h};
		thread_t t = create(mandelbrot_fn, &e);
		int r = mandelbrot(x, y, w2, h);
		return r + GET(join(t));
	} else {
		int h2 = h / 2;
		struct mandelbrot_env e = {x, y + h2, w, h - h2};
		thread_t t = create(mandelbrot_fn, &e);
		int r = mandelbrot(x, y, w, h2);
		return r + GET(join(t));
	}
}

static int
doit()
{
	return mandelbrot(0, 0, size, size);
}

static void
rep(int n)
{
	struct timeval t1, t2;
	double d1, d2;
	int r;
	while (n > 0) {
		gettimeofday(&t1, NULL);
		r = doit();
		gettimeofday(&t2, NULL);
#if 0
		fprintf(stderr, "P1\n%d %d\n", size, size);
		for (int i = 0; i < size * size; i++)
			fprintf(stderr, "%d", image[i]);
#endif
		d1 = t1.tv_sec + (double)t1.tv_usec / 1000000;
		d2 = t2.tv_sec + (double)t2.tv_usec / 1000000;
		printf(" - {result: %d, time: %.6f}\n", r, d2 - d1);
		n--;
	}
}

int
main(int argc, char **argv)
{
	if (argc > 1) repeat = atoi(argv[1]);
	if (argc > 2) size = atoi(argv[2]);
	if (argc > 3) cutOff = atoi(argv[3]);
	image = malloc(size * size * sizeof(image[0]));
	delta = side / size;
	printf(" bench: mandelbrot_c_%s\n size: %d\n cutoff: %d\n results:\n",
	       threadtype, size, cutOff);
	rep(repeat);
	return 0;
}
