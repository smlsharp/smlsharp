#ifndef IMLRuntimeException_hh_
#define IMLRuntimeException_hh_

#include "SystemDef.hh"
#include "IMLException.hh"

#ifdef USE_NAMESPACE
using jp_ac_jaist_iml::IMLException;
#endif

BEGIN_NAMESPACE(jp_ac_jaist_iml)

class IMLRuntimeException
    : public IMLException
{
    ///////////////////////////////////////////////////////////////////////////

  public:

    IMLRuntimeException()
        : IMLException()
    {
    }

    ///////////////////////////////////////////////////////////////////////////

  public:

    virtual
    const char *what() const
        throw()
    {
        return "IMLRuntimeException";
    }
};

END_NAMESPACE

#endif
