(* path-util.sml
 *
 * COPYRIGHT (c) 1997 Bell Labs, Lucent Technologies.
 *
 * Various higher-level pathname and searching utilities.
 *)

structure PathUtil : PATH_UTIL =
  struct

    structure P = OS.Path
    structure F = OS.FileSys

    fun existsFile pred pathList fileName = let
	  fun chk s = if (pred s) then SOME s else NONE
	  fun iter [] = NONE
	    | iter (p::r) = (case chk(P.joinDirFile{dir=p, file=fileName})
		 of NONE => iter r
		  | res => res
		(* end case *))
	  in
	    iter pathList
	  end
    fun allFiles pred pathList fileName = let
	  fun chk s = if (pred s) then SOME s else NONE
	  fun iter ([], l) = rev l
	    | iter (p::r, l) = (case chk(P.joinDirFile{dir=p, file=fileName})
		 of NONE => iter(r, l)
		  | (SOME s) => iter(r, s::l)
		(* end case *))
	  in
	    iter (pathList, [])
	  end

    fun fileExists s = F.access(s, [])

    val findFile  = existsFile fileExists
    val findFiles = allFiles fileExists

  end;

