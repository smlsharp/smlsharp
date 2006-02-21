// WordOperationsTest0001
// jp_ac_jaist_iml_runtime

#include "WordOperations.hh"

#include "TestCase.h"
#include "TestSuite.h"

using std::string;

namespace jp_ac_jaist_iml_runtime
{

///////////////////////////////////////////////////////////////////////////////

/**
 * Tests of WordOperations
 *
 * <p><b>supplementary comments:</b></p>
 *
 * <p><b>the number of test cases</b></p>
 *
 * <hr>
 *
 */
class WordOperationsTest0001
    : public TestCase
{
    ////////////////////////////////////////
  private:

    ////////////////////////////////////////
  public:
    WordOperationsTest0001(string name)
        : TestCase(name)
    {
    }

    virtual void setUp();

    virtual void tearDown();

    ////////////////////////////////////////
  public:

    /**
     * WordOperations#getSingleByte test case
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
    void testGetSingleByte0001();

    /**
     * WordOperations#getDoubleByte test case
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
    void testGetDoubleByte0001();

    /**
     * WordOperations#getTriByte test case
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
    void testGetTriByte0001();

    /**
     * WordOperations#getTriByteSigned test case
     *
     * <p>prerequisite</p>
     * <ul>
     * <li>the embedded value is positive integer.</li>
     * </ul>
     *
     * <p>expected result</p>
     * <ul>
     * <li>exceptions : not thrown</li>
     * </ul>
     */
    void testGetTriByteSigned0001();

    /**
     * WordOperations#getTriByteSigned test case
     *
     * <p>prerequisite</p>
     * <ul>
     * <li>the embedded value is negative integer.</li>
     * </ul>
     *
     * <p>expected result</p>
     * <ul>
     * <li>exceptions : not thrown</li>
     * </ul>
     */
    void testGetTriByteSigned0002();

    /**
     * WordOperations#getQuadByte test case
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
    void testGetQuadByte0001();

    /**
     * WordOperations#reverseDoubleByte test case
     *
     * <p>prerequisite</p>
     * <ul>
     * <li>the second argument : 0</li>
     * </ul>
     *
     * <p>expected result</p>
     * <ul>
     * <li>exceptions : not thrown</li>
     * </ul>
     */
    void testReverseDoubleByte0001();

    /**
     * WordOperations#reverseDoubleByte test case
     *
     * <p>prerequisite</p>
     * <ul>
     * <li>the second argument : 1</li>
     * </ul>
     *
     * <p>expected result</p>
     * <ul>
     * <li>exceptions : not thrown</li>
     * </ul>
     */
    void testReverseDoubleByte0002();

    /**
     * WordOperations#reverseTriByte test case
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
    void testReverseTriByte0001();

    /**
     * WordOperations#reverseQuadByte test case
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
    void testReverseQuadByte0001();

    /**
     * WordOperations#reverseDoubleQuadByte test case
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
    void testReverseDoubleQuadByte0001();

    class Suite;
};

class WordOperationsTest0001::Suite
    : public TestSuite
{
    ////////////////////////////////////////
  public:
    Suite();
};

///////////////////////////////////////////////////////////////////////////////

}
