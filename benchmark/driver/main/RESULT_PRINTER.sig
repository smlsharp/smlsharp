(**
 * print test result into channel.
 * @author YAMATODANI Kiyoshi
 * @version $Id: RESULT_PRINTER.sig,v 1.1 2005/09/05 05:28:13 kiyoshiy Exp $
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

  val printCase : context -> BenchmarkTypes.benchmarkResult -> context

  val printSummary :
      context ->
      {
        (** general message *) messages : string list,
        (** list of test case results *)
        results : BenchmarkTypes.benchmarkResult list
      } -> context

  (***************************************************************************)

end