#ifndef ProtocolException_hh_
#define ProtocolException_hh_

#include "SystemDef.hh"
#include "IMLRuntimeException.hh"

BEGIN_NAMESPACE(jp_ac_jaist_iml)

class ProtocolException
    : public IMLRuntimeException // ToDo : RuntimeException ??
{
    ///////////////////////////////////////////////////////////////////////////

  public:

    ProtocolException()
        : IMLRuntimeException()
    {
    }

    ///////////////////////////////////////////////////////////////////////////

  public:

    virtual
    const char *what() const
        throw()
    {
        return "ProtocolException";
    }

};

END_NAMESPACE

#endif
