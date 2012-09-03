#include "StandAloneSession.hh"

#include "FileReader.hh"
#include "FileWriter.hh"
#include <unistd.h>

BEGIN_NAMESPACE(jp_ac_jaist_iml_runtime)

///////////////////////////////////////////////////////////////////////////////

StandAloneSession::StandAloneSession(InputChannel* executableInputChannel)
    : SessionBase(),
      executableInputChannel_(executableInputChannel)
{
    standardInputReader_ =
    new FileReader("stdin", STDIN_FILENO, BOOLVALUE_TRUE);
    standardOutputWriter_ =
    new FileWriter("stdout", STDOUT_FILENO, BOOLVALUE_TRUE);
    standardErrorWriter_ =
    new FileWriter("stderr", STDERR_FILENO, BOOLVALUE_TRUE);
}

StandAloneSession::~StandAloneSession()
{
    delete standardInputReader_;
    delete standardOutputWriter_;
    delete standardErrorWriter_;
}

///////////////////////////////////////////////////////////////////////////////

SInt32Value
StandAloneSession::start()
    throw(IMLRuntimeException,
          UserException,
          SystemError)
{
    while(BOOLVALUE_FALSE == executableInputChannel_->isEOF())
    {
        Executable* executable = receiveExecutable(executableInputChannel_);

        linkAndExecute(executable);
    }
    return 0;
}

///////////////////////////////////////////////////////////////////////////////

DBGWRAP(LogAdaptor StandAloneSession::LOG =
        LogAdaptor("StandAloneSession"));

///////////////////////////////////////////////////////////////////////////////

END_NAMESPACE
