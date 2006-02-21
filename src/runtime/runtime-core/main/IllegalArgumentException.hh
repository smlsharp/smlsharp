#ifndef IllegalArgumentException_hh_
#define IllegalArgumentException_hh_

#include "SystemDef.hh"
#include "IMLRuntimeException.hh"

BEGIN_NAMESPACE(jp_ac_jaist_iml)

class IllegalArgumentException
    : public IMLRuntimeException
{
    ///////////////////////////////////////////////////////////////////////////

  public:

    IllegalArgumentException()
        : IMLRuntimeException()
    {
    }

    ///////////////////////////////////////////////////////////////////////////

  public:

    virtual
    const char *what() const
        throw()
    {
        return "IllegalArgumentException";
    }

};

END_NAMESPACE

#endif
