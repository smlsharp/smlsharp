#ifndef StandAloneSession_hh_
#define StandAloneSession_hh_

#include "Session.hh"
#include "SessionBase.hh"
#include "VirtualMachine.hh"
#include "InputChannel.hh"
#include "ExecutablePreProcessor.hh"
#include "VariableLengthArray.hh"
#include "WordOperations.hh"
#include "Log.hh"
#include "Debug.hh"

BEGIN_NAMESPACE(jp_ac_jaist_iml_runtime)

///////////////////////////////////////////////////////////////////////////////

/**
 *
 */
class StandAloneSession
    :public SessionBase
{
    ///////////////////////////////////////////////////////////////////////////
  private:

    /**
     * the input channel from which executables are read.
     */
    InputChannel* executableInputChannel_;

    /**
     * log writer
     */
    DBGWRAP(static LogAdaptor LOG);

    ///////////////////////////////////////////////////////////////////////////
  public:

    /**
     * constructor
     *
     * @param executableInputChannel the session reads executables from this
     *                        input channel.
     */
    StandAloneSession(InputChannel* executableInputChannel);

    /**
     * destructor
     */
    virtual
    ~StandAloneSession();

    ///////////////////////////////////////////////////////////////////////////
  public:

    virtual
    SInt32Value start()
        throw(IMLRuntimeException,
              UserException,
              SystemError);

};

///////////////////////////////////////////////////////////////////////////////

END_NAMESPACE

#endif // StandAloneSession_hh_
