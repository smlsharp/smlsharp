/**
 * @author YAMATODANI Kiyoshi
 * @version $Id: FileLogFacade.cc,v 1.3 2005/02/07 10:34:10 kiyoshiy Exp $
 */
#include "FileLogFacade.hh"

BEGIN_NAMESPACE(jp_ac_jaist_iml)

///////////////////////////////////////////////////////////////////////////////

FileLogFacade::FileLogFacade(FILE* file)
    : LogFacade(),
      file_(file)
{
}

FileLogFacade::~FileLogFacade()
{
    if(NULL != file_){ fclose(file_); }
}

void
FileLogFacade::setup(FILE* file)
{
    static FileLogFacade facade = FileLogFacade(file);
    setInstance(&facade);
}

void
FileLogFacade::log_(const LogType& type,
                    const ByteValue* who,
                    const ByteValue* message) const
{
    fprintf(file_,
            "%s:%s:%s\n",
            type.getTypeLabel(), who, message);
    fflush(file_);
}

void
FileLogFacade::close_()
{
    if(NULL != file_)
    {
        fclose(file_);
        file_ = NULL;
    }
}

///////////////////////////////////////////////////////////////////////////////

END_NAMESPACE
