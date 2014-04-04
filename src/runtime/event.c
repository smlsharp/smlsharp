/*
 * event.c
 * @copyright (c) 2011, Tohoku University.
 * @author UENO Katsuhiro
 */

#include "smlsharp.h"
#include <stdlib.h>
#include <pthread.h>

struct sml_event {
	pthread_mutex_t mutex;
	pthread_cond_t cond;
	int signal;
	int reset;
};

sml_event_t *
sml_event_new(int no_reset, int init)
{
	int err;
	sml_event_t *event;

	event = xmalloc(sizeof(sml_event_t));
	err = pthread_mutex_init(&event->mutex, NULL);
	if (err != 0)
		sml_sysfatal("sml_event_new: pthread_mutex_init");
	err = pthread_cond_init(&event->cond, NULL);
	if (err != 0)
		sml_sysfatal("sml_event_new: pthread_cond_init");
	event->reset = no_reset;
	event->signal = init;
	return event;
}

void
sml_event_free(sml_event_t *event)
{
	pthread_mutex_destroy(&event->mutex);
	pthread_cond_destroy(&event->cond);
	free(event);
}

void
sml_event_wait(sml_event_t *event)
{
	pthread_mutex_lock(&event->mutex);
	while (!event->signal)
		pthread_cond_wait(&event->cond, &event->mutex);
	event->signal = event->reset;
	pthread_mutex_unlock(&event->mutex);
}

void
sml_event_signal(sml_event_t *event)
{
	pthread_mutex_lock(&event->mutex);
	if (!event->signal) {
		event->signal = 1;
		pthread_cond_signal(&event->cond);
	}
	pthread_mutex_unlock(&event->mutex);
}

void
sml_event_reset(sml_event_t *event)
{
	pthread_mutex_lock(&event->mutex);
	event->signal = 0;
	pthread_mutex_unlock(&event->mutex);
}
