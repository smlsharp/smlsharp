(**
 * Time structure.
 * @author AT&T Bell Laboratories
 * @author YAMATODANI Kiyoshi
 * @version $Id: Time.sml,v 1.8 2007/07/25 13:28:07 kiyoshiy Exp $
 *)
(* time.sml
 *
 * COPYRIGHT (c) 1995 AT&T Bell Laboratories.
 *
 *)
structure Time
          :> sig
              include TIME
(*
              (* export these for the benefit of, e.g., Posix.ProcEnv.times: *)
              val fractionsPerSecond : LargeInt.int
              val toFractions   : time -> LargeInt.int
              val fromFractions : LargeInt.int -> time
*)
              (* for Timer structure. *)
              val fromSecondsAndMicroSeconds
                  : LargeInt.int * LargeInt.int -> time
end = 
struct

  (***************************************************************************)

  structure LInt = LargeInt
  open LInt

  (***************************************************************************)

  datatype time = TIME of { sec : LInt.int, usec : LInt.int }

  exception Time

  (***************************************************************************)

  val L = LInt.fromInt

  infix 7 quot (* has same precedence with *, /, div and mod. *)
  val op quot = LInt.quot
  fun quotRem (left, right) = (LInt.quot (left,right), LInt.rem (left, right))

  val L0 = L 0
  val L1 = L 1
  val L2 = L 2
  val L5 = L 5
  val L6 = L 6
  val L10 = L 10
  val L50 = L 50
  val L500 = L 500
  val L1000 = L 1000
  val L5000 = L 5000
  val L50000 = L 50000
  val L500000 = L 500000
  val L1000000 = L 1000000
  val L1000000000 = L 1000000000
  val zeroTime = TIME { sec = L0, usec = L0 }

(*
  val fractionsPerSecond : LargeInt.int = 1000000
  fun toFractions (TIME { sec, usec }) = usec
  fun fromFractions usec = (TIME { usec = usec })
*)
  (* rounding is towards ZERO *)
  fun toSeconds (TIME { sec, usec }) = sec
  fun fromSeconds sec = TIME { sec = sec, usec = L0 }
  fun toMilliseconds (TIME { sec, usec }) =
      sec * L1000 + (usec quot (L1000))
  fun fromMilliseconds msec =
      TIME
          {sec = msec quot (L1000), usec = LInt.rem (msec, L1000) * L1000}
  fun toMicroseconds (TIME { sec, usec }) = sec * (L1000000) + usec
  fun fromMicroseconds usec =
      TIME { sec = usec quot (L1000000), usec = LInt.rem(usec, (L1000000)) }
  fun toNanoseconds (TIME { sec, usec }) =
      sec * (L1000000000) + usec * (L1000)
  fun fromNanoseconds nsec =
      TIME
          {
            sec = nsec quot (L1000000000),
            usec = LInt.rem(nsec, L1000000000) quot (L1000)
          }
  fun fromSecondsAndMicroSeconds (sec, usec) =
      TIME
          {
            sec = sec + (usec quot (L1000000)),
            usec = LInt.rem(usec, (L1000000))
          }

  fun fromReal rsec =
      TIME
          {
            sec = Real.toLargeInt IEEEReal.TO_ZERO rsec,
            usec =
            Real.toLargeInt
                IEEEReal.TO_ZERO (Real.* (Real.realMod rsec, 1.0e6))
          }
  fun toReal (TIME { sec, usec }) =
      Real.+
      (Real.fromLargeInt sec, Real.* (Real.fromLargeInt usec, 1.0e~6))

  fun now () =
      let val (ts, tu) = SMLSharp.Runtime.Time_gettimeofday 0
      in TIME{ sec = Int32.toLarge ts, usec = Int.toLarge tu}
      end

  val rndv = Vector.fromList [L50000, L5000, L500, L50, L5]

  fun fmt prec (TIME { sec, usec }) =
      let
        val (neg, sec, usec) =
            if sec < L0 andalso usec < L0
            then (true, ~sec, ~usec)
            else (false, sec, usec)
        fun fmtInt i = LInt.fmt StringCvt.DEC i
        fun fmtSec (neg, i) = fmtInt (if neg then ~i else i)
        fun isEven i = LInt.rem (i, L2) = L0
      in
        if Int.< (prec, 0)
        then raise General.Size
        else
          if prec = 0
          then
            let
              val sec =
                  case LInt.compare (usec, L500000) of
                    LESS => sec
                  | GREATER => sec + L1
                  | EQUAL => if isEven sec then sec else sec + L1
            in
              fmtSec (neg, sec)
            end
          else
            if Int.>= (prec, 6)
            then
              concat
                  [
                    fmtSec (neg, sec), ".",
                    StringCvt.padLeft #"0" 6 (fmtInt usec),
                    StringCvt.padLeft #"0" (Int.- (prec, 6)) ""
                  ]
            else
              let
                (* assume usec = 123456, prec = 3 *)
                (* rnd = 500 *)
                val rnd = Vector.sub (rndv, Int.- (prec, 1))
                (* whole = 123, frac = 456 *)
                val (whole, frac) = quotRem (usec, L2 * rnd)
                (* round up or down *)
                (* whole = 123 because frac(=456) < rnd(=500) *)
                val whole =
                    case LInt.compare (frac, rnd) of
                      LESS => whole
                    | GREATER => whole + L1
                    | EQUAL => if isEven whole then whole else whole + L1

                val frac = whole
