#ifndef NoEnoughHeapException_hh_
#define NoEnoughHeapException_hh_

#include "SystemDef.hh"
#include "SystemError.hh"

#ifdef USE_NAMESPACE
using jp_ac_jaist_iml::SystemError;
#endif

BEGIN_NAMESPACE(jp_ac_jaist_iml)

/**
 * Exception thrown when the heap manager cannot allocate a block of the
 * requested size in heap area.
 */
class NoEnoughHeapException
    : public SystemError
{
    ///////////////////////////////////////////////////////////////////////////

  public:
    
    NoEnoughHeapException()
        : SystemError()
    {
    }

    ///////////////////////////////////////////////////////////////////////////

  public:

    virtual
    const char *what() const
        throw()
    {
        return "NoEnoughHeapException";
    }

};

END_NAMESPACE

#endif
