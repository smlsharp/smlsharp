_interface "RealClass.smi"

  structure RealClass :> sig
    type class
    val classReal : real -> class
    val classFloat : SMLSharp.Real32.real -> class
    val class : class -> IEEEReal.float_class
    val isFinite : class -> bool
    val isInf : class -> bool
    val isNan : class -> bool
    val isNormal : class -> bool
    val sign : class -> int
    val signBit : class -> bool
  end =
  struct
  local
    infix 7 * / div mod
    infix 6 + -
    infixr 5 ::
    infix 4 = <> > >= < <=
    val op < = SMLSharp.Int.lt
    val op > = SMLSharp.Int.gt
    val op <= = SMLSharp.Int.lteq
    val op >= = SMLSharp.Int.gteq
  in

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
        : __attribute__((pure,no_callback)) SMLSharp.Real32.real -> class

    fun class c =
        case SMLSharp.Int.abs c of
          1 => IEEEReal.NAN
        | 2 => IEEEReal.NAN
        | 3 => IEEEReal.INF
        | 4 => IEEEReal.SUBNORMAL
        | 5 => IEEEReal.ZERO
        | 6 => IEEEReal.NORMAL
        | _ => raise Fail "BUG: RealClass.toIEEERealClass"
    fun isFinite class =
        class >= 4 orelse class <= ~4   (* denormal, zero, or normal *)
    fun isInf class =
        class = 3 orelse class = ~3     (* infinity *)
    fun isNan class =
        ~2 <= class andalso class < 2   (* SNaN or QNaN *)
    fun isNormal class =
        class = 6 orelse class = ~6     (* isNormal *)
    fun sign class =
        if isNan class then raise Domain
        else if class = 5 then 0        (* zero *)
        else if class < 0 then ~1 else 1
    fun signBit class = class < 0

  end
end
