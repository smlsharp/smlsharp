(**
 * Typed-Directed Polymorohic Record Compilation.
 * @copyright (c) 2006, Tohoku University.
 * @author Atsushi Ohori 
 * @version $Id: RECORD_COMPILER.sig,v 1.3 2006/02/28 16:11:04 kiyoshiy Exp $
 *)
signature RECORD_COMPILER =
sig

  val compile : RecordCalc.rcdecl list -> TypedLambda.tldecl list

end
