(**
 * Symbolic Instruction Generator
 * @copyright (c) 2007, Tohoku University.
 * @author UENO Katsuhiro
 * @version $Id: SIGENERATOR.sig,v 1.4 2007/12/17 12:11:15 katsu Exp $
 *)
signature YASIGENERATOR = sig

  val generate
      : (GlobalIndexEnv.arrayIndex * ANormal.ty) list
           * AbstractInstruction.program
         -> SymbolicInstructions.clusterCode list

end
