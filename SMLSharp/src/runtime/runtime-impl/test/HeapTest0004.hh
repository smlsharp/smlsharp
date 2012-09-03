// HeapTest0004
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
 * Tests of Heap#updateField (withoug GC)
 *
 * <p><b>variation of arguments:</b></p>
 *
 * <p>type of block</p>
 *
 * <ul>
 * <li>ATOM(1)</li>
 * <li>POINTER(1)</li>
 * <li>RECORD(1)</li>
 * </ul>
 *
 * <p>field type</p>
 *
 * <ul>
 * <li>integer(1)</li>
 * <li>pointer(2)</li>
 * </ul>
 *
 * <p>field index</p>
 *
 * <ul>
 * <li>each test case updates from 1th to 32th field in one case.</li>
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
 * <th>type of field</th>
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
 * <th>-</th>
 * <td align="center">1</td>
 * <td align="center">2</td>
 * <td align="center">impossible</td>
 * </tr>
 *
 * <tr>
 * <th>-</th>
 * <td align="center">2</td>
 * <td align="center">1</td>
 * <td align="center">impossible</td>
 * </tr>
 *
 * <tr>
 * <th>0002</th>
 * <td align="center">2</td>
 * <td align="center">2</td>
 * <td align="center"><br></td>
 * </tr>
 *
 * <tr>
 * <th>0003</th>
 * <td align="center">3</td>
 * <td align="center">1</td>
 * <td align="center"><br></td>
 * </tr>
 *
 * <tr>
 * <th>0004</th>
 * <td align="center">3</td>
 * <td align="center">2</td>
 * <td align="center"><br></td>
 * </tr>
 *
 * </table>
 */
class HeapTest0004
    : public TestCase
{
    ////////////////////////////////////////
  private:

    void testUpdateFieldIntegerImpl(Heap& heap, Cell* block);

    void testUpdateFieldPointerImpl(Heap& heap, Cell* block);

    ////////////////////////////////////////
  public:
    HeapTest0004(string name)
        : TestCase(name)
    {
    }

    virtual void setUp();

    virtual void tearDown();

    ////////////////////////////////////////
  public:

    /**
     * Heap#updateField normal test case
     *
     * <p>specifies normal arguments, and verifies the result.</p>
     *
     * <p>prerequisite</p>
     * <ul>
     * <li>type of block : ATOM</li>
     * <li>type of field : integer</li>
     * <li>GC : none</li>
     * </ul>
     *
     * <p>expected result</p>
     * <ul>
     * <li>getField returns the updated value of the field.</li>
     * <li>exceptions : not thrown</li>
     * </ul>
     */
    void testUpdateField0001();

    /**
     * Heap#updateField normal test case
     *
     * <p>specifies normal arguments, and verifies the result.</p>
     *
     * <p>prerequisite</p>
     * <ul>
     * <li>type of block : POINTER</li>
     * <li>type of field : pointer</li>
     * <li>GC : none</li>
     * </ul>
     *
     * <p>expected result</p>
     * <ul>
     * <li>getField returns the updated value of the field.</li>
     * <li>exceptions : not thrown</li>
     * </ul>
     */
    void testUpdateField0002();

    /**
     * Heap#updateField normal test case
     *
     * <p>specifies normal arguments, and verifies the result.</p>
     *
     * <p>prerequisite</p>
     * <ul>
     * <li>type of block : RECORD</li>
     * <li>type of field : integer</li>
     * <li>GC : none</li>
     * </ul>
     *
     * <p>expected result</p>
     * <ul>
     * <li>getField returns the updated value of the field.</li>
     * <li>exceptions : not thrown</li>
     * </ul>
     */
    void testUpdateField0003();

    /**
     * Heap#updateField normal test case
     *
     * <p>specifies normal arguments, and verifies the result.</p>
     *
     * <p>prerequisite</p>
     * <ul>
     * <li>type of block : RECORD</li>
     * <li>type of field : pointer</li>
     * <li>GC : none</li>
     * </ul>
     *
     * <p>expected result</p>
     * <ul>
     * <li>getField returns the updated value of the field.</li>
     * <li>exceptions : not thrown</li>
     * </ul>
     */
    void testUpdateField0004();

    class Suite;
};

class HeapTest0004::Suite
    : public TestSuite
{
    ////////////////////////////////////////
  public:
    Suite();
};

///////////////////////////////////////////////////////////////////////////////

}
