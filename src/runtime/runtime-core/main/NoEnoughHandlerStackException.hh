#ifndef NoEnoughHandlerStackException_hh_
#define NoEnoughHandlerStackException_hh_

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
class NoEnoughHandlerStackException
    : public IMLRuntimeException
{
    ///////////////////////////////////////////////////////////////////////////

  public:
    
    NoEnoughHandlerStackException()
        : IMLRuntimeException()
    {
    }

    ///////////////////////////////////////////////////////////////////////////

  public:

    virtual
    const char *what() const
        throw()
    {
        return "NoEnoughHandlerStackException";
    }

};

END_NAMESPACE

#endif
