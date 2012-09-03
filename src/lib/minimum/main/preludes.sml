(**
 * Minimum preludes.
 * Only top level bindings specified by SML Basis Manual are defined.
 * @author YAMATODANI Kiyoshi
 * @version $Id: preludes.sml,v 1.20 2007/06/19 22:19:12 ohori Exp $
 *)
(*****************************************************************************)

(* temporary printFormat.
 * Full version is defined after SMLFormat is loaded.
 *)
fun printFormat exp =
    let
      fun prList [] = ()
        | prList (e :: es) = 
          (pr e; prList es)
      and pr exp =
          case exp
           of Term(int, string) => print string
            | Guard(assocOpt, exps) => prList exps
            | Indicator{space, newline} => if space then print " " else ()
            | StartOfIndent int => ()
            | EndOfIndent => ()
    in
      pr exp
    end;

 local
  val s_Indicator = Indicator{space = true, newline = NONE}
  val s_1_Indicator =
      Indicator {space = true, newline = SOME{priority = Preferred 1}}
in
fun printFormatOfValBinding (name, valExp, tyExp) =
    printFormat
        (Guard
             (
               NONE,
               [
                 Term(3, "val"),
                 s_Indicator,
                 Guard
                     (
                       NONE,
                       [
                         Term(String_size name, name),
                         s_Indicator,
                         Term(1, "="),
                         s_1_Indicator,
                         valExp,
                         s_1_Indicator,
                         Term(2, ": "),
                         tyExp
                       ]
                     )
               ]
             ))
end;

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

fun '_format_int' arg =
    let val string = Int_toString arg in Term(size string, string) end;

fun '_format_word' arg =
    let val string = "0wx" ^ (Word_toString arg)
    in Term(size string, string) end;

fun '_format_ptr' (f:'a->expression) (arg:'a ptr) =
    let val addr = _cast(arg) : word
        val s = "00000000" ^ Word_toString addr
        val n = String_size s
        val s = if n > 8 then String_substring (s, n - 8, 8) else s
    in Term(10, "0x" ^ s)
    end;

fun '_format_real' arg =
    let val string = Real_toString arg in Term(size string, string) end;

fun '_format_float' arg =
    let val string = Real_toString (Real_fromFloat arg)
    in Term(size string, string) end;

fun '_format_bool' arg =
    let val string = case arg of true => "true" | false => "false"
    in Term(size string, string) end;

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
fun '_format_string' arg =
    let
      val string =
          "\""
          ^ (foldr
                 (fn (left, right) => left ^ right)
                 ""
                 (map escape (explode arg)))
          ^ "\""
    in Term(size string, string) end;
end


(* Bug ? "#\"" is rejected by lexer. *)
fun '_format_char' arg =
    let val string = "#" ^ "\"" ^ (Char_toEscapedString arg) ^ "\""
    in Term(size string, string) end;

(* This formatter does not stop if arg contains cyclic data structure.
 * When module mechanism is supported in future version of compiler,
 * this formatter should be rewritten as described in the message 
 * <20041004161448.85390.qmail@web10103.mail.yahoo.co.jp>
 *)
local
  val depthRef = ref 1
  val MaxDepth = 5
