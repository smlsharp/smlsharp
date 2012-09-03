// VirtualMachineTest0002
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
 *  Verifies that the rootset that the VM holds is updated when the GC occurs.
 *
 * <p><b>purpose of this test:</b></p>
 * <p>
 *  Verifies that, when executing a code block which requires so much heap
 * blocks that let the heap manager invoke garbage collection, the VM tells
 * the pointers in its rootset to the heap manager and not tells non-pointers.
 *  The rootset of the VM is constituted from
 * <ul>
 * <li>ENV register, if it holds non-NULL pointer.</li>
 * <li>non-NULL pointers in boxed global table</li>
 * <li><ul>
 *     <li>the pointer entries</li>
 *     <li>the record entries whose bit in the bitmap is set</li>
 *     </ul> in every stack frames.</li>
 * </ul>
 * Among them, this test suite verifies that ENV register and boxed globals
 * are traced.
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
 * <th>ENV</th>
 * <th>boxed globals</th>
 * <th>comment</th>
 * </tr>
 *
 * <tr>
 * <th>0001</th>
 * <td>NULL</td>
 * <td>none</td>
 * <td>&nbsp;</td>
 * </tr>
 *
 * <tr>
 * <th>0002</th>
 * <td>a pointer to block</td>
 * <td>some elements</td>
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
 * <li>Builds execution monitors and Attaches them to the VM. </li>
 * <li>Makes a code block which requires so much heap allocation that
 *    invokes garbage collection in the heap manager.</li>
 * <li>Calls the <code>execute</code> method on the VM with the code block
 *    as a parameter.</li>
 * <li>Checks the machine state saved in the monitors and 
 *   verifies that pointers contained in the rootset are updated and point
 *   to valid heap blocks.</li>
 * </ol>
 */
class VirtualMachineTest0002
    : public TestCase
{
    ////////////////////////////////////////
  private:

    ////////////////////////////////////////

  public:
    VirtualMachineTest0002(string name)
        : TestCase(name)
    {
    }

    virtual void setUp();

    virtual void tearDown();

    ////////////////////////////////////////
  public:

    /**
     *  Verifies that the rootset that the VM holds is updated when the GC
     * occurs.
     *
     * <p>
     *  Lets the VM execute a code block which requires so much heap
     * allocation that invokes garbage collection in the heap manager.
     * </p>
     *
     * <p>prerequisite</p>
     * <ul>
     * <li>ENV : holds a null pointer</li>
     * <li>boxed globals : None</li>
     * </ul>
     *
     * <p>expected result</p>
     * <ul>
     * <li></li>
     * <li>exceptions : not thrown</li>
     * </ul>
     */
    void testGC0001();

    /**
     *  Verifies that the rootset that the VM holds is updated when the GC
     * occurs.
     *
     * <p>
     *  Lets the VM execute a code block which requires so much heap
     * allocation that invokes garbage collection in the heap manager.
     * </p>
     *
     * <p>prerequisite</p>
     * <ul>
     * <li>ENV : holds a pointer to a block</li>
     * <li>boxed globals : 3 elements whose indexes are not continuous.</li>
     * </ul>
     *
     * <p>expected result</p>
     * <ul>
     * <li>ENV is updated.</li>
     * <li>boxed globals are updated.</li>
     * <li>exceptions : not thrown</li>
     * </ul>
     */
    void testGC0002();

    class Suite;
};

class VirtualMachineTest0002::Suite
    : public TestSuite
{
    ////////////////////////////////////////
  public:
    Suite();
};

///////////////////////////////////////////////////////////////////////////////

}
