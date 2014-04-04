/*
 * nqueen.c - a parallel N-queen solver
 * @copyright (C) 2013, Tohoku University.
 * @author UENO Katsuhiro
 */

#include <pthread.h>
#include <stdlib.h>
#include <stdio.h>
#include <stdint.h>

struct board {
	unsigned int width;
	unsigned int queens;
	unsigned int left, down, right;
};
typedef struct board board;

struct task {
	board board;
	struct task *next;
};
typedef struct task task;

static pthread_mutex_t tasks_mutex = PTHREAD_MUTEX_INITIALIZER;
static task *tasks;

static board *
get_task()
{
	task *t;

	pthread_mutex_lock(&tasks_mutex);
	t = tasks;
	if (t)
		tasks = t->next;
	pthread_mutex_unlock(&tasks_mutex);

	return &t->board;
}

static void
put(board *b, const board *orig, unsigned int bit)
{
	b->width = orig->width;
	b->queens = orig->queens - 1;
	b->left = (orig->left | bit) >> 1;
	b->down = orig->down | bit;
	b->right = (orig->right | bit) << 1;
}

static unsigned int
solve(board *b)
{
	unsigned int i, mask, bits, sum;
	board board;

	if (b->queens == 0)
		return 1;

	bits = b->left | b->down | b->right;
	sum = 0;

	for (i = 0, mask = 1; i < b->width; i++, mask <<= 1) {
		if (!(bits & mask)) {
			put(&board, b, mask);
			sum += solve(&board);
		}
	}

	return sum;
}

static task *
step(const task *t)
{
	unsigned int i, mask, bits;
	task *ret = NULL, *t2;

	for (; t; t = t->next) {
		if (t->board.queens == 0)
			continue;

		bits = t->board.left | t->board.down | t->board.right;

		for (i = 0, mask = 1; i < t->board.width; i++, mask <<= 1) {
			if (!(bits & mask)) {
				t2 = malloc(sizeof(task));
				put(&t2->board, &t->board, mask);
				t2->next = ret;
				ret = t2;
			}
		}
	}

	return ret;
}

static unsigned int
length(const task *t)
{
	unsigned int n = 0;
	while (t) {
		n++;
		t = t->next;
	}
	return n;
}

static void
gen_tasks(unsigned int width, unsigned int nthreads)
{
	struct task t0;

	t0.board.width = width;
	t0.board.queens = width;
	t0.board.left = 0;
	t0.board.down = 0;
	t0.board.right = 0;
	t0.next = NULL;
	tasks = &t0;

	while (length(tasks) < nthreads * 3)
		tasks = step(tasks);
}

void *
solve_para(void *arg)
{
	board *b;
	unsigned int sum = 0;

	while ((b = get_task()))
		sum += solve(b);
	return (void*)((uintptr_t)sum);
}

#ifndef SINGLETHREAD

/* parallel version */
int
main(int argc, char **argv)
{
	unsigned int width = atoi(argv[1]);
	unsigned int nthreads = atoi(argv[2]);
	pthread_t *threads;
	unsigned int i, sum;
	int err;
	void *result;

	gen_tasks(width, nthreads);

	threads = malloc(sizeof(pthread_t) * nthreads);
	for (i = 0; i < nthreads; i++) {
		err = pthread_create(&threads[i], NULL, solve_para, NULL);
		if (err != 0) {
			perror("pthread_create");
			abort();
		}
	}

	sum = 0;
	for (i = 0; i < nthreads; i++) {
		pthread_join(threads[i], &result);
		sum += (uintptr_t)result;
	}

	printf("%d\n", sum);

	return 0;
}

#else /* SINGLETHREAD */

/* sequential version */
int
main(int argc, char **argv)
{
	unsigned int n;
	struct board b;

	b.width = atoi(argv[1]);
	b.queens = b.width;
	b.left = 0;
	b.down = 0;
	b.right = 0;

	n = solve(&b);
	printf("%d\n", n);

	return 0;
}

#endif /* SINGLETHREAD */
