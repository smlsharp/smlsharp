(**
 * NativeDataTransporter is a data structure converter between ML value and
 * 'native' data structure.
 * @author YAMATODANI Kiyoshi
 * @copyright 2010, Tohoku University.
 * @version $Id: NativeDataTransporter.sml,v 1.2 2007/05/20 05:32:56 kiyoshiy Exp $
 *)
structure NativeDataTransporter :> NATIVE_DATA_TRANSPORTER =
struct

  (**********************************************************************)

  structure A = Word8Array
  structure H = HashTable
  structure UM = UnmanagedMemory
  structure FLOB = SMLSharp.FLOB

  (**********************************************************************)

  type pe = (Dyn.dyn, UM.address) H.hash_table
  type upe = (UM.address, Dyn.dyn) H.hash_table
  type refs = (UM.address, Dyn.dyn) H.hash_table

  type 'a exporter =
       'a * (int * Word8.word -> unit) * int * refs * pe
       -> (int * (unit -> unit))
  type 'a importr = (int -> Word8.word) * int * refs * upe -> ('a * int)
  type 'a sizeof = 'a * int -> int
  type hash = int * word
  type 'a hasher = 'a -> hash -> hash

  type 'a transporter =
       {
         export : 'a exporter,
         import : 'a importr,
         sizeof : 'a sizeof,
         hash : 'a hasher
       }

  type 'a external =
       {
         transporter : 'a transporter,
         (** mapping address to Dynamic to keep sharing property of 'ref' and
          * 'array'. *)
         refs : refs,
         (** the address of allocated memory where exported data is stored. *)
         address : UM.address,
         (** function to release external memory allocated at 'export'. *)
         cleaner : unit -> unit
       }

  (**********************************************************************)

  exception NullPointerException

  (**********************************************************************)

  fun subArray array index = A.sub (array, index)
  fun updateArray array (index, byte) = A.update (array, index, byte)
  fun subMemory address index = UM.sub (UM.advance (address, index))
  fun updateMemory address (index, byte) =
      UM.update (UM.advance (address, index), byte)

  fun equalAddress (a1, a2) = UM.addressToWord a1 = UM.addressToWord a2

  (* We assume that imported/exported data structure is not so complex.
   * So, we use small hash table. *)
  val sizeHint = 10
  val maxDepth = 5
  local
    val Alpha = 0w65599
    val Beta = 0w19
    val hashTag = ref 0w1
  in
  fun hashAdd hash ((depth, accum) : hash) =
      (depth - 1, hash + accum * Alpha)
  fun hashAddSmall hash (depth, accum) =
      (depth - 1, hash + accum * Beta)
  fun maybestop f (s as (depth, accum)) =
      if depth <= 0 then s else f s
