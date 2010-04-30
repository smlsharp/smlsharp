/*
 * prep.h
 * @copyright (c) 2007, Tohoku University.
 * @author UENO Katsuhiro
 * @version $Id: prep.h,v 1.3 2008/01/10 04:43:13 katsu Exp $
 */
#ifndef SMLSHARP__PREP_H__
#define SMLSHARP__PREP_H__

#include "error.h"
#include "exe.h"
#include "runtime.h"

/* returns the pointer to error position */
void *preprocess32(runtime_t *vm, executable_t *exe);

#endif /* SMLSHARP__PREP_H__ */
