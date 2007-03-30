(**
 * This module provides access method to the internal of SML# system.
 * @author YAMATODANI Kiyoshi
 * @copyright (c) 2006, Tohoku University.
 * @version $Id: SMLSHARP.sig,v 1.2 2007/03/16 11:30:36 kiyoshiy Exp $
 *)
signature SMLSHARP =
sig

  structure GC : GC
  structure Finalizable : FINALIZABLE
  structure FLOB : FLOB
  structure Platform : PLATFORM

end;
