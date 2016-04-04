/*
 * splay.c - splay tree implementation
 * @copyright (c) 2009-2015, Tohoku University.
 * @author UENO Katsuhiro
 */

#include "smlsharp.h"
#include <stdlib.h>
#include <string.h>
#include "splay.h"

typedef int (*cmp_fn)(const void *, const void *);

enum direction { RIGHT, LEFT };
#define DIR(cmp) (cmp < 0 ? LEFT : RIGHT)  /* sign bit of compare result */
#define OPP(dir) ((enum direction)((unsigned int)(dir) ^ 1))

struct sml_tree {
	struct inst {
		cmp_fn cmp;
		unsigned int item_size, alloc_size;
	} inst;
	struct node *root;
	struct chunk *chunk;
	struct node *freelist;
};

struct node {
	/* char item[];   // there is a user-specified-length field here. */
	struct node *child[2];
	void *back;   /* for tree traversal */
};
#ifdef HAVE_ALIGNOF
#define NODE_ALIGN  __alignof__(struct node)
#else
#define NODE_ALIGN  sizeof(struct node *)  /* we assume this */
#endif /* HAVE_ALIGN_OF */
#define NODE_OFFSET(item_size) (CEILING(item_size, NODE_ALIGN))
#define NODE_SIZE(item_size)   (NODE_OFFSET(item_size) + sizeof(struct node))
#define SIZEOF_NODE(item_size) (CEILING(NODE_SIZE(item_size), item_size))
#define NODE(beg,item_size) \
	((struct node *)((char*)(beg) + NODE_OFFSET(item_size)))
#define NODE_ITEM(node,item_size) \
	((void*)((char*)(node) - NODE_OFFSET(item_size)))

/* for convenience */
#define USE_ITEM_OF(inst) \
	const unsigned int node__offset__ = NODE_OFFSET((inst)->item_size)
#define ITEM_OF(node) ((void*)((char*)(node) - node__offset__))

struct chunk_footer {
	struct chunk *next;
	char *free;
};
#define CHUNK_OFFSET    (4096 / sizeof(struct chunk_footer) - 1)
#define CHUNK_SIZE      (CHUNK_OFFSET * sizeof(struct chunk_footer))
struct chunk {
	char begin[CHUNK_SIZE];
	struct chunk_footer foot;
};
#define CHUNK_END(chunk)  ((chunk)->begin + CHUNK_SIZE)
#define CHUNK_REST(chunk) ((size_t)(CHUNK_END(chunk) - (chunk)->foot.free))

void *
chunk_alloc(struct chunk **chunk, size_t len)
{
	struct chunk *newchunk;
	void *p;
	assert(len < CHUNK_SIZE);
	if (*chunk == NULL || CHUNK_REST(*chunk) < len) {
		newchunk = xmalloc(sizeof(struct chunk));
		newchunk->foot.next = *chunk;
		newchunk->foot.free = newchunk->begin;
		*chunk = newchunk;
	}
	p = (*chunk)->foot.free;
	(*chunk)->foot.free += len;
	return p;
}

static void
chunk_destroy(struct chunk *chunk)
{
	struct chunk *next;
	while (chunk) {
		next = chunk->foot.next;
		free(chunk);
		chunk = next;
	}
}

static void
forward(struct chunk **chunk, struct node **node_ref, const struct inst *inst)
{
	void *newnode, *oldnode;
	struct chunk *oldchunk = *chunk;

	if (*node_ref == NULL)
		return;

	newnode = chunk_alloc(chunk, inst->alloc_size);
	oldnode = NODE_ITEM(*node_ref, inst->item_size);
	memcpy(newnode, oldnode, NODE_SIZE(inst->item_size));
	*node_ref = NODE(newnode, inst->item_size);

	/* reverse the chunk list */
	if (oldchunk && *chunk != oldchunk) {
		assert(oldchunk->foot.next == NULL);
		oldchunk->foot.next = *chunk;
		(*chunk)->foot.next = NULL;
	}
}

