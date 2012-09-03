(**
 * Time structure.
 * @author YAMATODANI Kiyoshi
 * @version $Id: Time.sml,v 1.8 2007/07/25 13:28:07 kiyoshiy Exp $
 *)
structure Time
          :> sig
              include TIME
              (* for Timer structure. *)
              val fromSecondsAndMicroSeconds
                  : LargeInt.int * LargeInt.int -> time
             end = 
struct

  (***************************************************************************)

  structure LI = LargeInt

  (***************************************************************************)

  (* The argument of TIME is nanoseconds.
   *)
  datatype time = TIME of LI.int

  (***************************************************************************)

  exception Time

  (***************************************************************************)

  val zeroTime = TIME 0

  val i1E3 : LI.int = 1000
  val i1E6 : LI.int = 1000000
  val i1E9 : LI.int = 1000000000

  val quot = LargeInt.quot
  infix quot

  (* To round towards ZERO, use quot, not div. *)
  fun toSeconds (TIME ns) = ns quot i1E9
  fun fromSeconds sec = TIME (sec * i1E9)
  fun toMilliseconds (TIME ns) = ns quot i1E6
  fun fromMilliseconds msec = TIME (msec * i1E6)
  fun toMicroseconds (TIME ns) = ns quot i1E3
  fun fromMicroseconds usec = TIME (usec * i1E3)
  fun toNanoseconds (TIME ns) = ns
  fun fromNanoseconds nsec = TIME nsec
  fun fromSecondsAndMicroSeconds (sec, usec) = TIME (sec * i1E9 + usec * i1E3)

  fun fromReal rsec = TIME (Real.toLargeInt IEEEReal.TO_ZERO (rsec * 1E9))
  fun toReal (TIME ns) = (Real.fromLargeInt ns) / 1E9

  fun now () =
      let val (s, ms) = SMLSharp.Runtime.Time_gettimeofday 0
      in fromSecondsAndMicroSeconds (Int.toLarge s, Int.toLarge ms)
      end

  fun pow10 0 = 1 : LI.int
    | pow10 1 = 10
    | pow10 2 = 100
    | pow10 3 = 1000
    | pow10 4 = 10000
    | pow10 5 = 100000
    | pow10 6 = 1000000
    | pow10 7 = 10000000
    | pow10 8 = 100000000
    | pow10 9 = 1000000000
    | pow10 n = raise Fail ("Bug:Time.pow10(" ^ Int.toString n ^ ")")

  local
    fun zeros n = implode (List.tabulate (n, fn i => #"0"))
  in
  fun fmt prec (TIME ns) =
      if prec < 0
      then raise General.Size
      else
        let
          val underPrec = if prec < 9 then pow10 (9 - prec - 1) else 0
          (* To round ns to the nearest, adds 0.5 * precision. *)
          val ns =
              if prec < 9
              then ns + (5 * underPrec * LI.fromInt (LI.sign ns))
              else ns
          (* splits ns to whole part and fraction part. *)
          val (whole, frac) = (ns quot i1E9, ns mod i1E9)
          val wholeStr = LI.toString whole
          val frac = if prec < 9 then frac quot (underPrec * 10) else frac
          val fracStr = LI.toString (abs frac)
          (* appends 0s to fill the specified precision. *)
          val fracStr = 
              if size fracStr < prec
              then fracStr ^ zeros (prec - size fracStr)
              else fracStr
        in
          if 0 < prec then wholeStr ^ "." ^ fracStr else wholeStr
        end
  end

  (* scan a time value; this has the syntax:
   *
   *  [+-~]?([0-9]+(.[0-9]+)? | .[0-9]+)
   *)
  local
    structure SC = StringCvt
    structure PC = ParserComb

    fun charToNumber char =
        case char of
          #"0" => 0
        | #"1" => 1
        | #"2" => 2
        | #"3" => 3
        | #"4" => 4
        | #"5" => 5
        | #"6" => 6
        | #"7" => 7
        | #"8" => 8
        | #"9" => 9
        | _ => raise Fail "unexpected char in IEEEReal.charToNumbr."

    val isNumberChar = Char.isDigit

    (* (+|-|~)? *)
    fun scanSign reader stream =
        PC.or(PC.seqWith #2 (PC.char #"+", PC.result false),
              PC.or (PC.seqWith #2 (PC.char #"~", PC.result true),
                     PC.or(PC.seqWith #2 (PC.char #"-", PC.result true),
                           PC.result false)))
             reader stream

    (* scan [0-9] *)
    fun scanNumChar reader stream =
        PC.wrap(PC.eatChar isNumberChar, charToNumber) reader stream

    (* NOTE: SMLBasis document seems specify [0-9]+.[0-9]+? .
     * But SML/NJ and MLton accept [0-9]+(.[0-9]+?)?
     * So, "5" should be rejected by SMLBasis spec, but is accepted by SML/NJ
     * and MLton.
     *)
    (* scan: [0-9]+(.[0-9]+?)? *)
    fun scanFirstForm reader stream =
        (PC.seq
             (
               PC.oneOrMore scanNumChar,
               PC.or(PC.seqWith #2 (PC.char #".", PC.zeroOrMore scanNumChar),
                     PC.result [0])
             ))
            reader stream

    (* scan: .[0-9]+ *)
    fun scanSecondForm reader stream =
        (PC.wrap
             (
               PC.seqWith #2 (PC.char #".", PC.oneOrMore scanNumChar),
               fn fractionals => ([], fractionals)
             ))
            reader stream

    (* scan: ([0-9]+(.[0-9]+?)? | .[0-9]+) *)
    fun scanDigits reader steram =
        PC.or (scanFirstForm, scanSecondForm) reader steram

    (* digitsToInt [1, 2, 3] = 123 , for example.
     *)
    fun digitsToInt digits =
        List.foldl (fn (left, right) => left + right * 10) 0 digits
  in
  fun scan reader stream =
      PC.wrap
          (
            PC.seq(scanSign, scanDigits),
            fn (isNegative, (wholeDigits, fracDigits)) =>
               let
                 val sign = if isNegative then ~1 else 1
                 (* The whole part denotes seconds. *)
                 val whole = (digitsToInt wholeDigits) * i1E9
                 (* 1E~9 denotes 1 nanosecond.
                  * Truncates trailing digits beyond 9 digits.
                  * Appends 0s if the digits sequence is shorter than 9. *)
                 val fracLen = List.length fracDigits
                 val frac =
                     if fracLen <= 9
                     then digitsToInt fracDigits * (pow10 (9 - fracLen))
                     else digitsToInt (List.take (fracDigits, 9))
               in
                 TIME(sign * (whole + frac))
               end
          )
          reader (StringCvt.skipWS reader stream)
  end

  val toString = fmt 3
  val fromString = StringCvt.scanString scan

  val op + = fn (TIME x, TIME y) => TIME (x + y)
  val op - = fn (TIME x, TIME y) => TIME (x - y)

  fun compare (TIME t1, TIME t2) = LI.compare (t1, t2)
  val op < = fn (TIME x, TIME y) => x < y
  val op <= = fn (TIME x, TIME y) => x <= y
  val op > = fn (TIME x, TIME y) => x > y
  val op >= = fn (TIME x, TIME y) => x >= y

  (***************************************************************************)

end
