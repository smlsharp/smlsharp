#ifndef RuntimeTypes_hh_
#define RuntimeTypes_hh_

#include "SystemDef.hh"
#include "IMLRuntimeException.hh"

BEGIN_NAMESPACE(jp_ac_jaist_iml_runtime)

///////////////////////////////////////////////////////////////////////////////

/**
 *  Bitmap information indicating which fields hold reference to the heap
 * blocks.
 *
 * <p>
 * The least significant bit indicates whether the first (= 0-th) field of
 * the block holds a block pointer, and the most significant bit indicates
 * whether the 31-th field of the block holds a block pointer.
 * If the i-th bit is set (= 1), the i-th field holds a block pointer.
 * </p>
 * <p>
 *  The width of bitmap is defined according to the specification of the
 * compiler.
 * </p>
 */
typedef UInt32Value Bitmap;

////////////////////////////////////////

/**
 * Building unit of a heap area.
 */
typedef union U_Cell
{
    /** reference to a heap block */
    U_Cell* blockRef;

    /** signed integer value */
    SInt32Value sint32;
    
    /** unsigned integer value */
    UInt32Value uint32;

    /** single precision floating point value */
    Real32Value real32;

} Cell;

///////////////////////////////////////////////////////////////////////////////

/**
 * Interface through which a client tells the heap manager the rootset which
 * the client holds.
 *
 * <p>
 * At the beginning of GC, the heap manager passes an instance of this
 * <code>RootTracer</code> class to its client. The client should update its
 * rootset by invoking the <code>trace</code> method on this
 * <code>RootTracer</code> object passed.
 * </p>
 * <p>
 * Usage: the following class implements <code>RootSet</code> itnerface,
 * and calls the two versions of '<code>trace</code>' method of this
 * <code>RootTracer</code> class.
 * </p>
 * <pre>
 * class MyVM : public RootSet
 * {
 *   private:
 *     Cell* Accum_;
 *     Cell* Env_;
 *     List&lt;Cell**&gt; temporaryRootsList_;
 *        :
 *   public:
 *     void exec(Byte code[])
 *     {
 *       while(){
 *         Byte inst = code[pc];
 *         switch(OPERATOR(inst)){
 *                :
 *         case SOME_INST:
 *                :
 *           Cell* block = heap.allocPointerBlock(2);
 * &nbsp;
 *           //  If the following computations include any allocation,
 *           // those might trigger GC, which would discard the last allocated
 *           // block which the 'block' points to.
 *           //  By keeping the address of the 'block' variable in the list
 *           // in advance, the 'trace' method below can pass the address of
 *           // the 'block' to the heap manager, so that the GC keeps the
 *           // block in the heap and  the content of 'block' would be updated
 *           // to point to the new location of the block.
 *           temporaryRootsList_.push(&amp;block);
 *                :
 *           Cell valueA = ... some computation ...
 *           Cell valueB = ... some computation ...
 *                :
 *           block[0] = valueA;
 *           block[1] = valueB;
 *                :
 *           temporaryRootsList_.pop(1);
 *           break;
 *         }
 *       }
 *     }
 *           :
 *     void trace(RootTracer* tracer)
 *     {
 *       // The next two statements call the trace(Cell**,int) method.
 *       tracer->trace(&amp;Accum_, 1);
 *       tracer->trace(&amp;Env_, 1);
 *           :
 *       // The trace(Cell***,int) method is called in the following code.
 *       Cell*** temporaryRoots = temporaryRootsList_.contents();
 *       tracer->trace(temporaryRoots, temporaryRootsList_.count());
 *     }
 * };
 * </pre>
 */
class RootTracer
{
  public:
    
    /**
     * Traces roots.
     *
     * <p>
     * You can invoke this method only from RootSet::trace().
     * </p>
     *
     * @param roots array of pointers to pointers to Cell (= the top of block.)
     * @param count the number of elements in the 'roots'
     */
    virtual
    void trace(Cell*** roots, int count)
        throw(IMLException)
        = 0;

    /**
     * Traces roots.
     *
     * <p>
     * You can invoke this method only from RootSet::trace().
     * </p>
     *
     * @param roots array of pointer to Cell (= the top of block).
     * @param count the number of elements in the 'roots'
     */
    virtual
    void trace(Cell** roots, int count)
        throw(IMLException)
        = 0;

    /**
     * Traces root.
     *
     * <p>
     * You can invoke this method only from RootSet::trace().
     * </p>
     *
     * @param root a pointer a block.
     * @return a pointer to block which may be at new location.
     */
    virtual
    Cell* trace(Cell* roots)
        throw(IMLException)
        = 0;

};

////////////////////////////////////////

/**
 * Interface which every client of the heap manager must implement.
 *
 * <p>
 *  Anyone who wants to use the service of heap manager must implement
 * this interface and pass it to the heap manager.
 * </p>
 *
 * @see RootTracer
 */
class RootSet
{
  public:

    /**
     * The heap manager invokes this method at the time of GC.
     * Heap client must pass its rootset to RootTracer::trace
     *
     * @param tracer an interface by which client should pass rootset
     * @see RootTracer::trace
     */
    virtual
    void trace(RootTracer* tracer)
        throw(IMLException)
        = 0;
};

///////////////////////////////////////////////////////////////////////////////

class FinalizerExecutor
{
  public:

    virtual
    void executeFinalizer(Cell* finalizable)
        = 0;
};

///////////////////////////////////////////////////////////////////////////////

END_NAMESPACE

#endif /* RuntimeTypes_hh_ */
