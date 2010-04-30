/**
 * env.h
 * @copyright (c) 2007, Tohoku University.
 * @author UENO Katsuhiro
 * @version $Id: env.h,v 1.2 2008/01/10 04:43:13 katsu Exp $
 */
#ifndef SMLSHARP__ENV_H__
#define SMLSHARP__ENV_H__

#include "cdecl.h"
#include "error.h"

typedef struct env env_t;

env_t *env_new(void) ATTR_MALLOC;
void env_free(env_t *env);

status_t env_define(env_t *env, const char *name, void *value);
status_t env_redefine(env_t *env, const char *name, void *value);
status_t env_lookup(env_t *env, const char *name, void **value_ret);
void env_commit(env_t *env);
void env_rollback(env_t *env);

#endif /* SMLSHARP__ENV_H__ */
