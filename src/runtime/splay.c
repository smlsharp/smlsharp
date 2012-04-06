/*
 * splay.c - splay tree implementation
 * @copyright (c) 2009-2010, Tohoku University.
 * @author UENO Katsuhiro
 */

#include <stdio.h>
#include <stdlib.h>
#include "smlsharp.h"
#include "splay.h"

enum { RIGHT, LEFT };   /* sign bit of compare result */
#define OPP(dir) ((int)((unsigned int)(dir) ^ 1))
#define DIR(cmp) (cmp < 0 ? LEFT : RIGHT)

struct sml_tree_node {
	struct sml_tree_node *child[2];
	void *item;
	void *next;   /* for tree traversal */
};

typedef int (*cmp_fn)(void *, void *);

static void
node_dump(struct sml_tree_node *node, int indent)
{
	if (node == NULL)
		return;
	node_dump(node->child[LEFT], indent + 2);
	fprintf(stderr, "%*s%d\n", indent, "", (int)node->item);
	node_dump(node->child[RIGHT], indent + 2);
}

/* for debug */
void
sml_tree_dump(struct sml_tree_node *node)
{
	node_dump(node, 0);
}

/* for debug */
unsigned int
sml_tree_height(struct sml_tree_node *node)
{
	int m, n;
	if (node == NULL)
		return 0;
	m = sml_tree_height(node->child[LEFT]);
	n = sml_tree_height(node->child[RIGHT]);
	return (m > n ? m : n) + 1;
}

/* for debug */
unsigned int
sml_tree_count(struct sml_tree_node *node)
{
	int m, n;
	if (node == NULL)
		return 0;
	m = sml_tree_count(node->child[LEFT]);
	n = sml_tree_count(node->child[RIGHT]);
	return m + n + 1;
}

/*
 * Top-down splaying.
 *
 * Let a,b,c,... be nodes.
 * Let A,B,C,... be trees.
 * nil denotes an empty tree.
 * T[n][L][R] is tree context where n is the root node, [L] and [R] are
 * the hole in the left and right sub-tree of n, respectively.
 * E[n][L][R] is empty tree context such that
 *                  n
 *   E[n][L][R] =  / \
 *                L   R
 *
 * Splaying operation by key k moves a node whose key is k to
 * root by the splaying operations.
 *
 * We describe the splaying operations through transformation rules
 * of SPLAY term;
 *
 *   SPLAY_k(A, E[][][]) --*--> T[a][B][C]
 *
 * where k is a key and A is a non-empty binary search tree.
 * After splaying operation, key of root node of resulting tree
 * T[a][B][C] is equal to k if there is the node a in tree A such
 * that key of a is k.
 *
 * Invaliant:
 * For any SPLAY_k(A, T[][][]), let n be a node whose key is k,
 * T[n][nil][nil] is a binary search tree.
 *
 * Found:
 *              a
 *   SPLAY_k(  / \  , T[][][] )     if k = a.key
 *            B   C
 *
 *   ---> T[a][B][C]
 *
 * Left Not Found:
 *               a
 *   SPLAY_k(   / \  , T[][][] )    if k < a.key
 *            nil  C
 *
 *   ---> T[a][nil][C]
 *
 * Left Zig:
 *                a
 *               / \
 *   SPLAY_k(   b   C , T[][][] )    if k < a.key and cannot apply other rules
 *             / \
 *            A   B
 *                   b              a
 *   ---> SPLAY_k(  / \  , T[][][  / \  ] )
 *                 A   B          []  C
 *
 * Left Zig-Zig:
 *               a
 *              / \
 *   SPLAY_k(  b   C , T[][][] )    if k < b.key < a.key and A != nil
 *            / \
 *           A   B
 *                    b
 *                   / \
 *   ---> SPLAY_k(  A   a  , T[][][] )    (right rotation)
 *                     / \
 *                    B   C
 *                              b
 *                             / \
 *   ---> SPLAY_k( A , T[][][ []  a  ] )    (left zig)
 *                               / \
 *                              B   C
 *
 *   If k < b.key < a.key but A == nil, one Left Zig will be applied and
 *   then splaying will be finished with Left Not Found rule. This is
 *   equivalent to terminating after right rotation step of Zig-Zig rule.
 *
 * Right rules are vice versa.
 */
static int
splay(cmp_fn cmp, struct sml_tree_node **root, void *item)
{
	struct sml_tree_node *child[2], **hole[2];
	struct sml_tree_node *node = *root;
	struct sml_tree_node *tmp;
	int n, dir;

	if (node == NULL)
		return 1;

	hole[RIGHT] = &child[RIGHT];
	hole[LEFT] = &child[LEFT];
	n = cmp(item, node->item);
	while (n != 0) {
		dir = DIR(n);
		if (node->child[dir] == NULL)
			break;
		n = cmp(item, node->child[dir]->item);
		if (n != 0 && DIR(n) == dir) {
			/* zig-zig: rotation */
			tmp = node->child[dir];
			node->child[dir] = node->child[dir]->child[OPP(dir)];
			tmp->child[OPP(dir)] = node;
			node = tmp;
			if (node->child[dir] == NULL)
				break;
			n = cmp(item, node->child[dir]->item);
		}
		*hole[OPP(dir)] = node;
		hole[OPP(dir)] = &node->child[dir];
		node = node->child[dir];
	}
	*hole[RIGHT] = node->child[RIGHT];
	*hole[LEFT] = node->child[LEFT];
	node->child[RIGHT] = child[RIGHT];
	node->child[LEFT] = child[LEFT];

	*root = node;
	return n;
}

