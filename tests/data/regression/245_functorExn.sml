(*
2012-11-9 ohori
This cause a BUG excetion.
[BUG] composeExn: tag not found

The excetion defined in the fuctor F (245_functorExn3.smi)
is treated as an internal excetion when functor application 
is used in the interface file.
The name evaluator creates the following
  val() a(v0) = raise A.Foo(e1)
  245_functorExn3.sml:1.1-1.19 Warning:
    (type inference 065) dummy type variable(s) are introduced due to value
    restriction in: a
  [BUG] composeExn: tag not found
where e1 is an internal exception id.

If we replace 
  structure A = F(B)
with the following declaration, then compiler works fine.
  structure A = 
  struct
    exception Foo
  end
The name evaluator generates the following:
  extern exception A.Foo : d()exn(t12) (NONEQ)
  val() a(v0) = raise A.Foo

*)
val a = (raise A.Foo) : int
