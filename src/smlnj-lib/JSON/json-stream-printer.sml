(* json-stream-printer.sml
 *
 * Support for printing to `TextIO` output streams.
 *
 * COPYRIGHT (c) 2021 The Fellowship of SML/NJ (http://www.smlnj.org)
 * All rights reserved.
 *)
(* 2025-11-10 katsu: JSONStreamOutputFn is only used here *)
_use "./json-stream-output.fun"

structure JSONStreamPrinter
  : JSON_STREAM_OUTPUT where type outstream = TextIO.outstream
  = JSONStreamOutputFn (
    struct
      type outstream = TextIO.outstream
      val output1 = TextIO.output1
      val output = TextIO.output
      val outputSlice = TextIO.outputSubstr
    end)
