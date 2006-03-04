(* bit-array.sml
 *
 * COPYRIGHT (c) 1995 by AT&T Bell Laboratories.  See COPYRIGHT file for details.
 *
 *)

structure BitArray :> BIT_ARRAY =
  struct

    open BitVector
    type array = vector

    fun vector a = a

    fun copy { src, dst, di } = copy' { src = src, dst = dst, di = di,
					si = 0, len = NONE }

    val copyVec = copy

    fun appi f a = appi' f (a, 0, NONE)
    fun modifyi f a = modifyi' f (a, 0, NONE)
    fun foldli f init a = foldli' f init (a, 0, NONE)
    fun foldri f init a = foldri' f init (a, 0, NONE)

    (* These are slow, pedestrian implementations.... *)
    fun findi p a = let
	val len = length a
	fun fnd i =
	    if i >= len then NONE
	    else let val x = sub (a, i)
		 in
		     if p (i, x) then SOME (i, x) else fnd (i + 1)
		 end
    in
	fnd 0
    end

    fun find p a = let
	val len = length a
	fun fnd i =
	    if i >= len then NONE
	    else let val x = sub (a, i)
		 in
		     if p x then SOME x else fnd (i + 1)
		 end
    in
	fnd 0
    end

    fun exists p a = let
	val len = length a
	fun ex i = i < len andalso (p (sub (a, i)) orelse ex (i + 1))
    in
	ex 0
    end

    fun all p a = let
	val len = length a
	fun al i = i >= len orelse (p (sub (a, i)) andalso al (i + 1))
    in
	al 0
    end

    fun collate c (a1, a2) = let
	val l1 = length a1
	val l2 = length a2
	val l12 = Int.min (l1, l2)
	fun col i =
	    if i >= l12 then Int.compare (l1, l2)
	    else case c (sub (a1, i), sub (a2, i)) of
		     EQUAL => col (i + 1)
		   | unequal => unequal
    in
	col 0
    end

end (* structure BitArray *)
