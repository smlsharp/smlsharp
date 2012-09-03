// HeapTest0010
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
 * Tests of garbage collection of Heap.
 *
 * <p><b>purpose of this test:</b></p>
 * <p>
 *  Verifies that the heap manager traces the necessary and sufficient pointer
 * between generations or the rootset and moves the block if needed.
 * </p>
 *
 * <p><b>variation of GC:</b></p>
 *
 * <p>level of GC</p>
 *
 * <ul>
 * <li>minor GC only</li>
 * <li>minor and major GC</li>
 * </ul>
 * 
 * <p><b>variation of the source of the pointer:</b></p>
 *
 * <p>the source S of the pointer</p>
 *
 * <ul>
 * <li>younger block</li>
 * <li>elder-from block</li>
 * <li>rootset</li>
 * </ul>
 *
 * <p>the block type of S</p>
 * (for the cases where S is a block.)
 * <ul>
 * <li>POINTER</li>
 * </ul>
 * <p>
 * (The variation of the block type of S is not examined in this test.
 * Test0006 examines patterns in the block type of S.)
 * </p>
 *
 * <p><b>variation of the destination of the pointer:</b></p>
 *
 * <p>the generation to which the block D belongs to before GC</p>
 *
 * <ul>
 * <li>younger</li>
 * <li>elder-from</li>
 * </ul>
 *
 * <p><b>supplementary comments:</b></p>
 *
 * <p><b>test cases:</b></p>
 *
 * <p>the number of test cases = 2 * 3 * 2 = 12</p>
 *
 * <table border="1">
 * <caption>Test cases matrix</caption>
 * <tr>
 * <th>Case #</th>
 * <th>GC</th>
 * <th>S</th>
 * <th>D</th>
 * <th>expected result</th>
 * <th>comment</th>
 * </tr>
 *
 * <tr>
 * <td>0001</td>
 * <td>minor</td>
 * <td>younger</td>
 * <td>younger</td>
 * <td>trace</td>
 * <td><br></td>
 * </tr>
 *
 * <tr>
 * <td>0002</td>
 * <td>minor</td>
 * <td>younger</td>
 * <td>elder-from</td>
 * <td>not trace</td>
 * <td><br></td>
 * </tr>
 *
 * <tr>
 * <td>0003</td>
 * <td>minor</td>
 * <td>elder-from</td>
 * <td>younger</td>
 * <td>trace</td>
 * <td><br></td>
 * </tr>
 *
 * <tr>
 * <td>0004</td>
 * <td>minor</td>
 * <td>elder-from</td>
 * <td>elder-from</td>
 * <td>not trace</td>
 * <td><br></td>
 * </tr>
 *
 * <tr>
 * <td>0005</td>
 * <td>minor</td>
 * <td>rootset</td>
 * <td>younger</td>
 * <td>trace</td>
 * <td><br></td>
 * </tr>
 *
 * <tr>
 * <td>0006</td>
 * <td>minor</td>
 * <td>rootset</td>
 * <td>elder-from</td>
 * <td>not trace</td>
 * <td><br></td>
 * </tr>
 *
 * <tr>
 * <td>0007</td>
 * <td>major</td>
 * <td>younger</td>
 * <td>younger</td>
 * <td>trace</td>
 * <td><br></td>
 * </tr>
 *
 * <tr>
 * <td>0008</td>
 * <td>major</td>
 * <td>younger</td>
 * <td>elder-from</td>
 * <td>trace</td>
 * <td><br></td>
 * </tr>
 *
 * <tr>
 * <td>0009</td>
 * <td>major</td>
 * <td>elder-from</td>
 * <td>younger</td>
 * <td>trace</td>
 * <td><br></td>
 * </tr>
 *
 * <tr>
 * <td>0010</td>
 * <td>major</td>
 * <td>elder-from</td>
 * <td>elder-from</td>
 * <td>trace</td>
 * <td><br></td>
 * </tr>
 *
 * <tr>
 * <td>0011</td>
 * <td>major</td>
 * <td>rootset</td>
 * <td>younger</td>
 * <td>trace</td>
 * <td><br></td>
 * </tr>
 *
 * <tr>
 * <td>0012</td>
 * <td>major</td>
 * <td>rootset</td>
 * <td>elder-from</td>
 * <td>trace</td>
 * <td><br></td>
 * </tr>
 *
 * </table>
 *
 * <p><b>The detail of the test procedure:</b></p>
 *
 * <ol>
 * <li>If D should be in the elder-from generation, allocates an ATOM block
 *   of 1 field.</li>
 * <li>If S is the rootset, add a pointer to the D to the rootset.</li>
 * <li>If S should be an elder-from block, allocates a block of
 *   POINTER type of 1 field, adds a pointer to S to the rootset,
 *   and initializes the field of S with a pointer to D (if D should be in
 *   the elder-from) or with a pointer to S itself (otherwise). </li>
 * <li>If S or D should be in the elder-from, allocates more blocks so
 *   sufficient to let the heap manager start a minor GC. </li>
 * <li>If D should be in the younger generation, allocates an ATOM block
 *   of 1 field.</li>
 * <li>If S should be a younger block, allocates a POINTER block of 1 field,
 *   and add a pointer to S to the rootset.</li>
 * <li>Initializes or updates the field of S with a pointer to D
 *   except for the case where both S and D are in the elder-from generation.
 *   </li>
 * <li>Allocates more blocks so sufficient to let the heap manager start
 *   GC of the specified level. </li>
 * <li>Verifies the content of the field of S.
 *   <ul>
 *   <li>If the pointer is to be traced, verifies that the content of the
 *     field has been changed so as to point to the updated location of B.
 *     </li>
 *   <li>If the pointer is to be not traced, verifies that the content of
 *     the field is not changed.
 *     </li>
 *   </ul>
 *   </li>
 * </ol>
 *
 */
