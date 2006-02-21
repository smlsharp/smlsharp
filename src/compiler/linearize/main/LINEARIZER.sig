(**
 * Copyright (c) 2006, Tohoku University.
 *
 * translates an expression of untyped bitmap calc into sequences of symbolic
 * instructions.
 * <p>
 *  Backend of compiler performs translation from an abstract syntax
 * tree to a sequence of primitive operations. 
 * In this translation, the time and spatial details of evaluation are made
 * explicit.
 * <dl>
 * <dt>Time</dt>
 * <dd>the order of evaluation is fixed by translation to A-normal form. </dd>
 * <dt>Space</dt>
 * <dd>the location where results of evaluation are stored and the
 * location where codes are laid are determined by translations
 * which this module and assembler perform.</dd>
 * </dl>
 * </p>
 * <p>
 * The translation which made spatial detail explicit consists of two phases.
 * The first phase, linearize, translates an expression of bitmapcalculus to a
 * sequence of symbolic instructions. The target of this phase is
 * 'symbolic' in the sense that entities(= code block and location in
 * memory) are referred to by symbol(= label and name).
 * The second phase, assemble, translates these symbols to less abstracted
 * representations.
 * </p>
 *
 * <hr>
 * <h3>innermost, result, tail expressions</h3>
 * <p>
 * There defines three terms denoting subsets of A-normal
 * expressions with structured exception handling.
 * The linearizer translates expressions of these classes into different code.
 * </p>
 *
 * <dl>
 * 
 * <dt>innermost expression</dt>
 * <dd>"innermost expression" is an expression which has no non-atom
 * expression as its sub expression, and itself is not sub expression
 * of other innermost expression.
 * For example, a function call is innermost because, in the A-normal
 * form, its every argument is atom and it can not occur as an
 * argument of other expression.
 * It is to be noted that an atom expression is necessarily not
 * innermost expression.
 * On the other hand, a local variable access can be innermost or be
 * not innermost because it can occur as an argument of other
 * innermost expression, such as a function call.</dd>
 *
 * <dt>"result expression"</dt>
 * <dd>"result expression"is an expression whose value is returned to
 * the caller as the result of function application when evaluated
 * successfully.</dd>
 *
 * <dt>"tail expression"</dt>
 * <dd>"tail expression" is an expression, such that, once its
 * evaluation begins, other expressions in the same function are not
 * evaluated.
 * If the expression is a function call, it can be optimized as a
 * tail call.</dd>
 *
 * </dl>
 *
 * <p>There is following relation among these expressions.
 * <pre> tail expression < result expression < innermost expression</pre>
 * Here, the '<' means an usual subset relation on sets.
 * </p>
 * <p>
 * An innermost expression is not necessarily a result expression.
 * For example,
 * <pre>fn x => (1.23; 4.56)</pre>
 * '1.23' is an innermost expression, but not a result expression.
 * ('4.56' is a innermost and result expression.)
 * </p>
 * <p>
 * A result expression is not necessarily a tail expression.
 * For example,
 * <pre>fn x => (1.23 handle v => 4.56)</pre>
 * '1.23' is a result expression but not a tail expression.
 * ('4.56' is tail, and therefore, is result also.)
 * </p>
 * <p>
 * The linearizer should generate different code sequences even for
 * the same expression, depending on whether the expression is tail
 * or result or otherwise.
 * For example, a function call should be translated into a
 * TailCallStatic if tail, a CallStatic if not tail.
 * And a local variable access is translated into a Return if result,
 * into an operand of other instruction (ex. CallStatic) if not
 * innermost, and if innermost but not result, code generation can be
 * skipped.
 * </p>
 *
 * <hr>
 * <h3>detail of function invocation in runtime</h3>
 * <p>
 * Here is a description about detail of function invocation in the VM.
 * </p>
 * <h4>variables</h4>
 * <p>
 * In runtime, variables used in the function body are stored in
 * stack frame, environment block or global table.
 * </p>
 * <p>
 * Local variables and arguments are stored in stack frames. Each
 * function invocation allocates a new stack frame. A stack frame
 * consists of three area: non-pointer (= atom) values, pointer
 * values and record values. Whether each of record values is pointer
 * or non-pointer is indicated by bitmaps. Arguments are stored in
 * record values area.
 * </p>
 * <p>
 * The ENV register holds a pointer to a block(= the environment
 * block). The environment block contains values of free variables of
 * the function body. The block is passed from the caller of the
 * function.
 * </p>
 * <p>
 * The global table holds bindings introduced by top level declarations.
 * </p>
 * <p>
 * For example,
 * <pre>
 *  val x = 1
 *  val f = fn y =>
 *          let
 *            val g = fn z =>
 *                       (x, y, z)  <-- *
 *          in g 2 end
 * </pre>
 * In the body of the function bound to 'g' (indicated by '*'), the
 * value of 'x' is obtained from the global table, the value of 'y'
 * is obtained from the environment block, and the value of 'z' is
 * obtained from the stack frame.
 * </p>
 * <h4>function call instructions</h4>
 * <p>
 * Functions are invoked by either of the following two instructions.
 * </p>
 * <dl>
 * <dt>CallStatic(f, {v1, ..., vn})</dt>
 * <dd>'f' is the label of the target function which is determined in
 * compile time.
 *  '{v1, ..., vn}' are indexes of local variables in the caller's
 * stack frame which are passed as arguments to the called function.
 * </dd>
 * <dt>Apply(v)</dt>
 * <dd> 'v' is the index of a local variable which holds a pointer to a
 * closure block.
 *   The closure block contains the entry point of the target
 * function and arguments except the last one.
 * </dd>
 * </dl>
 * <p>
 * For both instructions, in addition to the arguments specified by
 * instruction operands or stored in the closure, the value on the AC
 * register is used as the last argument. And the first argument is a
 * pointer to a block which is used as the environment in the called
 * function.
 * </p>
 *
 * <h4>function prologue code</h4>
 * <p>
 * The compiler compiles the function body into a code sequence which
 * assumes that the variables are available in place. That is:
 * <ul>
 * <li>Arguments are stored in the stack frame.</li>
 * <li>The ENV register points to the environment block.</li>
 * </ul>
 * Therefore, before entering into the function body, the stack frame
 * and the ENV register must be coordinated. This coordination is
 * called 'prologue' of function. The needed work in prologue depends
 * on whether the invocation is static or non-static.
 * </p>
 * <p>
 * When invoked by CallStatic, arguments except the last one are
 * stored in the frame already. 
 * The following work must be performed in the function prologue.
 * <ul>
 * <li>copy the last argument on the AC register to the slot in the frame.</li>
 * <li>copy the first argument stored in the frame to the ENV register.</li>
 * <li>jump to the function body.</li>
 * </ul>
 * </p>
 * <p>
 * When invoked by Apply, the closure is stored in the last slot of the frame.
 * The following work must be performed in the function prologue.
 * <ul>
 * <li>copy the last argument on the AC register to the slot in the frame.</li>
 * <li>copy the arguments except the last one from the closure to the frame.
 * </li>
 * <li>copy the first argument stored in the closure to the ENV register.</li>
 * <li>jump to the function body.</li>
 * </ul>
 * </p>
 *
 * @author YAMATODANI Kiyoshi
 * @version $Id: LINEARIZER.sig,v 1.9 2006/02/18 04:59:22 ohori Exp $
 *)
signature LINEARIZER =
sig

  (**
   * translates an expression of untyped bitmap calc into sequences of
   * symbolic instructions.
   * A sequence is generated for each function in the source expression.
   *)
  val linearize :
      (** the expression to be linearized *)
      ANormal.anexp ->
      {
        (** main function name *)
         mainFunctionName : SymbolicInstructions.varid,
        (** function code list *)
         functions : SymbolicInstructions.functionCode list
      }
  
  (***************************************************************************)

end
