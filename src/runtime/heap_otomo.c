/*
 * heap_otomo.c
 * @copyright (c) 2010, Tohoku University.
 * @author OTOMO Toshiaki
 * @version $Id: $
 */

#include <stdlib.h>
#include <string.h>
#include <math.h>
#include <inttypes.h>
#include "smlsharp.h"
#include "object.h"
#include "objspace.h"
#include "heap.h"
#include "heap_otomo.h"

#ifdef GCSTAT
#define GCTIME
#endif /* GCSTAT */

#if defined GCSTAT || defined GCTIME
#include <stdarg.h>
#include <stdio.h>
#include "timer.h"
static struct {
  FILE *file;
  size_t probe_threshold;
  unsigned int verbose;
  sml_timer_t exec_begin, exec_end;
  sml_time_t exec_time;
  struct gcstat_gc {
    unsigned int count;
    sml_time_t total_time;
    sml_time_t clear_time;
    unsigned long total_clear_bytes;
    unsigned long total_trace_count;
    unsigned long total_push_count;
  } gc;
  struct {
    unsigned int trigger;
    struct {
      unsigned int fast[THE_NUMBER_OF_FIXED_BLOCK];
      unsigned int find[THE_NUMBER_OF_FIXED_BLOCK];
      unsigned int malloc;
    } alloc_count;
    unsigned int trace_count;
    unsigned int push_count;
    size_t alloc_bytes;
    size_t clear_bytes;
  } last;
} gcstat;

#define clear_last_counts() \
	(memset(&gcstat.last, 0, sizeof(gcstat.last)))

#define GCSTAT_VERBOSE_GC      10
#define GCSTAT_VERBOSE_COUNT   20
#define GCSTAT_VERBOSE_HEAP    30
#define GCSTAT_VERBOSE_PROBE   40
#define GCSTAT_VERBOSE_MAX    100

static void (*stat_notice)(const char *format, ...) ATTR_PRINTF(1, 2) =
  sml_notice;

#if defined GCSTAT
static void
gcstat_print(const char *fmt, ...)
{
  va_list args;
  va_start(args, fmt);
  vfprintf(gcstat.file, fmt, args);
  fputs("\n", gcstat.file);
  va_end(args);
}

static void
print_alloc_count()
{
  unsigned int i;

  if (gcstat.verbose < GCSTAT_VERBOSE_COUNT)
    return;

  stat_notice("count:");
  for (i = 0; i < THE_NUMBER_OF_FIXED_BLOCK; i++) {
    if (gcstat.last.alloc_count.fast[i] != 0
	|| gcstat.last.alloc_count.find[i] != 0)
      stat_notice(" %lu: {fast: %u, find: %u}",
		  (unsigned long)bitmap_info[i].block_size_bytes,
		  gcstat.last.alloc_count.fast[i],
		  gcstat.last.alloc_count.find[i]);
  }
  if (gcstat.last.alloc_count.malloc > 0)
    stat_notice(" other: {malloc: %u}", gcstat.last.alloc_count.malloc);
}
#endif /* GCSTAT */
#endif /* GCSTAT || GCTIME */

#define ALIGN ALIGNSIZE

#define BITMAP_TYPE (sizeof(unsigned int))
#define SENTINEL BITMAP_TYPE

#define CAL_BLOCK_COUNTS(total,size)				\
  (unsigned int)(total / (size + sizeof(void *) + 0.13))

#define CAL_TOTAL_SIZE(_bitmap_size, _block_counts, _block_size)	\
  ((_block_counts) * (_block_size) +					\
   ALIGN((_bitmap_size) + OBJ_HEADER_SIZE, MAXALIGN))

#define CAL_BITMAP_SIZE(_block_counts)		\
  (BITMAP_ROUND(_block_counts) * BITMAP_TYPE +	\
   (((_block_counts) & 0x01f)? 0 : SENTINEL)) 

#define CAL_BITMAP_SENTINEL_MASK(_block_counts)	\
  (0xffffffff << ((_block_counts) & 0x01f))

#define BITMAP_ROUND(sz) ((sz + 31) >> 5)

struct bitmap_info_space bitmap_info[THE_NUMBER_OF_FIXED_BLOCK];
static struct heap_bitmap_space major_heap = {0,0,0};

struct marking_stack_space {
  void **top;
  void **bottom;
  void *limit;
  unsigned int size;
};
static struct marking_stack_space marking_stack = {0,0,0,0};

const size_t block_size[THE_NUMBER_OF_FIXED_BLOCK][2] = {
	{8,3},{16,4},{32,5},{64,6},{128,7},{256,8},
	{512,9},{1024,10},{2048,11},{4096,12}
    };

static struct heap_layout{
  size_t block_counts;
  size_t bitmap_size[MAX_BITMAP_RANK+1];
  unsigned int sentinel_mask[MAX_BITMAP_RANK+1];
  size_t bitmap_and_tree_size;
  int rank;
  size_t total_size;
}heap_layout[THE_NUMBER_OF_FIXED_BLOCK]={0};

#ifdef PRINT_ALLOC_TIME
#include <stdio.h>
#include <sys/time.h>
#include <sys/resource.h>
#define getRusage(tt_) do{					\
  struct rusage t_;						\
  struct timeval tv_;						\
  getrusage(RUSAGE_SELF,&t_);						\
  tv_ = t_.ru_utime;							\
    (tt_) = (tv_.tv_sec + (double)(tv_.tv_usec) * 1e-6);		\
  }while(0)

FILE *fp_at;
size_t count_flag=0, count_alloc=0, count_alloc_another=0,
    count_gc=0, count_outside=0, count_not_mark=0, count_call_mark=0, 
    live_max = 0, live_min = 0x7fffffff, live_all = 0, live_tmp = 0,
    arranged = 0;

#ifdef GC_TIME
int tmp_mark=0,tmp_alloc=0;
#endif /* GC_TIME */

double all_time_bit_clear = 0.0, all_time_gc = 0.0, init_time = 0.0;

