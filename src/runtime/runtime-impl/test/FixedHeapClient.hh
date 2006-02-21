#ifndef FixedHeapClient_hh_
#define FixedHeapClient_hh_

#include "Heap.hh"

namespace jp_ac_jaist_iml_runtime
{

#include <assert.h>

/**
 * This class implements HeapClient interface.
 *
 * This class provides the heap manager with the rootset passed to 
 * the constructor.
 * The rootset can be set by the 'setRoots' method.
 * A root can be added to the rootset by the 'add' method.
 */
class FixedHeapClient
    : public RootSet
{
  public:

    ///////////////////////////////////////////////////////////////////////////
    // Constructors

    /**
     * Constructor
     *
     * @param roots new buffer which contains pointers to root pointers in
     *              roots[0] ... roots[count-1]
     * @param count the number of root pointers stored in roots
     * @param capacity the capacity of the roots
     */
    FixedHeapClient(Cell*** roots, int count, int capacity)
    {
        setRoots(roots, count, capacity);
    }

    /**
     * Constructor
     *
     * @param roots new buffer which contains pointers to root pointers in
     *              roots[0] ... roots[count-1]. The capacity of the roots
     *              is equal to the count.
     * @param count the number of root pointers stored in roots
     */
    FixedHeapClient(Cell*** roots, int count)
    {
        setRoots(roots, count, count);
    }

    ///////////////////////////////////////////////////////////////////////////
    // Instance methods

    /**
     * Replaces rootset.
     *
     * @param roots new buffer which contains pointers to root pointers in
     *              roots[0] ... roots[count-1]
     * @param count the number of root pointers stored in roots
     * @param capacity the capacity of the roots
     */
    void setRoots(Cell*** roots, int count, int capacity)
    {
        roots_ = roots;
        count_ = count;
        capacity_ = capacity;
    }

    /**
     * Adds a pointer to a block pointer into the buffer.
     *
     * @param root a pointer to a block pointer
     */
    void add(Cell** root)
    {
        assert(count_ < capacity_);

        roots_[count_] = root;
        count_ += 1;
    }

    /**
     * Removes an element from the buffer.
     *
     * @param index index of the element to remove
     */
    void remove(int index)
    {
        assert(index < count_);

        if(index < count_ - 1){
            memmove(roots_ + index,
                    roots_ + index + 1,
                    sizeof(Cell**) * (capacity_ - index - 1));
        }
        count_ -= 1;
    }

    /**
     * Replaces the content of the specified element of the buffer
     *
     * @param index index of the slot to replace
     * @param newRoot a block pointer to store in the buffer
     */
    void update(int index, Cell** newRoot)
    {
        assert(0 <= index);
        assert(index < count_);
        roots_[index] = newRoot;
    }

    ///////////////////////////////////////////////////////////////////////////
    // Overriding of class RootSet

    void trace(RootTracer* updater)
      throw (IMLRuntimeException)
    {
        if(0 == count_){ return; }
        updater->trace(roots_, count_);
    }

  private:

    ///////////////////////////////////////////////////////////////////////////
    // instance fields

    /**
     * array of pointers to block pointers
     *
     * The contents of this array is updated when 'beginTrace' method is
     * invoked.
     */
    Cell*** roots_;

    /**
     * The number of pointers stored in the roots_
     */
    int count_;

    /**
     * The capacity of the roots_;
     */
    int capacity_;
};

}
#endif
