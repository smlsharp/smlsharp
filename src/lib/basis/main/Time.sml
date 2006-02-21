(**
 * Time structure.
 * @author AT&T Bell Laboratories
 * @author YAMATODANI Kiyoshi
 * @version $Id: Time.sml,v 1.4 2005/09/09 15:23:22 kiyoshiy Exp $
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

  (***************************************************************************)

  datatype time = TIME of { sec : LargeInt.int, usec : LargeInt.int }

  exception Time

  (***************************************************************************)

  infix quot
  val op quot = LInt.quot
  fun quotRem (left, right) = (LInt.quot (left,right), LInt.rem (left, right))

  val zeroTime = TIME { sec = 0, usec = 0 }
(*
  val fractionsPerSecond : LargeInt.int = 1000000
  fun toFractions (TIME { sec, usec }) = usec
  fun fromFractions usec = (TIME { usec = usec })
*)
  (* rounding is towards ZERO *)
  fun toSeconds (TIME { sec, usec }) = sec
  fun fromSeconds sec = TIME { sec = sec, usec = 0 }
  fun toMilliseconds (TIME { sec, usec }) = sec * 1000 + (usec quot 1000)
  fun fromMilliseconds msec =
      TIME { sec = msec quot 1000, usec = LInt.rem (msec, 1000) * 1000 }
  fun toMicroseconds (TIME { sec, usec }) = sec * 1000000 + usec
  fun fromMicroseconds usec =
      TIME { sec = usec quot 1000000, usec = LInt.rem(usec, 1000000) }
  fun toNanoseconds (TIME { sec, usec }) = sec * 1000000000 + usec * 1000
  fun fromNanoseconds nsec =
      TIME
      {sec = nsec quot 1000000000, usec = LInt.rem(nsec, 1000000000) quot 1000}
  fun fromSecondsAndMicroSeconds (sec, usec) = TIME{sec = sec, usec = usec}

  fun fromReal rsec =
      TIME
          {
            sec = Real.toLargeInt IEEEReal.TO_ZERO rsec,
            usec = Real.toLargeInt IEEEReal.TO_ZERO (Real.realMod rsec * 1.0e6)
          }
  fun toReal (TIME { sec, usec }) =
      (Real.fromLargeInt sec) + (Real.fromLargeInt usec * 1.0e~6)

  fun now () =
      let val (ts, tu) = Time_gettimeofday 0
      in TIME{ sec = Int32.toLarge ts, usec = Int.toLarge tu}
      end

  val rndv = Vector.fromList [50000 : LargeInt.int, 5000, 500, 50, 5]

  fun fmt prec (TIME { sec, usec }) =
      let
        val (neg, sec, usec) =
            if sec < 0 andalso usec < 0
            then (true, ~sec, ~usec)
            else (false, sec, usec)
        fun fmtInt i = LInt.fmt StringCvt.DEC i
        fun fmtSec (neg, i) = fmtInt (if neg then ~i else i)
        fun isEven i = LInt.rem (i, 2) = 0
      in
        if prec < 0
        then raise General.Size
        else
          if prec = 0
          then
            let
              val sec =
                  case LInt.compare (usec, 500000) of
                    LESS => sec
                  | GREATER => sec + 1
                  | EQUAL => if isEven sec then sec else sec + 1
            in
              fmtSec (neg, sec)
            end
          else
            if prec >= 6
            then
              concat
                  [
                    fmtSec (neg, sec), ".",
                    StringCvt.padLeft #"0" 6 (fmtInt usec),
                    StringCvt.padLeft #"0" (prec - 6) ""
                  ]
            else
              let
                (* assume usec = 123456, prec = 3 *)
                (* rnd = 500 *)
                val rnd = Vector.sub (rndv, prec - 1)
                (* whole = 123, frac = 456 *)
                val (whole, frac) = quotRem (usec, 2 * rnd)
                (* round up or down *)
                (* whole = 123 because frac(=456) < rnd(=500) *)
                val whole =
                    case LInt.compare (frac, rnd) of
                      LESS => whole
                    | GREATER => whole + 1
                    | EQUAL => if isEven whole then whole else whole + 1

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

        fun digv c = Int.toLarge (Char.ord c - Char.ord #"0")

        fun whole s =
            let
              fun loop (s, n, m, ret) =
                  case getc s of
                    NONE => ret (n, s, m)
                  | SOME (c, s') =>
                    if Char.isDigit c
                    then loop (s', 10 * n + digv c, m + 1, SOME)
                    else ret (n, s, m)
            in
              loop (s, 0, 0, fn _ => NONE)
            end

        fun time (negative, s) =
            let
              fun pow10 0 = 1
                | pow10 1 = 10
                | pow10 p = 10 * (pow10 (p - 1))
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
                      if m > 6
                      then done (n div pow10 (m - 6))
                      else
                        if m < 6 then done (n * pow10 (6 - m)) else done n
                    end
                  | NONE => NONE
              fun withwhole s =
                  case whole s of
                    NONE => NONE
                  | SOME (wh, s', _) =>
                    (case getc s' of
                       SOME (#".", s'') => fractional (wh, s'')
                     | _ => return (wh, 0, s'))
            in
              case getc s of
                NONE => NONE
              | SOME (#".", s') => fractional (0, s')
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
          val (secInUSec, usec) = quotRem (usec, 1000000)
          val sec = sec + secInUSec
          val secSign = LInt.sign sec
          val usecSign = LInt.sign usec
        in
          if secSign = usecSign orelse secSign = 0 orelse usecSign = 0
          then TIME{sec = sec, usec = usec}
          else
            if secSign < 0
            then TIME{sec = sec + 1, usec = usec - 1000000}
            else TIME{sec = sec - 1, usec = usec + 1000000}
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
