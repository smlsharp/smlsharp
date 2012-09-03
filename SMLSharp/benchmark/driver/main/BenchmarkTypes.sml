(**
 * 
 * @author YAMATODANI Kiyoshi
 * @version $Id: BenchmarkTypes.sml,v 1.7 2005/09/15 09:05:19 kiyoshiy Exp $
 *)
structure BenchmarkTypes =
struct

  (***************************************************************************)

  type elapsedTime = {sys : Time.time, usr : Time.time, real : Time.time}

  type benchmarkResult =
       {
         sourcePath : string,
         compileTime : elapsedTime,
         compileProfile : (string * string * Time.time) list,
         executionTime : elapsedTime,
         exitStatus : OS.Process.status,
         exceptions : exn list ref,
         compileOutputArrayOpt : Word8Array.array option,
         executeOutputArrayOpt : Word8Array.array option
       }

  val zeroElapsedTime : elapsedTime =
      {sys = Time.zeroTime, usr = Time.zeroTime, real = Time.zeroTime}

  (***************************************************************************)

end