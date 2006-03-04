/**
 * @author YAMATODANI Kiyoshi
 * @version $Id: Heap.cc,v 1.6 2006/02/27 09:12:59 kiyoshiy Exp $
 */
#include "Heap.hh"
#include "IllegalStateException.hh"
#include "Debug.hh"

BEGIN_NAMESPACE(jp_ac_jaist_iml_runtime)

///////////////////////////////////////////////////////////////////////////////
// Macros for walking on the heap

Heap::Tracer Heap::tracer_;

RootSet* Heap::rootset_ = 0;

Heap::GCMode
Heap::currentGC_ = Heap::GC_NONE;

UInt32Value* Heap::heap_ = 0;
Cell* Heap::unitBlock_ = 0;

Heap::HeapRegion
Heap::youngerRegion_;

Heap::HeapRegion
Heap::elderFromRegion_;

Heap::HeapRegion
Heap::elderToRegion_;

Heap::HeapRegion
Heap::copyToRegion_;

VariableLengthArray Heap::assignments_;

#ifdef IML_ENABLE_HEAP_MONITORING
VariableLengthArray Heap::monitors_;
#endif

///////////////////////////////////////////////////////////////////////////////
// Constructor

Heap::Heap(int size, RootSet* rootset)
{
    initialize(size, rootset);
}

Heap::~Heap()
{
    finalize();
}

void
Heap::initialize(int size, RootSet* rootset)
{
    rootset_ = rootset;
    currentGC_ = GC_NONE;
    heap_ =
    (UInt32Value*)
    (ALLOCATE_MEMORY(sizeof(UInt32Value) * (size * 3) + WORDS_OF_HEADER));
    if(NULL == heap_){throw OutOfMemoryException();}
    youngerRegion_ = HeapRegion(heap_, size);
    elderFromRegion_ = HeapRegion(heap_ + size, size);
    elderToRegion_ = HeapRegion(heap_ + size + size, size);
    BlockHeader* unitBlockHeader = (BlockHeader*)(heap_ + size + size + size);
    unitBlock_ = HEADER_TO_BLOCK(unitBlockHeader);
    setHeader(unitBlockHeader, 0, BLOCKTYPE_ATOM, false);
    copyToRegion_ = HeapRegion(0, 0);
    assignments_.clear();
}

void
Heap::finalize()
{
    clear();
    RELEASE_MEMORY(heap_);
}

///////////////////////////////////////////////////////////////////////////////

void
Heap::setRootSet(RootSet* rootset)
{
    rootset_ = rootset;
}

int
Heap::addMonitor(HeapMonitor* monitor)
{
#ifdef IML_ENABLE_HEAP_MONITORING
    int index = monitors_.getCount();
    monitors_.add(monitor); // ToDo : search empty slot and store in that slot.
    return index;
#else
    return -1;
#endif
}

HeapMonitor*
Heap::removeMonitor(int index)
{
#ifdef IML_ENABLE_HEAP_MONITORING
    if((index < 0) || (monitors_.getCount() <= index)){
        throw IllegalArgumentException();
    }
    HeapMonitor* monitor =
    (HeapMonitor*)
    monitors_.getContents()[index];
    monitors_.getContents()[index] = 0;
    return monitor;
#else
    return 0;
#endif
}

///////////////////////////////////////////////////////////////////////////////

BlockSize
Heap::getTotalWords(BlockHeader* header)
{
    BlockSize payloadSize = getPayloadCells(header) * WORDS_OF_CELL;

    if(BLOCKTYPE_RECORD == getType(header))
    {
        return payloadSize + WORDS_OF_HEADER + WORDS_OF_BITMAP;
    }
    else
    {
        return payloadSize + WORDS_OF_HEADER;
    }
}

INLINE_FUN 
BoolValue
Heap::isForwarded(BlockHeader* header)
{
    return (0 != (*header & FORWARDED_MASK));
}

INLINE_FUN 
void
Heap::setForwarded(BlockHeader* header, BoolValue forwarded)
{
    ASSERT(isValidHeaderPointer(header));

    BlockHeader forwardedBit = forwarded ? 1 : 0;
    *header |=  (forwardedBit << FORWARDED_SHIFT) & FORWARDED_MASK;
}

