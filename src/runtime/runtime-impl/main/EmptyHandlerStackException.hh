#ifndef EmptyHandlerStackException_hh_
#define EmptyHandlerStackException_hh_

#include "SystemDef.hh"
#include "UserException.hh"

BEGIN_NAMESPACE(jp_ac_jaist_iml_runtime)

/**
 * thrown when no exception handler is found in the handler stack.
 */
class EmptyHandlerStackException
    : public UserException /* FIXME : Is this an user exception ? */
{
    ///////////////////////////////////////////////////////////////////////////

  public:

    EmptyHandlerStackException()
        : UserException()
    {
    }

    ///////////////////////////////////////////////////////////////////////////

  public:

    virtual
    const char *what() const
        throw()
    {
        return "uncaught exception";
    }

};

END_NAMESPACE

#endif