void print_heap_layout(){
    int i,j;
    fprintf(fp_at,"****** major heap layout ******\n");
    fprintf(fp_at,"major heap base=%p, limit=%p, size=%u\n",
	    major_heap.base,major_heap.limit,major_heap.size);
    
    fprintf(fp_at,"+++ bitmap address (upon termination) +++\n");
    for(i=0;i<THE_NUMBER_OF_FIXED_BLOCK;i++)
    {
	fprintf(fp_at,"------------\n");
	fprintf(fp_at,"block_size=%u, block_size_log=%u, rank=%d\n",
		(bitmap_info+i)->block_size_bytes,
		(bitmap_info+i)->block_size_log,(bitmap_info+i)->rank);
	fprintf(fp_at,"rate = %0.3f,block_counts=%u, bitmap_and_tree=%u, total=%u\n",
		print_info[i].rate,
		heap_layout[i].block_counts, heap_layout[i].bitmap_and_tree_size,
		heap_layout[i].total_size);
	fprintf(fp_at,"bitmap_size=%u",heap_layout[i].bitmap_size[0]);
	for(j=1;j<heap_layout[i].rank;j++)
	  fprintf(fp_at,", tree[%d]=%u",j,heap_layout[i].bitmap_size[j]);
	fprintf(fp_at,"\n block_mask=%x",heap_layout[i].sentinel_mask[0]);
	for(j=1;j<heap_layout[i].rank;j++)
	  fprintf(fp_at,", mask[%d]=%u",j,heap_layout[i].sentinel_mask[j]);
	fprintf(fp_at,"\nbitmap_info=%p\nbase=%p, "
		,bitmap_info + i,(bitmap_info+i)->base);
	for(j=0;j<heap_layout[i].rank;j++)
	    fprintf(fp_at," tree[%d]=%p, ",j,(bitmap_info+i)->tree[j]);
	fprintf(fp_at,"end=%p\n",(bitmap_info+i)->end);
	fprintf(fp_at," bitmap.cur=%p, bitmap.mask=%x\n",j,(bitmap_info+i)->bitmap.cur,j,(bitmap_info+i)->bitmap.mask);
	fprintf(fp_at,"obj_base=%p, next_obj=%p\n",
		(bitmap_info+i)->obj_base,(bitmap_info+i)->next_obj);
	fprintf(fp_at,"\n");
    }

    fprintf(fp_at,"+++ marking stack +++\n");
    fprintf(fp_at,"marking stack bottom=%p, top=%p, limit=%p, size=%u\n",
	    marking_stack.bottom,marking_stack.top,
	    marking_stack.limit,marking_stack.size);
    fprintf(fp_at,"*********************************\n");
}

static void print_info_init()
{
  int i,j;
  for(i=0;i<THE_NUMBER_OF_FIXED_BLOCK;i++)
  {
      print_info[i].block_size = block_size[i][0];
      print_info[i].total_size = heap_layout[i].total_size;
      print_info[i].rank = heap_layout[i].rank;
      print_info[i].count_alloc = 0;
      for(j=0;j<(print_info[i].rank+2);j++)
	  print_info[i].count_search[j] = 0;
      print_info[i].count_gc = 0;
      print_info[i].count_mark = 0;
      print_info[i].tmp_mark = 0;
      print_info[i].max_live = 0;
   }
}

static void print_and_close_file()
{
  int i,j;
  size_t total_size = 0;
  size_t total_bitmap_size = 0;
  
  for(i=0;i<THE_NUMBER_OF_FIXED_BLOCK;i++){
      total_size += heap_layout[i].total_size;
      total_bitmap_size += heap_layout[i].bitmap_and_tree_size;
  }
  
  fprintf(fp_at,"\n");
 
//  print_heap_layout();

  fprintf(fp_at,"****** otomo gc alloc and gc infomation ****** \n");
  fprintf(fp_at,"stack and heap size %u(arranged heap size %u)\n",
	  total_size+marking_stack.size,arranged);
  fprintf(fp_at," total heap (with bitmap) size %u\n",total_size);
  fprintf(fp_at,"  heap size %u, bitmap size %u\n",
	  total_size-total_bitmap_size,total_bitmap_size);
  fprintf(fp_at," total stack  size %u\n",marking_stack.size);

  fprintf(fp_at,"all alloc \t%u\n",count_alloc);      
  /*
  for(i=0;i<THE_NUMBER_OF_FIXED_BLOCK;i++)
    {
      fprintf(fp_at," block size is %u (rank is %d)\n heap and bitmap size %u (%f[%%])\n"
	      ,print_info[i].block_size,print_info[i].rank
	      ,print_info[i].total_size
	      ,100.0 * (double)print_info[i].total_size / (double)total_size);

      fprintf(fp_at,"  alloc \t%u (%f[%%])\n",
	      print_info[i].count_alloc,
	      100.0*(double)print_info[i].count_alloc/(double)count_alloc); 
      if(print_info[i].count_alloc != 0)
	{
	  fprintf(fp_at,"   next bitptr \t%u \t%f\n"
		  ,print_info[i].count_search[0]
		  ,(double)100.0*(double)print_info[i].count_search[0]/(double)print_info[i].count_alloc);

	  fprintf(fp_at,"   search now bitptr \t%u \t%f\n"
		  ,print_info[i].count_search[1]
		  ,(double)100.0*(double)print_info[i].count_search[1]/(double)print_info[i].count_alloc);  
	
	  for(j=0;j<print_info[i].rank;j++)
	    fprintf(fp_at,"   search tree[%d] \t%u \t%f\n"
		    ,j+1,print_info[i].count_search[j+2]
		    ,100.0*(double)print_info[i].count_search[j+2]/(double)print_info[i].count_alloc);
	}
      fprintf(fp_at,"\n");
    }
  fprintf(fp_at," alloc another size\t%u\n\n",count_alloc_another);      
  
  fprintf(fp_at,"do_gc \t%u\n",count_gc);
  fprintf(fp_at," call mark function \t%u\n",count_call_mark);
  fprintf(fp_at,"  mark \t%u\n",count_call_mark - count_not_mark - count_outside);
  fprintf(fp_at,"  already marked \t%u\n",count_not_mark);
  fprintf(fp_at,"  outside \t%u\n\n",count_outside);

  for(i=0;i<THE_NUMBER_OF_FIXED_BLOCK;i++)
    {
      fprintf(fp_at,"block size is %u. GC invoked by this %u\n"
	      ,print_info[i].block_size,print_info[i].count_gc);
  
      if(count_gc != 0) {
	fprintf(fp_at," mark \t%u\n",print_info[i].count_mark);
	fprintf(fp_at," average mark \t%u\n"
		,print_info[i].count_mark/count_gc);
	fprintf(fp_at," max live \t%u\n",print_info[i].max_live);
      }
      fprintf(fp_at,"\n");
    }
*/
  
  fprintf(fp_at,"do gc \t%u\n",count_gc);
  if(count_gc != 0) {
    fprintf(fp_at,"all gc time \t%f\n",all_time_gc);
    fprintf(fp_at,"average gc time \t%f\n",all_time_gc/count_gc);
    fprintf(fp_at,"\n");
    fprintf(fp_at,"all : live obj[bytes]\t%u\n",live_all);
    fprintf(fp_at,"average : percent of live obj in heap \t%f\n"
	    ,100.0 * ((double)live_all / (double) count_gc) / (double)(total_size+marking_stack.size));
    fprintf(fp_at,"max : percent of live obj in heap \t%f \t(%u)\n"
	    ,100.0 * (double)live_max / (double)(total_size+marking_stack.size)
	    ,live_max);
    fprintf(fp_at,"min : percent of live obj in heap \t%f \t(%u)\n"
	    ,100.0 * (double)live_min / (double)(total_size+marking_stack.size)
	    ,live_min);
  }
  fprintf(fp_at,"\n");
  fprintf(fp_at,"all bit clear  time \t%f\n",all_time_bit_clear);
  if(count_gc != 0) fprintf(fp_at,"average bit clear time \t%f\n",all_time_bit_clear/count_gc);
  fprintf(fp_at,"\n");
  fprintf(fp_at,"otomo heap init time \t%f\n\n",init_time);
  
  fprintf(fp_at,"total size %u\n",total_size+marking_stack.size);
  fprintf(fp_at,"all alloc \t%u \t(outside \t%u)\n"
	  ,count_alloc, count_alloc_another);      
  fprintf(fp_at,"do gc \t%u\n",count_gc);
  fprintf(fp_at,"size  \t alloc \t max live \tinvoked\n");
  for(i=0;i<THE_NUMBER_OF_FIXED_BLOCK;i++)
    fprintf(fp_at," %u \t%u \t%u \t%u\n",
	    print_info[i].block_size,
	    print_info[i].count_alloc,
	    print_info[i].max_live,
	    print_info[i].count_gc); 

  if(fp_at != stderr) fclose(fp_at);
}
#endif /* PIRINT_ALLOOC_TIME */

