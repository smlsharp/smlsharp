(**
 * Utility functions to manipulate the typed pattern calculus.
 * @copyright (c) 2006, Tohoku University.
 * @author OHORI Atushi
 * @version $Id: TYPEDCALCUTILS.sig,v 1.3 2006/02/28 16:11:07 kiyoshiy Exp $
 *)
signature TYPEDCALCUTILS = sig
  val getLocOfExp : TypedCalc.tpexp -> Loc.loc
  val freshInst : Types.ty * TypedCalc.tpexp -> Types.ty * TypedCalc.tpexp
end