void
sml_tree_compact(struct sml_tree *tree)
{
	struct chunk *newchunk = NULL, *begin;
	struct node *node;
	struct { struct chunk *c; char *p; } cursor;

	/* simple copying garbage collection */
	forward(&newchunk, &tree->root, &tree->inst);
	begin = newchunk;
	if (tree->root) {
		cursor.c = newchunk;
		cursor.p = newchunk->begin;
		do {
			node = NODE(cursor.p, tree->inst.item_size);
			forward(&newchunk, &(node->child[LEFT]), &tree->inst);
			forward(&newchunk, &(node->child[RIGHT]), &tree->inst);
			cursor.p += tree->inst.alloc_size;
			if (cursor.p >= cursor.c->foot.free) {
				cursor.c = cursor.c->foot.next;
				cursor.p = cursor.c->begin;
			}
		} while (cursor.c);
	}

	chunk_destroy(tree->chunk);
	tree->chunk = begin;
	tree->freelist = NULL;
}

struct sml_tree *
sml_tree_new(cmp_fn cmp, size_t item_size)
{
	struct sml_tree *tree;
	tree = xmalloc(sizeof(struct sml_tree));
	tree->inst.cmp = cmp;
	tree->inst.item_size = item_size;
	tree->inst.alloc_size = SIZEOF_NODE(item_size);
	assert(SIZEOF_NODE(item_size) <= CHUNK_SIZE);
	tree->root = NULL;
	tree->chunk = NULL;
	tree->freelist = NULL;
	return tree;
}

void
sml_tree_destroy(struct sml_tree *tree)
{
	chunk_destroy(tree->chunk);
}

static struct node *
node_alloc(struct sml_tree *tree)
{
	struct node *newnode;
	void *newitem;
	if (tree->freelist) {
		newnode = tree->freelist;
		tree->freelist = newnode->back;
       } else {
		newitem = chunk_alloc(&tree->chunk, tree->inst.alloc_size);
		newnode = NODE(newitem, tree->inst.item_size);
	}
	return newnode;
}

static void
node_reclaim(struct sml_tree *tree, struct node *node)
{
	node->back = tree->freelist;
	tree->freelist = node;
}

/*
 * Simple top-down splay presented in
 *   D. D. Sleator and R. E. Tarjan,
 *   Self-Adjusting Binary Search Trees,
 *   Journal of the ACM, 32(3), 1985, pp. 652--686.
 *
 * Let m and n range over the given set of vertexes.
 * A binary search tree, ranged over by A,B,C,... is either $ (an empty tree)
 * or AnB (vertex n with its left and right sub-tree A and B).
 * T[] is a tree including a hole as its sub-tree.
 * T[A] is a tree obtained by filling the hole of T with A.
 *
 * The simple top-down algorithm is defined as a state transformation of the
 * following form:
 *     (k, [], T, []) -*-> (k, L[], T', R[])
 *
 * The transformation rules are given below:
 *   L1:
 *         (k, L[], (AmB)nC, R[])        if k < m < n and A != $
 *     --> (k, L[], Am(BnC), R[])        (rotate right)
 *     --> (k, L[], A, R[[]m(BnC)])      (link right)
 *   L2:
 *         (k, L[], (AmB)nC, R[])        if m <= k < n
 *     --> (k, L[], AmB, R[[]mC])        (link right)
 *   R1:
 *         (k, L[], Am(BnC), R[])        if m < n < k and C != $
 *     --> (k, L[], (AmB)nC, R[])        (rotate left)
 *     --> (k, L[(AmB)n[]], C, R[])      (link left)
 *   R2:
 *         (k, L[], Am(BnC), R[])        if m < k <= n
 *     --> (k, L[Am[]], BnC, R[])        (link left)
 *   LN:
 *         (k, L[], ($mB)nC, R[])        if k < m < n
 *     --> (k, L[], $m(BnC), R[])        (rotate right)
 *   RN:
 *         (k, L[], Am(Bn$), R[])        if m < n < k
 *     --> (k, L[], (AmB)n$, R[])        (rotate left)
 * The last two rules LN and RN are straightforwardly derived from L1 and R1
 * to ensure that the tree in the last state is empty only if that in the
 * initial state is empty.
 *
 * SPLAY indicates the result of the transformation.
 *   SPLAY(k,T) = (L[], T', R[])  where (k, [], T, []) -*-> (k, L[], T', R[])
 *
 * Searching for k is carried out by splaying at k.
 *   Find(k,T) = k       if SPLAY(k,T) = (L[],AkB,R[])
 *   Find(k,T) = null    otherwise
 *
 * Insertion is carried out by searching for k, replacing $ with $k$, and
 * finally splaying at k.
 *   Insert(k,$) = $k$
 *   Insert(k,T) = AkB              if SPLAY(k,T) = (L[],AkB,R[])
 *   Insert(k,T) = (L[$])k(R[$nB])  if SPLAY(k,T) = (L[],$nB,R[]) and k < n
 *   Insert(k,T) = (L[An$])k(R[$])  if SPLAY(k,T) = (L[],An$,R[]) and n < k
 *
 * Deletion is carried out by searching for k, replacing k with the join of
 * sub-trees of k, and finally splaying at the parent of k.  For simplicity,
 * we splay at the largest item smaller than k instead of the parent of k.
 *   Delete(k,$) = $
 *   Delete(k,T) = AnB                 if SPLAY(k,T) = (L[],AnB,R[]) and n != k
 *   Delete(k,T) = (L[C])n(R[D])       if SPLAY(k,T) = (L[],AkB,R[])
 *                                        and join(AkB) = CnD
 *   Delete(k,T) = join((L[$])k(R[$])) if SPLAY(k,T) = (L[],$k$,R[])
 * where
 *   join($kB) = B
 *   join(AkB) = L[C]nB  where SPLAY(k,A) = (L[], Cn$, [])
 *
 * Note that the last case of Delete carries out SPLAY twice.
 */

