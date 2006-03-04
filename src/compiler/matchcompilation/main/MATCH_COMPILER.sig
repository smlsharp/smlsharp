(**
 * match compiler.
 * @copyright (c) 2006, Tohoku University.
 * @author OSAKA Satoshi
 * @version $Id: MATCH_COMPILER.sig,v 1.8 2006/02/28 16:11:02 kiyoshiy Exp $
 *)
signature MATCH_COMPILER =
sig

  (***************************************************************************)

  val compile :
      TypedFlatCalc.tfpdecl list
      -> RecordCalc.rcdecl list * UserError.errorInfo list

  (***************************************************************************)

end