Bitmap
Heap::getBitmapTag(BlockHeader* header)
{
    ASSERT(BLOCKTYPE_RECORD == getType(header));

    // bitmap information is stored in the next cell of the last cell of
    // payload.
    return (Bitmap)(HEADER_TO_BLOCK(header)[getPayloadCells(header)].uint32);
}

void
Heap::setBitmapTag(BlockHeader* header, Bitmap bitmap)
{
    ASSERT(BLOCKTYPE_RECORD == getType(header));

    Cell* block = HEADER_TO_BLOCK(header);
    *((Bitmap*)(&block[getPayloadCells(header)])) = bitmap; // the last cell
}

BoolValue
Heap::isValidBlockField(BlockHeader* header, int index)
{
    return ((0 <= index) && (index < getPayloadCells(header)));
}

BoolValue
Heap::isPointerField(Cell* block, int index)
{
    // delegate to the isPointerField(BlockHeader*, int)
    return (isPointerField(BLOCK_TO_HEADER(block), index));
}

BoolValue
Heap::isPointerField(BlockHeader* header, int index)
{
    BlockType type = getType(header);
    switch(type)
    {
      case BLOCKTYPE_RECORD:
        {
            Bitmap bitmap = getBitmapTag(header);
            return (((1UL << index) & bitmap) != 0UL);
        }

      case BLOCKTYPE_POINTER:
      case BLOCKTYPE_POINTER_ARRAY:
        return BOOLVALUE_TRUE;

      case BLOCKTYPE_ATOM:
      case BLOCKTYPE_SINGLE_ATOM_ARRAY:
      case BLOCKTYPE_DOUBLE_ATOM_ARRAY:
        return BOOLVALUE_FALSE;

      default:
        DBGWRAP(LOG.error("isPointerField::IllegalStateException"));
        throw IllegalStateException();
    }
}

INLINE_FUN 
BoolValue
Heap::isValidHeaderPointer(BlockHeader* header)
{
    if(BLOCK_TO_HEADER(unitBlock_) == header){ return true; }

    switch(currentGC_)
    {
      case GC_NONE:
        return (isInYoungerRegion(header) ||
                isInElderFromRegion(header));

      case GC_MINOR:
        return (isInYoungerRegion(header) ||
                isInElderFromRegion(header));

      case GC_MAJOR:
        return (isInYoungerRegion(header) ||
                isInElderFromRegion(header) ||
                isInElderToRegion(header));

      default:
        DBGWRAP(LOG.error("isValidHeaderPointer::IllegalStateException"));
        throw IllegalStateException();
    }
}

INLINE_FUN 
BoolValue
Heap::isValidBlockPointer(Cell* block)
{
    if(NULL == block){
        return false;
    }
    else{
        return isValidHeaderPointer(BLOCK_TO_HEADER(block));
    }
}

void
Heap::invokeMinorGC()
{
    INVOKE_ON_HEAP_MONITORS(beforeMinorGC());

    DBGWRAP(LOG.debug("begin minor GC"));

    // The minor GC copies live blocks to the elder-from region.
    currentGC_ = GC_MINOR;
    copyToRegion_ = elderFromRegion_;

    // 'copiedBegin' is a pointer to the area into which the minor GC copies
    // live blocks in the younger region.
    BlockHeader* copiedBegin = (BlockHeader*)(copyToRegion_.free_);

    try
    {
        // scans assignments
        Cell*** pblocks = (Cell***)(assignments_.getContents());
        int size = assignments_.getCount();
        for(int index = 0 ; index < size ; index += 1)
        {
            ASSERT(isValidBlockPointer(**pblocks));
            **pblocks = update(**pblocks);
            pblocks += 1;
        }

        // scans roots the client holds
        rootset_->trace(&tracer_);

        // scans copied blocks and copies reachable blocks recursively.
        scanToRegion(copiedBegin);
    }
    catch(NoEnoughHeapException&)
    {
        invokeMajorGC();
    }

#ifdef IML_DEBUG    
    FILL_MEMORY(youngerRegion_.begin_,
                0xFF,
                sizeof(*(youngerRegion_.end_)) *
                (youngerRegion_.end_ - youngerRegion_.begin_));
#endif
    elderFromRegion_.free_ = copyToRegion_.free_;// writes back
    youngerRegion_.free_ = youngerRegion_.begin_;// empties the younger region.
    assignments_.clear();// empties the assignments

    currentGC_ = GC_NONE;

    DBGWRAP(LOG.debug("end minor GC"));
    INVOKE_ON_HEAP_MONITORS(afterMinorGC());
};

