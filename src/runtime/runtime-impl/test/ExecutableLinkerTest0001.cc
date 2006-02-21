// ExecutableLinkerTest0001
// jp_ac_jaist_iml_runtime

#include "ExecutableLinkerTest0001.hh"
#include "ExecutableLinker.hh"
#include "SystemDef.hh"

#include "TestCaller.h"

namespace jp_ac_jaist_iml_runtime
{

///////////////////////////////////////////////////////////////////////////////

UInt32Value
ExecutableLinkerTest0001::
pack1_1_2(UInt8Value first, UInt8Value second, UInt16Value third)
{
    UInt8Value buffer[4];
    buffer[0] = first;
    buffer[1] = second;
    UInt8Value highByte = (UInt8Value)(third >> 8);
    UInt8Value lowByte = (UInt8Value)third;
    buffer[2] = littleEndian_ ? lowByte : highByte;
    buffer[3] = littleEndian_ ? highByte : lowByte;

    return *(UInt32Value*)buffer;
}

UInt32Value
ExecutableLinkerTest0001::pack1_3(UInt8Value first, UInt32Value second)
{
    UInt8Value buffer[4];
    buffer[0] = first;
    UInt8Value highByte = (UInt8Value)(second >> 16);
    UInt8Value middleByte = (UInt8Value)(second >> 8);
    UInt8Value lowByte = (UInt8Value)second;
    buffer[1] = littleEndian_ ? lowByte : highByte;
    buffer[2] = middleByte;
    buffer[3] = littleEndian_ ? highByte : lowByte;

    return *(UInt32Value*)buffer;
}

UInt32Value
ExecutableLinkerTest0001::pack4(UInt32Value value)
{
    UInt8Value buffer[4];
    UInt8Value highByte = (UInt8Value)(value >> 24);
    UInt8Value middleHighByte = (UInt8Value)(value >> 16);
    UInt8Value middleLowByte = (UInt8Value)(value >> 8);
    UInt8Value lowByte = (UInt8Value)value;
    UInt8Value* bytes = (UInt8Value*)buffer;
    buffer[0] = littleEndian_ ? lowByte : highByte;
    buffer[1] = littleEndian_ ? middleLowByte : middleHighByte;
    buffer[2] = littleEndian_ ? middleHighByte : middleLowByte;
    buffer[3] = littleEndian_ ? highByte : lowByte;

    return *(UInt32Value*)buffer;
}

#define PACK_FUNENTRY \
        pack1_3(FunEntry, 0), \
        pack4(0), /* arity */ \
        pack4(0), /* bitmap args count */ \
        pack4(0), /* bitmap frees count */ \
        pack4(0), /* frame size */ \
        pack4(0), /* pointers */ \
        pack4(0), /* atoms */ \
        pack4(0) /* record groups count */ \


///////////////////////////////////////////////////////////////////////////////

void
ExecutableLinkerTest0001::setUp()
{
    // setup facades
}

void
ExecutableLinkerTest0001::tearDown()
{
    //
}

///////////////////////////////////////////////////////////////////////////////

#ifdef BYTE_ORDER_LITTLE_ENDIAN
#define assertPacked1_3(value, expectedFirst, expectedSecond) \
assertLongsEqual((((expectedSecond) << 8) | ((expectedFirst) & 0xFF)), value)
#else
#define assertPacked1_3(value, expectedFirst, expectedSecond) \
assertLongsEqual((((expectedSecond) & 0xFF) | (expectedFirst) << 24), value)
#endif

#ifdef BYTE_ORDER_LITTLE_ENDIAN
#define assertPacked1_1_2(value, expectedFirst, expectedSecond, expectedThird)\
assertLongsEqual(((((expectedThird) & 0xFFFF) << 16) | \
                  (((expectedSecond) & 0xFF) << 8) | \
                  ((expectedFirst) & 0xFF)), value)
#else
#define assertPacked1_1_2(value, expectedFirst, expectedSecond, expectedThird)\
assertLongsEqual((((expectedThird) & 0xFFFF) | \
                  (((expectedSecond) & 0xFF) << 16) | \
                  (((expectedFirst) & 0xFF) << 24)), value)
#endif

#define assertOffsetEqual(expected, code, addressOffset) \
assertLongsEqual((expected), \
                 (UInt32Value)(((UInt32Value*)((code)[(addressOffset)])) - \
                               (code)))

///////////////////////////////////////////////////////////////////////////////

void
ExecutableLinkerTest0001::testLinkLoadInt0001()
{
    testLink2ConstOperands0001(LoadInt);
}

////////////////////////////////////////

void
ExecutableLinkerTest0001::testLinkLoadWord0001()
{
    testLink2ConstOperands0001(LoadWord);
}

////////////////////////////////////////

const UInt32Value TESTLINKLOADSTRING0001_STRINGOFFSET = 0x3;
const UInt32Value TESTLINKLOADSTRING0001_DESTINATION = 0x87654321;

void
ExecutableLinkerTest0001::testLinkLoadString0001()
{
    UInt32Value code[] = {
        pack1_3(LoadString, 0),
        pack4(TESTLINKLOADSTRING0001_STRINGOFFSET),
        pack4(TESTLINKLOADSTRING0001_DESTINATION),
        pack1_3(ConstString, 0),  // STRINGOFFSET points here.
        pack4(0), // length
        pack4(0), // zero trailer
    };
    Executable executable = doLink(sizeof(code)/sizeof(code[0]), code);
    assertLongsEqual(sizeof(code) / sizeof(code[0]), executable.codeWordLength);
    assertPacked1_3(executable.code[0], LoadString, 0);
    assertOffsetEqual(TESTLINKLOADSTRING0001_STRINGOFFSET, executable.code, 1);
    assertLongsEqual(TESTLINKLOADSTRING0001_DESTINATION, executable.code[2]);
}

////////////////////////////////////////

// it is not required to be in valid real number format.
const Real64Value TESTLINKLOADREALBASE0001_FLOAT = 123.456789;
const UInt32Value TESTLINKLOADREALBASE0001_DESTINATION = 0x12345678;

void
ExecutableLinkerTest0001::testLinkLoadRealBase0001(instruction opcode)
{
    fail("not implemented.", __LINE__, __FILE__);
    UInt32Value* floatBuf = (UInt32Value*)&TESTLINKLOADREALBASE0001_FLOAT;
    UInt32Value code[] = {
        pack1_3(opcode, 0),
        // ToDo : pack float
        pack4(0),
        pack4(0),
        pack4(TESTLINKLOADREALBASE0001_DESTINATION),
    };
    Executable executable = doLink(sizeof(code)/sizeof(code[0]), code);
    assertLongsEqual(sizeof(code) / sizeof(code[0]), executable.codeWordLength);
    assertPacked1_3(executable.code[0], opcode, 0);
    // ToDo : check float
    assertLongsEqual(TESTLINKLOADREALBASE0001_DESTINATION, executable.code[3]);
}

////////////////////////////////////////

void
ExecutableLinkerTest0001::testLinkLoadReal0001()
{
    testLinkLoadRealBase0001(LoadReal);
}

////////////////////////////////////////

void
ExecutableLinkerTest0001::testLinkLoadBoxedReal0001()
{
    testLinkLoadRealBase0001(LoadBoxedReal);
}

////////////////////////////////////////

void
ExecutableLinkerTest0001::testLinkLoadChar0001()
{
    testLink2ConstOperands0001(LoadChar);
}

////////////////////////////////////////

void
ExecutableLinkerTest0001::testLinkAccess_S0001()
{
    testLink2ConstOperands0001(Access_S);
}

////////////////////////////////////////

void
ExecutableLinkerTest0001::testLinkAccess_D0001()
{
    testLink2ConstOperands0001(Access_D);
}

////////////////////////////////////////

void
ExecutableLinkerTest0001::testLinkAccess_V0001()
{
    testLink3ConstOperands0001(Access_V);
}

////////////////////////////////////////

void
ExecutableLinkerTest0001::testLinkAccessEnv_S0001()
{
    testLink2ConstOperands0001(AccessEnv_S);
}

////////////////////////////////////////

void
ExecutableLinkerTest0001::testLinkAccessEnv_D0001()
{
    testLink2ConstOperands0001(AccessEnv_D);
}

////////////////////////////////////////

void
ExecutableLinkerTest0001::testLinkAccessEnv_V0001()
{
    testLink3ConstOperands0001(AccessEnv_V);
}

////////////////////////////////////////

void
ExecutableLinkerTest0001::testLinkAccessEnvIndirect_S0001()
{
    testLink2ConstOperands0001(AccessEnvIndirect_S);
}

////////////////////////////////////////

void
ExecutableLinkerTest0001::testLinkAccessEnvIndirect_D0001()
{
    testLink2ConstOperands0001(AccessEnvIndirect_D);
}

////////////////////////////////////////

void
ExecutableLinkerTest0001::testLinkAccessEnvIndirect_V0001()
{
    testLink3ConstOperands0001(AccessEnvIndirect_V);
}

////////////////////////////////////////

void
ExecutableLinkerTest0001::testLinkGetField_S0001()
{
    testLink3ConstOperands0001(GetField_S);
}

////////////////////////////////////////

void
ExecutableLinkerTest0001::testLinkGetField_D0001()
{
    testLink3ConstOperands0001(GetField_D);
}

////////////////////////////////////////

void
ExecutableLinkerTest0001::testLinkGetField_V0001()
{
    testLink4ConstOperands0001(GetField_V);
}

////////////////////////////////////////

void
ExecutableLinkerTest0001::testLinkGetFieldIndirect_S0001()
{
    testLink3ConstOperands0001(GetFieldIndirect_S);
}

////////////////////////////////////////

void
ExecutableLinkerTest0001::testLinkGetFieldIndirect_D0001()
{
    testLink3ConstOperands0001(GetFieldIndirect_D);
}

////////////////////////////////////////

void
ExecutableLinkerTest0001::testLinkGetFieldIndirect_V0001()
{
    testLink4ConstOperands0001(GetFieldIndirect_V);
}

////////////////////////////////////////

void
ExecutableLinkerTest0001::testLinkSetField_S0001()
{
    testLink3ConstOperands0001(SetField_S);
}

////////////////////////////////////////

void
ExecutableLinkerTest0001::testLinkSetField_D0001()
{
    testLink3ConstOperands0001(SetField_D);
}

////////////////////////////////////////

void
ExecutableLinkerTest0001::testLinkSetField_V0001()
{
    testLink4ConstOperands0001(SetField_V);
}

////////////////////////////////////////

void
ExecutableLinkerTest0001::testLinkSetFieldIndirect_S0001()
{
    testLink3ConstOperands0001(SetFieldIndirect_S);
}

////////////////////////////////////////

void
ExecutableLinkerTest0001::testLinkSetFieldIndirect_D0001()
{
    testLink3ConstOperands0001(SetFieldIndirect_D);
}

////////////////////////////////////////

void
ExecutableLinkerTest0001::testLinkSetFieldIndirect_V0001()
{
    testLink4ConstOperands0001(SetFieldIndirect_V);
}

////////////////////////////////////////

void
ExecutableLinkerTest0001::testLinkCopyBlock0001()
{
    testLink2ConstOperands0001(CopyBlock);
}

////////////////////////////////////////

void
ExecutableLinkerTest0001::testLinkGetGlobalBoxed0001()
{
    testLink2ConstOperands0001(GetGlobalBoxed);
}

////////////////////////////////////////

void
ExecutableLinkerTest0001::testLinkSetGlobalBoxed0001()
{
    testLink2ConstOperands0001(SetGlobalBoxed);
}

////////////////////////////////////////

void
ExecutableLinkerTest0001::testLinkGetGlobalUnboxed0001()
{
    testLink2ConstOperands0001(GetGlobalUnboxed);
}

////////////////////////////////////////

void
ExecutableLinkerTest0001::testLinkSetGlobalUnboxed0001()
{
    testLink2ConstOperands0001(SetGlobalUnboxed);
}

////////////////////////////////////////

void
ExecutableLinkerTest0001::testLinkGetEnv0001()
{
    testLink1ConstOperand0001(GetEnv);
}

////////////////////////////////////////

const UInt32Value TESTLINKCALLPRIM0001_PRIMINDEX = 0x12345678;
const UInt32Value TESTLINKCALLPRIM0001_ARGSCOUNT = 0x3;
const UInt32Value TESTLINKCALLPRIM0001_ARGENTRY1 = 0x34567890;
const UInt32Value TESTLINKCALLPRIM0001_ARGENTRY2 = 0x4567890A;
const UInt32Value TESTLINKCALLPRIM0001_ARGENTRY3 = 0x567890AB;
const UInt32Value TESTLINKCALLPRIM0001_DESTINATION = 0x67890ABC;

void
ExecutableLinkerTest0001::testLinkCallPrim0001()
{
    UInt32Value code[] = {
        pack1_3(CallPrim, 0),
        pack4(TESTLINKCALLPRIM0001_PRIMINDEX),
        pack4(TESTLINKCALLPRIM0001_ARGSCOUNT),
        pack4(TESTLINKCALLPRIM0001_ARGENTRY1),
        pack4(TESTLINKCALLPRIM0001_ARGENTRY2),
        pack4(TESTLINKCALLPRIM0001_ARGENTRY3),
        pack4(TESTLINKCALLPRIM0001_DESTINATION),
    };
    Executable executable = doLink(sizeof(code)/sizeof(code[0]), code);
    assertLongsEqual(sizeof(code) / sizeof(code[0]), executable.codeWordLength);
    assertPacked1_3(executable.code[0], CallPrim, 0);
    assertLongsEqual(TESTLINKCALLPRIM0001_PRIMINDEX, executable.code[1]);
    assertLongsEqual(TESTLINKCALLPRIM0001_ARGSCOUNT, executable.code[2]);
    assertLongsEqual(TESTLINKCALLPRIM0001_ARGENTRY1, executable.code[3]);
    assertLongsEqual(TESTLINKCALLPRIM0001_ARGENTRY2, executable.code[4]);
    assertLongsEqual(TESTLINKCALLPRIM0001_ARGENTRY3, executable.code[5]);
}

////////////////////////////////////////

const UInt32Value TESTLINKAPPLYBASE0001_CLOSUREINDEX = 0x12345678;
const UInt32Value TESTLINKAPPLYBASE0001_ARGSCOUNT = 0x3;
const UInt32Value TESTLINKAPPLYBASE0001_ARGENTRY1 = 0x34567890;
const UInt32Value TESTLINKAPPLYBASE0001_ARGENTRY2 = 0x4567890A;
const UInt32Value TESTLINKAPPLYBASE0001_ARGENTRY3 = 0x567890AB;
const UInt32Value TESTLINKAPPLYBASE0001_OPERANDLAST1 = 0x67890ABC;
const UInt32Value TESTLINKAPPLYBASE0001_OPERANDLAST2 = 0x7890ABCD;

void
ExecutableLinkerTest0001::testLinkApplyBase0001(instruction opcode)
{
    UInt32Value code[] = {
        pack1_3(opcode, 0),
        pack4(TESTLINKAPPLYBASE0001_CLOSUREINDEX),
        pack4(TESTLINKAPPLYBASE0001_ARGSCOUNT),
        pack4(TESTLINKAPPLYBASE0001_ARGENTRY1),
        pack4(TESTLINKAPPLYBASE0001_ARGENTRY2),
        pack4(TESTLINKAPPLYBASE0001_ARGENTRY3),
        pack4(TESTLINKAPPLYBASE0001_OPERANDLAST2),
        (Apply_V == opcode)
        ? pack4(TESTLINKAPPLYBASE0001_OPERANDLAST1)
        : pack1_3(Nop, 0),
    };
    
    Executable executable = doLink(sizeof(code)/sizeof(code[0]), code);
    assertLongsEqual(sizeof(code) / sizeof(code[0]), executable.codeWordLength);
    assertPacked1_3(executable.code[0], opcode, 0);
    assertLongsEqual(TESTLINKAPPLYBASE0001_CLOSUREINDEX, executable.code[1]);
    assertLongsEqual(TESTLINKAPPLYBASE0001_ARGSCOUNT, executable.code[2]);
    assertLongsEqual(TESTLINKAPPLYBASE0001_ARGENTRY1, executable.code[3]);
    assertLongsEqual(TESTLINKAPPLYBASE0001_ARGENTRY2, executable.code[4]);
    assertLongsEqual(TESTLINKAPPLYBASE0001_ARGENTRY3, executable.code[5]);
    assertLongsEqual(TESTLINKAPPLYBASE0001_OPERANDLAST2, executable.code[6]);
    if(Apply_V == opcode)
    {assertLongsEqual(TESTLINKAPPLYBASE0001_OPERANDLAST1, executable.code[7]);}
}

////////////////////////////////////////

void
ExecutableLinkerTest0001::testLinkApply_S0001()
{
    testLinkApplyBase0001(Apply_S);
}

////////////////////////////////////////

void
ExecutableLinkerTest0001::testLinkApply_D0001()
{
    testLinkApplyBase0001(Apply_D);
}

////////////////////////////////////////

void
ExecutableLinkerTest0001::testLinkApply_V0001()
{
    testLinkApplyBase0001(Apply_V);
}

////////////////////////////////////////

const UInt32Value TESTLINKTAILAPPLYBASE0001_CLOSUREINDEX = 0x12345678;
const UInt32Value TESTLINKTAILAPPLYBASE0001_ARGSCOUNT = 0x3;
const UInt32Value TESTLINKTAILAPPLYBASE0001_ARGENTRY1 = 0x34567890;
const UInt32Value TESTLINKTAILAPPLYBASE0001_ARGENTRY2 = 0x4567890A;
const UInt32Value TESTLINKTAILAPPLYBASE0001_ARGENTRY3 = 0x567890AB;
const UInt32Value TESTLINKTAILAPPLYBASE0001_OPERANDLAST = 0x67890ABC;

void
ExecutableLinkerTest0001::testLinkTailApplyBase0001(instruction opcode)
{
    UInt32Value code[] = {
        pack1_3(opcode, 0),
        pack4(TESTLINKTAILAPPLYBASE0001_CLOSUREINDEX),
        pack4(TESTLINKTAILAPPLYBASE0001_ARGSCOUNT),
        pack4(TESTLINKTAILAPPLYBASE0001_ARGENTRY1),
        pack4(TESTLINKTAILAPPLYBASE0001_ARGENTRY2),
        pack4(TESTLINKTAILAPPLYBASE0001_ARGENTRY3),
        (TailApply_V == opcode)
        ? pack4(TESTLINKTAILAPPLYBASE0001_OPERANDLAST)
        : pack1_3(Nop, 0),
    };
    Executable executable = doLink(sizeof(code)/sizeof(code[0]), code);
    assertLongsEqual(sizeof(code) / sizeof(code[0]), executable.codeWordLength);
    assertPacked1_3(executable.code[0], opcode, 0);
    assertLongsEqual
    (TESTLINKTAILAPPLYBASE0001_CLOSUREINDEX, executable.code[1]);
    assertLongsEqual(TESTLINKTAILAPPLYBASE0001_ARGSCOUNT, executable.code[2]);
    assertLongsEqual(TESTLINKTAILAPPLYBASE0001_ARGENTRY1, executable.code[3]);
    assertLongsEqual(TESTLINKTAILAPPLYBASE0001_ARGENTRY2, executable.code[4]);
    assertLongsEqual(TESTLINKTAILAPPLYBASE0001_ARGENTRY3, executable.code[5]);
    if(TailApply_V == opcode)
    {
        assertLongsEqual
        (TESTLINKTAILAPPLYBASE0001_OPERANDLAST, executable.code[6]);
    }
}

////////////////////////////////////////

void
ExecutableLinkerTest0001::testLinkTailApply_S0001()
{
    testLinkTailApplyBase0001(TailApply_S);
}

////////////////////////////////////////

void
ExecutableLinkerTest0001::testLinkTailApply_D0001()
{
    testLinkTailApplyBase0001(TailApply_D);
}

////////////////////////////////////////

void
ExecutableLinkerTest0001::testLinkTailApply_V0001()
{
    testLinkTailApplyBase0001(TailApply_V);
}

////////////////////////////////////////

const UInt32Value TESTLINKCALLSTATICBASE0001_ENTRYPOINTOFFSET = 0x8;
const UInt32Value TESTLINKCALLSTATICBASE0001_ARGSCOUNT = 0x3;
const UInt32Value TESTLINKCALLSTATICBASE0001_ARGENTRY1 = 0x34567890;
const UInt32Value TESTLINKCALLSTATICBASE0001_ARGENTRY2 = 0x4567890A;
const UInt32Value TESTLINKCALLSTATICBASE0001_ARGENTRY3 = 0x567890AB;
const UInt32Value TESTLINKCALLSTATICBASE0001_OPERANDLAST1 = 0x67890ABC;
const UInt32Value TESTLINKCALLSTATICBASE0001_OPERANDLAST2 = 0x7890ABCD;

void
ExecutableLinkerTest0001::testLinkCallStaticBase0001(instruction opcode)
{
    UInt32Value code[] = {
        pack1_3(opcode, 0),
        pack4(TESTLINKCALLSTATICBASE0001_ENTRYPOINTOFFSET),
        pack4(TESTLINKCALLSTATICBASE0001_ARGSCOUNT),
        pack4(TESTLINKCALLSTATICBASE0001_ARGENTRY1),
        pack4(TESTLINKCALLSTATICBASE0001_ARGENTRY2),
        pack4(TESTLINKCALLSTATICBASE0001_ARGENTRY3),
        pack4(TESTLINKCALLSTATICBASE0001_OPERANDLAST1),
        (CallStatic_V == opcode)
        ? pack4(TESTLINKCALLSTATICBASE0001_OPERANDLAST2)
        : pack1_3(Nop, 0),
        PACK_FUNENTRY, // entry point
    };
    Executable executable = doLink(sizeof(code)/sizeof(code[0]), code);
    assertLongsEqual(sizeof(code) / sizeof(code[0]), executable.codeWordLength);
    assertPacked1_3(executable.code[0], opcode, 0);
    assertOffsetEqual(TESTLINKCALLSTATICBASE0001_ENTRYPOINTOFFSET,
                      executable.code,
                      1);
    assertLongsEqual(TESTLINKCALLSTATICBASE0001_ARGSCOUNT, executable.code[2]);
    assertLongsEqual(TESTLINKCALLSTATICBASE0001_ARGENTRY1, executable.code[3]);
    assertLongsEqual(TESTLINKCALLSTATICBASE0001_ARGENTRY2, executable.code[4]);
    assertLongsEqual(TESTLINKCALLSTATICBASE0001_ARGENTRY3, executable.code[5]);
    assertLongsEqual
    (TESTLINKCALLSTATICBASE0001_OPERANDLAST1, executable.code[6]);
    if(CallStatic_V == opcode)
    {
        assertLongsEqual
        (TESTLINKCALLSTATICBASE0001_OPERANDLAST2, executable.code[7]);
    }
}

////////////////////////////////////////

void
ExecutableLinkerTest0001::testLinkCallStatic_S0001()
{
    testLinkCallStaticBase0001(CallStatic_S);
}

////////////////////////////////////////

void
ExecutableLinkerTest0001::testLinkCallStatic_D0001()
{
    testLinkCallStaticBase0001(CallStatic_D);
}

////////////////////////////////////////

void
ExecutableLinkerTest0001::testLinkCallStatic_V0001()
{
    testLinkCallStaticBase0001(CallStatic_V);
}

////////////////////////////////////////

const UInt32Value TESTLINKTAILCALLSTATIC0001_ENTRYPOINTOFFSET = 0x7;
const UInt32Value TESTLINKTAILCALLSTATIC0001_ARGSCOUNT = 0x3;
const UInt32Value TESTLINKTAILCALLSTATIC0001_ARGENTRY1 = 0x34567890;
const UInt32Value TESTLINKTAILCALLSTATIC0001_ARGENTRY2 = 0x4567890A;
const UInt32Value TESTLINKTAILCALLSTATIC0001_ARGENTRY3 = 0x567890AB;
const UInt32Value TESTLINKTAILCALLSTATIC0001_LASTOPERAND = 0x67890ABC;

void
ExecutableLinkerTest0001::testLinkTailCallStaticBase0001(instruction opcode)
{
    UInt32Value code[] = {
        pack1_3(opcode, 0),
        pack4(TESTLINKTAILCALLSTATIC0001_ENTRYPOINTOFFSET),
        pack4(TESTLINKTAILCALLSTATIC0001_ARGSCOUNT),
        pack4(TESTLINKTAILCALLSTATIC0001_ARGENTRY1),
        pack4(TESTLINKTAILCALLSTATIC0001_ARGENTRY2),
        pack4(TESTLINKTAILCALLSTATIC0001_ARGENTRY3),
        (TailCallStatic_V == opcode)
        ? pack4(TESTLINKTAILCALLSTATIC0001_LASTOPERAND)
        : pack1_3(Nop, 0),
        PACK_FUNENTRY, // entry point
    };
    Executable executable = doLink(sizeof(code)/sizeof(code[0]), code);
    assertLongsEqual(sizeof(code) / sizeof(code[0]), executable.codeWordLength);
    assertPacked1_3(executable.code[0], opcode, 0);
    assertOffsetEqual(TESTLINKTAILCALLSTATIC0001_ENTRYPOINTOFFSET,
                      executable.code,
                      1);
    assertLongsEqual(TESTLINKTAILCALLSTATIC0001_ARGSCOUNT, executable.code[2]);
    assertLongsEqual(TESTLINKTAILCALLSTATIC0001_ARGENTRY1, executable.code[3]);
    assertLongsEqual(TESTLINKTAILCALLSTATIC0001_ARGENTRY2, executable.code[4]);
    assertLongsEqual(TESTLINKTAILCALLSTATIC0001_ARGENTRY3, executable.code[5]);
    if(TailCallStatic_V == opcode)
    {
        assertLongsEqual
        (TESTLINKTAILCALLSTATIC0001_LASTOPERAND, executable.code[6]);
    }
}

////////////////////////////////////////

void
ExecutableLinkerTest0001::testLinkTailCallStatic_S0001()
{
    testLinkTailCallStaticBase0001(TailCallStatic_S);
}

////////////////////////////////////////

void
ExecutableLinkerTest0001::testLinkTailCallStatic_D0001()
{
    testLinkTailCallStaticBase0001(TailCallStatic_D);
}

////////////////////////////////////////

void
ExecutableLinkerTest0001::testLinkTailCallStatic_V0001()
{
    testLinkTailCallStaticBase0001(TailCallStatic_V);
}

////////////////////////////////////////

const UInt32Value TESTLINKMAKEBLOCK0001_BITMAPENTRY = 0x12345678;
const UInt32Value TESTLINKMAKEBLOCK0001_SIZEENTRY = 0x23456789;
const UInt32Value TESTLINKMAKEBLOCK0001_FIELDS = 0x3;
const UInt32Value TESTLINKMAKEBLOCK0001_FIELDENTRY1 = 0xA0A1A2A3;
const UInt32Value TESTLINKMAKEBLOCK0001_FIELDENTRY2 = 0xB0B1B2B3;
const UInt32Value TESTLINKMAKEBLOCK0001_FIELDENTRY3 = 0xC0C1C2C3;
const UInt32Value TESTLINKMAKEBLOCK0001_FIELDSIZEENTRY1 = 0xD0D1D2D3;
const UInt32Value TESTLINKMAKEBLOCK0001_FIELDSIZEENTRY2 = 0xE0E1E2E3;
const UInt32Value TESTLINKMAKEBLOCK0001_FIELDSIZEENTRY3 = 0xF0F1F2F3;
const UInt32Value TESTLINKMAKEBLOCK0001_DESTINATION = 0x90919293;

void
ExecutableLinkerTest0001::testLinkMakeBlock0001()
{
    UInt32Value code[] = {
        pack1_3(MakeBlock, 0),
        pack4(TESTLINKMAKEBLOCK0001_BITMAPENTRY),
        pack4(TESTLINKMAKEBLOCK0001_SIZEENTRY),
        pack4(TESTLINKMAKEBLOCK0001_FIELDS),
        pack4(TESTLINKMAKEBLOCK0001_FIELDENTRY1),
        pack4(TESTLINKMAKEBLOCK0001_FIELDENTRY2),
        pack4(TESTLINKMAKEBLOCK0001_FIELDENTRY3),
        pack4(TESTLINKMAKEBLOCK0001_FIELDSIZEENTRY1),
        pack4(TESTLINKMAKEBLOCK0001_FIELDSIZEENTRY2),
        pack4(TESTLINKMAKEBLOCK0001_FIELDSIZEENTRY3),
        pack4(TESTLINKMAKEBLOCK0001_DESTINATION),
        pack1_3(Nop, 0),
    };
    Executable executable = doLink(sizeof(code)/sizeof(code[0]), code);
    assertLongsEqual(sizeof(code) / sizeof(code[0]), executable.codeWordLength);
    assertPacked1_3(executable.code[0], MakeBlock, 0);
    assertLongsEqual(TESTLINKMAKEBLOCK0001_BITMAPENTRY, executable.code[1]);
    assertLongsEqual(TESTLINKMAKEBLOCK0001_SIZEENTRY, executable.code[2]);
    assertLongsEqual(TESTLINKMAKEBLOCK0001_FIELDS, executable.code[3]);
    assertLongsEqual(TESTLINKMAKEBLOCK0001_FIELDENTRY1, executable.code[4]);
    assertLongsEqual(TESTLINKMAKEBLOCK0001_FIELDENTRY2, executable.code[5]);
    assertLongsEqual(TESTLINKMAKEBLOCK0001_FIELDENTRY3, executable.code[6]);
    assertLongsEqual
    (TESTLINKMAKEBLOCK0001_FIELDSIZEENTRY1, executable.code[7]);
    assertLongsEqual
    (TESTLINKMAKEBLOCK0001_FIELDSIZEENTRY2, executable.code[8]);
    assertLongsEqual
    (TESTLINKMAKEBLOCK0001_FIELDSIZEENTRY3, executable.code[9]);
    assertLongsEqual(TESTLINKMAKEBLOCK0001_DESTINATION, executable.code[10]);
    assertPacked1_3(executable.code[11], Nop, 0);
}

////////////////////////////////////////

void
ExecutableLinkerTest0001::testLinkMakeArray_S0001()
{
    testLink4ConstOperands0001(MakeArray_S);
}

////////////////////////////////////////

void
ExecutableLinkerTest0001::testLinkMakeArray_D0001()
{
    testLink4ConstOperands0001(MakeArray_D);
}

////////////////////////////////////////

void
ExecutableLinkerTest0001::testLinkMakeArray_V0001()
{
    testLink5ConstOperands0001(MakeArray_V);
}

////////////////////////////////////////

const UInt32Value TESTLINKMAKECLOSURE0001_ENTRYPOINTOFFSET = 0x5;
const UInt32Value TESTLINKMAKECLOSURE0001_ENVENTRY = 0x34567890;
const UInt32Value TESTLINKMAKECLOSURE0001_DESTINATION = 0x67890ABC;

void
ExecutableLinkerTest0001::testLinkMakeClosure0001()
{
    UInt32Value code[] = {
        pack1_3(MakeClosure, 0),
        pack4(TESTLINKMAKECLOSURE0001_ENTRYPOINTOFFSET),
        pack4(TESTLINKMAKECLOSURE0001_ENVENTRY),
        pack4(TESTLINKMAKECLOSURE0001_DESTINATION),
        pack1_3(Nop, 0),
        PACK_FUNENTRY, // entry point
    };
    Executable executable = doLink(sizeof(code)/sizeof(code[0]), code);
    assertLongsEqual(sizeof(code) / sizeof(code[0]), executable.codeWordLength);
    assertPacked1_3(executable.code[0], MakeClosure, 0);
    assertOffsetEqual(TESTLINKMAKECLOSURE0001_ENTRYPOINTOFFSET,
                      executable.code,
                      1);
    assertLongsEqual(TESTLINKMAKECLOSURE0001_ENVENTRY, executable.code[2]);
    assertLongsEqual(TESTLINKMAKECLOSURE0001_DESTINATION, executable.code[3]);
}

////////////////////////////////////////

void
ExecutableLinkerTest0001::testLinkRaise0001()
{
    testLink1ConstOperand0001(Raise);
}

////////////////////////////////////////

const UInt32Value TESTLINKPUSHHANDLER0001_HANDLEROFFSET = 0x3;
const UInt32Value TESTLINKPUSHHANDLER0001_EXCEPTIONENTRY = 0x12345678;

void
ExecutableLinkerTest0001::testLinkPushHandler0001()
{
    UInt32Value code[] = {
        pack1_3(PushHandler, 0),
        pack4(TESTLINKPUSHHANDLER0001_HANDLEROFFSET),
        pack4(TESTLINKPUSHHANDLER0001_EXCEPTIONENTRY),
        pack1_3(Nop, 0),
    };
    Executable executable = doLink(sizeof(code)/sizeof(code[0]), code);
    assertLongsEqual(sizeof(code) / sizeof(code[0]), executable.codeWordLength);
    assertPacked1_3(executable.code[0], PushHandler, 0);
    assertOffsetEqual(TESTLINKPUSHHANDLER0001_HANDLEROFFSET,
                      executable.code,
                      1);
    assertLongsEqual(TESTLINKPUSHHANDLER0001_EXCEPTIONENTRY,
                     executable.code[2]);
}

////////////////////////////////////////

void
ExecutableLinkerTest0001::testLinkPopHandler0001()
{
    testLinkNoOperand0001(PopHandler);
}

////////////////////////////////////////

void
ExecutableLinkerTest0001::testLinkSwitchInt0001()
{
    testLinkSwitchAtom0001(SwitchInt);
}

////////////////////////////////////////

void
ExecutableLinkerTest0001::testLinkSwitchWord0001()
{
    testLinkSwitchAtom0001(SwitchInt);
}

////////////////////////////////////////

void
ExecutableLinkerTest0001::testLinkSwitchChar0001()
{
    testLinkSwitchAtom0001(SwitchInt);
}

////////////////////////////////////////

const UInt32Value TESTLINKSWITCHSTRING0001_TARGETENTRY = 0x12345678;
const UInt32Value TESTLINKSWITCHSTRING0001_CASESCOUNT = 0x3;
const UInt32Value TESTLINKSWITCHSTRING0001_CASE1CONST = 10;
const UInt32Value TESTLINKSWITCHSTRING0001_CASE1OFFSET = 10;
const UInt32Value TESTLINKSWITCHSTRING0001_CASE2CONST = 10;
const UInt32Value TESTLINKSWITCHSTRING0001_CASE2OFFSET = 10;
const UInt32Value TESTLINKSWITCHSTRING0001_CASE3CONST = 10;
const UInt32Value TESTLINKSWITCHSTRING0001_CASE3OFFSET = 10;
const UInt32Value TESTLINKSWITCHSTRING0001_DEFAULTOFFSET = 10;

void
ExecutableLinkerTest0001::testLinkSwitchString0001()
{
    UInt32Value code[] = {
        pack1_3(SwitchString, 0),
        pack4(TESTLINKSWITCHSTRING0001_TARGETENTRY),
        pack4(TESTLINKSWITCHSTRING0001_CASESCOUNT),
        pack4(TESTLINKSWITCHSTRING0001_CASE1CONST),
        pack4(TESTLINKSWITCHSTRING0001_CASE1OFFSET),
        pack4(TESTLINKSWITCHSTRING0001_CASE2CONST),
        pack4(TESTLINKSWITCHSTRING0001_CASE2OFFSET),
        pack4(TESTLINKSWITCHSTRING0001_CASE3CONST),
        pack4(TESTLINKSWITCHSTRING0001_CASE3OFFSET),
        pack4(TESTLINKSWITCHSTRING0001_DEFAULTOFFSET),
        pack1_3(ConstString, 0),  // OFFSETs point here.
        pack4(0), // length
        pack4(0), // zero trailer
    };
    Executable executable = doLink(sizeof(code)/sizeof(code[0]), code);
    assertLongsEqual(sizeof(code) / sizeof(code[0]), executable.codeWordLength);
    assertPacked1_3(executable.code[0], SwitchString, 0);
    assertLongsEqual(TESTLINKSWITCHSTRING0001_TARGETENTRY, executable.code[1]);
    assertLongsEqual(TESTLINKSWITCHSTRING0001_CASESCOUNT, executable.code[2]);
    assertOffsetEqual(TESTLINKSWITCHSTRING0001_CASE1CONST, executable.code, 3);
    assertOffsetEqual(TESTLINKSWITCHSTRING0001_CASE1OFFSET,
                      executable.code, 4);
    assertOffsetEqual(TESTLINKSWITCHSTRING0001_CASE2CONST, executable.code, 5);
    assertOffsetEqual(TESTLINKSWITCHSTRING0001_CASE2OFFSET,
                      executable.code, 6);
    assertOffsetEqual(TESTLINKSWITCHSTRING0001_CASE3CONST, executable.code, 7);
    assertOffsetEqual(TESTLINKSWITCHSTRING0001_CASE3OFFSET,
                      executable.code, 8);
    assertOffsetEqual(TESTLINKSWITCHSTRING0001_DEFAULTOFFSET,
                      executable.code, 9);
}

////////////////////////////////////////

const UInt32Value TESTLINKJUMP0001_DESTINATIONOFFSET = 0x3;

void
ExecutableLinkerTest0001::testLinkJump0001()
{
    UInt32Value code[] = {
        pack1_3(Jump, 0),
        pack4(TESTLINKJUMP0001_DESTINATIONOFFSET),
        pack1_3(Nop, 0),
        pack1_3(Nop, 0),
    };
    Executable executable = doLink(sizeof(code)/sizeof(code[0]), code);
    assertLongsEqual(sizeof(code) / sizeof(code[0]), executable.codeWordLength);
    assertPacked1_3(executable.code[0], Jump, 0);
    assertOffsetEqual(TESTLINKJUMP0001_DESTINATIONOFFSET, executable.code, 1);
    assertPacked1_3(executable.code[2], Nop, 0);
    assertPacked1_3(executable.code[3], Nop, 0);
}

////////////////////////////////////////

void
ExecutableLinkerTest0001::testLinkExit0001()
{
    testLinkNoOperand0001(Exit);
}

////////////////////////////////////////

void
ExecutableLinkerTest0001::testLinkReturn_S0001()
{
    testLink1ConstOperand0001(Return_S);
}

////////////////////////////////////////

void
ExecutableLinkerTest0001::testLinkReturn_D0001()
{
    testLink1ConstOperand0001(Return_D);
}

////////////////////////////////////////

void
ExecutableLinkerTest0001::testLinkReturn_V0001()
{
    testLink2ConstOperands0001(Return_V);
}

////////////////////////////////////////

const UInt32Value TESTLINKFUNENTRY0001_ARITY = 0x2;
const UInt32Value TESTLINKFUNENTRY0001_ARGSDEST1 = 0x12345678;
const UInt32Value TESTLINKFUNENTRY0001_ARGSDEST2 = 0x23456789;
const UInt32Value TESTLINKFUNENTRY0001_BITMAPVALSARGSCOUNT = 0x3;
const UInt32Value TESTLINKFUNENTRY0001_BITMAPVALSARGS1 = 0x34567890;
const UInt32Value TESTLINKFUNENTRY0001_BITMAPVALSARGS2 = 0x4567890A;
const UInt32Value TESTLINKFUNENTRY0001_BITMAPVALSARGS3 = 0x567890AB;
const UInt32Value TESTLINKFUNENTRY0001_BITMAPVALSFREESCOUNT = 0x4;
const UInt32Value TESTLINKFUNENTRY0001_BITMAPVALSFREES1 = 0x34567890;
const UInt32Value TESTLINKFUNENTRY0001_BITMAPVALSFREES2 = 0x4567890A;
const UInt32Value TESTLINKFUNENTRY0001_BITMAPVALSFREES3 = 0x567890AB;
const UInt32Value TESTLINKFUNENTRY0001_BITMAPVALSFREES4 = 0x67890ABC;
const UInt32Value TESTLINKFUNENTRY0001_FRAMESIZE = 0x7890ABCD;
const UInt32Value TESTLINKFUNENTRY0001_POINTERS = 0x890ABCDE;
const UInt32Value TESTLINKFUNENTRY0001_ATOMS = 0x90ABCDEF;
const UInt32Value TESTLINKFUNENTRY0001_RECORDGROUPSCOUNT = 0x1;
const UInt32Value TESTLINKFUNENTRY0001_RECORDGROUPS1 = 0x87654321;

void
ExecutableLinkerTest0001::testLinkFunEntry0001()
{
    UInt32Value code[] = {
        pack1_3(Nop, 0),
        pack1_3(Nop, 0),
        pack1_3(FunEntry, 0),
        pack4(TESTLINKFUNENTRY0001_ARITY),
        pack4(TESTLINKFUNENTRY0001_ARGSDEST1),
        pack4(TESTLINKFUNENTRY0001_ARGSDEST2),
        pack4(TESTLINKFUNENTRY0001_BITMAPVALSARGSCOUNT),
        pack4(TESTLINKFUNENTRY0001_BITMAPVALSARGS1),
        pack4(TESTLINKFUNENTRY0001_BITMAPVALSARGS2),
        pack4(TESTLINKFUNENTRY0001_BITMAPVALSARGS3),
        pack4(TESTLINKFUNENTRY0001_BITMAPVALSFREESCOUNT),
        pack4(TESTLINKFUNENTRY0001_BITMAPVALSFREES1),
        pack4(TESTLINKFUNENTRY0001_BITMAPVALSFREES2),
        pack4(TESTLINKFUNENTRY0001_BITMAPVALSFREES3),
        pack4(TESTLINKFUNENTRY0001_BITMAPVALSFREES4),
        pack4(TESTLINKFUNENTRY0001_FRAMESIZE),
        pack4(TESTLINKFUNENTRY0001_POINTERS),
        pack4(TESTLINKFUNENTRY0001_ATOMS),
        pack4(TESTLINKFUNENTRY0001_RECORDGROUPSCOUNT),
        pack4(TESTLINKFUNENTRY0001_RECORDGROUPS1),
        pack1_3(Nop, 0),
        pack1_3(Nop, 0),
    };
    Executable executable = doLink(sizeof(code)/sizeof(code[0]), code);
    assertLongsEqual(sizeof(code) / sizeof(code[0]), executable.codeWordLength);
    assertPacked1_3(executable.code[0], Nop, 0);
    assertPacked1_3(executable.code[1], Nop, 0);
    assertPacked1_3(executable.code[2], FunEntry, 0);
    assertLongsEqual(TESTLINKFUNENTRY0001_ARITY, executable.code[3]);
    assertLongsEqual(TESTLINKFUNENTRY0001_ARGSDEST1, executable.code[4]);
    assertLongsEqual(TESTLINKFUNENTRY0001_ARGSDEST2, executable.code[5]);
    assertLongsEqual(TESTLINKFUNENTRY0001_BITMAPVALSARGSCOUNT,
                     executable.code[6]);
    assertLongsEqual(TESTLINKFUNENTRY0001_BITMAPVALSARGS1, executable.code[7]);
    assertLongsEqual(TESTLINKFUNENTRY0001_BITMAPVALSARGS2, executable.code[8]);
    assertLongsEqual(TESTLINKFUNENTRY0001_BITMAPVALSARGS3, executable.code[9]);
    assertLongsEqual(TESTLINKFUNENTRY0001_BITMAPVALSFREESCOUNT,
                     executable.code[10]);
    assertLongsEqual(TESTLINKFUNENTRY0001_BITMAPVALSFREES1,
                     executable.code[11]);
    assertLongsEqual(TESTLINKFUNENTRY0001_BITMAPVALSFREES2,
                     executable.code[12]);
    assertLongsEqual(TESTLINKFUNENTRY0001_BITMAPVALSFREES3,
                     executable.code[13]);
    assertLongsEqual(TESTLINKFUNENTRY0001_BITMAPVALSFREES4,
                     executable.code[14]);
    assertLongsEqual(TESTLINKFUNENTRY0001_FRAMESIZE, executable.code[15]);
    assertLongsEqual(TESTLINKFUNENTRY0001_POINTERS, executable.code[16]);
    assertLongsEqual(TESTLINKFUNENTRY0001_ATOMS, executable.code[17]);
    assertLongsEqual(TESTLINKFUNENTRY0001_RECORDGROUPSCOUNT,
                     executable.code[18]);
    assertLongsEqual(TESTLINKFUNENTRY0001_RECORDGROUPS1, executable.code[19]);
    assertPacked1_3(executable.code[20], Nop, 0);
    assertPacked1_3(executable.code[21], Nop, 0);
}

////////////////////////////////////////

const UInt8Value TESTLINKCONSTSTRING0001_STRING[] = {
    0x01, 0x23, 0x45, 0x67,
    0x89, 0xAB, 0xCD, 0xEF,
    0x00, 0x00, 0x00, 0x00,
};
const UInt32Value TESTLINKCONSTSTRING0001_LENGTH = 0x8;

void
ExecutableLinkerTest0001::testLinkConstString0001()
{
    UInt32Value code[] = {
        pack1_3(ConstString, sizeof(TESTLINKCONSTSTRING0001_STRING)),
        pack4(TESTLINKCONSTSTRING0001_LENGTH),
        *(UInt32Value*)&TESTLINKCONSTSTRING0001_STRING[0],
        *(UInt32Value*)&TESTLINKCONSTSTRING0001_STRING[4],
        *(UInt32Value*)&TESTLINKCONSTSTRING0001_STRING[8],
    };
    Executable executable = doLink(sizeof(code)/sizeof(code[0]), code);
    assertLongsEqual(sizeof(code) / sizeof(code[0]), executable.codeWordLength);
    assertPacked1_3(executable.code[0],
                    ConstString, sizeof(TESTLINKCONSTSTRING0001_STRING));
    assertLongsEqual(TESTLINKCONSTSTRING0001_LENGTH, executable.code[1]);
    assertLongsEqual(*(UInt32Value*)&TESTLINKCONSTSTRING0001_STRING[0],
                     executable.code[2]);
    assertLongsEqual(*(UInt32Value*)&TESTLINKCONSTSTRING0001_STRING[4],
                     executable.code[3]);
    assertLongsEqual(*(UInt32Value*)&TESTLINKCONSTSTRING0001_STRING[8],
                     executable.code[4]);
}

////////////////////////////////////////

void
ExecutableLinkerTest0001::testLinkNop0001()
{
    testLinkNoOperand0001(Nop);
}

////////////////////////////////////////

void
ExecutableLinkerTest0001::testLinkEqual0001()
{
    testLinkPrimitive20001(Equal);
}

void
ExecutableLinkerTest0001::testLinkAddInt0001()
{
    testLinkPrimitive20001(AddInt);
}

void
ExecutableLinkerTest0001::testLinkAddReal0001()
{
    testLinkPrimitive20001(AddReal);
}

void
ExecutableLinkerTest0001::testLinkAddWord0001()
{
    testLinkPrimitive20001(AddWord);
}

void
ExecutableLinkerTest0001::testLinkSubInt0001()
{
    testLinkPrimitive20001(SubInt);
}

void
ExecutableLinkerTest0001::testLinkSubReal0001()
{
    testLinkPrimitive20001(SubReal);
}

void
ExecutableLinkerTest0001::testLinkSubWord0001()
{
    testLinkPrimitive20001(SubWord);
}

void
ExecutableLinkerTest0001::testLinkMulInt0001()
{
    testLinkPrimitive20001(MulInt);
}

void
ExecutableLinkerTest0001::testLinkMulReal0001()
{
    testLinkPrimitive20001(MulReal);
}

void
ExecutableLinkerTest0001::testLinkMulWord0001()
{
    testLinkPrimitive20001(MulWord);
}

void
ExecutableLinkerTest0001::testLinkDivInt0001()
{
    testLinkPrimitive20001(DivInt);
}

void
ExecutableLinkerTest0001::testLinkDivWord0001()
{
    testLinkPrimitive20001(DivWord);
}

void
ExecutableLinkerTest0001::testLinkDivReal0001()
{
    testLinkPrimitive20001(DivReal);
}

void
ExecutableLinkerTest0001::testLinkModInt0001()
{
    testLinkPrimitive20001(ModInt);
}

void
ExecutableLinkerTest0001::testLinkModWord0001()
{
    testLinkPrimitive20001(ModWord);
}

void
ExecutableLinkerTest0001::testLinkQuotInt0001()
{
    testLinkPrimitive20001(QuotInt);
}

void
ExecutableLinkerTest0001::testLinkRemInt0001()
{
    testLinkPrimitive20001(RemInt);
}

////////////////////

void
ExecutableLinkerTest0001::testLinkNegInt0001()
{
    testLinkPrimitive10001(NegInt);
}

void
ExecutableLinkerTest0001::testLinkNegReal0001()
{
    testLinkPrimitive10001(NegReal);
}

void
ExecutableLinkerTest0001::testLinkAbsInt0001()
{
    testLinkPrimitive10001(AbsInt);
}

void
ExecutableLinkerTest0001::testLinkAbsReal0001()
{
    testLinkPrimitive10001(AbsReal);
}

////////////////////

void
ExecutableLinkerTest0001::testLinkLtInt0001()
{
    testLinkPrimitive20001(LtInt);
}

void
ExecutableLinkerTest0001::testLinkLtReal0001()
{
    testLinkPrimitive20001(LtReal);
}

void
ExecutableLinkerTest0001::testLinkLtWord0001()
{
    testLinkPrimitive20001(LtWord);
}

void
ExecutableLinkerTest0001::testLinkLtChar0001()
{
    testLinkPrimitive20001(LtChar);
}

void
ExecutableLinkerTest0001::testLinkLtString0001()
{
    testLinkPrimitive20001(LtString);
}

void
ExecutableLinkerTest0001::testLinkGtInt0001()
{
    testLinkPrimitive20001(GtInt);
}

void
ExecutableLinkerTest0001::testLinkGtReal0001()
{
    testLinkPrimitive20001(GtReal);
}

void
ExecutableLinkerTest0001::testLinkGtWord0001()
{
    testLinkPrimitive20001(GtWord);
}

void
ExecutableLinkerTest0001::testLinkGtChar0001()
{
    testLinkPrimitive20001(GtChar);
}

void
ExecutableLinkerTest0001::testLinkGtString0001()
{
    testLinkPrimitive20001(GtString);
}

void
ExecutableLinkerTest0001::testLinkLteqInt0001()
{
    testLinkPrimitive20001(LteqInt);
}

void
ExecutableLinkerTest0001::testLinkLteqReal0001()
{
    testLinkPrimitive20001(LteqReal);
}

void
ExecutableLinkerTest0001::testLinkLteqWord0001()
{
    testLinkPrimitive20001(LteqWord);
}

void
ExecutableLinkerTest0001::testLinkLteqChar0001()
{
    testLinkPrimitive20001(LteqChar);
}

void
ExecutableLinkerTest0001::testLinkLteqString0001()
{
    testLinkPrimitive20001(LteqString);
}

void
ExecutableLinkerTest0001::testLinkGteqInt0001()
{
    testLinkPrimitive20001(GteqInt);
}

void
ExecutableLinkerTest0001::testLinkGteqReal0001()
{
    testLinkPrimitive20001(GteqReal);
}

void
ExecutableLinkerTest0001::testLinkGteqWord0001()
{
    testLinkPrimitive20001(GteqWord);
}

void
ExecutableLinkerTest0001::testLinkGteqChar0001()
{
    testLinkPrimitive20001(GteqChar);
}

void
ExecutableLinkerTest0001::testLinkGteqString0001()
{
    testLinkPrimitive20001(GteqString);
}

void
ExecutableLinkerTest0001::testLinkWord_toIntX0001()
{
    testLinkPrimitive10001(Word_toIntX);
}

void
ExecutableLinkerTest0001::testLinkWord_fromInt0001()
{
    testLinkPrimitive10001(Word_fromInt);
}

void
ExecutableLinkerTest0001::testLinkWord_andb0001()
{
    testLinkPrimitive20001(Word_andb);
}

void
ExecutableLinkerTest0001::testLinkWord_orb0001()
{
    testLinkPrimitive20001(Word_orb);
}

void
ExecutableLinkerTest0001::testLinkWord_xorb0001()
{
    testLinkPrimitive20001(Word_xorb);
}

void
ExecutableLinkerTest0001::testLinkWord_notb0001()
{
    testLinkPrimitive10001(Word_notb);
}

void
ExecutableLinkerTest0001::testLinkWord_leftShift0001()
{
    testLinkPrimitive20001(Word_leftShift);
}

void
ExecutableLinkerTest0001::testLinkWord_logicalRightShift0001()
{
    testLinkPrimitive20001(Word_logicalRightShift);
}

void
ExecutableLinkerTest0001::testLinkWord_arithmeticRightShift0001()
{
    testLinkPrimitive20001(Word_arithmeticRightShift);
}

///////////////////////////////////////////////////////////////////////////////

Executable
ExecutableLinkerTest0001::doLink(UInt32Value codeLength, UInt32Value code[])
{
    // NOTE: allocate a dynamic memory. This buffer is not released.
    // Because this is test code, memory leak can be ignored.
    UInt32Value totalLength = codeLength + 1;
    UInt32Value* buffer = 
    (UInt32Value*)ALLOCATE_MEMORY(sizeof(UInt32Value) * totalLength);
    buffer[0] = codeLength;// the first word holds the number of words of code
    COPY_MEMORY(buffer + 1, code, codeLength * sizeof(UInt32Value));

    Executable executable((littleEndian_
                           ? Executable::LittleEndian
                           : Executable::BigEndian),
                          totalLength,
                          buffer);

    ExecutableLinker linker;
    linker.process(&executable);
    return executable;
}

////////////////////////////////////////

void
ExecutableLinkerTest0001::testLinkNoOperand0001(instruction opcode)
{
    UInt32Value code[] = {
        pack1_3(opcode, 0),
    };
    Executable executable = doLink(sizeof(code)/sizeof(code[0]), code);
    assertLongsEqual(sizeof(code) / sizeof(code[0]), executable.codeWordLength);
    assertPacked1_3(executable.code[0], opcode, 0);
}

////////////////////////////////////////

const UInt32Value TESTLINK1CONSTOPERAND0001_OPERAND1 = 0x12345678;

void
ExecutableLinkerTest0001::testLink1ConstOperand0001(instruction opcode)
{
    UInt32Value code[] = {
        pack1_3(opcode, 0),
        pack4(TESTLINK1CONSTOPERAND0001_OPERAND1),
    };
    Executable executable = doLink(sizeof(code)/sizeof(code[0]), code);
    assertLongsEqual(sizeof(code) / sizeof(code[0]), executable.codeWordLength);
    assertPacked1_3(executable.code[0], opcode, 0);
    assertLongsEqual(TESTLINK1CONSTOPERAND0001_OPERAND1, executable.code[1]);
}

////////////////////////////////////////

const UInt32Value TESTLINK2CONSTOPERANDS0001_OPERAND1 = 0x12345678;
const UInt32Value TESTLINK2CONSTOPERANDS0001_OPERAND2 = 0x23456789;

void
ExecutableLinkerTest0001::testLink2ConstOperands0001(instruction opcode)
{
    UInt32Value code[] = {
        pack1_3(opcode, 0),
        pack4(TESTLINK2CONSTOPERANDS0001_OPERAND1),
        pack4(TESTLINK2CONSTOPERANDS0001_OPERAND2),
    };
    Executable executable = doLink(sizeof(code)/sizeof(code[0]), code);
    assertLongsEqual(sizeof(code) / sizeof(code[0]), executable.codeWordLength);
    assertPacked1_3(executable.code[0], opcode, 0);
    assertLongsEqual(TESTLINK2CONSTOPERANDS0001_OPERAND1, executable.code[1]);
    assertLongsEqual(TESTLINK2CONSTOPERANDS0001_OPERAND2, executable.code[2]);
}

////////////////////////////////////////

const UInt32Value TESTLINK3CONSTOPERANDS0001_OPERAND1 = 0x12345678;
const UInt32Value TESTLINK3CONSTOPERANDS0001_OPERAND2 = 0x23456789;
const UInt32Value TESTLINK3CONSTOPERANDS0001_OPERAND3 = 0x34567890;

void
ExecutableLinkerTest0001::testLink3ConstOperands0001(instruction opcode)
{
    UInt32Value code[] = {
        pack1_3(opcode, 0),
        pack4(TESTLINK3CONSTOPERANDS0001_OPERAND1),
        pack4(TESTLINK3CONSTOPERANDS0001_OPERAND2),
        pack4(TESTLINK3CONSTOPERANDS0001_OPERAND3),
    };
    Executable executable = doLink(sizeof(code)/sizeof(code[0]), code);
    assertLongsEqual(sizeof(code) / sizeof(code[0]), executable.codeWordLength);
    assertPacked1_3(executable.code[0], opcode, 0);
    assertLongsEqual(TESTLINK3CONSTOPERANDS0001_OPERAND1, executable.code[1]);
    assertLongsEqual(TESTLINK3CONSTOPERANDS0001_OPERAND2, executable.code[2]);
    assertLongsEqual(TESTLINK3CONSTOPERANDS0001_OPERAND3, executable.code[3]);
}

////////////////////////////////////////

const UInt32Value TESTLINK4CONSTOPERANDS0001_OPERAND1 = 0x12345678;
const UInt32Value TESTLINK4CONSTOPERANDS0001_OPERAND2 = 0x23456789;
const UInt32Value TESTLINK4CONSTOPERANDS0001_OPERAND3 = 0x34567890;
const UInt32Value TESTLINK4CONSTOPERANDS0001_OPERAND4 = 0x4567890A;

void
ExecutableLinkerTest0001::testLink4ConstOperands0001(instruction opcode)
{
    UInt32Value code[] = {
        pack1_3(opcode, 0),
        pack4(TESTLINK4CONSTOPERANDS0001_OPERAND1),
        pack4(TESTLINK4CONSTOPERANDS0001_OPERAND2),
        pack4(TESTLINK4CONSTOPERANDS0001_OPERAND3),
        pack4(TESTLINK4CONSTOPERANDS0001_OPERAND4),
    };
    Executable executable = doLink(sizeof(code)/sizeof(code[0]), code);
    assertLongsEqual(sizeof(code) / sizeof(code[0]), executable.codeWordLength);
    assertPacked1_3(executable.code[0], opcode, 0);
    assertLongsEqual(TESTLINK4CONSTOPERANDS0001_OPERAND1, executable.code[1]);
    assertLongsEqual(TESTLINK4CONSTOPERANDS0001_OPERAND2, executable.code[2]);
    assertLongsEqual(TESTLINK4CONSTOPERANDS0001_OPERAND3, executable.code[3]);
    assertLongsEqual(TESTLINK4CONSTOPERANDS0001_OPERAND4, executable.code[4]);
}

////////////////////////////////////////

const UInt32Value TESTLINK5CONSTOPERANDS0001_OPERAND1 = 0x12345678;
const UInt32Value TESTLINK5CONSTOPERANDS0001_OPERAND2 = 0x23456789;
const UInt32Value TESTLINK5CONSTOPERANDS0001_OPERAND3 = 0x34567890;
const UInt32Value TESTLINK5CONSTOPERANDS0001_OPERAND4 = 0x4567890A;
const UInt32Value TESTLINK5CONSTOPERANDS0001_OPERAND5 = 0x567890AB;

void
ExecutableLinkerTest0001::testLink5ConstOperands0001(instruction opcode)
{
    UInt32Value code[] = {
        pack1_3(opcode, 0),
        pack4(TESTLINK5CONSTOPERANDS0001_OPERAND1),
        pack4(TESTLINK5CONSTOPERANDS0001_OPERAND2),
        pack4(TESTLINK5CONSTOPERANDS0001_OPERAND3),
        pack4(TESTLINK5CONSTOPERANDS0001_OPERAND4),
        pack4(TESTLINK5CONSTOPERANDS0001_OPERAND5),
    };
    Executable executable = doLink(sizeof(code)/sizeof(code[0]), code);
    assertLongsEqual(sizeof(code) / sizeof(code[0]), executable.codeWordLength);
    assertPacked1_3(executable.code[0], opcode, 0);
    assertLongsEqual(TESTLINK5CONSTOPERANDS0001_OPERAND1, executable.code[1]);
    assertLongsEqual(TESTLINK5CONSTOPERANDS0001_OPERAND2, executable.code[2]);
    assertLongsEqual(TESTLINK5CONSTOPERANDS0001_OPERAND3, executable.code[3]);
    assertLongsEqual(TESTLINK5CONSTOPERANDS0001_OPERAND4, executable.code[4]);
    assertLongsEqual(TESTLINK5CONSTOPERANDS0001_OPERAND5, executable.code[5]);
}

////////////////////////////////////////

const UInt32Value TESTLINKPRIMITIVE10001_ARGENTRY = 0x12345678;
const UInt32Value TESTLINKPRIMITIVE10001_DESTINATION = 0x4567890;

void
ExecutableLinkerTest0001::testLinkPrimitive10001(instruction opcode)
{
    UInt32Value code[] = {
        pack1_3(opcode, 0),
        pack4(TESTLINKPRIMITIVE10001_ARGENTRY),
        pack4(TESTLINKPRIMITIVE10001_DESTINATION),
    };
    Executable executable = doLink(sizeof(code)/sizeof(code[0]), code);
    assertLongsEqual(sizeof(code) / sizeof(code[0]), executable.codeWordLength);
    assertPacked1_3(executable.code[0], opcode, 0);
    assertLongsEqual(TESTLINKPRIMITIVE10001_ARGENTRY, executable.code[1]);
    assertLongsEqual(TESTLINKPRIMITIVE10001_DESTINATION, executable.code[2]);
}

////////////////////////////////////////

const UInt32Value TESTLINKPRIMITIVE20001_ARGENTRY1 = 0x12345678;
const UInt32Value TESTLINKPRIMITIVE20001_ARGENTRY2 = 0x3456789;
const UInt32Value TESTLINKPRIMITIVE20001_DESTINATION = 0x4567890;

void
ExecutableLinkerTest0001::testLinkPrimitive20001(instruction opcode)
{
    UInt32Value code[] = {
        pack1_3(opcode, 0),
        pack4(TESTLINKPRIMITIVE20001_ARGENTRY1),
        pack4(TESTLINKPRIMITIVE20001_ARGENTRY2),
        pack4(TESTLINKPRIMITIVE20001_DESTINATION),
    };
    Executable executable = doLink(sizeof(code)/sizeof(code[0]), code);
    assertLongsEqual(sizeof(code) / sizeof(code[0]), executable.codeWordLength);
    assertPacked1_3(executable.code[0], opcode, 0);
    assertLongsEqual(TESTLINKPRIMITIVE20001_ARGENTRY1, executable.code[1]);
    assertLongsEqual(TESTLINKPRIMITIVE20001_ARGENTRY2, executable.code[2]);
    assertLongsEqual(TESTLINKPRIMITIVE20001_DESTINATION, executable.code[3]);
}

////////////////////////////////////////

const UInt32Value TESTLINKSWITCHATOM0001_TARGETENTRY = 0x12345678;
const UInt32Value TESTLINKSWITCHATOM0001_CASESCOUNT = 0x3;
const UInt32Value TESTLINKSWITCHATOM0001_CASE1CONST = 0x23456789;
const UInt32Value TESTLINKSWITCHATOM0001_CASE1OFFSET = 10;
const UInt32Value TESTLINKSWITCHATOM0001_CASE2CONST = 0x34567890;
const UInt32Value TESTLINKSWITCHATOM0001_CASE2OFFSET = 10;
const UInt32Value TESTLINKSWITCHATOM0001_CASE3CONST = 0x4567890A;
const UInt32Value TESTLINKSWITCHATOM0001_CASE3OFFSET = 10;
const UInt32Value TESTLINKSWITCHATOM0001_DEFAULTOFFSET = 10;

void
ExecutableLinkerTest0001::testLinkSwitchAtom0001(instruction opcode)
{
    UInt32Value code[] = {
        pack1_3(opcode, 0),
        pack4(TESTLINKSWITCHATOM0001_TARGETENTRY),
        pack4(TESTLINKSWITCHATOM0001_CASESCOUNT),
        pack4(TESTLINKSWITCHATOM0001_CASE1CONST),
        pack4(TESTLINKSWITCHATOM0001_CASE1OFFSET),
        pack4(TESTLINKSWITCHATOM0001_CASE2CONST),
        pack4(TESTLINKSWITCHATOM0001_CASE2OFFSET),
        pack4(TESTLINKSWITCHATOM0001_CASE3CONST),
        pack4(TESTLINKSWITCHATOM0001_CASE3OFFSET),
        pack4(TESTLINKSWITCHATOM0001_DEFAULTOFFSET),
        pack1_3(Nop, 0),
    };
    Executable executable = doLink(sizeof(code)/sizeof(code[0]), code);
    assertLongsEqual(sizeof(code) / sizeof(code[0]), executable.codeWordLength);
    assertPacked1_3(executable.code[0], opcode, 0);
    assertLongsEqual(TESTLINKSWITCHATOM0001_TARGETENTRY, executable.code[1]);
    assertLongsEqual(TESTLINKSWITCHATOM0001_CASESCOUNT, executable.code[2]);
    assertLongsEqual(TESTLINKSWITCHATOM0001_CASE1CONST, executable.code[3]);
    assertOffsetEqual(TESTLINKSWITCHATOM0001_CASE1OFFSET, executable.code, 4);
    assertLongsEqual(TESTLINKSWITCHATOM0001_CASE2CONST, executable.code[5]);
    assertOffsetEqual(TESTLINKSWITCHATOM0001_CASE2OFFSET, executable.code, 6);
    assertLongsEqual(TESTLINKSWITCHATOM0001_CASE3CONST, executable.code[7]);
    assertOffsetEqual(TESTLINKSWITCHATOM0001_CASE3OFFSET, executable.code, 8);
    assertOffsetEqual(TESTLINKSWITCHATOM0001_DEFAULTOFFSET,
                      executable.code,
                      9);
}

///////////////////////////////////////////////////////////////////////////////

template<class TestClass>
ExecutableLinkerTest0001::Suite<TestClass>::Suite()
{
    addTest(new TestCaller<TestClass>("testLinkLoadInt0001", &ExecutableLinkerTest0001::testLinkLoadInt0001));
    addTest(new TestCaller<TestClass>("testLinkLoadWord0001", &ExecutableLinkerTest0001::testLinkLoadWord0001));
    addTest(new TestCaller<TestClass>("testLinkLoadString0001", &ExecutableLinkerTest0001::testLinkLoadString0001));
    addTest(new TestCaller<TestClass>("testLinkLoadReal0001", &ExecutableLinkerTest0001::testLinkLoadReal0001));
    addTest(new TestCaller<TestClass>("testLinkLoadBoxedReal0001", &ExecutableLinkerTest0001::testLinkLoadBoxedReal0001));
    addTest(new TestCaller<TestClass>("testLinkLoadChar0001", &ExecutableLinkerTest0001::testLinkLoadChar0001));
    addTest(new TestCaller<TestClass>("testLinkAccess_S0001", &ExecutableLinkerTest0001::testLinkAccess_S0001));
    addTest(new TestCaller<TestClass>("testLinkAccess_D0001", &ExecutableLinkerTest0001::testLinkAccess_D0001));
    addTest(new TestCaller<TestClass>("testLinkAccess_V0001", &ExecutableLinkerTest0001::testLinkAccess_V0001));
    addTest(new TestCaller<TestClass>("testLinkAccessEnv_S0001", &ExecutableLinkerTest0001::testLinkAccessEnv_S0001));
    addTest(new TestCaller<TestClass>("testLinkAccessEnv_D0001", &ExecutableLinkerTest0001::testLinkAccessEnv_D0001));
    addTest(new TestCaller<TestClass>("testLinkAccessEnv_V0001", &ExecutableLinkerTest0001::testLinkAccessEnv_V0001));
    addTest(new TestCaller<TestClass>("testLinkAccessEnvIndirect_S0001", &ExecutableLinkerTest0001::testLinkAccessEnvIndirect_S0001));
    addTest(new TestCaller<TestClass>("testLinkAccessEnvIndirect_D0001", &ExecutableLinkerTest0001::testLinkAccessEnvIndirect_D0001));
    addTest(new TestCaller<TestClass>("testLinkAccessEnvIndirect_V0001", &ExecutableLinkerTest0001::testLinkAccessEnvIndirect_V0001));
    addTest(new TestCaller<TestClass>("testLinkGetField_S0001", &ExecutableLinkerTest0001::testLinkGetField_S0001));
    addTest(new TestCaller<TestClass>("testLinkGetField_D0001", &ExecutableLinkerTest0001::testLinkGetField_D0001));
    addTest(new TestCaller<TestClass>("testLinkGetField_V0001", &ExecutableLinkerTest0001::testLinkGetField_V0001));
    addTest(new TestCaller<TestClass>("testLinkGetFieldIndirect_S0001", &ExecutableLinkerTest0001::testLinkGetFieldIndirect_S0001));
    addTest(new TestCaller<TestClass>("testLinkGetFieldIndirect_D0001", &ExecutableLinkerTest0001::testLinkGetFieldIndirect_D0001));
    addTest(new TestCaller<TestClass>("testLinkGetFieldIndirect_V0001", &ExecutableLinkerTest0001::testLinkGetFieldIndirect_V0001));
    addTest(new TestCaller<TestClass>("testLinkSetField_S0001", &ExecutableLinkerTest0001::testLinkSetField_S0001));
    addTest(new TestCaller<TestClass>("testLinkSetField_D0001", &ExecutableLinkerTest0001::testLinkSetField_D0001));
    addTest(new TestCaller<TestClass>("testLinkSetField_V0001", &ExecutableLinkerTest0001::testLinkSetField_V0001));
    addTest(new TestCaller<TestClass>("testLinkSetFieldIndirect_S0001", &ExecutableLinkerTest0001::testLinkSetFieldIndirect_S0001));
    addTest(new TestCaller<TestClass>("testLinkSetFieldIndirect_D0001", &ExecutableLinkerTest0001::testLinkSetFieldIndirect_D0001));
    addTest(new TestCaller<TestClass>("testLinkSetFieldIndirect_V0001", &ExecutableLinkerTest0001::testLinkSetFieldIndirect_V0001));
    addTest(new TestCaller<TestClass>("testLinkCopyBlock0001", &ExecutableLinkerTest0001::testLinkCopyBlock0001));

    addTest(new TestCaller<TestClass>("testLinkGetGlobalBoxed0001", &ExecutableLinkerTest0001::testLinkGetGlobalBoxed0001));
    addTest(new TestCaller<TestClass>("testLinkSetGlobalBoxed0001", &ExecutableLinkerTest0001::testLinkSetGlobalBoxed0001));
    addTest(new TestCaller<TestClass>("testLinkGetGlobalUnboxed0001", &ExecutableLinkerTest0001::testLinkGetGlobalUnboxed0001));
    addTest(new TestCaller<TestClass>("testLinkSetGlobalUnboxed0001", &ExecutableLinkerTest0001::testLinkSetGlobalUnboxed0001));
    addTest(new TestCaller<TestClass>("testLinkGetEnv0001", &ExecutableLinkerTest0001::testLinkGetEnv0001));
    addTest(new TestCaller<TestClass>("testLinkCallPrim0001", &ExecutableLinkerTest0001::testLinkCallPrim0001));
    addTest(new TestCaller<TestClass>("ftestLinkApply_S0001", &ExecutableLinkerTest0001::testLinkApply_S0001));
    addTest(new TestCaller<TestClass>("testLinkApply_D0001", &ExecutableLinkerTest0001::testLinkApply_D0001));
    addTest(new TestCaller<TestClass>("testLinkApply_V0001", &ExecutableLinkerTest0001::testLinkApply_V0001));
    addTest(new TestCaller<TestClass>("ftestLinkTailApply_S0001", &ExecutableLinkerTest0001::testLinkTailApply_S0001));
    addTest(new TestCaller<TestClass>("testLinkTailApply_D0001", &ExecutableLinkerTest0001::testLinkTailApply_D0001));
    addTest(new TestCaller<TestClass>("testLinkTailApply_V0001", &ExecutableLinkerTest0001::testLinkTailApply_V0001));
    addTest(new TestCaller<TestClass>("testLinkCallStatic_S0001", &ExecutableLinkerTest0001::testLinkCallStatic_S0001));
    addTest(new TestCaller<TestClass>("testLinkCallStatic_D0001", &ExecutableLinkerTest0001::testLinkCallStatic_D0001));
    addTest(new TestCaller<TestClass>("testLinkCallStatic_V0001", &ExecutableLinkerTest0001::testLinkCallStatic_V0001));
    addTest(new TestCaller<TestClass>("testLinkTailCallStatic_S0001", &ExecutableLinkerTest0001::testLinkTailCallStatic_S0001));
    addTest(new TestCaller<TestClass>("testLinkTailCallStatic_D0001", &ExecutableLinkerTest0001::testLinkTailCallStatic_D0001));
    addTest(new TestCaller<TestClass>("testLinkTailCallStatic_V0001", &ExecutableLinkerTest0001::testLinkTailCallStatic_V0001));
    addTest(new TestCaller<TestClass>("testLinkMakeBlock0001", &ExecutableLinkerTest0001::testLinkMakeBlock0001));

    addTest(new TestCaller<TestClass>("testLinkMakeArray_S0001", &ExecutableLinkerTest0001::testLinkMakeArray_S0001));
    addTest(new TestCaller<TestClass>("testLinkMakeArray_D0001", &ExecutableLinkerTest0001::testLinkMakeArray_D0001));
    addTest(new TestCaller<TestClass>("testLinkMakeArray_V0001", &ExecutableLinkerTest0001::testLinkMakeArray_V0001));
    addTest(new TestCaller<TestClass>("testLinkMakeClosure0001", &ExecutableLinkerTest0001::testLinkMakeClosure0001));
    addTest(new TestCaller<TestClass>("testLinkRaise0001", &ExecutableLinkerTest0001::testLinkRaise0001));
    addTest(new TestCaller<TestClass>("testLinkPushHandler0001", &ExecutableLinkerTest0001::testLinkPushHandler0001));
    addTest(new TestCaller<TestClass>("testLinkPopHandler0001", &ExecutableLinkerTest0001::testLinkPopHandler0001));
    addTest(new TestCaller<TestClass>("testLinkSwitchInt0001", &ExecutableLinkerTest0001::testLinkSwitchInt0001));
    addTest(new TestCaller<TestClass>("testLinkSwitchWord0001", &ExecutableLinkerTest0001::testLinkSwitchWord0001));
    addTest(new TestCaller<TestClass>("testLinkSwitchChar0001", &ExecutableLinkerTest0001::testLinkSwitchChar0001));
    addTest(new TestCaller<TestClass>("testLinkSwitchString0001", &ExecutableLinkerTest0001::testLinkSwitchString0001));
    addTest(new TestCaller<TestClass>("testLinkJump0001", &ExecutableLinkerTest0001::testLinkJump0001));
    addTest(new TestCaller<TestClass>("testLinkExit0001", &ExecutableLinkerTest0001::testLinkExit0001));
    addTest(new TestCaller<TestClass>("testLinkReturn_S0001", &ExecutableLinkerTest0001::testLinkReturn_S0001));
    addTest(new TestCaller<TestClass>("testLinkReturn_D0001", &ExecutableLinkerTest0001::testLinkReturn_D0001));
    addTest(new TestCaller<TestClass>("testLinkReturn_V0001", &ExecutableLinkerTest0001::testLinkReturn_V0001));
    addTest(new TestCaller<TestClass>("testLinkFunEntry0001", &ExecutableLinkerTest0001::testLinkFunEntry0001));
    addTest(new TestCaller<TestClass>("testLinkConstString0001", &ExecutableLinkerTest0001::testLinkConstString0001));
    addTest(new TestCaller<TestClass>("testLinkNop0001", &ExecutableLinkerTest0001::testLinkNop0001));

    addTest(new TestCaller<TestClass>("testLinkEqual0001", &ExecutableLinkerTest0001::testLinkEqual0001));
    addTest(new TestCaller<TestClass>("testLinkAddInt0001", &ExecutableLinkerTest0001::testLinkAddInt0001));
    addTest(new TestCaller<TestClass>("testLinkAddReal0001", &ExecutableLinkerTest0001::testLinkAddReal0001));
    addTest(new TestCaller<TestClass>("testLinkAddWord0001", &ExecutableLinkerTest0001::testLinkAddWord0001));
    addTest(new TestCaller<TestClass>("testLinkSubInt0001", &ExecutableLinkerTest0001::testLinkSubInt0001));
    addTest(new TestCaller<TestClass>("testLinkSubReal0001", &ExecutableLinkerTest0001::testLinkSubReal0001));
    addTest(new TestCaller<TestClass>("testLinkSubWord0001", &ExecutableLinkerTest0001::testLinkSubWord0001));
    addTest(new TestCaller<TestClass>("testLinkMulInt0001", &ExecutableLinkerTest0001::testLinkMulInt0001));
    addTest(new TestCaller<TestClass>("testLinkMulReal0001", &ExecutableLinkerTest0001::testLinkMulReal0001));
    addTest(new TestCaller<TestClass>("testLinkMulWord0001", &ExecutableLinkerTest0001::testLinkMulWord0001));
    addTest(new TestCaller<TestClass>("testLinkDivInt0001", &ExecutableLinkerTest0001::testLinkDivInt0001));
    addTest(new TestCaller<TestClass>("testLinkDivWord0001", &ExecutableLinkerTest0001::testLinkDivWord0001));
    addTest(new TestCaller<TestClass>("testLinkDivReal0001", &ExecutableLinkerTest0001::testLinkDivReal0001));
    addTest(new TestCaller<TestClass>("testLinkModInt0001", &ExecutableLinkerTest0001::testLinkModInt0001));
    addTest(new TestCaller<TestClass>("testLinkModWord0001", &ExecutableLinkerTest0001::testLinkModWord0001));
    addTest(new TestCaller<TestClass>("testLinkQuotInt0001", &ExecutableLinkerTest0001::testLinkQuotInt0001));
    addTest(new TestCaller<TestClass>("testLinkRemInt0001", &ExecutableLinkerTest0001::testLinkRemInt0001));
    addTest(new TestCaller<TestClass>("testLinkNegInt0001", &ExecutableLinkerTest0001::testLinkNegInt0001));
    addTest(new TestCaller<TestClass>("testLinkNegReal0001", &ExecutableLinkerTest0001::testLinkNegReal0001));
    addTest(new TestCaller<TestClass>("testLinkAbsInt0001", &ExecutableLinkerTest0001::testLinkAbsInt0001));
    addTest(new TestCaller<TestClass>("testLinkAbsReal0001", &ExecutableLinkerTest0001::testLinkAbsReal0001));
    addTest(new TestCaller<TestClass>("testLinkLtInt0001", &ExecutableLinkerTest0001::testLinkLtInt0001));
    addTest(new TestCaller<TestClass>("testLinkLtReal0001", &ExecutableLinkerTest0001::testLinkLtReal0001));
    addTest(new TestCaller<TestClass>("testLinkLtWord0001", &ExecutableLinkerTest0001::testLinkLtWord0001));
    addTest(new TestCaller<TestClass>("testLinkLtChar0001", &ExecutableLinkerTest0001::testLinkLtChar0001));
    addTest(new TestCaller<TestClass>("testLinkLtString0001", &ExecutableLinkerTest0001::testLinkLtString0001));
    addTest(new TestCaller<TestClass>("testLinkGtInt0001", &ExecutableLinkerTest0001::testLinkGtInt0001));
    addTest(new TestCaller<TestClass>("testLinkGtReal0001", &ExecutableLinkerTest0001::testLinkGtReal0001));
    addTest(new TestCaller<TestClass>("testLinkGtWord0001", &ExecutableLinkerTest0001::testLinkGtWord0001));
    addTest(new TestCaller<TestClass>("testLinkGtChar0001", &ExecutableLinkerTest0001::testLinkGtChar0001));
    addTest(new TestCaller<TestClass>("testLinkGtString0001", &ExecutableLinkerTest0001::testLinkGtString0001));
    addTest(new TestCaller<TestClass>("testLinkLteqInt0001", &ExecutableLinkerTest0001::testLinkLteqInt0001));
    addTest(new TestCaller<TestClass>("testLinkLteqReal0001", &ExecutableLinkerTest0001::testLinkLteqReal0001));
    addTest(new TestCaller<TestClass>("testLinkLteqWord0001", &ExecutableLinkerTest0001::testLinkLteqWord0001));
    addTest(new TestCaller<TestClass>("testLinkLteqChar0001", &ExecutableLinkerTest0001::testLinkLteqChar0001));
    addTest(new TestCaller<TestClass>("testLinkLteqString0001", &ExecutableLinkerTest0001::testLinkLteqString0001));
    addTest(new TestCaller<TestClass>("testLinkGteqInt0001", &ExecutableLinkerTest0001::testLinkGteqInt0001));
    addTest(new TestCaller<TestClass>("testLinkGteqReal0001", &ExecutableLinkerTest0001::testLinkGteqReal0001));
    addTest(new TestCaller<TestClass>("testLinkGteqWord0001", &ExecutableLinkerTest0001::testLinkGteqWord0001));
    addTest(new TestCaller<TestClass>("testLinkGteqChar0001", &ExecutableLinkerTest0001::testLinkGteqChar0001));
    addTest(new TestCaller<TestClass>("testLinkGteqString0001", &ExecutableLinkerTest0001::testLinkGteqString0001));
    addTest(new TestCaller<TestClass>("testLinkWord_toIntX0001", &ExecutableLinkerTest0001::testLinkWord_toIntX0001));
    addTest(new TestCaller<TestClass>("testLinkWord_fromInt0001", &ExecutableLinkerTest0001::testLinkWord_fromInt0001));
    addTest(new TestCaller<TestClass>("testLinkWord_andb0001", &ExecutableLinkerTest0001::testLinkWord_andb0001));
    addTest(new TestCaller<TestClass>("testLinkWord_orb0001", &ExecutableLinkerTest0001::testLinkWord_orb0001));
    addTest(new TestCaller<TestClass>("testLinkWord_xorb0001", &ExecutableLinkerTest0001::testLinkWord_xorb0001));
    addTest(new TestCaller<TestClass>("testLinkWord_notb0001", &ExecutableLinkerTest0001::testLinkWord_notb0001));
    addTest(new TestCaller<TestClass>("testLinkWord_leftShift0001", &ExecutableLinkerTest0001::testLinkWord_leftShift0001));
    addTest(new TestCaller<TestClass>("testLinkWord_logicalRightShift0001", &ExecutableLinkerTest0001::testLinkWord_logicalRightShift0001));
    addTest(new TestCaller<TestClass>("testLinkWord_arithmeticRightShift0001", &ExecutableLinkerTest0001::testLinkWord_arithmeticRightShift0001));

}

///////////////////////////////////////////////////////////////////////////////

}
