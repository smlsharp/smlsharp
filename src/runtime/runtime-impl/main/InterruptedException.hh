#ifndef InterruptedException_hh_
#define InterruptedException_hh_

#include "SystemDef.hh"
#include "UserException.hh"

BEGIN_NAMESPACE(jp_ac_jaist_iml_runtime)

class InterruptedException
    : public UserException
{
    ///////////////////////////////////////////////////////////////////////////

  public:

    InterruptedException()
        : UserException()
    {
    }

    ///////////////////////////////////////////////////////////////////////////

  public:

    virtual
    const char *what() const
        throw()
    {
        return "interrupted";
    }

};

END_NAMESPACE

#endif
