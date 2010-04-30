(**
 * Pretty printer of the typed pattern calculus.
 * @copyright (c) 2006, Tohoku University.
 * @author LIU Bochao
 * @version $Id: PRINTTFP.sig,v 1.6 2008/02/23 15:49:54 bochao Exp $
 *)
signature PRINTTFP = sig
  val tfpdecToString :  TypedFlatCalc.tfpdecl -> string
  val tfpTopBlockToString : TypedFlatCalc.topBlock -> string
end
