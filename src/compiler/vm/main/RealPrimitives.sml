(**
 * implementation of primitives on real values.
 * @copyright (c) 2006, Tohoku University.
 * @author YAMATODANI Kiyoshi
 * @version $Id: RealPrimitives.sml,v 1.11.6.1 2007/03/22 16:57:42 katsu Exp $
 *)
structure RealPrimitives : PRIMITIVE_IMPLEMENTATIONS =
struct

  (***************************************************************************)

  open RuntimeTypes
  open BasicTypes
  structure RE = RuntimeErrors
  structure SLD = SourceLanguageDatatypes
  structure H = Heap

  (***************************************************************************)

  fun Real_toString VM heap [Real realValue, Word 0w0] =
      [SLD.stringToValue heap (Real64.toString realValue)]
    | Real_toString _ _ _ =
      raise RE.UnexpectedPrimitiveArguments "Real_toString"

  fun Real_fromInt VM heap [Int intValue] =
      [Real(SInt32ToReal64 intValue), Word 0w0]
    | Real_fromInt _ _ _ =
      raise RE.UnexpectedPrimitiveArguments "Real_fromInt"

  fun Real_floor VM heap [Real realValue, Word 0w0] =
      [Int(IntToSInt32(Real64.floor realValue))]
    | Real_floor _ _ _ =
      raise RE.UnexpectedPrimitiveArguments "Real_floor"

  fun Real_ceil VM heap [Real realValue, Word 0w0] =
      [Int(IntToSInt32(Real64.ceil realValue))]
    | Real_ceil _ _ _ =
      raise RE.UnexpectedPrimitiveArguments "Real_ceil"

  fun Real_trunc VM heap [Real realValue, Word 0w0] =
      [Int(IntToSInt32(Real64.trunc realValue))]
    | Real_trunc _ _ _ =
      raise RE.UnexpectedPrimitiveArguments "Real_trunc"

  fun Real_round VM heap [Real realValue, Word 0w0] =
      [Int(IntToSInt32(Real64.round realValue))]
    | Real_round _ _ _ =
      raise RE.UnexpectedPrimitiveArguments "Real_round"

  (* real -> real * real *)
  fun Real_split VM heap [Real realValue, Word 0w0] =
      let
        val {whole, frac} = Real.split realValue
        val elements = [Real whole, Word 0w0, Real frac, Word 0w0]
      in
        [SLD.tupleElementsToValue heap 0w0 elements]
      end
    | Real_split _ _ _ =
      raise RE.UnexpectedPrimitiveArguments "Real_split"

  (* real -> real * int *)
  fun Real_toManExp VM heap [Real realValue, Word 0w0] =
      let
        val {man, exp} = Real.toManExp realValue
        val elements = [Real man, Word 0w0, Int (IntToSInt32 exp)]
      in
        [SLD.tupleElementsToValue heap 0w0 elements]
      end
    | Real_toManExp _ _ _ =
      raise RE.UnexpectedPrimitiveArguments "Real_toManExp"

  (* real * int -> real *)
  fun Real_fromManExp VM heap [Real manValue, Word 0w0, Int expValue] =
      [
        Real(Real.fromManExp{man = manValue, exp = SInt32ToInt expValue}),
        Word 0w0
      ]
    | Real_fromManExp _ _ _ = 
      raise RE.UnexpectedPrimitiveArguments "Real_fromManExp"

  (* val copySign : real * real -> real *)
  fun Real_copySign
          VM heap [Real realValue1, Word 0w0, Real realValue2, Word 0w0] =
      [Real(Real.copySign(realValue1, realValue2)), Word 0w0]
    | Real_copySign _ _ _ = 
      raise RE.UnexpectedPrimitiveArguments "Real_copySign"

  (* val equal : real * real -> bool *)
  fun Real_equal
          VM heap [Real realValue1, Word 0w0, Real realValue2, Word 0w0] =
      let
        val isEqual = IEEEReal.EQUAL = Real.compareReal(realValue1, realValue2)
      in
        [SLD.boolToValue heap isEqual]
      end
    | Real_equal _ _ _ = 
      raise RE.UnexpectedPrimitiveArguments "Real_equal"

  (*
   * val class : real -> int
   * see Real.sml in Basis about the return value.
   *)
  fun Real_class VM heap [Real realValue, Word 0w0] =
      let
        val class =
            case (Real.class realValue, Real.signBit realValue) of
              (IEEEReal.NAN IEEEReal.SIGNALLING, _) => 0
            | (IEEEReal.NAN IEEEReal.QUIET, _) => 1
            | (IEEEReal.INF, true) => 2
            | (IEEEReal.INF, false) => 3
            | (IEEEReal.SUBNORMAL, true) => 4 
            | (IEEEReal.SUBNORMAL, false) => 5
            | (IEEEReal.ZERO, true) => 6
            | (IEEEReal.ZERO, false) => 7
            | (IEEEReal.NORMAL, true) => 8
            | (IEEEReal.NORMAL, false) => 9
      in
        [Int(IntToSInt32 class)]
      end
    | Real_class _ _ _ =
      raise RE.UnexpectedPrimitiveArguments "Real_class"

  (* val fromFloat : float -> real *)
  fun Real_fromFloat VM heap [Real floatValue] = [Real floatValue, Word 0w0]
    | Real_fromFloat _ _ _ = 
      raise RE.UnexpectedPrimitiveArguments "Real_fromFloat"

  (* val toFloat : float -> real *)
  fun Real_toFloat VM heap [Real realValue1, Word 0w0] = [Real realValue1]
    | Real_toFloat _ _ _ = 
      raise RE.UnexpectedPrimitiveArguments "Real_toFloat"

  val primitives =
      [
        {name = "Real_toString", function = Real_toString},
        {name = "Real_fromInt", function = Real_fromInt},
        {name = "Real_floor", function = Real_floor},
        {name = "Real_ceil", function = Real_ceil},
        {name = "Real_trunc", function = Real_trunc},
        {name = "Real_round", function = Real_round},
        {name = "Real_split", function = Real_split},
        {name = "Real_toManExp", function = Real_toManExp},
        {name = "Real_fromManExp", function = Real_fromManExp},
        {name = "Real_copySign", function = Real_copySign},
        {name = "Real_equal", function = Real_equal},
        {name = "Real_class", function = Real_class},
        {name = "Real_fromFloat", function = Real_fromFloat},
        {name = "Real_toFloat", function = Real_toFloat}
      ]

  (***************************************************************************)

end;
