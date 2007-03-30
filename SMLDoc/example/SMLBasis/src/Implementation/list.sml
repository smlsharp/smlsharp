(* list.sml
 *
 * COPYRIGHT (c) 1995 AT&T Bell Laboratories.
 *
 * Available (unqualified) at top level:
 *   type list
 *   val nil, ::, hd, tl, null, length, @, app, map, foldr, foldl, rev
 *
 * Consequently the following are not visible at top level:
 *   val last, nth, take, drop, concat, revAppend, mapPartial, find, filter,
 *       partition, exists, all, tabulate
 *   exception Empty
 *
 * The following infix declarations will hold at top level:
 *   infixr 5 :: @
 *
 *)

structure List : LIST =
  struct

    val op +  = InlineT.DfltInt.+
    val op -  = InlineT.DfltInt.-
    val op <  = InlineT.DfltInt.<
    val op <= = InlineT.DfltInt.<=
    val op >  = InlineT.DfltInt.>
    val op >= = InlineT.DfltInt.>=
(*    val op =  = InlineT.= *)

    datatype list = datatype list

    exception Empty = Empty

    val null = null
    val hd = hd
    val tl = tl

    fun last [] = raise Empty
      | last [x] = x
      | last (_::r) = last r

    fun getItem [] = NONE
      | getItem (x::r) = SOME(x, r)

    fun nth (l,n) = let
          fun loop ((e::_),0) = e
            | loop ([],_) = raise Subscript
            | loop ((_::t),n) = loop(t,n-1)
          in
            if n >= 0 then loop (l,n) else raise Subscript
          end

    fun take (l, n) = let
          fun loop (l, 0) = []
            | loop ([], _) = raise Subscript
            | loop ((x::t), n) = x :: loop (t, n-1)
          in
            if n >= 0 then loop (l, n) else raise Subscript
          end

    fun drop (l, n) = let
          fun loop (l,0) = l
            | loop ([],_) = raise Subscript
            | loop ((_::t),n) = loop(t,n-1)
          in
            if n >= 0 then loop (l,n) else raise Subscript
          end

    val length = length
    val rev = rev
    val op @ = op @

    fun concat [] = []
      | concat (l::r) = l @ concat r

    fun revAppend ([],l) = l
      | revAppend (h::t,l) = revAppend(t,h::l)

    val app = app
    val map = map

    fun mapPartial pred l = let
          fun mapp ([], l) = rev l
            | mapp (x::r, l) = (case (pred x)
                 of SOME y => mapp(r, y::l)
                  | NONE => mapp(r, l)
                (* end case *))
          in
            mapp (l, [])
          end

    fun find pred [] = NONE
      | find pred (a::rest) = if pred a then SOME a else (find pred rest)

    fun filter pred [] = []
      | filter pred (a::rest) = if pred a then a::(filter pred rest) 
                                else (filter pred rest)

    fun partition pred l = let
          fun loop ([],trueList,falseList) = (rev trueList, rev falseList)
            | loop (h::t,trueList,falseList) = 
                if pred h then loop(t, h::trueList, falseList)
                else loop(t, trueList, h::falseList)
          in loop (l,[],[]) end

    val foldr = foldr
    val foldl = foldl

    fun exists pred = let 
          fun f [] = false
            | f (h::t) = pred h orelse f t
          in f end
    fun all pred = let 
          fun f [] = true
            | f (h::t) = pred h andalso f t
          in f end

    fun tabulate (len, genfn) = 
          if len < 0 then raise Size
          else let
            fun loop n = if n = len then []
                         else (genfn n)::(loop(n+1))
            in loop 0 end

    fun collate compare = let
	fun loop ([], []) = EQUAL
	  | loop ([], _) = LESS
	  | loop (_, []) = GREATER
	  | loop (x :: xs, y :: ys) =
	    (case compare (x, y) of
		 EQUAL => loop (xs, ys)
	       | unequal => unequal)
    in
	loop
    end

  end (* structure List *)

