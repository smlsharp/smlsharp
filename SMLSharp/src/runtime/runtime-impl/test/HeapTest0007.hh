// HeapTest0007
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
 * Tests of garbage collection of Heap
 *
 * <p><strong><em>
 * These cases are not implemente because included in Test0010.
 * </em></strong></p>
 *
 * <p>
 * These cases test GC in regard to location of a block.
 * </p>
 * <p>
 * In GC, the heap manager promotes heap blocks among generations.
 * It moves blocks from the younger generation to the elder-from generation
 * in minor GC, and from the younger and elder-from generations to the
 * elder-to generation in major GC.
 * All live blocks will be promoted to the elder-to generation finally, and
 * garbage blocks (= blocks not referred to by the roots directly nor
 * indirectly) will not be promoted to the elder-to generation never.
 * In addition, there are two notes about the promotions by GC.
 * <ul>
 * <li>The minor GC may promote blocks which is not referred to by the global
 *   roots if these blocks are referred to by the assignments. ('assignments'
 *   is a list of pointers from elder blocks to younger blocks.)</li>
 * <li>When switched to the major GC, the younger generation may contain
 *   some live blocks which had been to be promoted to the elder-from
 *   generation if the minor GC continued.</li>
 * </ul>
 * </p>
 *
 * <p><b>variation of the referene to the block from the rootset:</b></p>
 *
 * <ul>
 * <li>direct reference</li>
 * <li>indirect reference</li>
 * </ul>
 *
 * <p><b>variation of the generation to which the block belongs:</b></p>
 *
 * <p>before Minor GC</p>
 * <ul>
 * <li>younger</li>
 * <li>elder-from</li>
 * </ul>
 *
 * <p>before Major GC</p>
 * <ul>
 * <li>younger</li>
 * <li>elder-from</li>
 * </ul>
 *
 * <p>after Major GC</p>
 * <ul>
 * <li>younger</li>
 * <li>elder-from</li>
 * <li>elder-to</li>
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
 * <th>from the rootset</th>
 * <th>before Minor GC</th>
 * <th>before Major GC</th>
 * <th>after Major GC</th>
 * <th>comment</th>
 * </tr>
 *
 * <tr>
 * <td>0001</td>
 * <td>-</td>
 * <td>younger</td>
 * <td>younger</td>
 * <td>younger</td>
 * <td>garbage</td>
 * </tr>
 *
 * <tr>
 * <td>-</td>
 * <td>direct/indirect</td>
 * <td>younger</td>
 * <td>younger</td>
 * <td>elder-from</td>
 * <td>impossible</td>
 * </tr>
 *
 * <tr>
 * <td>0002/0008</td>
 * <td>direct/indirect</td>
 * <td>younger</td>
 * <td>younger</td>
 * <td>elder-to</td>
 * <td><br></td>
 * </tr>
 *
 * <tr>
 * <td>-</td>
 * <td>direct/indirect</td>
 * <td>younger</td>
 * <td>elder-from</td>
 * <td>younger</td>
 * <td>impossible</td>
 * </tr>
 *
 * <tr>
 * <td>0003</td>
 * <td>-</td>
 * <td>younger</td>
 * <td>elder-from</td>
 * <td>elder-from</td>
 * <td>garbage</td>
 * </tr>
 *
 * <tr>
 * <td>0004/0010</td>
 * <td>direct/indirect</td>
 * <td>younger</td>
 * <td>elder-from</td>
 * <td>elder-to</td>
 * <td><br></td>
 * </tr>
 *
 * <tr>
 * <td>-</td>
 * <td>direct/indirect</td>
 * <td>elder-from</td>
 * <td>younger</td>
 * <td>younger</td>
 * <td>impossible</td>
 * </tr>
 *
 * <tr>
 * <td>-</td>
 * <td>direct/indirect</td>
 * <td>elder-from</td>
 * <td>younger</td>
 * <td>elder-from</td>
 * <td>impossible</td>
 * </tr>
 *
 * <tr>
 * <td>-</td>
 * <td>direct/indirect</td>
 * <td>elder-from</td>
 * <td>younger</td>
 * <td>elder-to</td>
 * <td>impossible</td>
 * </tr>
 *
 * <tr>
 * <td>-</td>
 * <td>direct/indirect</td>
 * <td>elder-from</td>
 * <td>elder-from</td>
 * <td>younger</td>
 * <td>impossible</td>
 * </tr>
 *
 * <tr>
 * <td>0005</td>
 * <td>-</td>
 * <td>elder-from</td>
 * <td>elder-from</td>
 * <td>elder-from</td>
 * <td>garbage</td>
 * </tr>
 *
 * <tr>
 * <td>0006/0012</td>
 * <td>direct/indirect</td>
 * <td>elder-from</td>
 * <td>elder-from</td>
 * <td>elder-to</td>
 * <td><br></td>
 * </tr>
 * </table>
 * 
 * <p><b>The detail of the test procedure:</b></p>
 *
 * <dl>
 * <dt>case 0001</dt>
 * <dd>
 *   <ol>
 *   <li>Allocates an POINTER block (= B) of 1 field.</li>
 *   <li>Allocates more blocks sufficient to let the heap manager start major
 *      GC.</li>
 *   <li>If the GC reaches at B and traces the contents of B mistakenly,
 *     a certain exception should occur.</li>
 *   </ol>
 * </dd>
 * <dt>:</dt>
 * <dd>:</dd>
 * </dl>
 */
class HeapTest0007
    : public TestCase
{
    ////////////////////////////////////////
  private:

    ////////////////////////////////////////
  public:
    HeapTest0007(string name)
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
     * <p></p>
     *
     * <p>prerequisite</p>
     * <ul>
     * <li>GC : none</li>
     * </ul>
     *
     * <p>expected result</p>
     * <ul>
     * <li>exceptions : not thrown</li>
     * </ul>
     */
    void testGC0001();

    class Suite;
};

class HeapTest0007::Suite
    : public TestSuite
{
    ////////////////////////////////////////
  public:
    Suite();
};

///////////////////////////////////////////////////////////////////////////////

}