#ifdef CHECK
static void
clear_heap(void)
{
  bitptr b;
  char *p;
  int i;
  for (i = 0; i < THE_NUMBER_OF_FIXED_BLOCK; i++) {
    b = bitmap_info[i].bitmap;
    p = bitmap_info[i].obj_base;
    while ((char *)b.cur < (char *)bitmap_info[i].tree[0]) {
      if(!TEST_BITPTR(b)) {
        size_t j;
        for (j = 0; j < bitmap_info[i].block_size_bytes; j++)
	  (p - OBJ_HEADER_SIZE)[j] = 0x55;
      }
      SUCC_BITPTR(b);
      p += bitmap_info[i].block_size_bytes;
    }
  }
}
#endif /* CHECK */

#define COUNT_BITS(_bits)						\
  do{									\
    (_bits) = ((_bits) & 0x55555555) + ((_bits) >> 1 & 0x55555555);	\
    (_bits) = ((_bits) & 0x33333333) + ((_bits) >> 2 & 0x33333333);	\
    (_bits) = ((_bits) & 0x0f0f0f0f) + ((_bits) >> 4 & 0x0f0f0f0f);	\
    (_bits) = ((_bits) & 0x00ff00ff) + ((_bits) >> 8 & 0x00ff00ff);	\
    (_bits) = ((_bits) & 0x0000ffff) + ((_bits) >>16 & 0x0000ffff);	\
  }while(0)

#define IS_IN_HEAP_SPACE(ptr)				\
  ((char*)major_heap.base <= (char*)(ptr)		\
   && (char*)(ptr) < (char*)major_heap.limit)

void
heap_layout_init(size_t size)
{
    int i,j;
    size_t tmp,tmp2;

    double rate[THE_NUMBER_OF_FIXED_BLOCK] =
	{0.15,0.25,0.25,0.15,0.05,0.05,0.025,0.025,0.025,0.025};

    char *s,*e;
    long n;
    s = getenv("SMLSHARP_HEAPLAYOUT");
    if(s)
	for(i=0;i<THE_NUMBER_OF_FIXED_BLOCK;i++) {
	    n = strtol(s,&s,10);
	    if(n > 0)
		rate[i] = (double)n / 1000.0;
#ifdef PRINT_ALLOC_TIME
	    print_info[i].rate = rate[i];
#endif /* PRINT_ALLOC_TIME */
	    s++;
	}
#ifdef PRINT_ALLOC_TIME
    else {
	for(i=0;(i<THE_NUMBER_OF_FIXED_BLOCK);i++)
	    print_info[i].rate = rate[i];
    }
#endif /* PRINT_ALLOC_TIME */
	    

    for(i=0;i<THE_NUMBER_OF_FIXED_BLOCK;i++)
    {
	heap_layout[i].block_counts = 
	    CAL_BLOCK_COUNTS(((double)size * rate[i]), block_size[i][0]);
	
	heap_layout[i].rank=-1;
	tmp = heap_layout[i].block_counts;
	tmp2 = tmp + 31;
	j=0;
	
	do{
	  heap_layout[i].bitmap_size[j] = CAL_BITMAP_SIZE(tmp);
	  heap_layout[i].bitmap_and_tree_size += heap_layout[i].bitmap_size[j];
	  heap_layout[i].sentinel_mask[j] = CAL_BITMAP_SENTINEL_MASK(tmp);
	  tmp = BITMAP_ROUND(tmp);
	  tmp2 >>=5;
	  j++;
	  heap_layout[i].rank++;
	}while((tmp2 > 0)&&(heap_layout[i].rank < MAX_BITMAP_RANK));

	heap_layout[i].total_size = 
	    CAL_TOTAL_SIZE(heap_layout[i].bitmap_and_tree_size,
			   heap_layout[i].block_counts,block_size[i][0]);

    }
}

void
bitmap_clear(struct bitmap_info_space *b_info,unsigned int index)
{    
#ifndef NOT_CLEAR_BITMAP
  /* clear bitmap */
  memset(b_info->base,0,heap_layout[index].bitmap_and_tree_size);
#ifdef GCSTAT
  gcstat.last.clear_bytes += heap_layout[index].bitmap_and_tree_size;
#endif /* GCSTAT */
#endif /* NOT_CLEAR_BITMAP */

  /* clear bitptr */
  CLEAR_BITPTR(b_info->bitmap, b_info->base);
  
  b_info->next_obj = b_info->obj_base;
  
#ifdef UPPER
  b_info->alloc_bitmap_info = b_info;
#endif /* UPPER */

  int i;
  for(i=0;i<b_info->rank;i++)
    ((unsigned int *)b_info->tree[i])[-1] = heap_layout[index].sentinel_mask[i];
    
  ((unsigned int *)b_info->end)[-1] = heap_layout[index].sentinel_mask[i];
}

static void
all_bitmaps_space_clear()
{
    unsigned int i;
    
    for(i=0;i<THE_NUMBER_OF_FIXED_BLOCK;i++)
      bitmap_clear(bitmap_info + i,i);
}

void *
make_bitmap_information (size_t size)
{
  char *next_block = major_heap.base;
  int i,j;
 
  heap_layout_init(size);
 
  for(i=0;i<THE_NUMBER_OF_FIXED_BLOCK;i++)
  {
      bitmap_info[i].block_size_bytes = block_size[i][0];
      bitmap_info[i].block_size_log = block_size[i][1];
      bitmap_info[i].rank = heap_layout[i].rank;
      bitmap_info[i].base = (void *)next_block;
      bitmap_info[i].end = next_block + heap_layout[i].bitmap_and_tree_size;
      bitmap_info[i].obj_base =
	next_block + 
	ALIGN(heap_layout[i].bitmap_and_tree_size + OBJ_HEADER_SIZE, MAXALIGN);
      bitmap_info[i].tree[0] = next_block + heap_layout[i].bitmap_size[0];
      for(j=1;j < bitmap_info[i].rank;j++)
	  bitmap_info[i].tree[j] = bitmap_info[i].tree[j-1] + 
	    heap_layout[i].bitmap_size[j]; 
      next_block += ALIGN(heap_layout[i].total_size, MAXALIGN);
      DBG(("BLOCK_SIZE %u TOTAL_SIZE %u BITMAP_SIZE %u"
	   ,block_size[i][0],heap_layout[i].total_size
	   ,heap_layout[i].bitmap_and_tree_size));
      DBG(("size %u base %p tree %p tree2 %p end %p obj %p",
	   bitmap_info[i].block_size_bytes,bitmap_info[i].base,
	   bitmap_info[i].tree[0],bitmap_info[i].tree[1],
	   bitmap_info[i].end,bitmap_info[i].obj_base));
  }

  all_bitmaps_space_clear();

  return next_block;
}

