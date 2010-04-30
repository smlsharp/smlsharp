// HeapTest0003
// jp_ac_jaist_iml_runtime

#include "Heap.hh"

#include "TestCase.h"
#include "TestSuite.h"

using std::string;

namespace jp_ac_jaist_iml_runtime
{

///////////////////////////////////////////////////////////////////////////////

/**
 * Tests of Heap#allocRecordBlock/getPayloadSize/getBitmap
 * (withoug GC)
 *
 * <p><b>purpose of this test:</b></p>
 * <p>
 *  Verifies the behavior of allocAtomBlock, getPayloadSize and getBitmap
 * methods of Heap.
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
 * <p>type of fields</p>
 *
 * <ul>
 * <li>all integer(1)</li>
 * <li>all pointer(2)</li>
 * <li>integer/pointer mixed(3)</li>
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
 * the number of test cases =
 *  3(# of fields) * 3(type of fields) - 1(impossible case) = 9 cases
 * </p>
 *
 * <hr>
 *
 * <table border="1">
 * <caption>Test cases matrix</caption>
 * <tr>
 * <th>Case #</th>
 * <th># of fields</th>
 * <th>type of fields</th>
 * <th>comment</th>
 * </tr>
 *
 * <tr>
 * <th>0001</th>
 * <td align="center">1</td>
 * <td align="center">1</td>
 * <td align="center"><br></td>
 * </tr>
 *
 * <tr>
 * <th>0002</th>
 * <td align="center">1</td>
 * <td align="center">2</td>
 * <td align="center"><br></td>
 * </tr>
 *
 * <tr>
 * <th>-</th>
 * <td align="center">1</td>
 * <td align="center">3</td>
 * <td align="center">impossible case</td>
 * </tr>
 *
 * <tr>
 * <th>0003</th>
 * <td align="center">17</td>
 * <td align="center">1</td>
 * <td align="center"><br></td>
 * </tr>
 *
 * <tr>
 * <th>0004</th>
 * <td align="center">17</td>
 * <td align="center">2</td>
 * <td align="center"><br></td>
 * </tr>
 *
 * <tr>
 * <th>0005</th>
 * <td align="center">17</td>
 * <td align="center">3</td>
 * <td align="center"><br></td>
 * </tr>
 *
 * <tr>
 * <th>0006</th>
 * <td align="center">32</td>
 * <td align="center">1</td>
 * <td align="center"><br></td>
 * </tr>
 *
 * <tr>
 * <th>0007</th>
 * <td align="center">32</td>
 * <td align="center">2</td>
 * <td align="center"><br></td>
 * </tr>
 *
 * <tr>
 * <th>0008</th>
 * <td align="center">32</td>
 * <td align="center">3</td>
 * <td align="center"><br></td>
 * </tr>
 *
 * </table>
 */
class HeapTest0003
    : public TestCase
{
    ////////////////////////////////////////
  private:

    void testAllocRecordBlockImplAllInteger(int heapSize,
                                            int numBlocks,
                                            int numFields);

    void testAllocRecordBlockImplAllPointer(int heapSize,
                                            Bitmap bitmap,
                                            int numBlocks,
                                            int numFields);

    void testAllocRecordBlockImplMixed(int heapSize,
                                       Bitmap bitmap,
                                       int numBlocks,
                                       int numFields);

    ////////////////////////////////////////
  public:
    HeapTest0003(string name)
        : TestCase(name)
    {
    }

    virtual void setUp();

    virtual void tearDown();

    ////////////////////////////////////////
  public:

    /**
     * Heap#allocRecordBlock normal test case
     *
     * <p>specifies normal arguments, and verifies the result.</p>
     *
     * <p>prerequisite</p>
     * <ul>
     * <li># of fields : 1</li>
     * <li>type of fields : all integer</li>
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
    void testAllocRecordBlock0001();

    /**
     * Heap#allocRecordBlock normal test case
     *
     * <p>specifies normal arguments, and verifies the result.</p>
     *
     * <p>prerequisite</p>
     * <ul>
     * <li># of fields : 1</li>
     * <li>type of fields : all pointer</li>
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
    void testAllocRecordBlock0002();

    /**
     * Heap#allocRecordBlock normal test case
     *
     * <p>specifies normal arguments, and verifies the result.</p>
     *
     * <p>prerequisite</p>
     * <ul>
     * <li># of fields : 2</li>
     * <li>type of fields : all integer</li>
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
    void testAllocRecordBlock0003();

    /**
     * Heap#allocRecordBlock normal test case
     *
     * <p>specifies normal arguments, and verifies the result.</p>
     *
     * <p>prerequisite</p>
     * <ul>
     * <li># of fields : 2</li>
     * <li>type of fields : all pointer</li>
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
    void testAllocRecordBlock0004();

    /**
     * Heap#allocRecordBlock normal test case
     *
     * <p>specifies normal arguments, and verifies the result.</p>
     *
     * <p>prerequisite</p>
     * <ul>
     * <li># of fields : 2</li>
     * <li>type of fields : integer/pointer mixed</li>
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
    void testAllocRecordBlock0005();


    /**
     * Heap#allocRecordBlock normal test case
     *
     * <p>specifies normal arguments, and verifies the result.</p>
     *
     * <p>prerequisite</p>
     * <ul>
     * <li># of fields : 32</li>
     * <li>type of fields : all integer</li>
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
    void testAllocRecordBlock0006();

    /**
     * Heap#allocRecordBlock normal test case
     *
     * <p>specifies normal arguments, and verifies the result.</p>
     *
     * <p>prerequisite</p>
     * <ul>
     * <li># of fields : 32</li>
     * <li>type of fields : all pointer</li>
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
    void testAllocRecordBlock0007();

    /**
     * Heap#allocRecordBlock normal test case
     *
     * <p>specifies normal arguments, and verifies the result.</p>
     *
     * <p>prerequisite</p>
     * <ul>
     * <li># of fields : 32</li>
     * <li>type of fields : integer/pointer mixed</li>
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
    void testAllocRecordBlock0008();

    class Suite;
};

class HeapTest0003::Suite
    : public TestSuite
{
    ////////////////////////////////////////
  public:
    Suite();
};

///////////////////////////////////////////////////////////////////////////////

}
