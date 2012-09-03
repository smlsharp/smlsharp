#ifndef SMLSHARP__HEAP_OTOMO_H__
#define SMLSHARP__HEAP_OTOMO_H__

struct _bitptr{
  unsigned int *cur;
  unsigned int mask;
};
typedef struct _bitptr bitptr;

#define THE_NUMBER_OF_FIXED_BLOCK 10
#define MAX_BITMAP_RANK 5

struct bitmap_info_space {
#ifdef UPPER
  struct bitmap_info_space *alloc_bitmap_info;
#endif /* UPPER */
  bitptr bitmap;
  void *next_obj;
  void *base;
  void *end;
  void *tree[MAX_BITMAP_RANK];
  int rank;
  void *obj_base;
  size_t block_size_log;
  size_t block_size_bytes;
};
extern struct bitmap_info_space bitmap_info[THE_NUMBER_OF_FIXED_BLOCK];

struct heap_bitmap_space {
  void *base;
  void *limit;
  unsigned int size;
};

/* Heap Space Layout:
 *
 *   <-----------             size          ---------------->
 *  +------------+---------+-----+-----------+---------------+
 *  |size 16 heap| size 32 | ... | size 8192 |   stack area  |
 *  +------------+---------+-----+-----------+---------------+
 *  ^                                        ^               ^
 * base                         (marking_stack.bottom)     limit
 *
 */

/* Size X Heap Space Layout: 
 *
 *                                              HEADER_SIZE + OFFSET
 *   <-----          bitmap_size          ----> <->
 *  +-------------+---------+---------+--------+---+---------------------+
 *  |bitmap  leaf | tree[0] | tree[1] | ...... |   |                     |
 *  +-------------+---------+---------+--------+---+---------------------+
 *  ^             ^         ^         ^         ^   ^                     ^
 * base         tree[0]   tree[1]  tree[2]     end obj_base    (next size base)
 *
 */

//extern struct heap_bitmap_space major_heap;
#define CLEAR_BITPTR(bp,start)			\
  do{							\
    (bp).mask = 0x01;					\
    (bp).cur = (start);					\
  }while(0)

//#define SET_BITPTR(bp) ((*((bp).cur)) |= ((bp).mask))

#define TEST_BITPTR(bp) ((*((bp).cur)) & ((bp).mask))

#define SUCC_BITPTR(bp)				\
  do{						\
    ((bp).mask) <<= 1;				\
    if((bp).mask == 0){				\
      ((bp).cur)++;				\
      (bp).mask = 0x01;				\
    }						\
  }while(0);

#define NEXT_BITPTR(mask,bitmap) ((mask) = ((~(bitmap)) & ((bitmap) + 1)))

#define NEXT_AND_SET_BITPTR(bp)						\
  do{									\
    unsigned int tmp = (*(bp.cur)) | ((bp).mask | ((bp).mask - 1));	\
    NEXT_BITPTR((bp).mask,tmp);						\
  }while(0)
  
// ALIGN with NEXT_AND_SET
#define ALIGN_BITPTR(bp_h,base_h,bp_l,base_l)				\
  do{									\
    unsigned int _tmp = ((bp_l).cur) - (unsigned int *)(base_l);	\
    (bp_h).cur = (unsigned int *)(base_h) + (_tmp >> 5);		\
    _tmp = (unsigned int)0x01 << (_tmp & 0x01f);		        \
    _tmp = *((bp_h).cur) | (_tmp | (_tmp- 1));				\
    NEXT_BITPTR((bp_h).mask,_tmp);					\
  }while(0)

// UPDATE with NEXT
#define UPDATE_BITPTR(bp_l,base_l,bp_u,base_u)			\
  do{									\
    unsigned int _res = (bp_u).mask - 1;				\
    COUNT_BITS(_res);							\
    (bp_l).cur = (unsigned int *)(base_l) +			\
      (((bp_u).cur - (unsigned int *)(base_u)) << 5) + _res;	\
    NEXT_BITPTR((bp_l).mask,*((bp_l).cur));			\
  }while(0)

#define ALLOC_SIZE_MIN       (OBJ_HEADER_SIZE + sizeof(void*))
//#define HEAP_ROUND_SIZE(sz)  ALIGN(sz,ALIGN(ALLOC_SIZE_MIN, MAXALIGN))
#define HEAP_ROUND_SIZE(sz)  (sz)
//#define HEAP_ROUND_BLOCK_SIZE(sz,bsz)  ALIGN(sz,bsz)

int sml_heap_check_obj(void*);
#ifdef PRINT_ALLOC_TIME
struct print_info_space {
  unsigned int block_size;
  int rank;
  int count_alloc;
  int count_search[MAX_BITMAP_RANK+2];
  int count_gc;
  int count_mark;
  int tmp_mark;
  int max_live;
  unsigned int total_size;
  double rate;
};
struct print_info_space print_info[THE_NUMBER_OF_FIXED_BLOCK];
#endif /* PRINT_ALLOC_TIME */

//#define MIN_BLOCK_SIZE 8
#define MAX_BLOCK_SIZE 4096

//void *heap_alloc(size_t alloc_size);
int search_bitptr(struct bitmap_info_space *b_info);

/*
 *                      16
 *        *<=* /                 *>*		\
 *            8                       32
 *        /      \           /                    \
 *      *8*     *16*       *32*                   256
 *                                      /                       \
 *                                     64                       1024
 *                                 /          \             /            \
 *                               *64*         128          512          2048
 *                                           /   \       /     \        /   \
 *                                        *128* *256*  *512* *1024*  *2048* *4096*
 */
