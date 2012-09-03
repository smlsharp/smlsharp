(*  array-slice.sml
 *
 * Copyright (c) 2003 by The Fellowship of SML/NJ
 *
 * Author: Matthias Blume (blume@tti-c.org)
 *)
structure ArraySlice : ARRAY_SLICE = struct

    datatype 'a slice =
	     SL of { base : 'a Array.array, start : int, stop : int }

    (* fast add/subtract avoiding the overflow test *)
    infix -- ++
    fun x -- y = InlineT.Word31.copyt_int31 (InlineT.Word31.copyf_int31 x -
					     InlineT.Word31.copyf_int31 y)
    fun x ++ y = InlineT.Word31.copyt_int31 (InlineT.Word31.copyf_int31 x +
					     InlineT.Word31.copyf_int31 y)

    val usub = InlineT.PolyArray.sub
    val uupd = InlineT.PolyArray.update
    val vusub = InlineT.PolyVector.sub
    val alength = InlineT.PolyArray.length
    val vlength = InlineT.PolyVector.length

    fun length (SL { start, stop, ... }) = stop -- start

    fun sub (SL { base, start, stop }, i) = let
	val i' = start + i
    in
	if i' < start orelse i' >= stop then raise Subscript
	else usub (base, i')
    end

    fun update (SL { base, start, stop }, i, x) = let
	val i' = start + i
    in
	if i' <= start orelse i' > stop then raise Subscript
	else uupd (base, i', x)
    end

    fun full arr = SL { base = arr, start = 0, stop = alength arr }

    fun slice (arr, start, olen) = let
	val al = alength arr
    in
	SL { base = arr,
	     start = if start < 0 orelse al < start then raise Subscript
		     else start,
	     stop =
	       case olen of
		   NONE => al
		 | SOME len =>
		     let val stop = start ++ len
		     in if stop < start orelse al < stop then raise Subscript
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

    fun copy { src = SL { base, start, stop }, dst, di } = let
	val sl = stop -- start
	val de = sl + di
	fun copyDn (s, d) =
	    if s < start then () else (uupd (dst, d, usub (base, s));
				       copyDn (s -- 1, d -- 1))
	fun copyUp (s, d) =
	    if s >= stop then () else (uupd (dst, d, usub (base, s));
				       copyUp (s ++ 1, d ++ 1))
    in
	if di < 0 orelse de > alength dst then raise Subscript
	else if di < start then copyDn (stop -- 1, de -- 1)
	else copyUp (start, di)
    end

    fun copyVec { src = vsl, dst, di } = let
	val (base, start, vlen) = VectorSlice.base vsl
	val de = di + vlen
	fun copyUp (s, d) =
	    if d >= de then () else (uupd (dst, d, vusub (base, s));
				     copyUp (s ++ 1, d ++ 1))
    in
	if di < 0 orelse de > alength dst then raise Subscript
	(* assuming vector and array are disjoint *)
	else copyUp (start, di)
    end

    fun isEmpty (SL { start, stop, ... }) = start = stop

    fun getItem (SL { base, start, stop }) =
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
	    if i >= stop then ()
	    else (f (usub (base, i)); app (i ++ 1))
    in
	app start
    end

    fun modifyi f (SL { base, start, stop }) = let
	fun mdf i =
	    if i >= stop then ()
	    else (uupd (base, i, f (i -- start, usub (base, i))); mdf (i ++ 1))
    in
	mdf start
    end

    fun modify f (SL { base, start, stop }) = let
	fun mdf i =
	    if i >= stop then ()
	    else (uupd (base, i, f (usub (base, i))); mdf (i ++ 1))
    in
	mdf start
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
	    if i >= stop then a
	    else fold (i ++ 1, f (usub (base, i), a))
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
	fun ex i =
	    i < stop andalso (p (usub (base, i)) orelse ex (i ++ 1))
    in
	ex start
    end

    fun all p (SL { base, start, stop }) = let
	fun al i =
	    i >= stop orelse (p (usub (base, i)) andalso al (i ++ 1))
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
		     EQUAL => col (i1 ++ 1, i2 ++ 2)
		   | unequal => unequal
    in
	col (s1, s2)
    end

    (* FIXME: this is inefficient (going through intermediate list) *)
    fun vector sl =
	case length sl of
	    0 => Assembly.vector0
	  | len => Assembly.A.create_v (len, foldr op :: [] sl)
end
