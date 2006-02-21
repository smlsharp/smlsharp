// HeapTest0009
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
 * Verifies the behavior of GC in situations where the graph of blocks
 * contains IGPs.
 * ('IGP' is an inter-generational pointer from a younger block to an elder
 * block).
 * </p>
 *
 * <p><b>the variety of IGP</b></p>
 *
 * <p>the number of IGPs</p>
 * <ul>
 * <li>1</li>
 * <li>2</li>
 * </ul>
 *
 * <p>two IGPs the source of which are the same block</p>
 * <ul>
 * <li>exist</li>
 * <li>not exist</li>
 * </ul>
 *
 * <p>two IGPs the destination of which are the same block</p>
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
 * <th># of IGP</th>
 * <th>IGPs of the same source</th>
 * <th>IGPs of the same destination</th>
 * <th>comment</th>
 * </tr>
 *
 * <tr>
 * <td>0001</td>
 * <td>1</td>
 * <td>-</td>
 * <td>-</td>
 * <td><br></td>
 * </tr>
 *
 * <tr>
 * <td>0002</td>
 * <td>2</td>
 * <td>exist</td>
 * <td>exist</td>
 * <td><br></td>
 * </tr>
 *
 * <tr>
 * <td>0003</td>
 * <td>2</td>
 * <td>exist</td>
 * <td>not exist</td>
 * <td><br></td>
 * </tr>
 *
 * <tr>
 * <td>0004</td>
 * <td>2</td>
 * <td>not exist</td>
 * <td>exist</td>
 * <td><br></td>
 * </tr>
 *
 * <tr>
 * <td>0005</td>
 * <td>2</td>
 * <td>not exist</td>
 * <td>not exist</td>
 * <td><br></td>
 * </tr>
 *
 * </table>
 *
 * <p><b>The detail of the test procedure:</b></p>
 *
 * <ol>
 * <li>Allocates POINTER blocks which are used as the source of IGPs.
 *   <ul>
 *   <li>If the number of IGPs should be 2 and the sources of those IGPs 
 *     should not be the same block, allocates 2 blocks.
 *     Otherwise, allocates 1 block.</li>
 *   <li>If the number of IGPs should be 2 and the source of those IGPs
 *     should be the same block, allocates blocks of 2 fields.
 *     Otherwise, the number of blocks should be 1.</li>
 *   </ul>
 *   </li>
 * <li>Initializes the fields of the allocated blocks with pointers to the
 *   blocks themselves.</li>
 * <li>Adds pointers to the source blocks to the rootset.</li>
 * <li>Allocates more blocks sufficient to let the heap manager start minor
 *   GC.</li>
 * <li>Allocates ATOM blocks which are used as the destination of IGPs.
 *     If the number of IGPs should be 2 and the destination of those IGPs 
 *     should not be the same block, allocates 2 blocks.
 *     Otherwise, allocates 1 block.
 *     In any case, specifies 1 as the number of fields of blocks.
 *   </li>
 * <li>Initializes the destination blocks with unique integers.</li>
 * <li>Updates the fields of the source blocks with pointers to the destination
 *   blocks.</li>
 * <li>Allocates more blocks sufficient to let the heap manager start minor GC.
 *   </li>
 * <li>Verifies that GC preserves the structure of the graph of blocks.</li>
 * </ol>
 */
class HeapTest0009
    : public TestCase
{
    ////////////////////////////////////////
  private:

    ////////////////////////////////////////
  public:
    HeapTest0009(string name)
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
     * <li># of IGP : 1</li>
     * <li>source of IGPs : -</li>
     * <li>destination of IGPs : -</li>
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
     * <li># of IGP : 2</li>
     * <li>source of IGPs : 1</li>
     * <li>destination of IGPs : 1</li>
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
     * <li># of IGP : 2</li>
     * <li>source of IGPs : 1</li>
     * <li>destination of IGPs : 2</li>
     * </ul>
     *
     * <p>expected result</p>
     * <ul>
     * <li>exceptions : not thrown</li>
     * </ul>
     */
    void testGC0003();

    /**
     * Garbage collection of Heap test case
     *
     * <p></p>
     *
     * <p>prerequisite</p>
     * <ul>
     * <li># of IGP : 2</li>
     * <li>source of IGPs : 2</li>
     * <li>destination of IGPs : 1</li>
     * </ul>
     *
     * <p>expected result</p>
     * <ul>
     * <li>exceptions : not thrown</li>
     * </ul>
     */
    void testGC0004();

    /**
     * Garbage collection of Heap test case
     *
     * <p></p>
     *
     * <p>prerequisite</p>
     * <ul>
     * <li># of IGP : 2</li>
     * <li>source of IGPs : 2</li>
     * <li>destination of IGPs : 2</li>
     * </ul>
     *
     * <p>expected result</p>
     * <ul>
     * <li>exceptions : not thrown</li>
     * </ul>
     */
    void testGC0005();

    class Suite;
};

class HeapTest0009::Suite
    : public TestSuite
{
    ////////////////////////////////////////
  public:
    Suite();
};

///////////////////////////////////////////////////////////////////////////////

}
