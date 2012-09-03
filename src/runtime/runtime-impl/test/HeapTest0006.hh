// HeapTest0006
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
 *  Verifies that the heap manager identifies and traces the necessary and
 * sufficient pointer fields in a block at GC.
 * </p>
 *
 * <p><b>variation of the target block:</b></p>
 *
 * <p>type of block</p>
 *
 * <ul>
 * <li>ATOM</li>
 * <li>POINTER</li>
 * <li>RECORD</li>
 * </ul>
 *
 * <p>the number of fields in the block</p>
 *
 * <ul>
 * <li>0</li>
 * <li>1</li>
 * <li>2</li>
 * <li>17</li>
 * <li>32</li>
 * </ul>
 *
 * <p>the number of pointer fields in the block</p>
 *
 * <ul>
 * <li>0</li>
 * <li>1</li>
 * <li>2</li>
 * <li>17</li>
 * <li>32</li>
 * </ul>
 *
 * <p>bitmap of the block</p>
 *
 * 0, 1, 01, 10, ...., 11111111 11111111 11111111 11111111
 *
 * <p><b>variation of internal state of heap manager:</b></p>
 *
 * <p>level of GC</p>
 *
 * <ul>
 * <li>minor GC only</li>
 * <li>minor and major GC</li>
 * </ul>
 * (*) Only the first case is tested.
 * 
 * <p><b>supplementary comments:</b></p>
 *
 * <p><b>test cases:</b></p>
 *
 * <table border="1">
 * <caption>Test cases matrix</caption>
 * <tr>
 * <th>Case #</th>
 * <th>type of block</th>
 * <th># of fields</th>
 * <th># of pointer fields</th>
 * <th>bitmap of block</th>
 * <th>comment</th>
 * </tr>
 *
 * <tr>
 * <td>0001</td>
 * <td>ATOM</td>
 * <td>32</td>
 * <td>0</td>
 * <td>-</td>
 * <td><br></td>
 * </tr>
 *
 * <tr>
 * <td>0002</td>
 * <td>POINTER</td>
 * <td>1</td>
 * <td>1</td>
 * <td>-</td>
 * <td><br></td>
 * </tr>
 *
 * <tr>
 * <td>0003</td>
 * <td>POINTER</td>
 * <td>2</td>
 * <td>2</td>
 * <td>-</td>
 * <td><br></td>
 * </tr>
 *
 * <tr>
 * <td>0004</td>
 * <td>POINTER</td>
 * <td>32</td>
 * <td>32</td>
 * <td>-</td>
 * <td><br></td>
 * </tr>
 *
 * <tr>
 * <td>0005</td>
 * <td>RECORD</td>
 * <td>1</td>
 * <td>-</td>
 * <td>0</td>
 * <td><br></td>
 * </tr>
 *
 * <tr>
 * <td>0006</td>
 * <td>RECORD</td>
 * <td>1</td>
 * <td>-</td>
 * <td>1</td>
 * <td><br></td>
 * </tr>
 *
 * <tr>
 * <td>0007</td>
 * <td>RECORD</td>
 * <td>2</td>
 * <td>-</td>
 * <td>00</td>
 * <td><br></td>
 * </tr>
 *
 * <tr>
 * <td>0008</td>
 * <td>RECORD</td>
 * <td>2</td>
 * <td>-</td>
 * <td>01</td>
 * <td><br></td>
 * </tr>
 *
 * <tr>
 * <td>0009</td>
 * <td>RECORD</td>
 * <td>2</td>
 * <td>-</td>
 * <td>10</td>
 * <td><br></td>
 * </tr>
 *
 * <tr>
 * <td>0010</td>
 * <td>RECORD</td>
 * <td>2</td>
 * <td>-</td>
 * <td>11</td>
 * <td><br></td>
 * </tr>
 *
 * <tr>
 * <td>0011</td>
 * <td>RECORD</td>
 * <td>32</td>
 * <td>-</td>
 * <td>00000000 00000000 00000000 00000000</td>
 * <td><br></td>
 * </tr>
 *
 * <tr>
 * <td>0012</td>
 * <td>RECORD</td>
 * <td>32</td>
 * <td>-</td>
 * <td>10000000 00000001 00000000 00000001</td>
 * <td><br></td>
 * </tr>
 *
 * <tr>
 * <td>0013</td>
 * <td>RECORD</td>
 * <td>32</td>
 * <td>-</td>
 * <td>11111111 11111111 11111111 11111111</td>
 * <td><br></td>
 * </tr>
 *
 * </table>
 *
 * <p><b>The detail of the test procedure:</b></p>
 *
 * <p>
 * The sequence of these cases is as follows.
 * <ol>
 * <li>Allocates the target block of the specified type.</li>
 * <li>Initializes each fields of the allocated block as follows.
 *     (assume that the index of the field to be initialized is 'i'.)
 *   <ul>
 *   <li>Non-pointer field is initialized with an integer 'i'.</li>
 *   <li>For pointer field, before the allcation of the target block
 *     allocates an 1-field atom block and initializes the contents of
 *     the atom block with an integer 'i'. After the allocation of the target
 *     block, initializes the target field with a pointer to the atom block.
 *   </li>
 *   </ul>
 *   (Up to this point, any GC must not be invoked.)
 *   </li>
 * <li>Allocates more blocks so sufficient to let the heap manager start a GC.
 *     </li>
 * <li>Verifies the content of each field of the target block.
 *   (The target block should be forwarded by GC.)
 *   (assume that the index of the field to be verified is 'i'.)
 *   <ul>
 *   <li>the content of the non-pointer field must be an integer 'i'</li>
 *   <li>the content of the pointer field must be a pointer to an atom block
 *      which holds an integer 'i' in its only field.</li>
 *   </ul>
 *   (If the heap manager traced any non-pointer field mistakenly,
 *   a certain fault(segmentaion fault, etc.) or an exception should be
 *   thrown immediately.
 *   If the heap manager finished GC without tracing a pointer field, the
 *   content of the field would be left unchanged.)
 *   </li>
 * </ol>
 * </p>
 *
 */
