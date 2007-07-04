#ifndef MalformedExecutableException_hh_
#define MalformedExecutableException_hh_

#include "SystemDef.hh"
#include "IMLRuntimeException.hh"

BEGIN_NAMESPACE(jp_ac_jaist_iml)

class MalformedExecutableException
    : public IMLRuntimeException
{
    ///////////////////////////////////////////////////////////////////////////

  public:

    MalformedExecutableException()
        : IMLRuntimeException()
    {
    }

    ///////////////////////////////////////////////////////////////////////////

  public:

    virtual
    const char *what() const
        throw()
    {
        return "MalformedExecutableException";
    }

};

END_NAMESPACE

#endif
