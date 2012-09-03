#ifndef FFIException_hh_
#define FFIException_hh_

#include "SystemDef.hh"
#include "IMLRuntimeException.hh"

BEGIN_NAMESPACE(jp_ac_jaist_iml)

class FFIException
    : public IMLRuntimeException
{
    ///////////////////////////////////////////////////////////////////////////

    const char * const message;

  public:

    FFIException()
        : IMLRuntimeException(), message("FFIException")
    {
    }

    FFIException(const char *msg)
        : IMLRuntimeException(), message(msg)
    {
    }

    ///////////////////////////////////////////////////////////////////////////

  public:

    virtual
    const char *what() const
        throw()
    {
        return message;
    }

};

END_NAMESPACE

#endif