static int
splay(const struct inst *inst, const void *item,
      struct node **tree, struct node **hole[2])
{
	USE_ITEM_OF(inst);
	struct node *node = *tree, *tmp;
	enum direction dir;
	int n;

	n = inst->cmp(item, ITEM_OF(node));
	while (n != 0) {
		dir = DIR(n);
		if (node->child[dir] == NULL)
			break;
		n = inst->cmp(item, ITEM_OF(node->child[dir]));
		if (n != 0 && DIR(n) == dir) {
			/* rotate */
			tmp = node->child[dir];
			node->child[dir] = node->child[dir]->child[OPP(dir)];
			tmp->child[OPP(dir)] = node;
			node = tmp;
			if (node->child[dir] == NULL)
				break;
			n = inst->cmp(item, ITEM_OF(node->child[dir]));
		}
		/* link */
		*hole[OPP(dir)] = node;
		hole[OPP(dir)] = &node->child[dir];
		node = node->child[dir];
	}
	*tree = node;
	return n;
}

static void
assemble(struct node *node, struct node *result[2], struct node **hole[2])
{
	*hole[RIGHT] = node->child[RIGHT];
	*hole[LEFT] = node->child[LEFT];
	node->child[RIGHT] = result[RIGHT];
	node->child[LEFT] = result[LEFT];
}

#define INIT_HOLE(result) {[RIGHT]=&(result)[RIGHT], [LEFT]=&(result)[LEFT]}

void *
sml_tree_find(struct sml_tree *tree, void *item)
{
	USE_ITEM_OF(&tree->inst);
	struct node *result[2], **hole[2] = INIT_HOLE(result);
	int n;

	if (!tree->root)
		return NULL;
	n = splay(&tree->inst, item, &tree->root, hole);
	assemble(tree->root, result, hole);
	return (n == 0) ? ITEM_OF(tree->root) : NULL;
}

void *
sml_tree_insert(struct sml_tree *tree, void *item)
{
	USE_ITEM_OF(&tree->inst);
	struct node *result[2], **hole[2] = INIT_HOLE(result);
	struct node *newnode;
	int n;

	n = tree->root ? splay(&tree->inst, item, &tree->root, hole) : 1;
	if (n != 0) {
		newnode = node_alloc(tree);
		newnode->child[DIR(n)] = NULL;
		newnode->child[OPP(DIR(n))] = tree->root;
		tree->root = newnode;
	}
	assemble(tree->root, result, hole);
	memcpy(ITEM_OF(tree->root), item, tree->inst.item_size);
	return ITEM_OF(tree->root);
}

static int
insert_node(struct sml_tree *tree, struct node *node)
{
	struct node *result[2], **hole[2] = INIT_HOLE(result);
	const void *item = NODE_ITEM(node, tree->inst.item_size);
	int n;

	n = tree->root ? splay(&tree->inst, item, &tree->root, hole) : 1;
	if (n != 0) {
		node->child[DIR(n)] = NULL;
		node->child[OPP(DIR(n))] = tree->root;
		tree->root = node;
	}
	assemble(tree->root, result, hole);
	return n;
}

