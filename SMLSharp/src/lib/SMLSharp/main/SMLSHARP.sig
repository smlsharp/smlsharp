(**
 * This module provides access method to the internal of SML# system.
 * @author YAMATODANI Kiyoshi
 * @copyright (c) 2006, Tohoku University.
 * @version $Id: SMLSHARP.sig,v 1.7 2007/06/01 01:25:11 kiyoshiy Exp $
 *)
signature SMLSHARP =
sig

  structure CommandLine : SMLSHARP_COMMAND_LINE
  structure Control : SMLSHARP_CONTROL
  structure GC : SMLSHARP_GC
  structure Finalizable : SMLSHARP_FINALIZABLE
  structure FLOB : SMLSHARP_FLOB
(*
  structure Mutable : SMLSHARP_MUTABLE
*)
  structure Platform : SMLSHARP_PLATFORM

end;
