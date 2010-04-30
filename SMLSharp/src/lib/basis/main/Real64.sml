(**
 * Real64 structure.
 * @author YAMATODANI Kiyoshi
 * @version $Id: Real64.sml,v 1.6 2008/01/16 08:17:46 kiyoshiy Exp $
 *)
structure Real64 =
struct

  (***************************************************************************)

  type real = real

  (***************************************************************************)

  structure Math = Math
  structure IR = IEEEReal
  structure S = String
  structure SS = Substring

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
        case SMLSharp.Runtime.Real_class real of
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

  val copySign = SMLSharp.Runtime.Real_copySign
  end

  local
    val equal = Real.==
  in
  fun == (left, right) =
      if isNan left orelse isNan right
      then false
      else equal (left, right)
  val != = not o op == 

  fun ?= (left, right) =
      if isNan left orelse isNan right
      then true
      else equal (left, right)
  end

  fun toManExp real =
      let val (man, exp) = SMLSharp.Runtime.Real_toManExp real
      in {man = man, exp = exp}
      end

  fun fromManExp {man, exp} = SMLSharp.Runtime.Real_fromManExp (man, exp)

  fun split real =
      let val (whole, frac) = SMLSharp.Runtime.Real_split real
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
      if isNan real then raise Domain else
      case mode of
        IR.TO_NEGINF => SMLSharp.Runtime.Real_floor real
      | IR.TO_POSINF => SMLSharp.Runtime.Real_ceil real
      | IR.TO_ZERO => Real.trunc_unsafe real
      | IR.TO_NEAREST => SMLSharp.Runtime.Real_round real

  fun toLargeInt mode real = Int.toLarge(toInt mode real)

  val fromInt = Real.fromInt
  val fromLargeInt = Real.fromInt o Int.fromLarge

(*
  val toFloat = Real_toFloat
  val fromFloat = Real_fromFloat
*)

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

    fun numOfChar char =
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
        | _ => raise Fail "bug: Real.numOfChar"

  in

  fun toDecimal r =
      let
        val class = class r
        val sign = signBit r
        val isNormal =
            case class
             of IEEEReal.NORMAL => true
              | IEEEReal.SUBNORMAL => true
              | _ => false
      in
        if isNormal
        then
          let
            val (str, exp) = SMLSharp.Runtime.Real_dtoa (abs r, 0)
            val chars = String.explode str
            val digits = List.map numOfChar chars
          in
            {kind = class, sign = sign, digits = digits, exp = exp}
          end
        else {kind = class, sign = sign, digits = [], exp = 0}
      end

  (* sign * 0.d[1]d[2]...d[n] * 10 ^ exp *)
  fun fromDecimal ({kind, sign, digits, exp} : IR.decimal_approx) =
      case kind of
        IR.NAN _ => SOME nan
      | IR.INF => SOME(if sign then negInf else posInf)
      | IR.ZERO => SOME(if sign then ~1.0 * 0.0 else 0.0)
      | _ =>
        let
          val string =
              String.implode (#"0" :: #"." :: List.map charOfNum digits)
          val string = if sign then "~" ^ string else string
          val string = string ^ "E" ^ Int.toString exp
        in
          SOME (SMLSharp.Runtime.Real_strtod string)
        end

  local

    fun zeros num = (CharVector.tabulate (num, fn _ => #"0"))
    fun signToString real =
        (if ~1 = sign real then "~" else "")
        handle General.Domain => "" (* if real is nan. *)
    fun splitAt (string, i) =
        let val (l, r) = SS.splitAt (SS.full string, i)
        in (SS.string l, SS.string r)
        end

    (* convert to scientific representation.
     *  [~]?[0-9].[0-9]+?E[0-9]+
     *)
    fun fmtSCI zeroTrail maxFrac real =
        case class real
         of IEEEReal.NAN _ => "nan"
          | IEEEReal.INF => signToString real ^ "inf"
          | _ =>
            let
              val (string, exp) = SMLSharp.Runtime.Real_dtoa (real, maxFrac + 1)
              val i = if S.sub (string, 0) = #"~" then 1 else 0
              val (left, right) = splitAt (string, i + 1)
              val right =
                  if S.size right < maxFrac
                  then
                    if zeroTrail
                    then right ^ zeros (maxFrac - S.size right)
                    else right
                  else #1(splitAt (right, maxFrac))
              val expStr =
                  if class real = IEEEReal.ZERO
                  then "0"
                  else Int.toString (exp - 1)
            in
              (if 0 < S.size right then left ^ "." ^ right else left)
              ^ "E" ^ expStr
            end
              
    (* convert to fixed-point representation
     *  [~]?[0-9]+.[0-9]+?
     *)
    fun fmtFIX zeroTrail maxFrac real =
        case class real
         of IEEEReal.NAN _ => "nan"
          | IEEEReal.INF => signToString real ^ "inf"
          | _ =>
            let
              val exp = ceil (Math.log10 (abs real))
              val (string, exp) =
                  if exp + maxFrac <= 0
                  then ("0", 0)
                  else SMLSharp.Runtime.Real_dtoa (real, exp + maxFrac)
              val i = if S.sub (string, 0) = #"~" then 1 else 0
              val (sign, num) = splitAt (string, i)
              val (whole, frac) =
                  if 0 < exp
                  then
                    if exp < S.size num
                    then splitAt (num, exp)
                    else (num ^ zeros (exp - S.size num), "")
                  else ("0", zeros (~exp) ^ num)
              val frac =
                  if maxFrac = 0 orelse frac = ""
                  then ""
                  else
                    if zeroTrail
                    then S.concat [".", frac, zeros (maxFrac - S.size frac)]
                    else S.concat [".", frac]
            in
              S.concat [sign, whole, frac]
            end

    fun fmtEXACT real =
        case class real
         of IEEEReal.NAN _ => "nan"
          | IEEEReal.INF => signToString real ^ "inf"
          | _ =>
            let
              val (string, exp) = SMLSharp.Runtime.Real_dtoa (real, 0)
            in
              "0." ^ string ^ "E" ^ Int.toString exp
            end

  in
  fun fmt mode real =
      case (mode, class real) of
        (_, IEEEReal.INF) => signToString real ^ "inf"
      | (_, IEEEReal.NAN _) => signToString real ^ "nan"
      | (StringCvt.GEN maxDigitsOpt, _) =>
        let
          val maxDigits = getOpt (maxDigitsOpt, 12)
          val _ = if maxDigits < 1 then raise Size else ()
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
                then maxDigits - wholeNumDecimals
                else 0
          (* GEN is almostly same to FIX or SCI, but does not allow trailing
           * zeros. *)
          val fix = fmtFIX false prec real
          val sci = fmtSCI false (maxDigits - 1) real
        in
          if size fix <= size sci then fix else sci
        end
      | (StringCvt.SCI maxFracOpt, _) =>
        let val maxFrac = getOpt (maxFracOpt, 6)
        in
          if Int.<(maxFrac, 0)
          then raise General.Size
          else fmtSCI true maxFrac real
        end
      | (StringCvt.FIX maxFracOpt, _) =>
        let val maxFrac = getOpt (maxFracOpt, 6)
        in
          if Int.<(maxFrac, 0)
          then raise General.Size
          else fmtFIX true maxFrac real
        end
      | (StringCvt.EXACT, _) => fmtEXACT real
  end

  fun toString real = fmt (StringCvt.GEN NONE) real

  fun scan reader stream =
      PC.bind
          (
            IEEEReal.scan,
            fn digits =>
               case fromDecimal digits
                of SOME r => PC.result r
                 | NONE => PC.failure
          )
          reader stream
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
