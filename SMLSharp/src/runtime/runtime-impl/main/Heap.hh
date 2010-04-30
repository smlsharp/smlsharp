/**
 * @copyright (c) 2006, Tohoku University.
 * @author YAMATODANI Kiyoshi
 * @version $Id: Heap.hh,v 1.24 2007/12/24 13:30:52 kiyoshiy Exp $
 */
#ifndef Heap_hh_
#define Heap_hh_

#include <list>
#include <map>

#include "RuntimeTypes.hh"
#include "LargeInt.hh"
#include "IllegalArgumentException.hh"
#include "NoEnoughHeapException.hh"
#include "OutOfMemoryException.hh"
#include "Log.hh"
#include "Debug.hh"

BEGIN_NAMESPACE(jp_ac_jaist_iml_runtime)

///////////////////////////////////////////////////////////////////////////////

/**
 *
 *  The heap monitoring facility is enabled if the
 * IML_ENABLE_HEAP_MONITORING compilation flag is set.
 *
 * ToDo : this name is too lengthy...
 */
class HeapMonitor
{
    ///////////////////////////////////////////////////////////////////////////

  public:

    virtual void beforeMinorGC()
    {
        // default implementation
    };

    virtual
    void afterMinorGC()
    {
        // default implementation
    };

    virtual
    void beforeMajorGC()
    {
        // default implementation
    };

    virtual
    void afterMajorGC()
    {
        // default implementation
    };

    virtual
    void beforeAllocRecordBlock(Bitmap &bitmap, int &number)
    {
        // default implementation
    };

    virtual
    void afterAllocRecordBlock(Bitmap &bitmap, int &number, Cell* &block)
    {
        // default implementation
    };

    virtual
    void beforeAllocAtomBlock(int &number)
    {
        // default implementation
    };

    virtual
    void afterAllocAtomBlock(int &number, Cell* &block)
    {
        // default implementation
    };

    virtual
    void beforeAllocPointerBlock(int &number)
    {
        // default implementation
    };

    virtual
    void afterAllocPointerBlock(int &number, Cell* &block)
    {
        // default implementation
    };

    virtual
    void beforeAllocAtomArray(int &number)
    {
        // default implementation
    };

    virtual
    void afterAllocAtomArray(int &number, Cell* &block)
    {
        // default implementation
    };

    virtual
    void beforeAllocPointerArray(int &number)
    {
        // default implementation
    };

    virtual
    void afterAllocPointerArray(int &number, Cell* &block)
    {
        // default implementation
    };

    virtual
    void beforeAllocLargeIntBlock(Cell* block)
    {
    };

    virtual
    void afterAllocLargeIntBlock(Cell* block)
    {
    };

    virtual
    void beforeInitializeField(Cell* &block, int &index, const Cell& cell)
    {
        // default implementation
    };

    virtual
    void afterInitializeField(Cell* &block, int &index, const Cell& cell)
    {
        // default implementation
    };

    virtual
    void beforeInitializeArray(Cell* &block, const Cell& cell)
    {
        // default implementation
    };

    virtual
    void afterInitializeArray(Cell* &block, const Cell& cell)
    {
        // default implementation
    };

    virtual
    void beforeUpdateField(Cell* &block, int &index, const Cell& cell)
    {
        // default implementation
    };

    virtual
    void afterUpdateField(Cell* &block, int &index, const Cell& cell)
    {
        // default implementation
    };
};

///////////////////////////////////////////////////////////////////////////////

/**
 * Heap manager which implements a simple generational GC algorithm.
 *
 * NOTE: For optimization, the heap is made a static module rather than
 * objects of the heap class. Therefore, there is single heap in a program.
 */
