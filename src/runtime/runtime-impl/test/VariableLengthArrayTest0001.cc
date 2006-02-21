// VariableLengthArrayTest0001
// jp_ac_jaist_iml_runtime

#include "VariableLengthArrayTest0001.hh"
#include "VariableLengthArray.hh"
#include "SystemDef.hh"

#include "TestCaller.h"

namespace jp_ac_jaist_iml_runtime
{

///////////////////////////////////////////////////////////////////////////////

void
VariableLengthArrayTest0001::setUp()
{
    // setup facades
}

void
VariableLengthArrayTest0001::tearDown()
{
    //
}

///////////////////////////////////////////////////////////////////////////////

const int TESTADD0001_BUFFERSIZE = 5;

void
VariableLengthArrayTest0001::testAdd0001()
{
    void** address = (void**)&TESTADD0001_BUFFERSIZE; // address of somewhere
    VariableLengthArray array(TESTADD0001_BUFFERSIZE);

    for(int addIndex = 0; addIndex < TESTADD0001_BUFFERSIZE + 2; addIndex += 1)
    {
        array.add(address + addIndex);
        assertLongsEqual(addIndex + 1, array.getCount());
        void** contents = array.getContents();
        for(int index = 0; index < addIndex; index += 1){
            assertLongsEqual((long)(address + index), (long)(contents[index]));
        }
    }

}

////////////////////////////////////////

const int TESTREMOVE0001_BUFFERSIZE = 7;
const int TESTREMOVE0001_ELEMENTS = 7;

void
VariableLengthArrayTest0001::testRemove0001()
{
    VariableLengthArray array(TESTREMOVE0001_BUFFERSIZE);
    
    for(int index = 0 ; index < TESTREMOVE0001_ELEMENTS ; index += 1){
        array.add((VariableLengthArray::Element)index);
    }

    // remove the last element
    array.remove(TESTREMOVE0001_ELEMENTS - 1);
    {
        assertLongsEqual(TESTREMOVE0001_ELEMENTS - 1, array.getCount());
        VariableLengthArray::Element* contents = array.getContents();
        for(int index = 0 ; index < TESTREMOVE0001_ELEMENTS - 1 ; index += 1){
            assertLongsEqual(index, (long)(contents[index]));
        }
    }
    
    // remove the first element
    array.remove(0);
    {
        assertLongsEqual(TESTREMOVE0001_ELEMENTS - 2, array.getCount());
        VariableLengthArray::Element* contents = array.getContents();
        for(int index = 0 ; index < TESTREMOVE0001_ELEMENTS - 2; index += 1){
            assertLongsEqual(index + 1, (long)(contents[index]));
        }
    }

    // remove the middle element
    array.remove(2);
    {
        assertLongsEqual(TESTREMOVE0001_ELEMENTS - 3, array.getCount());
        VariableLengthArray::Element* contents = array.getContents();
        // assert that elements before the removed element are not moved.
        for(int index = 0 ; index < 2; index += 1){
            assertLongsEqual(index + 1, (long)(contents[index]));
        }
        // assert that elements following the removed element are shifted
        // toward the front
        for(int index = 2 ; index < TESTREMOVE0001_ELEMENTS - 3; index += 1){
            assertLongsEqual(index + 2, (long)(contents[index]));
        }
    }
}

////////////////////////////////////////

void
VariableLengthArrayTest0001::testClear0001()
{
    int var1, var2, var3, var4, var5;

    VariableLengthArray array(2);

    // clear before any 'add'ition.
    array.clear();
    assertLongsEqual(0, array.getCount());

    array.add(&var1);
    assertLongsEqual((long)&var1, (long)(array.getContents()[0]));
    assertLongsEqual(1, array.getCount());

    // clear after some 'add'ition without buffer reallocation
    array.clear();
    assertLongsEqual(0, array.getCount());
    
    array.add(&var2);
    assertLongsEqual(1, array.getCount());
    assertLongsEqual((long)&var2, (long)(array.getContents()[0]));

    array.add(&var3);
    assertLongsEqual(2, array.getCount());
    assertLongsEqual((long)&var2, (long)(array.getContents()[0]));
    assertLongsEqual((long)&var3, (long)(array.getContents()[1]));

    array.add(&var4); // the buffer will be reallocated, here.
    assertLongsEqual(3, array.getCount());
    assertLongsEqual((long)&var2, (long)(array.getContents()[0]));
    assertLongsEqual((long)&var3, (long)(array.getContents()[1]));
    assertLongsEqual((long)&var4, (long)(array.getContents()[2]));

    // 'clear' after reallocation of the buffer 
    array.clear();
    assertLongsEqual(0, array.getCount());

    array.add(&var5);
    assertLongsEqual(1, array.getCount());
    assertLongsEqual((long)&var5, (long)(array.getContents()[0]));
}

///////////////////////////////////////////////////////////////////////////////

VariableLengthArrayTest0001::Suite::Suite()
{
    addTest(new TestCaller<VariableLengthArrayTest0001>
            ("testAdd0001",
             &VariableLengthArrayTest0001::testAdd0001));
    addTest(new TestCaller<VariableLengthArrayTest0001>
            ("testRemove0001",
             &VariableLengthArrayTest0001::testRemove0001));
    addTest(new TestCaller<VariableLengthArrayTest0001>
            ("testClear0001",
             &VariableLengthArrayTest0001::testClear0001));
}

///////////////////////////////////////////////////////////////////////////////

}
