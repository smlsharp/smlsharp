
exception Exn1

exception Exn2 of int

type t1 = int
exception Exn3 of t1

exception Exn41
      and Exn42

exception Exn41 = Exn42
      and Exn42 = Exn41

exception Exn5 = Exn1

infix Exn6
exception Exn6 of int * int

exception Exn7 of int -> int
exception Exn8 of {A:int, B:string}
exception Exn9 of int list

val v2 = Exn2 1
val v3 = Exn3 1
