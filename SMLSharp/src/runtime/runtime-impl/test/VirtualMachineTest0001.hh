// VirtualMachineTest0001
// jp_ac_jaist_iml_runtime

/**
 * @author YAMATODANI Kiyoshi
 * @version $Id: VirtualMachineTest0001.hh,v 1.1 2005/09/29 16:45:13 kiyoshiy Exp $
 */
#include "Heap.hh"
#include "Heap.hh"
#include "VirtualMachine.hh"
#include "Primitives.hh"
#include "Instructions.hh"

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
 *  Lets the VM execute each VM instruction and verifies that the machine
 * state changes as the specification.
 * </p>
 * <p>
 *  The following instructions are tested in other test cases:
 *  <code>FunEntry, Raise, PushHandler, PopHandler</code>
 * </p>
 *
 * <p><b>the variety of instruction</b></p>
 *
 * <p>
 *  This test class targets every instruction in the IML VM instruction set.
 * </p>
 *
 * <p><b>supplementary comments:</b></p>
 *
 * <p><b>test cases:</b></p>
 *
 * <table border="1">
 * <caption>Test cases matrix</caption>
 * <tr>
 * <th>Target Instruction</th>
 * <th>Case Index</th>
 * <th>Variation</th>
 * <th>comment</th>
 * </tr>
 *
 * <tr><td rowspan=2>LoadInt</td><td>0001</td><td>positive number</td><td>&nbsp;</td></tr>
 * <tr><td>0002</td><td>negative number</td><td>&nbsp;</td></tr>
 * <tr><td rowspan=1>LoadWord</td><td>0001</td><td>-</td><td>&nbsp;</td></tr>
 * <tr><td rowspan=1>LoadString</td><td>0001</td><td>-</td><td>&nbsp;</td></tr>
 * <tr><td rowspan=1>LoadReal</td><td>0001</td><td>-</td><td>&nbsp;</td></tr>
 * <tr><td rowspan=1>LoadBoxedReal</td><td>0001</td><td>-</td><td>&nbsp;</td></tr>
 * <tr><td rowspan=1>LoadChar</td><td>0001</td><td>-</td><td>&nbsp;</td></tr>
 * <tr><td rowspan=1>Access</td><td>0001</td><td>-</td><td>&nbsp;</td></tr>
 * <tr><td rowspan=1>AccessEnv</td><td>0001</td><td>-</td><td>&nbsp;</td></tr>
 * <tr><td rowspan=1>AccessEnvIndirect</td><td>0001</td><td>-</td><td>&nbsp;</td></tr>
 * <tr><td rowspan=1>GetField</td><td>0001</td><td>-</td><td>&nbsp;</td></tr>
 * <tr><td rowspan=1>GetFieldIndirect</td><td>0001</td><td>-</td><td>&nbsp;</td></tr>
 * <tr><td rowspan=1>SetField</td><td>0001</td><td>-</td><td>&nbsp;</td></tr>
 * <tr><td rowspan=1>SetFieldIndirect</td><td>0001</td><td>-</td><td>&nbsp;</td></tr>
 * <tr><td rowspan=1>CopyBlock</td><td>0001</td><td>-</td><td>&nbsp;</td></tr>
 * <tr><td rowspan=1>GetGlobalBoxed</td><td>0001</td><td>-</td><td>&nbsp;</td></tr>
 * <tr><td rowspan=1>SetGlobalBoxed</td><td>0001</td><td>-</td><td>&nbsp;</td></tr>
 * <tr><td rowspan=1>GetGlobalUnboxed</td><td>0001</td><td>-</td><td>&nbsp;</td></tr>
 * <tr><td rowspan=1>SetGlobalUnboxed</td><td>0001</td><td>-</td><td>&nbsp;</td></tr>
 * <tr><td rowspan=1>GetEnv</td><td>0001</td><td>-</td><td>&nbsp;</td></tr>
 * <tr><td rowspan=1>CallPrim</td><td>0001</td><td>-</td><td>not implemented</td></tr>
 * <tr><td rowspan=1>Apply</td><td>0001</td><td>-</td><td>&nbsp;</td></tr>
 * <tr><td rowspan=1>TailApply</td><td>0001</td><td>-</td><td>&nbsp;</td></tr>
 * <tr><td rowspan=1>CallStatic</td><td>0001</td><td>-</td><td>&nbsp;</td></tr>
 * <tr><td rowspan=1>TailCallStatic</td><td>0001</td><td>-</td><td>&nbsp;</td></tr>
 * <tr><td rowspan=1>MakeBlock</td><td>0001</td><td>-</td><td>&nbsp;</td></tr>
 * <tr><td rowspan=1>MakeBlockOfSingleValues</td><td>0001</td><td>-</td><td>&nbsp;</td></tr>
 * <tr><td rowspan=1>MakeArray</td><td>0001</td><td>-</td><td>&nbsp;</td></tr>
 * <tr><td rowspan=1>MakeClosure</td><td>0001</td><td>-</td><td>&nbsp;</td></tr>
 * <tr><td rowspan=1>Raise</td><td>-</td><td>-</td><td>see Test0008</td></tr>
 * <tr><td rowspan=1>PushHandler</td><td>-</td><td>-</td><td>see Test0008</td></tr>
 * <tr><td rowspan=1>PopHandler</td><td>-</td><td>-</td><td>see Test0008</td></tr>
 * <tr><td rowspan=2>SwitchInt</td><td>0001</td><td>a case matches</td><td>&nbsp;</td></tr>
 * <tr><td>0002</td><td>no case matches</td><td>&nbsp;</td></tr>
 * <tr><td rowspan=2>SwitchWord</td><td>0001</td><td>a case matches</td><td>&nbsp;</td></tr>
 * <tr><td>0002</td><td>no case matches</td><td>&nbsp;</td></tr>
 * <tr><td rowspan=2>SwitchChar</td><td>0001</td><td>a case matches</td><td>&nbsp;</td></tr>
 * <tr><td>0002</td><td>no case matches</td><td>&nbsp;</td></tr>
 * <tr><td rowspan=2>SwitchString</td><td>0001</td><td>a case matches</td><td>&nbsp;</td></tr>
 * <tr><td>0002</td><td>no case matches</td><td>&nbsp;</td></tr>
 * <tr><td rowspan=1>Jump</td><td>0001</td><td>-</td><td>&nbsp;</td></tr>
 * <tr><td rowspan=1>Exit</td><td>0001</td><td>-</td><td>&nbsp;</td></tr>
 * <tr><td rowspan=1>Return</td><td>0001</td><td>-</td><td>&nbsp;</td></tr>
 * <tr><td rowspan=1>Nop</td><td>0001</td><td>-</td><td>&nbsp;</td></tr>
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
 * <li>Makes a code block which contains the instruction which is the target
 *    of the test case.</li>
 * <li>Calls the <code>execute</code> method on the VM with the code block
 *    as a parameter.</li>
 * <li>Checks the machine registers saved in the monitors and 
 *   verifies that the state transition of the VM conforms to the
 *   specification.</li>
 * </ol>
 */
