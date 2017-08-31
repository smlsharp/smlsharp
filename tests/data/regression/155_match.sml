datatype e = Error of exn
fun toString (Error (Fail x)) = ()

(*
2011-11-28 katsu

This causes BUG at MatchCompiler.

[BUG] non tyCon in TagNode (matchcompilation/main/MatchCompiler.sml)
    raised at: ../matchcompilation/main/MatchCompiler.sml:1098.23-1100.69
   handled at: ../matchcompilation/main/MatchCompiler.sml:1528.27-1528.30
                ../toplevel2/main/Top.sml:836.37
                main/SimpleMain.sml:368.53

*)

(*
2011-11-28 ohori

This is due to the error in calculating the type of the result of
exception construct. Since the type of (Fail x) is set to that of
Fail (i.e. a function type), the match compiler cannot determine 
the tag.

I do not know when and why this bug is created.

*)
