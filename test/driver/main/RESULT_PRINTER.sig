(**
 * print test result into channel.
 * @author YAMATODANI Kiyoshi
 * @version $Id: RESULT_PRINTER.sig,v 1.3 2005/06/11 02:16:34 kiyoshiy Exp $
 *)
signature RESULT_PRINTER =
sig

  (***************************************************************************)

  type context

  (***************************************************************************)

  val initialize :
      {
        (** the diretcory where formatted to be emitted.*) directory : string
      } -> context

  val finalize : context -> unit

  val printCase : context -> TestTypes.caseResult -> context

  val printSummary :
      context ->
      {
        (** general message *) messages : string list,
        (** list of test case results *) results : TestTypes.caseResult list
      } -> context

  (***************************************************************************)

end