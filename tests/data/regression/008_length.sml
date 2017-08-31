_interface "008_length.smi"

fun length l = 
    let
      fun j(k, nil) = k
        | j(k, a::x) = j(k+1,x)
    in
      j(0,l)
    end
(*
2011-08-12 ohori

This causes bug in MatchCompiler.
getTagNums
['a. 'a list(t14)]
[BUG] MatchCompiler: Non conty in userdefined type
    raised at: ../matchcompilation/main/MatchCompiler.sml:396.22-396.57
   handled at: ../matchcompilation/main/MatchCompiler.sml:1511.27-1511.30
		../toplevel2/main/Top.sml:760.37
		main/SimpleMain.sml:269.53

FIXEd. 2011-08-12 ohori 

*)

(*
2011-08-12 katsu

This causes BUG in RecordUnboxing.

2011-08-13 katsu

Fixed by changeset dc96e94463e2.
*)

(*
2011-08-13 katsu

This causes BUG in X86Select since integer literals are compiled
to IntInf terms in spite of their actual types.

2011-08-13 katsu

Fixed by changeset 5c2722226f2d.
*)