static struct node *
join(const struct inst *inst, struct node *node)
{
	USE_ITEM_OF(inst);
	struct node *result[2], **hole[2] = INIT_HOLE(result);
	struct node *left = node->child[LEFT];

	if (!left)
		return node->child[RIGHT];
	splay(inst, ITEM_OF(node), &left, hole);
	assert(left->child[RIGHT] == NULL);
	left->child[RIGHT] = node->child[RIGHT];
	assemble(left, result, hole);
	return left;
}

void *
sml_tree_delete(struct sml_tree *tree, void *item)
{
	USE_ITEM_OF(&tree->inst);
	struct node *result[2], **hole[2] = INIT_HOLE(result);
	struct node *newroot;
	int n;

	if (!tree->root)
		return NULL;
	n = splay(&tree->inst, item, &tree->root, hole);
	if (n != 0) {
		assemble(tree->root, result, hole);
		return NULL;
	} else {
		newroot = join(&tree->inst, tree->root);
		if (newroot) {
			assemble(newroot, result, hole);
		} else {
			assemble(tree->root, result, hole);
			newroot = join(&tree->inst, tree->root);
		}
		item = ITEM_OF(tree->root);
		node_reclaim(tree, tree->root);
		tree->root = newroot;
		/* item is alive until insert or compact is called */
		return item;
	}
}

void
sml_tree_each(struct sml_tree *tree, void (*visit)(void *, void *), void *cls)
{
	USE_ITEM_OF(&tree->inst);
	struct node *node = tree->root, *prev = NULL;

	while (prev || node) {
		if (node) {
			node->back = prev;
			prev = node;
			node = node->child[LEFT];
		} else {
			node = prev;
			prev = node->back;
			visit(ITEM_OF(node), cls);
			node = node->child[RIGHT];
		}
	}
}

void
sml_tree_reject(struct sml_tree *tree, int (*reject)(void *))
{
	USE_ITEM_OF(&tree->inst);
	struct node **node = &tree->root, **prev = NULL;

	while (prev || *node) {
		if (*node) {
			(*node)->back = prev;
			prev = node;
			node = &((*node)->child[LEFT]);
			continue;
		}
		node = prev;
		prev = (*node)->back;
		if (!reject(ITEM_OF(*node))) {
			node = &((*node)->child[RIGHT]);
			continue;
		}
		node_reclaim(tree, *node);
		if ((*node)->child[LEFT] == NULL) {
			*node = (*node)->child[RIGHT];
		} else {
			*node = join(&tree->inst, *node);
			/* *node is already visited. Let's go right */
			node = &((*node)->child[RIGHT]);
		}
	}
}

void
sml_tree_rebuild(struct sml_tree *tree)
{
	struct node *node = tree->root, *prev = NULL, *last = NULL;
	tree->root = NULL;

	while (prev || node) {
		if (node) {
			node->back = prev;
			prev = node;
			node = node->child[LEFT];
		} else if (prev->child[RIGHT] && prev->child[RIGHT] != last) {
			node = prev->child[RIGHT];
		} else {
			last = prev;
			prev = prev->back;
			if (insert_node(tree, last) == 0)
				node_reclaim(tree, last);
		}
	}
}



#if 0  /** TEST CODE **/
#include <stdio.h>

static ATTR_UNUSED void
node_dump(const struct inst *inst, struct node *node, int indent)
{
	USE_ITEM_OF(inst);
	if (node == NULL)
		return;
	node_dump(inst, node->child[RIGHT], indent + 2);
	fprintf(stderr, "%*s%d\n", indent, "", *(int*)ITEM_OF(node));
	node_dump(inst, node->child[LEFT], indent + 2);
}
#define tree_dump(tree)  node_dump(&(tree)->inst, (tree)->root, 0)

#define CHECK(e) do { \
	if (!(e)) { \
		printf("%s:%d: CHECK failed: %s\n", __FILE__, __LINE__, #e); \
		abort(); \
	} \
} while (0)

