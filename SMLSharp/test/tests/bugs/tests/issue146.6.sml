functor MonoVectorBase
            (B
             : sig
               type elem
               type array
               val sub : array * int -> elem
             end) =
struct
  fun concat (vector :: _) =
      let
        val initialValueOpt =
            SOME(B.sub(valOf (#buffer vector), 0))
      in 
        case (0, initialValueOpt) of
          (0, _) => ()
        | (_, SOME _) => ()
      end
end;

structure Operations =
struct
  type elem = unit
  type array = unit
  val sub = fn ((), n : int) => ()
end
structure UnitVector = MonoVectorBase(Operations);
