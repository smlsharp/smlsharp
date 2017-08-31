(**
 * HeapDump
 * @copyright (c) 2015, Tohoku University.
 * @author UENO Katsuhiro
 *)

structure HeapDump =
struct

  structure Pointer = SMLSharp_Builtin.Pointer
  structure Array = SMLSharp_Builtin.Array
  structure BWord = SMLSharp_Builtin.Word32

  val IS_POINTER_FLAG = 0wx1 : Word8.word
  val POINT_TO_MUTABLE_FLAG = 0wx2 : Word8.word
  val OBJECT_BEGIN_FLAG = 0wx4 : Word8.word

  val 'a#boxed sml_dump_heap =
      _import "sml_dump_heap"
      : __attribute__((unsafe))
        ('a,
         unit ptr ptr ref,
         Word8.word ptr ref,
         word ref,
         unit ptr ptr ref,
         Word8.word ptr ref,
         word ref,
         word ref,
         Word8.word ref) -> ()
val sml_dump_heap = fn _ => raise Fail "FIXME"

  val free =
      _import "free"
      : __attribute__((unsafe,fast))
        'a ptr -> ()

  type raw_space =
      {dump : unit ptr array, flags : Word8.word array}

  type dump =
      {immutables : raw_space,
       mutables : raw_space,
       first : {index : word, flags : Word8.word}}

  datatype pointer =
      IMMUTABLE	of Word64.word
    | MUTABLE of Word64.word

  datatype image =
      VALUE of Word64.word
    | POINTER of pointer

  (* FIXME : this should be replaced with memcpy *)
  fun copy i ary src len =
      if i < len
      then (Array.update_unsafe (ary, i, Pointer.deref src);
            copy (i+1) ary (Pointer.advance (src, 1)) len)
      else ()

  fun dump obj =
      let
        val null_dump = Pointer.fromUnitPtr _NULL : unit ptr ptr
        val null_flags = Pointer.fromUnitPtr _NULL : Word8.word ptr
        val immutables_dump_r = ref null_dump
        val immutables_flags_r = ref null_flags
        val immutables_words_r = ref 0w0
        val mutables_dump_r = ref null_dump
        val mutables_flags_r = ref null_flags
        val mutables_words_r = ref 0w0
        val first_index_r = ref 0w0
        val first_flags_r = ref 0w0
        val _ = sml_dump_heap (obj,
                               immutables_dump_r,
                               immutables_flags_r,
                               immutables_words_r,
                               mutables_dump_r,
                               mutables_flags_r,
                               mutables_words_r,
                               first_index_r,
                               first_flags_r)
        fun free_dump p =
            if !p = null_dump then () else free (!p)
        fun free_flags p =
            if !p = null_flags then () else free (!p)
        fun freeAll () =
            (free_dump immutables_dump_r;
             free_flags immutables_flags_r;
             free_dump mutables_dump_r;
             free_flags mutables_flags_r)
        fun readDump (dump, flags, words) =
            let
              val len = Word.toInt words
              val dump_a = Array.alloc len
              val flags_a = Array.alloc len
              val _ = copy 0 dump_a dump len
              val _ = copy 0 flags_a flags len
            in
              {dump = dump_a, flags = flags_a}
            end
        val immutables = readDump (!immutables_dump_r,
                                   !immutables_flags_r,
                                   !immutables_words_r)
        val mutables = readDump (!mutables_dump_r,
                                 !mutables_flags_r,
                                 !mutables_words_r)
      in
        freeAll ();
        if !first_index_r = 0w0
        then NONE
        else SOME {immutables = immutables,
                   mutables = mutables,
                   first = {index = !first_index_r,
                            flags = !first_flags_r}}
      end

  fun readPointer (v, flags) =
      if Word8.andb (flags, POINT_TO_MUTABLE_FLAG) <> 0w0
      then MUTABLE v
      else IMMUTABLE v

  fun readImage (v, flags) =
      if Word8.andb (flags, IS_POINTER_FLAG) <> 0w0
      then POINTER (readPointer (v, flags))
      else VALUE v

  fun readSpace ({dump, flags}:raw_space) =
      let
        val dst = Array.alloc_unsafe (Array.length dump)
      in
        Word8Array.appi
          (fn (i, b) =>
              let
                val v = Pointer.toWord64 (Array.sub_unsafe (dump, i))
                val m = readImage (v, b)
              in
                Array.update_unsafe (dst, i, m)
              end)
          flags;
        Array.turnIntoVector dst
      end

  fun listObjects ({dump, flags}:raw_space) =
      Word8Array.foldri
        (fn (i, b, z) =>
            if Word8.andb (b, OBJECT_BEGIN_FLAG) <> 0w0
            then Word64.fromInt i :: z
            else z)
        nil
        flags

  fun image ({immutables, mutables, first}:dump) =
      {immutables = readSpace immutables,
       mutables = readSpace mutables,
       first = readPointer (BWord.toWord64 (#index first), #flags first),
       mutableObjects = map MUTABLE (listObjects mutables)}

end
