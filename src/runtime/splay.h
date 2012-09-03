/*
 * splay.h - splay tree implementation
 * @copyright (c) 2009-2010, Tohoku University.
 * @author UENO Katsuhiro
 */

#ifndef SMLSHARP__SPLAY_H__
#define SMLSHARP__SPLAY_H__

struct sml_tree {
	struct sml_tree_node *root;
	int (*cmp)(void *item1, void *item2);
	void *(*alloc)(size_t);   /* for node allocation */
	void (*free)(void *);     /* for node releasing */
};
typedef struct sml_tree sml_tree_t;

#define SML_TREE_INITIALIZER(cmp, alloc, free) {NULL, cmp, alloc, free}

void *sml_tree_find(sml_tree_t *tree, void *item);
void sml_tree_insert(sml_tree_t *tree, void *item);
void *sml_tree_delete(sml_tree_t *tree, void *item);
void sml_tree_delete_all(sml_tree_t *tree);
void sml_tree_reject(sml_tree_t *tree, int (*f)(void *item));
void sml_tree_each(sml_tree_t *tree, void (*f)(void *item, void *), void*);

#endif /* SMLSHARP__SPLAY_H__ */
