// VirtualMachineTest0007
// jp_ac_jaist_iml_runtime

#include "Heap.hh"
#include "Heap.hh"

#include "TestCase.h"
#include "TestSuite.h"

namespace jp_ac_jaist_iml_runtime
{

using std::string;

///////////////////////////////////////////////////////////////////////////////

/**
 * Tests of execute method of VirtualMachine
 *
 * <p><b>purpose of this test:</b></p>
 * <p>
 *  verifies that the pointer and atom arguments passed to a function are
 * stored in correct slots of the callee's frame.
 * </p>
 *
 * <p><b>the variety of parameter</b></p>
 *
 * <ul>
 *   <li>the function calling instruction
 *     <ul>
 *       <li>Apply</li>
 *       <li>TailApply</li>
 *       <li>CallStatic</li>
 *       <li>TailCallStatic</li>
 *     </ul>
 *   </li>
 *   <li>the number of pointer arguments
 *     <ul>
 *       <li>1</li>
 *       <li>2</li>
 *     </ul>
 *   </li>
 *   <li>the number of atom arguments
 *     <ul>
 *       <li>1</li>
 *       <li>2</li>
 *     </ul>
 *   </li>
 * </ul>
 *
 * <p><b>supplementary comments:</b></p>
 *
 * <p><b>test cases:</b></p>
 *
 * <table border="1">
 * <caption>Test cases matrix</caption>
 * <tr>
 * <th>Case Index</th>
 * <th>instruction</th>
 * <th>pointer arguments</th>
 * <th>atom arguments</th>
 * <th>comment</th>
 * </tr>
 *
 * <tr><td>011Apply</td><td>Apply</td><td rowspan=4>1</td><td rowspan=4>1</td><td>&nbsp;</td></tr>
 * <tr><td>011TailApply</td><td>TailApply</td><td>&nbsp;</td></tr>
 * <tr><td>011CallStatic</td><td>TailApply</td><td>&nbsp;</td></tr>
 * <tr><td>011TailCallStatic</td><td>TailApply</td><td>&nbsp;</td></tr>
 * <tr><td>022Apply</td><td>Apply</td><td rowspan=4>2</td><td rowspan=4>2</td><td>&nbsp;</td></tr>
 * <tr><td>022TailApply</td><td>TailApply</td><td>&nbsp;</td></tr>
 * <tr><td>022CallStatic</td><td>TailApply</td><td>&nbsp;</td></tr>
 * <tr><td>022TailCallStatic</td><td>TailApply</td><td>&nbsp;</td></tr>
 *
 * </table>
 *
 */
class VirtualMachineTest0007
    : public TestCase
{
    ////////////////////////////////////////
  private:

    ////////////////////////////////////////
  public:
    VirtualMachineTest0007(string name)
        : TestCase(name)
    {
    }

    virtual void setUp();

    virtual void tearDown();

    ////////////////////////////////////////
  public:

    /**
     * tests arguments passed by the <code>Apply</code> instruction.
     *
     * <p>prerequisite</p>
     * <ul>
     * <li>instruction: Apply</li>
     * <li>pointer arguments: 1</li>
     * <li>atom arguments: 1</li>
     * <li>GC : not occurrs</li>
     * </ul>
     *
     * <p>expected result</p>
     * <ul>
     * <li>the function body is executed.</li>
     * <li>exceptions : not thrown</li>
     * </ul>
     */
    void testFunEntry011Apply();

    /**
     * tests arguments passed by the <code>TailApply</code> instruction.
     *
     * <p>prerequisite</p>
     * <ul>
     * <li>instruction: TailApply</li>
     * <li>pointer arguments: 1</li>
     * <li>atom arguments: 1</li>
     * <li>GC : not occurrs</li>
     * </ul>
     *
     * <p>expected result</p>
     * <ul>
     * <li>the function body is executed.</li>
     * <li>exceptions : not thrown</li>
     * </ul>
     */
    void testFunEntry011TailApply();

    /**
     * tests arguments passed by the <code>CallStatic</code> instruction.
     *
     * <p>prerequisite</p>
     * <ul>
     * <li>instruction: CallStatic</li>
     * <li>pointer arguments: 1</li>
     * <li>atom arguments: 1</li>
     * <li>GC : not occurrs</li>
     * </ul>
     *
     * <p>expected result</p>
     * <ul>
     * <li>the function body is executed.</li>
     * <li>exceptions : not thrown</li>
     * </ul>
     */
    void testFunEntry011CallStatic();

    /**
     * tests arguments passed by the <code>TailCallStatic</code> instruction.
     *
     * <p>prerequisite</p>
     * <ul>
     * <li>instruction: TailCallStatic</li>
     * <li>pointer arguments: 1</li>
     * <li>atom arguments: 1</li>
     * <li>GC : not occurrs</li>
     * </ul>
     *
     * <p>expected result</p>
     * <ul>
     * <li>the function body is executed.</li>
     * <li>exceptions : not thrown</li>
     * </ul>
     */
    void testFunEntry011TailCallStatic();

    /**
     * tests arguments passed by the <code>Apply</code> instruction.
     *
     * <p>prerequisite</p>
     * <ul>
     * <li>instruction: Apply</li>
     * <li>pointer arguments: 2</li>
     * <li>atom arguments: 2</li>
     * <li>GC : not occurrs</li>
     * </ul>
     *
     * <p>expected result</p>
     * <ul>
     * <li>the function body is executed.</li>
     * <li>exceptions : not thrown</li>
     * </ul>
     */
    void testFunEntry022Apply();

    /**
     * tests arguments passed by the <code>TailApply</code> instruction.
     *
     * <p>prerequisite</p>
     * <ul>
     * <li>instruction: TailApply</li>
     * <li>pointer arguments: 2</li>
     * <li>atom arguments: 2</li>
     * <li>GC : not occurrs</li>
     * </ul>
     *
     * <p>expected result</p>
     * <ul>
     * <li>the function body is executed.</li>
     * <li>exceptions : not thrown</li>
     * </ul>
     */
    void testFunEntry022TailApply();

    /**
     * tests arguments passed by the <code>CallStatic</code> instruction.
     *
     * <p>prerequisite</p>
     * <ul>
     * <li>instruction: CallStatic</li>
     * <li>pointer arguments: 2</li>
     * <li>atom arguments: 2</li>
     * <li>GC : not occurrs</li>
     * </ul>
     *
     * <p>expected result</p>
     * <ul>
     * <li>the function body is executed.</li>
     * <li>exceptions : not thrown</li>
     * </ul>
     */
    void testFunEntry022CallStatic();

    /**
     * tests arguments passed by the <code>TailCallStatic</code> instruction.
     *
     * <p>prerequisite</p>
     * <ul>
     * <li>instruction: TailCallStatic</li>
     * <li>pointer arguments: 2</li>
     * <li>atom arguments: 2</li>
     * <li>GC : not occurrs</li>
     * </ul>
     *
     * <p>expected result</p>
     * <ul>
     * <li>the function body is executed.</li>
     * <li>exceptions : not thrown</li>
     * </ul>
     */
    void testFunEntry022TailCallStatic();

    class Suite;

  private:

    void testApplyCommon(bool isTailCall,
                         int pointerArgs,
                         UInt32Value* pointerArgValues,
                         int atomArgs,
                         UInt32Value* atomArgValues);

    void testCallStaticCommon(bool isTailCall,
                              int pointerArgs,
                              UInt32Value* pointerArgValues,
                              int atomArgs,
                              UInt32Value* atomArgValues);

};

class VirtualMachineTest0007::Suite
    : public TestSuite
{
    ////////////////////////////////////////
  public:
    Suite();
};

///////////////////////////////////////////////////////////////////////////////

}
