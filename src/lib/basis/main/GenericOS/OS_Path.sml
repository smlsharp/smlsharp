(**
 * OS_Path structure.
 * @author AT&T Bell Laboratories.
 * @author YAMATODANI Kiyoshi
 * @version $Id: OS_Path.sml,v 1.2 2005/08/18 00:45:19 kiyoshiy Exp $
 *)
(* os-path.sml
 *
 * COPYRIGHT (c) 1995 AT&T Bell Laboratories.
 *
 * This is the UNIX implementation of the generic OS.Path structure.
 *
 *)
local
  structure OSPathOperations =
  struct

    exception Path

    datatype arc_kind = Null | Parent | Current | Arc of string

    fun classify "" = Null
      | classify "." = Current
      | classify ".." = Parent
      | classify a = Arc a

    val parentArc = ".."

    val currentArc = "."

    fun validVolume (_, vol)= Substring.isEmpty vol

    val volSS = Substring.all ""

    (* Note: we are guaranteed that this is never called with "" *)
    fun splitVolPath s =
        if (CharVector.sub(s, 0) = #"/")
        then (true, volSS, Substring.triml 1 (Substring.all s))
        else (false, volSS, Substring.all s)

    fun joinVolPath (true, "", "") = "/"
      | joinVolPath (true, "", s) = "/" ^ s
      | joinVolPath (false, "", s) = s
      | joinVolPath _ = raise Path (* invalid volume *)

    val arcSepChar = #"/"

    fun sameVol (v1, v2 : string) = v1 = v2

  end
in
structure OS_Path = OS_PathFn(OSPathOperations)
end
