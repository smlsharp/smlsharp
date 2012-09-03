(**
 * 
 * @author YAMATODANI Kiyoshi
 * @version $Id: BENCHMARK_RUNNER.sig,v 1.3 2005/09/15 09:05:19 kiyoshiy Exp $
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
          preludesFileName : string,
          preludesChannel : CT.InputChannel,
          sourceFileName : string,
          sourceChannel : CT.InputChannel,
          compileOutputChannel : CT.OutputChannel,
          executeOutputChannel : CT.OutputChannel
        }
        -> {
             compileTime : BT.elapsedTime,
             executionTime : BT.elapsedTime,
             exitStatus : OS.Process.status
           }

  (***************************************************************************)

end
end (* local *)