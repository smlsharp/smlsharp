(**
 * RealClass
 * @author UENO Katsuhiro
 * @author Atsushi Ohori
 * @copyright 2010, 2011, 2012, 2013, Tohoku University.
 *)

infix 4 = <> > >= < <=
val op < = SMLSharp_Builtin.Int.lt
val op > = SMLSharp_Builtin.Int.gt
val op <= = SMLSharp_Builtin.Int.lteq
val op >= = SMLSharp_Builtin.Int.gteq

structure SMLSharp_RealClass =
struct

  (*
   * Following constants are defined in nativeruntime/prim.c.
   *
   * #define IEEEREAL_CLASS_SNAN     1   /* signaling NaN */
   * #define IEEEREAL_CLASS_QNAN     2   /* quiet NaN */
   * #define IEEEREAL_CLASS_INF      3   /* infinity */
   * #define IEEEREAL_CLASS_DENORM   4   /* denormal */
   * #define IEEEREAL_CLASS_ZERO     5   /* zero */
   * #define IEEEREAL_CLASS_NORM     6   /* normal */
   * #define IEEEREAL_CLASS_UNKNOWN  0
   *
   * sign of class integer means sign bit information.
   *)

  type class = int
                 
  val classReal =
      _import "prim_Real_class"
      : __attribute__((pure,no_callback)) real -> class

  val classFloat =
      _import "prim_Float_class"
      : __attribute__((pure,no_callback)) SMLSharp_Builtin.Real32.real -> class
                                                                    
  (* 2014-01-25 以下がruntime/prim.cの実際の定義
    #define IEEEREAL_CLASS_SNAN     1   /* signaling NaN */
    #define IEEEREAL_CLASS_QNAN     2   /* quiet NaN */
    #define IEEEREAL_CLASS_INF      3   /* infinity */
    #define IEEEREAL_CLASS_ZERO     4   /* zero */
    #define IEEEREAL_CLASS_DENORM   5   /* denormal */
    #define IEEEREAL_CLASS_NORM     6   /* normal */
    #define IEEEREAL_CLASS_UNKNOWN  0
  *)
  fun class c =
      case SMLSharp_Builtin.Int.abs c of
        1 => IEEEReal.NAN
      | 2 => IEEEReal.NAN
      | 3 => IEEEReal.INF
      | 4 => IEEEReal.ZERO
      | 5 => IEEEReal.SUBNORMAL
      | 6 => IEEEReal.NORMAL
      | _ => raise SMLSharp_Runtime.Bug "BUG: RealClass.toIEEERealClass"

(* 2014-01-25. 以下，脆弱につき，書き直し．
  fun isFinite class =
      class >= 4 orelse class <= ~4   (* denormal, zero, or normal *)

  fun isInf class =
      class = 3 orelse class = ~3     (* infinity *)

  fun isNan class =
      ~2 <= class andalso class <= 2   (* SNaN or QNaN *)

  fun isNormal class =
      class = 6 orelse class = ~6     (* isNormal *)

  fun sign class =
      if isNan class then raise Domain
      else if class = 5 then 0        (* zero *)
      else if class < 0 then ~1 else 1
*)
  fun isFinite c =
      case class c of
        IEEEReal.NAN => false
      | IEEEReal.INF => false
      | IEEEReal.ZERO => true
      | IEEEReal.SUBNORMAL => true
      | IEEEReal.NORMAL => true

  fun isInf c =
      case class c of
        IEEEReal.INF => true
      | _ => false

  fun isNan c =
      case class c of
        IEEEReal.NAN => true
      | _ => false

  fun isNormal c =
      case class c of
        IEEEReal.NORMAL => true
      | _ => false

  fun isZero c =
      case class c of
        IEEEReal.ZERO => true
      | _ => false

  fun sign class =
      if isNan class then raise Domain
      else if isZero class then 0 
      else if class < 0 then ~1 else 1

  fun signBit class = class < 0

  fun toInt class = class
end
