#ifndef IMLException_hh_
#define IMLException_hh_

#include "SystemDef.hh"

BEGIN_NAMESPACE(jp_ac_jaist_iml)

class IMLException
    : std::exception
{
    ///////////////////////////////////////////////////////////////////////////

  public:

    IMLException()
        : exception()
    {
    }

    ///////////////////////////////////////////////////////////////////////////

  public:

    virtual
    const char *what() const
        throw()
    {
        return "IMLException";
    }
};

END_NAMESPACE

#endif
