(**
 * Utility functions to manipulate the typed pattern calculus.
 * @copyright (c) 2006, Tohoku University.
 * @author OHORI Atushi
 * @version $Id: TYPEDCALCUTILS.sig,v 1.9 2008/08/05 14:44:00 bochao Exp $
 *)
signature TYPEDCALCUTILS = sig
  val getLocOfExp : TypedCalc.tpexp -> Loc.loc
  val freshInst : Types.ty * TypedCalc.tpexp -> 
                  (Types.ty * TypedCalc.tpexp) 
  val collectExnTagSetStrDecList : TypedCalc.tpstrdecl list -> ExnTagID.Set.set
  val substExnTagTopDecList : ExnTagID.id ExnTagID.Map.map
                              -> TypedCalc.tptopdecl list
                              -> TypedCalc.tptopdecl list 
end
