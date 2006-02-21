(**
 * Copyright (c) 2006, Tohoku University.
 *
 * @author OHORI Atsushi
 * @version $Id: PATTERNCALC_FORMATTER.sig,v 1.4 2006/02/18 04:59:25 ohori Exp $
 *)
signature PATTERNCALC_FORMATTER =
sig
  val plpatToString : PatternCalc.plpat -> string
  val pldecToString : PatternCalc.pdecl -> string
  val pltopdecToString : PatternCalc.pltopdec -> string
end
