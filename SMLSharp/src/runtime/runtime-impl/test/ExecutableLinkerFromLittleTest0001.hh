#include "ExecutableLinker.hh"
#include "ExecutableLinkerTest0001.hh"

namespace jp_ac_jaist_iml_runtime
{

using std::string;

///////////////////////////////////////////////////////////////////////////////

class ExecutableLinkerFromLittleTest0001
    : public ExecutableLinkerTest0001
{
    ////////////////////////////////////////
  public:

    ExecutableLinkerFromLittleTest0001(string name)
        : ExecutableLinkerTest0001(name, true)
    {
    }

    class Suite;
};

class ExecutableLinkerFromLittleTest0001::Suite
    : public ExecutableLinkerTest0001::Suite<ExecutableLinkerFromLittleTest0001>
{
    ////////////////////////////////////////
  public:
    Suite();
};

///////////////////////////////////////////////////////////////////////////////

}
