(**
 * encode ML paths to C symbols.
 * @copyright (c) 2011, Tohoku University.
 * @author UENO Katsuhiro
 *)
structure NameMangle : sig

  val mangle : string list -> string

end =
struct

  (* It is not a good idea to use ML longids as link symbols as it is
   * because of the following reasons:
   * - ML longid may contain symbol characters which C linker may not
   *   accept.
   * - An ML name may conflict with a name defined in C.
   * This module generates symbol string corresponging to given ML longids
   * by encoding ML-specific information to ASCII character strings.
   * (In C++, this process is called as "name mangling.")
   *)

  (*
   * Digits and alphabets are passed through.
   * Symbol characters (including '_') are escaped as '_' followed by
   * corresponding character of the following table.
   * from: ! " # $ % & ' ( ) * + , - . / : ; < = > ? @ [ \ ] ^ _ ` { | } ~
   *   to: A B C D E F G H I J K L M N O P Q R S T U V W X Y Z _ a b c d e
   *
   * 8 bit characters are escaped as '_x' followed by two upper-case
   * hexiadecimal digits.
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
      then "_" ^ str (chr (ord c - ord #"{" + ord #"b"))
      else if ord c >= 128 andalso ord c <= 255
      then "_x" ^ Int.fmt StringCvt.HEX (ord c)
      else raise Fail ("PathToSymbol.escape: " ^ str c)

  fun escape s =
      String.translate escapeChar s

  fun mangle nil = raise Bug.Bug "NameMangle.mangle"
    | mangle path =
      let
        val path = map (fn s => Int.toString (size s) ^ escape s) path
        val name = String.concat path
      in
        if length path >= 2 then "N" ^ name ^ "E" else name
      end

end