void
Heap::invokeMajorGC()
{
    INVOKE_ON_HEAP_MONITORS(beforeMajorGC());
    DBGWRAP(LOG.debug("begin major GC"));

    currentGC_ = GC_MAJOR;

    // copies live blocks into the 'elder-to' region
    copyToRegion_ = elderToRegion_;

    BlockHeader* copiedBegin = (BlockHeader*)(copyToRegion_.free_);

    // scans roots
    rootset_->trace(&tracer_);

    scanToRegion(copiedBegin);

#ifdef IML_DEBUG    
    FILL_MEMORY(elderFromRegion_.begin_,
                0xFF,
                sizeof(*(elderFromRegion_.end_)) *
                (elderFromRegion_.end_ - elderFromRegion_.begin_));
#endif
    elderToRegion_.free_ = copyToRegion_.free_;

    // swaps the elder-from region and the elder-to region.
    HeapRegion tempRegion = elderFromRegion_;
    elderFromRegion_ = elderToRegion_;
    elderToRegion_ = tempRegion;

    // empties the elder-to region (previous elder-from region)
    elderToRegion_.free_ = elderToRegion_.begin_;

    DBGWRAP(LOG.debug("end major GC"));
    INVOKE_ON_HEAP_MONITORS(afterMajorGC());
}

void
Heap::scanToRegion(BlockHeader* copiedBegin)
{
    // 'scan' points to the first cell of the payload, not to the header.
    BlockHeader* scanHeader = alignHeaderAddress(copiedBegin);
    while(((UInt32Value*)scanHeader) < copyToRegion_.free_)
    {
        Cell* scan = HEADER_TO_BLOCK(scanHeader);

        BlockType type = getType(scanHeader);
        switch(type)
        {
          case BLOCKTYPE_POINTER:
          case BLOCKTYPE_POINTER_ARRAY:
            {
                int fields = getPayloadCells(scanHeader);
                for(int index = 0; index < fields; index += 1)
                {
                    Cell updated;
                    updated.blockRef = update(scan[index].blockRef);
                    initializeField(scan, index, updated);
                }
            }
            break;

          case BLOCKTYPE_RECORD:
            {
                int fields = getPayloadCells(scanHeader);
                Bitmap bitmap = getBitmapTag(scanHeader);
                for(int index = 0; index < fields; index += 1)
                {
                    if(0 != (bitmap & 0x01)){
                        Cell updated;
                        updated.blockRef = update(scan[index].blockRef);
                        initializeField(scan, index, updated);
                    }
                    bitmap >>= 1;
                }
            }
            break;

          case BLOCKTYPE_ATOM:
          case BLOCKTYPE_SINGLE_ATOM_ARRAY:
          case BLOCKTYPE_DOUBLE_ATOM_ARRAY:
            break;

          default:
            DBGWRAP(LOG.error("scanToRegion::IllegalStateException"));
            throw IllegalStateException();
        }
        scanHeader = NEXT_HEADER(scanHeader);
    }
}

INLINE_FUN 
Cell*
Heap::copyToToRegion(Cell* block)
{
    BlockHeader* header = BLOCK_TO_HEADER(block);
    ASSERT(isInFromRegion(header));

    BlockSize totalWords = getTotalWords(header);
    BlockHeader* destHeader = alignHeaderAddress(copyToRegion_.free_);
    if(copyToRegion_.end_ < (destHeader + totalWords))
    {
        DBGWRAP(LOG.error("copyToToRegion::NoEnoughHeapException"));
        throw NoEnoughHeapException();
    }

    COPY_MEMORY(destHeader, header, totalWords * sizeof(UInt32Value));

    // returns a pointer to the first cell of payload, not to the header.
    Cell* copied = HEADER_TO_BLOCK(destHeader);

    copyToRegion_.free_ = destHeader + totalWords;

    // embeds forward pointer
    block[0].blockRef = copied;
    setForwarded(header, BOOLVALUE_TRUE);

    return copied;
};

