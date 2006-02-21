// VirtualMachineTest0008
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
 *  verifies that the bitmap of a frame is build correctly from atom arguments
 * and free variables in environment block passed to a function.
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
 *       <li>1, for environment block</li>
 *     </ul>
 *   </li>
 *   <li>the number of atom arguments used to construct the bitmap
 *     <ul>
 *       <li>1</li>
 *       <li>2</li>
 *     </ul>
 *   </li>
 *   <li>the number of variables in environment used to construct the bitmap
 *     <ul>
 *       <li>1</li>
 *     </ul>
 *   </li>
 *   <li>the number of record arguments per each record group
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
 * <th>arguments for bitmap</th>
 * <th>free variables for bitmap</th>
 * <th>record arguments of a group</th>
 * <th>comment</th>
 * </tr>
 *
 * <tr><td>0111Apply</td><td>Apply</td><td rowspan=4>1</td><td rowspan=4>1</td><td rowspan=4>1</td><td>&nbsp;</td></tr>
 * <tr><td>0111TailApply</td><td>TailApply</td><td>&nbsp;</td></tr>
 * <tr><td>0111CallStatic</td><td>TailApply</td><td>&nbsp;</td></tr>
 * <tr><td>0111TailCallStatic</td><td>TailApply</td><td>&nbsp;</td></tr>
 * <tr><td>0212Apply</td><td>Apply</td><td rowspan=4>2</td><td rowspan=4>1</td><td rowspan=4>2</td><td>&nbsp;</td></tr>
 * <tr><td>0212TailApply</td><td>TailApply</td><td>&nbsp;</td></tr>
 * <tr><td>0212CallStatic</td><td>TailApply</td><td>&nbsp;</td></tr>
 * <tr><td>0212TailCallStatic</td><td>TailApply</td><td>&nbsp;</td></tr>
 *
 * </table>
 *
 */
class VirtualMachineTest0008
    : public TestCase
{
    ////////////////////////////////////////
  private:

    ////////////////////////////////////////
  public:
    VirtualMachineTest0008(string name)
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
    void testFunEntry0111Apply();

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
    void testFunEntry0111TailApply();

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
    void testFunEntry0111CallStatic();

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
    void testFunEntry0111TailCallStatic();

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
    void testFunEntry0212Apply();

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
    void testFunEntry0212TailApply();

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
    void testFunEntry0212CallStatic();

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
    void testFunEntry0212TailCallStatic();

    class Suite;

  private:

    void testApplyCommon(bool isTailCall,
                         int atomArgs,
                         int freeVars,
                         int recordArgs,
                         UInt32Value* recordArgValues);

    void testCallStaticCommon(bool isTailCall,
                              int atomArgs,
                              int freeVars,
                              int recordArgs,
                              UInt32Value* recordArgValues);

};

class VirtualMachineTest0008::Suite
    : public TestSuite
{
    ////////////////////////////////////////
  public:
    Suite();
};

///////////////////////////////////////////////////////////////////////////////

}
