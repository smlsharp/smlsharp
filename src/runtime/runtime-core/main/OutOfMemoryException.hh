#ifndef OutOfMemoryException_hh_
#define OutOfMemoryException_hh_

#include "SystemDef.hh"
#include "IMLException.hh"
#include "IMLRuntimeException.hh"

BEGIN_NAMESPACE(jp_ac_jaist_iml)

class OutOfMemoryException
    : public IMLRuntimeException
{
    ///////////////////////////////////////////////////////////////////////////

  public:

    OutOfMemoryException()
        : IMLRuntimeException()
    {
    }

    ///////////////////////////////////////////////////////////////////////////

  public:

    virtual
    const char *what() const
        throw()
    {
        return "OutOfMemoryException";
    }

};

END_NAMESPACE

#endif
