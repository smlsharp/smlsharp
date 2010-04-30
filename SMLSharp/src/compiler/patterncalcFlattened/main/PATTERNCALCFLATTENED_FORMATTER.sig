(**
 * @copyright (c) 2006, Tohoku University.
 * @author Liu Bochao
 * @version $Id: PATTERNCALCFLATTENED_FORMATTER.sig,v 1.4 2008/08/05 14:43:59 bochao Exp $
 *)
signature PATTERNCALCFLATTENED_FORMATTER =
sig
  val plfpatToString : PatternCalcFlattened.plfpat -> string
  val plfdecToString : PatternCalcFlattened.pdfdecl -> string
  val plftopdecToString : PatternCalcFlattened.plftopdec -> string
end
