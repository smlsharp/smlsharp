/*
 * thread.h
 * @copyright (c) 2010, Tohoku University.
 * @author UENO Katsuhiro
 * @version $Id: $
 */
#ifndef SMLSHARP__THREAD_H__
#define SMLSHARP__THREAD_H__

#include "objspace.h"

void sml_thread_env_init(void);
void sml_thread_env_free(void);
void sml_frame_enum_ptr(sml_trace_cls *, enum sml_gc_mode, void *);

#endif /* SMLSHARP__THREAD_H__ */
