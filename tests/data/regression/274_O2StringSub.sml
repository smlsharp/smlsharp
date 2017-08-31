(*
print (Char.toString (String.sub("a",0)) ^ "\n")
(* 2014-01-25 ohori
-O2 オプション付きでコンパイルすると，String.subの結果
が#"\000"となるらしい．

[ohori@localhost tests]$ smlsharp -O2 274_O2StringSub.sml
[ohori@localhost tests]$ ./a.out 
  \^@
*)
*)

case SMLSharp_Builtin.String.sub ("a", 0) of
  #"a" => ()
| _ => raise Fail "BUG"

(*
2013-01-27 katsu

The above code must not raise any exception but it raises "BUG" if
the code is compiled with -O2 switch.
*)

(*
2013-01-28 katsu

fixed by changeset 70d27d6fcf83.

*)
