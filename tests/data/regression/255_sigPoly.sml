structure A
: sig
   val f : ['a. 'a -> ['b#{a: 'c}, 'c. 'b -> 'a * 'c]]
  end
=
struct
  fun f x y = (x, #a y)
end

val x =  A.f (1, (1,1), 1.1);

(*
2013-4-12 ohori

In the interactive mode, this causes segmentation fault.
*)