in
fun '_format_ref' format_arg (ref (arg : 'a)) =
    (* Note: '!' and 'before' are not defined yet here. *)
    case depthRef of
      ref depth => 
      if MaxDepth <= depth
      then Term(7, "ref ...")
      else
        let
          val _ = depthRef := depth + 1
          val result = Guard(NONE, [Term(3, "ref"), format_arg arg])
          val _ = depthRef := depth
        in
          result
        end
          handle e => (depthRef := depth; raise e);

end;

val '_format_exnRef' =
    ref
        (fn exn =>
            let
              val string = 
                  case exn
                   of Match => "Match"
                    | Bind => "Bind"
                    | MatchCompBug message => "MatchCompBug:" ^ message
                    | Formatter message => "Formatter:" ^ message
                    | SysErr(message, syserrOpt) => "SysErr:" ^ message
                    | Fail(message) => "Fail:" ^ message
            in Term(size string, string) end);

fun '_format_exn' exn = case '_format_exnRef' of ref format => format exn;

fun '_format_list' format_element list =
    let
      fun format [] = []
        | format [last] = [format_element last]
        | format (head :: tail) =
          format_element head :: Term(1, ",") :: format tail
    in Guard(NONE, Term(1, "[") :: format list @ [Term(1, "]")]) end;

fun '_format_array' (format_arg : 'a -> string) (arg : 'a array) =
    Term(5, "array");

fun '_format_byteArray' (arg : byteArray) =
    Term(9, "byteArray");

fun '_format_byte' (arg : byte) =
    let val string = "0wx" ^ (Word_toString ((_cast (arg)) : word))
    in Term(size string, string) end;

(*****************************************************************************)

exception Fail = Fail (* Fail is builtin exception. *)

fun negInt number = subInt(0, number)

fun not true = false
  | not fasle = true;

fun left <> right = not (left = right);

fun ! (ref arg) = arg;

fun f o g = fn x => f(g x);

fun result before discard = result;

(*****************************************************************************)

(* option is built-in type. 
datatype 'a option = NONE
                   | SOME of 'a;
*)

fun '_format_option' format_element NONE = Term(4, "NONE")
  | '_format_option' format_element (SOME arg) =
    Guard(NONE, [Term(4, "SOME"), format_element arg]);

exception Option;

fun getOpt (SOME v, _) = v
  | getOpt (NONE, v) = v;

fun valOf (SOME v) = v
  | valOf NONE = raise Option;

fun isSome (SOME _) = true | isSome NONE = false;

(*****************************************************************************)
(* for FFI *)

type void = unit;
val NULL = '_NULL';

(*****************************************************************************)

    datatype arch =
             Alpha
           | AMD64
           | ARM
           | HPPA
           | IA64
           | m68k
           | MIPS
           | PowerPC
           | S390
           | Sparc
           | X86
           | Unknown;

fun '_format_arch' Alpha = Term(5, "Alpha")
  | '_format_arch' AMD64 = Term(5, "AMD64")
  | '_format_arch' ARM = Term(3, "ARM")
  | '_format_arch' HPPA = Term(4, "HPPA")
  | '_format_arch' IA64 = Term(4, "IA64")
  | '_format_arch' m68k = Term(4, "m68k") 
  | '_format_arch' MIPS = Term(4, "MIPS")
  | '_format_arch' PowerPC = Term(7, "PowerPC")
  | '_format_arch' S390 = Term(4, "S390")
  | '_format_arch' Sparc = Term(5, "Sparc")
  | '_format_arch' X86 = Term(4, "X86")
  | '_format_arch' Unknown = Term(7, "Unknown");

  datatype OS =
           Cygwin
         | Darwin
         | FreeBSD
         | Linux
         | MinGW
         | NetBSD
         | OpenBSD
         | Solaris
         | Unknown;

fun '_format_OS' Cygwin = Term(6, "Cygwin")
  | '_format_OS' Darwin = Term(6, "Darwin")
  | '_format_OS' FreeBSD = Term(7, "FreeBSD")
  | '_format_OS' Linux = Term(5, "Linux") 
  | '_format_OS' MinGW = Term(5, "MinGW")
  | '_format_OS' NetBSD = Term(6, "NetBSD")
  | '_format_OS' OpenBSD = Term(7, "OpenBSD")
  | '_format_OS' Solaris = Term(7, "Solaris")
  | '_format_OS' Unknown = Term(7, "Unknown");

(*****************************************************************************)

fun '_format_assocDirection' (Left) = Term(4, "Left")
  | '_format_assocDirection' (Right) = Term(5, "Right")
  | '_format_assocDirection' (Neutral) = Term(7, "Neutral");

fun '_format_priority' (Preferred n) =
    Guard(NONE, [Term(9, "Preferred"), '_format_int' n])
  | '_format_priority' (Deferred) = Term(8, "Deferred");

fun '_format_assoc' {cut, strength, direction} = Term(4, "assoc");
(*
    "{cut = " ^ '_format_bool' cut ^ ", "
    ^ "strength = " ^ '_format_int' strength ^ ", "
    ^ "direction = " ^ '_format_assocDirection' direction
    ^ "}";
*);

fun '_format_expression' (Term(n, s)) =
    Guard
        (
          NONE,
          [
            Term(4, "Term"),
            Term(1, "("),
            '_format_int' n,
            Term(1, ","),
            '_format_string' s,
            Term(1,")")
          ]
        )
  | '_format_expression' (Guard(assocOpt, expressions)) =
    Guard
        (
          NONE,
          [
            Term(5, "Guard"),
            Term(1, "("),
            '_format_option' '_format_assoc' assocOpt,
            Term(1, ","),
            '_format_list' '_format_expression' expressions,
            Term(1, ")")
          ]
        )
  | '_format_expression' (Indicator{space, newline}) =
    Guard
        (
          NONE,
          [
            Term(9, "Indicator"),
            Term(1, "{"),
            '_format_bool' space,
            Term(1, ","),
            '_format_option'
                (fn {priority} => '_format_priority' priority) newline,
            Term(1, "}")
          ]
        )
  | '_format_expression' (StartOfIndent n) =
    Guard(NONE, [Term(13, "StartOfIndent"), '_format_int' n])
  | '_format_expression' (EndOfIndent) = Term(11, "EndOfIndent");

(*****************************************************************************)

