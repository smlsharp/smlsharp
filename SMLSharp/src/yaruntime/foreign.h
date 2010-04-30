/*
 * foreign.h
 * @copyright (c) 2007, Tohoku University.
 * @author UENO Katsuhiro
 * @version $Id: foreign.h,v 1.3 2008/12/11 10:22:51 katsu Exp $
 */
#ifndef SMLSHARP__FOREIGN_H__
#define SMLSHARP__FOREIGN_H__

#include <ffi.h>
#include "memory.h"
#include "runtime.h"

ffi_cif *foreign_prep_cif(obstack_t **obstack, const char *src);

void foreign_init(void);
void foreign_free(void);
void *foreign_export(runtime_t *rt, void *entry, void *env, ffi_cif *cif);

void foreign_enum_rootset(void (*f)(void **), void *dummy);

#endif /* SMLSHARP__FOREIGN_H__ */
