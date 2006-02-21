// @@CLASS@@
// @@NAMESPACE@@

#include "TestCase.h"
#include "TestSuite.h"

#include "Log.hh"
#include "Debug.h"

using std::string;

namespace @@NAMESPACE@@
{

///////////////////////////////////////////////////////////////////////////////

class @@CLASS@@
    : public TestCase
{
    ////////////////////////////////////////
  private:
    DBGWRAP(static LogAdaptor LOG);

    ////////////////////////////////////////
  public:
    @@CLASS@@(string name)
        : TestCase(name)
    {
    }

    virtual void setUp();

    virtual void tearDown();

    ////////////////////////////////////////
  public:
//    void testOwn0001();

    class Suite;
};

class @@CLASS@@::Suite
    : public TestSuite
{
    ////////////////////////////////////////
  public:
    Suite();
};

///////////////////////////////////////////////////////////////////////////////

}
