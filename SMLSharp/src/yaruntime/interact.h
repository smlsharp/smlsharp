/*
 * interact.h
 * @copyright (c) 2007, Tohoku University.
 * @author UENO Katsuhiro
 * @version $Id: interact.h,v 1.1 2008/01/10 04:43:13 katsu Exp $
 */
#ifndef SMLSHARP__INTERACT_H__
#define SMLSHARP__INTERACT_H__

#include "cdecl.h"
#include "error.h"
#include "runtime.h"

extern int interactive_mode;
ml_int_t interact_prim_read(ml_int_t fd, void *buf, ml_uint_t offset,
			    ml_uint_t len);
ml_int_t interact_prim_write(ml_int_t fd, void *buf, ml_uint_t offset,
			     ml_uint_t len);
ml_int_t interact_prim_print(void *arg);
ml_int_t interact_prim_printerr(void *arg);
ml_int_t interact_prim_chdir(void *dirname);
ml_int_t interact_prim_exit(ml_int_t status);

status_t interact_start(runtime_t *rt, FILE *in, FILE *out, int *status_ret);

#endif /* SMLSHARP__INTERACT_H__ */
