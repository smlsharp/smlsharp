// WordOperationsTest0001
// jp_ac_jaist_iml_runtime

#include "WordOperationsTest0001.hh"
#include "WordOperations.hh"
#include "SystemDef.hh"

#include "TestCaller.h"

namespace jp_ac_jaist_iml_runtime
{

///////////////////////////////////////////////////////////////////////////////

void
WordOperationsTest0001::setUp()
{
    // setup facades
}

void
WordOperationsTest0001::tearDown()
{
    //
}

///////////////////////////////////////////////////////////////////////////////

const UInt8Value TESTGETSINGLEBYTE0001_VALUES[] = {
    0x1, 0x2, 0x3, 0x4,
};

void
WordOperationsTest0001::testGetSingleByte0001()
{
    UInt32Value* words = (UInt32Value*)TESTGETSINGLEBYTE0001_VALUES;
    assertLongsEqual(TESTGETSINGLEBYTE0001_VALUES[0],
                     WordOperations::getSingleByte(words, 0));
    assertLongsEqual(TESTGETSINGLEBYTE0001_VALUES[1],
                     WordOperations::getSingleByte(words, 1));
    assertLongsEqual(TESTGETSINGLEBYTE0001_VALUES[2],
                     WordOperations::getSingleByte(words, 2));
    assertLongsEqual(TESTGETSINGLEBYTE0001_VALUES[3],
                     WordOperations::getSingleByte(words, 3));
}

////////////////////////////////////////

const UInt16Value TESTGETDOUBLEBYTE0001_VALUES[] = {
    0x1234, 0xABCD,
};

void
WordOperationsTest0001::testGetDoubleByte0001()
{
    UInt32Value* words = (UInt32Value*)TESTGETDOUBLEBYTE0001_VALUES;
    assertLongsEqual(TESTGETDOUBLEBYTE0001_VALUES[0],
                     WordOperations::getDoubleByte(words, 0));
    assertLongsEqual(TESTGETDOUBLEBYTE0001_VALUES[1],
                     WordOperations::getDoubleByte(words, 1));
}

////////////////////////////////////////

const UInt8Value TESTGETTRIBYTE0001_VALUES[] = {
    0x01, 0x23, 0x45, 0x67,
};

#if defined(BYTE_ORDER_BIG_ENDIAN)
const UInt32Value TESTGETTRIBYTE0001_EXPECTEDRESULT = 0x234567;
#elif defined(BYTE_ORDER_LITTLE_ENDIAN)
const UInt32Value TESTGETTRIBYTE0001_EXPECTEDRESULT = 0x674523l;
#endif

void
WordOperationsTest0001::testGetTriByte0001()
{
    UInt32Value* words = (UInt32Value*)TESTGETTRIBYTE0001_VALUES;
    UInt32Value result = WordOperations::getTriByte(words);
    assertLongsEqual(TESTGETTRIBYTE0001_EXPECTEDRESULT, result);
}

////////////////////////////////////////

const UInt8Value TESTGETTRIBYTESIGNED0001_VALUES[] = {
    0x01, 0x23, 0x45, 0x67,
};

#if defined(BYTE_ORDER_BIG_ENDIAN)
const SInt32Value TESTGETTRIBYTESIGNED0001_EXPECTEDRESULT = 0x234567;
#elif defined(BYTE_ORDER_LITTLE_ENDIAN)
const SInt32Value TESTGETTRIBYTESIGNED0001_EXPECTEDRESULT = 0x674523;
#endif

void
WordOperationsTest0001::testGetTriByteSigned0001()
{
    UInt32Value* words = (UInt32Value*)TESTGETTRIBYTESIGNED0001_VALUES;
    SInt32Value result = WordOperations::getTriByteSigned(words);
    assertLongsEqual(TESTGETTRIBYTESIGNED0001_EXPECTEDRESULT, result);
}

////////////////////////////////////////

const UInt8Value TESTGETTRIBYTESIGNED0002_VALUES[] = {
    0x01, 0xFC, 0xFB, 0xFA
};

#if defined(BYTE_ORDER_BIG_ENDIAN)
const SInt32Value TESTGETTRIBYTESIGNED0002_EXPECTEDRESULT = 0xFFFCFBFA;
#elif defined(BYTE_ORDER_LITTLE_ENDIAN)
const SInt32Value TESTGETTRIBYTESIGNED0002_EXPECTEDRESULT = 0xFFFAFBFC;
#endif

void
WordOperationsTest0001::testGetTriByteSigned0002()
{
    UInt32Value* words = (UInt32Value*)TESTGETTRIBYTESIGNED0002_VALUES;
    SInt32Value result = WordOperations::getTriByteSigned(words);
    assertLongsEqual(TESTGETTRIBYTESIGNED0002_EXPECTEDRESULT, result);
}

////////////////////////////////////////

const UInt8Value TESTGETQUADBYTE0001_VALUES[] = {
    0x01, 0x23, 0x45, 0x67,
};

#if defined(BYTE_ORDER_BIG_ENDIAN)
const UInt32Value TESTGETQUADBYTE0001_EXPECTEDRESULT = 0x01234567;
#elif defined(BYTE_ORDER_LITTLE_ENDIAN)
const UInt32Value TESTGETQUADBYTE0001_EXPECTEDRESULT = 0x67452301;
#endif

void
WordOperationsTest0001::testGetQuadByte0001()
{
    UInt32Value* words = (UInt32Value*)TESTGETQUADBYTE0001_VALUES;
    SInt32Value result = WordOperations::getQuadByte(words);
    assertLongsEqual(TESTGETQUADBYTE0001_EXPECTEDRESULT, result);
}

////////////////////////////////////////

UInt8Value TESTREVERSEDOUBLEBYTE0001_VALUES[] = {
    0x01, 0x23, 0x45, 0x67,
};

#if defined(BYTE_ORDER_BIG_ENDIAN)
const UInt32Value TESTREVERSEDOUBLEBYTE0001_EXPECTEDRESULT = 0x23014567;
#elif defined(BYTE_ORDER_LITTLE_ENDIAN)
const UInt32Value TESTREVERSEDOUBLEBYTE0001_EXPECTEDRESULT = 0x67450123;
#endif

void
WordOperationsTest0001::testReverseDoubleByte0001()
{
    UInt32Value* words = (UInt32Value*)TESTREVERSEDOUBLEBYTE0001_VALUES;
    WordOperations::reverseDoubleByte(words, 0);
    assertLongsEqual(TESTREVERSEDOUBLEBYTE0001_EXPECTEDRESULT, *words);
}

////////////////////////////////////////

UInt8Value TESTREVERSEDOUBLEBYTE0002_VALUES[] = {
    0x01, 0x23, 0x45, 0x67,
};

#if defined(BYTE_ORDER_BIG_ENDIAN)
const UInt32Value TESTREVERSEDOUBLEBYTE0002_EXPECTEDRESULT = 0x01236745;
#elif defined(BYTE_ORDER_LITTLE_ENDIAN)
const UInt32Value TESTREVERSEDOUBLEBYTE0002_EXPECTEDRESULT = 0x45672301;
#endif

void
WordOperationsTest0001::testReverseDoubleByte0002()
{
    UInt32Value* words = (UInt32Value*)TESTREVERSEDOUBLEBYTE0002_VALUES;
    WordOperations::reverseDoubleByte(words, 1);
    assertLongsEqual(TESTREVERSEDOUBLEBYTE0002_EXPECTEDRESULT, *words);
}

////////////////////////////////////////

UInt8Value TESTREVERSETRIBYTE0001_VALUES[] = {
    0x01, 0x23, 0x45, 0x67,
};

#if defined(BYTE_ORDER_BIG_ENDIAN)
const UInt32Value TESTREVERSETRIBYTE0001_EXPECTEDRESULT = 0x01674523;
#elif defined(BYTE_ORDER_LITTLE_ENDIAN)
const UInt32Value TESTREVERSETRIBYTE0001_EXPECTEDRESULT = 0x23456701;
#endif

void
WordOperationsTest0001::testReverseTriByte0001()
{
    UInt32Value* words = (UInt32Value*)TESTREVERSETRIBYTE0001_VALUES;
    WordOperations::reverseTriByte(words);
    assertLongsEqual(TESTREVERSETRIBYTE0001_EXPECTEDRESULT, *words);
}

////////////////////////////////////////

UInt8Value TESTREVERSEQUADBYTE0001_VALUES[] = {
    0x01, 0x23, 0x45, 0x67,
};

#if defined(BYTE_ORDER_BIG_ENDIAN)
const UInt32Value TESTREVERSEQUADBYTE0001_EXPECTEDRESULT = 0x67452301;
#elif defined(BYTE_ORDER_LITTLE_ENDIAN)
const UInt32Value TESTREVERSEQUADBYTE0001_EXPECTEDRESULT = 0x01234567;
#endif

void
WordOperationsTest0001::testReverseQuadByte0001()
{
    UInt32Value* words = (UInt32Value*)TESTREVERSEQUADBYTE0001_VALUES;
    WordOperations::reverseQuadByte(words);
    assertLongsEqual(TESTREVERSEQUADBYTE0001_EXPECTEDRESULT, *words);
}

////////////////////////////////////////

UInt8Value TESTREVERSEDOUBLEQUADBYTE0001_VALUES[] = {
    0x01, 0x23, 0x45, 0x67,
    0x89, 0xAB, 0xCD, 0xEF,
};

const UInt8Value TESTREVERSEDOUBLEQUADBYTE0001_EXPECTEDRESULT[] = {
    0xEF, 0xCD, 0xAB, 0x89,
    0x67, 0x45, 0x23, 0x01
};

void
WordOperationsTest0001::testReverseDoubleQuadByte0001()
{
    UInt8Value* bytes = TESTREVERSEDOUBLEQUADBYTE0001_VALUES;
    WordOperations::reverseDoubleQuadByte((UInt32Value*)bytes);
    for(int index = 0 ;
        index < sizeof(TESTREVERSEDOUBLEQUADBYTE0001_EXPECTEDRESULT) ;
        index += 1)
    {
        assertLongsEqual(TESTREVERSEDOUBLEQUADBYTE0001_EXPECTEDRESULT[index],
                         bytes[index]);
    }
}

///////////////////////////////////////////////////////////////////////////////

WordOperationsTest0001::Suite::Suite()
{
    addTest(new TestCaller<WordOperationsTest0001>
            ("testGetSingleByte0001",
             &WordOperationsTest0001::testGetSingleByte0001));
    addTest(new TestCaller<WordOperationsTest0001>
            ("testGetDoubleByte0001",
             &WordOperationsTest0001::testGetDoubleByte0001));
    addTest(new TestCaller<WordOperationsTest0001>
            ("testGetTriByte0001",
             &WordOperationsTest0001::testGetTriByte0001));
    addTest(new TestCaller<WordOperationsTest0001>
            ("testGetTriByteSigned0001",
             &WordOperationsTest0001::testGetTriByteSigned0001));
    addTest(new TestCaller<WordOperationsTest0001>
            ("testGetTriByteSigned0002",
             &WordOperationsTest0001::testGetTriByteSigned0002));
    addTest(new TestCaller<WordOperationsTest0001>
            ("testGetQuadByte0001",
             &WordOperationsTest0001::testGetQuadByte0001));
    addTest(new TestCaller<WordOperationsTest0001>
            ("testReverseDoubleByte0001",
             &WordOperationsTest0001::testReverseDoubleByte0001));
    addTest(new TestCaller<WordOperationsTest0001>
            ("testReverseDoubleByte0002",
             &WordOperationsTest0001::testReverseDoubleByte0002));
    addTest(new TestCaller<WordOperationsTest0001>
            ("testReverseTriByte0001",
             &WordOperationsTest0001::testReverseTriByte0001));
    addTest(new TestCaller<WordOperationsTest0001>
            ("testReverseQuadByte0001",
             &WordOperationsTest0001::testReverseQuadByte0001));
    addTest(new TestCaller<WordOperationsTest0001>
            ("testReverseDoubleQuadByte0001",
             &WordOperationsTest0001::testReverseDoubleQuadByte0001));
}

///////////////////////////////////////////////////////////////////////////////

}
