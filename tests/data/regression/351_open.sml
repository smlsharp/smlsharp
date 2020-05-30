structure A = struct exception A exception B val x = 1 val y = 2 type foo = int end;
open A;

(*
対話モードでの、openの後のプリント順がおかしい。

structure A =
  struct
    type foo = int32
    exception A
    exception B
    val x = 1 : foo
    val y = 2 : foo
  end
# open A;
type foo = int32
exception B = A.B
val x = 1 : foo
exception A = A.A
val y = 2 : foo
*)
