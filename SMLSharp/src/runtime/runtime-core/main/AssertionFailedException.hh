#ifndef AssertionFailedException_hh_
#define AssertionFailedException_hh_

#include "SystemDef.hh"
#include "IMLRuntimeException.hh"

#include <stdio.h>

BEGIN_NAMESPACE(jp_ac_jaist_iml)

class AssertionFailedException
    : public IMLRuntimeException
{
    ///////////////////////////////////////////////////////////////////////////

  private:

    const char* fileName_;
    const int line_;
    const char* expression_;

    char* what_;

    ///////////////////////////////////////////////////////////////////////////

  public:

    AssertionFailedException(const char* fileName,
                             const int line,
                             const char* expression)
        : IMLRuntimeException(),
          fileName_(fileName),
          line_(line),
          expression_(expression)
    {
        int textLength = strlen(fileName_) + 1 + 4 + 1 + strlen(expression);
        what_ = new char[textLength + 1];
        sprintf(what_, "%s:%4d:%s", fileName_, line_, expression_);
    }

    virtual 
    ~AssertionFailedException()
        throw ()
    {
        delete[] what_;
    }

    ///////////////////////////////////////////////////////////////////////////

  public:

    virtual
    const char *what() const
        throw()
    {
        return what_;
    }
};

END_NAMESPACE

#endif
