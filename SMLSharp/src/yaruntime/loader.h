/*
 * loader.h
 * @copyright (c) 2007, Tohoku University.
 * @author UENO Katsuhiro
 * @version $Id: loader.h,v 1.2 2008/01/10 04:43:13 katsu Exp $
 */
#ifndef SMLSHARP__LOADER_H__
#define SMLSHARP__LOADER_H__

#include "error.h"
#include "file.h"
#include "env.h"
#include "exe.h"

status_t
load_elf(file_t *file, env_t *symenv, executable_t **exe);

#endif /* SMLSHARP__LOADER_H_ */
