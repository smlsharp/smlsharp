/*
 * frame.h - SML# stack frame format
 * @copyright (c) 2009-2010, Tohoku University.
 * @author UENO Katsuhiro
 */
#ifndef SMLSHARP__FRAME_H__
#define SMLSHARP__FRAME_H__

/*
 * See also FrameLayout.sml.
 *
 * Frame pointer points the address of memory holding previous frame pointer.
 * The next (in the direction of stack growing) word of the previous frame
 * pointer holds the frame header. If the header indicates that there is
 * an extra word, then the extra word appears at the next of the header.
 * The size of both the header and the extra word is same as the size of
 * pointers on the target platform.
 *
 * For example, on a 32-bit architecture whose the stack grows down
 * (x86 etc.),
 * [fp + 0] is previous frame pointer, and
 * [fp - 4] is the relative address of frame info word.
 * [fp - 8] is for the extra word of frame header.
 *
 * Frame Stack Chain:
 *                                     :          :
 *                                     |          |
 *                                     +==========+ current frame begin
 *                                     |          |
 *            +--------+               :          :
 *            | header |-------------->|frame info|
 *            +--------+               :          :
 *     fp --->|  prev  |               |          |
 *            +--|-----+               +==========+ current frame end
 *               |                     |          |
 *               |                     :          :
 *               |                     |          |
 *               |                     +==========+ previous frame begin
 *               |                     |          |
 *               |   +--------+        :          :
 *               |   | header |------->|frame info|
 *               |   +--------+        :          :
 *               +-->|  prev  |        |          |
 *                   +---|----+        +==========+ previous frame end
 *                       |             |          |
 *                       :             :          :
 *
 * header:
 *  31                            2   1     0
 * +--------------------------------+----+----+
 * |           info-offset          |next| gc |
 * +--------------------------------+----+----+
 * MSB                                      LSB
 *
 * info-offset holds the high 30 bit of the offset of frame info of this
 * frame from the frame pointer. Low 2 bit is always 0.
 * If info-offset is 0, this frame has no frame info and thus there is no
 * boxed or generic slot in this frame.
 * If the pointer size is larger than 32 bit, info-offset field is
 * expanded to the pointer size.
 *
 * If next bit is 1, the header has an extra word which holds the address
 * of previous ML frame. (this is used to skip C frames between two ML
 * frames due to callback functions.)
 *
 * gc bit is reserved for non-moving gc. It must be 0 for new frames.
 * If the root-set enumerator meets this frame during pointer enumeration,
 * the gc bit is set to 1.
 *
 * To make sure that we may use last 2 bits for the flags, the frame info
 * must be aligned at the address of multiple of 4.
 *
 * frame info:
 *  31                16 15                 0
 * +--------------------+--------------------+
 * |  num boxed slots   |  num bitmap bits   |
 * +--------------------+--------------------+
 *
 * The size of frame info is same as the size of pointers on the target
 * platform. If the pointer size is larger than 32 bit, then padding bits
 * must be added to the most significant side of the frame info.
 *
 * Structure of Frame:
 *
 * addr
 *   | :               :
 *   | +---------------+ [align in frameAlign] <------- offset origin
 *   | | pre-offset    |
 *   | +===============+ ================== beginning of frame
 *   | |               |
 *   | +---------------+ [align in frameAlign]
 *   | | slots of tN   | generic slot 0 of tN
 *   | |  :            |   :
 *   | +---------------+ [align in frameAlign]
 *   | :               :
 *   | +---------------+ [align in frameAlign]
 *   | | slots of t1   | generic slot 0 of t1
 *   | :               :   :
 *   | +---------------+ [align in frameAlign]
 *   | | slots of t0   | generic slot 0 of t0
 *   | |               | generic slot 1 of t0
 *   | :               :   :
 *   | +---------------+ [align in frameAlign] <---- pointed by the header
 *   | | frame info    |
 *   | +---------------+ [align in unsigned int]
 *   | |               | 
 *   | +---------------+ [align in void*]
 *   | | boxed part    |
 *   | :               :
 *   | |               |
 *   | +---------------+ [align in void*]
 *   | |               |
 *   | +---------------+ [align in unsigned int]
 *   | | sizes         | number of slots of t0
 *   | |               | number of slots of t1
 *   | :               :   :
 *   | |               | number of slots of t(N-1)
 *   | +---------------+ [align in unsigned int]
 *   | | bitmaps       | bitmap of (t0-t31)
 *   | :               :   :
 *   | |               | bitmap of (t(N-32)-t(N-1))
 *   | +---------------+ [align in unsigned int]
 *   | | unboxed part  |
 *   | |               |
 *   | |               |
 *   | :               :
 *   | |               |
 *   | +===============+ ================== end of frame
 *   | | post-offset   |
 *   | +---------------+ [align in frameAlign]
 *   | :               :
 *   v
 */

#ifdef STACK_GROWSUP
#define FRAME_HEADER(fp)  (*(uintptr_t*)((void**)(fp) + 1))
#define FRAME_EXTRA(fp)   (*(uintptr_t*)((void**)(fp) + 2))
#else
#define FRAME_HEADER(fp)  (*(uintptr_t*)((void**)(fp) - 1))
#define FRAME_EXTRA(fp)   (*(uintptr_t*)((void**)(fp) - 2))
#endif
#define FRAME_NEXT(fp)  (((void**)(fp))[0])

#define FRAME_FLAG_VISITED  0x1
#define FRAME_FLAG_SKIP     0x2
#define FRAME_OFFSET_MASK   (~(uintptr_t)0x3)
#define FRAME_INFO_OFFSET(header)  ((intptr_t)((header) & FRAME_OFFSET_MASK))
#define FRAME_SKIP_NEXT(header)    ((void*)((header) & FRAME_OFFSET_MASK))

#define FRAME_NUM_BOXED(info)   (((unsigned int*)(info))[0] >> 16)
#define FRAME_NUM_GENERIC(info) (((unsigned int*)(info))[0] & 0xffff)
#define FRAME_BOXED_PART(info) \
	((void*)((char*)(info) + ALIGNSIZE(sizeof(unsigned int), \
					   sizeof(void*))))

#ifndef SIZEOF_GENERIC
#define SIZEOF_GENERIC MAXALIGN
#endif

#endif /* SMLSHARP__FRAME_H__ */
