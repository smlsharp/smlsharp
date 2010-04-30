(**
 * An implementation of serialize combinator based on
 * "Type-Specialized Serialization with Sharing", Martin Elsman
 * @author YAMATODANI Kiyoshi
 * @version $Id: Pickle.sml,v 1.19 2008/01/08 03:18:51 bochao Exp $
 *)
structure Pickle :> PICKLE =
struct

  (***************************************************************************)

  structure H = HashTable
  structure S = Stream

  (***************************************************************************)

  type pe = (Dyn.dyn, S.loc) H.hash_table
  type upe =
       (S.loc, Dyn.dyn * (** end pos of pickled form. *) S.loc) H.hash_table

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

  fun assert false = raise Fail "assertion error"
    | assert true = ()

  fun assertWith (false, S) = raise Control.Bug S
    | assertWith (true, S) = ()

  val enableShare = ref true

  val sizeHint = ref 100000

  fun makeInstream reader =
      let
        val hashTable : upe =
            H.mkTable
                (
                  fn x => (Word.fromLargeWord o Word32.toLargeWord) x,
                  fn (v1, v2) => v1 = (v2 : Word32.word)
                )
                (!sizeHint, Fail "not found")
        val stream = Stream.openInStream reader
      in
        (stream, hashTable)
      end

  fun makeOutstream writer =
      let
        val hashTable =
            H.mkTable (Dyn.hash, Dyn.eq) (!sizeHint, Fail "not found")
        val stream = Stream.openOutStream writer
      in
        (stream, hashTable)
      end

  fun pickle (pu : 'a pu) (v : 'a) stream = #pickler pu v stream