static void *
marking_stack_init(void *bottom)
{
  marking_stack.bottom = bottom;

  unsigned int i,tmp = 0;
  for(i=0;i<THE_NUMBER_OF_FIXED_BLOCK;i++)
      tmp += heap_layout[i].block_counts;

  marking_stack.size = tmp * sizeof(void *);
  
  marking_stack.top = marking_stack.bottom;
  marking_stack.limit = (char *)marking_stack.bottom + marking_stack.size;
  ASSERT((char *)marking_stack.top < (char *)marking_stack.limit);
  
  return  marking_stack.limit;
}

#ifdef GCSTAT
static void
print_heap_occupancy()
{
  unsigned int i;

  if (gcstat.verbose < GCSTAT_VERBOSE_HEAP)
    return;

  stat_notice("heap:");
  for (i = 0; i < THE_NUMBER_OF_FIXED_BLOCK; i++) {
    unsigned int count = 0;
    unsigned long filled = 0;
    struct bitmap_info_space *b_info = &bitmap_info[i];
    char *end = (char*)bitmap_info[i].obj_base
      + (heap_layout[i].block_counts << bitmap_info[i].block_size_log);
    char *p = b_info->obj_base;
    bitptr b, b_end = b_info->bitmap;
    if (b_end.mask == 0) b_end.mask = ~0U;
    CLEAR_BITPTR(b, b_info->base);
    while (p < end) {
      if (b.cur < b_end.cur || (b.cur == b_end.cur && b.mask < b_end.mask)
	  || TEST_BITPTR(b))
	count++, filled += OBJ_TOTAL_SIZE(p);
      SUCC_BITPTR(b);
      p += b_info->block_size_bytes;
    }
    stat_notice(" %lu:", (unsigned long)b_info->block_size_bytes);
    stat_notice("  - {filled: %lu, count: %u, used: %u}",
		filled, count, count << bitmap_info[i].block_size_log);
  }
}
#endif /* GCSTAT */

static void
heap_space_clear()
{
  major_heap.limit = (char *)major_heap.base + major_heap.size;
  ASSERT(major_heap.base < major_heap.limit);

}

void *
sml_heap_thread_init()
{
	return NULL;
}

void
sml_heap_thread_free(void *data ATTR_UNUSED)
{
}

void
sml_heap_init(size_t size, size_t max_size ATTR_UNUSED)
{
#ifdef PRINT_ALLOC_TIME
    arranged = size;
    
    double st;
    getRusage(st);
#endif /* PRINT_ALLOC_TIME */

  void *stack_bottom;
  
#ifdef GCSTAT
  {
    const char *env;
    env = getenv("SMLSHARP_GCSTAT_FILE");
    if (env) {
      gcstat.file = fopen(env, "w");
      if (gcstat.file == NULL) {
	perror("sml_heap_init");
	abort();
      }
      stat_notice = gcstat_print;
    }
    env = getenv("SMLSHARP_GCSTAT_VERBOSE");
    if (env)
      gcstat.verbose = strtol(env, NULL, 10);
    else
      gcstat.verbose = GCSTAT_VERBOSE_MAX;
    env = getenv("SMLSHARP_GCSTAT_PROBE");
    if (env) {
      gcstat.probe_threshold = strtol(env, NULL, 10);
      if (gcstat.probe_threshold == 0)
	gcstat.probe_threshold = size;
    } else {
      gcstat.probe_threshold = 2 * 1024 * 1024;
    }
  }
#endif /* GCSTAT */

#ifdef GCTIME
  sml_timer_now(gcstat.exec_begin);
#endif /* GCTIME */

  major_heap.base = xmalloc(size);
  major_heap.size = size;
  heap_space_clear();
  stack_bottom = make_bitmap_information(size);
  
  if((char *)marking_stack_init(stack_bottom) >= (char *)major_heap.limit)
      sml_fatal(0,"heap size over");
  
  DBG(("heap space init %p %p %u",major_heap.base,major_heap.limit,major_heap.size));

#ifdef PRINT_ALLOC_TIME
  double en;
  getRusage(en);
  init_time = (en - st);

  fp_at = stderr;
  if(fp_at == NULL) sml_fatal(0,"can not open print alloc file");
  print_info_init();
#endif /* PRINT_ALLOC_TIME */

#ifdef GCSTAT
  {
    unsigned int i;
    stat_notice("---");
    stat_notice("event: init");
    stat_notice("time: 0.0");
    stat_notice("heap_size: %lu", (unsigned long)size);
    stat_notice("config:");
    for (i = 0; i < THE_NUMBER_OF_FIXED_BLOCK; i++)
      stat_notice(" %lu: {size: %lu, num_slots: %lu, bitmap_size: %lu}",
		  (unsigned long)bitmap_info[i].block_size_bytes,
		  (unsigned long)heap_layout[i].total_size,
		  (unsigned long)heap_layout[i].block_counts,
		  (unsigned long)heap_layout[i].bitmap_and_tree_size);
    stat_notice("stack_size: %lu", (unsigned long)marking_stack.size);
    stat_notice("counters:");
    stat_notice(" heap: [fast, find, next, new]");
    stat_notice(" other: [malloc]");
    print_heap_occupancy();
  }
#endif /* GCSTAT */
}

void
sml_heap_free()
{
#ifdef PRINT_ALLOC_TIME
  print_and_close_file();
#endif /* PRINT_ALLOC_TIME */

  free(major_heap.base);

#ifdef GCTIME
  sml_timer_now(gcstat.exec_end);
  sml_timer_dif(gcstat.exec_begin, gcstat.exec_end, gcstat.exec_time);
#endif /* GCTIME */
#if defined GCSTAT || defined GCTIME
#ifdef GCSTAT
  stat_notice("---");
  stat_notice("event: finish");
  stat_notice("time: "TIMEFMT, TIMEARG(gcstat.exec_time));
  print_alloc_count();
#endif /* GCSTAT */
  stat_notice("exec time      : "TIMEFMT" #sec",
	      TIMEARG(gcstat.exec_time));
  stat_notice("gc count       : %u #times", gcstat.gc.count);
  stat_notice("gc time        : "TIMEFMT" #sec (%4.2f%%)",
	      TIMEARG(gcstat.gc.total_time),
	      TIMEFLOAT(gcstat.gc.total_time) / TIMEFLOAT(gcstat.exec_time)
	      * 100.0f);
  stat_notice("avg gc time    : %.6f #sec",
	      TIMEFLOAT(gcstat.gc.total_time) / (double)gcstat.gc.count);
//#ifdef GCSTAT
  stat_notice("clear time     : "TIMEFMT" #sec (%4.2f%%)",
	      TIMEARG(gcstat.gc.clear_time),
	      TIMEFLOAT(gcstat.gc.clear_time) / TIMEFLOAT(gcstat.gc.total_time)
	      * 100.0f);
  stat_notice("avg clear time : %.6f #sec",
	      TIMEFLOAT(gcstat.gc.clear_time) / (double)gcstat.gc.count);

#ifdef GCSTAT
  if (gcstat.file)
	  fclose(gcstat.file);
#endif /* GCSTAT */
#endif /* GCSTAT || GCTIME */
}

