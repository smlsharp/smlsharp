(*
 * @author YAMATODANI Kiyoshi
 * @copyright 2010, Tohoku University.
 *)

structure IEEEReal =
struct

  open IEEEReal

  structure Old =
  struct
    datatype nan_mode = datatype nan_mode
    datatype float_class = datatype float_class
    type decimal_approx = decimal_approx
  end

  datatype float_class
         = NAN
         | INF
         | ZERO
         | NORMAL
         | SUBNORMAL

  type decimal_approx = {
                          class : float_class,
                          sign : bool,
                          digits : int list,
                          exp : int
                        }

  fun toNewClass (Old.NAN _) = NAN
    | toNewClass Old.INF = INF
    | toNewClass Old.ZERO = ZERO
    | toNewClass Old.NORMAL = NORMAL
    | toNewClass Old.SUBNORMAL = SUBNORMAL
  fun toNewDecimalApprox ({kind, sign, digits, exp} : Old.decimal_approx) =
      {class = toNewClass kind, sign = sign, digits = digits, exp = exp}
      : decimal_approx

  fun fromNewClass NAN = Old.NAN Old.QUIET
    | fromNewClass INF = Old.INF
    | fromNewClass ZERO = Old.ZERO
    | fromNewClass NORMAL = Old.NORMAL
    | fromNewClass SUBNORMAL = Old.SUBNORMAL
  fun fromNewDecimalApprox ({class, sign, digits, exp} : decimal_approx) =
      {kind = fromNewClass class, sign = sign, digits = digits, exp = exp}
      : Old.decimal_approx

  local
    fun convertReader conv (reader : ('result, 'stream) StringCvt.reader) =
        let
          fun reader' stream =
              case reader stream
               of SOME (result, stream') => SOME(conv result, stream')
                | NONE => NONE
        in
          reader' : ('newresult, 'stream) StringCvt.reader
        end
  in

  val toString = toString o fromNewDecimalApprox
  
  val scan = (convertReader toNewDecimalApprox) o scan

  val fromString = Option.map toNewDecimalApprox o fromString

  end

end;

structure Real =
struct
  open Real

  val class = IEEEReal.toNewClass o class

  val toDecimal = IEEEReal.toNewDecimalApprox o toDecimal

  val fromDecimal = SOME o fromDecimal o IEEEReal.fromNewDecimalApprox

end;

structure String =
struct
  open String

  fun concatWith separator strings =
      raise Fail "concatWith is not implemented."

  fun scan reader = raise Fail "scan is not implemented."

end;