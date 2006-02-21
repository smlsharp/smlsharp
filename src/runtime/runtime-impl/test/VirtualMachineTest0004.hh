// VirtualMachineTest0004
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
 *  Verifies that the pointers in the stack frames of the VM are traced at GC.
 *
 * <p><b>purpose of this test:</b></p>
 * <p>
 * </p>
 *
 * <p><b>supplementary comments:</b></p>
 *
 * <p><b>test cases:</b></p>
 *
 * <table border="1">
 * <caption>Test cases matrix</caption>
 * <tr>
 * <th>Case</th>
 * <th>record entries</th>
 * <th>comment</th>
 * </tr>
 *
 * <tr>
 * <th>0003</th>
 * <td>0</td>
 * <td>0</td>
 * <td>1<br>
 *     0B</td>
 * <td>&nbsp;</td>
 * </tr>
 *
 * <tr>
 * <th>0004</th>
 * <td>0</td>
 * <td>0</td>
 * <td>1<br>
 *     1B</td>
 * <td>&nbsp;</td>
 * </tr>
 *
 * <tr>
 * <th>0005</th>
 * <td>0</td>
 * <td>0</td>
 * <td>32<br>
 *     00000000 00000000 00000000 00000000B</td>
 * <td>&nbsp;</td>
 * </tr>
 *
 * <tr>
 * <th>0006</th>
 * <td>0</td>
 * <td>0</td>
 * <td>32<br>
 *     11111111 11111111 11111111 11111111B</td>
 * <td>&nbsp;</td>
 * </tr>
 *
 * </table>
 *
 * <p><b>The detail of the test procedure:</b></p>
 *
 * <p>
 * The sequence of these cases is as follows.
 * <ol>
 * <li>Sets up the VM and the heap.</li>
 * <li>Builds heap monitor and execution monitors and attaches them to the heap
 *     and the VM respectively. </li>
 * <li>Makes a code block which requires so much heap allocation that
 *    invokes garbage collection in the heap manager.</li>
 * <li>Calls the <code>execute</code> method on the VM with the code block
 *    as a parameter.</li>
 * <li>Checks the pointers in the pointer entries and record entries contained
 *   in the stack frames are updated to point at valid blocks.</li>
 * </ol>
 */