#ifdef MULTITHREAD
void
sml_heap_thread_stw_hook(void *data ATTR_UNUSED)
{
}
#endif /* MULTITHREAD */

#define mark_children(obj)  sml_obj_enum_ptr(obj, mark)

#define FROM_HEAP_TO_BITMAP(info,p)					\
  ((unsigned int)((char *)(p) - ((char *)(info)->obj_base))		\
   >> (info)->block_size_log)

#ifdef PRINT_ALLOC_TIME
/*
 *               64_obj_base
 *        *<* /                   *>=* \
 *          16                         256
 *     /         \           /                       \
 *     8         32         128                    4096 
 *   /   \      /   \      /   \          /                     \
 * *out* *8*  *16* *32* *64*  *128*     1024                  heap_limit
  *                                  /         \               /         \ 
 *                                 512        2048          *4096*      *out*
 *                                /    \    /       \       
 *                              *256* *512* *1024* *2048*
 *
 */
#define MAPPING_HEAP_MARK(obj_,b_info_,slot,OUTSIDE)	\
  do{							\
    if((obj_) < bitmap_info[3].obj_base) {		\
      if((obj_) < bitmap_info[1].obj_base) {		\
	if((obj_) < bitmap_info[0].obj_base) {		\
	  count_outside++;				\
	  DBG(("%p at %p outside", (obj_), slot));	\
	  OUTSIDE(obj_);				\
	} else						\
	  (b_info_) = bitmap_info;			\
      } else {						\
	if((obj_) < bitmap_info[2].obj_base)		\
	  (b_info_) = bitmap_info + 1;			\
	else (b_info_) = bitmap_info + 2;		\
      }							\
    } else {						\
      if((obj_) < bitmap_info[5].obj_base) {		\
	if((obj_) < bitmap_info[4].obj_base)		\
	  (b_info_) = bitmap_info + 3;			\
	else (b_info_) = bitmap_info + 4;		\
      } else {						\
	if((obj_) < bitmap_info[9].obj_base) {		\
	  if((obj_) < bitmap_info[7].obj_base) {	\
	    if((obj_) < bitmap_info[6].obj_base) 	\
	      (b_info_) = bitmap_info + 5;		\
	    else (b_info_) = bitmap_info + 6;		\
	  } else {					\
	    if((obj_) < bitmap_info[8].obj_base) 	\
	      (b_info_) = bitmap_info + 7;		\
	    else (b_info_) = bitmap_info + 8;		\
	  }						\
	} else {					\
	  if((obj_) < major_heap.limit)			\
	    (b_info_) = bitmap_info + 9;		\
	  else {					\
	    count_outside++;				\
	    DBG(("%p at %p outside", (obj_), slot));	\
	    OUTSIDE(obj_);				\
	  }						\
	}						\
      }							\
    }							\
  }while(0)
#else /* PRINT_ALLOC_TIME */
#define MAPPING_HEAP_MARK(obj_,b_info_,slot,OUTSIDE)	\
  do{							\
    if((obj_) < bitmap_info[3].obj_base) {		\
      if((obj_) < bitmap_info[1].obj_base) {		\
	if((obj_) < bitmap_info[0].obj_base) {		\
	  DBG(("%p at %p outside", (obj_), slot));	\
	  OUTSIDE(obj_);				\
	} else						\
	  (b_info_) = bitmap_info;			\
      } else {						\
	if((obj_) < bitmap_info[2].obj_base)		\
	  (b_info_) = bitmap_info + 1;			\
	else (b_info_) = bitmap_info + 2;		\
      }							\
    } else {						\
      if((obj_) < bitmap_info[5].obj_base) {		\
	if((obj_) < bitmap_info[4].obj_base)		\
	  (b_info_) = bitmap_info + 3;			\
	else (b_info_) = bitmap_info + 4;		\
      } else {						\
	if((obj_) < bitmap_info[9].obj_base) {		\
	  if((obj_) < bitmap_info[7].obj_base) {	\
	    if((obj_) < bitmap_info[6].obj_base) 	\
	      (b_info_) = bitmap_info + 5;		\
	    else (b_info_) = bitmap_info + 6;		\
	  } else {					\
	    if((obj_) < bitmap_info[8].obj_base) 	\
	      (b_info_) = bitmap_info + 7;		\
	    else (b_info_) = bitmap_info + 8;		\
	  }						\
	} else {					\
	  if((obj_) < (void *)marking_stack.bottom)	\
	    (b_info_) = bitmap_info + 9;		\
	  else {					\
	    DBG(("%p at %p outside", (obj_), slot));	\
	    OUTSIDE(obj_);				\
	  }						\
	}						\
      }							\
    }							\
  }while(0)
#endif /* PRINT_ALLOC_TIME */

int sml_heap_check_obj(void*obj)
{
  struct bitmap_info_space *b_info;

#define OUTSIDE(obj)  return 0;
  MAPPING_HEAP_MARK(obj,b_info,&obj,OUTSIDE);
#undef OUTSIDE

  if (obj < b_info->obj_base) {
    DBG(("obj %p < obj_base %p", obj, b_info->obj_base));
    return 0;
  }
  
  if(b_info != (bitmap_info + (THE_NUMBER_OF_FIXED_BLOCK-1))) {
    if (obj >= (b_info + 1)->base) {
      DBG(("obj %p >=  (next block size).base%p", obj, (b_info + 1)->base));
      return 0;
    }
  } else {
    if (obj >= (void *)marking_stack.bottom) {
      DBG(("obj %p >= marking_stack.bottom %p", obj, marking_stack.bottom));
      return 0;
    }
  }
  return 1;   
}

static int
is_marked(void *obj)
{
  struct bitmap_info_space *b_info;
  unsigned int tmp,tmp_index;
  unsigned int *tmp_bitmap;
  
#define OUTSIDE(obj) return 0
  MAPPING_HEAP_MARK(obj,b_info,&obj,OUTSIDE);
#undef OUTSIDE

  tmp = FROM_HEAP_TO_BITMAP(b_info,obj);
  tmp_index = tmp >> 5;
  tmp_bitmap = (unsigned int *)b_info->base + tmp_index;
  tmp = (unsigned int)0x01 << (tmp & 0x0000001f);

  return (*tmp_bitmap & tmp);
}

static void mark(void **slot);

static void
trace_outside(void *obj)
{
	if (obj != NULL)
		sml_trace_ptr(obj);
}

