/**
 * @author YAMATODANI Kiyoshi
 * @version $Id: Log.hh,v 1.3 2005/02/07 10:34:10 kiyoshiy Exp $
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
    const ByteValue* getTypeLabel() const = 0;
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
    const ByteValue* getTypeLabel() const;
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
    const ByteValue* getTypeLabel() const;
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
    const ByteValue* getTypeLabel() const;
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
    const ByteValue* getTypeLabel() const;
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
    const ByteValue* getTypeLabel() const;
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
    const ByteValue* getTypeLabel() const;
};

///////////////////////////////////////////////////////////////////////////////

class LogFacade
{
    ////////////////////////////////////////

  public:

    static void log(const LogType& type,
                    const ByteValue* who,
                    const ByteValue* message);

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
              const ByteValue* who,
              const ByteValue* message) const
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

    LogAdaptor(const ByteValue* who);

    ~LogAdaptor();

    ////////////////////////////////////////

  public:

    void error(const ByteValue* message);
    void warn(const ByteValue* message);
    void info(const ByteValue* message);
    void enter(const ByteValue* message);
    void exit(const ByteValue* message);
    void debug(const ByteValue* message);
    void test(const ByteValue* message);

    ////////////////////////////////////////

  private:

    const ByteValue* const who_;

};

///////////////////////////////////////////////////////////////////////////////

END_NAMESPACE

#endif
