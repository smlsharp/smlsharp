#ifndef ExecutablePreProcessor_hh_
#define ExecutablePreProcessor_hh_

#include "Executable.hh"
#include "IMLRuntimeException.hh"
#include "SystemError.hh"

BEGIN_NAMESPACE(jp_ac_jaist_iml_runtime)

///////////////////////////////////////////////////////////////////////////////

/**
 *  This is the base class of the classes which implements processings to
 * the executables prior to execution.
 *  For example, jit-linker and jit-optimizer are derived from this class.
 */
class ExecutablePreProcessor
{
    ///////////////////////////////////////////////////////////////////////////

  public:

    /**
     * process executables
     *
     * @param executable the executable object
     */
    virtual
    void process(Executable* executable)
        throw(IMLRuntimeException,
              SystemError)
        = 0;
};

///////////////////////////////////////////////////////////////////////////////

END_NAMESPACE

#endif // ExecutablePreProcessor_hh_
