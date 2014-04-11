(**
 * List structure.
 * @author UENO Katsuhiro
 * @author YAMATODANI Kiyoshi
 * @copyright 2010, 2011, 2012, 2013, Tohoku University.
 *)

infix  6 + - ^
infixr 5 :: @
infix  4 = <> > >= < <=
val op + = SMLSharp_Builtin.Int.add_unsafe
val op - = SMLSharp_Builtin.Int.sub_unsafe
val op >= = SMLSharp_Builtin.Int.gteq
val op < = SMLSharp_Builtin.Int.lt

structure List =
struct

  datatype list = datatype list
  exception Empty

  fun null nil = true
    | null _ = false

  fun length (l:'a list) =
      let
        fun loop (nil:'a list, z) = z
          | loop (_::t, z) = loop (t, z + 1)
      in
        loop (l, 0)
      end

  fun revAppend (l:'a list, r) =
      let
        fun loop (nil:'a list, r) = r
          | loop (h::t, r) = loop (t, h::r)
      in
        loop (l, r)
      end

  fun rev l =
      revAppend (l, nil)

  fun op @ (nil, r) = r
    | op @ (l, nil) = l
    | op @ (l, r) = revAppend (rev l, r)

  fun hd nil = raise Empty
    | hd (h::_) = h

  fun tl nil = raise Empty
    | tl (_::t) = t

  fun last nil = raise Empty
    | last [x] = x
    | last (_::t) = last t

  fun getItem nil = NONE
    | getItem (h::t) = SOME (h, t)

  fun nth (l:'a list, index) =
      let
        fun loop (nil:'a list, _) = raise Subscript
          | loop (h::t, 0) = h
          | loop (_::t, i) = loop (t, i - 1)
      in
        if index < 0 then raise Subscript else loop (l, index)
      end

  fun take (l:'a list, len) =
      let
        fun loop (_:'a list, 0, r) = rev r
          | loop (nil, _, _) = raise Subscript
          | loop (h::t, i, r) = loop (t, i - 1, h::r)
      in
        if len < 0 then raise Subscript else loop (l, len, nil)
      end

  fun drop (l:'a list, len) =
      let
        fun loop (l:'a list, 0) = l
          | loop (nil, _) = raise Subscript
          | loop (_::t, i) = loop (t, i - 1)
      in
        if len < 0 then raise Subscript else loop (l, len)
      end

  fun concat (lists:'a list list) =
      let
        fun loop (nil:'a list list, r) = rev r
          | loop (h::t, r) = loop (t, revAppend (h, r))
      in
        loop (lists, nil)
      end

  fun app f nil = ()
    | app f (h::t) = (f h : unit; app f t)

  fun map f (l:'a list) =
      let
        fun loop (nil:'a list, r) = rev r
          | loop (h::t, r) = loop (t, f h :: r)
      in
        loop (l, nil)
      end

  fun find predicate nil = NONE
    | find predicate (h::t) =
      if predicate h then SOME h else find predicate t

  fun filter predicate (l:'a list) =
      let
        fun loop (nil:'a list, r) = rev r
          | loop (h::t, r) = loop (t, if predicate h then h::r else r)
      in
        loop (l, nil)
      end

  fun mapPartial f (l:'a list) =
      let
        fun loop (nil:'a list, r) = rev r
          | loop (h::t, r) =
            case f h of SOME h => loop (t, h::r) | NONE => loop (t, r)
      in
        loop (l, nil)
      end

  fun partition predicate (l:'a list) =
      let
        fun loop (nil:'a list, positives, negatives) =
            (rev positives, rev negatives)
          | loop (h::t, positives, negatives) =
            if predicate h
            then loop (t, h::positives, negatives)
            else loop (t, positives, h::negatives)
      in
        loop (l, nil, nil)
      end

  fun foldl f z (l:'a list) =
      let
        fun loop (nil:'a list, z) = z
          | loop (h::t, z) = loop (t, f (h, z))
      in
        loop (l, z)
      end

  fun foldr f z (l:'a list) =
      let
        fun loop (nil:'a list, z) = z
          | loop (h::t, z) = f (h, loop (t, z))
      in
        loop (l, z)
      end

  fun exists predicate nil = false
    | exists predicate (h::t) = predicate h orelse exists predicate t

  fun all predicate nil = true
    | all predicate (h::t) = predicate h andalso all predicate t

  fun tabulate (len, elemFn) =
      let
        fun loop (i, r) =
            if i >= len then rev r else loop (i + 1, elemFn i :: r)
      in
        if len < 0 then raise Size else loop (0, nil)
      end

  fun collate cmpFn (l1, l2) =
      let
        fun loop (nil, _::_) = General.LESS
          | loop (nil, nil) = General.EQUAL
          | loop (_::_, nil) = General.GREATER
          | loop (h1::t1, h2::t2) =
            case cmpFn (h1, h2) of
              General.EQUAL => loop (t1, t2)
            | order => order
      in
        loop (l1, l2)
      end

end
