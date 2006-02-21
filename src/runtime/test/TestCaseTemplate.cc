// @@CLASS@@
// @@NAMESPACE@@

#include "@@CLASS@@.hh"
#include "SystemDef.hh"

#include "TestCaller.h"

namespace @@NAMESPACE@@
{

///////////////////////////////////////////////////////////////////////////////

DBGWRAP(LogAdaptor @@CLASS@@::LOG =
        LogAdaptor("@@CLASS@@"));

void
@@CLASS@@::setUp()
{
    // setup facades
}

void
@@CLASS@@::tearDown()
{
    //
}

/*
void
@@CLASS@@::testOwn0001()
{
}
*/

///////////////////////////////////////////////////////////////////////////////

@@CLASS@@::Suite::Suite()
{
/*
    addTest(new TestCaller<@@CLASS@@>
            ("testOwn0001",
             &@@CLASS@@::testOwn0001));
*/
}

///////////////////////////////////////////////////////////////////////////////

}
