(**
 * Utils of Intermediate Language
 * @copyright (c) 2006, Tohoku University.
 * @author NGUYEN Huu-Duc
 * @version $Id: ILUtils.sml,v 1.5 2008/03/11 08:53:54 katsu Exp $
 *)
structure ILUtils : ILUTILS  =
struct
  structure CT = ConstantTerm
  structure AN = ANormal 

(*
  fun newVar varKind ty =
      let
        val id = ID.generate ()
      in
        {id = id, displayName = "$" ^ (ID.toString id), ty = ty, varKind = varKind}
      end
*)

  fun defaultConstantType constant = 
      case constant of
        CT.INT value => AN.ATOM
      | CT.LARGEINT value => AN.BOXED
      | CT.WORD value => AN.ATOM
      | CT.BYTE value => AN.ATOM
      | CT.STRING value => AN.BOXED
      | CT.REAL value => if !Control.enableUnboxedFloat then AN.DOUBLE else AN.BOXED
      | CT.FLOAT value => AN.ATOM
      | CT.CHAR value => AN.ATOM
      | CT.UNIT => AN.ATOM
      | CT.NULL => AN.ATOM
        
end