static void
mark(void **slot)
{
  struct bitmap_info_space *b_info;
  unsigned int obj_size, alloc_size;
  unsigned int tmp,tmp_index;
  unsigned int *tmp_bitmap;
  void *obj = *slot;

#ifdef PRINT_ALLOC_TIME
  count_call_mark++;
#endif /* PRINT_ALLOC_TIME */    
  
#define OUTSIDE(obj)  do{trace_outside(obj); return;}while(0)
  MAPPING_HEAP_MARK(obj,b_info,slot,OUTSIDE);
#undef OUTSIDE
  
  //marked check and mark
  tmp = FROM_HEAP_TO_BITMAP(b_info,obj);
  tmp_index = tmp >> 5;
  tmp_bitmap = (unsigned int *)b_info->base + tmp_index;
  tmp = (unsigned int)0x01 << (tmp & 0x0000001f);

#ifdef GCSTAT
  gcstat.last.trace_count++;
#endif /* GCSTAT */
  if(*tmp_bitmap & tmp) {
    DBG(("%p at %p already marked", obj, slot));
#ifdef PRINT_ALLOC_TIME
    count_not_mark++;
#endif /* PRINT_ALLOC_TIME */
    return;    
  }
  
  *tmp_bitmap |= tmp; //mark
  
  //tree check
  unsigned int i;
  for(i=0;(*tmp_bitmap == 0xffffffff)&&(i < b_info->rank);i++){   
    tmp = ((unsigned int)0x01 << (tmp_index & 0x0000001f));
    tmp_index >>= 5;
    tmp_bitmap = (unsigned int *)b_info->tree[i] + tmp_index;
    *tmp_bitmap |= tmp;
  }
  
  DBG(("%p at %p mark (%"PRIuMAX", %"PRIuMAX")",
       obj, slot, (intmax_t)obj_size, (intmax_t)alloc_size));
  
#ifdef PRINT_ALLOC_TIME
  print_info[b_info - bitmap_info].count_mark++;
  live_tmp += HEAP_ROUND_SIZE(OBJ_TOTAL_SIZE(obj));
#endif /* PRINT_ALLOC_TIME */
  
  /* STACK_PUSH */
  (*(marking_stack.top)) = obj;  
  marking_stack.top++;  

#ifdef GCSTAT
  gcstat.last.push_count++;
#endif /* GCSTAT */
}

static void
mark_all(void **slot)
{
  mark(*slot);
  
  /* STACK POP */
  while (marking_stack.bottom != marking_stack.top){
      marking_stack.top--;
      mark_children((*(marking_stack.top)));
  }
}

static void
bitmap_dump(struct bitmap_info_space *b_info)
{
  unsigned int *tmp = (unsigned int *)b_info->base;
  
  sml_debug("bitmap dump start %p %u\n",b_info,b_info->block_size_log);
  while((char *)tmp < (char *)b_info->tree[0]) {
    sml_debug("%x",*tmp);
    tmp++;
  }
  sml_debug("tree dump\n");

  while((char *)tmp < (char *)b_info->end) {
    sml_debug("%x",*tmp);
    tmp++;
  }
  sml_debug("bitmap dump end\n");
  return;
}

static void
all_bitmaps_dump()
{
  unsigned int i;
  
  for(i=0;i<THE_NUMBER_OF_FIXED_BLOCK;i++)
    bitmap_dump(bitmap_info + i);
}

void
sml_heap_gc(void)
{
#ifdef GCTIME
  sml_timer_t b_start, b_end;
  sml_time_t gctime;
//#endif /* GCTIME */
//#ifdef GCSTAT
  sml_time_t cleartime,t;
  sml_timer_t b_cleared;
#endif /* GCSTAT */

#ifdef GCSTAT
  if (gcstat.verbose >= GCSTAT_VERBOSE_COUNT) {
    stat_notice("---");
    stat_notice("event: start gc");
    if (gcstat.last.trigger)
      stat_notice("trigger: %u", gcstat.last.trigger);
    print_alloc_count();
    print_heap_occupancy();
  }
  clear_last_counts();
#endif /* GCSTAT */

  DBG(("start gc"));

#ifdef GCTIME
  gcstat.gc.count++;
  sml_timer_now(b_start);
#endif /* GCTIME */

#ifdef PRINT_ALLOC_TIME
  live_tmp = 0;
  count_gc++;
  double st;
  getRusage(st);
#endif /* PRINT_ALLOC_TIME */

  all_bitmaps_space_clear();

#ifdef GCTIME//GCSTAT
	sml_timer_now(b_cleared);
#endif /* GCSTAT */

#ifdef PRINT_ALLOC_TIME
  double en;
  getRusage(en);
  all_time_bit_clear += (en - st);
#endif /* PRINT_ALLOC_TIME */
  
  /* mark root objects */
  sml_rootset_enum_ptr(mark, MAJOR);
  
  DBG(("marking root objects completed"));
  
  /* STACK POP */
  while (marking_stack.bottom != marking_stack.top){
      marking_stack.top--;
      mark_children((*(marking_stack.top)));
  }

  sml_malloc_pop_and_mark(mark_all, MAJOR);

  DBG(("marking completed"));

#ifdef CHECK
  clear_heap();
#endif /* CHECK */

  /* check finalization */
  sml_check_finalizer(mark_all, MAJOR);

  /* sweep malloc heap */
  sml_malloc_sweep(MAJOR);
  
#ifdef GCTIME
  sml_timer_now(b_end);
#endif /* GCTIME */

  DBG(("gc finished."));

#ifdef GCTIME
  sml_timer_dif(b_start, b_end, gctime);
  sml_time_accum(gctime, gcstat.gc.total_time);
  sml_timer_dif(b_start, b_cleared, cleartime);
  sml_time_accum(cleartime, gcstat.gc.clear_time);
#endif
#ifdef GCSTAT
  if (gcstat.verbose >= GCSTAT_VERBOSE_GC) {
    sml_timer_dif(gcstat.exec_begin, b_start, t);
    stat_notice("time: "TIMEFMT, TIMEARG(t));
    stat_notice("---");
    stat_notice("event: end gc");
    sml_timer_dif(gcstat.exec_begin, b_end, t);
    stat_notice("time: "TIMEFMT, TIMEARG(t));
    stat_notice("duration: "TIMEFMT, TIMEARG(gctime));
    stat_notice("clear_time: "TIMEFMT, TIMEARG(cleartime));
    stat_notice("clear_bytes: %lu", gcstat.last.clear_bytes);
    stat_notice("push: %u", gcstat.last.push_count);
    stat_notice("trace: %u", gcstat.last.trace_count);
    print_heap_occupancy();
  }
#endif /* GCSTAT */

#ifdef PRINT_ALLOC_TIME
  if(live_tmp > live_max) live_max = live_tmp;
  if(live_tmp < live_min) live_min = live_tmp;
  live_all += live_tmp;

  unsigned int i;
  for(i=0;i<THE_NUMBER_OF_FIXED_BLOCK;i++) {
      if(((print_info[i].count_mark - print_info[i].tmp_mark) * print_info[i].block_size)
	 > print_info[i].max_live)
	print_info[i].max_live = 
	      ((print_info[i].count_mark - print_info[i].tmp_mark) * print_info[i].block_size);
      print_info[i].tmp_mark=print_info[i].count_mark;
  }
#endif /* PRINT_ALLOC_TIME */
  
  /* start finalizers */
  sml_run_finalizer(NULL);
}

