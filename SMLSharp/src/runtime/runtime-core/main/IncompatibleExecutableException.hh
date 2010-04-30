#ifndef IncompatibleExecutableException_hh_
#define IncompatibleExecutableException_hh_

#include "SystemDef.hh"
#include "IMLRuntimeException.hh"

BEGIN_NAMESPACE(jp_ac_jaist_iml)

class IncompatibleExecutableException
    : public IMLRuntimeException
{
    ///////////////////////////////////////////////////////////////////////////

  public:

    IncompatibleExecutableException()
        : IMLRuntimeException()
    {
    }

    ///////////////////////////////////////////////////////////////////////////

  public:

    virtual
    const char *what() const
        throw()
    {
        return "IncompatibleExecutableException";
    }

};

END_NAMESPACE

#endif