class VirtualMachineTest0004
    : public TestCase
{
    ////////////////////////////////////////
  private:

    ////////////////////////////////////////

  public:
    VirtualMachineTest0004(string name)
        : TestCase(name)
    {
    }

    virtual void setUp();

    virtual void tearDown();

    ////////////////////////////////////////
  public:

    /**
     *  Verifies that the pointers in the stack frames of the VM are traced
     * at GC.
     *
     * <p>prerequisite</p>
     * <ul>
     * <li>stack frames : 1
     *    <ul>
     *    <li>records : 1<br>
     *        bitmap : <br>
     *                 0B</li>
     *        entry/group : 1
     *    </ul>
     * </ul>
     *
     * <p>expected result</p>
     * <ul>
     * <li>no entries is updated</li>
     * <li>exceptions : not thrown</li>
     * </ul>
     */
    void testGC0001();

    /**
     *  Verifies that the pointers in the stack frames of the VM are traced
     * at GC.
     *
     * <p>prerequisite</p>
     * <ul>
     * <li>stack frames : 1
     *    <ul>
     *    <li>records : 1<br>
     *        bitmap : <br>
     *                 1B</li>
     *        entry/group : 1
     *    </ul>
     * </ul>
     *
     * <p>expected result</p>
     * <ul>
     * <li>record entries are updated</li>
     * <li>exceptions : not thrown</li>
     * </ul>
     */
    void testGC0002();

    /**
     *  Verifies that the pointers in the stack frames of the VM are traced
     * at GC.
     *
     * <p>prerequisite</p>
     * <ul>
     * <li>stack frames : 1
     *    <ul>
     *    <li>records : 32<br>
     *        bitmap : <br>
     *                 00000000 00000000 00000000 00000000B</li>
     *        entry/group : 1
     *    </ul>
     * </ul>
     *
     * <p>expected result</p>
     * <ul>
     * <li>no entries is updated</li>
     * <li>exceptions : not thrown</li>
     * </ul>
     */
    void testGC0003();

    /**
     *  Verifies that the pointers in the stack frames of the VM are traced
     * at GC.
     *
     * <p>prerequisite</p>
     * <ul>
     * <li>stack frames : 1
     *    <ul>
     *    <li>records : 32<br>
     *        bitmap : <br>
     *                 00001111 00001111 00001111 00001111B</li>
     *        entry/group : 1
     *    </ul>
     * </ul>
     *
     * <p>expected result</p>
     * <ul>
     * <li>pointers in record entries are updated</li>
     * <li>exceptions : not thrown</li>
     * </ul>
     */
    void testGC0004();

    /**
     *  Verifies that the pointers in the stack frames of the VM are traced
     * at GC.
     *
     * <p>prerequisite</p>
     * <ul>
     * <li>stack frames : 1
     *    <ul>
     *    <li>records : 32<br>
     *        bitmap : <br>
     *                 11111111 11111111 11111111 11111111B</li>
     *        entry/group : 1
     *    </ul>
     * </ul>
     *
     * <p>expected result</p>
     * <ul>
     * <li>pointers in record entries are updated</li>
     * <li>exceptions : not thrown</li>
     * </ul>
     */
    void testGC0005();

    /**
     *  Verifies that the pointers in the stack frames of the VM are traced
     * at GC.
     *
     * <p>prerequisite</p>
     * <ul>
     * <li>stack frames : 1
     *    <ul>
     *    <li>records : 1<br>
     *        bitmap : <br>
     *                 0B</li>
     *        entry/group : 2
     *    </ul>
     * </ul>
     *
     * <p>expected result</p>
     * <ul>
     * <li>no entries is updated</li>
     * <li>exceptions : not thrown</li>
     * </ul>
     */
    void testGC0011();

    /**
     *  Verifies that the pointers in the stack frames of the VM are traced
     * at GC.
     *
     * <p>prerequisite</p>
     * <ul>
     * <li>stack frames : 1
     *    <ul>
     *    <li>records : 1<br>
     *        bitmap : <br>
     *                 1B</li>
     *        entry/group : 2
     *    </ul>
     * </ul>
     *
     * <p>expected result</p>
     * <ul>
     * <li>record entries are updated</li>
     * <li>exceptions : not thrown</li>
     * </ul>
     */
    void testGC0012();

    /**
     *  Verifies that the pointers in the stack frames of the VM are traced
     * at GC.
     *
     * <p>prerequisite</p>
     * <ul>
     * <li>stack frames : 1
     *    <ul>
     *    <li>records : 32<br>
     *        bitmap : <br>
     *                 00000000 00000000 00000000 00000000B</li>
     *        entry/group : 2
     *    </ul>
     * </ul>
     *
     * <p>expected result</p>
     * <ul>
     * <li>no entries is updated</li>
     * <li>exceptions : not thrown</li>
     * </ul>
     */
    void testGC0013();

    /**
     *  Verifies that the pointers in the stack frames of the VM are traced
     * at GC.
     *
     * <p>prerequisite</p>
     * <ul>
     * <li>stack frames : 1
     *    <ul>
     *    <li>records : 32<br>
     *        bitmap : <br>
     *                 00001111 00001111 00001111 00001111B</li>
     *        entry/group : 2
     *    </ul>
     * </ul>
     *
     * <p>expected result</p>
     * <ul>
     * <li>pointers in record entries are updated</li>
     * <li>exceptions : not thrown</li>
     * </ul>
     */
    void testGC0014();

    /**
     *  Verifies that the pointers in the stack frames of the VM are traced
     * at GC.
     *
     * <p>prerequisite</p>
     * <ul>
     * <li>stack frames : 1
     *    <ul>
     *    <li>records : 32<br>
     *        bitmap : <br>
     *                 11111111 11111111 11111111 11111111B</li>
     *        entry/group : 2
     *    </ul>
     * </ul>
     *
     * <p>expected result</p>
     * <ul>
     * <li>pointers in record entries are updated</li>
     * <li>exceptions : not thrown</li>
     * </ul>
     */
    void testGC0015();

    class Suite;

    ////////////////////////////////////////
  private:

    void testRecordCommon(Bitmap bitmap,
                          int recordGroupsCount,
                          int recordArgs);

};

class VirtualMachineTest0004::Suite
    : public TestSuite
{
    ////////////////////////////////////////
  public:
    Suite();
};

///////////////////////////////////////////////////////////////////////////////

}
