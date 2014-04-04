(**
 * Time
 * @author YAMATODANI Kiyoshi
 * @author UENO Katsuhiro
 * @copyright 2010, 2013, Tohoku University.
 *)

infix 7 * / quot
infix 6 + - ^
infixr 5 ::
infix 4 = < >=
val op quot = IntInf.quot
val op * = IntInf.*
val op + = IntInf.+
val op / = LargeReal./
val op < = SMLSharp_Builtin.Int.lt
val op >= = SMLSharp_Builtin.Int.gteq
val op - = SMLSharp_Builtin.Int.sub_unsafe
val op ^ = String.^
structure Word = SMLSharp_Builtin.Word

structure Time =
struct

  type time = IntInf.int
  exception Time

  val op + = IntInf.+

  val zeroTime = 0 : IntInf.int

  fun fromReal rsec =
      IntInf.fromLarge
        (LargeReal.toLargeInt IEEEReal.TO_ZERO
                              (LargeReal.* (rsec, Real.toLarge 1E9)))
  fun toReal nsec =
      LargeReal.fromLargeInt (IntInf.toLarge nsec) / Real.toLarge 1E9

(* To round towards ZERO, use quot, not div. *)
  fun toSeconds nsec      = IntInf.toLarge (nsec quot 1000000000)
  fun toMilliseconds nsec = IntInf.toLarge (nsec quot 1000000)
  fun toMicroseconds nsec = IntInf.toLarge (nsec quot 1000)
  fun toNanoseconds nsec  = IntInf.toLarge nsec
  fun fromSeconds sec       = IntInf.fromLarge sec  * 1000000000
  fun fromMilliseconds msec = IntInf.fromLarge msec * 1000000
  fun fromMicroseconds usec = IntInf.fromLarge usec * 1000
  fun fromNanoseconds nsec  = IntInf.fromLarge nsec

  val prim_gettimeofday =
      _import "prim_Time_gettimeofday"
      : __attribute__((no_callback)) int array -> int

  (* number of seconds from UNIX epoch without leap seconds in UTC. *)
  fun now () =
      let
        val ret = SMLSharp_Builtin.Array.alloc 2
        val err = prim_gettimeofday ret
        val _ = if err < 0 then raise SMLSharp_Runtime.OS_SysErr () else ()
        val sec = SMLSharp_Builtin.Array.sub_unsafe (ret, 0)
        val usec = SMLSharp_Builtin.Array.sub_unsafe (ret, 1)
      in
        IntInf.fromInt sec * 1000000000 + IntInf.fromInt usec * 1000
      end

  fun toStringWithDot (n, d, prec) =
      let
        val (whole, frac) = IntInf.quotRem (IntInf.abs n, IntInf.pow (10, d))
        val sign = if IntInf.sign n < 0 then "~" else ""
        val whole = IntInf.toString whole
        val frac = IntInf.toString frac
      in
        sign ^ whole ^ "." ^ StringCvt.padRight #"0" prec frac
      end

  fun fmt prec nsec =
      if prec < 0 then raise Size
      else if prec >= 9 then toStringWithDot (nsec, 9, prec)
      else
        let
          val p = IntInf.pow (10, 9 - prec)
          val (d, r) = IntInf.quotRem (nsec, p)
          (* round to nearest or even *)
          val d = if IntInf.abs r = IntInf.div (p, 2)
                  then d + IntInf.rem (d, 2) else d
        in
          toStringWithDot (d, prec, prec)
        end

  fun toString nsec =
      fmt 3 nsec

  fun toInt digits =
      let
        fun loop (nil, z) = z
          | loop (h::t, z) = loop (t, z * 10 + IntInf.fromInt h)
      in
        loop (digits, 0)
      end

  fun scan getc strm =
      let
        val strm = SMLSharp_ScanChar.skipSpaces getc strm
        (* scan [+~-]?([0-9]+(\.[0-9]+)?|\.[0-9]+) *)
        val (sign, strm) = SMLSharp_ScanChar.scanSign getc strm
      in
        case SMLSharp_ScanChar.scanMantissa getc strm of
          NONE => NONE
        | SOME ((il, fl), strm) =>
          let
            fun pad (nil, 0w0) = nil
              | pad (nil, n) = 0 :: pad (nil, Word.sub (n, 0w1))
              | pad (h::t, 0w0) = raise Time
              | pad (h::t, n) = h :: pad (t, Word.sub (n, 0w1))
            val n = toInt il * 1000000000 + toInt (pad (fl, 0w9))
          in
            SOME (if sign then IntInf.~ n else n, strm)
          end
      end

  fun fromString s =
      StringCvt.scanString scan s

  val op - = IntInf.-
  val compare = IntInf.compare
  val op < = IntInf.<
  val op <= = IntInf.<=
  val op > = IntInf.>
  val op >= = IntInf.>=

end
