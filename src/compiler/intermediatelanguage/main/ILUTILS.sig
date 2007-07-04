(**
 * Utils of Intermediate Language
 * @copyright (c) 2006, Tohoku University.
 * @author NGUYEN Huu-Duc
 * @version $Id: ILUTILS.sig,v 1.2 2007/04/18 09:02:19 ducnh Exp $
 *)
signature ILUTILS  =
sig

  val newVar : IntermediateLanguage.varKind -> IntermediateLanguage.ty -> IntermediateLanguage.varInfo

  val defaultConstantType : ConstantTerm.constant -> IntermediateLanguage.ty
        
end
