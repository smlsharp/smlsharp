(**
 * Time structure.
 * @author YAMATODANI Kiyoshi
 * @copyright 2010, Tohoku University.
 * @version $Id: Time.sml,v 1.8 2007/07/25 13:28:07 kiyoshiy Exp $
 *)
_interface "Time.smi"

structure Time :> TIME =
struct

  infix 7 * / quot
  infix 6 + -
  infixr 5 ::
  infix 4 = < >=
(*
  infix 6 + -
  infix 4 = <> > >= < <=
  val op + = SMLSharp.Int.add
  val op - = SMLSharp.Int.sub
  val op > = SMLSharp.Int.gt
  val op < = SMLSharp.Int.lt
  val op <= = SMLSharp.Int.gteq
  val op >= = SMLSharp.Int.lteq
*)
  val op quot = IntInf.quot
  val op * = IntInf.*
  val op / = LargeReal./
  val op < = SMLSharp.Int.lt
  val op >= = SMLSharp.Int.gteq
  val op - = SMLSharp.Int.sub
  val op + = IntInf.+

  type time = SMLSharp.IntInf.int
  exception Time

  val zeroTime = 0 : SMLSharp.IntInf.int

  fun fromReal rsec =
      IntInf.fromLarge
        (LargeReal.toLargeInt IEEEReal.TO_ZERO
                              (LargeReal.* (rsec, Real.toLarge 1E9)))
  fun toReal nsec =
      LargeReal.fromLargeInt (IntInf.toLarge nsec) / Real.toLarge 1E9

(* To round towards ZERO, use quot, not div. *)
(* 2012-1-1 ohori.
  fun toSeconds nsec = IntInf.toLarge (nsec quot 100000000)
*)
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
        val ret = SMLSharp.PrimArray.allocArray 2
        val err = prim_gettimeofday ret
        val _ = if err < 0 then raise SMLSharpRuntime.OS_SysErr () else ()
        val sec = SMLSharp.PrimArray.sub (ret, 0)
        val usec = SMLSharp.PrimArray.sub (ret, 1)
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

  fun scanSign getc strm =
      case getc strm of
        SOME (#"+", strm) => (false, strm)
      | SOME (#"~", strm) => (true, strm)
      | SOME (#"-", strm) => (true, strm)
      | _ => (false, strm)

  fun scanDigits getc strm =
      case SMLSharpScanChar.scanRepeat1 SMLSharpScanChar.scanDigit getc strm of
        NONE => (nil, strm)
      | SOME x => x

  fun digitsToTime (il, fl, limit, z) =
      case (il, fl, limit) of
        (h::t, fl, _) => digitsToTime (t, fl, limit, z * 10 + IntInf.fromInt h)
      | (nil, 0::t, 0) => digitsToTime (il, t, limit, z)
      | (nil, h::t, 0) => raise Time
      | (nil, h::t, limit) =>
        digitsToTime (il, t, limit - 1, z * 10 + IntInf.fromInt h)
      | (nil, nil, 0) => z
      | (nil, nil, limit) => digitsToTime (il, fl, limit - 1, z * 10)

  fun scan getc strm =
      let
        val strm = SMLSharpScanChar.skipSpaces getc strm
        (* scan [+~-]?([0-9]+\.[0-9]*|\.[0-9]+) *)
        val (sign, strm) = scanSign getc strm
        val (il, strm) = scanDigits getc strm
        val (fl, strm) =
            case getc strm of
              SOME (#".", strm) => scanDigits getc strm
            | _ => (nil, strm)
      in
        case (il, fl) of
          (nil, nil) => NONE
        | _ => SOME (digitsToTime (il, fl, 9, 0), strm)
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
