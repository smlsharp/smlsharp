// StandAloneSessionTest0001
// jp_ac_jaist_iml_runtime

#include "StandAloneSession.hh"
#include "WordOperations.hh"

#include "TestCase.h"
#include "TestSuite.h"

using std::string;

namespace jp_ac_jaist_iml_runtime
{

///////////////////////////////////////////////////////////////////////////////

/**
 * Tests of StandAloneSession
 *
 * <p><b>supplementary comments:</b></p>
 *
 * <p><b>the number of test cases</b></p>
 *
 * <hr>
 *
 */
class StandAloneSessionTest0001
    : public TestCase,
      public WordOperations 
{
    ////////////////////////////////////////
  private:

    ////////////////////////////////////////
  public:
    StandAloneSessionTest0001(string name)
        : TestCase(name)
    {
    }

    virtual void setUp();

    virtual void tearDown();

    ////////////////////////////////////////
  public:

    /**
     * run an executable in a session.
     *
     * <p>prerequisite</p>
     * <ul>
     *   <li></li>
     * </ul>
     *
     * <p>expected result</p>
     * <ul>
     * <li>exceptions : not thrown</li>
     * </ul>
     */
    void testStart0001();

    class Suite;

    ////////////////////////////////////////

};

class StandAloneSessionTest0001::Suite
    : public TestSuite
{
    ////////////////////////////////////////
  public:
    Suite();
};

///////////////////////////////////////////////////////////////////////////////

}
