#include "ExecutableLinker.hh"
#include "ExecutableLinkerTest0001.hh"

namespace jp_ac_jaist_iml_runtime
{

using std::string;

///////////////////////////////////////////////////////////////////////////////

class ExecutableLinkerFromBigTest0001
    : public ExecutableLinkerTest0001
{
    ////////////////////////////////////////
  public:

    ExecutableLinkerFromBigTest0001(string name)
        : ExecutableLinkerTest0001(name, true)
    {
    }

    class Suite;
};

class ExecutableLinkerFromBigTest0001::Suite
    : public ExecutableLinkerTest0001::Suite<ExecutableLinkerFromBigTest0001>
{
    ////////////////////////////////////////
  public:
    Suite();
};

///////////////////////////////////////////////////////////////////////////////

}
