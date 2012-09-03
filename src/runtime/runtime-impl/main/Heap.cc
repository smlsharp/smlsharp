/**
 * @author YAMATODANI Kiyoshi
 * @version $Id: Heap.cc,v 1.14 2007/06/01 09:40:59 kiyoshiy Exp $
 */
#include "Heap.hh"
#include "IllegalStateException.hh"
#include "OutOfMemoryException.hh"
#include "Debug.hh"

BEGIN_NAMESPACE(jp_ac_jaist_iml_runtime)

///////////////////////////////////////////////////////////////////////////////
// Macros for walking on the heap

Heap::Tracer Heap::tracer_;

RootSet* Heap::rootset_ = 0;

FinalizerExecutor* Heap::finalizeExecutor_ = 0;

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

Heap::BlockPointerRefList Heap::assignments_;

Heap::BlockPointerList Heap::reachableFinalizables_;

Heap::BlockPointerList Heap::unreachableFinalizables_;

Heap::FLOBInfoMap Heap::FLOBInfoMap_;

#ifdef IML_ENABLE_HEAP_MONITORING
Heap::HeapMonitorList Heap::monitors_;
#endif

///////////////////////////////////////////////////////////////////////////////
// Constructor

Heap::Heap(int size, RootSet* rootset, FinalizerExecutor* finalizeExecutor)
{
    initialize(size, rootset);
}

Heap::~Heap()
{
    finalize();
}

