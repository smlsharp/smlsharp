#ifndef EmptyHandlerStackException_hh_
#define EmptyHandlerStackException_hh_

#include "SystemDef.hh"
#include "UserException.hh"

BEGIN_NAMESPACE(jp_ac_jaist_iml_runtime)

class EmptyHandlerStackException
    : public UserException
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
