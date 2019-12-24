datatype 'a par_list =
    NIL
  | CELL of {head : 'a, cham: ForeachData.index, tail: ForeachData.index}

fun initialize nest nil = NIL
  | initialize nest (h::t) =
    let
      val t = nest t
    in
      CELL {head = h, cham = t, tail = t}
    end

fun finalize nest NIL = nil
  | finalize nest (CELL {head, tail, ...}) = head :: nest tail

fun suffixSum l =
    _foreach id in l
    where
      {finalize = finalize,
       initialize = initialize}
    with
      {value, newValue, ...}
    do
      case value id of
        NIL => NIL
      | c as CELL {head=h1, tail, cham} =>
        case value cham of
          CELL {head=h2, tail=_, cham} =>
          CELL {head = h1 + h2 : int,  cham = cham, tail = tail}
        | NIL => c
    while
      case newValue id of
        NIL => false
      | CELL {head, cham, tail} =>
        case newValue cham of
          NIL => false
        | CELL _ => true
    end

val n = valOf (Int.fromString (valOf (OS.Process.getEnv "SIZE")))

val l1 = List.tabulate (n, fn i => 1)
val l2 = suffixSum l1
(*
val _ = app (fn i => print (Int.toString i ^ "\n")) l2
*)
