#include <stdio.h>
#include <stdlib.h>
#include <sys/time.h>
#include "thread_c.h"

static int repeat = 10;
static int size = 14;
static unsigned int cutOff = 7;

struct board {
	unsigned int queens, limit, left, down, right, kill;
};

static struct board
init(unsigned int width)
{
	struct board b;
	b.queens = width;
	b.limit = 1 << width;
	b.left = 0;
	b.down = 0;
	b.right = 0;
	b.kill = 0;
	return b;
}

static struct board *
put(const struct board *b, unsigned int bit)
{
	struct board *r = malloc(sizeof(struct board));;
	r->queens = b->queens - 1;
	r->limit = b->limit;
	r->left = (b->left | bit) >> 1;
	r->down = b->down | bit;
	r->right = (b->right | bit) << 1;
	r->kill = r->left | r->down | r->right;
	return r;
}

static int solve(const struct board *);

static int
ssum(const struct board *board, unsigned int bit)
{
	struct board *b;
	int sum = 0;
	while (bit < board->limit) {
		if ((board->kill & bit) == 0) {
			b = put(board, bit);
			sum += solve(b);
			free(b);
		}
		bit <<= 1;
	}
	return sum;
}

static void *
psum_fn(void *arg)
{
	const struct board *board = arg;
	int result = solve(board);
	free((void*)board);
	return RET(result);
}

static int
psum(const struct board *board, unsigned int bit)
{
	struct board *b;
	thread_t t;
	int n;
	while (bit < board->limit) {
		if ((board->kill & bit) == 0) {
			b = put(board, bit);
			t = create(psum_fn, b);
			n = psum(board, bit << 1);
			return n + GET(join(t));
		}
		bit <<= 1;
	}
	return 0;
}

static int
solve(const struct board *board)
{
	if (board->queens == 0)
		return 1;
	else if (board->queens <= cutOff)
		return ssum(board, 1);
	else
		return psum(board, 1);
}

static int
doit()
{
	const struct board b = init(size);
	return solve(&b);
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
	printf(" bench: nqueen_c_%s\n size: %d\n cutoff: %d\n results:\n",
	       threadtype, size, cutOff);
	rep(repeat);
	return 0;
}
