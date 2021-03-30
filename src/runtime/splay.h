/*
 * splay.h - splay tree implementation
 * @copyright (C) 2021 SML# Development Team.
 * @author UENO Katsuhiro
 */

#ifndef SMLSHARP__SPLAY_H__
#define SMLSHARP__SPLAY_H__

typedef struct sml_tree sml_tree_t;

/* create a tree with a compare function and the size of an item. */
sml_tree_t *sml_tree_new(int(*cmp)(const void *, const void *), size_t);

/* destroy a tree by freeing all memory allocated for vertexes and items */
void sml_tree_destroy(sml_tree_t *);

/* perform copying compaction to free deleted vertexes and items */
void sml_tree_compact(sml_tree_t *);

/* search for an item in the given tree equivalent to the given item.
 * It returns null if not found. */
void *sml_tree_find(sml_tree_t *tree, void *item);

/* insert the given item to the given tree.  It returns a pointer to memory
 * allocated for the item in the tree.  The memory is initialized by copying
 * the given item.  If there already exists an item equivalent to the given
 * one, it does not allocate memory but overwrites the existing one with the
 * given one. */
void *sml_tree_insert(sml_tree_t *tree, void *item);

/* delete an item in the given tree equivalent to the given item.  It returns
 * a pointer to the item in the tree, or null if not found.  The returned
 * memory would be reclaimed or freed by sml_tree_insert or sml_tree_compact;
 * the memory is accessible until those functions are invoked. */
void *sml_tree_delete(sml_tree_t *tree, void *item);

/* call visit function for each item in the tree.  The first argument of
 * visit is the pointer to the item, and the second one is the given pointer
 * as the third argument of sml_tree_each. */
void sml_tree_each(sml_tree_t *tree, void (*visit)(void *, void *), void *);

/* call reject function for each item in the tree and return the item if
 * reject returns non-zero. */
void sml_tree_reject(sml_tree_t *tree, int (*reject)(void *));

/* rebuild tree by inserting all items in tree to a new tree */
void sml_tree_rebuild(struct sml_tree *tree);

#endif /* SMLSHARP__SPLAY_H__ */