#ifdef GCSTAT
static void
gcstat_alloc_count(unsigned int *counter, size_t size)
{
	sml_timer_t b;
	sml_time_t t;

	gcstat.last.alloc_bytes += size;
	if (gcstat.last.alloc_bytes > gcstat.probe_threshold
	    && gcstat.verbose >= GCSTAT_VERBOSE_PROBE) {
		sml_timer_now(b);
		sml_timer_dif(gcstat.exec_begin, b, t);
		stat_notice("---");
		stat_notice("event: probe");
		stat_notice("time: "TIMEFMT, TIMEARG(t));
		print_alloc_count();
		print_heap_occupancy();
		clear_last_counts();
	}
	(*counter)++;
}

void
sml_heap_fast_alloced(struct bitmap_info_space *b_info)
{
  gcstat_alloc_count(&gcstat.last.alloc_count.fast[b_info - bitmap_info],
		     b_info->block_size_bytes);
}

void
sml_heap_find_alloced(struct bitmap_info_space *b_info)
{
  gcstat_alloc_count(&gcstat.last.alloc_count.find[b_info - bitmap_info],
		     b_info->block_size_bytes);
}

void
sml_heap_malloced(size_t size)
{
  gcstat_alloc_count(&gcstat.last.alloc_count.malloc, size);
}
#endif /* GCSTAT */

int
search_bitptr(struct bitmap_info_space *b_info)
{
#ifdef PRINT_ALLOC_TIME
  count_flag=0;
#endif /* PRINT_ALLOC_TIME */
  
  NEXT_AND_SET_BITPTR(b_info->bitmap);

  if(b_info->bitmap.mask == 0x0) {
    bitptr node;
    ALIGN_BITPTR(node,b_info->tree[0],b_info->bitmap,b_info->base);
    
#ifdef PRINT_ALLOC_TIME
    count_flag = 1;
#endif /* PRINT_ALLOC_TIME */
    
    if(node.mask == 0x0) {
      if(b_info->rank == 1) return -1;
      bitptr node2;
      ALIGN_BITPTR(node2,b_info->tree[1],node,b_info->tree[0]); 
      
#ifdef PRINT_ALLOC_TIME
      count_flag = 2;
#endif /* PRINT_ALLOC_TIME */
      
      if(node2.mask == 0x0) {
	if(b_info->rank == 2) return -1;
	bitptr node3;
	ALIGN_BITPTR(node3,b_info->tree[2],node2,b_info->tree[1]); 
	
#ifdef PRINT_ALLOC_TIME
	count_flag = 3;
#endif /* PRINT_ALLOC_TIME */

	if(node3.mask == 0x0) {
	  if(b_info->rank == 3) return -1;
	  bitptr node4;
	  ALIGN_BITPTR(node4,b_info->tree[3],node3,b_info->tree[2]); 
	  
#ifdef PRINT_ALLOC_TIME
	  count_flag = 4;
#endif /* PRINT_ALLOC_TIME */
	  
	  if(node4.mask == 0x0) {
	    if(b_info->rank == 4) return -1;
	    bitptr node5;
	    ALIGN_BITPTR(node5,b_info->tree[4],node4,b_info->tree[3]); 
	    
#ifdef PRINT_ALLOC_TIME
	    count_flag = 5;
#endif /* PRINT_ALLOC_TIME */

	    while(node5.mask == 0x0) //rank==5
	      {
		node5.cur++;
		if((char *)(node5.cur) >= (char *)(b_info->end)) return -1;
		NEXT_BITPTR(node5.mask,*(node5.cur));
	      }
	    
	    UPDATE_BITPTR(node4,b_info->tree[3],node5,b_info->tree[4]);
	  }
	  
	  UPDATE_BITPTR(node3,b_info->tree[2],node4,b_info->tree[3]);
	}

	UPDATE_BITPTR(node2,b_info->tree[1],node3,b_info->tree[2]);
      }

      UPDATE_BITPTR(node,b_info->tree[0],node2,b_info->tree[1]);
    }
    
    UPDATE_BITPTR(b_info->bitmap,b_info->base,node,b_info->tree[0]);
  }
  
#ifdef PRINT_ALLOC_TIME
  print_info[b_info - bitmap_info].count_search[count_flag + 1]++;
#endif /* PRINT_ALLOC_TIME */					
  
  unsigned int tmp = b_info->bitmap.mask - 1;
  COUNT_BITS(tmp);
  b_info->next_obj = (char *)(b_info->obj_base) +
    ((((b_info->bitmap.cur - (unsigned int *)b_info->base) << 5) + tmp) 
     << b_info->block_size_log);
  
  return 0;
}

void *
heap_alloc(size_t alloc_size)
{
  struct bitmap_info_space *b_info;
  void *obj;

  if(alloc_size > MAX_BLOCK_SIZE){
#ifdef PRINT_ALLOC_TIME
    obj = sml_obj_malloc(alloc_size);
    if(obj != NULL) {
      count_alloc++;
      count_alloc_another++;
    }
    return obj;
#else /* PRINT_ALLOC_TIME */
#ifdef GCSTAT
    sml_heap_malloced(alloc_size);
#endif /* GCSTAT */
    return sml_obj_malloc(alloc_size);
#endif /* PRINT_ALLOC_TIME */
  }

  b_info = MAPPING_HEAP_ALLOC(alloc_size);
    
#ifdef GCSTAT
  if(!TEST_BITPTR(b_info->bitmap))
    sml_heap_fast_alloced(b_info);
#endif /* GCSTAT */

  if(TEST_BITPTR(b_info->bitmap)){
    if(search_bitptr(b_info) == -1) return NULL;
#ifdef GCSTAT
    sml_heap_find_alloced(b_info);
#endif /* GCSTAT */
  }
#ifdef PRINT_ALLOC_TIME
  else{
      print_info[b_info - bitmap_info].count_search[0]++;     
  }
  print_info[b_info - bitmap_info].count_alloc++;
  count_alloc++;
#endif /* PRINT_ALLOC_TIME */

  obj = b_info->next_obj;
  DBG(("find %u %p %x %p",alloc_size,b_info->bitmap.cur,b_info->bitmap.mask,obj));
  
  b_info->next_obj = (char *)(b_info->next_obj) + b_info->block_size_bytes;
  //SET_BITPTR(b_info->bitmap);
  SUCC_BITPTR(b_info->bitmap);

  return obj;
}

#ifdef UPPER
#define MAPPING_HEAP_ALLOC_WITHOUT_UPPER(size_)		\
  ((size_ <= 16) ?					\
   ((size_ <= 8) ? bitmap_info : bitmap_info + 1 )	\
   : ((size_ <= 32) ? bitmap_info + 2			\
      : ((size_ <= 256) ?				\
	 ((size_ <= 64) ? bitmap_info + 3 		\
	  : ((size_ <= 128) ? bitmap_info + 4 : bitmap_info + 5 ))	\
	 : ((size_ <= 1024) ?						\
	    ((size_ <= 512) ? bitmap_info + 6 : bitmap_info + 7 )	\
	    : ((size_ <= 2048) ? bitmap_info + 8 : bitmap_info + 9)))))

