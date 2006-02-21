#ifndef IllegalStateException_hh_
#define IllegalStateException_hh_

#include "SystemDef.hh"
#include "IMLRuntimeException.hh"

BEGIN_NAMESPACE(jp_ac_jaist_iml)

class IllegalStateException
    : public IMLRuntimeException
{
    ///////////////////////////////////////////////////////////////////////////

  public:

    IllegalStateException()
        : IMLRuntimeException()
    {
    }

    ///////////////////////////////////////////////////////////////////////////

  public:

    virtual
    const char *what() const
        throw()
    {
        return "IllegalStateException";
    }

};

END_NAMESPACE

#endif
