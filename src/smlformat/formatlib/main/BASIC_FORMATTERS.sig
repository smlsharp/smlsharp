(**
 *  This signature provides the specifications of formatters for the standard
 * types.
 *
 *  When you add a new formatter in this signature, it is required to update
 * the "../generator/BasicFormattersEnv.sml" to register the name of the new
 * formatter to the formatters environment.
 *
 * @author YAMATODANI Kiyoshi
 * @copyright 2010, Tohoku University.
 * @version $Id: BASIC_FORMATTERS.sig,v 1.1 2006/02/07 12:51:51 kiyoshiy Exp $
 *)
signature BASIC_FORMATTERS =
sig

  (***************************************************************************)

  (** format expression *)
  type expression

  (**
   *  formatter for a type T receives a value of the type T and returns
   * a list of format expressions of the string representation of the value.
   *)
  type 'a formatter = 'a -> expression list

  (***************************************************************************)

  (** the formatter for unit type. *)
  val format_unit : General.unit formatter

  (** the formatter for int type. *)
  val format_int : Int.int formatter

  (** the formatter for word type. *)
  val format_word : Word.word formatter

  (** the formatter for real type. *)
  val format_real : Real.real formatter

  (** the formatter for char type. *)
  val format_char : Char.char formatter

  (** the formatter for string type. *)
  val format_string : String.string formatter

  (** the formatter for substring type. *)
  val format_substring : Substring.substring formatter

  (** the formatter for exn type. *)
  val format_exn : General.exn formatter

  val format_exn_Ref : General.exn formatter ref

  (** the formatter for array type. *)
  val format_array :
      ('a formatter * expression list) -> 'a Array.array formatter

  (** the formatter for vector type. *)
  val format_vector :
      ('a formatter * expression list) -> 'a Vector.vector formatter

  (** the formatter for ref type. *)
  val format_ref : 'a formatter -> 'a ref formatter

  (** the formatter for bool type. *)
  val format_bool : bool formatter

  (** the formatter for option type. *)
  val format_option : 'a formatter -> 'a Option.option formatter

  (** the formatter for order type. *)
  val format_order : General.order formatter

  (** the formatter for list type. *)
  val format_list : ('a formatter * expression list) -> 'a list formatter

  (***************************************************************************)

end