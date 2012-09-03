#ifndef NoEnoughHeapException_hh_
#define NoEnoughHeapException_hh_

#include "SystemDef.hh"
#include "IMLRuntimeException.hh"

#ifdef USE_NAMESPACE
using jp_ac_jaist_iml::IMLRuntimeException;
#endif

BEGIN_NAMESPACE(jp_ac_jaist_iml)

/**
 * Exception thrown when the heap manager cannot allocate a block of the
 * requested size in heap area.
 */
class NoEnoughHeapException
    : public IMLRuntimeException
{
    ///////////////////////////////////////////////////////////////////////////

  public:
    
    NoEnoughHeapException()
        : IMLRuntimeException()
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
