#ifndef UserException_hh_
#define UserException_hh_

#include "SystemDef.hh"
#include "IMLException.hh"

#ifdef USE_NAMESPACE
using jp_ac_jaist_iml::IMLException;
#endif

BEGIN_NAMESPACE(jp_ac_jaist_iml)

class UserException
    : public IMLException
{
    ///////////////////////////////////////////////////////////////////////////

  public:

    UserException()
        : IMLException()
    {
    }

    ///////////////////////////////////////////////////////////////////////////

  public:

    virtual
    const char *what() const
        throw()
    {
        return "UserException";
    }

};

END_NAMESPACE

#endif
