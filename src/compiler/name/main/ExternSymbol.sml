(**
 * external symbols
 *
 * @copyright (c) 2012, Tohoku University.
 * @author UENO Katsuhiro
 *)
structure ExternSymbol :> sig

  type id
  val touch : string list -> id
  val toString : id -> string  
  val format_id : id -> SMLFormat.FormatExpression.expression list
  structure Map : ORD_MAP where type Key.ord_key = id
  structure Set : ORD_SET where type item = id

end =
struct

  type id = string

  fun touch path =
      NameMangle.mangle path

  fun toString x = x : id

  fun format_id id =
      let
        val s = toString id
      in
        [SMLFormat.FormatExpression.Term (size s, s)]
      end

  structure Map = SEnv
  structure Set = SSet

end
