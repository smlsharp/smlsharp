#ifndef SystemError_hh_
#define SystemError_hh_

#include "SystemDef.hh"

BEGIN_NAMESPACE(jp_ac_jaist_iml)

class SystemError
{
    ///////////////////////////////////////////////////////////////////////////

  public:

    SystemError()
    {
    }

    ///////////////////////////////////////////////////////////////////////////

  public:

    virtual
    const char *what() const
        throw()
    {
        return "SystemError";
    }

};

END_NAMESPACE

#endif
