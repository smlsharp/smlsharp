functor F (
  A : sig
    exception E
  end
) = 
struct
  exception E = A.E
  val x = 1
end
