/*
 * control.h
 * @copyright (c) 2010, Tohoku University.
 * @author UENO Katsuhiro
 */
#ifndef SMLSHARP__CONTROL_H__
#define SMLSHARP__CONTROL_H__

#include "objspace.h"

void sml_control_init(void);
void sml_control_free(void);
/*void sml_rootset_enum_ptr(void (*trace)(void **), enum sml_gc_mode mode);*/
unsigned int sml_num_threads(void);
void *sml_gc_initiate(void (*trace)(void **), void *(*fix_collect_set)(void));

void sml_start_collector(void);
void sml_stop_collector(void);
void sml_signal_collector(void);

int sml_check_write_barrier(void);

#ifdef DEBUG
int sml_is_no_thread(void);
#endif /* DEBUG */

volatile int sml_write_barrier_flag;

#endif /* SMLSHARP__CONTROL_H__ */