void *
heap_alloc_with_upper(size_t alloc_size)
{
  struct bitmap_info_space *b_info;
  void *obj;

  if(alloc_size > MAX_BLOCK_SIZE){
#ifdef PRINT_ALLOC_TIME
    obj = sml_obj_malloc(alloc_size);
    if(obj != NULL) {
      count_alloc++;
      count_alloc_another++;
    }
    return obj;
#else /* PRINT_ALLOC_TIME */
    return sml_obj_malloc(alloc_size);
#endif /* PRINT_ALLOC_TIME */
  }
  
  b_info = MAPPING_HEAP_ALLOC_WITHOUT_UPPER(alloc_size);
  
  while((bitmap_info + THE_NUMBER_OF_FIXED_BLOCK) > b_info) {   
    
#ifdef PRINT_ALLOC_TIME					
    void * tmp_cur;
    unsigned int tmp_mask;

    tmp_cur = b_info->bitmap.cur;					
    tmp_mask = b_info->bitmap.mask;				
#endif

    if((TEST_BITPTR(b_info->bitmap))&&(search_bitptr(b_info) == -1)) {
	b_info->alloc_bitmap_info++;
	b_info = b_info->alloc_bitmap_info;
	DBG(("upper %p %u",b_info,b_info->block_size_bytes));
    } else {
#ifdef PRINT_ALLOC_TIME
	if((tmp_cur == b_info->bitmap.cur)&&(tmp_mask == b_info->bitmap.mask))
	    print_info[b_info - bitmap_info].count_search[0]++;     
	print_info[b_info - bitmap_info].count_alloc++;
	count_alloc++;
#endif /* PRINT_ALLOC_TIME */
	
	obj = b_info->next_obj;
	DBG(("find %u %p %x %p",alloc_size,b_info->bitmap.cur,b_info->bitmap.mask,obj));
	
	b_info->next_obj = (char *)(b_info->next_obj) + b_info->block_size_bytes;
	//SET_BITPTR(b_info->bitmap);
	SUCC_BITPTR(b_info->bitmap);
	
	return obj;
    }
  }
  
  return NULL;
}
#endif /* UPPER */

void *
sml_heap_slow_alloc(size_t alloc_size)
{
  void *obj;

#ifdef PRINT_ALLOC_TIME 
  int i;
  for(i=0;i<THE_NUMBER_OF_FIXED_BLOCK;i++)
    {
      if(print_info[i].block_size >= alloc_size)
	{
	  print_info[i].count_gc++;
	  break;
	}
    }
#ifdef GC_TIME
  tmp_mark = count_call_mark - count_not_mark - count_outside;
#endif /* GC_TIME */
  double st;
  getRusage(st);
#endif /* PRINT_ALLOC_TIME */

#ifdef GCSTAT
  {
    struct bitmap_info_space *b_info = MAPPING_HEAP_ALLOC(alloc_size);
    gcstat.last.trigger = b_info->block_size_bytes;
  }
#endif /* GCSTAT */

  sml_heap_gc();

#ifdef PRINT_ALLOC_TIME
  double en;
  getRusage(en);
  all_time_gc += (en - st);
#ifdef GC_TIME
  fprintf(fp_at,"gc %f mark %u live %u alloc %u invoke_size %u\n",
	  (en - st),
	  (count_call_mark - count_not_mark - count_outside)-tmp_mark,
	  live_tmp,count_alloc - tmp_alloc,
	  alloc_size);
  tmp_alloc = count_alloc;
#endif /* GC_TIME */
#endif /* PRINT_ALLOC_TIME */

#ifndef UPPER
  obj = heap_alloc(alloc_size);
#else /* UPPER */
  obj = heap_alloc_with_upper(alloc_size);
#endif /* UPPER */
  if (obj == NULL) {
    DBG(("alloc failed"));
#ifdef GCSTAT
    stat_notice("---");
    stat_notice("event: error");
    stat_notice("heap exceeded: intented to allocate %lu bytes.",
		(unsigned long)alloc_size);
    if (gcstat.file)
      fclose(gcstat.file);
#endif /* GCSTAT */
    sml_fatal(0, "heap exceeded: intended to allocate %"PRIuMAX" bytes",
	      (intmax_t)alloc_size);
  }

  return obj;
}

SML_PRIMITIVE void
sml_write(void *objaddr, void **writeaddr, void *new_value)
{ 
  *writeaddr = new_value;
#ifndef NOT_CLEAR_BITMAP
  if (IS_IN_HEAP_SPACE(writeaddr)) return;
  
  /* remember the writeaddr as a root pointer which is outside
   * of the heap. */
  sml_global_barrier(writeaddr, objaddr);
  
#else /* NOT_CLEAR_BITMAP */
  struct bitmap_info_space *b_info;
  unsigned int obj_size, alloc_size;
  unsigned int tmp,tmp_index;
  unsigned int *tmp_bitmap;
  void *obj = *writeaddr;

  if (!(IS_IN_HEAP_SPACE(writeaddr)))
    sml_global_barrier(writeaddr, objaddr);

#ifdef PRINT_ALLOC_TIME
  count_call_mark++;
#endif /* PRINT_ALLOC_TIME */    
  
#define OUTSIDE(obj)  do{trace_outside(obj); return;}while(0)
  MAPPING_HEAP_MARK(obj,b_info,NULL,OUTSIDE);
#undef OUTSIDE
  
  //marked check and mark
  tmp = FROM_HEAP_TO_BITMAP(b_info,obj);
  tmp_index = tmp >> 5;
  tmp_bitmap = (unsigned int *)b_info->base + tmp_index;
  tmp = (unsigned int)0x01 << (tmp & 0x0000001f);

  if(*tmp_bitmap & tmp) {
    DBG(("%p at %p already marked", obj, NULL));
#ifdef PRINT_ALLOC_TIME
    count_not_mark++;
#endif /* PRINT_ALLOC_TIME */
    return;    
  }
  
  *tmp_bitmap |= tmp; //mark
  
  //tree check
  unsigned int i;
  for(i=0;(*tmp_bitmap == 0xffffffff)&&(i < b_info->rank);i++){   
    tmp = ((unsigned int)0x01 << (tmp_index & 0x0000001f));
    tmp_index >>= 5;
    tmp_bitmap = (unsigned int *)b_info->tree[i] + tmp_index;
    *tmp_bitmap |= tmp;
  }
  
  DBG(("%p at %p mark (%"PRIuMAX", %"PRIuMAX")",
       obj, NULL, (intmax_t)obj_size, (intmax_t)alloc_size));
  
#ifdef PRINT_ALLOC_TIME
  print_info[b_info - bitmap_info].count_mark++;
  live_tmp += HEAP_ROUND_SIZE(OBJ_TOTAL_SIZE(obj));
#endif /* PRINT_ALLOC_TIME */
  
  /* STACK_PUSH */
  (*(marking_stack.top)) = obj;  
  marking_stack.top++;  
#endif /* NOT_CLEAR_BITMAP */

}

SML_PRIMITIVE void *
sml_alloc(unsigned int objsize, void *frame_pointer)
{
	/* objsize = payload_size + bitmap_size */
	void *obj;
	size_t inc = HEAP_ROUND_SIZE(OBJ_HEADER_SIZE + objsize);

	GIANT_LOCK(frame_pointer);
	HEAP_FAST_ALLOC(obj, inc, (sml_save_frame_pointer(frame_pointer),
				   sml_heap_slow_alloc(inc)));
	GIANT_UNLOCK();
	OBJ_HEADER(obj) = 0;
	return obj;
}