class HeapTest0010
    : public TestCase
{
    ////////////////////////////////////////
  private:

    ////////////////////////////////////////
  public:
    HeapTest0010(string name)
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
     * <p>prerequisite:</p>
     * <ul>
     * <li>level of GC : minor</li>
     * <li>source : younger</li>
     * <li>destination : younger</li>
     * </ul>
     *
     * <p>expected result:</p>
     * <ul>
     * <li>exceptions : not thrown</li>
     * </ul>
     */
    void testGC0001();

    /**
     * Garbage collection of Heap test case
     *
     * <p>prerequisite:</p>
     * <ul>
     * <li>level of GC : minor</li>
     * <li>source : younger</li>
     * <li>destination : elder-from</li>
     * </ul>
     *
     * <p>expected result:</p>
     * <ul>
     * <li>exceptions : not thrown</li>
     * </ul>
     */
    void testGC0002();

    /**
     * Garbage collection of Heap test case
     *
     * <p>prerequisite:</p>
     * <ul>
     * <li>level of GC : minor</li>
     * <li>source : elder-from</li>
     * <li>destination : younger</li>
     * </ul>
     *
     * <p>expected result:</p>
     * <ul>
     * <li>exceptions : not thrown</li>
     * </ul>
     */
    void testGC0003();

    /**
     * Garbage collection of Heap test case
     *
     * <p>prerequisite:</p>
     * <ul>
     * <li>level of GC : minor</li>
     * <li>source : elder-from</li>
     * <li>destination : elder-from</li>
     * </ul>
     *
     * <p>expected result:</p>
     * <ul>
     * <li>exceptions : not thrown</li>
     * </ul>
     */
    void testGC0004();

    /**
     * Garbage collection of Heap test case
     *
     * <p>prerequisite:</p>
     * <ul>
     * <li>level of GC : minor</li>
     * <li>source : rootset</li>
     * <li>destination : younger</li>
     * </ul>
     *
     * <p>expected result:</p>
     * <ul>
     * <li>exceptions : not thrown</li>
     * </ul>
     */
    void testGC0005();

    /**
     * Garbage collection of Heap test case
     *
     * <p>prerequisite:</p>
     * <ul>
     * <li>level of GC : minor</li>
     * <li>source : rootset</li>
     * <li>destination : elder-from</li>
     * </ul>
     *
     * <p>expected result:</p>
     * <ul>
     * <li>exceptions : not thrown</li>
     * </ul>
     */
    void testGC0006();

    /**
     * Garbage collection of Heap test case
     *
     * <p>prerequisite:</p>
     * <ul>
     * <li>level of GC : major</li>
     * <li>source : younger</li>
     * <li>destination : younger</li>
     * </ul>
     *
     * <p>expected result:</p>
     * <ul>
     * <li>exceptions : not thrown</li>
     * </ul>
     */
    void testGC0007();

    /**
     * Garbage collection of Heap test case
     *
     * <p>prerequisite:</p>
     * <ul>
     * <li>level of GC : major</li>
     * <li>source : younger</li>
     * <li>destination : elder-from</li>
     * </ul>
     *
     * <p>expected result:</p>
     * <ul>
     * <li>exceptions : not thrown</li>
     * </ul>
     */
    void testGC0008();

    /**
     * Garbage collection of Heap test case
     *
     * <p>prerequisite:</p>
     * <ul>
     * <li>level of GC : major</li>
     * <li>source : elder-from</li>
     * <li>destination : younger</li>
     * </ul>
     *
     * <p>expected result:</p>
     * <ul>
     * <li>exceptions : not thrown</li>
     * </ul>
     */
    void testGC0009();

    /**
     * Garbage collection of Heap test case
     *
     * <p>prerequisite:</p>
     * <ul>
     * <li>level of GC : major</li>
     * <li>source : elder-from</li>
     * <li>destination : elder-from</li>
     * </ul>
     *
     * <p>expected result:</p>
     * <ul>
     * <li>exceptions : not thrown</li>
     * </ul>
     */
    void testGC0010();

    /**
     * Garbage collection of Heap test case
     *
     * <p>prerequisite:</p>
     * <ul>
     * <li>level of GC : major</li>
     * <li>source : rootset</li>
     * <li>destination : younger</li>
     * </ul>
     *
     * <p>expected result:</p>
     * <ul>
     * <li>exceptions : not thrown</li>
     * </ul>
     */
    void testGC0011();

    /**
     * Garbage collection of Heap test case
     *
     * <p>prerequisite:</p>
     * <ul>
     * <li>level of GC : major</li>
     * <li>source : rootset</li>
     * <li>destination : elder-from</li>
     * </ul>
     *
     * <p>expected result:</p>
     * <ul>
     * <li>exceptions : not thrown</li>
     * </ul>
     */
    void testGC0012();

    class Suite;
};

class HeapTest0010::Suite
    : public TestSuite
{
    ////////////////////////////////////////
  public:
    Suite();
};

///////////////////////////////////////////////////////////////////////////////

}
