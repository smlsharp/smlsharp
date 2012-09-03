(**
 *  This module provides a formatter environment consisting of entries for
 * basic types.
 *
 * @author YAMATODANI Kiyoshi
 * @copyright 2010, Tohoku University.
 * @version $Id: BasicFormattersEnv.sml,v 1.3 2006/02/07 12:49:33 kiyoshiy Exp $
 *)
structure BasicFormattersEnv =
struct

  (***************************************************************************)

  local
    structure FG = FormatterGenerator
  in

  (**
   * a formatter environment consisting of entries for basic types.
   * Registered in this environment are all types which are defined in
   * SMLBasis library and are specified to be available at top level.
   *)
  val basicFormattersEnv =
      let
        val basicFormattersStructureName = "SMLFormat.BasicFormatters"
        val entries =
            [
              ("unit", "format_unit"),
              ("General.unit", "format_unit"),
              ("int", "format_int"),
              ("Int.int", "format_int"),
              ("word", "format_word"),
              ("Word.word", "format_word"),
              ("real", "format_real"),
              ("Real.real", "format_real"),
              ("char", "format_char"),
              ("Char.char", "format_char"),
              ("string", "format_string"),
              ("String.string", "format_string"),
              ("substring", "format_substring"),
              ("Substring.substring", "format_substring"),
              ("exn", "format_exn"),
              ("General.exn", "format_exn"),
              ("array", "format_array"),
              ("Array.array", "format_array"),
              ("vector", "format_vector"),
              ("Vector.vector", "format_vector"),
              ("ref", "format_ref"),
              ("bool", "format_bool"),
              ("option", "format_option"),
              ("Option.option", "format_option"),
              ("order", "format_order"),
              ("General.order", "format_order"),
              ("list", "format_list"),
              ("List.list", "format_list")
            ]
      in
        foldr
        (fn ((tyConName, formatterName), F) =>
            let
              val formatterFQN =
                  basicFormattersStructureName ^ "." ^ formatterName
            in FG.addToFormatterEnv F (NONE, tyConName, formatterFQN) end)
        FG.initialFormatterEnv
        entries
      end
  end

  (***************************************************************************)

end