INLINE_FUN 
Cell*
Heap::update(Cell* block)
{
    if(NULL == block){// block pointer may be null.
        return block;
    }
    if(unitBlock_ == block){// unit block
        return block;
    }
    BlockHeader* header = BLOCK_TO_HEADER(block);

    if(isInToRegion(header))
    {
        return block;
    }
    else
    {
        ASSERT(isInFromRegion(header));
        if(isForwarded(header))
        {
            Cell* forwardPointer = block[0].blockRef;
            if(isInToRegion(BLOCK_TO_HEADER(forwardPointer)))
            {
                return forwardPointer;
            }
            else
            {
                ASSERT(GC_MAJOR == currentGC_);
                ASSERT(isInYoungerRegion(header));
                ASSERT(isInElderFromRegion(BLOCK_TO_HEADER(forwardPointer)));

                if(isForwarded(BLOCK_TO_HEADER(forwardPointer)))
                {
                    Cell* doubleForwardPointer = forwardPointer[0].blockRef;

                    ASSERT
                    (isInElderToRegion(BLOCK_TO_HEADER(doubleForwardPointer)));

                    return doubleForwardPointer;
                }
                else
                {
                    return copyToToRegion(forwardPointer);
                }
            }
        }
        else // not forwarded
        {
            return copyToToRegion(block);
        }
    }
}

bool
Heap::isSimilarBlockGraph(Cell* block1, Cell* block2)
{
    if(block1 == block2){ return true; }
    if((NULL == block1) || (NULL == block2)){ return false; }

    BlockHeader* header1 = BLOCK_TO_HEADER(block1);
    BlockHeader* header2 = BLOCK_TO_HEADER(block2);

    UInt32Value size1 = getPayloadCells(header1);
    UInt32Value size2 = getPayloadCells(header2);
    if(size1 != size2){ return false; }

    BlockType type1 = getType(header1);
    BlockType type2 = getType(header2);
    if(type1 != type2){ return false; }

    if((BLOCKTYPE_SINGLE_ATOM_ARRAY == type1)
       || (BLOCKTYPE_DOUBLE_ATOM_ARRAY == type1)
       || (BLOCKTYPE_POINTER_ARRAY == type1)){
        return block1 == block2;
    }
    else{
        if(BLOCKTYPE_RECORD == type1){
            Bitmap bitmap1 = getBitmapTag(header1);
	    Bitmap bitmap2 = getBitmapTag(header2);
	    if(bitmap1 != bitmap2){ return false; }
	}

        for(int index = 0; index < size1; index += 1){
            Cell field1 = block1[index];
            Cell field2 = block2[index];
            if(isPointerField(header1, index)){
                if(false
                   == isSimilarBlockGraph(field1.blockRef, field2.blockRef))
                {
                    return false;
                }
            }
            else{
                if(field1.uint32 != field2.uint32){
                    return false;
                }
            }
        }
        return true;
    }
}

void
Heap::forceGC()
    throw(IMLRuntimeException)
{
    invokeMinorGC();
}


///////////////////////////////////////////////////////////////////////////////

void 
Heap::clear()
    throw(IMLRuntimeException)
{
    currentGC_ = GC_NONE;
    youngerRegion_.free_ = youngerRegion_.begin_;
    elderFromRegion_.free_ = elderFromRegion_.begin_;
    elderToRegion_.free_ = elderToRegion_.begin_;
    assignments_.clear();
#ifdef IML_ENABLE_HEAP_MONITORING
    monitors_.clear();
#endif
}

///////////////////////////////////////////////////////////////////////////////

void
Heap::Tracer::trace(Cell*** roots, int count)
    throw(IMLRuntimeException)
{
    Cell*** pointersToBlockPointers = roots;
    for(int index = 0; index < count; index += 1)
    {
        **pointersToBlockPointers = update(**pointersToBlockPointers);
        pointersToBlockPointers += 1;
    }
}

void
Heap::Tracer::trace(Cell** roots, int count)
    throw(IMLRuntimeException)
{
    Cell** blockPointers = roots;
    for(int index = 0 ; index < count ; index += 1)
    {
        *blockPointers = update(*blockPointers);
        blockPointers += 1;
    }
}

///////////////////////////////////////////////////////////////////////////////

DBGWRAP(LogAdaptor Heap::LOG =
        LogAdaptor("Heap"));

///////////////////////////////////////////////////////////////////////////////

END_NAMESPACE