class VirtualMachineTest0001
    : public TestCase
{
    ////////////////////////////////////////
  private:

    ////////////////////////////////////////
  public:
    VirtualMachineTest0001(string name)
        : TestCase(name)
    {
    }

    virtual void setUp();

    virtual void tearDown();

    ////////////////////////////////////////
  public:

    /**
     * tests the <code>LoadInt</code> instruction
     *
     * <p>
     *  Lets the VM execute a code block which contains a 'LoadInt'
     * instruction.
     * </p>
     *
     * <p>prerequisite</p>
     * <ul>
     * <li>loaded costant : positve number</li>
     * <li>GC : not occurrs</li>
     * </ul>
     *
     * <p>expected result</p>
     * <ul>
     * <li></li>
     * <li>exceptions : not thrown</li>
     * </ul>
     */
    void testLoadInt0001();

    /**
     * tests the <code>LoadInt</code> instruction
     *
     * <p>
     *  Lets the VM execute a code block which contains a 'LoadInt'
     * instruction.
     * </p>
     *
     * <p>prerequisite</p>
     * <ul>
     * <li>loaded costant : negative number</li>
     * <li>GC : not occurrs</li>
     * </ul>
     *
     * <p>expected result</p>
     * <ul>
     * <li></li>
     * <li>exceptions : not thrown</li>
     * </ul>
     */
    void testLoadInt0002();

    /**
     * tests the <code>LoadWord</code> instruction
     *
     * <p>
     *  Lets the VM execute a code block which contains a 'LoadWord'
     * instruction.
     * </p>
     *
     * <p>prerequisite</p>
     * <ul>
     * <li>GC : not occurrs</li>
     * </ul>
     *
     * <p>expected result</p>
     * <ul>
     * <li></li>
     * <li>exceptions : not thrown</li>
     * </ul>
     */
    void testLoadWord0001();

    /**
     * tests the <code>LoadString</code> instruction
     *
     * <p>
     *  Lets the VM execute a code block which contains a 'LoadString'
     * instruction.
     * </p>
     *
     * <p>prerequisite</p>
     * <ul>
     * <li>GC : not occurrs</li>
     * </ul>
     *
     * <p>expected result</p>
     * <ul>
     * <li></li>
     * <li>exceptions : not thrown</li>
     * </ul>
     */
    void testLoadString0001();

    /**
     * tests the <code>LoadReal</code> instruction
     *
     * <p>
     *  Lets the VM execute a code block which contains a 'LoadReal'
     * instruction.
     * </p>
     *
     * <p>prerequisite</p>
     * <ul>
     * <li>GC : not occurrs</li>
     * </ul>
     *
     * <p>expected result</p>
     * <ul>
     * <li></li>
     * <li>exceptions : not thrown</li>
     * </ul>
     */
    void testLoadReal0001();

    /**
     * tests the <code>LoadBoxedReal</code> instruction
     *
     * <p>
     *  Lets the VM execute a code block which contains a 'LoadBoxedReal'
     * instruction.
     * </p>
     *
     * <p>prerequisite</p>
     * <ul>
     * <li>GC : not occurrs</li>
     * </ul>
     *
     * <p>expected result</p>
     * <ul>
     * <li></li>
     * <li>exceptions : not thrown</li>
     * </ul>
     */
    void testLoadBoxedReal0001();

    /**
     * tests the <code>LoadChar</code> instruction
     *
     * <p>
     *  Lets the VM execute a code block which contains a 'LoadChar'
     * instruction.
     * </p>
     *
     * <p>prerequisite</p>
     * <ul>
     * <li>GC : not occurrs</li>
     * </ul>
     *
     * <p>expected result</p>
     * <ul>
     * <li></li>
     * <li>exceptions : not thrown</li>
     * </ul>
     */
    void testLoadChar0001();

    /**
     * tests the <code>Access</code> instruction
     *
     * <p>
     *  Lets the VM execute a code block which contains a 'Access'
     * instruction.
     * </p>
     *
     * <p>prerequisite</p>
     * <ul>
     * <li></li>
     * <li>GC : not occurrs</li>
     * </ul>
     *
     * <p>expected result</p>
     * <ul>
     * <li></li>
     * <li>exceptions : not thrown</li>
     * </ul>
     */
    void testAccess0001();

    /**
     * tests the <code>AccessEnv</code> instruction
     *
     * <p>
     *  Lets the VM execute a code block which contains a 'AccessEnv'
     * instruction.
     * </p>
     *
     * <p>prerequisite</p>
     * <ul>
     * <li></li>
     * <li>GC : not occurrs</li>
     * </ul>
     *
     * <p>expected result</p>
     * <ul>
     * <li></li>
     * <li>exceptions : not thrown</li>
     * </ul>
     */
    void testAccessEnv0001();

    /**
     * tests the <code>AccessEnvIndirect</code> instruction
     *
     * <p>
     *  Lets the VM execute a code block which contains a 'AccessEnvIndirect'
     * instruction.
     * </p>
     *
     * <p>prerequisite</p>
     * <ul>
     * <li></li>
     * <li>GC : not occurrs</li>
     * </ul>
     *
     * <p>expected result</p>
     * <ul>
     * <li></li>
     * <li>exceptions : not thrown</li>
     * </ul>
     */
    void testAccessEnvIndirect0001();

    /**
     * tests the <code>GetField</code> instruction
     *
     * <p>
     *  Lets the VM execute a code block which contains a 'GetField'
     * instruction.
     * </p>
     *
     * <p>prerequisite</p>
     * <ul>
     * <li>GC : not occurrs</li>
     * </ul>
     *
     * <p>expected result</p>
     * <ul>
     * <li></li>
     * <li>exceptions : not thrown</li>
     * </ul>
     */
    void testGetField0001();

    /**
     * tests the <code>GetFieldIndirect</code> instruction
     *
     * <p>
     *  Lets the VM execute a code block which contains a 'GetFieldIndirect'
     * instruction.
     * </p>
     *
     * <p>prerequisite</p>
     * <ul>
     * <li>GC : not occurrs</li>
     * </ul>
     *
     * <p>expected result</p>
     * <ul>
     * <li></li>
     * <li>exceptions : not thrown</li>
     * </ul>
     */
    void testGetFieldIndirect0001();

    /**
     * tests the <code>SetField</code> instruction
     *
     * <p>
     *  Lets the VM execute a code block which contains a 'SetField'
     * instruction.
     * </p>
     *
     * <p>prerequisite</p>
     * <ul>
     * <li>GC : not occurrs</li>
     * </ul>
     *
     * <p>expected result</p>
     * <ul>
     * <li></li>
     * <li>exceptions : not thrown</li>
     * </ul>
     */
    void testSetField0001();

    /**
     * tests the <code>SetFieldIndirect</code> instruction
     *
     * <p>
     *  Lets the VM execute a code block which contains a 'SetFieldIndirect'
     * instruction.
     * </p>
     *
     * <p>prerequisite</p>
     * <ul>
     * <li>GC : not occurrs</li>
     * </ul>
     *
     * <p>expected result</p>
     * <ul>
     * <li></li>
     * <li>exceptions : not thrown</li>
     * </ul>
     */
    void testSetFieldIndirect0001();

    /**
     * tests the <code>CopyBlock</code> instruction
     *
     * <p>
     *  Lets the VM execute a code block which contains a 'CopyBlock'
     * instruction.
     * </p>
     *
     * <p>prerequisite</p>
     * <ul>
     * <li>GC : not occurrs</li>
     * </ul>
     *
     * <p>expected result</p>
     * <ul>
     * <li></li>
     * <li>exceptions : not thrown</li>
     * </ul>
     */
    void testCopyBlock0001();

    /**
     * tests the <code>GetGlobalBoxed</code> instruction
     *
     * <p>
     *  Lets the VM execute a code block which contains a 'GetGlobalBoxed'
     * instruction.
     * </p>
     *
     * <p>prerequisite</p>
     * <ul>
     * <li>GC : not occurrs</li>
     * </ul>
     *
     * <p>expected result</p>
     * <ul>
     * <li></li>
     * <li>exceptions : not thrown</li>
     * </ul>
     */
    void testGetGlobalBoxed0001();

    /**
     * tests the <code>SetGlobalBoxed</code> instruction
     *
     * <p>
     *  Lets the VM execute a code block which contains a 'SetGlobalBoxed'
     * instruction.
     * </p>
     *
     * <p>prerequisite</p>
     * <ul>
     * <li>GC : not occurrs</li>
     * </ul>
     *
     * <p>expected result</p>
     * <ul>
     * <li></li>
     * <li>exceptions : not thrown</li>
     * </ul>
     */
    void testSetGlobalBoxed0001();

    /**
     * tests the <code>GetGlobalUnboxed</code> instruction
     *
     * <p>
     *  Lets the VM execute a code block which contains a 'GetGlobalUnboxed'
     * instruction.
     * </p>
     *
     * <p>prerequisite</p>
     * <ul>
     * <li>GC : not occurrs</li>
     * </ul>
     *
     * <p>expected result</p>
     * <ul>
     * <li></li>
     * <li>exceptions : not thrown</li>
     * </ul>
     */
    void testGetGlobalUnboxed0001();

    /**
     * tests the <code>SetGlobalUnboxed</code> instruction
     *
     * <p>
     *  Lets the VM execute a code block which contains a 'SetGlobalUnboxed'
     * instruction.
     * </p>
     *
     * <p>prerequisite</p>
     * <ul>
     * <li>GC : not occurrs</li>
     * </ul>
     *
     * <p>expected result</p>
     * <ul>
     * <li></li>
     * <li>exceptions : not thrown</li>
     * </ul>
     */
    void testSetGlobalUnboxed0001();

    /**
     * tests the <code>GetEnv</code> instruction
     *
     * <p>
     *  Lets the VM execute a code block which contains a 'GetEnv'
     * instruction.
     * </p>
     *
     * <p>prerequisite</p>
     * <ul>
     * <li>GC : not occurrs</li>
     * </ul>
     *
     * <p>expected result</p>
     * <ul>
     * <li></li>
     * <li>exceptions : not thrown</li>
     * </ul>
     */
    void testGetEnv0001();

    /**
     * tests the <code>CallPrim</code> instruction
     *
     * <p>
     *  Lets the VM execute a code block which contains a 'CallPrim'
     * instruction.
     * </p>
     *
     * <p>prerequisite</p>
     * <ul>
     * <li>GC : not occurrs</li>
     * </ul>
     *
     * <p>expected result</p>
     * <ul>
     * <li></li>
     * <li>exceptions : not thrown</li>
     * </ul>
     */
    void testCallPrim0001();

    /**
     * tests the <code>Apply</code> instruction
     *
     * <p>
     *  Lets the VM execute a code block which contains a 'Apply'
     * instruction.
     * </p>
     *
     * <p>prerequisite</p>
     * <ul>
     * <li>GC : not occurrs</li>
     * </ul>
     *
     * <p>expected result</p>
     * <ul>
     * <li></li>
     * <li>exceptions : not thrown</li>
     * </ul>
     */
    void testApply0001();

    /**
     * tests the <code>TailApply</code> instruction
     *
     * <p>
     *  Lets the VM execute a code block which contains a 'TailApply'
     * instruction.
     * </p>
     *
     * <p>prerequisite</p>
     * <ul>
     * <li>GC : not occurrs</li>
     * </ul>
     *
     * <p>expected result</p>
     * <ul>
     * <li></li>
     * <li>exceptions : not thrown</li>
     * </ul>
     */
    void testTailApply0001();

    /**
     * tests the <code>CallStatic</code> instruction
     *
     * <p>
     *  Lets the VM execute a code block which contains a 'CallStatic'
     * instruction.
     * </p>
     *
     * <p>prerequisite</p>
     * <ul>
     * <li>GC : not occurrs</li>
     * </ul>
     *
     * <p>expected result</p>
     * <ul>
     * <li></li>
     * <li>exceptions : not thrown</li>
     * </ul>
     */
    void testCallStatic0001();

    /**
     * tests the <code>TailCallStatic</code> instruction
     *
     * <p>
     *  Lets the VM execute a code block which contains a 'TailCallStatic'
     * instruction.
     * </p>
     *
     * <p>prerequisite</p>
     * <ul>
     * <li>GC : not occurrs</li>
     * </ul>
     *
     * <p>expected result</p>
     * <ul>
     * <li></li>
     * <li>exceptions : not thrown</li>
     * </ul>
     */
    void testTailCallStatic0001();

    /**
     * tests the <code>MakeBlock</code> instruction
     *
     * <p>
     *  Lets the VM execute a code block which contains a 'MakeBlock'
     * instruction.
     * </p>
     *
     * <p>prerequisite</p>
     * <ul>
     * <li>GC : not occurrs</li>
     * </ul>
     *
     * <p>expected result</p>
     * <ul>
     * <li></li>
     * <li>exceptions : not thrown</li>
     * </ul>
     */
    void testMakeBlock0001();

    /**
     * tests the <code>MakeBlockOfSingleValues</code> instruction
     *
     * <p>
     *  Lets the VM execute a code block which contains a
     * 'MakeBlockOfSingleValues' instruction.
     * </p>
     *
     * <p>prerequisite</p>
     * <ul>
     * <li>GC : not occurrs</li>
     * </ul>
     *
     * <p>expected result</p>
     * <ul>
     * <li></li>
     * <li>exceptions : not thrown</li>
     * </ul>
     */
    void testMakeBlockOfSingleValues0001();

    /**
     * tests the <code>MakeArray</code> instruction
     *
     * <p>
     *  Lets the VM execute a code block which contains a 'MakeArray'
     * instruction.
     * </p>
     *
     * <p>prerequisite</p>
     * <ul>
     * <li>GC : not occurrs</li>
     * </ul>
     *
     * <p>expected result</p>
     * <ul>
     * <li></li>
     * <li>exceptions : not thrown</li>
     * </ul>
     */
    void testMakeArray0001();

    /**
     * tests the <code>MakeClosure</code> instruction
     *
     * <p>
     *  Lets the VM execute a code block which contains a 'MakeClosure'
     * instruction.
     * </p>
     *
     * <p>prerequisite</p>
     * <ul>
     * <li>GC : not occurrs</li>
     * </ul>
     *
     * <p>expected result</p>
     * <ul>
     * <li></li>
     * <li>exceptions : not thrown</li>
     * </ul>
     */
    void testMakeClosure0001();

    /**
     * tests the <code>SwitchInt</code> instruction
     *
     * <p>
     *  Lets the VM execute a code block which contains a 'SwitchInt'
     * instruction.
     * </p>
     *
     * <p>prerequisite</p>
     * <ul>
     * <li></li>
     * <li>GC : not occurrs</li>
     * </ul>
     *
     * <p>expected result</p>
     * <ul>
     * <li></li>
     * <li>exceptions : not thrown</li>
     * </ul>
     */
    void testSwitchInt0001();

    /**
     * tests the <code>SwitchInt</code> instruction
     *
     * <p>
     *  Lets the VM execute a code block which contains a 'SwitchInt'
     * instruction.
     * </p>
     *
     * <p>prerequisite</p>
     * <ul>
     * <li></li>
     * <li>GC : not occurrs</li>
     * </ul>
     *
     * <p>expected result</p>
     * <ul>
     * <li></li>
     * <li>exceptions : not thrown</li>
     * </ul>
     */
    void testSwitchInt0002();

    /**
     * tests the <code>SwitchWord</code> instruction
     *
     * <p>
     *  Lets the VM execute a code block which contains a 'SwitchWord'
     * instruction.
     * </p>
     *
     * <p>prerequisite</p>
     * <ul>
     * <li></li>
     * <li>GC : not occurrs</li>
     * </ul>
     *
     * <p>expected result</p>
     * <ul>
     * <li></li>
     * <li>exceptions : not thrown</li>
     * </ul>
     */
    void testSwitchWord0001();

    /**
     * tests the <code>SwitchWord</code> instruction
     *
     * <p>
     *  Lets the VM execute a code block which contains a 'SwitchWord'
     * instruction.
     * </p>
     *
     * <p>prerequisite</p>
     * <ul>
     * <li></li>
     * <li>GC : not occurrs</li>
     * </ul>
     *
     * <p>expected result</p>
     * <ul>
     * <li></li>
     * <li>exceptions : not thrown</li>
     * </ul>
     */
    void testSwitchWord0002();

    /**
     * tests the <code>SwitchChar</code> instruction
     *
     * <p>
     *  Lets the VM execute a code block which contains a 'SwitchChar'
     * instruction.
     * </p>
     *
     * <p>prerequisite</p>
     * <ul>
     * <li></li>
     * <li>GC : not occurrs</li>
     * </ul>
     *
     * <p>expected result</p>
     * <ul>
     * <li></li>
     * <li>exceptions : not thrown</li>
     * </ul>
     */
    void testSwitchChar0001();

    /**
     * tests the <code>SwitchChar</code> instruction
     *
     * <p>
     *  Lets the VM execute a code block which contains a 'SwitchChar'
     * instruction.
     * </p>
     *
     * <p>prerequisite</p>
     * <ul>
     * <li></li>
     * <li>GC : not occurrs</li>
     * </ul>
     *
     * <p>expected result</p>
     * <ul>
     * <li></li>
     * <li>exceptions : not thrown</li>
     * </ul>
     */
    void testSwitchChar0002();

    /**
     * tests the <code>SwitchString</code> instruction
     *
     * <p>
     *  Lets the VM execute a code block which contains a 'SwitchString'
     * instruction.
     * </p>
     *
     * <p>prerequisite</p>
     * <ul>
     * <li></li>
     * <li>GC : not occurrs</li>
     * </ul>
     *
     * <p>expected result</p>
     * <ul>
     * <li></li>
     * <li>exceptions : not thrown</li>
     * </ul>
     */
    void testSwitchString0001();

    /**
     * tests the <code>SwitchString</code> instruction
     *
     * <p>
     *  Lets the VM execute a code block which contains a 'SwitchString'
     * instruction.
     * </p>
     *
     * <p>prerequisite</p>
     * <ul>
     * <li></li>
     * <li>GC : not occurrs</li>
     * </ul>
     *
     * <p>expected result</p>
     * <ul>
     * <li></li>
     * <li>exceptions : not thrown</li>
     * </ul>
     */
    void testSwitchString0002();

    /**
     * tests the <code>Jump</code> instruction
     *
     * <p>
     *  Lets the VM execute a code block which contains a 'Jump'
     * instruction.
     * </p>
     *
     * <p>prerequisite</p>
     * <ul>
     * <li></li>
     * <li>GC : not occurrs</li>
     * </ul>
     *
     * <p>expected result</p>
     * <ul>
     * <li></li>
     * <li>exceptions : not thrown</li>
     * </ul>
     */
    void testJump0001();

    /**
     * tests the <code>Exit</code> instruction
     *
     * <p>
     *  Lets the VM execute a code block which contains a 'Exit'
     * instruction.
     * </p>
     *
     * <p>prerequisite</p>
     * <ul>
     * <li>GC : not occurrs</li>
     * </ul>
     *
     * <p>expected result</p>
     * <ul>
     * <li></li>
     * <li>exceptions : not thrown</li>
     * </ul>
     */
    void testExit0001();

    /**
     * tests the <code>Return</code> instruction
     *
     * <p>
     *  Lets the VM execute a code block which contains a 'Return'
     * instruction.
     * </p>
     *
     * <p>prerequisite</p>
     * <ul>
     * <li>GC : not occurrs</li>
     * </ul>
     *
     * <p>expected result</p>
     * <ul>
     * <li>exceptions : not thrown</li>
     * </ul>
     */
    void testReturn0001();

    /**
     * tests the <code>Nop</code> instruction
     *
     * <p>
     *  Lets the VM execute a code block which contains a 'Nop'
     * instruction.
     * </p>
     *
     * <p>prerequisite</p>
     * <ul>
     * <li>GC : not occurrs</li>
     * </ul>
     *
     * <p>expected result</p>
     * <ul>
     * <li></li>
     * <li>exceptions : not thrown</li>
     * </ul>
     */
    void testNop0001();

    class Suite;

    ////////////////////////////////////////
  private:

    void testApplyCommon0001(bool isTailCall);

    void testCallStaticCommon0001(bool isTailCall);

    /** implementation of test cases for switchXXX instructions on
     * atom type values (int, word, char).
     */
    void testSwitchAtom(const instruction switchInstruction,
                        const UInt32Value casesCount,
                        const UInt32Value* cases,
                        const UInt32Value targetValue);

    void testSwitchString(const UInt32Value casesCount,
                          const char* cases[],
                          const char* targetValue);

};

class VirtualMachineTest0001::Suite
    : public TestSuite
{
    ////////////////////////////////////////
  public:
    Suite();
};

///////////////////////////////////////////////////////////////////////////////

}
