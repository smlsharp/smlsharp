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
void sml_control_enum_ptr(void (*callback)(void **), enum sml_gc_mode mode);
unsigned int sml_num_threads(void);

#ifdef DEBUG
int sml_is_no_thread(void);
#endif /* DEBUG */

#endif /* SMLSHARP__CONTROL_H__ */
