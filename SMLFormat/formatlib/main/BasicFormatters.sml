(**
 *  This module provides formatters for the standard types.
 *
 *  When you add a new formatter in this structure, it is required to update
 * the "../generator/BasicFormattersEnv.sml" to register the name of the new
 * formatter to the formatters environment.
 *
 * @author YAMATODANI Kiyoshi
 * @copyright 2010, Tohoku University.
 * @version $Id: BasicFormatters.sml,v 1.3 2008/02/28 13:08:30 kiyoshiy Exp $
 *)
structure BasicFormatters : BASIC_FORMATTERS =
struct

  (***************************************************************************)

  structure FE = FormatExpression

  type expression = FE.expression

  type 'a formatter = 'a -> expression list

  (***************************************************************************)

  fun format_unit () = [FE.Term (2, "()")]

  fun format_int int =
      let val text = Int.toString int
      in [FE.Term (size text, text)] end

  fun format_word word =
      let val text = "0x" ^ Word.toString word
      in [FE.Term (size text, text)] end

  fun format_real real =
      let val text = Real.toString real
      in [FE.Term (size text, text)] end

  fun format_char char =
      let val text = Char.toString char
      in [FE.Term (size text, text)] end

  fun format_string string = [FE.Term (size string, string)]

  fun format_substring substring =
      [FE.Term (Substring.size substring, Substring.string substring)]

  val format_exn_Ref =
      ref
      (fn exn => 
          let val text = General.exnMessage exn
          in [FE.Term (size text, text)] end)

  fun format_exn exn = !format_exn_Ref exn

  fun format_array (elementFormatter, separator) array =
      (* This function can be implemented by using Array.foldri.
       * But, the signature of Array.fordri differs depending on Basis version.
       * In order to compile both on SML/NJ and on SML#, we do not use
       * Array.foldri.
       * For the same reason, the format_vector is implemented without using
       * Vector.foldri.
       *)
      let
        fun scan index expressions =
            let val expression = elementFormatter (Array.sub (array, index))
            in
              if 0 = index
              then expression @ expressions
              else scan (index - 1) (separator @ expression @ expressions)
            end
      in
        case Array.length array of
          0 => []
        | arraySize => scan (arraySize - 1) []
      end
(*
      Array.foldri
      (fn (index, element, expressions) =>
          let val expression = elementFormatter element
          in
            if 0 = index
            then expression @ expressions
            else separator @ expression @ expressions
          end)
      []
      (array, 0, NONE)
*)

  fun format_vector (elementFormatter, separator) vector =
      let
        fun scan index expressions =
            let val expression = elementFormatter (Vector.sub (vector, index))
            in
              if 0 = index
              then expression @ expressions
              else scan (index - 1) (separator @ expression @ expressions)
            end
      in
        case Vector.length vector of
          0 => []
        | vectorSize => scan (vectorSize - 1) []
      end
(*
      Vector.foldri
      (fn (index, element, expressions) =>
          let val expression = elementFormatter element
          in
            if 0 = index
            then expression @ expressions
            else separator @ expression @ expressions
          end)
      []
      (vector, 0, NONE)
*)

  fun format_ref elementFormatter (ref value) =
      elementFormatter value

  fun format_bool bool =
      let val text = Bool.toString bool
      in [FE.Term (size text, text)] end

  fun format_option elementFormatter value =
      case value of
        Option.NONE => [FE.Term (0, "")]
      | Option.SOME value => elementFormatter value

  fun format_order order =
      case order of
        General.LESS => [FE.Term (4, "LESS")]
      | General.EQUAL => [FE.Term (5, "EQUAL")]
      | General.GREATER => [FE.Term (7, "GREATER")]

  fun format_list (elementFormatter, separator) [] = []
    | format_list (elementFormatter, separator) values =
      let
        fun format [] = []
          | format [value] = elementFormatter value
          | format (head::tail) =
            (elementFormatter head) @ separator @ (format tail)
      in
        format values
      end

  (***************************************************************************)

end