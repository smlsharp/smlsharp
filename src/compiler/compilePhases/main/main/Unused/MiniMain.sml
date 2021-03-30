(**
 * main for minismlsharp
 * @copyright (C) 2021 SML# Development Team.
 * @author UENO Katsuhiro
 *)

(* dummy *)
structure RunLoop =
struct
  fun interactive _ _ _ = ()
end

structure AnalyzeFiles =
struct
  fun analyzeFiles _ _ _ = ()
end

(* dummy *)
structure SMLSharp_Version =
struct
  val Release = "(minismlsharp)"
  val DefaultSystemBaseDir = "src"
end

;
_use "./Main.sml"
