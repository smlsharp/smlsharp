(**
 * Copyright (c) 2006, Tohoku University.
 *
 * Typed-Directed Polymorohic Record Compilation.
 * @author Atsushi Ohori 
 * @version $Id: RECORD_COMPILER.sig,v 1.2 2006/02/18 04:59:26 ohori Exp $
 *)
signature RECORD_COMPILER =
sig

  val compile : RecordCalc.rcdecl list -> TypedLambda.tldecl list

end