class Heap
/*
    : public Heap,
      public RootTracer
*/
{

    ///////////////////////////////////////////////////////////////////////////

  public:

    ///////////////////////////////////////////////////////////////////////////
    // types and inner classes

    /** type of the block header */
    typedef UInt32Value BlockHeader;

    /** type of the block type field in block header */
    typedef UInt32Value BlockType;

    /** type of the block size field in block header */
    typedef UInt32Value BlockSize;

    typedef std::list<Cell*> BlockPointerList;
    typedef std::list<Cell**> BlockPointerRefList;

    typedef std::list<HeapMonitor*> HeapMonitorList;

    /**
     * Constants indicating which GC is running.
     */
    enum GCMode
    {
        /** GC is not running. */
        GC_NONE,

        /** minor GC is running. */
        GC_MINOR,

        /** major GC is running. */
        GC_MAJOR
    };

    ///////////////////////////////////////////////////////////////////////////

  private:

    ///////////////////////////////////////////////////////////////////////////
    // types and inner classes

    /**
     * Datatype which represents a region in heap.
     */
    struct HeapRegion
    {
        ///////////////////////////////////////////////////////////////////////

        /**
         * Constructor.
         *
         * @param begin pointer to the first cell of the region
         * @param size size of the region (in Cells)
         */
        HeapRegion(UInt32Value* begin = 0, int size = 0)
            :begin_(begin),
             end_(begin + size),
             free_(begin)
        {
        }

        ///////////////////////////////////////////////////////////////////////

        /**
         * pointer to the first cell of the region
         */
        UInt32Value* begin_;
        
        /**
         * pointer to the next of the last cell of the region.
         *
         * <p>
         * The address of the last cell of the region is 'end - 1'.
         * </p>
         */
        UInt32Value* end_;

        /**
         * pointer to the first cell in the unused area of this region
         *
         * <p>
         * On allocation of a block, free_ is forwarded by the size of the
         * allocated block.
         * </p>
         */
        UInt32Value* free_;
    };

    ///////////////////////////////////////////////////////////////////////////

    class Tracer
        :public RootTracer
    {
        ///////////////////////////////////////////////////////////////////////
      public:

        Tracer(){}

        virtual ~Tracer(){}

        ///////////////////////////////////////////////////////////////////////
        // Concretization of class RootTracer
      public:

        virtual
        void trace(Cell*** roots, int count)
            throw(IMLException);

        virtual
        void trace(Cell** roots, int count)
            throw(IMLException);

        virtual
        Cell* trace(Cell* root)
            throw(IMLException);

    };
    friend class Tracer;

    struct FLOBInfo
    {
        /**
         * a pointer to memory allocated by ALLOCATE_MEMORY.
         */
        void* memory_;

        /**
         * true if user calls releaseFLOB on this FLOB.
         */
        bool isReleased_;

        FLOBInfo():memory_(NULL), isReleased_(false)
        {
        }

        FLOBInfo(void* memory)
            :isReleased_(false)
        {
            memory_ = memory;
        }

    };

    typedef std::map<Cell*, FLOBInfo*> FLOBInfoMap;

    ///////////////////////////////////////////////////////////////////////////
    // fields
    
  private:

    /**
     * 
     */
    static Tracer tracer_;

    /**
     * Rootset holder
     */
    static RootSet* rootset_;

    static FinalizerExecutor* finalizeExecutor_;

    /**
     * current GC
     */
    static GCMode currentGC_;

    /**
     * heap area
     */
    static UInt32Value* heap_;

    /**
     * pointer to a block of zero field.
     */
    static Cell* unitBlock_;

    /**
     * Heap segment which contains blocks belonging to the younger generation.
     */
    static HeapRegion youngerRegion_;

    /**
     * Heap segment which contains block belonging to the elder generation.
     */
    static HeapRegion elderFromRegion_;

    /**
     * Heap segment which is reserved for major GC.
     *
     * <p>
     * Major GC copies all the live blocks in the younger and elder-from region
     * into this region. On major GC is completed, this region becomes
     * elder-from region and previous elder-from region, elder-to region.
     * </p>
     */
    static HeapRegion elderToRegion_;

    /**
     * The region into which live blocks are copied when GC.
     *
     * <p>
     * The copyToRegion_ is the younger region at minor GC 
     * and the elder-to region at major GC.
     * </p>
     */
    static HeapRegion copyToRegion_;

    /**
     * An array of addresses of inter-generational pointers which point to
     * blocks in the younger region and are stored in blocks in the elder
     * region.
     *
     * <p>
     * The type of elements of this array is Cell**.
     * </p>
     */
    static BlockPointerRefList assignments_;

    /**
     * a list of finalizable blocks which are in reachable state.
     */
    static BlockPointerList reachableFinalizables_;

    /**
     * a list of finalizable blocks which are in unreachable state.
     */
    static BlockPointerList unreachableFinalizables_;

    /**
     * an associated array from block pointer to FLOBInfo.
     */
    static FLOBInfoMap FLOBInfoMap_;

    /**
     * log writer
     */
    DBGWRAP(static LogAdaptor LOG;)

#ifdef IML_ENABLE_HEAP_MONITORING
    static
    HeapMonitorList monitors_;
#endif

    ///////////////////////////////////////////////////////////////////////////

  public:

    ///////////////////////////////////////////////////////////////////////////
    // Constants 

    /*
     * block type
     */
    /** record type */
    static const UInt32Value BLOCKTYPE_RECORD = 1;
    /** atom type */
    static const UInt32Value BLOCKTYPE_ATOM = 2;
    /** pointer type */
    static const UInt32Value BLOCKTYPE_POINTER = 3;
    /** single atom mutable array type */
    static const UInt32Value BLOCKTYPE_SINGLE_ATOM_MUTABLE_ARRAY = 4;
    /** double atom mutable array type */
    static const UInt32Value BLOCKTYPE_DOUBLE_ATOM_MUTABLE_ARRAY = 5;
    /** pointer mutable array type */
    static const UInt32Value BLOCKTYPE_POINTER_MUTABLE_ARRAY = 6;
    /** single atom immutable array type */
    static const UInt32Value BLOCKTYPE_SINGLE_ATOM_IMMUTABLE_ARRAY = 7;
    /** double atom immutable array type */
    static const UInt32Value BLOCKTYPE_DOUBLE_ATOM_IMMUTABLE_ARRAY = 8;
    /** pointer immutable array type */
    static const UInt32Value BLOCKTYPE_POINTER_IMMUTABLE_ARRAY = 9;
    /** large int type */
    static const UInt32Value BLOCKTYPE_LARGEINT = 10;

    ///////////////////////////////////////////////////////////////////////////

  public:

    /**
     * constructor
     *
     * @param size size of each segment in heap area (by words).
     * @param rootset rootset holder
     * @param finalizeExecutor executor of finalizer functions
     */
    Heap(int size,
         RootSet* rootset = 0,
         FinalizerExecutor* finalizeExecutor = 0);

    /**
     * destructor
     */
    virtual
    ~Heap();

    ///////////////////////////////////////////////////////////////////////////

  public:

    /**
     * initialize
     *
     * @param size size of each segment in heap area (by words).
     * @param rootset rootset holder
     * @param finalizeExecutor executor of finalizer functions
     */
    static
    void initialize(int size,
                    RootSet* rootset = 0,
                    FinalizerExecutor* finalizeExecutor = 0);

    /**
     * release all resources used by the heap.
     */
    static
    void finalize();

    /**
     * Set the rootset holder of the heap
     *
     * @param rootset the rootset holder
     */
    static
    void setRootSet(RootSet* rootset);

    static
    void setFinalizerExecutor(FinalizerExecutor* finalizeExecutor);

    static
    void addMonitor(HeapMonitor* monitor);

    static
    void invokeGC(GCMode mode)
      throw(IMLException);

    static
    void addFinalizable(Cell* block);

    /**
     * Check whether the pointer points at a valid location in heap area.
     *
     * @param block pointer to the payload of block
     * @return true if block points a valid location in heap area.
     */
    static
    bool isValidBlockPointer(Cell* block);

    static
    bool isFLOB(Cell* block);

    /**
     * Indicates whether the specified field of the RECORD block holds a block
     * pointer.
     *
     * @param block pointer to the block
     * @param index index of the field of the block
     * @return true if the field specfied by 'index' of the block holds
     *        a block pointer.
     */
    static
    bool isPointerField(Cell* block, int index);

    ///////////////////////////////////////////////////////////////////////////

  private:

    ///////////////////////////////////////////////////////////////////////////
    // Constants 

    /**
     * Bit assignment in the block header
     *
     *   00-26 : payload size (in Cell)
     *          A block consists of header, payload and trailer.
     *          Header occupies a cell for every block types.
     *          Payload contains user fields.
     *          Trailer occupies a cell for record block to store bitmap.
     *          Ohter block types have no trailer.
     *   27-30 : type
     *   31-31 : GC information (set to '1' if the block has been forwarded)
     *
     * ToDo : More bit-width may be required for the payload size field ???
     *
     */
    static const UInt32Value SIZE_MASK = 0x7FFFFFFUL;
    static const UInt32Value SIZE_SHIFT = 0;
    static const UInt32Value TYPE_MASK = 0x78000000UL;
    static const UInt32Value TYPE_SHIFT = 27;
    static const UInt32Value FORWARDED_MASK = 0x80000000UL;
    static const UInt32Value FORWARDED_SHIFT = 31;

    /** maximum of the payload size of the record type blocks.
     * 32 user fields + 1 extra field for bitmap.
     */
    static const UInt32Value MAX_RECORDBLOCK_PAYLOAD_SIZE = 33;

    /**
     * blocks larger than this const are allocated out of heap as a FLOB.
     */
    static const UInt32Value MAX_HEAPBLOCK_SIZE = 1023;

    static const UInt32Value WORDS_OF_HEADER =
    (sizeof(BlockHeader) / sizeof(UInt32Value));
    static const UInt32Value WORDS_OF_BITMAP =
    (sizeof(Bitmap) / sizeof(UInt32Value));
    static const UInt32Value WORDS_OF_CELL =
    (sizeof(Cell) / sizeof(UInt32Value));
    static const int BLOCK_ALIGNMENT = sizeof(Real64Value);
    static const UInt32Value CELLS_OF_LARGEINT =
    ((sizeof(LargeInt::largeInt) + (sizeof(Cell) - 1)) / sizeof(Cell));

    /** size of finalizable object
     * Its first field is a finalized value, second field is a closure.
     */
    static const int SIZE_OF_FINALIZABLE = 2;

    ///////////////////////////////////////////////////////////////////////////
    // Macros for walking on the heap

    /**
     * Returns a pointer to the header of the block whose payload the 'block'
     * points to.
     *
     * @param block a pointer to the payload
     * @return a pointer to the header
     */
    INLINE_FUN static
    BlockHeader* BLOCK_TO_HEADER(Cell* block)
    {
        return ((BlockHeader*)(((char*)(block)) - sizeof(BlockHeader*)));
    }

    /**
     * Returns a pointer to the payload of the block whose header the 'header'
     * points to.
     *
     * @param header a pointer to the header
     * @return a pointer to the payload
     */
    INLINE_FUN static
    Cell* HEADER_TO_BLOCK(BlockHeader* header)
    {
        return ((Cell*)(((char*)(header)) + sizeof(BlockHeader*)));
    }

    /**
     *  indicates whether the payload of the block starts at double-word
     * boundary.
     * NOTE: This function is used for debug. 
     */
    static
    bool isAlignedBlockAddress(Cell* block)
    {
        return
        (unitBlock_ == block)
        || (0 == (((UInt32Value)block) % BLOCK_ALIGNMENT));
    }

    /**
     *  adjust a block header address so that the payload of the block starts
     * at double-word boundary.
     */
    INLINE_FUN static
    BlockHeader* alignHeaderAddress(BlockHeader* headerAddress)
    {
        UInt32Value payloadAddress =
        (UInt32Value)(headerAddress + WORDS_OF_HEADER);
        UInt32Value modulo = payloadAddress % BLOCK_ALIGNMENT;
        switch(modulo){
          case 0: return headerAddress;
          default:
            return
            (BlockHeader*)
            (((UInt32Value)headerAddress) + (BLOCK_ALIGNMENT - modulo));
        }
    }

    /**
     * Returns a pointer to the header of the block following the block whose
     * header the 'header' points to.
     *
     * @param header a pointer to the header
     * @return a pointer to the header of the next block
     */
    INLINE_FUN static
    BlockHeader* NEXT_HEADER(BlockHeader* header)
    {
        UInt32Value* nextCell = ((UInt32Value*)header) + getTotalWords(header);
        return (BlockHeader*)alignHeaderAddress(nextCell);
    }

/**
 * <code>INVOKE_ON_MONITORS</code>(<i>methodCall</i>) invokes <i>methodCall</i>
 * on each monitors in the <code>monitors_</code>.
 *
 * <p>
 *  <i>methodCall</i> specifies the method and arguments to be passed.
 * </p>
 *
 */
#ifdef IML_ENABLE_HEAP_MONITORING
#define INVOKE_ON_HEAP_MONITORS(methodCall) \
    { \
        for(HeapMonitorList::iterator i = monitors_.begin(); \
            i != monitors_.end(); \
            i += 1){ \
            HeapMonitor* monitor = *i \
            if(0 != monitor){ \
                monitor->methodCall; \
            } \
        } \
    }
#else
#define INVOKE_ON_HEAP_MONITORS(method)
#endif

    /**
     * Updates the header of the block.
     *
     * @param header pointer to the block header
     * @param payloadCells the size of payload of the block (in ords)
     * @param type type of the block (ATOM, POINTER, RECORD)
     * @param forwarded true if this block is forwarded
     */
    INLINE_FUN static
    void setHeader(BlockHeader* header,
                   BlockSize payloadCells,
                   BlockType type,
                   BoolValue forwarded)
    {
        ASSERT(isValidHeaderPointer(header));

        BlockHeader forwardedBit = forwarded ? 1 : 0;

        /*
         * 'payloadCells' is adjusted by 1 so that fits in 5 bit width of the
         * 'size' field of the header.
         */
        *header =
        (BlockHeader)(
                      ((payloadCells << SIZE_SHIFT) & SIZE_MASK) |
                      ((type << TYPE_SHIFT) & TYPE_MASK) |
                      ((forwardedBit << FORWARDED_SHIFT) & FORWARDED_MASK)
                      );
    }

    /**
     * Returns the type of the block
     *
     * @param header pointer to the block header
     * @return type of the block
     */
    INLINE_FUN static
    BlockType getType(BlockHeader* header)
    {
        return (*header & TYPE_MASK) >> TYPE_SHIFT;
    }

    /**
     * Returns the total size of the block (in words).
     *
     * @param header pointer to the block header
     * @return the size of the block (including the payload, the header and
     *        bitmap) (in words).
     */
    static
    BlockSize getTotalWords(BlockHeader* header);

    /**
     * Returns the count of cells of the payload of the block
     *
     * @param header pointer to the block header
     * @return the number of cells in payload of the block
     */
    INLINE_FUN 
    static
    BlockSize getPayloadCells(BlockHeader* header)
    {
        return ((*header & SIZE_MASK) >> SIZE_SHIFT);
    }

    /**
     * Returns true if the block has been forwarded by GC.
     *
     * @param header pointer to the block header
     * @return true if the block has been forwarded
     */ 
    static
    bool isForwarded(BlockHeader* header);

    /**
     * Updates the bit indicating whether the block has been forwarded.
     *
     * @param header pointer to the block header
     * @param forwarded true if the block has been forwarded
     */
    static
    void setForwarded(BlockHeader* header, bool forwarded);

    /**
     * Returns the bitmap information of the block
     *
     * <p>
     * This method is applicable only to RECORD type blocks.
     * </p>
     *
     * @param header pointer to the block header
     * @return bitmap information of the block
     */
    static
    Bitmap getBitmapTag(BlockHeader* header);

    /**
     * Update the bitmap information of the block
     *
     * <p>
     * This method is applicable only to RECORD type blocks.
     * </p>
     *
     * @param header pointer to the block header
     * @param bitmap bitmap information of the block
     */
    static
    void setBitmapTag(BlockHeader* header, Bitmap bitmap);

    /**
     * Indicates whether the specified index is within the number of fields of
     * the block.
     *
     * @param header pointer to the block header
     * @param index index of the field of the block
     * @return true if 'index' specifies a field of the block.
     */
    static
    bool isValidBlockField(BlockHeader* header, int index);

    /**
     * Indicates whether the specified field of the RECORD block holds a block
     * pointer.
     *
     * @param header pointer to the block header
     * @param index index of the field of the block
     * @return true if the field specfied by 'index' of the block holds
     *        a block pointer.
     */
    static
    bool isPointerField(BlockHeader* header, int index);

    /**
     * Indicates whether the block is in the younger region.
     *
     * @param header pointer to the block header
     * @return true if the block is in the younger region.
     */
    INLINE_FUN 
    static
    bool
    isInYoungerRegion(BlockHeader* header)
    {
        return ((youngerRegion_.begin_ <= ((UInt32Value*)header)) &&
                (((UInt32Value*)header) < youngerRegion_.end_));
    }

    /**
     * Indicates whether the block is in the elder-from region.
     *
     * @param header pointer to the block header
     * @return true if the block is in the elder-from region.
     */
    INLINE_FUN 
    static
    bool
    isInElderFromRegion(BlockHeader* header)
    {
        return ((elderFromRegion_.begin_ <= ((UInt32Value*)header)) &&
                (((UInt32Value*)header) < elderFromRegion_.end_));
    }

    /**
     * Indicates whether the block is in the elder-to region.
     *
     * @param header pointer to the block header
     * @return true if the block is in the elder-to region.
     */
    INLINE_FUN 
    static
    bool
    isInElderToRegion(BlockHeader* header)
    {
        return ((elderToRegion_.begin_ <= ((UInt32Value*)header)) &&
                (((UInt32Value*)header) < elderToRegion_.end_));
    }

    /**
     * Indicates whether the block is in regions from which GC copies
     * live blocks into the 'to' region.
     *
     * <p>
     * In minor GC,
     *   isInFromRegion(block) equals to isInYoungerRegion(block),
     * in major GC,
     *   isInFromRegion(block) equals to
     *   isInYoungerRegion(block) || isInElderToRegion(block),
     * for every block pointer 'block'.
     * </p>
     *
     * @param header pointer to the block header
     * @return true if the block is in copy source regions.
     */
    INLINE_FUN 
    static
    bool
    isInFromRegion(BlockHeader* header)
    {
        return ((isInYoungerRegion(header)) || 
                ((GC_MAJOR == currentGC_) && (isInElderFromRegion(header))));
    }

    /**
     * Indicates whether the block is in the copyToRegion to which GC copies
     * live blocks.
     *
     * <p>
     * Invocation of this method is valid only in minor/major GC.
     * </p>
     *
     * @param header pointer to the block header
     * @return true if the block is copytToRegion.
     */
    INLINE_FUN 
    static
    bool
    isInToRegion(BlockHeader* header)
    {
        return ((copyToRegion_.begin_ <= ((UInt32Value*)header)) &&
                (((UInt32Value*)header) < copyToRegion_.end_));
    }

    /**
     * indicates whether the block is a FLOB.
     */
    INLINE_FUN
    static
    bool
    isFLOBPointer(BlockHeader* header)
    {
        return
            (FLOBInfoMap_.end() != FLOBInfoMap_.find(HEADER_TO_BLOCK(header)));
    }

    INLINE_FUN
    static
    bool
    isVisited(BlockHeader* header)
    {
        return (isInToRegion(header)
                || (isFLOBPointer(header) && isForwarded(header)));
    }

    /**
     * Check whether the pointer points at a valid location in heap area.
     *
     * @param header pointer to the header of block
     * @return true if block points a valid location in heap area.
     */
    static
    bool isValidHeaderPointer(BlockHeader* header);

    /**
     * Allocates a block in the younger region.
     *
     * <p>
     * Any fields of the block this method returns are not initialized.
     * When there is not sufficient room in younger-from region, this method
     * starts GC.
     * </p>
     *
     * @param payloadAndTrailerCells the number of Cells required for payload
     *                   and trailer (excluding size of header).
     * @return pointer to the header of the new allocated block.
     */
    INLINE_FUN static
    BlockHeader* allocRawBlock(int payloadAndTrailerCells)
    {
        // if payloadAndTrailerCells is zero, return pointer to the
        // reserved unit block.
        if(0 == payloadAndTrailerCells){
            return BLOCK_TO_HEADER(unitBlock_);
        }

        int requiredWords =
        (payloadAndTrailerCells * WORDS_OF_CELL) + WORDS_OF_HEADER;

        if(MAX_HEAPBLOCK_SIZE < requiredWords){
            BlockHeader* newHeader = allocFixedRawBlock(requiredWords);
            /* mark this block as 'released', so that the allocated memory
             * is released if the block becomes unreachable. */
            releaseFLOB(HEADER_TO_BLOCK(newHeader));
            return newHeader;
        }

        BlockHeader* nextHeaderAddress =
        alignHeaderAddress(youngerRegion_.free_);

        if(youngerRegion_.end_ - nextHeaderAddress < requiredWords)
        {
            invokeGC(GC_MINOR);
        }
        // NOTE: youngerRegion_ can be updated in GC.

        nextHeaderAddress = alignHeaderAddress(youngerRegion_.free_);
        if(youngerRegion_.end_ - nextHeaderAddress < requiredWords)
        {
            DBGWRAP(LOG.error("allocRawBlock::NoEnoughHeapException"));
            throw NoEnoughHeapException();
        }

        youngerRegion_.free_ = nextHeaderAddress + requiredWords;

        // returns pointer to the header of the block, not to the payload.
        return nextHeaderAddress;
    }


    /**
     * Starts minor GC.
     *
     * <p>
     * Copies live blocks beglonging to the younger region into the
     * elder-from region.
     * When it is found that the elder-from region does not have sufficient
     * free room to hold all live blocks, major GC is kicked off.
     * </p>
     * @param forceMajorGC if true, do MajorGC in the MinorGC.
     */
    static
    void invokeMinorGC(bool forceMajorGC);

    /**
     * Starts major GC.
     *
     * <p>
     * Copies live blocks beglonging to the younger and elder-from region
     * into the elder-to region.
     * </p>
     */
    static
    void invokeMajorGC();

    /**
     * Scans the 'to' region and copies live blocks in 'from' regions
     * into the 'to' region.
     *
     * @param copiedBegin the first cell of the area into which GC has copied
     *                   live blocks
     */
    static
    void scanToRegion(BlockHeader* copiedBegin);

    /**
     * Returns a pointer to the block in 'to' region which corresponds to
     * the block to which the 'block' argument points.
     *
     * <p>
     * If the block to which 'block' points is in 'to' region, this method
     * returns the argument pointer.
     * </p>
     * <p>
     * If the block to which 'block' points is in 'from' region, this method
     * returns a pointer to the block in 'to' region which is a copy of the
     * original block.
     * If the block has not been copied yet, this method copies the block
     * into the 'to' region and embeds the forward pointer in the original
     * block.
     * </p>
     *
     * @param block block pointer
     * @return pointer to the block in 'to' region
     */
    static
    Cell* update(Cell* block);

    static
    void updateBlockContents(Cell* block);

    static
    void updatePointerOfBlockPointerList(BlockPointerRefList* ppblocks);

    static
    void updateBlockPointerList(BlockPointerList* ppblocks);

    static
    Cell* followForwardedPointer(Cell* block);

    /**
     * Copies a block beloinging to 'from' regions into the 'to' region.
     *
     * @param block pointer to a block in 'from' region
     * @return pointer to the block allocated in the 'to' region.
     * @exception OutOfMemory
     */
    static
    Cell* copyToToRegion(Cell* block);

    static
    void updateFLOBs();

    static
    void clearVisitedOfFLOBs();

    static
    void releaseUnreachableFLOBs();

    static
    void checkReachabilityOfFinalizables();

    /**
     * @return true if any finalizer has been executed.
     */
    static
    bool runFinalizer();

    ///////////////////////////////////////////////////////////////////////////
    // Concretization of class Heap

  public:

    static
    void clear()
        throw(IMLException);

    INLINE_FUN static
    int getPayloadSize(Cell* block)
        throw(IMLException)
    {
        return getPayloadCells(BLOCK_TO_HEADER(block));
    }

    static
    Bitmap getBitmap(Cell* block)
        throw(IMLException)
    {
        return getBitmapTag(BLOCK_TO_HEADER(block));
    }

    static
    void setBitmap(Cell* block, Bitmap bitmap)
        throw(IMLException)
    {
        return setBitmapTag(BLOCK_TO_HEADER(block), bitmap);
    }

    static
    BlockType getBlockType(Cell* block)
    {
        return getType(BLOCK_TO_HEADER(block));
    }

    INLINE_FUN static
    void initializeField(Cell* block, int index, const Cell& value)
        throw(IMLException)
    {
        INVOKE_ON_HEAP_MONITORS(beforeInitializeField(block, index, value));
        ASSERT(isValidBlockField(BLOCK_TO_HEADER(block), index));
        ASSERT(isValidBlockPointer(block));
        BlockHeader* header = BLOCK_TO_HEADER(block);
        ASSERT((!isPointerField(header, index)) ||
               isValidBlockPointer(value.blockRef));
        *(block + index) = value;
        INVOKE_ON_HEAP_MONITORS(afterInitializeField(block, index, value));
    }

    INLINE_FUN static
    void initializeField_D(Cell* block, int index, const Real64Value& value)
        throw(IMLException)
    {
        INVOKE_ON_HEAP_MONITORS(beforeInitializeField(block, index, value));
        ASSERT(isValidBlockField(BLOCK_TO_HEADER(block), index));
        ASSERT(isValidBlockPointer(block));
        BlockHeader* header = BLOCK_TO_HEADER(block);
        ASSERT((!isPointerField(header, index)) ||
               (!isPointerField(header, index + 1)));
        Cell* fieldAddress = block + index;
        *(Real64Value*)fieldAddress = value;
        INVOKE_ON_HEAP_MONITORS(afterInitializeField(block, index, value));
    }

    INLINE_FUN static
    void updateField(Cell* block, int index, const Cell& value)
        throw(IMLException)
    {
        INVOKE_ON_HEAP_MONITORS(beforeUpdateField(block, index, value));
        ASSERT(isValidBlockPointer(block));
        ASSERT(isValidBlockField(BLOCK_TO_HEADER(block), index));
        BlockHeader* header = BLOCK_TO_HEADER(block);
        ASSERT((!isPointerField(header, index)) ||
               isValidBlockPointer(value.blockRef));
        /* address of the cell holding IGP. */
        Cell* fieldAddress = block + index;
        /*
         *  Remembers the location of IGPs to younger from elder.
         * (IGP = Inter Generational Pointer)
         *  If all conditions below are satisfied, the 'value' is an IGP.
         *   1, 'block' points to the elder-from region.
         *   2, the field specified by 'index' holds block pointer
         *   3, 'value' points to blocks in the younger region.
         * Note: It is not necessary to add references from elder object to
         *     FLOB to assignements, because all FLOBs are traced as rootset
         *     at minor GC.
         */
        if(isInElderFromRegion(header) &&
           isPointerField(header, index) &&
           isInYoungerRegion(BLOCK_TO_HEADER(value.blockRef)))
        {
/*
            DBGWRAP(LOG.debug("add an assignment from %x to %x",
                              block, value.blockRef));
*/
            assignments_.push_front((Cell**)fieldAddress);
        }
        *fieldAddress = value;
        INVOKE_ON_HEAP_MONITORS(afterUpdateField(block, index, value));
    }

    INLINE_FUN static
    void updateField_D(Cell* block, int index, const double& value)
        throw(IMLException)
    {
// ToDo : add beforeUpdateField_D
//        INVOKE_ON_HEAP_MONITORS(beforeUpdateField(block, index, value));
        ASSERT(isValidBlockPointer(block));
        ASSERT(isValidBlockField(BLOCK_TO_HEADER(block), index));
        ASSERT(isValidBlockField(BLOCK_TO_HEADER(block), index + 1));
        BlockHeader* header = BLOCK_TO_HEADER(block);
        ASSERT(!isPointerField(header, index));
        ASSERT(!isPointerField(header, index + 1));

        Cell* fieldAddress = block + index;

        *(double*)fieldAddress = value;
//        INVOKE_ON_HEAP_MONITORS(afterUpdateField(block, index, value));
    }

    INLINE_FUN static
    Cell* allocRecordBlock(Bitmap bitmap, int fields)
        throw(IMLException)
    {
        INVOKE_ON_HEAP_MONITORS(beforeAllocRecordBlock(bitmap, fields));
        int totalSize = fields + 1;
        ASSERT(totalSize <= MAX_RECORDBLOCK_PAYLOAD_SIZE);
        // Record block has one field trailer.
        BlockHeader* header = allocRawBlock(totalSize);
        // the number of user fields is stored in the header.
        setHeader(header, fields, BLOCKTYPE_RECORD, BOOLVALUE_FALSE);
        Cell* block = HEADER_TO_BLOCK(header);
        ASSERT(isAlignedBlockAddress(block));
        *((Bitmap*)(&block[fields])) = bitmap; // the last cell
        INVOKE_ON_HEAP_MONITORS(afterAllocRecordBlock(bitmap, fields, block));
        return block;
    }

    INLINE_FUN static
    Cell* allocAtomBlock(int fields)
        throw(IMLException)
    {
        INVOKE_ON_HEAP_MONITORS(beforeAllocAtomBlock(fields));
        BlockHeader* header = allocRawBlock(fields);
        setHeader(header, fields, BLOCKTYPE_ATOM, BOOLVALUE_FALSE);
        Cell* block = HEADER_TO_BLOCK(header);
        ASSERT(isAlignedBlockAddress(block));
        INVOKE_ON_HEAP_MONITORS(afterAllocAtomBlock(fields, block));
        return block;
    }

    INLINE_FUN static
    Cell* allocPointerBlock(int fields)
        throw(IMLException)
    {
        INVOKE_ON_HEAP_MONITORS(beforeAllocPointerBlock(fields));
        BlockHeader* header = allocRawBlock(fields);
        setHeader(header, fields, BLOCKTYPE_POINTER, BOOLVALUE_FALSE);
        Cell* block = HEADER_TO_BLOCK(header);
        ASSERT(isAlignedBlockAddress(block));
        INVOKE_ON_HEAP_MONITORS(afterAllocPointerBlock(fields, block));
        return block;
    }

    INLINE_FUN static
    Cell* allocSingleAtomArray(int fields, bool isMutable)
        throw(IMLException)
    {
        INVOKE_ON_HEAP_MONITORS(beforeAllocAtomArray(fields));
        BlockType blockType =
            isMutable
            ? BLOCKTYPE_SINGLE_ATOM_MUTABLE_ARRAY
            : BLOCKTYPE_SINGLE_ATOM_IMMUTABLE_ARRAY;
        BlockHeader* header = allocRawBlock(fields);
        setHeader(header, fields, blockType, BOOLVALUE_FALSE);
        Cell* block = HEADER_TO_BLOCK(header);
        ASSERT(isAlignedBlockAddress(block));
        INVOKE_ON_HEAP_MONITORS(afterAllocAtomArray(fields, block));
        return block;
    }

    INLINE_FUN static
    Cell* allocDoubleAtomArray(int fields, bool isMutable)
        throw(IMLException)
    {
        INVOKE_ON_HEAP_MONITORS(beforeAllocAtomArray(fields));
        BlockType blockType =
            isMutable
            ? BLOCKTYPE_DOUBLE_ATOM_MUTABLE_ARRAY
            : BLOCKTYPE_DOUBLE_ATOM_IMMUTABLE_ARRAY;
        BlockHeader* header = allocRawBlock(fields);
        setHeader(header, fields, blockType, BOOLVALUE_FALSE);
        Cell* block = HEADER_TO_BLOCK(header);
        ASSERT(isAlignedBlockAddress(block));
        INVOKE_ON_HEAP_MONITORS(afterAllocAtomArray(fields, block));
        return block;
    }

    INLINE_FUN static
    Cell* allocPointerArray(int fields, bool isMutable)
        throw(IMLException)
    {
        INVOKE_ON_HEAP_MONITORS(beforeAllocPointerArray(fields));
        BlockType blockType =
            isMutable
            ? BLOCKTYPE_POINTER_MUTABLE_ARRAY
            : BLOCKTYPE_POINTER_IMMUTABLE_ARRAY;
        BlockHeader* header = allocRawBlock(fields);
        setHeader(header, fields, blockType, BOOLVALUE_FALSE);
        Cell* block = HEADER_TO_BLOCK(header);
        ASSERT(isAlignedBlockAddress(block));
        INVOKE_ON_HEAP_MONITORS(afterAllocPointerArray(fields, block));
        return block;
    }

    INLINE_FUN static
    Cell* allocLargeIntBlock(LargeInt::largeInt* src)
        throw(IMLException)
    {
        INVOKE_ON_HEAP_MONITORS(beforeAllocLargeIntBlock());
        int fields = CELLS_OF_LARGEINT;
        BlockHeader* header = allocRawBlock(fields);
        setHeader(header, fields, BLOCKTYPE_LARGEINT, BOOLVALUE_FALSE);
        Cell* block = HEADER_TO_BLOCK(header);
        ASSERT(isAlignedBlockAddress(block));
        if(src){
            LargeInt::initAndSet(*(LargeInt::largeInt*)block, *src);
        }
        else{
            LargeInt::init(*(LargeInt::largeInt*)block);
        }
        // we have to call LargeInt::release at finalization of the block.
        addFinalizable(block);
        INVOKE_ON_HEAP_MONITORS(afterAllocLargeIntBlock(block));
        return block;
    }

    INLINE_FUN static
    Cell* allocEmptyBlock()
        throw(IMLException)
    {
        return unitBlock_;
    }

    /**
     *  The argument is the number of words required for header, payload and
     * trailer.
     */
    INLINE_FUN static
    BlockHeader* allocFixedRawBlock(int totalWords)
    {
        BlockSize numBytes = sizeof(UInt32Value) * totalWords;

        void* memory = ALLOCATE_MEMORY(numBytes + BLOCK_ALIGNMENT);
        if(NULL == memory){throw OutOfMemoryException();}

        BlockHeader* newHeader = alignHeaderAddress((BlockHeader*)memory);
        Cell* newBlock = HEADER_TO_BLOCK(newHeader);

        FLOBInfo* info = new FLOBInfo(memory);
        FLOBInfoMap_[newBlock] = info;

//        DBGWRAP(LOG.debug("fixedCopy: %x", newBlock));
        return newHeader;
    }

    INLINE_FUN static
    Cell* fixedCopy(Cell* block)
    {
        BlockHeader* header = BLOCK_TO_HEADER(block);

        BlockHeader* newHeader = allocFixedRawBlock(getTotalWords(header));
        Cell* newBlock = HEADER_TO_BLOCK(newHeader);

        COPY_MEMORY(newHeader,
                    header,
                    getTotalWords(header) * sizeof(UInt32Value));
//        DBGWRAP(LOG.debug("fixedCopy: %x", newBlock));

        return newBlock;
    }

    INLINE_FUN static
    void releaseFLOB(Cell* block)
    {
        FLOBInfoMap::iterator i = FLOBInfoMap_.find(block);
        if(i == FLOBInfoMap_.end()){
            throw IllegalArgumentException();
        }
        i->second->isReleased_ = true;
//        DBGWRAP(LOG.debug("releaseFLOB: %x", block));
    }

    /**
     * allocates a new heap block which has enough size to hold the payload
     * and trailers of the argument block.
     */
    INLINE_FUN static
    Cell* reserveCopy(Cell* block)
    {
        BlockHeader* header = BLOCK_TO_HEADER(block);
        BlockHeader header_value = *header;
        BlockHeader* newHeader;
        if(isFLOBPointer(header)){
            newHeader = allocFixedRawBlock(getTotalWords(header));
        }
        else{
            int payloadAndTrailers = getTotalWords(header) - WORDS_OF_HEADER;
            newHeader = allocRawBlock(payloadAndTrailers);
        }
        /* Note: 'block' now may be made invalid by GC. */
        *newHeader = header_value;

        Cell* newBlock = HEADER_TO_BLOCK(newHeader);
        return newBlock;
    }

    /**
     * copy the payload and trailers of srcBlock to dstBlock.
     */
    INLINE_FUN static
    void copyBlock(Cell* srcBlock, Cell* dstBlock)
    {
        int payloadAndTrailers =
            getTotalWords(BLOCK_TO_HEADER(srcBlock)) - WORDS_OF_HEADER;
        COPY_MEMORY(dstBlock, srcBlock, sizeof(Cell) * payloadAndTrailers);
    }

    static
    bool isSimilarBlockGraph(Cell* block1, Cell* block2);

};

///////////////////////////////////////////////////////////////////////////////

END_NAMESPACE

#endif
