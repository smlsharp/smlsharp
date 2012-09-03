(**
 * Utils of Intermediate Language
 * @copyright (c) 2006, Tohoku University.
 * @author NGUYEN Huu-Duc
 * @version $Id: ILUTILS.sig,v 1.3 2007/12/15 08:30:34 bochao Exp $
 *)
signature ILUTILS  =
sig

(*  val newVar : IntermediateLanguage.varKind -> IntermediateLanguage.ty -> IntermediateLanguage.varInfo *)

  val defaultConstantType : ConstantTerm.constant -> IntermediateLanguage.ty
        
end
