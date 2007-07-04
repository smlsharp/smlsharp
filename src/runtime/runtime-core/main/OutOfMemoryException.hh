#ifndef OutOfMemoryException_hh_
#define OutOfMemoryException_hh_

#include "SystemDef.hh"
#include "SystemError.hh"

BEGIN_NAMESPACE(jp_ac_jaist_iml)

class OutOfMemoryException
    : public SystemError
{
    ///////////////////////////////////////////////////////////////////////////

  public:

    OutOfMemoryException()
        : SystemError()
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
