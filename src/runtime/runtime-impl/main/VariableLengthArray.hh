#ifndef VariableLengthArray_hh_
#define VariableLengthArray_hh_

#include "OutOfMemoryException.hh"
#include "IllegalArgumentException.hh"
#include "SystemDef.hh"
#include "Debug.hh"

#include <stdlib.h>
#include <assert.h>

BEGIN_NAMESPACE(jp_ac_jaist_iml_runtime)

/**
 * Simple implementation of a variable sized array.
 *
 * <p>
 * expected usage:
 * <ul>
 * <li>assignments list maintained by the heap manager</li>
 * <li>rootset held by heap clients</li>
 * </ul>
 */
class VariableLengthArray
{
  public:

    typedef void* Element;

    ///////////////////////////////////////////////////////////////////////////
    // Constructors
    
    /**
     * Constructor.
     *
     * @param initialBufferSize initial buffer size (in sizeof(Element))
     */
    VariableLengthArray(int initialBufferSize = 256)
        throw(IMLRuntimeException)
        : count_(0),
          buffer_(NULL),
          bufferSize_(initialBufferSize)
    {
        buffer_ = (Element*)ALLOCATE_MEMORY(bufferSize_ * sizeof(Element));
        if(NULL == buffer_){
            throw OutOfMemoryException();
        }
        FILL_MEMORY(buffer_, 0, bufferSize_ * sizeof(Element));
    }

    /**
     * Destructor.
     */
    ~VariableLengthArray()
    {
        if(NULL != buffer_){
            RELEASE_MEMORY(buffer_);
        }
    }

    ///////////////////////////////////////////////////////////////////////////

    /**
     * adds an element to the tail of the array.
     *
     * @param newElement new element
     */
    INLINE_FUN
    void
    add(Element newElement)
        throw(IMLRuntimeException)
    {
        if(count_ == bufferSize_)
        {
            int newBufferSize = bufferSize_ * 2;
            buffer_ =
            (Element*)
            REALLOCATE_MEMORY(buffer_, newBufferSize * sizeof(Element));
            if(NULL == buffer_){throw OutOfMemoryException();}
            bufferSize_ = newBufferSize;
        }
        buffer_[count_] = newElement;
        count_ += 1;
    }

    /**
     *
     * @param elements the number of new elements
     */
    INLINE_FUN
    void
    extend(int elements)
        throw(IMLRuntimeException)
    {
        if(count_ + elements > bufferSize_)
        {
            int newBufferSize =
            count_ + elements + (bufferSize_ - count_);// with margin
            buffer_ =
            (Element*)
            REALLOCATE_MEMORY(buffer_, newBufferSize * sizeof(Element));
            if(NULL == buffer_){throw OutOfMemoryException();}
            FILL_MEMORY(buffer_ + count_, 0, elements * sizeof(Element));
            bufferSize_ = newBufferSize;
        }
        count_ += elements;
    }

    /**
     * removes an element from the list
     *
     * @param index the index of the element to remove from the list
     */
    INLINE_FUN
    void
    remove(int index)
        throw(IMLRuntimeException)
    {
        if((index < 0) || (count_ <= index)){
            throw IllegalArgumentException();
        }
        if(index < count_ - 1){
            COPY_MEMORY(buffer_ + index,
                        buffer_ + index + 1,
                        sizeof(Element) * (bufferSize_ - index - 1));
        }
        count_ -= 1;

        FILL_MEMORY(buffer_ + count_,
                    0,
                    (bufferSize_ - count_) * sizeof(Element));
    }

    INLINE_FUN
    void
    push(Element newElement)
        throw(IMLRuntimeException)
    {
        add(newElement);
    }

    INLINE_FUN
    Element
    pop()
        throw(IMLRuntimeException)
    {
        count_ -= 1;
        Element element = buffer_[count_];
	buffer_[count_] = 0;
	return element;
    }

    /**
     * Removes all of the elements from array.
     */
    INLINE_FUN
    void
    clear()
        throw(IMLRuntimeException)
    {
        FILL_MEMORY(buffer_, 0, bufferSize_ * sizeof(Element));
        count_ = 0;
    }

    /**
     * Returns a pointer to the buffer.
     *
     * @return a pointer to the buffer
     */
    INLINE_FUN
    Element*
    getContents()
        throw(IMLRuntimeException)
    {
        return buffer_;
    }

    /**
     * Returns the number of elements in this array.
     *
     * @return the number of elements in this array
     */
    INLINE_FUN
    int
    getCount()
        throw(IMLRuntimeException)
    {
        return count_;
    }

  private:

    ///////////////////////////////////////////////////////////////////////////
    // private instance fields

    /**
     * The number of elements in this array
     */
    int count_;

    /**
     * The buffer holds all elements
     */
    Element* buffer_;

    /**
     * The size of 'buffer_' (in sizeof(Element))
     */
    int bufferSize_;
};

END_NAMESPACE

#endif
