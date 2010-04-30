/*
 * splay.c - splay tree implementation
 * @copyright (c) 2009, Tohoku University.
 * @author UENO Katsuhiro
 * @version $Id: $
 */

#include <stdlib.h>
#include "smlsharp.h"

#if 0
#include <stdio.h>
#define sml_debug(fmt,args...) fprintf(stderr,fmt,args)
#endif

enum { RIGHT, LEFT };
#define OPP(dir)   ((int)((unsigned int)(dir) ^ 1))
#define DIR(cmp)   (cmp < 0 ? LEFT : RIGHT)

struct sml_tree_node {
	void *key, *value;
	struct sml_tree_node *child[2];
};

static void
node_dump(struct sml_tree_node *node, int indent)
{
	if (node == NULL)
		return;
	node_dump(node->child[RIGHT], indent + 2);
	sml_debug("%*s%p: %p\n", indent, "", node->key, node->value);
	node_dump(node->child[LEFT], indent + 2);
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
 * Tree context T is of the form
 *                  n
 *   T[n][L][R] =  / \
 *                L   R
 *
 * Splaying operation by key 'k' moves a node whose key is 'k' to
 * root by zig-zag operation.
 *
 * We describes the splaying operation through transformation rules
 * of SPLAY term;
 *
 *   SPLAY<k>(A, T[][][]) --*--> T[a][B][C]
 *
 * where k is a key and A is a non-empty binary search tree.
 * After splaying operation, key of root node 'a' of resulting tree
 * T[a][B][C] is equal to k if there is the node 'a' in tree 'A'.
 *
 * Invaliant:
 * For any SPLAY<k>(A, T[][][]),
 * T[n][nil][nil] is a binary search tree for any node 'n' s.t. 'n'.key = k.
 *
 * Case 0: Found
 *
 *               a
 *   SPLAY<k>(  / \  , T[][][])   if k == a.key
 *             B   C
 *
 *   ---> T[a][B][C]
 *
 * Case 1: Left zig
 *
 *               a
 *   SPLAY<k>(  / \  , T[][][])     if k < a.key
 *             B   C
 *                              a
 *   ---> SPLAY<k>( B, T[][][  / \  ]  )
 *                            []  C
 *
 *               a
 *   SPLAY<k>(  / \  , T[][][])     if k < a.key
 *            nil  C
 *
 *   ---> T[a][nil][C]
 *
 * Case 2: Left zig-zig
 *
 *                 a
 *                / \
 *   SPLAY<k>(   b   C , T[][][])   if k < b.key < a.key and D != nil
 *              / \
 *             D   E
 *                      b
 *                     / \
 *   ---> SPLAY<k>(   D   a  , T[][][] )   (right rotation)
 *                       / \
 *                      E   C
 *                              b
 *                             / \
 *   ---> SPLAY<k>( D,  T[][ []   a   ] )
 *                               / \
 *                              E   C
 *
 * if D is nil, zig-zig is same as sequential two zig.
 *
 * Case 2: Left zig-zag
 *
 *                 a
 *                / \
 *   SPLAY<k>(   b   C , T[][][])   if b.key < key < a.key
 *              / \
 *             D   E
 *                     b              a
 *   ---> SPLAY<k>(   / \  , T[][][  / \  ])
 *                   D   E          []  C
 *                              b          a
 *   ---> SPLAY<k>( E , T[][   / \   ][   / \   ])
 *                            D   []     []  C
 *
 * Zig-zag is same as one left-zig followed by one right-zig.
 *
 *
 * Right rules are vice versa.
 *
 */
static int
splay(sml_tree_t *tree, void *key)
{
	struct sml_tree_node *child[2], **hole[2];
	struct sml_tree_node *node = tree->root;
	struct sml_tree_node *tmp;
	int n, dir;

	hole[RIGHT] = &child[RIGHT];
	hole[LEFT] = &child[LEFT];

	if (node == NULL)
		return 1;

	n = tree->cmp(key, node->key);
	while (n != 0) {
		dir = DIR(n);
		if (node->child[dir] == NULL)
			break;

		n = tree->cmp(key, node->child[dir]->key);
		if (n != 0 && DIR(n) == dir) {
			/* zig-zig: rotation */
			tmp = node->child[dir];
			node->child[dir] = node->child[dir]->child[OPP(dir)];
			tmp->child[OPP(dir)] = node;
			node = tmp;
			if (node->child[dir] == NULL)
				break;
			n = tree->cmp(key, node->child[dir]->key);
		}
		*hole[OPP(dir)] = node;
		hole[OPP(dir)] = &node->child[dir];
		node = node->child[dir];
	}
	*hole[LEFT] = node->child[LEFT];
	*hole[RIGHT] = node->child[RIGHT];
	node->child[LEFT] = child[LEFT];
	node->child[RIGHT] = child[RIGHT];
	tree->root = node;
	return n;
}

void **
sml_splay_find(sml_tree_t *tree, void *key)
{
	int n = splay(tree, key);
	return (n == 0) ? &tree->root->value : NULL;
}

void **
sml_splay_insert(sml_tree_t *tree, void *key)
{
	struct sml_tree_node *node;
	int n, dir;

	n = splay(tree, key);
	if (n != 0) {
		node = tree->alloc(sizeof(struct sml_tree_node));
		node->key = key;

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

	return &tree->root->value;
}

static struct sml_tree_node *
delete_root(sml_tree_t *tree)
{
	struct sml_tree_node *node = tree->root;

	if (node->child[LEFT] == NULL) {
		tree->root = node->child[RIGHT];
	} else {
		tree->root = node->child[LEFT];
		if (node->child[RIGHT] != NULL) {
			splay(tree, node->key);
			ASSERT(tree->root->child[RIGHT] == NULL);
			tree->root->child[RIGHT] = node->child[RIGHT];
		}
	}
	return node;
}

int
sml_splay_delete(sml_tree_t *tree, void *key, void **value_ret)
{
	struct sml_tree_node *node;
	int n;

	n = splay(tree, key);
	if (n != 0)
		return 0;

	node = delete_root(tree);
	if (value_ret)
		*value_ret = node->value;
	if (tree->free)
		tree->free(node);
	return 1;
}

void
sml_tree_delete_all(sml_tree_t *tree)
{
	struct sml_tree_node *root = tree->root;

	if (root == NULL)
		return;

	tree->root = root->child[LEFT];
	sml_tree_delete_all(tree);

	tree->root = root->child[RIGHT];
	sml_tree_delete_all(tree);

	if (tree->free)
		tree->free(root);
	tree->root = NULL;
}

void
sml_splay_reject(sml_tree_t *tree, int (*f)(void *, void **))
{
	struct sml_tree_node *root = tree->root;

	if (root == NULL)
		return;

	tree->root = root->child[RIGHT];
	sml_splay_reject(tree, f);
	root->child[RIGHT] = tree->root;

	tree->root = root->child[LEFT];
	sml_splay_reject(tree, f);
	root->child[LEFT] = tree->root;

	tree->root = root;
	if (f(root->key, &root->value)) {
		delete_root(tree);
		if (tree->free)
			tree->free(root);
	}
}

void
sml_tree_traverse(struct sml_tree_node *node,
		  void (*f)(void *, void **, void *), void *data)
{
	if (node == NULL)
		return;
	sml_tree_traverse(node->child[LEFT], f, data);
	f(node->key, &node->value, data);
	sml_tree_traverse(node->child[RIGHT], f, data);
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
	void **node, *value;
	int i, n;
	int data[8] = {53, 30, 0, 16, 38, 3, 57, 94};

	tree.root = NULL;
	tree.cmp = cmp;
	tree.alloc = malloc;
	tree.free = free;

	for (i = 0; i < 8; i++) {
		node = sml_splay_insert(&tree, (void*)data[i]);
		*node = (void*)data[i];
		printf("insert %d\n", data[i]);
		sml_tree_dump(tree.root);
	}

	for (i = 0; i < 8; i++) {
		node = sml_splay_find(&tree, (void*)data[i]);
		value = node ? *node : NULL;
		printf("find %d : %d\n", data[i], (int)value);
		sml_tree_dump(tree.root);
	}

	for (i = 0; i < 8; i++) {
		n = sml_splay_delete(&tree, (void*)data[i], &value);
		printf("delete %d : %d\n", data[i], (int)value);
		sml_tree_dump(tree.root);
	}
	return 0;
}
#endif
