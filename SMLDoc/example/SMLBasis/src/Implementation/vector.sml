(* vector.sml
 *
 * COPYRIGHT (c) 1994 AT&T Bell Laboratories.
 *
 *)

structure Vector : VECTOR =
  struct

(*
    val (op +)  = InlineT.DfltInt.+
    val (op <)  = InlineT.DfltInt.<
    val (op >=) = InlineT.DfltInt.>=
*)

    (* fast add/subtract avoiding the overflow test *)
    infix -- ++
    fun x -- y = InlineT.Word31.copyt_int31 (InlineT.Word31.copyf_int31 x -
					     InlineT.Word31.copyf_int31 y)
    fun x ++ y = InlineT.Word31.copyt_int31 (InlineT.Word31.copyf_int31 x +
					     InlineT.Word31.copyf_int31 y)

    type 'a vector = 'a vector

    val maxLen = Core.max_length

    fun checkLen n =
	if InlineT.DfltInt.ltu(maxLen, n) then raise General.Size else ()

    fun fromList l = let
	(* no list can be longer than what is representable as int: *)
	  fun len ([], n) = n
	    | len ([_], n) = n ++ 1
	    | len (_::_::r, n) = len (r, n ++ 2)
	  val n = len (l, 0)
    in
	checkLen n;
	if n = 0 then Assembly.vector0
	else Assembly.A.create_v (n, l)
    end

    fun tabulate (0, _) = Assembly.vector0
      | tabulate (n, f) = let
	    fun tab i = if i = n then [] else f i :: tab (i++1)
	in
	    checkLen n;
	    Assembly.A.create_v(n, tab 0)
	end

    val length : 'a vector -> int = InlineT.PolyVector.length
    val sub : 'a vector * int -> 'a = InlineT.PolyVector.chkSub
    val usub = InlineT.PolyVector.sub

  (* a utility function *)
    fun rev ([], l) = l
      | rev (x::r, l) = rev (r, x::l)

(*
    fun extract (v, base, optLen) = let
	  val len = length v
	  fun newVec n = let
		fun tab (~1, l) = Assembly.A.create_v(n, l)
		  | tab (i, l) = tab(i-1, InlineT.PolyVector.sub(v, base+i)::l)
		in
		  tab (n-1, [])
		end
	  in
	    case (base, optLen)
	     of (0, NONE) => v
	      | (_, SOME 0) => if ((base < 0) orelse (len < base))
		  then raise General.Subscript
		  else Assembly.vector0
	      | (_, NONE) => if ((base < 0) orelse (len < base))
		    then raise General.Subscript
		  else if (len = base)
		    then Assembly.vector0
		    else newVec (len - base)
	      | (_, SOME n) =>
		  if ((base < 0) orelse (n < 0) orelse (len < (base+n)))
		    then raise General.Subscript
		    else newVec n
	    (* end case *)
	  end
*)

    fun concat [v] = v
      | concat vl = let
	(* get the total length and flatten the list *)
	  fun len ([], n, l) = (checkLen n; (n, rev (l, [])))
	    | len (v::r, n, l) = let
		  val n' = InlineT.PolyVector.length v
		  fun explode (i, l) =
		      if i < n' then explode (i++1, usub(v, i) :: l) else l
	      in
		  len (r, n ++ n', explode(0, l))
	      end
	  in
	    case len (vl, 0, [])
	     of (0, _) => Assembly.vector0
	      | (n, l) => Assembly.A.create_v(n, l)
	    (* end case *)
	  end

    fun appi f vec = let
	val len = length vec
	fun app i =
	    if i >= len then () else (f (i, usub (vec, i)); app (i ++ 1))
    in
	app 0
    end

    fun app f vec = let
	val len = length vec
	fun app i =
	    if i < len then (f (usub (vec, i)); app (i ++ 1)) else ()
    in
	app 0
    end

    fun mapi f vec = let
	val len = length vec
	fun mapf (i, l) =
	    if i < len then mapf (i ++ 1, f (i, usub (vec, i)) :: l)
	    else Assembly.A.create_v (len, rev (l, []))
    in
	if len > 0 then mapf (0, []) else Assembly.vector0
    end

    fun map f vec = let
	val len = length vec
	fun mapf (i, l) =
	    if i < len then mapf (i+1, f (usub (vec, i)) :: l)
	    else Assembly.A.create_v (len, rev (l, []))
    in
	if len > 0 then mapf (0, []) else Assembly.vector0
    end

    fun update (v, i, x) =
	mapi (fn (i', x') => if i = i' then x else x') v

    fun foldli f init vec = let
	val len = length vec
	fun fold (i, a) =
	    if i >= len then a else fold (i ++ 1, f (i, usub (vec, i), a))
    in
	fold (0, init)
    end

    fun foldl f init vec = let
	val len = length vec
	fun fold (i, a) =
	    if i >= len then a else fold (i ++ 1, f (usub (vec, i), a))
    in
	fold (0, init)
    end

    fun foldri f init vec = let
	fun fold (i, a) =
	    if i < 0 then a else fold (i -- 1, f (i, usub (vec, i), a))
    in
	fold (length vec -- 1, init)
    end

    fun foldr f init vec = let
	fun fold (i, a) =
	    if i < 0 then a else fold (i -- 1, f (usub (vec, i), a))
    in
	fold (length vec -- 1, init)
    end

    fun findi p vec = let
	val len = length vec
	fun fnd i =
	    if i >= len then NONE
	    else let val x = usub (vec, i)
		 in
		     if p (i, x) then SOME (i, x) else fnd (i ++ 1)
		 end
    in
	fnd 0
    end

    fun find p vec = let
	val len = length vec
	fun fnd i =
	    if i >= len then NONE
	    else let val x = usub (vec, i)
		 in
		     if p x then SOME x else fnd (i ++ 1)
		 end
    in
	fnd 0
    end

    fun exists p vec = let
	val len = length vec
	fun ex i = i < len andalso (p (usub (vec, i)) orelse ex (i ++ 1))
    in
	ex 0
    end

    fun all p vec = let
	val len = length vec
	fun al i = i >= len orelse (p (usub (vec, i)) andalso al (i ++ 1))
    in
	al 0
    end

    fun collate c (v1, v2) = let
	val l1 = length v1
	val l2 = length v2
	val l12 = InlineT.Int31.min (l1, l2)
	fun col i =
	    if i >= l12 then IntImp.compare (l1, l2)
	    else case c (usub (v1, i), usub (v2, i)) of
		     EQUAL => col (i ++ 1)
		   | unequal => unequal
    in
	col 0
    end
  end  (* Vector *)
