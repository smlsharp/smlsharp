// HeapTest0005
// jp_ac_jaist_iml_runtime

#include "Heap.hh"
#include "Heap.hh"

#include "TestCase.h"
#include "TestSuite.h"

using std::string;

namespace jp_ac_jaist_iml_runtime
{

///////////////////////////////////////////////////////////////////////////////

/**
 * Tests of Heap#getPayload (withoug GC)
 *
 * <p><b>variation of arguments:</b></p>
 *
 * <p>type of block</p>
 *
 * <ul>
 * <li>ATOM(1)</li>
 * </ul>
 *
 * <p><b>variation of internal state of the target object:</b></p>
 *
 * <p><b>supplementary comments:</b></p>
 *
 * <ul>
 * <li>The size of heap area must be large so that blocks can be
 * allocated without invocation of GC.</li>
 * </ul>
 *
 * <p><b>test cases</b></p>
 *
 * <table border="1">
 * <caption>Test cases matrix</caption>
 * <tr>
 * <th>Case #</th>
 * <th>type of block</th>
 * <th>comment</th>
 * </tr>
 *
 * <tr>
 * <th>0001</th>
 * <td align="center">1</td>
 * <td align="center"><br></td>
 * </tr>
 *
 */
class HeapTest0005
    : public TestCase
{
    ////////////////////////////////////////
  private:

    ////////////////////////////////////////
  public:
    HeapTest0005(string name)
        : TestCase(name)
    {
    }

    virtual void setUp();

    virtual void tearDown();

    ////////////////////////////////////////
  public:

    /**
     * Heap#getPayload test case
     *
     * <p>specifies normal arguments, and verifies the result.</p>
     *
     * <p>prerequisite</p>
     * <ul>
     * <li>type of block : ATOM</li>
     * <li>GC : none</li>
     * </ul>
     *
     * <p>expected result</p>
     * <ul>
     * <li>'getPayload' returns a pointer to the first cell of the payload
     *    of the specified block.</li>
     * <li>The value obtained by dereference of the returned pointer equals
     * to the value of the first cell that 'getField(blk, 0)' returns. </li>
     * <li>exceptions : not thrown</li>
     * </ul>
     */
    void testGetPayload0001();

    class Suite;
};

class HeapTest0005::Suite
    : public TestSuite
{
    ////////////////////////////////////////
  public:
    Suite();
};

///////////////////////////////////////////////////////////////////////////////

}