#ifndef UPPER
#define MAPPING_HEAP_ALLOC(size_)			\
  ((size_ <= 16) ?					\
   ((size_ <= 8) ? bitmap_info : bitmap_info + 1 )	\
   : ((size_ <= 32) ? bitmap_info + 2			\
      : ((size_ <= 256) ?				\
	 ((size_ <= 64) ? bitmap_info + 3 		\
	  : ((size_ <= 128) ? bitmap_info + 4 : bitmap_info + 5 ))	\
	 : ((size_ <= 1024) ?						\
	    ((size_ <= 512) ? bitmap_info + 6 : bitmap_info + 7 )	\
	    : ((size_ <= 2048) ? bitmap_info + 8 : bitmap_info + 9)))))
#else /* UPPER */
#define MAPPING_HEAP_ALLOC(size_)			\
  ((size_ <= 16) ?					\
   ((size_ <= 8) ? (bitmap_info)->alloc_bitmap_info	\
    : (bitmap_info+1)->alloc_bitmap_info)			\
   : ((size_ <= 32) ? (bitmap_info+2)->alloc_bitmap_info		\
      : ((size_ <= 256) ?						\
	 ((size_ <= 64) ? (bitmap_info+3)->alloc_bitmap_info    	\
	  : ((size_ <= 128) ? (bitmap_info+4)->alloc_bitmap_info	\
	     : (bitmap_info+5)->alloc_bitmap_info))			\
	 : ((size_ <= 1024) ?						\
	    ((size_ <= 512) ? (bitmap_info+6)->alloc_bitmap_info	\
	     : (bitmap_info+7)->alloc_bitmap_info)			\
	    : ((size_ <= 2048) ? (bitmap_info+8)->alloc_bitmap_info	\
	       : (bitmap_info+9)->alloc_bitmap_info)))))
#endif /* UPPER */

#ifdef GCSTAT
void sml_heap_fast_alloced(struct bitmap_info_space *);
void sml_heap_find_alloced(struct bitmap_info_space *);
void sml_heap_malloced(size_t);
#define HEAP_IFGCSTAT(e) e
#else
#define HEAP_IFGCSTAT(e)
#endif /* GCSTAT */

#ifdef PRINT_ALLOC_TIME
extern size_t count_alloc,count_alloc_another;
#define HEAP_FAST_ALLOC(obj__,size_,IFFAIL)			\
  do{								\
    struct bitmap_info_space *b_info;				\
    								\
    /* ifdef PRINT_ALLOC_TIME */				\
    void* tmp_cur;						\
    unsigned int tmp_mask;					\
    								\
    if(size_ > MAX_BLOCK_SIZE) {					\
      obj__ = sml_obj_malloc(size_);					\
      if(obj__ != NULL) {						\
	count_alloc++;							\
	count_alloc_another++;						\
      }									\
    } else {								\
      b_info = MAPPING_HEAP_ALLOC(size_);				\
      									\
      /* ifdef PRINT_ALLOC_TIME */					\
      tmp_cur = b_info->bitmap.cur;					\
      tmp_mask = b_info->bitmap.mask;				\
      									\
      if((TEST_BITPTR(b_info->bitmap)) &&				\
	 (search_bitptr(b_info) == -1)) obj__ = IFFAIL;			\
      else {								\
	/* ifdef PRINT_ALLOC_TIME */					\
	if((tmp_cur == b_info->bitmap.cur)&&				\
	   (tmp_mask == b_info->bitmap.mask))			\
	  print_info[b_info - bitmap_info].count_search[0]++;		\
									\
	print_info[b_info - bitmap_info].count_alloc++;			\
	count_alloc++;							\
									\
	obj__ = b_info->next_obj;					\
	DBG(("find %u %p %x %p",size_,					\
	     b_info->bitmap.cur,b_info->bitmap.mask,obj__));		\
									\
	b_info->next_obj = (char *)(b_info->next_obj)			\
	  + b_info->block_size_bytes;					\
	/* SET_BITPTR(b_info->bitmap);*/				\
	SUCC_BITPTR(b_info->bitmap);					\
      }									\
      ASSERT(sml_heap_check_obj(obj__));				\
    }									\
  }while(0)
#else /* PRINT_ALLOC_TIME */
#define HEAP_FAST_ALLOC(obj__,size_,IFFAIL)			\
  do{								\
    struct bitmap_info_space *b_info;					\
    									\
    if(size_ > MAX_BLOCK_SIZE) {					\
      HEAP_IFGCSTAT(sml_heap_malloced(size_));				\
      obj__ = sml_obj_malloc(size_);					\
    } else {								\
      HEAP_IFGCSTAT(unsigned int testbit__);				\
      b_info = MAPPING_HEAP_ALLOC(size_);				\
      									\
      HEAP_IFGCSTAT(testbit__ = TEST_BITPTR(b_info->bitmap));	\
      if((TEST_BITPTR(b_info->bitmap)) &&				\
	 (search_bitptr(b_info) == -1)) obj__ = IFFAIL;			\
      else {								\
	HEAP_IFGCSTAT(testbit__ ? sml_heap_find_alloced(b_info)		\
		      : sml_heap_fast_alloced(b_info));			\
	obj__ = b_info->next_obj;					\
	DBG(("find %u %p %x %p",size_,					\
	     b_info->bitmap.cur,b_info->bitmap.mask,obj__));		\
									\
	b_info->next_obj = (char *)(b_info->next_obj)			\
	  + b_info->block_size_bytes;					\
	/* SET_BITPTR(b_info->bitmap);		*/		\
	SUCC_BITPTR(b_info->bitmap);					\
      }									\
      ASSERT(sml_heap_check_obj(obj__));				\
    }									\
  }while(0)
#endif /* PRINT_ALLOC_TIME */

#endif /* SMLSHARP__HEAP_OTOMO_H */