(*
  fun dumpHashTable table =
      let
        val total = H.numItems table
        val _ = print ("total = " ^ Int.toString total ^ "\n")
        val buckets = H.bucketSizes table
        val env =
            List.foldl
                (fn (n, env) =>
                    case IEnv.find (env, n)
                     of NONE => IEnv.insert (env, n, 1)
                      | SOME ns => IEnv.insert (env, n, ns + 1))
                IEnv.empty
                buckets
        val _ =
            app
                (fn (n, m) =>
                    print (Int.toString n ^ ":" ^ Int.toString m ^ "\n"))
                (IEnv.listItemsi env)
      in
        ()
      end
*)
  fun unpickle (pu : 'a pu) (stream as (_, upe)) =
      let
(*
        val realTimer = Timer.startRealTimer ()
        val CPUTimer = Timer.startCPUTimer ()
*)
        val result = #unpickler pu stream
(*
        val (CPU1, Real1) =
            (Timer.checkCPUTimer CPUTimer, Timer.checkRealTimer realTimer)
        val _ = print (LargeInt.toString (Time.toMilliseconds Real1) ^ "\n")

        val _ = dumpHashTable upe
*)
      in
        result
      end
        handle e => (
                 app
                     (fn line => print (line ^ "\n"))
                     (SMLofNJ.exnHistory e);
                     raise e)

  fun hash (pu : 'a pu) (v : 'a) hash = #hasher pu v hash

  fun eq (pu : 'a pu) = #eq pu

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

  fun pickleWord word (stream, pe) =
      S.outw((Word32.fromLargeWord o Word.toLargeWord) word, stream)
  fun unpickleWord (stream, upe) =
      let val word = S.getw stream
      in (Word.fromLargeWord o Word32.toLargeWord) word end
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
  fun hashWord32 word = hashAdd (Word.fromLargeWord(Word32.toLargeWord word))
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
  fun hashInt int = hashAdd (Word.fromInt int)
  val int : int pu =
      {
        pickler= pickleInt,
        unpickler = unpickleInt,
        hasher = hashInt,
        eq = op =
      }

  fun pickleInt32 int (stream, pe) =
      S.outw(Word32.fromLargeInt (Int32.toLarge int), stream)
  fun unpickleInt32 (stream, upe) =
      let val word = S.getw stream
      in Int32.fromLarge (Word32.toLargeIntX word) end
  fun hashInt32 int32 = hashAdd (Word.fromLargeInt (Int32.toLarge int32))
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
        unpickler = fn stream => convPickle (#unpickler pu stream),
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

  fun tuple10 (pu1, pu2, pu3, pu4, pu5, pu6, pu7, pu8, pu9, pu10) =
      conv
          (
           fn ((pu1, pu2, pu3, pu4, pu5), (pu6, pu7, pu8, pu9, pu10)) =>
              (pu1, pu2, pu3, pu4, pu5, pu6, pu7, pu8, pu9, pu10),
            fn (pu1, pu2, pu3, pu4, pu5, pu6, pu7, pu8, pu9, pu10) =>
               ((pu1, pu2, pu3, pu4, pu5), (pu6, pu7, pu8, pu9, pu10))
          )
          (tuple2 (tuple5(pu1, pu2, pu3, pu4, pu5), tuple5(pu6, pu7, pu8, pu9, pu10)))

  fun tuple11 (pu1, pu2, pu3, pu4, pu5, pu6, pu7, pu8, pu9, pu10, pu11) =
      conv
          (
           fn ((pu1, pu2, pu3, pu4, pu5), (pu6, pu7, pu8, pu9, pu10, pu11)) =>
              (pu1, pu2, pu3, pu4, pu5, pu6, pu7, pu8, pu9, pu10, pu11),
            fn (pu1, pu2, pu3, pu4, pu5, pu6, pu7, pu8, pu9, pu10, pu11) =>
               ((pu1, pu2, pu3, pu4, pu5), (pu6, pu7, pu8, pu9, pu10, pu11))
          )
          (tuple2 (tuple5(pu1, pu2, pu3, pu4, pu5), tuple6(pu6, pu7, pu8, pu9, pu10, pu11)))

  fun tuple12 (pu1, pu2, pu3, pu4, pu5, pu6, pu7, pu8, pu9, pu10, pu11, pu12) =
      conv
          (
           fn ((pu1, pu2, pu3, pu4, pu5, pu6), (pu7, pu8, pu9, pu10, pu11, pu12)) =>
              (pu1, pu2, pu3, pu4, pu5, pu6, pu7, pu8, pu9, pu10, pu11, pu12),
            fn (pu1, pu2, pu3, pu4, pu5, pu6, pu7, pu8, pu9, pu10, pu11, pu12) =>
               ((pu1, pu2, pu3, pu4, pu5, pu6), (pu7, pu8, pu9, pu10, pu11, pu12))
          )
          (tuple2 (tuple6(pu1, pu2, pu3, pu4, pu5, pu6), tuple6(pu7, pu8, pu9, pu10, pu11, pu12)))

  fun lazy (pu : 'a pu) : (unit -> 'a) pu =
      let
        fun pickle f (s, pe) = 
            let
              val pos1 = S.getLoc s
              val () = S.outw (0w0, s) (* dummy 0. *)
(*
val _ = print ("lazy: begin at " ^ Word32.toString pos1 ^ "\n")
*)
              val () = #pickler pu (f ()) (s, pe)
              val pos2 = S.getLoc s
(*
              val true = S.seekOut (s, pos1)
*)
              val () = assertWith(S.seekOut (s, pos1), 
                                  "false returned from seekOut : Pickle.sml")
              val () = S.outw (pos2, s) (* overwrites actual pos. *)
(*
              val true = S.seekOut (s, pos2)
*)
              val () = assertWith(S.seekOut (s, pos2),
                                  "false returned from seekOut : Pickle.sml")
                                  
              (* now at pos2. *)
(*
val _ = print ("lazy: pos1 = " ^ Word32.toString pos1 ^ "\n")
val _ = print ("      pos2 = " ^ Word32.toString pos2 ^ "\n")
val _ = print ("      size = " ^ Word32.toString size ^ "\n")
*)
            in
              ()
            end
        fun unpickle (s, upe) =
            let
              val endPos = S.getw s
              val pos1 = S.getLoc s
            in
              if S.seekIn (s, endPos)
              then
                let
                  fun f () =
                      let 
                        val pos2 = S.getLoc s
(*
val _ = print ("lazy: pos1 = " ^ Word32.toString pos1 ^ "\n")
val _ = print ("      pos2 = " ^ Word32.toString pos2 ^ "\n")
val _ = print ("    endPos = " ^ Word32.toString endPos ^ "\n")
*)
(*
                        val true = S.seekIn (s, pos1)
*)
                        val () = assertWith(S.seekIn (s, pos1),
                                            "false returned from seekIn : Pickle.sml")
                        val v = #unpickler pu (s, upe)
(*
                        val true = S.seekIn (s, pos2)
*)
                        val () = assertWith(S.seekIn (s, pos2),
                                            "false returned from seekIn : Pickle.sml")
                      in v end
                in f end
              else (* This stream does not implement seek. *)
                let val v = #unpickler pu (s, upe)
                in fn () => v end
            end
      in
        {
          pickler = pickle,
          unpickler = unpickle,
          hasher = fn f => maybestop (#hasher pu (f ())),
          eq = fn (f, g) => #eq pu (f (), g())
        }
      end

  fun share (pu : 'a pu) : 'a pu =
      let
        val REF = 0w254 : Word8.word
        and DEF = 0w255 : Word8.word
        val (toDyn, fromDyn) =
            Dyn.new
                (#eq pu)
                (fn v =>
                    let val hash = #2 (#hasher pu v (maxDepth, 0w0))
                    in hash
                    end)
        fun pickle v (s, pe) =
            let
              val d = toDyn v
(*
              val pos = S.getLoc s
val _ = print ("share begin at " ^ Word32.toString pos ^ "\n")
*)
            in
              (case H.find pe d of
                SOME loc => (S.outb(REF, s); S.outw(loc, s))
              | NONE =>
                let
                  val () = S.outb(DEF, s)
                  val loc = S.getLoc s (* position of next to DEF tag. *)
                  val () = #pickler pu v (s, pe)
                in
                  case H.find pe d of
                    SOME _ =>
                    (* NOTE: If 'share' and another 'share' or 'refCycle' are
                     * nested, for example 'share(refCycle pu)', inner 'share'
                     * or 'refCycle' adds another dyn which equals to d to the
                     * hash table.
                     *)
                    ()
                  | NONE => H.insert pe (d, loc)
                end)
(*
before print ("share end at " ^ Word32.toString pos ^ " - " ^ Word32.toString (S.getLoc s) ^ "\n")
*)
            end
        fun unpickle (s, upe) =
            let
(*
val _ = print ("share starts at " ^ Word32.toString (S.getLoc s) ^ "\n")
*)
              val tag = S.getb s
            in
              if tag = REF
              then
                let val pos1 = S.getw s (* where the object is unpickled. *)
                in
                  case H.find upe pos1
                   of SOME (d, _) => fromDyn d
                    | NONE => (* unpickling v may be delayed. *)
                      let
(*
val _ = print ("share(1): pos1 = " ^ Word32.toString pos1 ^ "\n")
*)
                        val pos2 = S.getLoc s
(*
val _ = print ("share(1): pos2 = " ^ Word32.toString pos2 ^ "\n")
*)
                        (* move to next to the DEF tag. *)
(*
                        val true = S.seekIn (s, pos1)
*)
                        val () = assertWith(S.seekIn (s, pos1),
                                            "false returned from seekIn : Pickle.sml")
                        val v = #unpickler pu (s, upe)
                        (* register the unpickled object. *)
                        val pos3 = S.getLoc s
                        val _ = H.insert upe (pos1, (toDyn v, pos3));
                        (* return to pos2 *)
(*
val _ = print ("share(1): pos3 = " ^ Word32.toString pos3 ^ "\n")
*)
(*
                        val true = S.seekIn (s, pos2)
*)
                        val () = assertWith(S.seekIn (s, pos2),
                                            "false returned from seekIn : Pickle.sml")
                      in
                        v
                      end
                end
              else if tag = DEF
              then
                let val pos1 = S.getLoc s
(*
val _ = print ("share(2): pos1 = " ^ Word32.toString pos1 ^ "\n")
*)
                in
                  (* It is possible that this object was unpickled before. *)
                  case H.find upe pos1
                   of NONE =>
                      let
                        val v = #unpickler pu (s, upe)
                        val pos2 = S.getLoc s
(*
val _ = print ("share(2): pos2 = " ^ Word32.toString pos2 ^ "\n")
*)
(*
val _ = print ("share(2): size = " ^ Word32.toString size ^ "\n")
*)
                      in
                        H.insert upe (pos1, (toDyn v, pos2));
                        v
                      end
                    | SOME (d, 0w0) => raise Fail "BUG:Pickle.share size=0w0"
                    | SOME (d, endPos) =>
                      (
(*
print ("share(3): size = " ^ Word32.toString size ^ "\n");
*)
                        S.seekIn (s, endPos);
                        fromDyn d
                      )
                end
              else
                raise
                  Fail
                      ("BUG:Pickle.share bad tag(" ^ Word8.toString tag ^ ")")
            end
      in
        {
          pickler = pickle,
          unpickler = unpickle,
          hasher = fn v => maybestop (#hasher pu v),
          eq = #eq pu
        }
      end

  fun refCycle (dummy : 'a) (pu : 'a pu) : 'a ref pu =
      let
        val hashTag = newHashTag ()
        val REF = 0w252 : Word8.word
        and DEF = 0w253 : Word8.word
        fun hash (ref v) =
            maybestop (fn p => (#hasher pu v (hashAddSmall hashTag p)))
        val (toDyn, fromDyn) =
            Dyn.new (op =) (fn v => #2 (hash v (maxDepth, 0w0)))
        fun pickle (r as ref v) (s, pe) =
            let
              val d = toDyn r
              val pos = S.getLoc s
(*
val _ = print ("refCycle begin at " ^ Word32.toString pos ^ "\n")
*)
            in
              (case H.find pe d of
                SOME loc => (S.outb(REF, s); S.outw(loc, s))
              | NONE =>
                let
                  val _ = S.outb(DEF, s)
                  val loc = S.getLoc s (* next to DEF tag. *)
                in H.insert pe (d, loc); #pickler pu v (s, pe) end)
(*
before print ("refCycle end at " ^ Word32.toString pos ^ " - " ^ Word32.toString (S.getLoc s) ^ "\n")
*)
            end
        fun unpickle (s, upe) =
            let val tag = S.getb s
(*
val _ = print ("refCycle(0): cur = " ^ Word32.toString (S.getLoc s) ^ "\n")
*)
            in
              if tag = REF
              then
                let val pos1 = S.getw s (* where object is pickled. *)
(*
val _ = print ("refCycle(1): pos1 = " ^ Word32.toString pos1 ^ "\n")
*)
                in
                  case H.find upe pos1 of
                    SOME (d, _) => fromDyn d
                  | NONE => 
                    let
                      val pos2 = S.getLoc s
(*
val _ = print ("refCycle(1): pos2 = " ^ Word32.toString pos2 ^ "\n")
*)
                      (* move to next to the DEF tag. *)
(*
                      val true = S.seekIn (s, pos1)
*)
                      val () = assertWith(S.seekIn (s, pos1),
                                          "false returned from seekIn : Pickle.sml")
                      val r = ref dummy
                      val dyn = toDyn r
                      val _ = H.insert upe (pos1, (dyn, 0w0)) (* dummy 0 *)
                      val v = #unpickler pu (s, upe)
                      val pos3 = S.getLoc s
                      val _ = H.insert upe (pos1, (dyn, pos3))
                      val _ = r := v
(*
val _ = print ("refCycle(1): pos3 = " ^ Word32.toString pos3 ^ "\n")
*)
(*
                      val true = S.seekIn (s, pos2)
*)
                      val () = assertWith(S.seekIn (s, pos2),
                                          "false returned from seekIn : Pickle.sml")
                      (* at pos2 *)
                    in
                      r
                    end
                end
              else if tag = DEF
              then
                let val pos1 = S.getLoc s
(*
val _ = print ("refCycle(2): pos1 = " ^ Word32.toString pos1 ^ "\n")
*)
                in
                  (* It is possible that this value is unpickled twice. *)
                  case H.find upe pos1
                   of NONE =>
                      let
                        val r = ref dummy
                        val dyn = toDyn r
                        val _ = H.insert upe (pos1, (dyn, 0w0)) (* dummy 0w0 *)
                        val v = #unpickler pu (s, upe)
                        val pos2 = S.getLoc s
(*
val _ = print ("refCycle(2): pos2 = " ^ Word32.toString pos2 ^ "\n")
*)
                        val _ = H.insert upe (pos1, (dyn, pos2))
                      in r := v ; r end
                    | SOME (d, 0w0) =>
                      raise Fail "BUG:Pickle.refCycle size = 0w0."
                    | SOME (d, endPos) =>
                      (
(*
print ("refCycle(3): size = " ^ Word32.toString size ^ "\n");
*)
                        S.seekIn (s, endPos);
                        fromDyn d
                      )
                end
              else raise Fail "BUG:Pickle.refCycle"
            end
      in
        {
          pickler = pickle,
          unpickler = unpickle,
          hasher = hash,
          eq = op =
        }
      end

  fun refNonCycle (pu : 'a pu) : 'a ref pu =
      share (conv (fn v => ref v, fn ref v => v) pu)

  fun refNonShared (pu : 'a pu) : 'a ref pu =
      conv (fn v => ref v, fn ref v => v) pu

  fun data (toInt: 'a -> int, fs : ('a pu -> 'a pu) list) : 'a pu =
      let
        val (outConTag, getConTag) =
            let val numCons = length fs
            in
              if numCons < 256
              then
                (
                  fn (n, s) =>
                     (* range-check only at pickling. *)
                     if 256 <= n
                     then raise Fail "Bug:tag should be less than 256."
                     else S.outb(Word8.fromInt n, s),
                  Word8.toInt o S.getb
                )
              else
                (
                  fn (n, s) => S.outw(Word32.fromInt n, s),
                  Word32.toInt o S.getw
                )
            end
        val hashTag = newHashTag()
        val res : 'a pu option ref = ref NONE
        val ps : 'a pu vector option ref = ref NONE
        fun p v (s, pe) =
            let val i = toInt v val _ = outConTag (i, s)
            in #pickler(getPUPI i) v (s, pe) end
        and up (s, upe) = #unpickler(getPUPI (getConTag s)) (s, upe)
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
              in
                ps := SOME psv;
                Vector.sub(psv, i)
                handle General.Subscript =>
                       raise
                         Fail
                             ("wrong unpickler index=" ^ Int.toString i
                              ^ ",|vector|=" ^ Int.toString(Vector.length psv))
              end
            | SOME psv =>
              Vector.sub(psv, i)
              handle General.Subscript =>
                     raise
                       Fail
                           ("wrong unpickler index=" ^ Int.toString i
                            ^ ",|vector|=" ^ Int.toString(Vector.length psv))
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
            con1 
                (op ::) 
                (fn (x :: y) => (x, y)
                  | nil =>
                    raise
                      Fail
                          "nil to pu_Cons in list (pickle/main/Pickle.sml)")
                (tuple2 (arg_pu, pu))
      in
        data (fn [] => 0 | op :: _ => 1, [pu_Nil, pu_Cons])
      end

  fun option (arg_pu : 'a pu) : 'a option pu =
      let
        fun pu_NONE pu = con0 NONE pu
        fun pu_SOME pu = 
            con1 
                SOME 
                (fn (SOME x) => x
                  | NONE =>
                    raise
                      Fail
                          "NONE to pu_SOME in option (pickle/main/Pickle.sml)")
                arg_pu
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
                         (Substring.full v)),
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
