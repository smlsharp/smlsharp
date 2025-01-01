(**
 * ListPair
 * @author UENO Katsuhiro
 * @author YAMATODANI Kiyoshi
 * @copyright (C) 2021 SML# Development Team.
 *)

infixr 5 ::

structure ListPair =
struct

  exception UnequalLengths

  fun revAppend (nil : 'a list) r = r
    | revAppend (h :: t) r = revAppend t (h :: r)

  fun zipRevAppend (h1 :: t1) (h2 :: t2) r = zipRevAppend t1 t2 ((h1, h2) :: r)
    | zipRevAppend _ _ r = r

  fun zipEqRevAppend (h1 :: t1) (h2 :: t2) r =
      zipEqRevAppend t1 t2 ((h1, h2) :: r)
    | zipEqRevAppend nil nil r = r
    | zipEqRevAppend _ _ _ = raise UnequalLengths

  fun zip (l1, l2) = revAppend (zipRevAppend l1 l2 nil) nil

  fun zipEq (l1, l2) = revAppend (zipEqRevAppend l1 l2 nil) nil

  fun unzip pairs =
      let
        fun loop nil l r = (revAppend l nil, revAppend r nil)
          | loop ((h1, h2) :: t) l r = loop t (h1 :: l) (h2 :: r)
      in
        loop pairs nil nil
      end

  fun map mapFn (l1, l2) =
      let
        fun loop (h1 :: t1) (h2 :: t2) r = loop t1 t2 (mapFn (h1, h2) :: r)
          | loop _ _ r = revAppend r nil
      in
        loop l1 l2 nil
      end

  fun mapEq mapFn (l1, l2) =
      let
        fun loop (h1 :: t1) (h2 :: t2) r = loop t1 t2 (mapFn (h1, h2) :: r)
          | loop nil nil r = revAppend r nil
          | loop _ _ _ = raise UnequalLengths
      in
        loop l1 l2 nil
      end

  fun app appFn (l1, l2) =
      let
        fun loop (h1 :: t1) (h2 :: t2) = (appFn (h1, h2) : unit; loop t1 t2)
          | loop _ _ = ()
      in
        loop l1 l2
      end

  fun appEq appFn (l1, l2) =
      let
        fun loop (h1 :: t1) (h2 :: t2) = (appFn (h1, h2) : unit; loop t1 t2)
          | loop nil nil = ()
          | loop _ _ = raise UnequalLengths
      in
        loop l1 l2
      end

  fun foldl foldFn z (l1, l2) =
      let
        fun loop (h1 :: t1) (h2 :: t2) z = loop t1 t2 (foldFn (h1, h2, z))
          | loop _ _ z = z
      in
        loop l1 l2 z
      end

  fun foldlEq foldFn z (l1, l2) =
      let
        fun loop (h1 :: t1) (h2 :: t2) z = loop t1 t2 (foldFn (h1, h2, z))
          | loop nil nil z = z
          | loop _ _ _ = raise UnequalLengths
      in
        loop l1 l2 z
      end

  fun foldr foldFn z (l1 : 'a list, l2 : 'b list) =
      let
        fun loop ((x : 'a, y : 'b) :: t) z = loop t (foldFn (x, y, z))
          | loop nil z = z
      in
        loop (zipRevAppend l1 l2 nil) z
      end

  fun foldrEq foldFn z (l1 : 'a list, l2 : 'b list) =
      let
        fun loop ((x : 'a, y : 'b) :: t) z = loop t (foldFn (x, y, z))
          | loop nil z = z
      in
        loop (zipEqRevAppend l1 l2 nil) z
      end

  fun all predicate (l1, l2) =
      let
        fun loop (h1 :: t1) (h2 :: t2) = predicate (h1, h2) andalso loop t1 t2
          | loop _ _ = true
      in
        loop l1 l2
      end

  fun allEq predicate (l1, l2) =
      let
        fun loop (h1 :: t1) (h2 :: t2) = predicate (h1, h2) andalso loop t1 t2
          | loop nil nil = true
          | loop _ _ = false
      in
        loop l1 l2
      end

  fun exists predicate (l1, l2) =
      let
        fun loop (h1 :: t1) (h2 :: t2) = predicate (h1, h2) orelse loop t1 t2
          | loop _ _ = false
      in
        loop l1 l2
      end

end
