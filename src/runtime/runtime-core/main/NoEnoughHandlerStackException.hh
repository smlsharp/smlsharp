#ifndef NoEnoughHandlerStackException_hh_
#define NoEnoughHandlerStackException_hh_

#include "SystemDef.hh"
#include "IMLRuntimeException.hh"

#ifdef USE_NAMESPACE
using jp_ac_jaist_iml::IMLRuntimeException;
#endif

BEGIN_NAMESPACE(jp_ac_jaist_iml)

/**
 * Exception thrown when the VM cannot allocate a new handler stack frame.
 * This is not a fatal error because VM can restart from the empty handler
 * stack.
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
