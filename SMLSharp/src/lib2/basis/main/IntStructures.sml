(**
 * Integer related structures.
 * @author YAMATODANI Kiyoshi
 * @author UENO Katsuhiro
 * @copyright 2010, 2011, Tohoku University.
 *)
_interface "IntStructures.smi"

local

infix 7 * / div mod
infix 6 + -
infixr 5 ::
infix 4 = <> > >= < <=
val op + = SMLSharp.Int.add
val op - = SMLSharp.Int.sub
val op > = SMLSharp.Int.gt
val op < = SMLSharp.Int.lt
val op <= = SMLSharp.Int.lteq
val op >= = SMLSharp.Int.gteq

structure IntStructures :> sig

  structure LargeInt : sig
    (* same as INTEGER except LargeInt.int *)
    eqtype int
    val toLarge : int -> (*LargeInt.*)int
    val fromLarge : (*LargeInt.*)int -> int
    val toInt : int -> SMLSharp.Int.int
    val fromInt : SMLSharp.Int.int -> int
    val precision : SMLSharp.Int.int option
    val minInt : int option
    val maxInt : int option
    val + : int * int -> int
    val - : int * int -> int
    val * : int * int -> int
    val div : int * int -> int
    val mod : int * int -> int
    val quot : int * int -> int
    val rem : int * int -> int
    val compare : int * int -> order
    val < : int * int -> bool
    val <= : int * int -> bool
    val > : int * int -> bool
    val >= : int * int -> bool
    val ~ : int -> int
    val abs : int -> int
    val min : int * int -> int
    val max : int * int -> int
    val sign : int -> SMLSharp.Int.int
    val sameSign : int * int -> bool
    val fmt : StringCvt.radix -> int -> string
    val toString : int -> string
    val scan : StringCvt.radix
               -> (char, 'a) StringCvt.reader
               -> (int, 'a) StringCvt.reader
    val fromString : string -> int option
  end

  structure IntInf : sig
    (* same as INT_INF *)
    eqtype int
    val toLarge : int -> LargeInt.int
    val fromLarge : LargeInt.int -> int
    val toInt : int -> SMLSharp.Int.int
    val fromInt : SMLSharp.Int.int -> int
    val precision : SMLSharp.Int.int option
    val minInt : int option
    val maxInt : int option
    val + : int * int -> int
    val - : int * int -> int
    val * : int * int -> int
    val div : int * int -> int
    val mod : int * int -> int
    val quot : int * int -> int
    val rem : int * int -> int
    val compare : int * int -> order
    val < : int * int -> bool
    val <= : int * int -> bool
    val > : int * int -> bool
    val >= : int * int -> bool
    val ~ : int -> int
    val abs : int -> int
    val min : int * int -> int
    val max : int * int -> int
    val sign : int -> SMLSharp.Int.int
    val sameSign : int * int -> bool
    val fmt : StringCvt.radix -> int -> string
    val toString : int -> string
    val scan : StringCvt.radix
               -> (char, 'a) StringCvt.reader
               -> (int, 'a) StringCvt.reader
    val fromString : string -> int option
    val divMod : int * int -> int * int
    val quotRem : int * int -> int * int
    val pow : int * SMLSharp.Int.int -> int
    val log2 : int -> SMLSharp.Int.int
    val orb : int * int -> int
    val xorb : int * int -> int
    val andb : int * int -> int
    val notb : int -> int
    val << : int * SMLSharp.Word.word -> int
    val ~>> : int * SMLSharp.Word.word -> int
  end
  where type int = SMLSharp.IntInf.int

  structure Int : sig
    (* same as INTEGER *)
    eqtype int
    val toLarge : int -> LargeInt.int
    val fromLarge : LargeInt.int -> int
    val toInt : int -> SMLSharp.Int.int
    val fromInt : SMLSharp.Int.int -> int
    val precision : SMLSharp.Int.int option
    val minInt : int option
    val maxInt : int option
    val + : int * int -> int
    val - : int * int -> int
    val * : int * int -> int
    val div : int * int -> int
    val mod : int * int -> int
    val quot : int * int -> int
    val rem : int * int -> int
    val compare : int * int -> order
    val < : int * int -> bool
    val <= : int * int -> bool
    val > : int * int -> bool
    val >= : int * int -> bool
    val ~ : int -> int
    val abs : int -> int
    val min : int * int -> int
    val max : int * int -> int
    val sign : int -> SMLSharp.Int.int
    val sameSign : int * int -> bool
    val fmt : StringCvt.radix -> int -> string
    val toString : int -> string
    val scan : StringCvt.radix
               -> (char, 'a) StringCvt.reader
               -> (int, 'a) StringCvt.reader
    val fromString : string -> int option
  end
  where type int = SMLSharp.Int.int

  structure Position : sig
    (* same as INTEGER *)
    eqtype int
    val toLarge : int -> LargeInt.int
    val fromLarge : LargeInt.int -> int
    val toInt : int -> SMLSharp.Int.int
    val fromInt : SMLSharp.Int.int -> int
    val precision : SMLSharp.Int.int option
    val minInt : int option
    val maxInt : int option
    val + : int * int -> int
    val - : int * int -> int
    val * : int * int -> int
    val div : int * int -> int
    val mod : int * int -> int
    val quot : int * int -> int
    val rem : int * int -> int
    val compare : int * int -> order
    val < : int * int -> bool
    val <= : int * int -> bool
    val > : int * int -> bool
    val >= : int * int -> bool
    val ~ : int -> int
    val abs : int -> int
    val min : int * int -> int
    val max : int * int -> int
    val sign : int -> SMLSharp.Int.int
    val sameSign : int * int -> bool
    val fmt : StringCvt.radix -> int -> string
    val toString : int -> string
    val scan : StringCvt.radix
               -> (char, 'a) StringCvt.reader
               -> (int, 'a) StringCvt.reader
    val fromString : string -> int option
  end

  structure LargeWord : sig
    (* same as WORD except LargeWord.word *)
    eqtype word
    val wordSize : int
    val toLarge : word -> (*LargeWord.*)word
    val toLargeX : word -> (*LargeWord.*)word
    val toLargeWord : word -> (*LargeWord.*)word
    val toLargeWordX : word -> (*LargeWord.*)word
    val fromLarge : (*LargeWord.*)word -> word
    val fromLargeWord : (*LargeWord.*)word -> word
    val toLargeInt : word -> LargeInt.int
    val toLargeIntX : word -> LargeInt.int
    val fromLargeInt : LargeInt.int -> word
    val toInt : word -> int
    val toIntX : word -> int
    val fromInt : int -> word
    val andb : word * word -> word
    val orb : word * word -> word
    val xorb : word * word -> word
    val notb : word -> word
    val << : word * SMLSharp.Word.word -> word
    val >> : word * SMLSharp.Word.word -> word
    val ~>> : word * SMLSharp.Word.word -> word
    val + : word * word -> word
    val - : word * word -> word
    val * : word * word -> word
    val div : word * word -> word
    val mod : word * word -> word
    val compare : word * word -> order
    val < : word * word -> bool
    val <= : word * word -> bool
    val > : word * word -> bool
    val >= : word * word -> bool
    val ~ : word -> word
    val min : word * word -> word
    val max : word * word -> word
    val fmt : StringCvt.radix -> word -> string
    val toString : word -> string
    val scan : StringCvt.radix
               -> (char, 'a) StringCvt.reader
               -> (word, 'a) StringCvt.reader
    val fromString : string -> word option
  end

  structure Word : sig
    (* same as WORD *)
    eqtype word
    val wordSize : int
    val toLarge : word -> LargeWord.word
    val toLargeX : word -> LargeWord.word
    val toLargeWord : word -> LargeWord.word
    val toLargeWordX : word -> LargeWord.word
    val fromLarge : LargeWord.word -> word
    val fromLargeWord : LargeWord.word -> word
    val toLargeInt : word -> LargeInt.int
    val toLargeIntX : word -> LargeInt.int
    val fromLargeInt : LargeInt.int -> word
    val toInt : word -> int
    val toIntX : word -> int
    val fromInt : int -> word
    val andb : word * word -> word
    val orb : word * word -> word
    val xorb : word * word -> word
    val notb : word -> word
    val << : word * SMLSharp.Word.word -> word
    val >> : word * SMLSharp.Word.word -> word
    val ~>> : word * SMLSharp.Word.word -> word
    val + : word * word -> word
    val - : word * word -> word
    val * : word * word -> word
    val div : word * word -> word
    val mod : word * word -> word
    val compare : word * word -> order
    val < : word * word -> bool
    val <= : word * word -> bool
    val > : word * word -> bool
    val >= : word * word -> bool
    val ~ : word -> word
    val min : word * word -> word
    val max : word * word -> word
    val fmt : StringCvt.radix -> word -> string
    val toString : word -> string
    val scan : StringCvt.radix
               -> (char, 'a) StringCvt.reader
               -> (word, 'a) StringCvt.reader
    val fromString : string -> word option
  end
  where type word = SMLSharp.Word.word

  structure Word32 : sig
    (* same as WORD *)
    eqtype word
    val wordSize : int
    val toLarge : word -> LargeWord.word
    val toLargeX : word -> LargeWord.word
    val toLargeWord : word -> LargeWord.word
    val toLargeWordX : word -> LargeWord.word
    val fromLarge : LargeWord.word -> word
    val fromLargeWord : LargeWord.word -> word
    val toLargeInt : word -> LargeInt.int
    val toLargeIntX : word -> LargeInt.int
    val fromLargeInt : LargeInt.int -> word
    val toInt : word -> int
    val toIntX : word -> int
    val fromInt : int -> word
    val andb : word * word -> word
    val orb : word * word -> word
    val xorb : word * word -> word
    val notb : word -> word
    val << : word * SMLSharp.Word.word -> word
    val >> : word * SMLSharp.Word.word -> word
    val ~>> : word * SMLSharp.Word.word -> word
    val + : word * word -> word
    val - : word * word -> word
    val * : word * word -> word
    val div : word * word -> word
    val mod : word * word -> word
    val compare : word * word -> order
    val < : word * word -> bool
    val <= : word * word -> bool
    val > : word * word -> bool
    val >= : word * word -> bool
    val ~ : word -> word
    val min : word * word -> word
    val max : word * word -> word
    val fmt : StringCvt.radix -> word -> string
    val toString : word -> string
    val scan : StringCvt.radix
               -> (char, 'a) StringCvt.reader
               -> (word, 'a) StringCvt.reader
    val fromString : string -> word option
  end

  structure Word8 : sig
    (* same as WORD *)
    eqtype word
    val wordSize : int
    val toLarge : word -> LargeWord.word
    val toLargeX : word -> LargeWord.word
    val toLargeWord : word -> LargeWord.word
    val toLargeWordX : word -> LargeWord.word
    val fromLarge : LargeWord.word -> word
    val fromLargeWord : LargeWord.word -> word
    val toLargeInt : word -> LargeInt.int
    val toLargeIntX : word -> LargeInt.int
    val fromLargeInt : LargeInt.int -> word
    val toInt : word -> int
    val toIntX : word -> int
    val fromInt : int -> word
    val andb : word * word -> word
    val orb : word * word -> word
    val xorb : word * word -> word
    val notb : word -> word
    val << : word * SMLSharp.Word.word -> word
    val >> : word * SMLSharp.Word.word -> word
    val ~>> : word * SMLSharp.Word.word -> word
    val + : word * word -> word
    val - : word * word -> word
    val * : word * word -> word
    val div : word * word -> word
    val mod : word * word -> word
    val compare : word * word -> order
    val < : word * word -> bool
    val <= : word * word -> bool
    val > : word * word -> bool
    val >= : word * word -> bool
    val ~ : word -> word
    val min : word * word -> word
    val max : word * word -> word
    val fmt : StringCvt.radix -> word -> string
    val toString : word -> string
    val scan : StringCvt.radix
               -> (char, 'a) StringCvt.reader
               -> (word, 'a) StringCvt.reader
    val fromString : string -> word option
  end
  where type word = SMLSharp.Word8.word

end =
struct

  structure IntBase =
  struct

    (* int is 32-bit signed integer. *)
    val precision = 32
    val minInt = ~0x80000000
    val maxInt = 0x7fffffff

  end

  structure IntInf =
  struct

    type int = SMLSharp.IntInf.int

    val abs =
        _import "prim_IntInf_abs"
        : __attribute__((pure,no_callback,alloc)) int -> int
    val ~ =
        _import "prim_IntInf_neg"
        : __attribute__((pure,no_callback,alloc)) int -> int
    val op - =
        _import "prim_IntInf_sub"
        : __attribute__((pure,no_callback,alloc)) (int, int) -> int
    val op + =
        _import "prim_IntInf_add"
        : __attribute__((pure,no_callback,alloc)) (int, int) -> int
    val op * =
        _import "prim_IntInf_mul"
        : __attribute__((pure,no_callback,alloc)) (int, int) -> int
    val div_unsafe =
        _import "prim_IntInf_div"
        : __attribute__((pure,no_callback,alloc)) (int, int) -> int
    val mod_unsafe =
        _import "prim_IntInf_mod"
        : __attribute__((pure,no_callback,alloc)) (int, int) -> int
    val cmp =
        _import "prim_IntInf_cmp"
        : __attribute__((pure,no_callback,alloc)) (int, int) -> SMLSharp.Int.int
    val toInt_unsafe =
        _import "prim_IntInf_toInt"
        : __attribute__((pure,no_callback)) int -> SMLSharp.Int.int
    val toWord =
        _import "prim_IntInf_toWord"
        : __attribute__((pure,no_callback)) int -> word
    val fromInt =
        _import "prim_IntInf_fromInt"
        : __attribute__((pure,no_callback,alloc)) SMLSharp.Int.int -> int
    val fromWord =
        _import "prim_IntInf_fromWord"
        : __attribute__((pure,no_callback,alloc)) word -> int
    val quot_unsafe =
        _import "prim_IntInf_quot"
        : __attribute__((pure,no_callback,alloc)) (int, int) -> int
    val rem_unsafe =
        _import "prim_IntInf_rem"
        : __attribute__((pure,no_callback,alloc)) (int, int) -> int
    val pow_unsafe =
        _import "prim_IntInf_pow"
        : __attribute__((pure,no_callback,alloc)) (int, SMLSharp.Int.int) -> int
    val log2_unsafe =
        _import "prim_IntInf_log2"
        : __attribute__((pure,no_callback)) int -> SMLSharp.Int.int
    val orb =
        _import "prim_IntInf_orb"
        : __attribute__((pure,no_callback,alloc)) (int, int) -> int
    val xorb =
        _import "prim_IntInf_xorb"
        : __attribute__((pure,no_callback,alloc)) (int, int) -> int
    val andb =
        _import "prim_IntInf_andb"
        : __attribute__((pure,no_callback,alloc)) (int, int) -> int
    val notb =
        _import "prim_IntInf_notb"
        : __attribute__((pure,no_callback,alloc)) int -> int

    fun compare (x, y) =
        case cmp (x, y) of
          0 => EQUAL
        | n => if n > 0 then GREATER else LESS

    fun op <= (x, y) = SMLSharp.Int.lteq (cmp (x, y), 0)
    fun op < (x, y) = SMLSharp.Int.lt (cmp (x, y), 0)
    fun op >= (x, y) = SMLSharp.Int.gteq (cmp (x, y), 0)
    fun op > (x, y) = SMLSharp.Int.gt (cmp (x, y), 0)

    fun toLarge n = n : int
    fun fromLarge n = n : int

    fun toInt int =
        if int < fromInt IntBase.minInt orelse fromInt IntBase.maxInt < int
        then raise Overflow
        else toInt_unsafe int

    val precision = NONE
    val minInt = NONE
    val maxInt = NONE

    fun op div (x, y) =
        if y = 0 then raise Div else div_unsafe (x, y)
    fun op mod (x, y) =
        if y = 0 then raise Div else mod_unsafe (x, y)

    fun quot (x, y) =
        if y = 0
        then raise Div
        else quot_unsafe (x, y)

    fun rem (x, y) =
        if y = 0
        then raise Div
        else rem_unsafe (x, y)

    (* ToDo : div and mod can be combined to one primitive. *)
    fun divMod (x, y) = (x div y, x mod y)

    (* ToDo : div and mod can be combined to one primitive. *)
    fun quotRem (x, y) = (quot (x, y), rem (x, y))

    fun pow (x, y) =
        if SMLSharp.Int.gt (y, 0)
        then pow_unsafe (x, y)
        else if y = 0 then 1
        else if x = 0 then raise Div
        else if x = 1 then 1
        else if x = ~1 then if SMLSharp.Int.mod (y, 2) = 0 then 1 else ~1
        else 0

    fun log2 x =
        if x <= 0 then raise Domain else log2_unsafe x

    fun << (x, 0w0) = x
      | << (x, width) = << (x * 2, SMLSharp.Word.sub (width, 0w1))
    fun ~>> (x, 0w0) = x
      | ~>> (x, width) = ~>> (x div 2, SMLSharp.Word.sub (width, 0w1))

    fun min (x, y) = if x < y then x else y
    fun max (x, y) = if x < y then y else x
    fun sign num = if num < 0 then ~1 else if num = 0 then 0 else 1
    fun sameSign (x, y) = (sign x) = (sign y)

    fun fmt radix n =
        let
          val r = fromInt (SMLSharpScanChar.radixToInt radix)
          fun loop (n, z) =
              if n <= 0 then z
              else let val m = toInt_unsafe (mod_unsafe (n, r))
                       val n = div_unsafe (n, r)
                   in loop (n, SMLSharpScanChar.intToDigit m :: z)
                   end
        in
          if n = 0 then "0"
          else if n < 0 then implode (#"~" :: loop (~n, nil))
          else implode (loop (n, nil))
        end

    fun toString n =
        fmt StringCvt.DEC n

    fun scan radix getc strm =
        case SMLSharpScanChar.scanInt radix getc strm of
          NONE => NONE
        | SOME ({neg, radix, digits}, strm) =>
          let
            val radix = fromInt radix
            fun loop (z, nil) = z
              | loop (z, h::t) = loop (z * radix + fromInt h, t)
            val n = loop (0, digits)
          in
            SOME (if neg then ~n else n, strm)
          end

    fun fromString string =
        StringCvt.scanString (scan StringCvt.DEC) string

  end (* IntInf *)

  structure LargeInt = IntInf

  structure Int =
  struct

    type int = int

    fun toInt x = x : int
    fun fromInt x = x : int

    val precision = SOME IntBase.precision
    val minInt = SOME IntBase.minInt
    val maxInt = SOME IntBase.maxInt

    val op + = SMLSharp.Int.add
    val op - = SMLSharp.Int.sub
    val op * = SMLSharp.Int.mul
    val op div = SMLSharp.Int.div
    val op mod = SMLSharp.Int.mod
    val op quot = SMLSharp.Int.quot
    val op rem = SMLSharp.Int.rem
    val op < = SMLSharp.Int.lt
    val op > = SMLSharp.Int.gt
    val op <= = SMLSharp.Int.lteq
    val op >= = SMLSharp.Int.gteq

    val toLarge = LargeInt.fromInt
    val fromLarge = LargeInt.toInt

    fun compare (left, right) =
        if left < right then LESS else if left = right then EQUAL else GREATER

    val ~ = SMLSharp.Int.neg
    val abs = SMLSharp.Int.abs
    fun min (left, right) = if left < right then left else right
    fun max (left, right) = if left > right then left else right
    fun sign num = if num < 0 then ~1 else if num = 0 then 0 else 1
    fun sameSign (left, right) = (sign left) = (sign right)

    fun fmt radix n =
        let
          val r = SMLSharpScanChar.radixToInt radix
          (* use nagative to avoid Overflow *)
          fun loop (n, z) =
              if n >= 0 then z
              else let val (n, m) = (quot (n, r), ~(rem (n, r)))
                   in loop (n, SMLSharpScanChar.intToDigit m :: z)
                   end
        in
          if n = 0 then "0"
          else if n > 0 then implode (loop (~n, nil))
          else implode (#"~" :: loop (n, nil))
        end

    fun toString n =
        fmt StringCvt.DEC n

    fun scan radix getc strm =
        case SMLSharpScanChar.scanInt radix getc strm of
          NONE => NONE
        | SOME ({neg, radix=r, digits}, strm) =>
          let
            fun loop (z, nil) = SOME (if neg then ~z else z, strm)
              | loop (z, h::t) =
                if (case radix of
                      StringCvt.BIN => z >= 0x40000000
                    | StringCvt.OCT => z >= 0x10000000
                    | StringCvt.DEC => z >= 0x0ccccccd
                    | StringCvt.HEX => z >= 0x08000000)
                then raise Overflow
                else loop (z * r + h, t)
          in
            loop (0, digits)
          end

    fun fromString s =
        StringCvt.scanString (scan StringCvt.DEC) s

  end (* Int *)

  structure Position = Int

  structure Word =
  struct

    type word = word
    val wordSize = 32  (* 32-bit unsigned integer *)
    fun toLarge x = x : word
    fun toLargeX x = x : word
    val toLargeWord = toLarge
    val toLargeWordX = toLargeX
    fun fromLarge x = x : word
    val fromLargeWord = fromLarge
    fun toLargeInt x = IntInf.fromWord x
    fun toLargeIntX x = IntInf.fromInt (SMLSharp.Word.toIntX x)
    fun fromLargeInt x = IntInf.toWord x

    fun toInt w =
        let val n = SMLSharp.Word.toIntX w
        in if SMLSharp.Int.lt (n, 0) then raise Overflow else n
        end

    val toIntX = SMLSharp.Word.toIntX
    val fromInt = SMLSharp.Word.fromInt
    val andb = SMLSharp.Word.andb
    val orb = SMLSharp.Word.orb
    val xorb = SMLSharp.Word.xorb
    val notb = SMLSharp.Word.notb
    val << = SMLSharp.Word.lshift
    val >> = SMLSharp.Word.rshift
    val ~>> = SMLSharp.Word.arshift
    val op + = SMLSharp.Word.add
    val op - = SMLSharp.Word.sub
    val op * = SMLSharp.Word.mul
    val op div = SMLSharp.Word.div
    val op mod = SMLSharp.Word.mod
    val op < = SMLSharp.Word.lt
    val op <= = SMLSharp.Word.lteq
    val op > = SMLSharp.Word.gt
    val op >= = SMLSharp.Word.gteq

    fun compare (x, y) =
        if x = y then EQUAL else if x < y then LESS else GREATER

    val op ~ = SMLSharp.Word.neg
    fun min (x, y) = if x < y then x else y
    fun max (x, y) = if x > y then x else y

    fun fmt radix n =
        let
          val r = SMLSharp.Word.fromInt (SMLSharpScanChar.radixToInt radix)
          fun loop (n, z) =
              if n = 0w0 then implode z
              else let val (n, m) = (n div r, toInt (n mod r))
                   in loop (n, SMLSharpScanChar.intToDigit m :: z)
                   end
        in
          if n = 0w0 then "0" else loop (n, nil)
        end

    fun toString w =
        fmt StringCvt.HEX w

    fun scan radix getc strm =
        case SMLSharpScanChar.scanWord radix getc strm of
          NONE => NONE
        | SOME ({radix=r, digits}, strm) =>
          let
            fun loop (z, nil) = SOME (z, strm)
              | loop (z, h::t) =
                if (case radix of
                      StringCvt.BIN => z >= 0wx80000000
                    | StringCvt.OCT => z >= 0wx20000000
                    | StringCvt.DEC => z >= 0wx1999999a
                    | StringCvt.HEX => z >= 0wx10000000)
                then raise Overflow
                else loop (z * fromInt r + fromInt h, t)
          in
            loop (0w0, digits)
          end

    fun fromString s =
        StringCvt.scanString (scan StringCvt.HEX) s

  end (* Word *)

  structure LargeWord = Word
  structure Word32 = Word

  structure Word8 =
  struct

    type word = SMLSharp.Word8.word
    val wordSize = 8  (* 8-bit unsigned integer *)
    val toLarge = SMLSharp.Word8.toWord
    fun toLargeX x = SMLSharp.Word.fromInt (SMLSharp.Word8.toIntX x)
    val toLargeWord = toLarge
    val toLargeWordX = toLargeX
    val fromLarge = SMLSharp.Word8.fromWord
    val fromLargeWord = fromLarge
    fun toLargeInt x = IntInf.fromWord (SMLSharp.Word8.toWord x)
    fun toLargeIntX x = IntInf.fromInt (SMLSharp.Word8.toIntX x)
    fun fromLargeInt x = SMLSharp.Word8.fromWord (IntInf.toWord x)
    val toInt = SMLSharp.Word8.toInt
    val toIntX = SMLSharp.Word8.toIntX
    val fromInt = SMLSharp.Word8.fromInt

    (* ToDo: the following should be builtin primitives *)
    fun andb (x, y) = fromLarge (SMLSharp.Word.andb (toLarge x, toLarge y))
    fun orb (x, y) = fromLarge (SMLSharp.Word.orb (toLarge x, toLarge y))
    fun xorb (x, y) = fromLarge (SMLSharp.Word.xorb (toLarge x, toLarge y))
    fun notb x = fromLarge (SMLSharp.Word.notb (toLarge x))
    fun << (x, y) = fromLarge (SMLSharp.Word.lshift (toLarge x, y))
    fun >> (x, y) = fromLarge (SMLSharp.Word.rshift (toLarge x, y))
    fun ~>> (x, y) = fromLarge (SMLSharp.Word.arshift (toLarge x, y))
    fun op ~ x = fromLarge (SMLSharp.Word.neg (toLarge x))

    val op + = SMLSharp.Word8.add
    val op - = SMLSharp.Word8.sub
    val op * = SMLSharp.Word8.mul
    val op div = SMLSharp.Word8.div
    val op mod = SMLSharp.Word8.mod
    val op < = SMLSharp.Word8.lt
    val op <= = SMLSharp.Word8.lteq
    val op > = SMLSharp.Word8.gt
    val op >= = SMLSharp.Word8.gteq

    fun compare (x, y) =
        if x = y then EQUAL else if x < y then LESS else GREATER

    fun min (x, y) = if x < y then x else y
    fun max (x, y) = if x > y then x else y

    fun fmt radix n =
        LargeWord.fmt radix (toLarge n)

    fun toString n =
        fmt StringCvt.HEX n

    fun scan radix getc strm =
        case LargeWord.scan radix getc strm of
          NONE => NONE
        | SOME (x, strm) =>
          if SMLSharp.Word.gt (x, 0wxff) then raise Overflow
          else SOME (SMLSharp.Word8.fromWord x, strm)

    fun fromString s =
        StringCvt.scanString (scan StringCvt.HEX) s

  end (* Word8 *)

end (* IntStructures *)

in

open IntStructures

end (* local *)