void *
sml_tree_find(sml_tree_t *tree, void *item)
{
	int n = splay(tree->cmp, &tree->root, item);
	return (n == 0) ? tree->root->item : NULL;
}

void
sml_tree_insert(sml_tree_t *tree, void *item)
{
	struct sml_tree_node *node;
	int n, dir;

	n = splay(tree->cmp, &tree->root, item);
	if (n == 0) {
		tree->root->item = item;
		return;
	}

	node = tree->alloc(sizeof(struct sml_tree_node));
	node->item = item;

	dir = DIR(n);
	node->child[OPP(dir)] = tree->root;
	if (tree->root) {
		node->child[dir] = tree->root->child[dir];
		tree->root->child[dir] = NULL;
	} else {
		node->child[dir] = NULL;
	}
	tree->root = node;
}

static struct sml_tree_node *
delete_root(cmp_fn cmp, struct sml_tree_node *root)
{
	struct sml_tree_node *newroot;

	if (root->child[LEFT] == NULL) {
		newroot = root->child[RIGHT];
	} else {
		newroot = root->child[LEFT];
		if (root->child[RIGHT] != NULL) {
			splay(cmp, &newroot, root->item);
			ASSERT(newroot->child[RIGHT] == NULL);
			newroot->child[RIGHT] = root->child[RIGHT];
		}
	}
	return newroot;
}

void *
sml_tree_delete(sml_tree_t *tree, void *item)
{
	struct sml_tree_node *node;
	void *ret;
	int n;

	n = splay(tree->cmp, &tree->root, item);
	if (n != 0)
		return NULL;

	ret = tree->root->item;
	node = tree->root;
	tree->root = delete_root(tree->cmp, tree->root);
	if (tree->free)
		tree->free(node);
	return ret;
}

void
sml_tree_reject(sml_tree_t *tree, int(*f)(void *attr))
{
	cmp_fn cmp = tree->cmp;
	void (*free)(void *) = tree->free;
	struct sml_tree_node *node, *new, **cur, **top;

	if (tree->root == NULL)
		return;

	tree->root->next = NULL;
	top = &tree->root;
	do {
		cur = top;
		node = *cur;
		top = node->next;
		while (f(node->item)) {
			new = delete_root(cmp, node);
			*cur = new;
			if (free)
				free(node);
			node = new;
			if (node == NULL)
				break;
		}
		if (node) {
			if (node->child[RIGHT]) {
				node->child[RIGHT]->next = top;
				top = &node->child[RIGHT];
			}
			if (node->child[LEFT]) {
				node->child[LEFT]->next = top;
				top = &node->child[LEFT];
			}
		}
	} while (top);
}

#define TRAVERSE_NEXT(top, new) do { \
	new = top->next; \
	if (top->child[RIGHT]) \
		top->child[RIGHT]->next = new, new = top->child[RIGHT]; \
	if (top->child[LEFT]) \
		top->child[LEFT]->next = new, new = top->child[LEFT];	\
} while (0)

void
sml_tree_delete_all(sml_tree_t *tree)
{
	void (*free)(void *) = tree->free;
	struct sml_tree_node *top, *next;

	if (free && tree->root) {
		tree->root->next = NULL;
		for (top = tree->root; top; top = next) {
			TRAVERSE_NEXT(top, next);
			free(top);
		}
	}
	tree->root = NULL;
}

void
sml_tree_each(sml_tree_t *tree, void (*f)(void *, void *), void *data)
{
	struct sml_tree_node *top, *next;

	if (!tree->root)
		return;

	tree->root->next = NULL;
	for (top = tree->root; top; top = next) {
		TRAVERSE_NEXT(top, next);
		f(top->item, data);
	}
}



#if 0
int cmp(void *a, void *b)
{
	if ((int)a < (int)b) return -1;
	else if ((int) a > (int)b) return 1;
	else return 0;
}

int main()
{
	sml_tree_t tree;
	void *value;
	int i;
	int data[8] = {53, 30, 0, 16, 38, 3, 57, 94};

	tree.root = NULL;
	tree.cmp = cmp;
	tree.alloc = malloc;
	tree.free = free;

	for (i = 0; i < 8; i++) {
		sml_tree_insert(&tree, (void*)data[i]);
		printf("insert %d\n", data[i]);
		sml_tree_dump(tree.root);
	}

	for (i = 0; i < 8; i++) {
		value = sml_tree_find(&tree, (void*)data[i]);
		printf("find %d : %d\n", data[i], (int)value);
		sml_tree_dump(tree.root);
	}

	for (i = 0; i < 8; i++) {
		value = sml_tree_delete(&tree, (void*)data[i]);
		printf("delete %d : %d\n", data[i], (int)value);
		sml_tree_dump(tree.root);
	}
	return 0;
}
#endif
