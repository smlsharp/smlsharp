#ifndef SystemError_hh_
#define SystemError_hh_

#include "SystemDef.hh"

#ifdef USE_NAMESPACE
using jp_ac_jaist_iml::IMLException;
#endif

BEGIN_NAMESPACE(jp_ac_jaist_iml)

class SystemError
    : public IMLException
{
    ///////////////////////////////////////////////////////////////////////////

  public:

    SystemError()
        : IMLException()
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
