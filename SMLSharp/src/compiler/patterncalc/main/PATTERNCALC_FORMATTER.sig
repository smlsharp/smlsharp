(**
 * @copyright (c) 2006, Tohoku University.
 * @author Atsushi Ohori 
 * @version $Id: PATTERNCALC_FORMATTER.sig,v 1.8 2008/08/05 14:43:59 bochao Exp $
 *)
signature PATTERNCALC_FORMATTER =
sig
  val plpatToString : PatternCalc.plpat -> string
  val pldecToString : PatternCalc.pdecl -> string
  val pltopdecToString : PatternCalc.pltopdec -> string
end
