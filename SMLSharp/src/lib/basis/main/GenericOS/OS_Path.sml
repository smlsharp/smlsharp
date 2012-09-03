(**
 * OS_Path structure.
 * @author AT&T Bell Laboratories.
 * @author YAMATODANI Kiyoshi
 * @version $Id: OS_Path.sml,v 1.4 2006/12/04 04:21:03 kiyoshiy Exp $
 *)
(* os-path.sml
 *
 * COPYRIGHT (c) 1995 AT&T Bell Laboratories.
 *
 * This is the UNIX implementation of the generic OS.Path structure.
 *
 *)
local

  structure SS = Substring

  structure OSPathOperations =
  struct

    exception Path

    datatype arc_kind = Null | Parent | Current | Arc of string

    fun trPath path =
        String.translate (fn #"\\" => "/" | c => String.str c) path

    fun classify "" = Null
      | classify "." = Current
      | classify ".." = Parent
      | classify a = Arc a

    val parentArc = ".."

    val currentArc = "."

    fun validVolume (_, vol)= Substring.isEmpty vol

    val volSS = Substring.full ""

    (* Note: we are guaranteed that this is never called with "" *)
    fun splitVolPath s =
        let val ss = SS.full (trPath s)
        in
          if (SS.sub(ss, 0) = #"/")
          then (true, volSS, Substring.triml 1 ss)
          else
            if (2 < SS.size ss) andalso (SS.sub(ss, 1) = #":")
            then
              let val (volSS, pathSS) = SS.splitAt (ss, 2)
              in (true, volSS, pathSS)
              end
            else (false, volSS, ss)
        end

    fun joinVolPath (true, "", "") = "/"
      | joinVolPath (true, "", s) = "/" ^ s
      | joinVolPath (false, "", s) = s
      | joinVolPath (true, vol, s) = vol ^ "/" ^ s
      | joinVolPath _ = raise Path (* invalid volume *)

    val arcSepChar = #"/"

    fun sameVol (v1, v2 : string) = v1 = v2

  end
in
structure OS_Path = OS_PathFn(OSPathOperations)
end
