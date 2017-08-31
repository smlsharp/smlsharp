signature S1 =
  sig
     datatype bar = A
     type foo
  end
signature S2 =
sig
  structure A : S1
  type foo 
  val x1 : int
  val x2 : int * int
  val x3 : int * int * int * int
  val x : foo -> A.foo
  val y : foo -> A.bar
end

(* 2013-3-3 
In the interactive mode, the following is printed.

signature S2 =
  sig
    type foo
    val x : foo -> foo
    val y : foo -> bar
    structure A :
    sig
      datatype bar = A
      type foo
    end
  end

We should have:

signature S2 =
  sig
    type foo
    val x : foo -> S1.foo
    val y : foo -> S1.bar
    structure A :
    sig
      datatype bar = A
      type foo
    end
  end

*)
(* 2013-3-3  ohori
   fixed by 4896:c57a7f02108c
*)
