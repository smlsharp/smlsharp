#include "Heap.hh"

namespace jp_ac_jaist_iml_runtime
{

class GCCountHeapMonitor
    :public HeapMonitor
{
    ///////////////////////////////////////////////////////////////////////////

  public:

    int minorGCCount_;
    int majorGCCount_;

    ///////////////////////////////////////////////////////////////////////////

  public:

    GCCountHeapMonitor()
        :minorGCCount_(0),
         majorGCCount_(0)
    {
    }

    ///////////////////////////////////////////////////////////////////////////

  public:

    virtual
    void afterMinorGC()
    {
        minorGCCount_ += 1;
    }
    
    virtual
    void afterMajorGC()
    {
        majorGCCount_ += 1;
    }
    
};

};
