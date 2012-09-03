(**
 * implementation of primitives for Math structure.
 * @copyright (c) 2006, Tohoku University.
 * @author YAMATODANI Kiyoshi
 * @version $Id: MathPrimitives.sml,v 1.4 2006/02/28 16:11:12 kiyoshiy Exp $
 *)
structure MathPrimitives : PRIMITIVE_IMPLEMENTATIONS =
struct

  (***************************************************************************)

  open RuntimeTypes
  open BasicTypes
  structure RE = RuntimeErrors
  structure SLD = SourceLanguageDatatypes
  structure H = Heap

  (***************************************************************************)

  (* val sqrt : real -> real *)
  fun Math_sqrt VM heap [Real realValue, Word 0w0] =
      [Real(Math.sqrt(realValue)), Word 0w0]
    | Math_sqrt _ _ _ = 
      raise RE.UnexpectedPrimitiveArguments "Math_sqrt"

  (* val sin : real -> real *)
  fun Math_sin VM heap [Real realValue, Word 0w0] =
      [Real(Math.sin(realValue)), Word 0w0]
    | Math_sin _ _ _ = 
      raise RE.UnexpectedPrimitiveArguments "Math_sin"

  (* val cos : real -> real *)
  fun Math_cos VM heap [Real realValue, Word 0w0] =
      [Real(Math.cos(realValue)), Word 0w0]
    | Math_cos _ _ _ = 
      raise RE.UnexpectedPrimitiveArguments "Math_cos"

  (* val tan : real -> real *)
  fun Math_tan VM heap [Real realValue, Word 0w0] =
      [Real(Math.tan(realValue)), Word 0w0]
    | Math_tan _ _ _ = 
      raise RE.UnexpectedPrimitiveArguments "Math_tan"

  (* val asin : real -> real *)
  fun Math_asin VM heap [Real realValue, Word 0w0] =
      [Real(Math.asin(realValue)), Word 0w0]
    | Math_asin _ _ _ = 
      raise RE.UnexpectedPrimitiveArguments "Math_asin"

  (* val acos : real -> real *)
  fun Math_acos VM heap [Real realValue, Word 0w0] =
      [Real(Math.acos(realValue)), Word 0w0]
    | Math_acos _ _ _ = 
      raise RE.UnexpectedPrimitiveArguments "Math_acos"

  (* val atan : real -> real *)
  fun Math_atan VM heap [Real realValue, Word 0w0] =
      [Real(Math.atan(realValue)), Word 0w0]
    | Math_atan _ _ _ = 
      raise RE.UnexpectedPrimitiveArguments "Math_atan"

  (* val atan2 : real * real -> real *)
  fun Math_atan2
          VM heap [Real realValue1, Word 0w0, Real realValue2, Word 0w0] =
      [Real(Math.atan2(realValue1, realValue2)), Word 0w0]
    | Math_atan2 _ _ _ = 
      raise RE.UnexpectedPrimitiveArguments "Math_atan2"

  (* val exp : real -> real *)
  fun Math_exp VM heap [Real realValue, Word 0w0] =
      [Real(Math.exp(realValue)), Word 0w0]
    | Math_exp _ _ _ = 
      raise RE.UnexpectedPrimitiveArguments "Math_exp"

  (* val pow : real * real -> real *)
  fun Math_pow VM heap [Real realValue1, Word 0w0, Real realValue2, Word 0w0] =
      [Real(Math.pow(realValue1, realValue2)), Word 0w0]
    | Math_pow _ _ _ = 
      raise RE.UnexpectedPrimitiveArguments "Math_pow"

  (* val ln : real -> real *)
  fun Math_ln VM heap [Real realValue, Word 0w0] =
      [Real(Math.ln(realValue)), Word 0w0]
    | Math_ln _ _ _ = 
      raise RE.UnexpectedPrimitiveArguments "Math_ln"

  (* val log10 : real -> real *)
  fun Math_log10 VM heap [Real realValue, Word 0w0] =
      [Real(Math.log10(realValue)), Word 0w0]
    | Math_log10 _ _ _ = 
      raise RE.UnexpectedPrimitiveArguments "Math_log10"

  (* val sinh : real -> real *)
  fun Math_sinh VM heap [Real realValue, Word 0w0] =
      [Real(Math.sinh(realValue)), Word 0w0]
    | Math_sinh _ _ _ = 
      raise RE.UnexpectedPrimitiveArguments "Math_sinh"

  (* val cosh : real -> real *)
  fun Math_cosh VM heap [Real realValue, Word 0w0] =
      [Real(Math.cosh(realValue)), Word 0w0]
    | Math_cosh _ _ _ = 
      raise RE.UnexpectedPrimitiveArguments "Math_cosh"

  (* val tanh : real -> real *)
  fun Math_tanh VM heap [Real realValue, Word 0w0] =
      [Real(Math.tanh(realValue)), Word 0w0]
    | Math_tanh _ _ _ = 
      raise RE.UnexpectedPrimitiveArguments "Math_tanh"

  val primitives =
      [
        {name = "Math_sqrt", function = Math_sqrt},
        {name = "Math_sin", function = Math_sin},
        {name = "Math_cos", function = Math_cos},
        {name = "Math_tan", function = Math_tan},
        {name = "Math_asin", function = Math_asin},
        {name = "Math_acos", function = Math_acos},
        {name = "Math_atan", function = Math_atan},
        {name = "Math_atan2", function = Math_atan2},
        {name = "Math_exp", function = Math_exp},
        {name = "Math_pow", function = Math_pow},
        {name = "Math_ln", function = Math_ln},
        {name = "Math_log10", function = Math_log10},
        {name = "Math_sinh", function = Math_sinh},
        {name = "Math_cosh", function = Math_cosh},
        {name = "Math_tanh", function = Math_tanh}
      ]

  (***************************************************************************)

end;
