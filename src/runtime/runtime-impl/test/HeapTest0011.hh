// HeapTest0011
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
 * Tests of garbage collection by Heap in the situations
 * where there are forward pointers.
 *
 * <p><b>purpose of this test:</b></p>
 * <p>
 * Verifies the behavior of the GC in the situations where the heap contains
 * chain of forward pointers.
 * </p>
 *
 * <p><b>variation of the GC:</b></p>
 *
 * <p>level of GC</p>
 * <ul>
 * <li>minor GC</li>
 * <li>major GC</li>
 * </ul>
 *
 * <p><b>variation of the forward pointer:</b></p>
 *
 * <p>the level of indirection of the forward pointer</p>
 * <ul>
 * <li>1</li>
 * <li>2</li>
 * </ul>
 *
 * <p>generation of the source of the chain of forward pointers</p>
 * <ul>
 * <li>younger generation</li>
 * <li>elder-from generation</li>
 * </ul>
 *
 * <p>generation of the destination of the chain of forward pointers</p>
 * <ul>
 * <li>elder-from generation</li>
 * <li>elder-to generation</li>
 * </ul>
 *
 * <p><b>supplementary comments:</b></p>
 *
 * <p><b>test cases:</b></p>
 *
 * <table border="1">
 * <caption>Test cases matrix</caption>
 * <tr>
 * <th>Case #</th>
 * <th>GC</th>
 * <th>indirection level</th>
 * <th>source of the chain</th>
 * <th>dest of the chain</th>
 * <th><pre>Younger | ElderFrom | ElderTo</pre></th>
 * </tr>
 *
 * <tr>
 * <th>0001</th>
 * <td>Minor</td>
 * <td>1</td>
 * <td>younger</td>
 * <td>elder-from</td>
 * <td><pre>    F --------> B               </pre></td>
 * </tr>
 *
 * <tr>
 * <th>0002</th>
 * <td>Major</td>
 * <td>1</td>
 * <td>younger</td>
 * <td>elder-from</td>
 * <td><pre>    F --------> B               </pre></td>
 * </tr>
 *
 * <tr>
 * <th>0003</th>
 * <td>Major</td>
 * <td>1</td>
 * <td>younger</td>
 * <td>elder-to</td>
 * <td><pre>    F --------------------> B   </pre></td>
 * </tr>
 *
 * <tr>
 * <th>0004</th>
 * <td>Major</td>
 * <td>1</td>
 * <td>elder-from</td>
 * <td>elder-to</td>
 * <td><pre>                F --------> B   </pre></td>
 * </tr>
 *
 * <tr>
 * <th>0005</th>
 * <td>Major</td>
 * <td>2</td>
 * <td>younger</td>
 * <td>elder-to</td>
 * <td><pre>    F --------> F --------> B   </pre></td>
 * </tr>
 *
 * </table>
 *
 * <p>
 * '<code>F</code>' is a block which contains a forward pointer.
 * '<code>B</code>' is a block which does not contain a forward pointer.
 * </p>
 *
 * <p><b>The detail of the test procedure:</b></p>
 *
 * <ol>
 * <li>
 *   Allocates blocks to set up the internal state of the heap so that the
 *  specified situation of forward pointers chain is realized in later GC.
 *  These allocated blocks contain two blocks (S and D). D is an atom block
 *  and the S is a pointer block which contains a pointer to the D.
 *  At the time of the GC, the rootset contains two pointers to D and S at
 *  least.
 *   The precise number, size and sequence of these allocations needed varies
 *  with each cases.(see the comments in each test cases.)
 *   </li>
 * <li>Allocates more blocks to let the heap manager invoke the specified GC.
 *   </li>
 * <li>Verifies that the field of the S points to the new location of the D.
 *   </li>
 * </ol>
 */
