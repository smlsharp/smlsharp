// VirtualMachineTest0006
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
 *  Lets the VM execute instructions and verifies that the VM correctly process
 * user exception and exception handlers.
 * </p>
 *
 * <p><b>the variety of instruction</b></p>
 *
 * <p>
 *  This test class targets Raise, PushHandler and PopHandler.
 * </p>
 *
 * <p><b>supplementary comments:</b></p>
 *
 * <p><b>test cases:</b></p>
 *
 * <table border="1">
 * <caption>Test cases matrix</caption>
 * <tr>
 * <th>Case Index</th>
 * <th>Raise expression exists</th>
 * <th>handler exists</th>
 * <th>comment</th>
 * </tr>
 *
 * <tr><td>0001</td><td>no</td><td>yes</td><td>&nbsp;</td></tr>
 * <tr><td>0002</td><td>yes</td><td>no</td><td>&nbsp;</td></tr>
 * <tr>
 *   <td>0003</td>
 *   <td>yes</td>
 *   <td>yes</td>
 *   <td>exception is caught by handler</td>
 * </tr>
 * <tr>
 *   <td>0004</td>
 *   <td>yes</td>
 *   <td>yes</td>
 *   <td>exception is raised in handler</td>
 * </tr>
 * <tr>
 *   <td>0005</td>
 *   <td>yes</td>
 *   <td>yes</td>
 *   <td>exception is raised after handler</td>
 * </tr>
 *
 * </table>
 *
 */
class VirtualMachineTest0006
    : public TestCase
{
    ////////////////////////////////////////
  private:

    ////////////////////////////////////////
  public:
    VirtualMachineTest0006(string name)
        : TestCase(name)
    {
    }

    virtual void setUp();

    virtual void tearDown();

    ////////////////////////////////////////
  public:

    /**
     * tests user exception handling in runtime.
     *
     * <p>prerequisite</p>
     * <ul>
     * <li>exception : not raised</li>
     * <li>handler : eixsts</li>
     * <li>GC : not occurrs</li>
     * </ul>
     *
     * <p>expected result</p>
     * <ul>
     *   <li>no exception thrown</li>
     * </ul>
     */
    void testException0001();

    /**
     * tests user exception handling in runtime.
     *
     * <p>prerequisite</p>
     * <ul>
     * <li>exception : raised</li>
     * <li>handler : not eixst</li>
     * <li>GC : not occurrs</li>
     * </ul>
     *
     * <p>expected result</p>
     * <ul>
     *   <li>no exception thrown</li>
     * </ul>
     */
    void testException0002();

    /**
     * tests user exception handling in runtime.
     *
     * <p>prerequisite</p>
     * <ul>
     * <li>exception : raised</li>
     * <li>handler : eixsts</li>
     * <li>exception is caught by handler.</li>
     * <li>GC : not occurrs</li>
     * </ul>
     *
     * <p>expected result</p>
     * <ul>
     *   <li>no exception thrown</li>
     * </ul>
     */
    void testException0003();

    /**
     * tests user exception handling in runtime.
     *
     * <p>prerequisite</p>
     * <ul>
     * <li>exception : two exceptions are raised</li>
     * <li>handler : eixsts</li>
     * <li>an exception is raised in handler.</li>
     * <li>GC : not occurrs</li>
     * </ul>
     *
     * <p>expected result</p>
     * <ul>
     *   <li>UsreException is thrown</li>
     * </ul>
     */
    void testException0004();

    /**
     * tests user exception handling in runtime.
     *
     * <p>prerequisite</p>
     * <ul>
     * <li>exception : raised</li>
     * <li>handler : eixsts</li>
     * <li>exception is raised after handler.</li>
     * <li>GC : not occurrs</li>
     * </ul>
     *
     * <p>expected result</p>
     * <ul>
     *   <li>UserException is thrown</li>
     * </ul>
     */
    void testException0005();

    class Suite;

};

class VirtualMachineTest0006::Suite
    : public TestSuite
{
    ////////////////////////////////////////
  public:
    Suite();
};

///////////////////////////////////////////////////////////////////////////////

}
