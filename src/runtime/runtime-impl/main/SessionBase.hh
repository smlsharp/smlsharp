#ifndef SessionBase_hh_
#define SessionBase_hh_

#include "Session.hh"
#include "VirtualMachine.hh"
#include "InputChannel.hh"
#include "ExecutablePreProcessor.hh"
#include "Executable.hh"
#include "WordOperations.hh"
#include "Log.hh"
#include "Debug.hh"

#include <list>

BEGIN_NAMESPACE(jp_ac_jaist_iml_runtime)

///////////////////////////////////////////////////////////////////////////////

/**
 *
 */
class SessionBase
    :public Session,
     public WordOperations 
{
    ///////////////////////////////////////////////////////////////////////////

    typedef std::list<ExecutablePreProcessor*> PreProcessorList;

    ///////////////////////////////////////////////////////////////////////////
  protected:

    Reader* standardInputReader_;

    Writer* standardOutputWriter_;

    Writer* standardErrorWriter_;

    /**
     * the list of executable preprocessors.
     */
    PreProcessorList executablePreProcessors_;

    /**
     * log writer
     */
    DBGWRAP(static LogAdaptor LOG);

    ///////////////////////////////////////////////////////////////////////////
  public:

    /**
     * constructor
     */
    SessionBase();

    /**
     * destructor
     */
    virtual
    ~SessionBase();

    ///////////////////////////////////////////////////////////////////////////
  public:

    virtual
    Reader* getStandardInputReader();

    virtual
    Writer* getStandardOutputWriter();

    virtual
    Writer* getStandardErrorWriter();

    virtual
    void addExecutablePreProcessor(ExecutablePreProcessor* preProcessor);

    ///////////////////////////////////////////////////////////////////////////
  protected:

    /**
     *
     */
    void linkAndExecute(Executable* executable)
        throw(IMLException);

    /**
     *  reads an executable from the input channel.
     * The executable this method returns must be relased by the <code>
     * releaseExecutable</code> method.
     *
     * @param channel the input channel from which executables is read.
     * @return an executable
     */
    Executable* receiveExecutable(InputChannel* channel);

    /**
     *  get an executable from serialized form of ExecutionRequest message
     * body.
     * buffer is advanced on return.
     */
    Executable* deserializeExecutionRequestFromBuffer(UInt32Value* &buffer);

    /**
     *  releases resources which the executable occupies.
     *
     * @param executable the executable to release
     */
    void releaseExecutable(Executable* executable);
};

///////////////////////////////////////////////////////////////////////////////

END_NAMESPACE

#endif // SessionBase_hh_
