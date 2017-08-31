fun app (f:'a -> int) = ()
fun pretty_rule (n:int,(M:int,N:int)) = M
fun pretty_rules l = app pretty_rule

(*
2011-08-14 katsu

This causes BUG at BitmapCompilation due to unboxing the nested
record (n,(M,N)).

[BUG] compileExp: MVINDEXOF
    raised at: ../bitmapcompilation/main/BitmapCompilation.sml:192.42-192.77
   handled at: ../toplevel2/main/Top.sml:824.37
		main/SimpleMain.sml:269.53

2011-08-14 katsu

Fixed by changeset fe8ca01e5462.

*)
