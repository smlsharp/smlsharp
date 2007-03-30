(**
 * The SMLSharp provides access method to the internal of SML# system.
 * @author YAMATODANI Kiyoshi
 * @copyright (c) 2006, Tohoku University.
 * @version $Id: SMLSharp.sml,v 1.2 2007/03/16 11:30:36 kiyoshiy Exp $
 *)
structure SMLSharp : SMLSHARP =
struct

  structure GC = GC
  structure Finalizable = Finalizable
  structure FLOB = FLOB
  structure Platform = Platform

end;
