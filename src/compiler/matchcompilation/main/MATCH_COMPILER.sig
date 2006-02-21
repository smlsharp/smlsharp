(**
 * Copyright (c) 2006, Tohoku University.
 *
 * match compiler.
 * @author OSAKA Satoshi
 * @version $Id: MATCH_COMPILER.sig,v 1.7 2006/02/18 04:59:22 ohori Exp $
 *)
signature MATCH_COMPILER =
sig

  (***************************************************************************)

  val compile :
      TypedFlatCalc.tfpdecl list
      -> RecordCalc.rcdecl list * UserError.errorInfo list

  (***************************************************************************)

end
