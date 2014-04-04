(**
 * ListPair
 * @author UENO Katsuhiro
 * @author YAMATODANI Kiyoshi
 * @copyright 2010, 2011, 2012, 2013, Tohoku University.
 *)

infixr 5 ::

structure ListPair =
struct

  exception UnequalLengths

  fun zip (l1, l2) =
      let
        fun loop (h1::t1, h2::t2, z) = loop (t1, t2, (h1,h2)::z)
          | loop (_, _, z) = List.rev z
      in
        loop (l1, l2, nil)
      end

  fun zipEq (l1, l2) =
      let
        fun loop (h1::t1, h2::t2, z) = loop (t1, t2, (h1,h2)::z)
          | loop (nil, nil, z) = List.rev z
          | loop _ = raise UnequalLengths
      in
        loop (l1, l2, nil)
      end

  fun unzip pairs =
      let
        fun loop (nil, l, r) = (List.rev l, List.rev r)
          | loop ((h1, h2)::t, l, r) = loop (t, h1::l, h2::r)
      in
        loop (pairs, nil, nil)
      end

  fun map mapFn (l1, l2) =
      let
        fun loop (h1::t1, h2::t2, z) = loop (t1, t2, mapFn (h1, h2) :: z)
          | loop (_, _, z) = List.rev z
      in
        loop (l1, l2, nil)
      end

  fun mapEq mapFn (l1, l2) =
      let
        fun loop (h1::t1, h2::t2, z) = loop (t1, t2, mapFn (h1, h2) :: z)
          | loop (nil, nil, z) = List.rev z
          | loop _ = raise UnequalLengths
      in
        loop (l1, l2, nil)
      end

  fun app appFn (l1, l2) =
      let
        fun loop (h1::t1, h2::t2) = (appFn (h1, h2) : unit; loop (t1, t2))
          | loop (_, _) = ()
      in
        loop (l1, l2)
      end

  fun appEq appFn (l1, l2) =
      let
        fun loop (h1::t1, h2::t2) = (appFn (h1, h2) : unit; loop (t1, t2))
          | loop (nil, nil) = ()
          | loop _ = raise UnequalLengths
      in
        loop (l1, l2)
      end

  fun foldl foldFn z (l1, l2) =
      let
        fun loop (h1::t1, h2::t2, z) = loop (t1, t2, foldFn (h1, h2, z))
          | loop (_, _, z) = z
      in
        loop (l1, l2, z)
      end

  fun foldlEq foldFn z (l1, l2) =
      let
        fun loop (h1::t1, h2::t2, z) = loop (t1, t2, foldFn (h1, h2, z))
          | loop (nil, nil, z) = z
          | loop _ = raise UnequalLengths
      in
        loop (l1, l2, z)
      end

  fun foldr foldFn z (l1, l2) =
      let
        fun loop (h1::t1, h2::t2, z) = foldFn (h1, h2, loop (t1, t2, z))
          | loop (_, _, z) = z
      in
        loop (l1, l2, z)
      end

  fun foldrEq foldFn z (l1, l2) =
      let
        fun loop (h1::t1, h2::t2, z) = foldFn (h1, h2, loop (t1, t2, z))
          | loop (nil, nil, z) = z
          | loop _ = raise UnequalLengths
      in
        loop (l1, l2, z)
      end

  fun all predicate (l1, l2) =
      let
        fun loop (h1::t1, h2::t2) = predicate (h1, h2) andalso loop (t1, t2)
          | loop _ = true
      in
        loop (l1, l2)
      end

  fun allEq predicate (l1, l2) =
      let
        fun loop (h1::t1, h2::t2) = predicate (h1, h2) andalso loop (t1, t2)
          | loop (nil, nil) = true
          | loop _ = false
      in
        loop (l1, l2)
      end

  fun exists predicate (l1, l2) =
      let
        fun loop (h1::t1, h2::t2) = predicate (h1, h2) orelse loop (t1, t2)
          | loop _ = false
      in
        loop (l1, l2)
      end

end
