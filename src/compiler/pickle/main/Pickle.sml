(**
 * An implementation of serialize combinator based on
 * "Type-Specialized Serialization with Sharing", Martin Elsman
 * @author YAMATODANI Kiyoshi
 * @version $Id: Pickle.sml,v 1.5 2006/02/18 09:10:50 kiyoshiy Exp $
 *)
structure Pickle :> PICKLE =
struct

  (***************************************************************************)

  structure H = HashTable
  structure S = Stream

  (***************************************************************************)

  type pe = (Dyn.dyn, S.loc) H.hash_table
  type upe = (S.loc, Dyn.dyn) H.hash_table

  type reader = S.reader
  type writer = S.writer

  type instream = reader S.stream * upe
  type outstream = writer S.stream * pe

  type 'a pickler = 'a -> outstream -> unit
  type 'a unpickler = instream -> 'a

  type hash = int * word
  type 'a hasher = 'a -> hash -> hash

  type 'a isEqual = 'a * 'a -> bool

  type 'a pu =
       {
         pickler : 'a pickler,
         unpickler : 'a unpickler,
         hasher : 'a hasher,
         eq : 'a isEqual
       }

  (***************************************************************************)

  val enableShare = ref true

  val sizeHint = 100000

  fun makeInstream reader =
      let
        val hashTable : upe =
            H.mkTable
                (
                  fn x => Word.fromLargeWord x,
                  fn (v1, v2) => v1 = (v2 : Word32.word)
                )
                (sizeHint, Fail "not found")
        val stream = Stream.openStream reader
      in
        (stream, hashTable)
      end

  fun makeOutstream writer =
      let
        val hashTable =
            H.mkTable (Dyn.hash, Dyn.eq) (sizeHint, Fail "not found")
        val stream = Stream.openStream writer
      in
        (stream, hashTable)
      end

  fun pickle (pu : 'a pu) (v : 'a) stream = #pickler pu v stream

  fun unpickle (pu : 'a pu) stream = #unpickler pu stream

  fun hash (pu : 'a pu) (v : 'a) hash = #hasher pu v hash

  fun eq (pu : 'a pu) = #eq pu

  fun toString pu value =
      let
        val buffer = ref ([] : Word8.word list)
        fun writer byte = buffer := byte :: (!buffer)
      in
        pickle pu value (makeOutstream writer);
        implode (map (Char.chr o Word8.toInt) (List.rev (!buffer)))
      end

  fun fromString pu string =
      let
        val pos = ref 0
        fun reader () =
            (Word8.fromInt o Char.ord o String.sub) (string, !pos)
            before pos := !pos + 1
      in
        unpickle pu (makeInstream reader)
      end

  val maxDepth = 50
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
  fun newHashTag() = !hashTag before hashTag := !hashTag + 0w1
  end

  fun newHashCon () =
      let val tyConHashTag = newHashTag ()
      in
        fn valConTag =>
           (hashAddSmall tyConHashTag)
           o (hashAddSmall (Word.fromInt valConTag))
      end

  fun make (pickler, unpickler, hasher, isEqual) =
      {
        pickler = pickler,
        unpickler = unpickler,
        hasher = fn v => maybestop (hasher v),
        eq = isEqual
      }

  fun fail message = raise Fail message

  fun pickleByte word (stream, pe) = S.outb(word, stream)
  fun unpickleByte (stream, upe) = let val word = S.getb stream in word end
  fun hashByte word = hashAdd (Word.fromLargeWord(Word8.toLargeWord word))
  val byte : Word8.word pu =
      {
        pickler = pickleByte,
        unpickler = unpickleByte,
        hasher = hashByte,
        eq = op =
      }

  fun pickleWord word (stream, pe) = S.outw(Word.toLargeWord word, stream)
  fun unpickleWord (stream, upe) =
      let val word = S.getw stream in Word.fromLargeWord word end
  fun hashWord word = hashAdd word
  val word : Word.word pu =
      {
        pickler= pickleWord,
        unpickler = unpickleWord,
        hasher = hashWord,
        eq = op =
      }

  fun pickleWord32 word (stream, pe) = S.outw(word, stream)
  fun unpickleWord32 (stream, upe) = let val word = S.getw stream in word end
  fun hashWord32 word = hashAdd (Word.fromLargeWord word)
  val word32 : Word32.word pu =
      {
        pickler= pickleWord32,
        unpickler = unpickleWord32,
        hasher = hashWord32,
        eq = op =
      }

  fun pickleInt int (stream, pe) = S.outw(Word32.fromInt int, stream)
  fun unpickleInt (stream, upe) =
      let val word = S.getw stream in Word32.toIntX word end
  fun hashInt word = hashAdd (Word.fromInt word)
  val int : int pu =
      {
        pickler= pickleInt,
        unpickler = unpickleInt,
        hasher = hashInt,
        eq = op =
      }

  fun pickleInt32 int (stream, pe) = S.outw(Word32.fromLargeInt int, stream)
  fun unpickleInt32 (stream, upe) =
      let val word = S.getw stream in Word32.toLargeInt word end
  fun hashInt32 word = hashAdd (Word.fromLargeInt word)
  val int32 : Int32.int pu =
      {
        pickler = pickleInt32,
        unpickler = unpickleInt32,
        hasher = hashInt32,
        eq = op =
      }

  fun conv (convPickle : 'a -> 'b, convUnpickle : 'b -> 'a) (pu : 'a pu) =
      {
        pickler = fn v => fn stream => #pickler pu (convUnpickle v) stream,
        unpickler =
        fn stream => let val v = #unpickler pu stream in convPickle v end,
        hasher = fn v => #hasher pu (convUnpickle v),
        eq = fn (v1, v2) => #eq pu (convUnpickle v1, convUnpickle v2)
      } : 'b pu

  fun tuple2 (pu1 : 'a pu, pu2 : 'b pu) =
      let
        val hashTag = newHashTag()
      in
        {
          pickler =
          fn (v1, v2) =>
             fn stream => (#pickler pu1 v1 stream; #pickler pu2 v2 stream),
          unpickler =
          fn stream =>
             let
               val v1 = #unpickler pu1 stream
               val v2 = #unpickler pu2 stream
             in (v1, v2) end,
          hasher =
          fn (v1, v2) =>
             maybestop
                 (fn s =>
                     #hasher pu2 v2 (#hasher pu1 v1 (hashAddSmall hashTag s))),
          eq =
          fn ((a1, a2), (b1, b2)) => #eq pu1 (a1, b1) andalso #eq pu2 (a2, b2)
        } : ('a * 'b) pu
      end

  fun tuple3 (pu1, pu2, pu3) =
      conv
          (
            fn ((pu1, pu2), pu3) => (pu1, pu2, pu3),
            fn (pu1, pu2, pu3) => ((pu1, pu2), pu3)
          )
          (tuple2(tuple2(pu1, pu2), pu3))

  fun tuple4 (pu1, pu2, pu3, pu4) =
      conv
          (
            fn ((pu1, pu2), (pu3, pu4)) => (pu1, pu2, pu3, pu4),
            fn (pu1, pu2, pu3, pu4) => ((pu1, pu2), (pu3, pu4))
          )
          (tuple2(tuple2(pu1, pu2), tuple2(pu3, pu4)))

  fun tuple5 (pu1, pu2, pu3, pu4, pu5) =
      conv
          (
            fn ((pu1, pu2, pu3), (pu4, pu5)) => (pu1, pu2, pu3, pu4, pu5),
            fn (pu1, pu2, pu3, pu4, pu5) => ((pu1, pu2, pu3), (pu4, pu5))
          )
          (tuple2(tuple3(pu1, pu2, pu3), tuple2(pu4, pu5)))

  fun tuple6 (pu1, pu2, pu3, pu4, pu5, pu6) =
      conv
          (
           fn ((pu1, pu2, pu3), (pu4, pu5, pu6)) =>
              (pu1, pu2, pu3, pu4, pu5, pu6),
            fn (pu1, pu2, pu3, pu4, pu5, pu6) =>
               ((pu1, pu2, pu3), (pu4, pu5, pu6))
          )
          (tuple2 (tuple3(pu1, pu2, pu3), tuple3(pu4, pu5, pu6)))

  fun tuple7 (pu1, pu2, pu3, pu4, pu5, pu6, pu7) =
      conv
          (
           fn ((pu1, pu2, pu3, pu4), (pu5, pu6, pu7)) =>
              (pu1, pu2, pu3, pu4, pu5, pu6, pu7),
            fn (pu1, pu2, pu3, pu4, pu5, pu6, pu7) =>
               ((pu1, pu2, pu3, pu4), (pu5, pu6, pu7))
          )
          (tuple2 (tuple4(pu1, pu2, pu3, pu4), tuple3(pu5, pu6, pu7)))

  fun tuple8 (pu1, pu2, pu3, pu4, pu5, pu6, pu7, pu8) =
      conv
          (
           fn ((pu1, pu2, pu3, pu4), (pu5, pu6, pu7, pu8)) =>
              (pu1, pu2, pu3, pu4, pu5, pu6, pu7, pu8),
            fn (pu1, pu2, pu3, pu4, pu5, pu6, pu7, pu8) =>
               ((pu1, pu2, pu3, pu4), (pu5, pu6, pu7, pu8))
          )
          (tuple2 (tuple4(pu1, pu2, pu3, pu4), tuple4(pu5, pu6, pu7, pu8)))

  fun share (pu : 'a pu) : 'a pu =
      let
        val REF = 0w0
        and DEF = 0w1
        val (toDyn, fromDyn) =
            Dyn.new
                (#eq pu)
                (fn v =>
                    let val hash = #2 (#hasher pu v (maxDepth, 0w0))
                    in hash
                    end)
      in
        {
          pickler =
          fn v =>
             fn (s, pe) =>
                let
                  val d = toDyn v
                in
                  case H.find pe d of
                    SOME loc => (S.outcw(REF, s); S.outw(loc, s))
                  | NONE =>
                    let
                      val () = S.outcw(DEF, s)
                      val loc = S.getLoc s
                      val () = #pickler pu v (s, pe)
                    in
                      case H.find pe d of
                        SOME _ => ()
                      | NONE => H.insert pe (d, loc)
                    end
                end,
          unpickler =
          fn (s, upe) =>
             let val tag = S.getcw s
             in
               if tag = REF
               then
                 let val loc = S.getw s
                 in
                   case H.find upe loc
                    of SOME d => fromDyn d
                     | NONE => fail "share.error"
                 end
               else (* tag = DEF *)
                 let
                   val loc = S.getLoc s
                   val v = #unpickler pu (s, upe)
                 in H.insert upe (loc,toDyn v); v end
             end,
          hasher = fn v => maybestop (#hasher pu v),
          eq = #eq pu
        }
      end

  fun refCyc (dummy : 'a) (pu : 'a pu) : 'a ref pu =
      let
        val hashTag = newHashTag ()
        val REF = 0w0
        and DEF = 0w1
        fun hasher (ref v) =
            maybestop (fn p => (#hasher pu v (hashAddSmall hashTag p)))
        val (toDyn, fromDyn) =
            Dyn.new
                (op =)
                (fn v =>
                    let val hash = #2 (hasher v (maxDepth, 0w0))
                    in hash
                    end)
      in
        {
          pickler =
          fn r as ref v =>
             fn (s, pe) =>
                let
                  val d = toDyn r
                in
                  case H.find pe d of
                    SOME loc =>
                    (S.outcw(REF, s); S.outw(loc, s))
                  | NONE =>
                    let val _ = S.outcw(DEF, s) val loc = S.getLoc s
                    in H.insert pe (d, loc); #pickler pu v (s, pe) end
                end,
          unpickler =
          fn (s, upe) =>
             let val tag = S.getcw s
             in
               if tag = REF
               then
                 let val loc = S.getw s
                 in
                   case H.find upe loc of
                     SOME d => fromDyn d
                   | NONE => fail "ref.error"
                 end
               else (* tag = DEF *)
                 let
                   val loc = S.getLoc s
                   val r = ref dummy
                   val _ = H.insert upe (loc, toDyn r)
                   val v = #unpickler pu (s, upe)
                 in r := v ; r end
             end,
          hasher = hasher,
          eq = op =
        }

      end

  fun data (toInt: 'a -> int, fs : ('a pu -> 'a pu) list) : 'a pu =
      let
        val hashTag = newHashTag()
        val res : 'a pu option ref = ref NONE
        val ps : 'a pu vector option ref = ref NONE
        fun p v (s, pe) =
            let val i = toInt v val _ = S.outcw (Word32.fromInt i, s)
            in #pickler(getPUPI i) v (s, pe) end
        and up (s, upe) =
            let val w = S.getcw s
            in #unpickler(getPUPI (Word32.toInt w)) (s, upe)
            end
        and eq(a1 : 'a, a2 : 'a) : bool =
            let val n = toInt a1
            in n = toInt a2 andalso #eq (getPUPI n) (a1, a2)
            end
        and getPUP() =
            case !res of
              NONE =>
              let
                val pup = {pickler = p, hasher = h, unpickler = up, eq = eq}
                val pup = if !enableShare then share pup else pup
              in res := SOME pup; pup
              end
            | SOME pup => pup
        and getPUPI (i : int) =
            case !ps of
              NONE =>
              let
                val ps0 = map (fn f => f (getPUP())) fs
                val psv = Vector.fromList ps0
              in ps := SOME psv; Vector.sub(psv, i)
              end
            | SOME psv => Vector.sub(psv, i)
        and h v =
            maybestop
                (fn p =>
                    let val i = toInt v
                    in
                      #hasher
                          (getPUPI i)
                          v 
                          (hashAddSmall
                               (Word.fromInt i)
                               (hashAddSmall hashTag p))
                    end)
      in getPUP()
      end

  fun con0 v pu =
      {
        pickler = fn _ => fn s => (),
        unpickler = fn s => v,
        hasher = fn _ => fn x => x,
        eq = fn _ => true
      }
  fun con1 (fromArg : 'arg -> 't) (toArg : 't -> 'arg) (pu : 'arg pu) =
      {
        pickler = (#pickler pu) o toArg,
        unpickler = fn s => case #unpickler pu s of v => fromArg v,
        hasher = #hasher pu o toArg,
        eq = fn (v1, v2) => #eq pu (toArg v1, toArg v2)
      }
  fun enum (toInt: 'a -> int, datacons : 'a list) : 'a pu =
      data (toInt, map (fn datacon => con0 datacon) datacons)

  val bool : bool pu =
      enum (fn false => 0 | true => 1, [false, true])
  val pickleBool = #pickler bool
  val unpickleBool = #unpickler bool

  val char : char pu =
      conv (Char.chr o Word8.toInt, Word8.fromInt o Char.ord) byte
  val pickleChar = #pickler char
  val unpickleChar = #unpickler char

  fun list (arg_pu : 'a pu) : 'a list pu =
      let
        fun pu_Nil pu = con0 [] pu
        fun pu_Cons pu =
            con1 (op ::) (fn (x :: y) => (x, y)) (tuple2 (arg_pu, pu))
      in
        data (fn [] => 0 | op :: _ => 1, [pu_Nil, pu_Cons])
      end

  fun option (arg_pu : 'a pu) : 'a option pu =
      let
        fun pu_NONE pu = con0 NONE pu
        fun pu_SOME pu = con1 SOME (fn (SOME x) => x) arg_pu
      in
        data (fn NONE => 0 | SOME _ => 1, [pu_NONE, pu_SOME])
      end

  fun vector (pu : 'a pu) : 'a vector pu =
      let
        val hashTag = newHashTag()
        fun eqVector (v1, v2) =
            let
              fun scan ~1 = true
                | scan index =
                  #eq pu (Vector.sub (v1, index), Vector.sub (v2, index))
                  andalso scan (index - 1)
              val length1 = Vector.length v1
            in
              (length1 = Vector.length v2) andalso scan (length1 - 1)
            end
      in
        {
          pickler =
          fn v =>
             fn stream =>
                (
                  pickleInt (Vector.length v) stream;
                  Vector.app
                      (fn elem => #pickler pu elem stream)
                       v
                ),
          unpickler =
          fn stream =>
             let
               val length = unpickleInt stream
               val v = Vector.tabulate (length, fn _ => #unpickler pu stream)
             in v end,
          hasher =
          fn v =>
             maybestop
                 (fn s =>
                     Vector.foldl
                         (fn (elem, s) => #hasher pu elem s)
                         (hashAddSmall hashTag s)
                         v),
          eq = eqVector
        } : 'a vector pu
      end

  val string : string pu =
      let
        val hashTag = newHashTag()
      in
        {
          pickler =
          fn s =>
             fn stream =>
                (
                  pickleInt (String.size s) stream;
                  Word8Vector.app
                      (fn elem => #pickler byte elem stream)
                      (Byte.stringToBytes s)
                ),
          unpickler =
          fn stream =>
             let
               val length = unpickleInt stream
               val v =
                   Word8Vector.tabulate
                       (length, fn _ => #unpickler byte stream)
             in Byte.bytesToString v end,
          hasher =
          fn v =>
             maybestop
                 (fn s =>
                     Substring.foldl
                         (fn (elem, s) => #hasher char elem s)
                         (hashAddSmall hashTag s)
                         (Substring.all v)),
          eq = op =
        }
      end
  val pickleString = #pickler string
  val unpickleString = #unpickler string

  (****************************************)

  type 'a functionRefs =
       {
         picklerRef : 'a pickler ref,
         unpicklerRef : 'a unpickler ref,
         hasherRef : 'a hasher ref,
         eqRef : 'a isEqual ref
       }

  fun makeNullPu (value : 'a) =
      let
        val picklerRef : 'a pickler ref =
            ref (fn v : 'a => fn stream => raise Fail "Dummy pickler")
        val unpicklerRef : 'a unpickler ref =
            ref (fn stream => raise Fail "dummy unpickler")
        val hasherRef =
            ref (fn v : 'a => fn p : hash => raise Fail "dummy hasher")
        val eqRef = ref (fn (v1 : 'a, v2) => false)
        val pu =
            make
                (
                  fn v => fn stream => (!picklerRef) v stream,
                  fn stream => (!unpicklerRef) stream,
                  fn v => fn p => (!hasherRef) v p,
                  fn v => (!eqRef) v
                )
        val functionRefs = 
          {
            picklerRef = picklerRef,
            unpicklerRef = unpicklerRef,
            hasherRef = hasherRef,
            eqRef = eqRef
          }
      in
        (functionRefs, pu)
      end

  fun updateNullPu (functionRefs : 'a functionRefs) (pu : 'a pu) =
      (
        #picklerRef functionRefs := #pickler pu;
        #unpicklerRef functionRefs := #unpickler pu;
        #hasherRef functionRefs := #hasher pu;
        #eqRef functionRefs := #eq pu
      )

  (***************************************************************************)

end