void
Heap::initialize(int size,
                 RootSet* rootset,
                 FinalizerExecutor* finalizeExecutor)
{
    rootset_ = rootset;

    finalizeExecutor_ = finalizeExecutor;

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

    reachableFinalizables_.clear();
    unreachableFinalizables_.clear();

    for(FLOBInfoMap::iterator i = FLOBInfoMap_.begin();
        i != FLOBInfoMap_.end();
        i++)
    {
        delete i->second;
    }
    FLOBInfoMap_.clear();
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

void
Heap::setFinalizerExecutor(FinalizerExecutor* finalizeExecutor)
{
    finalizeExecutor_ = finalizeExecutor;
}

void
Heap::addMonitor(HeapMonitor* monitor)
{
#ifdef IML_ENABLE_HEAP_MONITORING
    monitors_.push_front(monitor);
#endif
}

void
Heap::addFinalizable(Cell* block)
{
    ASSERT(BLOCKTYPE_RECORD == getType(BLOCK_TO_HEADER(block)));
    DBGWRAP(LOG.debug("add finalizable %x", block));
    DBGWRAP(LOG.debug("reachables = %d, unreachables = %d",
                   reachableFinalizables_.size(),
                   unreachableFinalizables_.size()));
    reachableFinalizables_.push_front(block);
}

///////////////////////////////////////////////////////////////////////////////

Heap::BlockSize
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
bool
Heap::isForwarded(BlockHeader* header)
{
    return (0 != (*header & FORWARDED_MASK));
}

INLINE_FUN 
void
Heap::setForwarded(BlockHeader* header, bool forwarded)
{
    ASSERT(isValidHeaderPointer(header));

    if(forwarded){
        *header |= FORWARDED_MASK;
    }
    else{
        *header &= ~FORWARDED_MASK;
    }
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

bool
Heap::isValidBlockField(BlockHeader* header, int index)
{
    return ((0 <= index) && (index < getPayloadCells(header)));
}

bool
Heap::isFLOB(Cell* block)
{
    return isFLOBPointer(BLOCK_TO_HEADER(block));
}

bool
Heap::isPointerField(Cell* block, int index)
{
    // delegate to the isPointerField(BlockHeader*, int)
    return (isPointerField(BLOCK_TO_HEADER(block), index));
}

bool
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
bool
Heap::isValidHeaderPointer(BlockHeader* header)
{
    if(BLOCK_TO_HEADER(unitBlock_) == header){ return true; }
    if(isFLOBPointer(header)){ return true; }

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

bool
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
Heap::invokeMinorGC(bool forceMajorGC)
{
    INVOKE_ON_HEAP_MONITORS(beforeMinorGC());

    DBGWRAP(LOG.debug("begin minor GC"));

    // The minor GC copies live blocks to the elder-from region.
    currentGC_ = GC_MINOR;
    copyToRegion_ = elderFromRegion_;

    // 'copiedBegin' is a pointer to the area into which the minor GC copies
    // live blocks in the younger region.
    BlockHeader* copiedBegin = (BlockHeader*)(copyToRegion_.free_);

    bool minorGCSucceeded = false;
    try
    {
        // update internal rootset
        updatePointerOfBlockPointerList(&assignments_);
        updateFLOBs();

        // scans roots the client holds
        rootset_->trace(&tracer_);

        // scans copied blocks and copies reachable blocks recursively.
        scanToRegion(copiedBegin);

        checkReachabilityOfFLOBs();
        checkReachabilityOfFinalizables();
        minorGCSucceeded = true;
    }
    catch(NoEnoughHeapException&)
    {
        invokeMajorGC();
    }
    if(minorGCSucceeded && forceMajorGC){invokeMajorGC();}

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

    // trace internal roots
    updateFLOBs();

    // scans client roots
    rootset_->trace(&tracer_);

    scanToRegion(copiedBegin);

    checkReachabilityOfFLOBs();
    checkReachabilityOfFinalizables();

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
Heap::updateFLOBs()
{
    switch(currentGC_)
    {
      case GC_MINOR:
        /* trace all FLOBs, because at MinorGC we cannot determine whether
         * a FLOB is reachable from user code.
         * A FLOB may be reachable from some heap block in elder region.
         */
        for (FLOBInfoMap::iterator i = FLOBInfoMap_.begin();
             i != FLOBInfoMap_.end();
             i++)
        {
            DBGWRAP(LOG.debug("FLOB is updated: %x", i->first));
            Cell* block = update(i->first);
            ASSERT(i->first == block);
        }
        break;

      case GC_MAJOR:
        /* trace FLOBs which are not released yet only.
         */
        for (FLOBInfoMap::iterator i = FLOBInfoMap_.begin();
             i != FLOBInfoMap_.end();
             i++)
        {
            if(i->second->isReleased_){
                DBGWRAP(LOG.debug("FLOB is skipped update: %x", i->first));
            }
            else{
                DBGWRAP(LOG.debug("FLOB is updated: %x", i->first));
                Cell* block = update(i->first);
                ASSERT(i->first == block);
            }
        }
        break;

      default:
        ASSERT(false);
    }
}

void
Heap::checkReachabilityOfFLOBs()
{
    switch(currentGC_)
    {
      case GC_MINOR:
        /* Because we cannot determine reachablity of FLOBs from user code
         * in MinorGC, all FLOBs are kept.
         */
        for (FLOBInfoMap::iterator i = FLOBInfoMap_.begin();
             i != FLOBInfoMap_.end();
             i++)
        {
            setForwarded(BLOCK_TO_HEADER(i->first), false);
        }
        break;

      case GC_MAJOR:
        for (FLOBInfoMap::iterator i = FLOBInfoMap_.begin();
             i != FLOBInfoMap_.end();
             i++)
        {
            if(i->second->isReleased_
               && !isForwarded(BLOCK_TO_HEADER(i->first)))
            {
                DBGWRAP(LOG.debug("FLOB is freed: %x", i->first));

                // this FLOB is in 'canfree' status.
                RELEASE_MEMORY(i->second->memory_);
                delete i->second;
                FLOBInfoMap_.erase(i);
            }
            else{
                DBGWRAP(LOG.debug("FLOB is not canfree: %x", i->first));
                setForwarded(BLOCK_TO_HEADER(i->first), false);
            }
        }
        break;

      default:
        ASSERT(false);
    }
}

void
Heap::checkReachabilityOfFinalizables()
{
    DBGWRAP(LOG.debug("checkReachabilityOfFinalizables:"));
    DBGWRAP(LOG.debug("reachables = %d, unreachables = %d",
                   reachableFinalizables_.size(),
                   unreachableFinalizables_.size()));

    BlockPointerList::iterator i;

    /*
     *  This function copies blocks into the new heap area, which may cause
     * NoEnoughHeapException raised.
     * In order to keep consistency of status even if aborted by an exception,
     * the following conditions have be satisfied.
     *  - No finalizable is contained in both reachables and unreachables at
     *   the same time.
     *  - Every finalizable is contained in either reachables or unreachables,
     *   unless it is found to be in cyclic dependency.
     */

    /* 1st phase.
     * copy all unreachables into the new heap area.
     */
    for(i = unreachableFinalizables_.begin();
        i != unreachableFinalizables_.end();
        i++)
    {
        DBGWRAP(LOG.debug("update unreachable %x", *i));
        *i = update(*i);
    }

    /* 2nd phase.
     *  - copy all blocks which are reachable from each finalizable to new
     *   heap area.
     *  - remove finalizables which is in cyclic dependency from reachables.
     */
    i = reachableFinalizables_.begin();
    while(i != reachableFinalizables_.end())
    {
        DBGWRAP(LOG.debug("update contents of reachable of %x", *i));
        *i = followForwardedPointer(*i);
        Cell* finalizable = *i;
        if(isVisited(BLOCK_TO_HEADER(finalizable)))
        {
            /* This finalizable block is reachable from other block.
             * And its contens has been already updated.
             */
            i++;
        }
        else{
            /* This finalizable block MAYBE unreachable.
             * Its contents is not updated yet.
             */

            UInt32Value* copiedStart = copyToRegion_.free_;

            // update contents only. The finalizable itself is not updated.
            updateBlockContents(finalizable);

            /* Now, direct children of the finalizable have just been copied
             * into the new heap area.
             * Then, scan those blocks to copy their descendents into new heap
             * area.
             */
            scanToRegion(copiedStart);

            /*
             * If the finalizable has been moved to new area by the last
             * scanToRegion, it means that it is in cyclic dependency.
             * Then, remove it from reachables.
             */
            if(isVisited(BLOCK_TO_HEADER(followForwardedPointer(finalizable))))
            {
                DBGWRAP(LOG.debug("cycle of finalizable is found for %x",
                                  finalizable));
                i = reachableFinalizables_.erase(i);
            }
            else{
                i++;
            }
        }
    }

    /*
     *  Now, every blocks reachable from the contents of finalizables in
     * reachableFinalizables_ are in new area.
     *
     * 3rd phase.
     *  Check whether each finalizable in reachables is in new area.
     * If it is in new area, this means that it is reachable from other block.
     * So, keep it in reachables.
     * Otherwise, remove it from reachables, and add to unreachables.
     */
    i = reachableFinalizables_.begin();
    while(i != reachableFinalizables_.end())
    {
        DBGWRAP(LOG.debug("check reachability of reachable finalizables"));
        Cell* finalizable = followForwardedPointer(*i);
        if(isVisited(BLOCK_TO_HEADER(finalizable)))
        {
            // keep it in reachables.
            *i = finalizable;
            i++;
        }
        else{
            /* This finalizable is not reachable from any other.
             */
            i = reachableFinalizables_.erase(i);
            unreachableFinalizables_.push_front(update(finalizable));
        }
    }
}

bool
Heap::runFinalizer()
{
    static bool inFinalizer = false;

    DBGWRAP(LOG.debug("Heap::runFinalizer: reachables = %d, unreachables = %d",
                   reachableFinalizables_.size(),
                   unreachableFinalizables_.size()));
    DBGWRAP(fflush(stdout));

    /*
     * An execution of a finalizer may cause GC, which calls this runFinalizer.
     * In such case, nested invocation of funFinalizer does nothing.
     */
    if(inFinalizer){return false;}

    inFinalizer = true;
    bool anyFinalized = false;
    try{
        BlockPointerList::iterator i = unreachableFinalizables_.begin();
        while(i != unreachableFinalizables_.end())
        {
            try{
                finalizeExecutor_->executeFinalizer(*i);
            }
            catch(...){
                i = unreachableFinalizables_.erase(i);
                throw;
            }
            i = unreachableFinalizables_.erase(i);
            anyFinalized = true;
        }
        inFinalizer = false;
        return anyFinalized;
    }
    catch(...){
        inFinalizer = false;
        throw;
    }
}

void
Heap::updateBlockContents(Cell* block)
{
    BlockHeader* header = BLOCK_TO_HEADER(block);

    BlockType type = getType(header);
    switch(type)
    {
      case BLOCKTYPE_POINTER:
      case BLOCKTYPE_POINTER_ARRAY:
        {
            int fields = getPayloadCells(header);
            for(int index = 0; index < fields; index += 1)
            {
                Cell updated;
                Cell* childBlock = block[index].blockRef;
                updated.blockRef = update(childBlock);
                initializeField(block, index, updated);
            }
        }
        break;

      case BLOCKTYPE_RECORD:
        {
            int fields = getPayloadCells(header);
            Bitmap bitmap = getBitmapTag(header);
            for(int index = 0; index < fields; index += 1)
            {
                if(0 != (bitmap & 0x01)){
                    Cell updated;
                    Cell* childBlock = block[index].blockRef;
                    updated.blockRef = update(childBlock);
                    initializeField(block, index, updated);
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
        DBGWRAP(LOG.error("updateBlockContents::IllegalStateException"));
        throw IllegalStateException();
    }
}

void
Heap::scanToRegion(BlockHeader* copiedBegin)
{
    // 'scan' points to the first cell of the payload, not to the header.
    BlockHeader* scanHeader = alignHeaderAddress(copiedBegin);
    while(((UInt32Value*)scanHeader) < copyToRegion_.free_)
    {
        updateBlockContents(HEADER_TO_BLOCK(scanHeader));

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
    setForwarded(header, true);

    return copied;
};

Cell* 
Heap::followForwardedPointer(Cell* block)
{
    BlockHeader* header = BLOCK_TO_HEADER(block);

    if(isInFromRegion(header))
    {
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
                    return forwardPointer;
                }
            }
        }
        else // not forwarded
        {
            return block;
        }
    }
    else
    {
        ASSERT(isInToRegion(header) || isFLOBPointer(header));
        return block;
    }
}

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
    Cell* currentBlock = followForwardedPointer(block);
    BlockHeader* currentHeader = BLOCK_TO_HEADER(currentBlock);
    if(isVisited(currentHeader))
    {
        return currentBlock;
    }
    else if(isFLOBPointer(currentHeader))
    {
        ASSERT(!isForwarded(currentHeader));
        // set forwarded bit to avoid cyclic recursive trace.
        setForwarded(currentHeader, true);
        try{
            DBGWRAP(LOG.debug("scanning FLOB: %x", currentBlock));
            // trace recursively from this FLOB.
            updateBlockContents(currentBlock);
        }
        catch(NoEnoughHeapException&){
            // reset forwarded bit if minor GC aborts.
            setForwarded(currentHeader, false); throw;
        }
        return currentBlock;
    }
    else
    {
        return copyToToRegion(currentBlock);
    }
}

void
Heap::updatePointerOfBlockPointerList(BlockPointerRefList* ppblocks)
{
    // scans list of bointer to pointer to block
    for(BlockPointerRefList::iterator i = ppblocks->begin() ;
        i != ppblocks->end() ;
        i++)
    {
        ASSERT(isValidBlockPointer(**i));
        **i = update(**i);
    }
}

void
Heap::updateBlockPointerList(BlockPointerList* pblocks)
{
    // scans list of bointer to block
    for(BlockPointerList::iterator i = pblocks->begin() ;
        i != pblocks->end() ;
        i++)
    {
        ASSERT(isValidBlockPointer(*i));
        *i = update(*i);
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
Heap::invokeGC(GCMode mode)
    throw(IMLException)
{
    switch(mode){
      case GC_MINOR:
        invokeMinorGC(false);
        break;
      case GC_MAJOR:
        invokeMinorGC(true);
        break;
      default:
        ASSERT(false);
    }
    if(runFinalizer()){
        // ToDo : 
    }
}


///////////////////////////////////////////////////////////////////////////////

void 
Heap::clear()
    throw(IMLException)
{
    currentGC_ = GC_NONE;

    youngerRegion_.free_ = youngerRegion_.begin_;
    elderFromRegion_.free_ = elderFromRegion_.begin_;
    elderToRegion_.free_ = elderToRegion_.begin_;

    assignments_.clear();

    reachableFinalizables_.clear();
    unreachableFinalizables_.clear();

    for(FLOBInfoMap::iterator i = FLOBInfoMap_.begin();
        i != FLOBInfoMap_.end();
        i++)
    {
        delete i->second;
    }
    FLOBInfoMap_.clear();

#ifdef IML_ENABLE_HEAP_MONITORING
    monitors_.clear();
#endif
}

///////////////////////////////////////////////////////////////////////////////

void
Heap::Tracer::trace(Cell*** roots, int count)
    throw(IMLException)
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
    throw(IMLException)
{
    Cell** blockPointers = roots;
    for(int index = 0 ; index < count ; index += 1)
    {
        *blockPointers = update(*blockPointers);
        blockPointers += 1;
    }
}

Cell*
Heap::Tracer::trace(Cell* root)
    throw(IMLException)
{
    return update(root);
}

///////////////////////////////////////////////////////////////////////////////

DBGWRAP(LogAdaptor Heap::LOG =
        LogAdaptor("Heap"));

///////////////////////////////////////////////////////////////////////////////

END_NAMESPACE