class HeapTest0006
    : public TestCase
{
    ////////////////////////////////////////
  private:

    void testGCForPointerBlockImpl(int fields);

    void testGCForRecordBlockImpl
    (int fields, int pointerFields, Bitmap bitmap);

    ////////////////////////////////////////
  public:
    HeapTest0006(string name)
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
     * <p>
     *  Lets the heap manager start GC, and verifies that the manager
     * traces only the required and sufficient pointer fields of blocks.
     * </p>
     *
     * <p>prerequisite:</p>
     * <ul>
     * <li>type of block : ATOM</li>
     * <li>minor GC : happens</li>
     * <li>major GC : not happens</li>
     * <li># of fields : 32</li>
     * <li># of pointers : 0</li>
     * </ul>
     *
     * <p>expected result:</p>
     * <ul>
     * <li>(see above comment)</li>
     * <li>exceptions : not thrown</li>
     * </ul>
     */
    void testGC0001();

    /**
     * Garbage collection of Heap test case
     *
     * <p>prerequisite:</p>
     * <ul>
     * <li>type of block : POINTER</li>
     * <li>minor GC : happens</li>
     * <li>major GC : not happens</li>
     * <li># of fields : 1</li>
     * <li># of pointers : 1</li>
     * </ul>
     *
     * <p>expected result:</p>
     * <ul>
     * <li>(see above comment)</li>
     * <li>exceptions : not thrown</li>
     * </ul>
     */
    void testGC0002();

    /**
     * Garbage collection of Heap test case
     *
     * <p>prerequisite:</p>
     * <ul>
     * <li>type of block : POINTER</li>
     * <li>minor GC : happens</li>
     * <li>major GC : not happens</li>
     * <li># of fields : 2</li>
     * <li># of pointers : 2</li>
     * </ul>
     *
     * <p>expected result:</p>
     * <ul>
     * <li>(see above comment)</li>
     * <li>exceptions : not thrown</li>
     * </ul>
     */
    void testGC0003();

    /**
     * Garbage collection of Heap test case
     *
     * <p>prerequisite:</p>
     * <ul>
     * <li>type of block : POINTER</li>
     * <li>minor GC : happens</li>
     * <li>major GC : not happens</li>
     * <li># of fields : 32</li>
     * <li># of pointers : 32</li>
     * </ul>
     *
     * <p>expected result:</p>
     * <ul>
     * <li>(see above comment)</li>
     * <li>exceptions : not thrown</li>
     * </ul>
     */
    void testGC0004();

    /**
     * Garbage collection of Heap test case
     *
     * <p>prerequisite:</p>
     * <ul>
     * <li>type of block : RECORD</li>
     * <li>minor GC : happens</li>
     * <li>major GC : not happens</li>
     * <li># of fields : 1</li>
     * <li>Bitmap : 0</li>
     * </ul>
     *
     * <p>expected result:</p>
     * <ul>
     * <li>(see above comment)</li>
     * <li>exceptions : not thrown</li>
     * </ul>
     */
    void testGC0005();


    /**
     * Garbage collection of Heap test case
     *
     * <p>prerequisite:</p>
     * <ul>
     * <li>type of block : RECORD</li>
     * <li>minor GC : happens</li>
     * <li>major GC : not happens</li>
     * <li># of fields : 1</li>
     * <li>Bitmap : 1</li>
     * </ul>
     *
     * <p>expected result:</p>
     * <ul>
     * <li>(see above comment)</li>
     * <li>exceptions : not thrown</li>
     * </ul>
     */
    void testGC0006();

    /**
     * Garbage collection of Heap test case
     *
     * <p>prerequisite:</p>
     * <ul>
     * <li>type of block : RECORD</li>
     * <li>minor GC : happens</li>
     * <li>major GC : not happens</li>
     * <li># of fields : 2</li>
     * <li>Bitmap : 00B</li>
     * </ul>
     *
     * <p>expected result:</p>
     * <ul>
     * <li>(see above comment)</li>
     * <li>exceptions : not thrown</li>
     * </ul>
     */
    void testGC0007();

    /**
     * Garbage collection of Heap test case
     *
     * <p>prerequisite:</p>
     * <ul>
     * <li>type of block : RECORD</li>
     * <li>minor GC : happens</li>
     * <li>major GC : not happens</li>
     * <li># of fields : 2</li>
     * <li>Bitmap : 01B</li>
     * </ul>
     *
     * <p>expected result:</p>
     * <ul>
     * <li>(see above comment)</li>
     * <li>exceptions : not thrown</li>
     * </ul>
     */
    void testGC0008();

    /**
     * Garbage collection of Heap test case
     *
     * <p>prerequisite:</p>
     * <ul>
     * <li>type of block : RECORD</li>
     * <li>minor GC : happens</li>
     * <li>major GC : not happens</li>
     * <li># of fields : 2</li>
     * <li>Bitmap : 10B</li>
     * </ul>
     *
     * <p>expected result:</p>
     * <ul>
     * <li>(see above comment)</li>
     * <li>exceptions : not thrown</li>
     * </ul>
     */
    void testGC0009();

    /**
     * Garbage collection of Heap test case
     *
     * <p>prerequisite:</p>
     * <ul>
     * <li>type of block : RECORD</li>
     * <li>minor GC : happens</li>
     * <li>major GC : not happens</li>
     * <li># of fields : 2</li>
     * <li>Bitmap : 11B</li>
     * </ul>
     *
     * <p>expected result:</p>
     * <ul>
     * <li>(see above comment)</li>
     * <li>exceptions : not thrown</li>
     * </ul>
     */
    void testGC0010();

    /**
     * Garbage collection of Heap test case
     *
     * <p>prerequisite:</p>
     * <ul>
     * <li>type of block : RECORD</li>
     * <li>minor GC : happens</li>
     * <li>major GC : not happens</li>
     * <li># of fields : 32</li>
     * <li>Bitmap : 00000000000000000000000000000000B</li>
     * </ul>
     *
     * <p>expected result:</p>
     * <ul>
     * <li>(see above comment)</li>
     * <li>exceptions : not thrown</li>
     * </ul>
     */
    void testGC0011();

    /**
     * Garbage collection of Heap test case
     *
     * <p>prerequisite:</p>
     * <ul>
     * <li>type of block : RECORD</li>
     * <li>minor GC : happens</li>
     * <li>major GC : not happens</li>
     * <li># of fields : 32</li>
     * <li>Bitmap : 10000000 00000001 00000000 00000001B</li>
     * </ul>
     *
     * <p>expected result:</p>
     * <ul>
     * <li>(see above comment)</li>
     * <li>exceptions : not thrown</li>
     * </ul>
     */
    void testGC0012();

    /**
     * Garbage collection of Heap test case
     *
     * <p>prerequisite:</p>
     * <ul>
     * <li>type of block : RECORD</li>
     * <li>minor GC : happens</li>
     * <li>major GC : not happens</li>
     * <li># of fields : 32</li>
     * <li>Bitmap : 11111111111111111111111111111111B</li>
     * </ul>
     *
     * <p>expected result:</p>
     * <ul>
     * <li>(see above comment)</li>
     * <li>exceptions : not thrown</li>
     * </ul>
     */
    void testGC0013();


    class Suite;
};

class HeapTest0006::Suite
    : public TestSuite
{
    ////////////////////////////////////////
  public:
    Suite();
};

///////////////////////////////////////////////////////////////////////////////

}
