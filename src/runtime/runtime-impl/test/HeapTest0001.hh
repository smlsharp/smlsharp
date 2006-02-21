// HeapTest0001
// jp_ac_jaist_iml_runtime

#include "TestCase.h"
#include "TestSuite.h"

using std::string;

namespace jp_ac_jaist_iml_runtime
{

///////////////////////////////////////////////////////////////////////////////

/**
 * Tests of Heap#allocAtomBlock/getPayloadSize (withoug GC)
 *
 * <p><b>purpose of this test:</b></p>
 * <p>
 *  Verifies the behavior of allocAtomBlock and getPayloadSize methods of
 * Heap.
 * </p>
 *
 * <p><b>variation of arguments:</b></p>
 *
 * <p>type of block</p>
 *
 * <p>the number of fields</p>
 *
 * <ul>
 * <li>1</li>
 * <li>17</li>
 * <li>32</li>
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
 * <p>
 * the number of test cases = 3(# of fields) cases
 * </p>
 *
 * <table border="1">
 * <caption>Test cases matrix</caption>
 * <tr>
 * <th>Case #</th>
 * <th># of fields</th>
 * <th>comment</th>
 * </tr>
 *
 * <tr>
 * <th>0001</th>
 * <td align="center">1</td>
 * <td align="center"><br></td>
 * </tr>
 *
 * <tr>
 * <th>0002</th>
 * <td align="center">17</td>
 * <td align="center"><br></td>
 * </tr>
 *
 * <tr>
 * <th>0003</th>
 * <td align="center">32</td>
 * <td align="center"><br></td>
 * </tr>
 *
 * </table>
 */
class HeapTest0001
    : public TestCase
{
    ////////////////////////////////////////
  private:

    void testAllocAtomBlockImpl(int heapSize,
                                int numBlocks,
                                int numFields);

    ////////////////////////////////////////
  public:
    HeapTest0001(string name)
        : TestCase(name)
    {
    }

    virtual void setUp();

    virtual void tearDown();

    ////////////////////////////////////////
  public:

    /**
     * Heap#allocAtomBlock normal test case
     *
     * <p>specifies normal arguments, and verifies the result.</p>
     *
     * <p>prerequisite</p>
     * <ul>
     * <li># of fields : 1</li>
     * <li># of blocks : 3</li>
     * <li>GC : none</li>
     * </ul>
     *
     * <p>expected result</p>
     * <ul>
     * <li>the content of each field is preserved after all blocks have
     *     been allocated.</li>
     * <li>exceptions : not thrown</li>
     * </ul>
     */
    void testAllocAtomBlock0001();

    /**
     * Heap#allocAtomBlock normal test case
     *
     * <p>specifies normal arguments, and verifies the result.</p>
     *
     * <p>prerequisite</p>
     * <ul>
     * <li># of fields : 2</li>
     * <li># of blocks : 3</li>
     * <li>GC : none</li>
     * </ul>
     *
     * <p>expected result</p>
     * <ul>
     * <li>the content of each field is preserved after all blocks have
     *     been allocated.</li>
     * <li>exceptions : not thrown</li>
     * </ul>
     */
    void testAllocAtomBlock0002();

    /**
     * Heap#allocAtomBlock normal test case
     *
     * <p>specifies normal arguments, and verifies the result.</p>
     *
     * <p>prerequisite</p>
     * <ul>
     * <li># of fields : 32</li>
     * <li># of blocks : 3</li>
     * <li>GC : none</li>
     * </ul>
     *
     * <p>expected result</p>
     * <ul>
     * <li>the content of each field is preserved after all blocks have
     *     been allocated.</li>
     * <li>exceptions : not thrown</li>
     * </ul>
     */
    void testAllocAtomBlock0003();

    class Suite;
};

class HeapTest0001::Suite
    : public TestSuite
{
    ////////////////////////////////////////
  public:
    Suite();
};

///////////////////////////////////////////////////////////////////////////////

}
