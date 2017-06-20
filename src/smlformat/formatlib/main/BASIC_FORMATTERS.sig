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

  (** format *)
  type format

  (**
   *  formatter for a type T receives a value of the type T and returns
   *  a format of the value.
   *)
  type 'a formatter = 'a -> format

  (***************************************************************************)

  (** the formatter for unit type. *)
  val format_unit : unit -> format

  (** the formatter for int type. *)
  val format_int : int -> format

  (** the formatter for word type. *)
  val format_word : word -> format

  (** the formatter for real type. *)
  val format_real : real -> format

  (** the formatter for char type. *)
  val format_char : char -> format

  (** the formatter for string type. *)
  val format_string : string -> format

  (** the formatter for substring type. *)
  val format_substring : substring -> format

  (** the formatter for exn type. *)
  val format_exn : exn -> format

  val format_exn_Ref : (exn -> format) ref

  (** the formatter for array type. *)
  val format_array :
      ('a formatter * format) -> 'a array -> format

  (** the formatter for vector type. *)
  val format_vector :
      ('a formatter * format) -> 'a vector -> format

  (** the formatter for ref type. *)
  val format_ref : 'a formatter -> 'a ref -> format

  (** the formatter for bool type. *)
  val format_bool : bool -> format

  (** the formatter for option type. *)
  val format_option : 'a formatter -> 'a option -> format

  (** the formatter for order type. *)
  val format_order : order -> format

  (** the formatter for list type. *)
  val format_list : ('a formatter * format) -> 'a list -> format

  (***************************************************************************)

end
