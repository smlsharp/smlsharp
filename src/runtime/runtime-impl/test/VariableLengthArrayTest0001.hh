// HeapTest0005
// jp_ac_jaist_iml_runtime

#include "VariableLengthArray.hh"

#include "TestCase.h"
#include "TestSuite.h"

using std::string;

namespace jp_ac_jaist_iml_runtime
{

///////////////////////////////////////////////////////////////////////////////

/**
 * Tests of VariableLengthArray
 *
 * <p><b>variation of arguments:</b></p>
 *
 * <p><b>variation of internal state of the target object:</b></p>
 *
 * <p><b>supplementary comments:</b></p>
 *
 * <p><b>the number of test cases</b></p>
 *
 * <hr>
 *
 */
class VariableLengthArrayTest0001
    : public TestCase
{
    ////////////////////////////////////////
  private:

    ////////////////////////////////////////
  public:
    VariableLengthArrayTest0001(string name)
        : TestCase(name)
    {
    }

    virtual void setUp();

    virtual void tearDown();

    ////////////////////////////////////////
  public:

    /**
     * VariableLengthArray#add test case
     *
     * <p>specifies normal arguments, and verifies the result.</p>
     * <p>This case tests 'getCount', 'getContents' method also.</p>
     *
     * <p>prerequisite</p>
     * <ul>
     * <li>size of buffer : n</li>
     * </ul>
     *
     * <p>expected result</p>
     * <ul>
     * <li>
     *   Calls the 'add' method on the array repeatedly 'n'+2 times.
     *   At each repetition, gets the address of the contents by calling
     *  'getContent' method, and verifies that the each cell of the contents
     *  is equal to the value which has been added by the 'add' method.
     * </li>
     * <li>exceptions : not thrown</li>
     * </ul>
     */
    void testAdd0001();

    /**
     * VariableLengthArray#remove test case
     *
     * <p>specifies normal arguments, and verifies the result.</p>
     *
     * <p>prerequisite</p>
     * <ul>
     * <li>size of buffer : n</li>
     * </ul>
     *
     * <p>expected result</p>
     * <ul>
     * <li>
     *   Adds 'n' elements to the array.
     *   Calls the 'remove' method on the array 
     *   <ul>
     *     <li>last element (index is 'n - 1')</li>
     *     <li>first element (index is '0')</li>
     *     <li>middle element (index is between '1' and 'n - 2')</li>
     *   </ul>
     *   At each repetition, gets the address of the contents by calling
     *  'getContent' method, and verifies that the each cell of the contents.
     * </li>
     * <li>exceptions : not thrown</li>
     * </ul>
     */
    void testRemove0001();

    /**
     * VariableLengthArray#clear test case
     *
     * <p>specifies normal arguments, and verifies the result.</p>
     *
     * <p>prerequisite</p>
     * <ul>
     * <li>size of buffer : n</li>
     * </ul>
     *
     * <p>expected result</p>
     * <ul>
     * <li>Just after invocation of the 'clear' method, 'getCount' method
     *   returns 0.</li>
     * <li>addition elements after an invocation of the 'clear' method
     *   overwrites the previous contents of the buffer.</li>
     * <li>exceptions : not thrown</li>
     * </ul>
     */
    void testClear0001();

    class Suite;
};

class VariableLengthArrayTest0001::Suite
    : public TestSuite
{
    ////////////////////////////////////////
  public:
    Suite();
};

///////////////////////////////////////////////////////////////////////////////

}
