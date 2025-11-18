(**
 * encode ML paths to C symbols.
 * @copyright (C) 2021 SML# Development Team.
 * @author UENO Katsuhiro
 *)
structure NameMangle =
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

  fun mangle (path, last) =
      let
        val path = map (fn s => Int.toString (size s) ^ escape s) path
        val last = Int.toString (size last) ^ escape last
        val name = String.concat path ^ last
      in
        case path of
          nil => name
        | _ :: _ => "N" ^ name ^ "E"
      end

end
