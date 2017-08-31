signature S =
sig
  structure A :
  sig
     datatype bar = A
     type foo
  end
  type foo 
  val x1 : int
  val x2 : int * int
  val x3 : int * int * int * int
  val x : foo -> A.foo
  val y : foo -> A.bar
end

(* 2013-3-3  ohori
In the interactive mode, the following is printed.

signature S =
  sig
    type foo
    val x : foo -> foo
    structure A : sig
      type foo
    end
  end

We should have:

signature S =
  sig
    type foo
    val x : foo -> A.foo
    structure A : sig
      type foo
    end
  end

*)

(* 2013-3-3  ohori
   fixed by 4896:c57a7f02108c
*)
