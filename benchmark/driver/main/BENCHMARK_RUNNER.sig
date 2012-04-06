(**
 * 
 * @author YAMATODANI Kiyoshi
 * @version $Id: BENCHMARK_RUNNER.sig,v 1.4 2007/01/26 09:33:15 kiyoshiy Exp $
 *)
local
  structure BT = BenchmarkTypes
  structure CT = ChannelTypes
in
signature BENCHMARK_RUNNER =
sig

  (***************************************************************************)

  val runBenchmark
      : {
          preludeFileName : string,
          isCompiledPrelude : bool,
          preludeChannel : CT.InputChannel,
          sourceFileName : string,
          sourceChannel : CT.InputChannel,
          compileOutputChannel : CT.OutputChannel,
          executeOutputChannel : CT.OutputChannel
        }
        -> {
             compileTime : BT.elapsedTime,
             compileProfile : (string * string * Time.time) list,
             executionTime : BT.elapsedTime,
             exitStatus : OS.Process.status
           }

  (***************************************************************************)

end
end (* local *)