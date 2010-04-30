(**
 * match compiler.
 * @copyright (c) 2006, Tohoku University.
 * @author OSAKA Satoshi
 * @version $Id: MATCH_COMPILER.sig,v 1.11 2008/06/09 03:16:07 ohori Exp $
 *)
signature MATCH_COMPILER =
sig
    val compile : 
      Counters.stamps 
      -> TypedFlatCalc.topBlock list
         -> (Counters.stamps * RecordCalc.topBlock list * UserError.errorInfo list)
end
