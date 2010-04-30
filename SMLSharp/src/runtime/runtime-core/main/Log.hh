/**
 * @author YAMATODANI Kiyoshi
 * @version $Id: Log.hh,v 1.4 2007/01/08 08:53:31 kiyoshiy Exp $
 */
#ifndef Log_hh_
#define Log_hh_

#include "SystemDef.hh"

BEGIN_NAMESPACE(jp_ac_jaist_iml)

///////////////////////////////////////////////////////////////////////////////

class LogType
{
    ////////////////////////////////////////

  protected:

    LogType();

    virtual
    ~LogType();

    ////////////////////////////////////////

  public:

    virtual
    const char* getTypeLabel() const = 0;
};

///////////////////////////////////////////////////////////////////////////////

class ErrorLogType
    : public LogType
{
    ////////////////////////////////////////

  public:

    const static ErrorLogType TYPE;

    ////////////////////////////////////////

  protected:

    ErrorLogType();

  public:

    virtual
    ~ErrorLogType();

    ////////////////////////////////////////
  public:

    virtual
    const char* getTypeLabel() const;
};

class WarningLogType
    : public LogType
{
    ////////////////////////////////////////

  public:

    const static WarningLogType TYPE;

    ////////////////////////////////////////

  protected:

    WarningLogType();

  public:

    virtual
    ~WarningLogType();

    ////////////////////////////////////////

  public:

    virtual
    const char* getTypeLabel() const;
};

class InfoLogType
    : public LogType
{
    ////////////////////////////////////////

  public:

    const static InfoLogType TYPE;

    ////////////////////////////////////////

  protected:

    InfoLogType();

  public:

    virtual
    ~InfoLogType();

    ////////////////////////////////////////

  public:

    virtual
    const char* getTypeLabel() const;
};

class TraceLogType
    : public LogType
{
    ////////////////////////////////////////

  public:

    const static TraceLogType TYPE;

    ////////////////////////////////////////

  protected:

    TraceLogType();

  public:

    virtual
    ~TraceLogType();

    ////////////////////////////////////////

  public:

    virtual
    const char* getTypeLabel() const;
};

class DebugLogType
    : public LogType
{
    ////////////////////////////////////////

  public:

    const static DebugLogType TYPE;

    ////////////////////////////////////////

  protected:

    DebugLogType();

  public:

    virtual
    ~DebugLogType();

    ////////////////////////////////////////

  public:

    virtual
    const char* getTypeLabel() const;
};

class TestLogType
    : public LogType
{
    ////////////////////////////////////////

  public:

    const static TestLogType TYPE;

    ////////////////////////////////////////

  protected:

    TestLogType();

  public:

    virtual
    ~TestLogType();

    ////////////////////////////////////////

  public:

    virtual
    const char* getTypeLabel() const;
};

///////////////////////////////////////////////////////////////////////////////

class LogFacade
{
    ////////////////////////////////////////

  public:

    static void log(const LogType& type,
                    const char* who,
                    const char* message);

    static void close();

    ////////////////////////////////////////

  protected:

    LogFacade();

    virtual
    ~LogFacade();

    ////////////////////////////////////////

  protected:

    virtual
    void log_(const LogType& type,
              const char* who,
              const char* message) const
        = 0;

    virtual
    void close_()
        = 0;

    static void setInstance(LogFacade* facade);

    ////////////////////////////////////////

  private:

    static LogFacade* facade_;

};

///////////////////////////////////////////////////////////////////////////////

class LogAdaptor
{
    ////////////////////////////////////////

  public:

    LogAdaptor(const char* who);

    ~LogAdaptor();

    ////////////////////////////////////////

  public:

    void error(const char* format, ...);
    void warn(const char* format, ...);
    void info(const char* format, ...);
    void enter(const char* format, ...);
    void exit(const char* format, ...);
    void debug(const char* format, ...);
    void test(const char* format, ...);

    ////////////////////////////////////////

  private:

    const char* const who_;

};

///////////////////////////////////////////////////////////////////////////////

END_NAMESPACE

#endif
