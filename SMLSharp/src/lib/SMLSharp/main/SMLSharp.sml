(**
 * The SMLSharp provides access method to the internal of SML# system.
 * @author YAMATODANI Kiyoshi
 * @copyright (c) 2006, Tohoku University.
 * @version $Id: SMLSharp.sml,v 1.7 2007/06/01 01:25:11 kiyoshiy Exp $
 *)
structure SMLSharp (*: SMLSHARP *) =
struct
  open SMLSharp

  structure CommandLine = SMLSharpCommandLine
  structure Control = SMLSharpControl
  structure GC = SMLSharpGC
  structure Finalizable = SMLSharpFinalizable
  structure FLOB = SMLSharpFLOB
(*
  structure Mutable = SMLSharpMutable
*)
  structure Platform = SMLSharpPlatform

end;
