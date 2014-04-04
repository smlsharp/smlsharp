(**
 * Collection of modules.
 * @author YAMATODANI Kiyoshi
 * @copyright 2010, Tohoku University.
 * @version $Id: SMLUnit.sml,v 1.2 2004/10/20 02:09:35 kiyoshiy Exp $
 *)
structure SMLUnit : SMLUNIT =
struct

  (***************************************************************************)

  structure Assert = Assert

  structure Test = Test

  structure TextUITestRunner = TextUITestRunner

(*
  structure HTMLReportTestRunner = HTMLReportTestRunner
*)

  (***************************************************************************)

end