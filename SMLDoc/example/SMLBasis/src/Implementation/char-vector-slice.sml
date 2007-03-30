(*  char-vector-slice.sml
 *
 * Copyright (c) 2003 by The Fellowship of SML/NJ
 *
 * Author: Matthias Blume (blume@tti-c.org)
 *)
structure CharVectorSlice :> MONO_VECTOR_SLICE
				 where type elem = char
				 where type vector = CharVector.vector
= struct

    (* fast add/subtract avoiding the overflow test *)
    infix -- ++
    fun x -- y = InlineT.Word31.copyt_int31 (InlineT.Word31.copyf_int31 x -
					     InlineT.Word31.copyf_int31 y)
    fun x ++ y = InlineT.Word31.copyt_int31 (InlineT.Word31.copyf_int31 x +
					     InlineT.Word31.copyf_int31 y)

    type elem = char
    type vector = CharVector.vector

    datatype slice =
	     SL of { base : vector, start : int, stop : int }

    val usub = InlineT.CharVector.sub
    val vlength = InlineT.CharVector.length

    fun length (SL { start, stop, ... }) = stop -- start

    fun sub (SL { base, start, stop }, i) = let
	val i' = start + i
    in
	if i' < start orelse i' >= stop then raise Subscript
	else usub (base, i')
    end

    fun full vec = SL { base = vec, start = 0, stop = vlength vec }

    fun slice (vec, start, olen) = let
	val vl = vlength vec
    in
	SL { base = vec,
	     start = if start < 0 orelse vl < start then raise Subscript
		     else start,
	     stop =
	       case olen of
		   NONE => vl
		 | SOME len => 
		     let val stop = start ++ len
		     in if stop < start orelse vl < stop then raise Subscript
			else stop
		     end }
    end

    fun subslice (SL { base, start, stop }, i, olen) = let
	val start' = if i < 0 orelse stop < i then raise Subscript
		     else start ++ i
	val stop' =
	    case olen of
		NONE => stop
	      | SOME len =>
		  let val stop' = start' ++ len
		  in if stop' < start' orelse stop < stop' then raise Subscript
		     else stop'
		  end
    in
	SL { base = base, start = start', stop = stop' }
    end

    fun base (SL { base, start, stop }) = (base, start, stop -- start)

    fun vector (SL { base, start, stop }) =
	CharVector.tabulate (stop -- start, fn i => usub (base, start ++ i))

    fun isEmpty (SL { start, stop, ... }) = start = stop

    fun getItem (SL { base , start, stop }) =
	if start >= stop then NONE
	else SOME (usub (base, start),
		   SL { base = base, start = start ++ 1, stop = stop })

    fun appi f (SL { base, start, stop }) = let
	fun app i =
	    if i >= stop then ()
	    else (f (i -- start, usub (base, i)); app (i ++ 1))
    in
	app start
    end

    fun app f (SL { base, start, stop }) = let
	fun app i =
	    if i >= stop then () else (f (usub (base, i)); app (i ++ 1))
    in
	app start
    end

    fun foldli f init (SL { base, start, stop }) = let
	fun fold (i, a) =
	    if i >= stop then a
	    else fold (i ++ 1, f (i -- start, usub (base, i), a))
    in
	fold (start, init)
    end

    fun foldl f init (SL { base, start, stop }) = let
	fun fold (i, a) =
	    if i >= stop then a else fold (i ++ 1, f (usub (base, i), a))
    in
	fold (start, init)
    end

    fun foldri f init (SL { base, start, stop }) = let
	fun fold (i, a) =
	    if i < start then a
	    else fold (i -- 1, f (i -- start, usub (base, i), a))
    in
	fold (stop -- 1, init)
    end

    fun foldr f init (SL { base, start, stop }) = let
	fun fold (i, a) =
	    if i < start then a else fold (i -- 1, f (usub (base, i), a))
    in
	fold (stop -- 1, init)
    end

    fun concat sll =
	CharVector.fromList
	    (rev (List.foldl (fn (sl, l) => foldl op :: l sl) [] sll))

    fun mapi f sl =
	CharVector.fromList
	    (rev (foldli (fn (i, x, a) => f (i, x) :: a) [] sl))

    fun map f sl =
	CharVector.fromList
	    (rev (foldl (fn (x, a) => f x :: a) [] sl))

    fun findi p (SL { base, start, stop }) = let
	fun fnd i =
	    if i >= stop then NONE
	    else let val x = usub (base, i)
		 in
		     if p (i, x) then SOME (i -- start, x) else fnd (i ++ 1)
		 end
    in
	fnd start
    end

    fun find p (SL { base, start, stop }) = let
	fun fnd i =
	    if i >= stop then NONE
	    else let val x = usub (base, i)
		 in
		     if p x then SOME x else fnd (i ++ 1)
		 end
    in
	fnd start
    end

    fun exists p (SL { base, start, stop }) = let
	fun ex i = i < stop andalso (p (usub (base, i)) orelse ex (i ++ 1))
    in
	ex start
    end

    fun all p (SL { base, start, stop }) = let
	fun al i = i >= stop orelse (p (usub (base, i)) andalso al (i ++ 1))
    in
	al start
    end

    fun collate c (SL { base = b1, start = s1, stop = e1 },
		   SL { base = b2, start = s2, stop = e2 }) = let
	fun col (i1, i2) =
	    if i1 >= e1 then
		if i2 >= e2 then EQUAL
		else LESS
	    else if i2 >= e2 then GREATER
	    else case c (usub (b1, i1), usub (b2, i2)) of
		     EQUAL => col (i1 ++ 1, i2 ++ 1)
		   | unequal => unequal
    in
	col (s1, s2)
    end
end
