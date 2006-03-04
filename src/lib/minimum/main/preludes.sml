(**
 * Minimum preludes.
 * Only top level bindings specified by SML Basis Manual are defined.
 * @author YAMATODANI Kiyoshi
 * @version $Id: preludes.sml,v 1.1 2006/02/24 14:14:26 kiyoshiy Exp $
 *)
(*****************************************************************************)

(* infixes specified in the SML Definition are hard-coded in staticevn.sml *)
infix 6 ^;
infixr 5 @;
infix 4 <>;
infix 3 o;
infix 0 before;

(*****************************************************************************)

(*
datatype 'a list = nil | :: of 'a * 'a list;
*)

(*****************************************************************************)
(* list operators *)

fun rev list =
    let
      fun accum [] result = result
        | accum (head :: tail) result = accum tail (head :: result)
    in accum list [] end;

fun map f list =
    let
      fun accum [] result = rev result
        | accum (hd :: tl) result = accum tl ((f hd) :: result)
    in
      accum list []
    end

fun foldl f initial list =
    let
      fun accum [] result = result
        | accum (hd :: tl) result = accum tl (f (hd, result))
    in accum list initial end;

fun foldr f initial list =
    let
      fun accum [] result  = result
        | accum (hd :: tl) result = f (hd, accum tl result)
    in accum list initial end;

fun append (left, right) =
    let
      fun accum [] result = result
        | accum (head :: tail) result = accum tail (head :: result)
    in accum (rev left) right end;

val (op @) = append;

(*****************************************************************************)
(* string operators *)

val sub = String_sub

val size = String_size

val op ^ = String_concat2

fun explode string =
    let
      fun accum 0 chars = chars
        | accum n chars = accum (n - 1) (sub (string, n - 1) :: chars)
    in accum (size string) [] end;

fun implode [] = ""
  | implode (char :: chars) = (Char_toString char) ^ (implode chars);

(*****************************************************************************)
(* formatters *)

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
    "0wx" ^ (Word_toString (_cast (arg) : word));

(*****************************************************************************)

exception Fail of string;

fun negInt number = subInt(0, number)

fun not true = false
  | not fasle = true;

fun left <> right = not (left = right);

fun ! (ref arg) = arg;

fun f o g = fn x => f(g x);

fun result before discard = result;

(*****************************************************************************)

datatype 'a option = NONE
                   | SOME of 'a;
exception Option;

fun getOpt (SOME v, _) = v
  | getOpt (NONE, v) = v;

fun valOf (SOME v) = v
  | valOf NONE = raise Option;

fun isSome (SOME _) = true | isSome NONE = false;

(*****************************************************************************)

(* for FFI *)

type void = int;

(*****************************************************************************)

