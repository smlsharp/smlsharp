infix 6 + - ^
infix 4 = <> > >= < <=
val op <= = SMLSharp_Builtin.Int.lteq
val op ^ = String.^
type substring = Substring.substring
structure InlineT =
struct
  structure CharVector = CharVector
end
(*
ToDo: Yamatodani's OSPathOperations includes Windows path support.

fun trPath path =
    String.translate (fn #"\\" => "/" | c => String.str c) path
val volSS = Substring.full ""
fun splitVolPath s =
    let val ss = SS.full (trPath s)
        val volSS = Substring.full ""
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
+  | joinVolPath (true, vol, s) = vol ^ "/" ^ s
   | joinVolPath _ = raise Path (* invalid volume *)
*)
(* os-path.sml
 *
 * COPYRIGHT (c) 2007 The Fellowship of SML/NJ (http://smlnj.org)
 * All rights reserved.
 *
 * This is the UNIX implementation of the generic OS.Path structure.
 *)

(*
structure OS_Path = OS_PathFn (
*)
structure SMLSharp_SMLNJ_PathBase = 
  struct
    exception Path
    datatype arc_kind = Null | Parent | Current | Arc of string
    fun classify "" = Null
      | classify "." = Current
      | classify ".." = Parent
      | classify a = Arc a
    val parentArc = ".."
    val currentArc = "."
    fun validArc arc = let
	  fun ok #"/" = false
	    | ok c = Char.isPrint c
	  in
	    CharVector.all ok arc
	  end
    fun validVolume (_:bool, vol:substring)= Substring.isEmpty vol
    val volSS = Substring.full ""
  (* Note: we are guaranteed that this is never called with "" *)
    fun splitVolPath s = if (InlineT.CharVector.sub(s, 0) = #"/")
	  then (true, volSS, Substring.triml 1 (Substring.full s))
	  else (false, volSS, Substring.full s)
    fun joinVolPath (true, "", "") = "/"
      | joinVolPath (true, "", s) = "/" ^ s
      | joinVolPath (false, "", s) = s
      | joinVolPath _ = raise Path (* invalid volume *)
    val arcSepChar = #"/"
    fun sameVol (v1, v2: string) = v1 = v2
  end

structure SMLSharp_SMLNJ_OS_Path = SMLSharp_SMLNJ_OS_PathFn (SMLSharp_SMLNJ_PathBase);





