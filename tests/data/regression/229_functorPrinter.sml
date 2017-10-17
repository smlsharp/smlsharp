functor F (P:sig type foo end) 
: sig
   type bar
   val f : bar -> bar
  end
=
struct
  type bar = P.foo
  fun f x =  x 
end;

structure A 
 : sig
     type 'a foo
     val f : bool foo -> bool foo
   end
=
  struct
    type 'a foo = int
    fun f x = x
  end ;

(* 2012-8-3 The types in a functor body are prinited strangely.
functor F
  (sig
    type foo
  end) =
    sig
      type bar = 'foo
      val f : \. 'foo(tv1208) -> \. 'foo(tv1208)
    end
structure A =
  struct
    type 'a foo = int
    val f = fn : bool \'a(tv1209) . int -> bool \'a(tv1209) . int
  end
*)

(* 2012-8-4 ohori 
  Fixed by 4365:7e011b9c685d
*)
