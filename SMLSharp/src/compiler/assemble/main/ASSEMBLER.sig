(**
 *  This signature specifies the interface of the module which provides the
 * functionality of translating instructions with symbolic references into
 * instructions in lower level representation.
 * <p>
 * The assemle phase performs the following three tasks.
 * </p>
 * <p>
 * Slot allocation:
 * In the symbolic bytecode, local variables are referred to by their names.
 * In this assemble phase, those variable names are transformed to
 * indexes of slots in a stack frame. It should optimize so that
 * multiple variables are mapped to the same slot if they have same
 * type (= pointer/non-pointer) and their scope do not overlap.
 * </p>
 * <p>
 * Label resolution:
 * Targets of jump/call instruction specified by labels are transformed to
 * relative offset or absolute address.
 * </p>
 * <p>
 * Bitmap width adjustment (not implemented):
 * In the symbolic bytecode the first phase generates, bitmap vector
 * can have any bit width. Implementation detail of runtime is hidden
 * in that phase.
 *  Assume that maximum bit width of bitmap values in runtime is 32
 * bits. Expressions which generate bitmap of more than 32 bits are
 * transformed so that generated bitmap fits within 32 bit width.
 * </p>
 *
 * @copyright (c) 2006, Tohoku University.
 * @author YAMATODANI Kiyoshi
 * @version $Id: ASSEMBLER.sig,v 1.10 2007/12/15 08:30:34 bochao Exp $
 *)
signature ASSEMBLER =
sig

  (***************************************************************************)

  (**
   *  Translate symolic instructions to raw instructions
   *
   * @params {mainFunctionName, functions}
   * @param mainFunctionName the name of the main function. Other functions
   *                   are called directly or indirectly from this function.
   * @param functions a list of pairs of function information and
   *                      symbolic instructions of the body of the function
   * @return a list of raw instructions
   *)
  val assemble :
      SymbolicInstructions.clusterCode list -> Executable.executable
                                               
  (***************************************************************************)

end
