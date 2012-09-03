#ifndef ExecutableLinker_hh_
#define ExecutableLinker_hh_

#include "ExecutablePreProcessor.hh"
#include "WordOperations.hh"
#include "Log.hh"
#include "Debug.hh"

BEGIN_NAMESPACE(jp_ac_jaist_iml_runtime)

///////////////////////////////////////////////////////////////////////////////

/**
 *  This class modifies the code block in the executable so that the virtual
 * machine can executes it efficiently.
 *
 * The executable linker
 * <ul>
 * <li>converts the byte order of multi byte operand to native order.
 * <li>replaces operands representing the offset to some location in code block
 *    with the absolute address of that location.
 * </ul>
 */
class ExecutableLinker
    :public ExecutablePreProcessor,
     public WordOperations 
{
    ///////////////////////////////////////////////////////////////////////////
  private:

    /**
     * log writer
     */
    DBGWRAP(static LogAdaptor LOG;)

    ///////////////////////////////////////////////////////////////////////////
  public:

    /**
     * constructor
     */
    ExecutableLinker(){}

    ///////////////////////////////////////////////////////////////////////////
  public:

    static
    void getLocationOfCodeRef(Executable* executable,
                              UInt32Value offset,
                              const char** fileName,
                              UInt32Value* leftLine,
                              UInt32Value* leftCol,
                              UInt32Value* rightLine,
                              UInt32Value* rightCol);

    ///////////////////////////////////////////////////////////////////////////
    // Concretization of class ExecutablePreProcessor

  public:

    void process(Executable* executable)
        throw(IMLException);

    ///////////////////////////////////////////////////////////////////////////
  private:

    static
    void convertOffsetToAddress(UInt32Value* base, UInt32Value* PC);

    template
    <
      void toNativeOrderDouble(UInt32Value*, int),
      void toNativeOrderTri(UInt32Value*),
      void toNativeOrderQuad(UInt32Value*),
      void toNativeOrderDoubleQuad(UInt32Value*)
    >
    void
    link(Executable* executable)
        throw(IMLException);

    INLINE_FUN
    static
    void nullFunction(UInt32Value*){}

    INLINE_FUN
    static
    void nullFunctionWithIndex(UInt32Value*, int){}

};

///////////////////////////////////////////////////////////////////////////////

END_NAMESPACE

#endif // ExecutableLinker_hh_