static void
shuffle(int *ary, size_t len)
{
	size_t i, j;
	int tmp;
	for (i = len; i > 1; i--) {
		j = rand() % i;
		tmp = ary[i-1];
		ary[i-1] = ary[j];
		ary[j] = tmp;
	}
}

static int
cmp(const void *x, const void *y)
{
	return *(const int *)x - *(const int *)y;
}

static void
check1(void *p, void *cls)
{
	int *count = cls, *k = p;
	CHECK(*count == *k);
	*count += 1;
}

static void
check3(void *p, void *cls)
{
	int *count = cls, *k = p;
	CHECK(*count == *k);
	*count += 3;
}

static int
reject3(void *p)
{
	return *(int*)p % 3 != 0;
}

#define TESTSIZE  1024
#define ITERATE   4096

static void
modify(void *p, void *cls ATTR_UNUSED)
{
	int *n = p;
	*n = TESTSIZE - *n + 1;
	if (*n == TESTSIZE)
		*n = 1;
}

int
main()
{
	int input[TESTSIZE], count, *p;
	size_t i, j;
	sml_tree_t *tree;
	tree = sml_tree_new(cmp, sizeof(int));

	for (i = 0; i < TESTSIZE; i++)
		input[i] = i + 1;

	for (j = 0; j < ITERATE; j++) {
		/* insert 1..TESTSIZE at random */
		shuffle(input, TESTSIZE);
		for (i = 0; i < TESTSIZE; i++)
			sml_tree_insert(tree, &input[i]);

		/* search for 1..TESTSIZE at random */
		shuffle(input, TESTSIZE);
		for (i = 0; i < TESTSIZE; i++) {
			p = sml_tree_find(tree, &input[i]);
			CHECK(p != NULL);
			CHECK(p != &input[i]);
			CHECK(*p == input[i]);
		}

		/* check whether all inserted items are in the tree */
		count = 1;
		sml_tree_each(tree, check1, &count);
		CHECK(count == TESTSIZE + 1);

		/* check whether sml_tree_rebuild has no effect */
		sml_tree_rebuild(tree);
		shuffle(input, TESTSIZE);
		for (i = 0; i < TESTSIZE; i++) {
			p = sml_tree_find(tree, &input[i]);
			CHECK(p != NULL);
			CHECK(p != &input[i]);
			CHECK(*p == input[i]);
		}
		count = 1;
		sml_tree_each(tree, check1, &count);
		CHECK(count == TESTSIZE + 1);

		/* map i to TESTSIZE-i+1 and remove TESTSIZE */
		sml_tree_each(tree, modify, NULL);
		sml_tree_rebuild(tree);

		/* search for 1..TESTSIZE at random */
		shuffle(input, TESTSIZE);
		for (i = 0; i < TESTSIZE; i++) {
			p = sml_tree_find(tree, &input[i]);
			CHECK((p != NULL) == (input[i] != TESTSIZE));
			CHECK(p != &input[i]);
			CHECK(p == NULL || *p == input[i]);
		}

		/* remove all items except for multiples of 3 */
		sml_tree_reject(tree, reject3);
		sml_tree_compact(tree);

		/* search for 1..TESTSIZE at random */
		shuffle(input, TESTSIZE);
		for (i = 0; i < TESTSIZE; i++) {
			p = sml_tree_find(tree, &input[i]);
			CHECK((p != NULL) == (input[i] % 3 == 0
					      && input[i] != TESTSIZE));
			CHECK(p != &input[i]);
			CHECK(p == NULL || *p == input[i]);
		}

		/* check whether all multiples of 3 are in the tree */
		count = 3;
		sml_tree_each(tree, check3, &count);
		CHECK(count == ((TESTSIZE + 2) / 3) * 3);

		/* delete 1..TESTSIZE at random */
		shuffle(input, TESTSIZE);
		for (i = 0; i < TESTSIZE; i++) {
			p = sml_tree_delete(tree, &input[i]);
			CHECK((p != NULL) == (input[i] % 3 == 0));
			CHECK(p != &input[i]);
			CHECK(p == NULL || *p == input[i]);
		}

		/* check whether tree is empty */
		count = 0;
		sml_tree_each(tree, check1, &count);
		CHECK(count == 0);
	}

	sml_tree_destroy(tree);
	return 0;
}

#endif /** TEST CODE **/
