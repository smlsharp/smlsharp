/*
 * naive parallel matrix multiplication
 * A matrix is represented by a nested array.
 */

#include <pthread.h>
#include <stdio.h>
#include <stdlib.h>

#define DIM (2*3*5*7*8)   /* dividable by 1 - 8 */
static double **matrix1;
static double **matrix2;
static double **result;
static unsigned int nthreads;

static double **
alloc_matrix(double init)
{
	unsigned int i, j;
	double **matrix;

	matrix = malloc(sizeof(double*) * DIM);
	if (matrix == NULL) abort();

	for (i = 0; i < DIM; i++) {
		matrix[i] = malloc(sizeof(double) * DIM);
		if (matrix[i] == NULL) abort();
		for (j = 0; j < DIM; j++) matrix[i][j] = init;
	}

	return matrix;
}

static void *
calc(void *arg)
{
	unsigned int start = (unsigned int)arg;
	unsigned int i, j, k;

	for (i = start; i < start + DIM / nthreads; i++) {
		for (j = 0; j < DIM; j++) {
			double d = 0.0;
			for (k = 0; k < DIM; k++)
				d += matrix1[i][k] * matrix2[k][j];
			result[i][j] = d;
		}
	}
	return NULL;
}

int
main(int argc, char **argv)
{
	unsigned int i, start;
	int err;
        pthread_t *th;

	nthreads = 1;
	if (argc == 2)
		nthreads = atoi(argv[1]);

        th = malloc(sizeof(pthread_t) * nthreads);
	if (th == NULL) abort();

	matrix1 = alloc_matrix(1.2345678);
	matrix2 = alloc_matrix(1.2345678);
	result = alloc_matrix(0.0);

	for (i = 1; i < nthreads; i++) {
		start = i * DIM / nthreads;
		err = pthread_create(&th[i], NULL, calc, (void*)start);
		if (err != 0) abort();
	}

	calc((void*)0);

	for (i = 1; i < nthreads; i++) {
		err = pthread_join(th[i], NULL);
		if (err != 0) abort();
	}

	return 0;
}
