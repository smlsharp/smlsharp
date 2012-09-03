#ifndef ExecutableLinkerTest0001_hh_
#define ExecutableLinkerTest0001_hh_

// ExecutableLinkerTest0001
// jp_ac_jaist_iml_runtime

#include "ExecutableLinker.hh"
#include "Instructions.hh"

#include "TestCase.h"
#include "TestSuite.h"

using std::string;

namespace jp_ac_jaist_iml_runtime
{

///////////////////////////////////////////////////////////////////////////////

/**
 * Tests of ExecutableLinker
 *
 * <p><b>supplementary comments:</b></p>
 *
 * <p><b>the number of test cases</b></p>
 *
 * <hr>
 *
 */
class ExecutableLinkerTest0001
    : public TestCase
{
    ///////////////////////////////////////////////////////////////////////////
  private:

    ///////////////////////////////////////////////////////////////////////////
  protected:

    /**
     * true if multi byte values in the code block passed to the
     * <code>process</code> method should be ordered in littel endian.
     */
    bool littleEndian_;

    ///////////////////////////////////////////////////////////////////////////
  public:

    ExecutableLinkerTest0001(string name, bool littleEndian)
        : TestCase(name),
          littleEndian_(littleEndian)
    {
    };

    virtual void setUp();

    virtual void tearDown();

    ///////////////////////////////////////////////////////////////////////////
  protected:

    UInt32Value
    pack1_1_2(UInt8Value first, UInt8Value second, UInt16Value third);

    UInt32Value pack1_3(UInt8Value first, UInt32Value second);

    UInt32Value pack4(UInt32Value value);

    Executable doLink(UInt32Value codeLength, UInt32Value code[]);

    void testLinkNoOperand0001(instruction opcode);
    void testLink1ConstOperand0001(instruction opcode);
    void testLink2ConstOperands0001(instruction opcode);
    void testLink3ConstOperands0001(instruction opcode);
    void testLink4ConstOperands0001(instruction opcode);
    void testLink5ConstOperands0001(instruction opcode);

    void testLinkLoadRealBase0001(instruction opcode);
    void testLinkApplyBase0001(instruction opcode);
    void testLinkTailApplyBase0001(instruction opcode);
    void testLinkCallStaticBase0001(instruction opcode);
    void testLinkTailCallStaticBase0001(instruction opcode);
    void testLinkReturnBase0001(instruction opcode);

    /** utility function for test cases for primitives of 1 arg.
     */
    void testLinkPrimitive10001(instruction opcode);

    /** utility function for test cases for primitives of 2 args.
     */
    void testLinkPrimitive20001(instruction opcode);

    /** utility function for test cases for switchXXX instructions,
     * except for SwitchString.
     */
    void testLinkSwitchAtom0001(instruction opcode);

    ///////////////////////////////////////////////////////////////////////////
  public:

    /**
     * ExecutableLinker#link test case
     *
     * <p>prerequisite</p>
     * <ul>
     *   <li></li>
     * </ul>
     *
     * <p>expected result</p>
     * <ul>
     * <li>exceptions : not thrown</li>
     * </ul>
     */
    void testLinkLoadInt0001();
    void testLinkLoadWord0001();
    void testLinkLoadString0001();
    void testLinkLoadReal0001();
    void testLinkLoadBoxedReal0001();
    void testLinkLoadChar0001();
    void testLinkAccess_S0001();
    void testLinkAccess_D0001();
    void testLinkAccess_V0001();
    void testLinkAccessEnv_S0001();
    void testLinkAccessEnv_D0001();
    void testLinkAccessEnv_V0001();
    void testLinkAccessEnvIndirect_S0001();
    void testLinkAccessEnvIndirect_D0001();
    void testLinkAccessEnvIndirect_V0001();
    void testLinkGetField_S0001();
    void testLinkGetField_D0001();
    void testLinkGetField_V0001();
    void testLinkGetFieldIndirect_S0001();
    void testLinkGetFieldIndirect_D0001();
    void testLinkGetFieldIndirect_V0001();
    void testLinkSetField_S0001();
    void testLinkSetField_D0001();
    void testLinkSetField_V0001();
    void testLinkSetFieldIndirect_S0001();
    void testLinkSetFieldIndirect_D0001();
    void testLinkSetFieldIndirect_V0001();
    void testLinkCopyBlock0001();
    void testLinkGetGlobalBoxed0001();
    void testLinkSetGlobalBoxed0001();
    void testLinkGetGlobalUnboxed0001();
    void testLinkSetGlobalUnboxed0001();
    void testLinkGetEnv0001();
    void testLinkCallPrim0001();
    void testLinkApply_S0001();
    void testLinkApply_D0001();
    void testLinkApply_V0001();
    void testLinkTailApply_S0001();
    void testLinkTailApply_D0001();
    void testLinkTailApply_V0001();
    void testLinkCallStatic_S0001();
    void testLinkCallStatic_D0001();
    void testLinkCallStatic_V0001();
    void testLinkTailCallStatic_S0001();
    void testLinkTailCallStatic_D0001();
    void testLinkTailCallStatic_V0001();
    void testLinkMakeBlock0001();
    void testLinkMakeArray_S0001();
    void testLinkMakeArray_D0001();
    void testLinkMakeArray_V0001();
    void testLinkMakeClosure0001();
    void testLinkRaise0001();
    void testLinkPushHandler0001();
    void testLinkPopHandler0001();
    void testLinkSwitchInt0001();
    void testLinkSwitchWord0001();
    void testLinkSwitchChar0001();
    void testLinkSwitchString0001();
    void testLinkJump0001();
    void testLinkExit0001();
    void testLinkReturn_S0001();
    void testLinkReturn_D0001();
    void testLinkReturn_V0001();

    void testLinkFunEntry0001();
    void testLinkConstString0001();
    void testLinkNop0001();

    void testLinkEqual0001();
    void testLinkAddInt0001();
    void testLinkAddReal0001();
    void testLinkAddWord0001();
    void testLinkSubInt0001();
    void testLinkSubReal0001();
    void testLinkSubWord0001();
    void testLinkMulInt0001();
    void testLinkMulReal0001();
    void testLinkMulWord0001();
    void testLinkDivInt0001();
    void testLinkDivWord0001();
    void testLinkDivReal0001();
    void testLinkModInt0001();
    void testLinkModWord0001();
    void testLinkQuotInt0001();
    void testLinkRemInt0001();
    void testLinkNegInt0001();
    void testLinkNegReal0001();
    void testLinkAbsInt0001();
    void testLinkAbsReal0001();
    void testLinkLtInt0001();
    void testLinkLtReal0001();
    void testLinkLtWord0001();
    void testLinkLtChar0001();
    void testLinkLtString0001();
    void testLinkGtInt0001();
    void testLinkGtReal0001();
    void testLinkGtWord0001();
    void testLinkGtChar0001();
    void testLinkGtString0001();
    void testLinkLteqInt0001();
    void testLinkLteqReal0001();
    void testLinkLteqWord0001();
    void testLinkLteqChar0001();
    void testLinkLteqString0001();
    void testLinkGteqInt0001();
    void testLinkGteqReal0001();
    void testLinkGteqWord0001();
    void testLinkGteqChar0001();
    void testLinkGteqString0001();
    void testLinkWord_toIntX0001();
    void testLinkWord_fromInt0001();
    void testLinkWord_andb0001();
    void testLinkWord_orb0001();
    void testLinkWord_xorb0001();
    void testLinkWord_notb0001();
    void testLinkWord_leftShift0001();
    void testLinkWord_logicalRightShift0001();
    void testLinkWord_arithmeticRightShift0001();

    template<class TestClass>
    class Suite;
};

template<class TestClass>
class ExecutableLinkerTest0001::Suite
    : public TestSuite
{
    ///////////////////////////////////////////////////////////////////////////
  public:
    Suite();
};

///////////////////////////////////////////////////////////////////////////////

}

#endif // ExecutableLinkerTest0001_hh_
