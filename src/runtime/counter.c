/*
 * counter.c
 * @copyright (c) 2012, Tohoku University.
 * @author UENO Katsuhiro
 */

#include "smlsharp.h"
#include <stdlib.h>
#include <pthread.h>

struct sml_counter {
	int count;
	pthread_mutex_t mutex;
	pthread_cond_t cond;
};

struct sml_counter *
sml_counter_new()
{
	struct sml_counter *c = xmalloc(sizeof(struct sml_counter));
	c->count = 0;
	pthread_mutex_init(&c->mutex, NULL);
	pthread_cond_init(&c->cond, NULL);
	return c;
}

void
sml_counter_free(struct sml_counter *c)
{
	pthread_mutex_destroy(&c->mutex);
	pthread_cond_destroy(&c->cond);
	free(c);
}

void
sml_counter_inc(struct sml_counter *c)
{
	pthread_mutex_lock(&c->mutex);
	c->count++;
	pthread_cond_signal(&c->cond);
	pthread_mutex_unlock(&c->mutex);
}

void
sml_counter_wait(struct sml_counter *c, int min)
{
	pthread_mutex_lock(&c->mutex);
	while (c->count < min)
		pthread_cond_wait(&c->cond, &c->mutex);
	c->count = 0;
	pthread_mutex_unlock(&c->mutex);
}