(*
  fun newHashTag() = !hashTag before hashTag := !hashTag + 0w1
*)
  end

  (**********************************************************************)

  local
    fun calcAlign alignment offset =
        case offset mod alignment
         of 0 => offset
          | m => offset + alignment - m
  in
  fun align alignment (transporter : 'a transporter) =
      {
        export =
        fn (v, update, offset, refs, pe) =>
           #export
               transporter (v, update, calcAlign alignment offset, refs, pe),
        import =
        fn (sub, offset, refs, upe) =>
           #import transporter (sub, calcAlign alignment offset, refs, upe),
        sizeof =
        fn (v, offset) => #sizeof transporter (v, calcAlign alignment offset),
        hash = fn v => #hash transporter v
      } : 'a transporter
  end

  fun conv
          (convPickle : 'a -> 'b, convUnpickle : 'b -> 'a)
          (transporter : 'a transporter) =
      {
        export =
        fn (v, update, offset, refs, pe) =>
           #export transporter (convUnpickle v, update, offset, refs, pe),
        import =
        fn arg =>
           case #import transporter arg
            of (v, offset) => (convPickle v, offset),
        sizeof =
        fn (v, offset) => #sizeof transporter (convUnpickle v, offset),
        hash = fn v => #hash transporter (convUnpickle v)
      } : 'b transporter

  val byte : Word8.word transporter =
      {
        export =
        fn (word, update, offset, _, _) =>
           (update (offset, word); (offset + 1, fn () => ())),
        import = fn (sub, start, _, _) => (sub start, start + 1),
        sizeof = fn (_, offset) => offset + 1,
        hash = fn byte => hashAdd (Word.fromLargeWord(Word8.toLargeWord byte))
      }

  local
    val BytesPerElem = PackWord32Big.bytesPerElem
    val buffer = A.array (BytesPerElem, 0w0)
    fun export unpack (word, update, offset, _, _) =
        (
          unpack (buffer, 0, word);
          A.appi (fn (index, byte) => update (offset + index, byte)) buffer;
          (offset + BytesPerElem, fn () => ())
        )
    fun import pack (sub, start, _, _) =
        (
          A.appi
              (fn (index, _) => A.update (buffer, index, sub (start + index)))
              buffer;
          (pack (buffer, 0), start + BytesPerElem)
        )
    fun sizeof (_, offset) = offset + BytesPerElem
    fun hash word = hashAdd word
  in
  val wordBig : Word.word transporter =
      {
        export = fn x => export PackWord32Big.update x,
        import = fn x => import PackWord32Big.subArr x,
        sizeof = sizeof,
        hash = hash
      }
  val wordLittle : Word.word transporter =
      {
        export = fn x => export PackWord32Little.update x,
        import = fn x => import PackWord32Little.subArr x,
        sizeof = sizeof,
        hash = hash
      }
  val word : Word.word transporter =
      case SMLSharp.Platform.byteOrder of
        SMLSharp.Platform.LittleEndian => wordLittle
      | SMLSharp.Platform.BigEndian => wordBig
  end

  val word32Big = wordBig
  val word32Little = wordLittle
  val word32 = word

  val intBig = conv (Word.toIntX, Word.fromInt) wordBig
  val intLittle = conv (Word.toIntX, Word.fromInt) wordLittle
  val int = conv (Word.toIntX, Word.fromInt) word

  val int32Big = intBig
  val int32Little = intLittle
  val int32 = int

  local
    val BytesPerElem = PackReal64Big.bytesPerElem
    val buffer = A.array (BytesPerElem, 0w0)
    fun export unpack (real, update, offset, _, _) =
        (
          unpack (buffer, 0, real);
          A.appi (fn (index, byte) => update (offset + index, byte)) buffer;
          (offset + BytesPerElem, fn () => ())
        )
    fun import pack (sub, start, _, _) =
        (
          A.appi
              (fn (index, _) => A.update (buffer, index, sub (start + index)))
              buffer;
          (pack (buffer, 0), start + BytesPerElem)
        )
    fun sizeof (_, offset) = offset + BytesPerElem
    fun hash real = hashAdd (Word.fromInt (Real.floor real))
  in
  val realBig : Real.real transporter =
      {
        export = fn x => export PackReal64Big.update x,
        import = fn x => import PackReal64Big.subArr x,
        sizeof = sizeof,
        hash = hash
      }
  val realLittle : Real.real transporter =
      {
        export = fn x => export PackReal64Little.update x,
        import = fn x => import PackReal64Little.subArr x,
        sizeof = sizeof,
        hash = hash
      }
  val real : Real.real transporter =
      case SMLSharp.Platform.byteOrder of
        SMLSharp.Platform.LittleEndian => realLittle
      | SMLSharp.Platform.BigEndian => realBig
  end

  val char = conv (Byte.byteToChar, Byte.charToByte) byte

  val address = conv (UM.wordToAddress, UM.addressToWord) word

  local
    fun export (v, update, offset, refs, pe) =
        let
          val fixedString = FLOB.fixedCopy v
          val adr = FLOB.addressOf fixedString
          fun cleaner1 () = FLOB.release fixedString
          val (s, cleaner2) = #export address (adr, update, offset, refs, pe)
        in
          (s, cleaner1 o cleaner2)
        end
    fun import (sub, start, refs, upe) =
        let
          val (adr, offset) = #import address (sub, start, refs, upe)
          val _ = if UM.isNULL adr then raise NullPointerException else ()
          fun untilNull index bytes =
              case UM.sub (UM.advance (adr, index)) of
                0w0 =>
                (Byte.bytesToString o Word8Vector.fromList o List.rev) bytes
              | byte => untilNull (index + 1) (byte :: bytes)
          val string = untilNull 0 []
        in
          (string, offset)
        end
  in
  val string =
      let
        fun sizeof (v, offset) = offset + 4
        fun hash string = hashAdd (Word.fromInt (String.size string))
      in
        {
          export = export,
          import = import,
          sizeof = sizeof,
          hash = hash
        }
      end
  end

  local
    fun export transporter (v, update, offset, refs, pe) =
        let
          val expectedSize = #sizeof transporter (v, 0)
          val fixedArray = FLOB.fixedCopy (A.array (expectedSize, 0w0))
          val adr = FLOB.addressOf fixedArray
          val (actualSize, cleaner1) =
              #export
                  transporter (v, FLOB.app updateArray fixedArray, 0, refs, pe)
          val _ =
              if expectedSize = actualSize
              then ()
              else raise Fail "wrong size of exportd data."
          val (s2, cleaner2) = #export address (adr, update, offset, refs, pe)
        in
          (s2, fn () => (FLOB.release fixedArray; cleaner2 (); cleaner1 ()))
        end
    fun import transporter (sub, start, refs, upe) =
        let
          val (adr, offset) = #import address (sub, start, refs, upe)
          val _ = if UM.isNULL adr then raise NullPointerException else ()
(*
          val _ =
              if SMLSharp.FLOB.isAddressOfFLOB adr
              then ()
              else
                raise
                  Fail
                      ("encountered not FLOB address:"
                       ^ Word.toString(UM.addressToWord adr))
*)
          val (v, _) = #import transporter (subMemory adr, 0, refs, upe)
        in
          (v, offset)
        end
  in
  fun boxed (transporter : 'a transporter) =
      let
        fun sizeof (v, offset) = offset + 4
        fun hash v = #hash transporter v
      in
        {
          export = export transporter,
          import = import transporter,
          sizeof = sizeof,
          hash = hash
        }
      end
  end

  local
    fun export transporter toDyn (vr, update, offset, refs, pe) =
        let
          val d = toDyn vr
          val (adr, cleaner1) = 
              case H.find pe d of
                SOME address => (address, fn _ => ())
              | NONE =>
                let
                  val expectedSize = #sizeof transporter (!vr, 0)
                  val fixedArray = FLOB.fixedCopy (A.array (expectedSize, 0w0))
                  val adr = FLOB.addressOf fixedArray
                  val _ = H.insert pe (d, adr)
                  val _ = H.insert refs (adr, d)
                  val (actualSize, cleaner1) =
                      #export
                          transporter
                          (!vr, FLOB.app updateArray fixedArray, 0, refs, pe)
                  val _ =
                      if expectedSize = actualSize
                      then ()
                      else raise Fail "wrong size of exportd data."
                in
                  (adr, fn () => (cleaner1 (); FLOB.release fixedArray))
                end
          val (s2, cleaner2) = #export address (adr, update, offset, refs, pe)
        in
          (s2, fn () => (cleaner2 (); cleaner1 ()))
        end
    fun import dummy transporter (fromDyn, toDyn) (sub, start, refs, upe) =
        let
          val (adr, offset) = #import address (sub, start, refs, upe)
          val _ = if UM.isNULL adr then raise NullPointerException else ()
(*
          val _ =
              if SMLSharp.FLOB.isAddressOfFLOB adr
              then ()
              else
                raise
                  Fail
                      ("encountered not FLOB address."
                       ^ Word.toString(UM.addressToWord adr))
*)
        in
          case H.find upe adr of
            SOME d => (fromDyn d, offset)
          | NONE =>
            let
              val (d, vr) =
                  case H.find refs adr of
                    SOME d => (d, fromDyn d)
                  | NONE => let val vr = ref dummy in (toDyn vr, vr) end
              val _ = H.insert upe (adr, d)
              val (v, _) =
                      #import transporter (subMemory adr, 0, refs, upe)
              val _ = vr := v
            in
              (vr, offset)
            end
        end
  in
  fun refNonNull (dummy : 'a) (transporter : 'a transporter) =
      let
        (* Do not use newHashTag. *)
        fun hash vr = #hash transporter (!vr)
        val (toDyn, fromDyn) =
            Dyn.new (op =) (fn v => #2 (hash v (maxDepth, 0w0)))
        fun sizeof (vr, offset) = offset + 4
      in
        {
          export = export transporter toDyn,
          import = import dummy transporter (fromDyn, toDyn),
          sizeof = sizeof,
          hash = hash
        }
      end
  end

  local
    fun export
            (transporter : 'a transporter)
            toDyn
            (ar, update, offset, refs, pe) =
        let
          val d = toDyn ar
          val (adr, cleaner1) = 
              case H.find pe d of
                SOME address => (address, fn _ => ())
              | NONE =>
                let
                  val expectedSize = Array.foldl (#sizeof transporter) 0 ar
                  val fixedArray = FLOB.fixedCopy (A.array (expectedSize, 0w0))
                  val adr = FLOB.addressOf fixedArray
                  val _ = H.insert pe (d, adr)
                  val _ = H.insert refs (adr, d)
                  val update = FLOB.app updateArray fixedArray
                  fun exportElem (elem, (offset, cleaner)) =
                      let
                        val (offset', cleaner') = 
                            #export
                                transporter (elem, update, offset, refs, pe)
                      in (offset', cleaner' o cleaner)
                      end
                  val (actualSize, cleaner1) =
                      Array.foldl exportElem (0, fn () => ()) ar
                  val _ =
                      if expectedSize = actualSize
                      then ()
                      else raise Fail "wrong size of exportd data."
                in
                  (adr, fn () => (cleaner1 (); FLOB.release fixedArray))
                end
          val (s2, cleaner2) = #export address (adr, update, offset, refs, pe)
        in
          (s2, fn () => (cleaner2 (); cleaner1 ()))
        end
    fun import (transporter : 'a transporter) fromDyn (sub, start, refs, upe) =
        let
          val (adr, offset) = #import address (sub, start, refs, upe)
          val _ = if UM.isNULL adr then raise NullPointerException else ()
(*
          val _ =
              if SMLSharp.FLOB.isAddressOfFLOB adr
              then ()
              else
                raise
                  Fail
                      ("encountered not FLOB address:"
                       ^ Word.toString(UM.addressToWord adr))
*)
        in
          case H.find upe adr of
            SOME d => (fromDyn d, offset)
          | NONE =>
            let
              val d =
                  case H.find refs adr of
                    SOME d => d
                  | NONE => raise Fail "unknown array address."
              val _ = H.insert upe (adr, d)
              val ar = fromDyn d
              fun importElem (index, _, offset) =
                  let
                    val (v, offset') = 
                        #import transporter (subMemory adr, offset, refs, upe)
                    val _ = Array.update (ar, index, v)
                  in offset' end
              val _ = Array.foldli importElem 0 ar
            in
              (ar, offset)
            end
        end
  in
  fun flatArray (transporter : 'a transporter) =
      let
        (* Do not use newHashTag. *)
        fun hash ar =
            let val sz = Word.fromInt (Array.length ar)
            in maybestop (hashAddSmall sz) end
        val (toDyn, fromDyn) =
            Dyn.new (op =) (fn v => #2 (hash v (maxDepth, 0w0)))
        fun sizeof (vr, offset) = offset + 4
      in
        {
          export = fn x => export transporter toDyn x,
          import = fn x => import transporter fromDyn x,
          sizeof = sizeof,
          hash = hash
        }
      end
  end

  local
    fun export toDyn (v, update, offset, refs, pe) =
        let
          val d = toDyn v
          val adr = FLOB.addressOf v
          val _ =
              if isSome(H.find refs adr) then () else H.insert refs (adr, d)
        in
          #export address (adr, update, offset, refs, pe)
        end
    fun import fromDyn (sub, start, refs, upe) =
        let
          val (adr, offset) = #import address (sub, start, refs, upe)
          val _ = if UM.isNULL adr then raise NullPointerException else ()
          val v = 
              case H.find refs adr of
                SOME d => fromDyn d
              | NONE => raise Fail "encountered unknown address."
        in
          (v, offset)
        end
  in
  fun FLOB () =
      let
        fun hash v = maybestop (fn p => #hash address (FLOB.addressOf v) p)
        val (toDyn, fromDyn) =
            Dyn.new
                (fn (v1, v2) =>
                    equalAddress (FLOB.addressOf v1, FLOB.addressOf v2))
                (fn v => #2 (hash v (maxDepth, 0w0)))
        fun sizeof (v, offset) = offset + 4
      in
        {
          export = export toDyn,
          import = import fromDyn,
          sizeof = sizeof,
          hash = hash
        }
      end
  end

  local
    fun nullable (transporter : 'a transporter) =
        let
          fun hash (NONE) h = h
            | hash (SOME v) h = #hash transporter v h
          fun export (NONE, update, offset, refs, pe) =
              #export address (UM.NULL, update, offset, refs, pe)
            | export (SOME v, update, offset, refs, pe) =
              #export transporter (v, update, offset, refs, pe)
          fun import (sub, start, refs, upe) =
              let
                val (adr, offset) = #import address (sub, start, refs, upe)
              in
                if UM.isNULL adr then (NONE, offset)
                else (* import from 'start' again. *)
                  let
                    val (v, offset) =
                        #import transporter (sub, start, refs, upe)
                  in (SOME v, offset)
                  end
              end
          fun sizeof (vr, offset) = offset + 4
        in
          {
            export = export,
            import = import,
            sizeof = sizeof,
            hash = hash
          }
        end
  in
  fun refNullable (dummy : 'a) (transporter : 'a transporter) =
      nullable (refNonNull dummy transporter)
  fun boxedNullable transporter = nullable (boxed transporter)
  end

  fun tuple2 (transporter1 : 'a transporter, transporter2 : 'b transporter) =
      let
        fun export ((v1, v2), update, s0, refs, pe) =
            let
              val (s1, cleaner1) =
                  #export transporter1 (v1, update, s0, refs, pe)
              val (s2, cleaner2) =
                  #export transporter2 (v2, update, s1, refs, pe)
            in (s2, cleaner1 o cleaner2)
            end
        fun import (sub, s0, refs, upe) =
            let
              val (v1, s1) = #import transporter1 (sub, s0, refs, upe)
              val (v2, s2) = #import transporter2 (sub, s1, refs, upe)
            in
              ((v1, v2), s2)
            end
        fun sizeof ((v1, v2), s0) =
            let
              val s1 = #sizeof transporter1 (v1, s0)
              val s2 = #sizeof transporter2 (v2, s1)
            in s2
            end
        val hashTag = 0w2
        fun hash (v1, v2) =
            maybestop
                (fn s =>
                    #hash
                        transporter2
                        v2
                        (#hash transporter1 v1 (hashAddSmall hashTag s)))
      in
        {
          export = export,
          import = import,
          sizeof = sizeof,
          hash = hash
        }
      end

  fun tuple3 (transporter1 : 'a transporter, transporter2 : 'b transporter, transporter3 : 'c transporter) =
      let
        val TUP2 = tuple2 (transporter1, transporter2)
        fun export ((v1, v2, v3), update, s0, refs, pe) =
            let
              val (s1, cleaner1) = #export TUP2 ((v1, v2), update, s0, refs, pe)
              val (s3, cleaner3) = #export transporter3 (v3, update, s1, refs, pe)
            in (s3, cleaner1 o cleaner3)
            end
        fun import (sub, s0, refs, upe) =
            let
              val ((v1, v2), s1) = #import TUP2 (sub, s0, refs, upe)
              val (v3, s3) = #import transporter3 (sub, s1, refs, upe)
            in
              ((v1, v2, v3), s3)
            end
        fun sizeof ((v1, v2, v3), s0) =
            let
              val s1 = #sizeof TUP2 ((v1, v2), s0)
              val s3 = #sizeof transporter3 (v3, s1)
            in s3
            end
        val hashTag = 0w3
        fun hash (v1, v2, v3) =
            maybestop
                (fn s =>
                    #hash transporter3 v3
                          (#hash TUP2 (v1, v2)
                                 (hashAddSmall hashTag s)))
      in
        {
          export = export,
          import = import,
          sizeof = sizeof,
          hash = hash
        }
      end

  fun tuple4 (transporter1 : 'a transporter, transporter2 : 'b transporter, transporter3 : 'c transporter, transporter4 : 'd transporter) =
      let
        val TUP3 = tuple3 (transporter1, transporter2, transporter3)
        fun export ((v1, v2, v3, v4), update, s0, refs, pe) =
            let
              val (s1, cleaner1) =
                  #export TUP3 ((v1, v2, v3), update, s0, refs, pe)
              val (s4, cleaner4) = #export transporter4 (v4, update, s1, refs, pe)
            in (s4, cleaner1 o cleaner4)
            end
        fun import (sub, s0, refs, upe) =
            let
              val ((v1, v2, v3), s1) = #import TUP3 (sub, s0, refs, upe)
              val (v4, s4) = #import transporter4 (sub, s1, refs, upe)
            in
              ((v1, v2, v3, v4), s4)
            end
        fun sizeof ((v1, v2, v3, v4), s0) =
            let
              val s1 = #sizeof TUP3 ((v1, v2, v3), s0)
              val s4 = #sizeof transporter4 (v4, s1)
            in s4
            end
        val hashTag = 0w4
        fun hash (v1, v2, v3, v4) =
            maybestop
                (fn s =>
                    #hash transporter4 v4
                          (#hash TUP3 (v1, v2, v3)
                                 (hashAddSmall hashTag s)))
      in
        {
          export = export,
          import = import,
          sizeof = sizeof,
          hash = hash
        }
      end

  fun tuple5
          (transporter1 : 'a transporter, transporter2 : 'b transporter, transporter3 : 'c transporter, transporter4 : 'd transporter, transporter5 : 'e transporter) =
      let
        val TUP4 = tuple4 (transporter1, transporter2, transporter3, transporter4)
        fun export ((v1, v2, v3, v4, v5), update, s0, refs, pe) =
            let
              val (s1, cleaner1) =
                  #export TUP4 ((v1, v2, v3, v4), update, s0, refs, pe)
              val (s5, cleaner5) = #export transporter5 (v5, update, s1, refs, pe)
            in (s5, cleaner1 o cleaner5)
            end
        fun import (sub, s0, refs, upe) =
            let
              val ((v1, v2, v3, v4), s1) = #import TUP4 (sub, s0, refs, upe)
              val (v5, s5) = #import transporter5 (sub, s1, refs, upe)
            in
              ((v1, v2, v3, v4, v5), s5)
            end
        fun sizeof ((v1, v2, v3, v4, v5), s0) =
            let
              val s1 = #sizeof TUP4 ((v1, v2, v3, v4), s0)
              val s5 = #sizeof transporter5 (v5, s1)
            in s5
            end
        val hashTag = 0w5
        fun hash (v1, v2, v3, v4, v5) =
            maybestop
                (fn s =>
                    #hash transporter5 v5
                          (#hash TUP4 (v1, v2, v3, v4)
                                 (hashAddSmall hashTag s)))
      in
        {
          export = export,
          import = import,
          sizeof = sizeof,
          hash = hash
        }
      end

  fun tuple6
          (transporter1 : 'a transporter, transporter2 : 'b transporter, transporter3 : 'c transporter, transporter4 : 'd transporter, transporter5 : 'e transporter,
           transporter6 : 'f transporter) =
      let
        val TUP5 = tuple5 (transporter1, transporter2, transporter3, transporter4, transporter5)
        fun export ((v1, v2, v3, v4, v5, v6), update, s0, refs, pe) =
            let
              val (s1, cleaner1) =
                  #export TUP5 ((v1, v2, v3, v4, v5), update, s0, refs, pe)
              val (s6, cleaner6) = #export transporter6 (v6, update, s1, refs, pe)
            in (s6, cleaner1 o cleaner6)
            end
        fun import (sub, s0, refs, upe) =
            let
              val ((v1, v2, v3, v4, v5), s1) = #import TUP5 (sub, s0, refs, upe)
              val (v6, s6) = #import transporter6 (sub, s1, refs, upe)
            in
              ((v1, v2, v3, v4, v5, v6), s6)
            end
        fun sizeof ((v1, v2, v3, v4, v5, v6), s0) =
            let
              val s1 = #sizeof TUP5 ((v1, v2, v3, v4, v5), s0)
              val s6 = #sizeof transporter6 (v6, s1)
            in s6
            end
        val hashTag = 0w6
        fun hash (v1, v2, v3, v4, v5, v6) =
            maybestop
                (fn s =>
                    #hash transporter6 v6
                          (#hash TUP5 (v1, v2, v3, v4, v5)
                                 (hashAddSmall hashTag s)))
      in
        {
          export = export,
          import = import,
          sizeof = sizeof,
          hash = hash
        }
      end

  fun tuple7
          (transporter1 : 'a transporter, transporter2 : 'b transporter, transporter3 : 'c transporter, transporter4 : 'd transporter, transporter5 : 'e transporter,
           transporter6 : 'f transporter, transporter7 : 'g transporter) =
      let
        val TUP6 = tuple6 (transporter1, transporter2, transporter3, transporter4, transporter5, transporter6)
        fun export ((v1, v2, v3, v4, v5, v6, v7), update, s0, refs, pe) =
            let
              val (s1, cleaner1) =
                  #export TUP6 ((v1, v2, v3, v4, v5, v6), update, s0, refs, pe)
              val (s7, cleaner7) = #export transporter7 (v7, update, s1, refs, pe)
            in (s7, cleaner1 o cleaner7)
            end
        fun import (sub, s0, refs, upe) =
            let
              val ((v1, v2, v3, v4, v5, v6), s1) =
                  #import TUP6 (sub, s0, refs, upe)
              val (v7, s7) = #import transporter7 (sub, s1, refs, upe)
            in
              ((v1, v2, v3, v4, v5, v6, v7), s7)
            end
        fun sizeof ((v1, v2, v3, v4, v5, v6, v7), s0) =
            let
              val s1 = #sizeof TUP6 ((v1, v2, v3, v4, v5, v6), s0)
              val s7 = #sizeof transporter7 (v7, s1)
            in s7
            end
        val hashTag = 0w7
        fun hash (v1, v2, v3, v4, v5, v6, v7) =
            maybestop
                (fn s =>
                    #hash transporter7 v7
                          (#hash TUP6 (v1, v2, v3, v4, v5, v6)
                                 (hashAddSmall hashTag s)))
      in
        {
          export = export,
          import = import,
          sizeof = sizeof,
          hash = hash
        }
      end

  fun tuple8
          (transporter1 : 'a transporter, transporter2 : 'b transporter, transporter3 : 'c transporter, transporter4 : 'd transporter, transporter5 : 'e transporter,
           transporter6 : 'f transporter, transporter7 : 'g transporter, transporter8 : 'h transporter) =
      let
        val TUP7 = tuple7 (transporter1, transporter2, transporter3, transporter4, transporter5, transporter6, transporter7)
        fun export ((v1, v2, v3, v4, v5, v6, v7, v8), update, s0, refs, pe) =
            let
              val (s1, cleaner1) =
                  #export TUP7 ((v1, v2, v3, v4, v5, v6, v7), update, s0, refs, pe)
              val (s8, cleaner8) = #export transporter8 (v8, update, s1, refs, pe)
            in (s8, cleaner1 o cleaner8)
            end
        fun import (sub, s0, refs, upe) =
            let
              val ((v1, v2, v3, v4, v5, v6, v7), s1) =
                  #import TUP7 (sub, s0, refs, upe)
              val (v8, s8) = #import transporter8 (sub, s1, refs, upe)
            in
              ((v1, v2, v3, v4, v5, v6, v7, v8), s8)
            end
        fun sizeof ((v1, v2, v3, v4, v5, v6, v7, v8), s0) =
            let
              val s1 = #sizeof TUP7 ((v1, v2, v3, v4, v5, v6, v7), s0)
              val s8 = #sizeof transporter8 (v8, s1)
            in s8
            end
        val hashTag = 0w8
        fun hash (v1, v2, v3, v4, v5, v6, v7, v8) =
            maybestop
                (fn s =>
                    #hash transporter8 v8
                          (#hash TUP7 (v1, v2, v3, v4, v5, v6, v7)
                                 (hashAddSmall hashTag s)))
      in
        {
          export = export,
          import = import,
          sizeof = sizeof,
          hash = hash
        }
      end

  fun tuple9
          (transporter1 : 'a transporter, transporter2 : 'b transporter, transporter3 : 'c transporter, transporter4 : 'd transporter, transporter5 : 'e transporter,
           transporter6 : 'f transporter, transporter7 : 'g transporter, transporter8 : 'h transporter, transporter9 : 'i transporter) =
      let
        val TUP8 = tuple8 (transporter1, transporter2, transporter3, transporter4, transporter5, transporter6, transporter7, transporter8)
        fun export ((v1, v2, v3, v4, v5, v6, v7, v8, v9), update, s0, refs, pe) =
            let
              val (s1, cleaner1) =
                  #export TUP8 ((v1, v2, v3, v4, v5, v6, v7, v8), update, s0, refs, pe)
              val (s9, cleaner9) = #export transporter9 (v9, update, s1, refs, pe)
            in (s9, cleaner1 o cleaner9)
            end
        fun import (sub, s0, refs, upe) =
            let
              val ((v1, v2, v3, v4, v5, v6, v7, v8), s1) =
                  #import TUP8 (sub, s0, refs, upe)
              val (v9, s9) = #import transporter9 (sub, s1, refs, upe)
            in
              ((v1, v2, v3, v4, v5, v6, v7, v8, v9), s9)
            end
        fun sizeof ((v1, v2, v3, v4, v5, v6, v7, v8, v9), s0) =
            let
              val s1 = #sizeof TUP8 ((v1, v2, v3, v4, v5, v6, v7, v8), s0)
              val s9 = #sizeof transporter9 (v9, s1)
            in s9
            end
        val hashTag = 0w9
        fun hash (v1, v2, v3, v4, v5, v6, v7, v8, v9) =
            maybestop
                (fn s =>
                    #hash transporter9 v9
                          (#hash TUP8 (v1, v2, v3, v4, v5, v6, v7, v8)
                                 (hashAddSmall hashTag s)))
      in
        {
          export = export,
          import = import,
          sizeof = sizeof,
          hash = hash
        }
      end

  fun tuple10
          (transporter1 : 'a transporter, transporter2 : 'b transporter, transporter3 : 'c transporter, transporter4 : 'd transporter, transporter5 : 'e transporter,
           transporter6 : 'f transporter, transporter7 : 'g transporter, transporter8 : 'h transporter, transporter9 : 'i transporter, transporter10 : 'j transporter) =
      let
        val TUP9 = tuple9 (transporter1, transporter2, transporter3, transporter4, transporter5, transporter6, transporter7, transporter8, transporter9)
        fun export ((v1, v2, v3, v4, v5, v6, v7, v8, v9, v10), update, s0, refs, pe) =
            let
              val (s1, cleaner1) =
                  #export TUP9 ((v1, v2, v3, v4, v5, v6, v7, v8, v9), update, s0, refs, pe)
              val (s10, cleaner10) = #export transporter10 (v10, update, s1, refs, pe)
            in (s10, cleaner1 o cleaner10)
            end
        fun import (sub, s0, refs, upe) =
            let
              val ((v1, v2, v3, v4, v5, v6, v7, v8, v9), s1) =
                  #import TUP9 (sub, s0, refs, upe)
              val (v10, s10) = #import transporter10 (sub, s1, refs, upe)
            in
              ((v1, v2, v3, v4, v5, v6, v7, v8, v9, v10), s10)
            end
        fun sizeof ((v1, v2, v3, v4, v5, v6, v7, v8, v9, v10), s0) =
            let
              val s1 = #sizeof TUP9 ((v1, v2, v3, v4, v5, v6, v7, v8, v9), s0)
              val s10 = #sizeof transporter10 (v10, s1)
            in s10
            end
        val hashTag = 0w10
        fun hash (v1, v2, v3, v4, v5, v6, v7, v8, v9, v10) =
            maybestop
                (fn s =>
                    #hash transporter10 v10
                          (#hash TUP9 (v1, v2, v3, v4, v5, v6, v7, v8, v9)
                                 (hashAddSmall hashTag s)))
      in
        {
          export = export,
          import = import,
          sizeof = sizeof,
          hash = hash
        }
      end

  (****************************************)

  local
    val buffer = A.array (4, 0w0)
  in
  fun export (transporter : 'a transporter) (v : 'a) =
      let
        val pe : pe = H.mkTable (Dyn.hash, Dyn.eq) (sizeHint, Fail "not found")
        val upe : upe =
            H.mkTable
                (UM.addressToWord, equalAddress) (sizeHint, Fail "not found")
        val refs : refs =
            H.mkTable
                (UM.addressToWord, equalAddress) (sizeHint, Fail "not found")
        val expectedSize = #sizeof transporter (v, 0)
        val _ =
            if expectedSize = 4
            then ()
            else raise Fail "support only word size."
        val (actualSize, cleaner) =
            #export transporter (v, updateArray buffer, 0, refs, pe)
        val _ =
            if actualSize = expectedSize
            then ()
            else raise Fail "wrong size of exportd data."
        val (adr, _) = #import address (subArray buffer, 0, refs, upe)
      in
        {
          transporter = transporter,
          refs = refs,
          address = adr,
          cleaner = cleaner
        }
        : 'a external
      end
  end

  fun attach (transporter : 'a transporter) adr =
      let
        val pe : pe = H.mkTable (Dyn.hash, Dyn.eq) (sizeHint, Fail "not found")
        val refs : refs =
            H.mkTable
                (UM.addressToWord, equalAddress) (sizeHint, Fail "not found")
      in
        {
          transporter = transporter,
          refs = refs,
          address = adr,
          cleaner = fn () => ()
        }
        : 'a external
      end

  local
    val buffer = A.array (4, 0w0)
  in
  fun import ({transporter, refs, address = adr, ...} : 'a external) =
      let
        val pe : pe = H.mkTable (Dyn.hash, Dyn.eq) (sizeHint, Fail "not found")
        val upe : upe =
            H.mkTable
                (UM.addressToWord, equalAddress) (sizeHint, Fail "not found")
        val (_, cleaner) =
            #export address (adr, updateArray buffer, 0, refs, pe)
        val (v, offset) = #import transporter (subArray buffer, 0, refs, upe)
        val _ = cleaner ()
        val _ = H.clear upe
      in
        v
      end
  end

  fun addressOf ({address, ...} : 'a external) = address

  fun release ({cleaner, ...} : 'a external) = cleaner ()

end
