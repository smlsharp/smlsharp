structure PickleTest001 =
struct

  structure EA = ExtensibleArray(structure A = Word8Array
                                 structure V = Word8Vector)
  structure P = Pickle

  fun toString pu value =
      let
        val buffer = EA.array (0, 0w0)
        val next = ref 0
        val writer =
            {
              putByte =
              fn byte => (EA.update (buffer, !next, byte); next := !next + 1),
              seekRelative = SOME (fn offset => next := !next + offset)
            }
      in
        P.pickle pu value (P.makeOutstream writer);
        Byte.bytesToString (EA.toVector buffer)
      end

  fun fromString pu string =
      let
        val pos = ref 0
        val reader =
            {
              getByte = 
              fn () =>
                 (Word8.fromInt o Char.ord o String.sub) (string, !pos)
                 before pos := !pos + 1,
              seekRelative = SOME (fn offset => pos := !pos + offset)
            }
      in
        P.unpickle pu (P.makeInstream reader)
      end

  fun test001 () =
      let
        val pu = P.lazy (P.tuple2(P.int, P.string))
        val v = (1, "hoge")
        val s = toString pu (fn () => v)
        val v' = fromString pu s ()
      in
        v = v'
      end

  fun test002 () =
      let
        val pu =
            P.tuple3(P.string, P.lazy (P.tuple2(P.int, P.string)), P.string)
        val v = ("aa", (fn () => (9, "bb")), "cc")
        val s = toString pu v
        val v' = fromString pu s
      in
        (v, v')
      end

end;

