(* 期待される結果
$ smlsharp -c 374_rank1tests2.sml
$ smlsharp -c 374_rank1tests.sml
$ smlsharp -o 374_rank1tests 374_rank1tests.smi
$ ./374_rank1tests 
{a = (1, 2), b = (1, 2), c = (1, 2), v = (2, [true]), w = (2, [1])}
*)
val a = f1 1 (1,2);
val b = f2 1 (1,2);
val c = f3 1 (1,2);
val s = Dynamic.format {a = a, b = b, c = c, v = v, w = w};
val _ =
    case s of
      "{a = (1, 2), b = (1, 2), c = (1, 2), v = (2, [true]), w = (2, [1])}" =>
      ()
    | _ => raise Fail "unexpected"
