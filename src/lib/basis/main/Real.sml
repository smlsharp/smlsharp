(**
 * Real structure.
 * @author YAMATODANI Kiyoshi
 * @version $Id: Real.sml,v 1.18.2.1 2007/03/26 09:18:50 katsu Exp $
 *)
structure Real =
struct

  (***************************************************************************)

  type real = real

  (***************************************************************************)

  structure Math = Math
  structure IR = IEEEReal

  (***************************************************************************)

  val radix = 2

  val precision = 53

  val maxFinite = 1.79769313486E308
  val minPos = 4.94065645841E~324
  val minNormalPos = 2.22507385851E~308

  (* ToDo : which definition is correct ? *)
  val posInf = 1.0 / 0.0
  val negInf = ~1.0 / 0.0
  val nan = 0.0 / 0.0

  fun abs real = if real < 0.0 then real * ~1.0 else real

  fun min (left : real, right) = if left < right then left else right
  fun max (left : real, right) = if left < right then right else left

  local
    (*
     * 0 FP_SNAN signaling NaN
     * 1 FP_QNAN quiet NaN
     * 2 FP_NINF negative infinity
     * 3 FP_PINF positive infinity
     * 4 FP_NDENORM negative denormalized non-zero
     * 5 FP_PDENORM positive denormalized non-zero
     * 6 FP_NZERO negative zero
     * 7 FP_PZERO positive zero
     * 8 FP_NNORM negative normalized non-zero
     * 9 FP_PNORM positive normalized non-zero
     *)
    datatype internal_class = 
             FP_SNAN
           | FP_QNAN
           | FP_NINF
           | FP_PINF
           | FP_NDENORM
           | FP_PDENORM
           | FP_NZERO
           | FP_PZERO
           | FP_NNORM
           | FP_PNORM

    fun internalClass real =
        case Real_class real of
          0 => FP_SNAN
        | 1 => FP_QNAN
        | 2 => FP_NINF
        | 3 => FP_PINF
        | 4 => FP_NDENORM
        | 5 => FP_PDENORM
        | 6 => FP_NZERO
        | 7 => FP_PZERO
        | 8 => FP_NNORM
        | 9 => FP_PNORM
        | _ => raise Fail "bug: unexpected return value of Real_class"
  in
  fun class real =
      case internalClass real of
        FP_SNAN => IR.NAN IR.SIGNALLING
      | FP_QNAN => IR.NAN IR.QUIET
      | FP_NINF => IR.INF
      | FP_PINF => IR.INF
      | FP_NDENORM => IR.SUBNORMAL
      | FP_PDENORM => IR.SUBNORMAL
      | FP_NZERO => IR.ZERO
      | FP_PZERO => IR.ZERO
      | FP_NNORM => IR.NORMAL
      | FP_PNORM => IR.NORMAL

  fun isFinite real =
      case class real of IR.INF => false | IR.NAN _ => false |_ => true

  fun isNan real = case class real of IR.NAN _ => true | _ => false

  fun isNormal real = case class real of IR.NORMAL => true | _ => false

  fun sign real = 
      case internalClass real of
        FP_SNAN => raise General.Domain
      | FP_QNAN => raise General.Domain
      | FP_NINF => ~1
      | FP_PINF => 1
      | FP_NDENORM => ~1
      | FP_PDENORM => 1
      | FP_NZERO => 0
      | FP_PZERO => 0
      | FP_NNORM => ~1
      | FP_PNORM => 1

  fun signBit real =
      case internalClass real of
        FP_NINF => true
      | FP_NDENORM => true
      | FP_NZERO => true
      | FP_NNORM => true
      | _ => false

  fun sameSign (left, right) = (signBit left) = (signBit right)

  val copySign = Real_copySign
  end

  fun == (left, right) =
      if isNan left orelse isNan right
      then false
      else Real_equal (left, right)
  val != = not o op == 

  fun ?= (left, right) =
      if isNan left orelse isNan right
      then true
      else Real_equal (left, right)

  fun toManExp real =
      let val (man, exp) = Real_toManExp real
      in {man = man, exp = exp}
      end

  fun fromManExp {man, exp} = Real_fromManExp (man, exp)

  fun split real =
      let val (whole, frac) = Real_split real
      in {whole = whole, frac = frac}
      end

  val realMod = #frac o split

  val nextAfter = fn _ => raise Unimplemented "nextAfter"

  fun checkFloat real =
      case class real of
        IR.INF => raise General.Overflow
      | IR.NAN _ => raise General.Div
      | _ => real

  fun toInt mode real =
      case mode of
        IR.TO_NEGINF => Real_floor real
      | IR.TO_POSINF => Real_ceil real
      | IR.TO_ZERO => Real_trunc real
      | IR.TO_NEAREST => Real_round real

  val toLargeInt = toInt

  val fromInt = Real_fromInt
  val fromLargeInt = Real_fromInt

  val toFloat = Real_toFloat
  val fromFloat = Real_fromFloat

  fun toLarge real = real
  fun fromLarge roundingMode real = real

  fun floor real = toInt IR.TO_NEGINF real
  fun ceil real = toInt IR.TO_POSINF real
  fun trunc real = toInt IR.TO_ZERO real
  fun round real = toInt IR.TO_NEAREST real

  fun isZero real = (0.0 <= real) andalso (real <= 0.0)
  local
    fun ifNonZeroFinite f real =
        case class real of
          IR.NORMAL => f real
        | IR.SUBNORMAL => f real
        | _ => real
    val whole = #whole o split
    val frac = realMod
  in
  (*
   * We cannot use floor to implement realFloor because, if the argument is
   * too big, the former may raise overflow but the latter should not raise.
   *)
  val realFloor =
      ifNonZeroFinite
      (fn real =>
          if 0.0 < real
          then whole real (* 1.4 ==> 1.0 *)
          else
            if isZero (frac real)
            then whole real (* -1.0 ==> -1.0 *)
            else (whole real) - 1.0) (* -1.2 ==> -2.0 *)
  val realCeil =
      ifNonZeroFinite
      (fn real =>
          if real < 0.0
          then whole real (* -1.4 ==> -1.0 *)
          else
            if isZero (frac real)
            then whole real (* 1.0 ==> 1.0 *)
            else (whole real) + 1.0) (* 1.2 ==> 2.0 *)
  val realTrunc = ifNonZeroFinite (fn real => whole real)
  val realRound = 
      ifNonZeroFinite
      (fn real => whole (if real < 0.0 then real - 0.5 else real + 0.5))

  end (* local *)

  fun rem (left, right) = left - (realTrunc(left / right) * right)

  val toDecimal = fn _ => raise Unimplemented "toDecimal"

  local
        fun pow10 num =
            let
              fun accum 0 result = result
                | accum n result = accum (n - 1) (result * 10.0)
              val powered = accum (Int.abs num) 1.0
            in
              if num < 0
              then 1.0 / powered
              else powered
            end
    fun accumIntList ints =
        foldl (fn (int, accum) => accum * 10.0 + fromInt int) 0.0 ints
  in
  (* sign * 0.d[1]d[2]...d[n] * 10 ^ exp *)
  fun fromDecimal ({kind, sign, digits, exp} : IR.decimal_approx) =
      case kind of
        IR.NAN _ => nan
      | IR.INF => if sign then negInf else posInf
      | IR.ZERO => if sign then ~1.0 * 0.0 else 0.0
      | _ =>
        let
          val frac =
              (accumIntList digits) * (1.0 / (pow10 (List.length digits)))
          val exp = pow10 exp
        in
          (if sign then ~1.0 else 1.0) * frac * exp
        end
  end

  local
    structure PC = ParserComb
    fun charOfNum num = 
        case num of
          0 => #"0"
        | 1 => #"1"
        | 2 => #"2"
        | 3 => #"3"
        | 4 => #"4"
        | 5 => #"5"
        | 6 => #"6"
        | 7 => #"7"
        | 8 => #"8"
        | 9 => #"9"
        | _ => raise Fail "bug: Real.charOfNum"
  in

  local
    (* toManExp10 123.456 ==> {man = 1.23456, exp = 2} *)
    fun toManExp10 real =
        case class real of
          IEEEReal.ZERO => {man = 0.0, exp = 0}
        | IEEEReal.INF => {man = real, exp = 0}
        | IEEEReal.NAN _ => {man = real, exp = 0}
        | _ =>
          let
            val exp = trunc (Math.log10 (abs real))
            (* man = 123.456 * (0.1 ^ exp) *)
            (* Note :
             * There found a case that (B) results more precisely than (A).
             * A) man = 123.456 / (10.0 ^ exp)
             * B) man = 123.456 * (0.1 ^ exp)
             *)
            val man = real * Math.pow (0.1, fromInt exp)
          in {man = man, exp = exp}
          end

    fun dropZero (#"0" :: list) = dropZero list
      | dropZero list = list

    (*
     * fracToString _ 0.123 2 [] ==> "12"
     * fracToString true 0.123 4 [] ==> "1230"
     * fracToString false 0.123 4 [] ==> "123"
     *)
    fun fracToString withTrailingZeros real 0 result =
        implode
            (rev
                 (if withTrailingZeros
                  then result
                  else dropZero result))
      | fracToString withTrailingZeros real max result =
        let val {whole, frac} = split (real * 10.0)
        in
          fracToString
              withTrailingZeros
              frac
              (Int.-(max, 1))
              (charOfNum (trunc whole) :: result)
        end

    fun signToString real =
        (if ~1 = sign real then "~" else "")
        handle General.Domain => "" (* if real is nan. *)

    (* wholeToString 123.000 ==> "123" *)
    fun wholeToString real =
        let
          fun accum whole result =
              if whole < 1.0
              then concat result
              else
                accum
                    (whole / 10.0)
                    (Int.toString(trunc(rem(whole, 10.0))) :: result)
        in
          if (abs real) < 1.0
          then "0"
          else (accum (abs real) [])
        end

    (*
     * normalToString _ 3 0.1239 ==> "0.124"
     * normalToString false 3 0.1294 ==> "0.129"
     * normalToString false 3 0.1295 ==> "0.130"
     * normalToString true 3 0.1294 ==> "0.129"
     * normalToString true 3 0.1295 ==> "0.13"
     *)
    fun normalToString withTrailingZeros maxFrac real =
        let
          (* round to the 0.1^maxFrac *)
          val real =
              real
              + fromInt(sign real)
                * 5.0
                * Math.pow (0.1, fromInt maxFrac + 1.0)
          val {whole, frac} = split real
          val frac = abs frac
          val signString = signToString real
          val wholeString = wholeToString whole
          val fracString =
              if 0 = maxFrac
              then ""
              else
                let val str = fracToString withTrailingZeros frac maxFrac []
                in
                  if (not withTrailingZeros) andalso str = ""
                  then ""
                  else "." ^ str
                end
        in
          signString
          ^ wholeString
          ^ fracString
        end

    fun fmtImpl withTrailingZeros mode real =
        case class real of
          IEEEReal.INF => signToString real ^ "inf"
        | IEEEReal.NAN _ => signToString real ^ "nan"
        | _ =>
          case mode of
            StringCvt.SCI maxFracOpt =>
            let
              val {man, exp} = toManExp10 real
              val maxFrac = getOpt (maxFracOpt, 6)
            in
              if Int.<(maxFrac, 0)
              then raise General.Size
              else
                (normalToString withTrailingZeros maxFrac man)
                ^ "E" ^ (Int.toString exp)
            end
          | StringCvt.FIX maxFracOpt =>
            let val maxFrac = getOpt (maxFracOpt, 6)
            in
              if Int.<(maxFrac, 0)
              then raise General.Size
              else normalToString withTrailingZeros maxFrac real
            end
          | StringCvt.EXACT => raise Unimplemented "Real.fmt EXACT"
          | StringCvt.GEN _ => raise Fail "Bug: fmtImpl"
  in
  fun fmt mode real =
      case mode of
        StringCvt.GEN maxDigitsOpt =>
        let
          val maxDigits = getOpt (maxDigitsOpt, 12)
          val _ = if Int.<(maxDigits, 1) then raise Size else ()
          val {whole, frac} = split real
          (* the number of digits of whole. *)
          val wholeNumDecimals =
              if isZero whole then 0 else floor (Math.log10 (abs whole)) + 1
          (* the number of leading zeros of frac. (ex. 2 for 0.003) *)
          val fracNumZeros =
              if isZero frac then 0 else Int.abs(ceil (Math.log10 (abs frac)))
          (* precision for FIX mode *)
          val prec =
              if wholeNumDecimals = 0
              then Int.+(maxDigits, fracNumZeros)
              else
                if wholeNumDecimals < maxDigits
                then Int.-(maxDigits, wholeNumDecimals)
                else 0
          (* GEN is almostly same to FIX or SCI, but does not allow trailing
           * zeros. *)
          val fix = fmtImpl false (StringCvt.FIX (SOME prec)) real
          val sci =
              fmtImpl false (StringCvt.SCI (SOME(Int.-(maxDigits, 1)))) real
        in
          if size fix <= size sci then fix else sci
        end
      | _ => fmtImpl true mode real
  end

  fun toString real = fmt (StringCvt.GEN NONE) real

  fun scan reader stream =
      PC.wrap (IEEEReal.scan, fn decimal => fromDecimal decimal) reader stream
  val fromString = StringCvt.scanString scan

  end

  val op + = fn (left : real, right) => left + right

  val op - = fn (left : real, right) => left - right

  val op * = fn (left : real, right) => left * right

  val op / = fn (left : real, right) => left / right

  fun *+ (r1, r2, r3) = r1 * r2 + r3
  fun *- (r1, r2, r3) = r1 * r2 - r3

  fun ~ real = real * ~1.0

  fun unordered (left, right) = isNan left orelse isNan right

  fun compare (left : real, right) =
      if unordered (left, right)
      then raise IR.Unordered
      else 
        if left < right
        then General.LESS
        else if right < left then General.GREATER else General.EQUAL

  fun compareReal (left, right) = 
      (case compare (left, right) of
         General.LESS => IR.LESS
       | General.EQUAL => IR.EQUAL
       | General.GREATER => IR.GREATER)
      handle IR.Unordered => IR.UNORDERED

  fun op < (left : real, right : real) =
      case compare (left, right) of General.LESS => true | _ => false
  fun op <= (left : real, right : real) =
      case compare (left, right) of General.GREATER => false | _ => true
  val op > = not o (op <=)
  val op >= = not o (op <)

  (***************************************************************************)

end;