(*
                (* rscl = 10000 *)
                val rscl = 2 * Vector.sub (rndv, 5 - prec)
                (* sec = 0, frac = 123 *)
                val (sec, frac) = LInt.quotRem (whole, rscl)
*)
              in
                concat
                    [
                      fmtSec (neg, sec), ".",
                      StringCvt.padLeft #"0" prec (fmtInt frac)
                    ]
              end
      end

  (* scan a time value; this has the syntax:
   *
   *  [+-~]?([0-9]+(.[0-9]+)? | .[0-9]+)
   *)
  fun scan getc s =
      let

        fun digv c = Int.toLarge (Int.- (Char.ord c, Char.ord #"0"))

        fun whole s =
            let
              fun loop (s, n, m, ret) =
                  case getc s of
                    NONE => ret (n, s, m)
                  | SOME (c, s') =>
                    if Char.isDigit c
                    then loop (s', L10 * n + digv c, m + L1, SOME)
                    else ret (n, s, m)
            in
              loop (s, L0, L0, fn _ => NONE)
            end

        fun time (negative, s) =
            let
              fun pow10 p =
                  if p = L0
                  then L1
                  else
                    if p = L1
                    then L10
                    else L10 * (pow10 (p - L1))
              fun return (sec, usec, s) =
                  SOME
                      (
                        TIME
                            {
                              sec = if negative then ~sec else sec,
                              usec = if negative then ~usec else usec
                            },
                        s
                      )
              fun fractional (wh, s) =
                  case whole s of
                    SOME (n, s, m) =>
                    let
                      fun done fr = return (wh, fr, s)
                    in
                      if m > L6
                      then done (n div pow10 (m - L6))
                      else
                        if m < L6 then done (n * pow10 (L6 - m)) else done n
                    end
                  | NONE => NONE
              fun withwhole s =
                  case whole s of
                    NONE => NONE
                  | SOME (wh, s', _) =>
                    (case getc s' of
                       SOME (#".", s'') => fractional (wh, s'')
                     | _ => return (wh, L0, s'))
            in
              case getc s of
                NONE => NONE
              | SOME (#".", s') => fractional (L0, s')
              | _ => withwhole s
            end

        fun sign s =
            case getc s of
              NONE => NONE
            | SOME (#"-", s') => time (true, s')
            | SOME (#"~", s') => time (true, s')
            | SOME (#"+", s') => time (false, s')
            | _ => time (false, s)
      in
        sign (StringCvt.skipWS getc s)
      end

  val toString = fmt 3
  val fromString = StringCvt.scanString scan

  local
    fun canonical (TIME{sec, usec}) =
        let
          val (secInUSec, usec) = quotRem (usec, L1000000)
          val sec = sec + secInUSec
          val secSign = LInt.sign sec
          val usecSign = LInt.sign usec
        in
          if secSign = usecSign orelse secSign = 0 orelse usecSign = 0
          then TIME{sec = sec, usec = usec}
          else
            if Int.< (secSign, 0)
            then TIME{sec = sec + L1, usec = usec - L1000000}
            else TIME{sec = sec - L1, usec = usec + L1000000}
        end
    fun binop oper (TIME t1, TIME t2) =
        canonical
            (TIME
                 {
                   sec = oper (#sec t1, #sec t2),
                   usec = oper (#usec t1, #usec t2)
                 })
  in
  val op + = binop (LInt.+)
  val op - = binop (LInt.-)
  end

  local
    fun binop oper (TIME t1, TIME t2) =
        case oper (#sec t1, #sec t2) of
          General.EQUAL =>
          oper (#usec t1, #usec t2)
        | order => order
  in
  val compare = binop LInt.compare
  val op < = (fn order => order = General.LESS) o compare
  val op <= = (fn order => order <> General.GREATER) o compare
  val op > = (fn order => order = General.GREATER) o compare
  val op >= = (fn order => order <> General.LESS) o compare
  end

  (***************************************************************************)

end
