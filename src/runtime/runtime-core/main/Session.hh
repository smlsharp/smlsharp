#ifndef Session_hh_
#define Session_hh_

#include "SystemDef.hh"
#include "Reader.hh"
#include "Writer.hh"
#include "ExecutablePreProcessor.hh"
#include "IMLRuntimeException.hh"
#include "SystemError.hh"
#include "UserException.hh"

BEGIN_NAMESPACE(jp_ac_jaist_iml_runtime)

///////////////////////////////////////////////////////////////////////////////

class VirtualMachine;

/**
 *
 */
class Session
{
    ///////////////////////////////////////////////////////////////////////////
  public:

    /**
     * constructor
     */
    Session(){}

    /**
     * destructor
     */
    virtual
    ~Session(){}

    ///////////////////////////////////////////////////////////////////////////
  public:

    virtual
    Reader* getStandardInputReader() = 0;

    virtual
    Writer* getStandardOutputWriter() = 0;

    virtual
    Writer* getStandardErrorWriter() = 0;

    /**
     *  add an executable preprocessor to the preprocessor list.
     * The session invokes the <code>process</code> method on these
     * preprocessors
     *
     * @param preProcessor an ExecutablePreProcessor object
     */
    virtual
    int addExecutablePreProcessor(ExecutablePreProcessor* preProcessor)
        = 0;

    /**
     *  start a session.
     * reads messages from input channel, preprocess and execute.
     * @return an integer to be used as exit code.
     */
    virtual
    SInt32Value start()
        throw(IMLRuntimeException,
              UserException,
              SystemError)
        = 0;

};

///////////////////////////////////////////////////////////////////////////////

END_NAMESPACE

#endif // Session_hh_
