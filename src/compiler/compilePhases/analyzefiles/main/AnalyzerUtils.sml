(**
 * @copyright (C) 2021 SML# Development Team.
 * @author Atsushi Ohori
 *)
structure AnalyzerUtils =
struct
local
  structure L = Loc
  val analyzerSwitch = ref false
in

  exception OnStdPath

  fun analyzerOn () = analyzerSwitch := true
  fun analyzerOff () = analyzerSwitch := false

  fun onStdpath (L.STDPATH, fileName) = true
    | onStdpath (L.USERPATH, fileName) = false
  fun onUserpath source = not (onStdpath source)
  fun locToStartPos (L.LOC ({pos=L.AT{pos,...},...}, _)) = pos
    | locToStartPos _ = ~1
  fun locToEndPos (L.LOC (_, {pos=L.AT{pos,...},...})) = pos
    | locToEndPos _ = ~2
end
end
