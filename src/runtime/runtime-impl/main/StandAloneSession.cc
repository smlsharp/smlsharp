#include "StandAloneSession.hh"

#include "FileReader.hh"
#include "FileWriter.hh"
#include <unistd.h>

BEGIN_NAMESPACE(jp_ac_jaist_iml_runtime)

///////////////////////////////////////////////////////////////////////////////

StandAloneSession::StandAloneSession()
    : SessionBase(),
      executableInputChannel_(NULL)
{
    standardInputReader_ =
    new FileReader("stdin", STDIN_FILENO, BOOLVALUE_TRUE);
    standardOutputWriter_ =
    new FileWriter("stdout", STDOUT_FILENO, BOOLVALUE_TRUE);
    standardErrorWriter_ =
    new FileWriter("stderr", STDERR_FILENO, BOOLVALUE_TRUE);
}

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
StandAloneSession::run(UInt32Value bufferByteLength, UInt32Value* buffer)
    throw(IMLException)
{
    try{
        UInt32Value* current = buffer;
        while(((char*)current - (char*)buffer) < bufferByteLength){
            // current is updated by getExecutableFromBuffer.
            Executable* executable =
                deserializeExecutionRequestFromBuffer(current);
            linkAndExecute(executable);
        }
        fflush(stdout);
        fflush(stderr);

        return 0;
    }
    catch(IMLException &exception){
        fflush(stdout);
        fflush(stderr);
        throw;
    }
}

SInt32Value
StandAloneSession::start()
    throw(IMLException)
{
    try{
        while(BOOLVALUE_FALSE == executableInputChannel_->isEOF())
        {
            Executable* executable =
                receiveExecutable(executableInputChannel_);

            linkAndExecute(executable);

            fflush(stdout);
            fflush(stderr);
        }
        return 0;
    }
    catch(IMLException &exception){
        fflush(stdout);
        fflush(stderr);
        throw;
    }
}

///////////////////////////////////////////////////////////////////////////////

DBGWRAP(LogAdaptor StandAloneSession::LOG =
        LogAdaptor("StandAloneSession"));

///////////////////////////////////////////////////////////////////////////////

END_NAMESPACE
