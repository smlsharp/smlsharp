(**
 * Copyright (c) 2006, Tohoku University.
 *
 * Utility functions to manipulate the typed pattern calculus.
 * @author OHORI Atushi
 * @version $Id: TYPEDCALCUTILS.sig,v 1.2 2006/02/18 04:59:31 ohori Exp $
 *)
signature TYPEDCALCUTILS = sig
  val getLocOfExp : TypedCalc.tpexp -> Loc.loc
  val freshInst : Types.ty * TypedCalc.tpexp -> Types.ty * TypedCalc.tpexp
end
