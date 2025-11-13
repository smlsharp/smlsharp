(**
 * Snoc structure.
 * @author Katsuhiro Ueno
 * @copyright (C) 2025 SML# Development Team.
 *)

infix  6 + - ^
infixr 5 :: @
infix  4 = <> > >= < <=
val op + = SMLSharp_Builtin.Int32.add_unsafe
val op - = SMLSharp_Builtin.Int32.sub_unsafe
val op >= = SMLSharp_Builtin.Int32.gteq
val op < = SMLSharp_Builtin.Int32.lt
structure Int32 = SMLSharp_Builtin.Int32

infix 5 ::>

structure Snoc =
struct
  datatype 'a snoc = NIL | ::> of 'a snoc * 'a

  exception Empty = List.Empty

  fun null NIL = true
    | null _ = false

  fun last NIL = raise Empty
    | last (_ ::> t) = t

  fun length' NIL z = z
    | length' (h ::> _) z = length' h (Int32.add (z, 1))

  fun length l = length' l 0

  fun prepend' NIL l = l
    | prepend' (h ::> t) l = prepend' h (t :: l)

  fun prepend (l, r) = prepend' l r

  fun append' l nil = l
    | append' l (h :: t) = append' (l ::> h) t

  fun append (l, r) = append' l r

  fun toList l = prepend' l nil

  fun fromList l = append' NIL l

  fun concat' NIL r = r
    | concat' (h ::> t) r = concat' h (prepend' t r)

  fun concat l = concat' l nil

  fun concatList' nil r = r
    | concatList' (h :: t) r = concatList' t (append' r h)

  fun concatList l = concatList' l NIL

  fun app' f NIL = ()
    | app' f (h ::> t) = (f t : unit; app' f h)

  fun app f l = app' f l

  fun mapPrepend' f NIL r = r
    | mapPrepend' f (h ::> t) r = mapPrepend' f h (f t :: r)

  fun mapPrepend f (l, r) = mapPrepend' f l r

  fun mapAppend' f l nil = l
    | mapAppend' f l (h :: t) = mapAppend' f (l ::> f h) t

  fun mapAppend f (l, r) = mapAppend' f l r

  fun map f l = mapPrepend' f l nil

  fun mapList f l = mapAppend' f NIL l

  fun filterPrepend' f NIL r = r
    | filterPrepend' f (h ::> t) r =
      if f t
      then filterPrepend' f h (t :: r)
      else filterPrepend' f h r

  fun filterPrepend f (l, r) = filterPrepend' f l r

  fun filterAppend' f l nil = l
    | filterAppend' f l (h :: t) =
      if f h
      then filterAppend' f (l ::> h) t
      else filterAppend' f l t

  fun filterAppend f (l, r) = filterAppend' f l r

  fun filter f l = filterPrepend' f l nil

  fun filterList f l = filterAppend' f NIL l

  fun find' f NIL = NONE
    | find' f (h ::> t) = if f t then SOME t else find' f h

  fun find f l = find' f l

  fun foldr' f z NIL = z
    | foldr' f z (h ::> t) = foldr' f (f (t, z)) h

  fun foldr f z l = foldr' f z l

  fun exists' f NIL = false
    | exists' f (h ::> t) = f t orelse exists' f h

  fun exists f l = exists' f l

  fun all' f NIL = true
    | all' f (h ::> t) = f t andalso all' f h

  fun all f l = all' f l
end

datatype snoc = datatype Snoc.snoc
