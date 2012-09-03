(*
test cases for Option structure.
*)

val getOpt1 = Option.getOpt (Option.NONE, 2);
val getOpt2 = Option.getOpt (Option.SOME 1, 2);

val isSome1 = Option.isSome (Option.NONE : int Option.option);
val isSome2 = Option.isSome (Option.SOME 1);

val valOf1 = Option.valOf Option.NONE handle Option.Option => 2;
val valOf2 = Option.valOf (Option.SOME 1);

fun filterFun x = x = 1;
val filter1 = Option.filter filterFun 1;
val filter2 = Option.filter filterFun 2;

val join1 = Option.join (Option.NONE : int Option.option Option.option);
val join2 = Option.join (Option.SOME (Option.NONE : int Option.option));
val join3 = Option.join (Option.SOME (Option.SOME 1));

fun mapFun x = (x + 1, 1);
val map1 = Option.map mapFun Option.NONE;
val map2 = Option.map mapFun (Option.SOME 1);

val mapPartialFun = fn x => if x then Option.SOME 1 else Option.NONE;
val mapPartial1 = Option.mapPartial mapPartialFun Option.NONE;
val mapPartial2 = Option.mapPartial mapPartialFun (Option.SOME true);
val mapPartial3 = Option.mapPartial mapPartialFun (Option.SOME false);

val composeFun1 = fn x => (x, 1);
val composeFun2 = fn x => if x then Option.SOME 1 else Option.NONE;
val compose1 = Option.compose (composeFun1, composeFun2) true;
val compose2 = Option.compose (composeFun1, composeFun2) false;

fun composePartialFun1 x = if x = 0 then Option.SOME true else Option.NONE
fun composePartialFun2 x = if 0 <= x then Option.SOME x else Option.NONE;
val composePartial1 =
    Option.composePartial (composePartialFun1, composePartialFun2) ~1;
val composePartial2 =
    Option.composePartial (composePartialFun1, composePartialFun2) 0;
val composePartial3 =
    Option.composePartial (composePartialFun1, composePartialFun2) 1;

