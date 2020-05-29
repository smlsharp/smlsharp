_dynamic (Dynamic.fromJson "[[1.1,\"a\"],[2.2]]") as real list list;

(*
case others
real
"a"
uncaught exception Bug.Bug: Type of term and designated type does not match. at src/compiler/extensions/reflection/main/ReifiedTermToML.sml:325.23(14618)
*)
