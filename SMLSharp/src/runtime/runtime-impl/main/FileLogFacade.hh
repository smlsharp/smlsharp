/**
 * @author YAMATODANI Kiyoshi
 * @version $Id: FileLogFacade.hh,v 1.3 2005/02/07 10:34:10 kiyoshiy Exp $
 */
#ifndef FileLogFacade_hh_
#define FileLogFacade_hh_

#include <stdio.h>
#include "Log.hh"

BEGIN_NAMESPACE(jp_ac_jaist_iml)

///////////////////////////////////////////////////////////////////////////////

class FileLogFacade
    : public LogFacade
{
  private:

    FILE* file_;

    ////////////////////////////////////////

  protected:

    FileLogFacade(FILE* file);

  public:

    virtual
    ~FileLogFacade();

    ////////////////////////////////////////

  public:

    static void setup(FILE* file);

    ////////////////////////////////////////

  protected:

    virtual
    void log_(const LogType& type,
              const ByteValue* who,
              const ByteValue* message) const;

    virtual
    void close_();
};

///////////////////////////////////////////////////////////////////////////////

END_NAMESPACE

#endif
