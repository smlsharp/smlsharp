// HeapTest0008
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
 * Tests of garbage collection of Heap
 *
 * <p><b>purpose of this test:</b></p>
 * <p>
 *  Verifies the behavior of GC in situations where the graph of blocks has
 * cycles.
 * </p>
 *
 * <p><b>the variety in structure of the graph</b></p>
 *
 * <p>the number of blocks constituting the cycle</p>
 * <ul>
 * <li>1</li>
 * <li>2</li>
 * <li>3</li>
 * </ul>
 *
 * <p>multiplicity</p>
 * <ul>
 * <li>1</li>
 * <li>2</li>
 * </ul>
 * ('multiplicity' is the number of edges of the same direction between
 *  a pair of blocks.
 *  If there are two edges from a block A to a block B, the mulitiplicity from
 * A to B is 2.)
 *
 * <p>edges which are IGP</p>
 * <ul>
 * <li>exist</li>
 * <li>not exist</li>
 * </ul>
 *
 * <p><b>supplementary comments:</b></p>
 *
 * <p><b>test cases:</b></p>
 *
 * <table border="1">
 * <caption>Test cases matrix</caption>
 * <tr>
 * <th>Case #</th>
 * <th># of blocks</th>
 * <th>multiplicity</th>
 * <th>IGP edge</th>
 * <th>comment</th>
 * </tr>
 *
 * <tr>
 * <td>0001</td>
 * <td>1</td>
 * <td>1</td>
 * <td>not exist</td>
 * <td><br></td>
 * </tr>
 *
 * <tr>
 * <td>-</td>
 * <td>1</td>
 * <td>1</td>
 * <td>exists</td>
 * <td>impossible</td>
 * </tr>
 *
 * <tr>
 * <td>-</td>
 * <td>1</td>
 * <td>2</td>
 * <td>not exist</td>
 * <td>omitted</td>
 * </tr>
 *
 * <tr>
 * <td>-</td>
 * <td>1</td>
 * <td>2</td>
 * <td>exists</td>
 * <td>impossible</td>
 * </tr>
 *
 * <tr>
 * <td>0002</td>
 * <td>2</td>
 * <td>1</td>
 * <td>not exist</td>
 * <td><br></td>
 * </tr>
 *
 * <tr>
 * <td>-</td>
 * <td>2</td>
 * <td>1</td>
 * <td>exists</td>
 * <td>omitted</td>
 * </tr>
 *
 * <tr>
 * <td>-</td>
 * <td>2</td>
 * <td>2</td>
 * <td>not exist</td>
 * <td>omitted</td>
 * </tr>
 *
 * <tr>
 * <td>-</td>
 * <td>2</td>
 * <td>2</td>
 * <td>exists</td>
 * <td>omitted</td>
 * </tr>
 *
 * <tr>
 * <td>-</td>
 * <td>3</td>
 * <td>1</td>
 * <td>not exists</td>
 * <td>omitted</td>
 * </tr>
 *
 * <tr>
 * <td>-</td>
 * <td>3</td>
 * <td>1</td>
 * <td>exists</td>
 * <td>omitted</td>
 * </tr>
 *
 * <tr>
 * <td>-</td>
 * <td>3</td>
 * <td>2</td>
 * <td>not exist</td>
 * <td>omitted</td>
 * </tr>
 *
 * <tr>
 * <td>0003</td>
 * <td>3</td>
 * <td>2</td>
 * <td>exists</td>
 * <td><br></td>
 * </tr>
 *
 * </table>
 *
 * (ToDo : is this sufficient ?)
 *
 * <p><b>The detail of the test procedure:</b></p>
 *
 * <p>
 * The sequence of these cases is as follows.
 * <ol>
 * <li>Allocates the specified number of POINTER blocks, specifying the
 *   multiplicity as the number of fields.
 *   In the test case where IGPs should exist, allocates some dummy blocks
 *   in the middle of these allocation, so that the heap manager starts
 *   minor GC and moves allocated blocks to the elder generation.
 *   </li>
 * <li>Links allocated blocks.</li>
 * <li>Allocates more blocks sufficient to let the heap manager start GC.</li>
 * <li>Verifies that GC preserve the structure of the graph of blocks.</li>
 * </ol>
 */
class HeapTest0008
    : public TestCase
{
    ////////////////////////////////////////
  private:

    ////////////////////////////////////////
  public:
    HeapTest0008(string name)
        : TestCase(name)
    {
    }

    virtual void setUp();

    virtual void tearDown();

    ////////////////////////////////////////
  public:

    /**
     * Garbage collection of Heap test case
     *
     * <p></p>
     *
     * <p>prerequisite</p>
     * <ul>
     * <li>the number of blocks : 1</li>
     * <li>multiplicity : 1</li>
     * <li>IGP : not exist</li>
     * </ul>
     *
     * <p>expected result</p>
     * <ul>
     * <li>exceptions : not thrown</li>
     * </ul>
     */
    void testGC0001();

    /**
     * Garbage collection of Heap test case
     *
     * <p></p>
     *
     * <p>prerequisite</p>
     * <ul>
     * <li>the number of blocks : 2</li>
     * <li>multiplicity : 1</li>
     * <li>IGP : not exist</li>
     * </ul>
     *
     * <p>expected result</p>
     * <ul>
     * <li>exceptions : not thrown</li>
     * </ul>
     */
    void testGC0002();

    /**
     * Garbage collection of Heap test case
     *
     * <p></p>
     *
     * <p>prerequisite</p>
     * <ul>
     * <li>the number of blocks : 3</li>
     * <li>multiplicity : 2</li>
     * <li>IGP : exists</li>
     * </ul>
     *
     * <p>expected result</p>
     * <ul>
     * <li>exceptions : not thrown</li>
     * </ul>
     */
    void testGC0003();

    class Suite;
};

class HeapTest0008::Suite
    : public TestSuite
{
    ////////////////////////////////////////
  public:
    Suite();
};

///////////////////////////////////////////////////////////////////////////////

}
