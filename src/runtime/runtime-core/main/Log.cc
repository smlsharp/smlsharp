#include "SystemDef.hh"
#include "Log.hh"

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

const ByteValue*
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

const ByteValue*
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

const ByteValue*
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

const ByteValue*
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

const ByteValue*
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

const ByteValue*
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
               const ByteValue* who,
               const ByteValue* message)
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

LogAdaptor::LogAdaptor(const ByteValue* who)
    : who_(who)
{
}

LogAdaptor::~LogAdaptor()
{
}

void
LogAdaptor::error(const ByteValue* message)
{
    LogFacade::log(ErrorLogType::TYPE, who_, message);
}

void
LogAdaptor::warn(const ByteValue* message)
{
    LogFacade::log(WarningLogType::TYPE, who_, message);
}

void
LogAdaptor::info(const ByteValue* message)
{
    LogFacade::log(InfoLogType::TYPE, who_, message);
}

void
LogAdaptor::enter(const ByteValue* message)
{
    // ToDo : make a string that is "ENTER:" + message.
    LogFacade::log(TraceLogType::TYPE, who_, message);
}

void
LogAdaptor::exit(const ByteValue* message)
{
    // ToDo : make a string that is "EXIT:" + message.
    LogFacade::log(TraceLogType::TYPE, who_, message);
}

void
LogAdaptor::debug(const ByteValue* message)
{
    LogFacade::log(DebugLogType::TYPE, who_, message);
}

void
LogAdaptor::test(const ByteValue* message)
{
    LogFacade::log(TestLogType::TYPE, who_, message);
}

///////////////////////////////////////////////////////////////////////////////

END_NAMESPACE