class HeapTest0011
    : public TestCase
{
    ////////////////////////////////////////
  private:

    ////////////////////////////////////////
  public:
    HeapTest0011(string name)
        : TestCase(name)
    {
    }

    virtual void setUp();

    virtual void tearDown();

    ////////////////////////////////////////
  public:

    /**
     * Garbage collection of Heap test case
     *
     * <p>prerequisite:</p>
     * <ul>
     * <li>level of indirection : 1</li>
     * <li>generation of the source of the forward pointers chain: younger</li>
     * <li>generation of the destination of the forward pointers chain :
     *   elder-from</li>
     * <li>level of GC : minor</li>
     * </ul>
     *
     * <p>expected result:</p>
     * <ul>
     * <li>(see above comment)</li>
     * <li>exceptions : not thrown</li>
     * </ul>
     */
    void testGC0001();

    /**
     * Garbage collection of Heap test case
     *
     * <p>The target situation can be brought about by the following sequence.
     * </p>
     * <ol>
     * <li>Allocates a block E and adds a pointer to it to the rootset.</li>
     * <li>Allocates more blocks to let the heap manager invoke minor GC,
     *   which moves the E to the elder-from generation.</li>
     * <li>Allocates the block D and stores a pointer to the D in the block E
     *   (the heap manager will add the address of this pointer to the
     *    assignments list).</li>
     * <li>Allocates the block S and stores a pointer to the D in it. Adds a
     *   pointer to the A to the rootset. </li>
     * <li>Allocates more blocks to invoke GC.
     *   In the GC, the following sequence should be performed.
     * <ol>
     * <li>At the beginning of the minor GC, the heap manager traces pointers
     *   contained in the assignments and moves the D to the elder-from
     *   generation.</li>
     * <li>Before it reaches S, the heap manager switches to the major GC.</li>
     * <li>The D is referred to by the assignments and the S. But the major GC
     *   does not trace the assignments. So, at the time when the heap manager
     *   reaches the S and traces the poitner to the D stored in the S, the D
     *   has been forwarded to the elder-from generation but is not been moved
     *   to the elder-to generation.</li>
     * </ol></li>
     * </ol>
     *
     * <p>prerequisite:</p>
     * <ul>
     * <li>level of indirection : 1</li>
     * <li>generation of the source of the forward pointers chain: younger</li>
     * <li>generation of the destination of the forward pointers chain :
     *   elder-from</li>
     * <li>level of GC : major</li>
     * </ul>
     *
     * <p>expected result:</p>
     * <ul>
     * <li>(see above comment)</li>
     * <li>exceptions : not thrown</li>
     * </ul>
     */
    void testGC0002();

    /**
     * Garbage collection of Heap test case
     *
     * <p>prerequisite:</p>
     * <ul>
     * <li>level of indirection : 1</li>
     * <li>generation of the source of the forward pointers chain: younger</li>
     * <li>generation of the destination of the forward pointers chain :
     *   elder-to</li>
     * <li>level of GC : major</li>
     * </ul>
     *
     * <p>expected result:</p>
     * <ul>
     * <li>(see above comment)</li>
     * <li>exceptions : not thrown</li>
     * </ul>
     */
    void testGC0003();

    /**
     * Garbage collection of Heap test case
     *
     * <p>prerequisite:</p>
     * <ul>
     * <li>level of indirection : 1</li>
     * <li>generation of the source of the forward pointers chain: elder-from
     *   </li>
     * <li>generation of the destination of the forward pointers chain :
     *   elder-to</li>
     * <li>level of GC : major</li>
     * </ul>
     *
     * <p>expected result:</p>
     * <ul>
     * <li>(see above comment)</li>
     * <li>exceptions : not thrown</li>
     * </ul>
     */
    void testGC0004();

    /**
     * Garbage collection of Heap test case
     *
     * <p>
     * This case verifies the behavior of the heap manager in
     * a situation where the heap manager reaches a younger block while tracing
     * a path of references, but the block has been forwarded to the elder-from
     * generation, then the manager traces the forward pointer and reaches a
     * block in the elder-from generation, but that block also has been
     * forwarded to the elder-to generation.
     * </p>
     *
     * <p>prerequisite:</p>
     * <ul>
     * <li>level of indirection : 2</li>
     * <li>generation of the source of the forward pointers chain: younger</li>
     * <li>generation of the destination of the forward pointers chain :
     *    elder-to</li>
     * <li>level of GC : major</li>
     * </ul>
     *
     * <p>expected result:</p>
     * <ul>
     * <li>(see above comment)</li>
     * <li>exceptions : not thrown</li>
     * </ul>
     */
    void testGC0005();

    class Suite;
};

class HeapTest0011::Suite
    : public TestSuite
{
    ////////////////////////////////////////
  public:
    Suite();
};

///////////////////////////////////////////////////////////////////////////////

}
