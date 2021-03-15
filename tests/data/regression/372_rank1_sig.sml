(*
対話型モードで、
Bug.Bug: PolyTyElimination: instantiate at src/compiler/compilePhases/polytyelimination/main/PolyTyElimination.sml:17.14(298)

コンパイルで、コンパイルエラー
371_rank1_sig.sml:11.8(159)-11.18(169) Error:
  (type inference 016) operator and operand don't agree
  operator domain: int * string
          operand: int * bool
*)

signature A =
sig
  val f : ['a. 'a -> ['b. 'a * 'b -> 'a * 'b]]
end
structure A1 : A =
struct
  fun f x y = y
end;
val g = A1.f 1;
val x = g (1,"2");
val y = g (1, true);


