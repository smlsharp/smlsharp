(**
 * Utils of Intermediate Language
 * @copyright (c) 2006, Tohoku University.
 * @author NGUYEN Huu-Duc
 * @version $Id: ILUtils.sml,v 1.2 2007/04/18 09:02:19 ducnh Exp $
 *)
structure ILUtils : ILUTILS  =
struct
  structure CT = ConstantTerm
  structure AN = ANormal 

  fun newVar varKind ty =
      let
        val id = ID.generate ()
      in
        {id = id, displayName = "$" ^ (ID.toString id), ty = ty, varKind = varKind}
      end

  fun defaultConstantType constant = 
      case constant of
        CT.INT value => AN.ATOM
      | CT.WORD value => AN.ATOM
      | CT.STRING value => AN.BOXED
      | CT.REAL value => if !Control.enableUnboxedFloat then AN.DOUBLE else AN.BOXED
      | CT.FLOAT value => AN.ATOM
      | CT.CHAR value => AN.ATOM
      | CT.UNIT => AN.ATOM
        
end
