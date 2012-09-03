signature REAL =
  sig
    type real
    structure Math : MATH
    val radix : int
    val precision : int
    val maxFinite : real
    val minPos : real
    val minNormalPos : real
    val posInf : real
    val negInf : real
    val + : real * real -> real
    val - : real * real -> real
    val * : real * real -> real
    val / : real * real -> real
    val *+ : real * real * real -> real
    val *- : real * real * real -> real
    val ~ : real -> real
    val abs : real -> real
    val min : real * real -> real
    val max : real * real -> real
    val sign : real -> int
    val signBit : real -> bool
    val sameSign : real * real -> bool
    val copySign : real * real -> real
    val compare : real * real -> order
    val compareReal : real * real -> IEEEReal.real_order
    val < : real * real -> bool
    val <= : real * real -> bool
    val > : real * real -> bool
    val >= : real * real -> bool
    val == : real * real -> bool
    val != : real * real -> bool
    val ?= : real * real -> bool
    val unordered : real * real -> bool
    val isFinite : real -> bool
    val isNan : real -> bool
    val isNormal : real -> bool
    val class : real -> IEEEReal.float_class
    val fmt : StringCvt.realfmt -> real -> string
    val toString : real -> string
    val fromString : string -> real option
    val scan : (char,'a) StringCvt.reader -> (real,'a) StringCvt.reader
    val toManExp : real -> {exp:int, man:real}
    val fromManExp : {exp:int, man:real} -> real
    val split : real -> {frac:real, whole:real}
    val realMod : real -> real
    val rem : real * real -> real
    val nextAfter : real * real -> real
    val checkFloat : real -> real
    val floor : real -> int
    val ceil : real -> int
    val trunc : real -> int
    val round : real -> int
    val realFloor : real -> real
    val realCeil : real -> real
    val realTrunc : real -> real
    val toInt : IEEEReal.rounding_mode -> real -> int
    val toLargeInt : IEEEReal.rounding_mode -> real -> Int32.int
    val fromInt : int -> real
    val fromLargeInt : Int32.int -> real
    val toLarge : real -> Orig_Real64.real
    val fromLarge : IEEEReal.rounding_mode -> Orig_Real64.real -> real
    val toDecimal : real -> IEEEReal.decimal_approx
    val fromDecimal : IEEEReal.decimal_approx -> real
    sharing type Math.real = real
  end
