(**
 * @copyright (c) 2006, Tohoku University.
 * @author OHORI Atsushi
 * @version $Id: PATTERNCALC_FORMATTER.sig,v 1.5 2006/02/28 16:11:02 kiyoshiy Exp $
 *)
signature PATTERNCALC_FORMATTER =
sig
  val plpatToString : PatternCalc.plpat -> string
  val pldecToString : PatternCalc.pdecl -> string
  val pltopdecToString : PatternCalc.pltopdec -> string
end
