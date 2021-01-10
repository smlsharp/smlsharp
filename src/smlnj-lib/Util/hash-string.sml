structure Unsafe =
struct
   structure CharVector =
   struct
     fun sub (s,i) = 
         SMLSharp_Builtin.Array.sub_unsafe 
         (SMLSharp_Builtin.String.castToArray s, i)
   end
end
(* hash-string.sml
 *
 * COPYRIGHT (c) 2020
 * All rights reserved.
 *)

structure HashString : sig

    val hashString  : string -> word

    val hashSubstring : substring -> word

  end = FNVHash

