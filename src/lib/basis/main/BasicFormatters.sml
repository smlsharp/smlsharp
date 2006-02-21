
fun format_int arg = Int_toString arg;

fun format_word arg = "0wx" ^ (Word_toString arg);

fun format_real arg = Real_toString arg;

fun format_bool arg = case arg of true => "true" | false => "false";

local
fun escape #"\a" = "\\a"
  | escape #"\b" = "\\b"
  | escape #"\t" = "\\t"
  | escape #"\n" = "\\n"
  | escape #"\v" = "\\v"
  | escape #"\f" = "\\f"
  | escape #"\r" = "\\r"
  | escape #"\\" = "\\\\"
  | escape #"\"" = "\\\""
  | escape c = Char_toEscapedString c
in
fun format_string arg = 
    "\"" ^
    (foldr (fn (left, right) => left ^ right) "" (map escape (explode arg))) ^
    "\"";
end

(* Bug ? "#\"" is rejected by lexer. *)
fun format_char arg = "#" ^ "\"" ^ (Char_toEscapedString arg) ^ "\"";

(* This formatter does not stop if arg contains cyclic data structure.
 * When module mechanism is supported in future version of compiler,
 * this formatter should be rewritten as described in the message 
 * <20041004161448.85390.qmail@web10103.mail.yahoo.co.jp>
 *)
fun format_ref (format_arg : 'a -> string) (ref (arg : 'a)) =
    "ref " ^ (format_arg arg);

val format_exnRef =
    ref
        ((fn Match => "Match"
           | Bind => "Bind"
           | MatchCompBug message => "MatchCompBug:" ^ message
           | Formatter message => "Formatter:" ^ message
           | SysErr(message, syserrOpt) => "SysErr:" ^ message
           | exn => "BUG:Unknown exception.") : exn -> string);

fun format_exn exn = case format_exnRef of ref format => format exn;

fun format_list format_element list =
    let
      fun format [] = ""
        | format [last] = format_element last
        | format (head :: tail) =
          (format_element head) ^ "," ^ (format tail)
    in "[" ^ format list ^ "]" end;

fun format_array (format_arg : 'a -> string) (arg : 'a array) = "array"

fun format_byteArray (arg : byteArray) = "byteArray"

fun format_byte (arg : byte) =
    "0wx" ^ (Word_toString ((_cast (arg)) : word));

fun format_option format_element NONE = "NONE"
  | format_option format_element (SOME arg) = "SOME " ^ (format_element arg);
