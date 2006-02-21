(**
 * Copyright (c) 2006, Tohoku University.
 *)

signature ordsig = sig
    type ord_key
    val compare : ord_key * ord_key -> order
end

structure Iord:ordsig = struct 
    type ord_key = int
    val compare = Int.compare
end

structure Sord:ordsig = struct 
    type ord_key = string
    fun compare (x,y) = 
	let val (a,b) = (valOf(Int.fromString x),valOf(Int.fromString y))
	in Int.compare (a,b)
	end
        handle Option => String.compare (x,y)
end

structure IEnv = BinaryMapFn(Iord);
local
  structure base = BinaryMapFn(Sord)
in
structure SEnv
  : sig
      include ORD_MAP
      val fromList : (string * 'item) list -> 'item map
    end =
struct
  open base
  fun fromList list =
      List.foldl
          (fn ((key, item), map) => insert (map, key, item))
          empty
          list
end
end; (* local *)
structure ISet = BinarySetFn(Iord);
structure SSet = BinarySetFn(Sord);

fun IEnvToISet m = IEnv.foldli (fn (i,_,s) => ISet.add(s,i)) ISet.empty m
fun SEnvToSSet m = SEnv.foldli (fn (i,_,s) => SSet.add(s,i)) SSet.empty m

