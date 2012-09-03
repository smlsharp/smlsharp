#include "SystemDef.hh"
#include "Log.hh"

#include <stdio.h>
#include <stdarg.h>

BEGIN_NAMESPACE(jp_ac_jaist_iml)

///////////////////////////////////////////////////////////////////////////////

LogType::LogType()
{
}

LogType::~LogType()
{
}

////////////////////////////////////////

const ErrorLogType
ErrorLogType::TYPE = ErrorLogType();

ErrorLogType::ErrorLogType()
    : LogType()
{
}

ErrorLogType::~ErrorLogType()
{
}

const char*
ErrorLogType::getTypeLabel() const
{
    return "ERROR";
}

////////////////////////////////////////

const WarningLogType
WarningLogType::TYPE = WarningLogType();

WarningLogType::WarningLogType()
    : LogType()
{
}

WarningLogType::~WarningLogType()
{
}

const char*
WarningLogType::getTypeLabel() const
{
    return "WARNING";
}

////////////////////////////////////////

const InfoLogType
InfoLogType::TYPE = InfoLogType();

InfoLogType::InfoLogType()
    : LogType()
{
}

InfoLogType::~InfoLogType()
{
}

const char*
InfoLogType::getTypeLabel() const
{
    return "INFO";
}

////////////////////////////////////////

const TraceLogType
TraceLogType::TYPE = TraceLogType();

TraceLogType::TraceLogType()
    : LogType()
{
}

TraceLogType::~TraceLogType()
{
}

const char*
TraceLogType::getTypeLabel() const
{
    return "TRACE";
}

////////////////////////////////////////

const DebugLogType
DebugLogType::TYPE = DebugLogType();

DebugLogType::DebugLogType()
    : LogType()
{
}

DebugLogType::~DebugLogType()
{
}

const char*
DebugLogType::getTypeLabel() const
{
    return "DEBUG";
}

////////////////////////////////////////

const TestLogType
TestLogType::TYPE = TestLogType();

TestLogType::TestLogType()
    : LogType()
{
}

TestLogType::~TestLogType()
{
}

const char*
TestLogType::getTypeLabel() const
{
    return "TEST";
}

///////////////////////////////////////////////////////////////////////////////

LogFacade* LogFacade::facade_ = NULL;

LogFacade::LogFacade()
{
}

LogFacade::~LogFacade()
{
}

void
LogFacade::log(const LogType& type,
               const char* who,
               const char* message)
{
    facade_->log_(type, who, message);
}

void
LogFacade::close()
{
    facade_->close_();
}

void
LogFacade::setInstance(LogFacade* facade)
{
    facade_ = facade;
}

///////////////////////////////////////////////////////////////////////////////

LogAdaptor::LogAdaptor(const char* who)
    : who_(who)
{
}

LogAdaptor::~LogAdaptor()
{
}

static char messageBuffer[1024];

#define FORMAT_MESSAGE(format, formatBuffer) \
{ \
    va_list arg; \
    va_start(arg, (format)); \
    vsnprintf((formatBuffer), sizeof (formatBuffer), (format), arg); \
    va_end(arg); \
}

void
LogAdaptor::error(const char* format, ...)
{
    FORMAT_MESSAGE(format, messageBuffer);
    LogFacade::log(ErrorLogType::TYPE, who_, messageBuffer);
}

void
LogAdaptor::warn(const char* format, ...)
{
    FORMAT_MESSAGE(format, messageBuffer);
    LogFacade::log(WarningLogType::TYPE, who_, messageBuffer);
}

void
LogAdaptor::info(const char* format, ...)
{
    FORMAT_MESSAGE(format, messageBuffer);
    LogFacade::log(InfoLogType::TYPE, who_, messageBuffer);
}

void
LogAdaptor::enter(const char* format, ...)
{
    // ToDo : make a string that is "ENTER:" + message.
    FORMAT_MESSAGE(format, messageBuffer);
    LogFacade::log(TraceLogType::TYPE, who_, messageBuffer);
}

void
LogAdaptor::exit(const char* format, ...)
{
    // ToDo : make a string that is "EXIT:" + message.
    FORMAT_MESSAGE(format, messageBuffer);
    LogFacade::log(TraceLogType::TYPE, who_, messageBuffer);
}

void
LogAdaptor::debug(const char* format, ...)
{
    FORMAT_MESSAGE(format, messageBuffer);
    LogFacade::log(DebugLogType::TYPE, who_, messageBuffer);
}

void
LogAdaptor::test(const char* format, ...)
{
    FORMAT_MESSAGE(format, messageBuffer);
    LogFacade::log(TestLogType::TYPE, who_, messageBuffer);
}

///////////////////////////////////////////////////////////////////////////////

END_NAMESPACE
