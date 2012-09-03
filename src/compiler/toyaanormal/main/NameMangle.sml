(**
 * encode ML paths to C symbols.
 * @copyright (c) 2011, Tohoku University.
 * @author UENO Katsuhiro
 *)
structure NameMangle : sig

  val mangle : ClosureANormal.exVarInfo -> string

end =
struct

  (* It is not a good idea to use ML longids as it is as link symbols
   * due to the following reasons:
   * - ML longid may contain special characters which C linker may not
   *   accept.
   * - Since the namespace of ML and C are not separated, if user define
   *   a function whose name is already defined in a C library (e.g.
   *   printf), linking of such ML program wil fail.
   *
   * To avoid the above problem, this module encodes ML longids to
   * strings which only includes alphabets, digits, and "_".
   * (In C++, this process is called as "name mangling.")
   *)

  (*
   * from: ! " # $ % & ' ( ) * + , - . / : ; < = > ? @ [ \ ] ^ _ ` { | } ~
   *   to: A B C D E F G H I J K L M N O P Q R S T U V W X Y Z _ a b c d e
   *)
  fun escapeChar c =
      if Char.isAlphaNum c then str c
      else if #"!" <= c andalso c <= #"/"
      then "_" ^ str (chr (ord c - ord #"!" + ord #"A"))
      else if #":" <= c andalso c <= #"@"
      then "_" ^ str (chr (ord c - ord #":" + ord #"P"))
      else if #"[" <= c andalso c <= #"^"
      then "_" ^ str (chr (ord c - ord #"[" + ord #"W"))
      else if c = #"_"
      then "__"
      else if c = #"`"
      then "_a"
      else if #"{" <= c andalso c <= #"~"
      then "_" ^ str (chr (ord #"{" + ord #"b"))
      else raise Fail ("PathToSymbol.escape: " ^ str c)

  fun escape s =
      String.translate escapeChar s

  fun manglePath nil = raise Control.Bug "PathToSymbol.manglePath"
    | manglePath path =
      let
        val path = map (fn s => Int.toString (size s) ^ escape s) path
        val name = String.concat path
      in
        if length path >= 2 then "N" ^ name ^ "E" else name
      end

  fun mangle ({path, ty}:ClosureANormal.exVarInfo) =
      "SML" ^ manglePath path
      handle exn => raise exn

end
