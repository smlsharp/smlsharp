(*
 * wrapper for IEEEReal of SML/NJ for compatibility.
 * @copyright (c) 2010, Tohoku University.
 * @author UENO Katsuhiro
 *)
structure IEEEReal : sig

  exception Unordered
  datatype real_order = LESS | EQUAL | GREATER | UNORDERED
  datatype float_class = NAN | INF | ZERO | NORMAL | SUBNORMAL
  datatype rounding_mode = TO_NEAREST | TO_NEGINF | TO_POSINF | TO_ZERO
  val setRoundingMode : rounding_mode -> unit
  val getRoundingMode : unit -> rounding_mode
  type decimal_approx =
       {class : float_class,
        sign : bool,
        digits : int list,
        exp : int}
  val toString : decimal_approx -> string
  val scan : (char, 'a) StringCvt.reader
             -> (decimal_approx, 'a) StringCvt.reader
  val fromString : string -> decimal_approx option

end =
struct

  open IEEEReal

  structure O = struct
    datatype float_class = datatype float_class
  end

  datatype float_class = NAN | INF | ZERO | NORMAL | SUBNORMAL 

  type decimal_approx =
       {
         class : float_class,
         sign : bool,
         digits : int list,
         exp : int
       }

  fun toOldApprox {class, sign, digits, exp} =
      {kind = case class of
                NAN => O.NAN QUIET
              | INF => O.INF
              | ZERO => O.ZERO
              | NORMAL => O.NORMAL
              | SUBNORMAL => O.SUBNORMAL,
       sign = sign, digits = digits, exp = exp}

  fun toNewApprox {kind, sign, digits, exp} =
      {class = case kind of
                 O.NAN _ => NAN
               | O.INF => INF
               | O.ZERO => ZERO
               | O.NORMAL => NORMAL
               | O.SUBNORMAL => SUBNORMAL,
       sign = sign, digits = digits, exp = exp}

  val toString = fn approx => toString (toOldApprox approx)

  val scan =
      fn reader => fn src =>
         case scan reader src of
           NONE => NONE
         | SOME (approx, src) => SOME (toNewApprox approx, src)

  val fromString =
      fn src =>
         case fromString src of
           NONE => NONE
         | SOME approx => SOME (toNewApprox approx)

end
