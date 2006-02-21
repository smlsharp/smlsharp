(*
(**
 * Copyright (c) 2006, Tohoku University.
 *
 * Minimum preludes.
 * Only top level bindings specified by SML Basis Manual are defined.
 * @author YAMATODANI Kiyoshi
 * @version $Id: preludes.sml,v 1.31 2006/02/18 04:59:39 ohori Exp $
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

fun map f [] = []
  | map f (hd :: tl) = (f hd) :: (map f tl);

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

fun rev list =
    let
      fun accum [] result = result
        | accum (head :: tail) result = accum tail (head :: result)
    in accum list [] end;

fun append (left, right) =
    let
      fun accum [] result = result
        | accum (head :: tail) result = accum tail (head :: result)
    in accum (rev left) right end;

val (op @) = append;

(*****************************************************************************)
(* string operators *)

val sub = subString

val size = sizeString

fun explode string =
    let
      fun accum 0 chars = chars
        | accum n chars = accum (n - 1) (sub (string, n - 1) :: chars)
    in accum (size string) [] end;

fun implode [] = ""
  | implode (char :: chars) = (charToString char) ^ (implode chars);

(*****************************************************************************)
(* formatters *)

fun format_int arg = intToString arg;

fun format_word arg = "0wx" ^ (wordToString arg);

fun format_real arg = realToString arg;

fun format_bool arg = case arg of true => "true" | false => "false";

local
fun escape #"\a" = "\\a"
  | escape #"\b" = "\\b"
  | escape #"\t" = "\\t"
  | escape #"\n" = "\\n"
  | escape #"\v" = "\\v"
  | escape #"\f" = "\\f"
  | escape #"\r" = "\\r"
  | escape c = charToString c
in
fun format_string arg = 
    "\"" ^
    (foldr (fn (left, right) => left ^ right) "" (map escape (explode arg))) ^
    "\"";
end

(* Bug ? "#\"" is rejected by lexer. *)
fun format_char arg = "#" ^ "\"" ^ (charToString arg) ^ "\"";

(* This formatter does not stop if arg contains cyclic data structure.
 * When module mechanism is supported in future version of compiler,
 * this formatter should be rewritten as described in the message 
 * <20041004161448.85390.qmail@web10103.mail.yahoo.co.jp>
 *)
fun format_ref (format_arg : 'a -> string) (ref (arg : 'a)) =
    "ref " ^ (format_arg arg);

val format_exnRef =
    ref
        ((fn Match => "nonexhaustive match failure"
           | Bind => "nonexhaustive binding failure"
           | exn => "BUG:Unknown exception.") : exn -> string);

fun format_exn exn = case format_exnRef of ref format => format exn;

fun format_list format_element list =
    let
      fun format [] = ""
        | format [last] = format_element last
        | format (head :: tail) =
          (format_element head) ^ "," ^ (format tail)
    in "[" ^ format list ^ "]" end;

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


*)
