/**
 * env.c
 * @copyright (c) 2007, Tohoku University.
 * @author UENO Katsuhiro
 * @version $Id: env.c,v 1.3 2008/01/10 04:43:13 katsu Exp $
 */

#include <string.h>
#include "memory.h"
#include "error.h"
#include "env.h"

/* naive AVL tree implementation */

struct node {
	const char *key;
	void *value;
	struct node *left, *right;
	unsigned int height;
};

/* for debug */
void
env_dumptree(int indent, struct node *node)
{
	if (node == NULL) {
		debug("%*sNULL\n", indent, "");
		return;
	}
	debug("%*s%s : %p (%u)\n", indent, "",
	      node->key, node->value, node->height);
	env_dumptree(indent + 2, node->left);
	env_dumptree(indent + 2, node->right);
}

#define HEIGHT(node)          (node ? node->height : 0)
#define ROTATE(node_, from, to) do {		\
	struct node *v_ = (node_)->from;	\
	(node_)->from = v_->to;			\
	v_->to = (node_);			\
	node_ = v_;				\
} while (0)
#define BALANCE(node, from, to) do {					\
	if (node->from->height >= HEIGHT(node->to) + 2) {		\
		if (node->from->to &&					\
		    node->from->to->height > HEIGHT(node->from->from)) { \
			node->from->to->height++;			\
			node->from->height--;				\
			ROTATE(node->from, to, from);			\
		}							\
		node->height--;						\
		ROTATE(node, from, to);					\
	} else {							\
		node->height = node->from->height + 1;			\
	}								\
} while (0)

static struct node *
insert(struct node *node, struct node *newnode)
{
	if (node == NULL)
		return newnode;
	if (strcmp(newnode->key, node->key) < 0) {
		node->left = insert(node->left, newnode);
		BALANCE(node, left, right);
	} else {
		node->right = insert(node->right, newnode);
		BALANCE(node, right, left);
	}
	return node;
}

static struct node *
lookup(struct node *node, const char *key)
{
	int cmp;

	while (node) {
		cmp = strcmp(key, node->key);
		if (cmp == 0)
			break;
		node = (cmp < 0) ? node->left : node->right;
	}
	return node;
}

static char *
new_key(obstack_t **obstack, const char *str)
{
	size_t size;
	char *dst;

	size = strlen(str);
	dst = obstack_alloc(obstack, size + 1);
	memcpy(dst, str, size + 1);
	return dst;
}

static struct node *
rollback(struct node *node, void *p, struct node *newroot)
{
	struct node *left, *right;

	if (node == NULL)
		return newroot;

	left = node->left;
	right = node->right;

	if ((char*)node < (char*)p) {
		node->left = NULL;
		node->right = NULL;
		node->height = 1;
		newroot = insert(newroot, node);
	}
	newroot = rollback(left, p, newroot);
	newroot = rollback(right, p, newroot);
	return newroot;
}

struct env {
	obstack_t *obstack;
	struct node *tree;
	void *rollback_ptr;
};

/* for debug */
void
env_dump(struct env *env)
{
	env_dumptree(0, env->tree);
}

struct env *
env_new()
{
	struct env *env;
	obstack_t *obstack = NULL;

	env = obstack_alloc(&obstack, sizeof(struct env));
	env->obstack = obstack;
	env->tree = NULL;
	env->rollback_ptr = NULL;
	return env;
}

void
env_free(struct env *env)
{
	obstack_t *obstack;

	if (env == NULL)
		return;
	obstack = env->obstack;
	obstack_free(&obstack, NULL);
}

void
env_commit(struct env *env)
{
	env->rollback_ptr = NULL;
}

void
env_rollback(struct env *env)
{
	if (env->rollback_ptr) {
		env->tree = rollback(env->tree, env->rollback_ptr, NULL);
		env->rollback_ptr = NULL;
	}
}

status_t
env_define(struct env *env, const char *key, void *value)
{
	struct node *node;

	node = lookup(env->tree, key);
	if (node != NULL)
		return (node->value == value) ? 0 : ERR_REDEFINED;

	node = obstack_alloc(&env->obstack, sizeof(struct node));
	node->key = new_key(&env->obstack, key);
	node->value = value;
	node->left = NULL;
	node->right = NULL;
	node->height = 1;

	if (env->rollback_ptr == NULL)
		env->rollback_ptr = node;

	env->tree = insert(env->tree, node);
	return 0;
}

status_t
env_redefine(struct env *env, const char *key, void *value)
{
	struct node *node;

	node = lookup(env->tree, key);
	if (node == NULL)
		return ERR_UNDEFINED;

	node->value = value;
	return 0;
}

status_t
env_lookup(struct env *env, const char *key, void **value_ret)
{
	struct node *node;

	node = lookup(env->tree, key);
	if (node) {
		*value_ret = node->value;
		return 0;
	}
	return ERR_UNDEFINED;
}
