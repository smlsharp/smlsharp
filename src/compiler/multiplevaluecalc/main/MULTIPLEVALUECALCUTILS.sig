(**
 * @copyright (c) 2006, Tohoku University.
 * @author Huu-Duc Nguyen 
 * @version $Id: MULTIPLEVALUECALCUTILS.sig,v 1.6 2007/11/16 04:01:55 bochao Exp $
 *)
signature MULTIPLEVALUECALCUTILS = sig

  val getLocOfExp : MultipleValueCalc.mvexp -> MultipleValueCalc.loc
(*
  val substExp : AnnotatedTypes.ty BoundTypeVarID.Map.map -> MultipleValueCalc.mvexp -> MultipleValueCalc.mvexp

  val substVarInfo : AnnotatedTypes.ty BoundTypeVarID.Map.map -> MultipleValueCalc.varInfo ->  MultipleValueCalc.varInfo
*)
end
