(*
 * @author YAMATODANI Kiyoshi
 * @copyright 2010, Tohoku University.
 * @version $Id: ArraySlice.sml,v 1.4 2007/09/01 03:21:15 kiyoshiy Exp $
 *)

local open SMLSharp.SMLFormat in

  fun rev list =
      let
        fun scan [] result = result
          | scan (head :: tail) result = scan tail (head :: result)
      in scan list [] end
  fun op @ ([], right) = right
    | op @ (left, []) = left
    | op @ (left, right) =
      let
        fun scan [] right = right
          | scan (head :: tail) right = scan tail (head :: right)
      in scan (rev left) right
      end

fun '_format_int' arg =
    let val string = SMLSharp.Runtime.Int_toString arg
    in Term(size string, string) end

structure IntInf = struct open IntInf
fun '_format_int' arg =
    let val string = SMLSharp.Runtime.LargeInt_toString arg
    in SMLSharp.SMLFormat.Term(size string, string) end
end

fun '_format_word' arg =
    let val string = "0wx" ^ (SMLSharp.Runtime.Word_toString arg)
    in Term(size string, string) end

fun '_format_ptr' (f:'a->expression) (arg:'a ptr) =
    let val addr = _cast(arg) : word
        val s = "00000000" ^ SMLSharp.Runtime.Word_toString addr
        val n = SMLSharp.PrimString.size s
        val s = if n > 8 then SMLSharp.Runtime.String_substring (s, n - 8, 8)
                else s
    in Term(10, "0x" ^ s)
    end

fun '_format_real' arg =
    let val string = SMLSharp.Runtime.Real_toString arg
    in Term(size string, string) end

structure Real32 = struct open Real32
fun '_format_real' arg =
    let val string = SMLSharp.Runtime.Float_toString arg
    in SMLSharp.SMLFormat.Term(size string, string) end
end

fun '_format_bool' arg =
    let val string = case arg of true => "true" | false => "false"
    in Term(size string, string) end

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
  | escape c = SMLSharp.Runtime.Char_toEscapedString c
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
    in Term(size string, string) end
end

(* Bug ? "#\"" is rejected by lexer. *)
fun '_format_char' arg =
    let val string = "#" ^ "\"" ^ (SMLSharp.Runtime.Char_toEscapedString arg)
                     ^ "\""
    in Term(size string, string) end

(* This formatter does not stop if arg contains cyclic data structure.
 * When module mechanism is supported in future version of compiler,
 * this formatter should be rewritten as described in the message 
 * <20041004161448.85390.qmail@web10103.mail.yahoo.co.jp>
 *)
local
  val depthRef = ref 1
in
fun '_format_ref' format_arg (ref (arg : 'a)) =
    (* Note: '!' and 'before' are not defined yet here. *)
    (* Control_maxRefDepth is defined in prelude.sml. *)
    case (depthRef, Control_maxRefDepth) of
      (ref depth, ref MaxDepth) => 
      if MaxDepth <= depth
      then Term(7, "ref ...")
      else
        let
          val _ = depthRef := depth + 1
          val result =
              Guard
                  (
                    SOME{cut = false, strength = 1, direction = Left},
                    [
                      Term(3, "ref"),
                      Indicator{space = true, newline = NONE},
                      format_arg arg
                    ]
                  )
          val _ = depthRef := depth
        in
          result
        end
          handle e => (depthRef := depth; raise e)

end

local
  fun formatPredefinedExn exn =
      Guard
        (
          NONE,
          (* These predefined exceptions are ordered as the order of tags in 
           * src/primitives/constants.csv *)
          case exn
           of Bind => [Term(4, "Bind")]
            | Match => [Term(5, "Match")]
            | Subscript =>
              [Term(9, "Subscript")]
            | Size => [Term(4, "Size")]
            | Overflow => [Term(8, "Overflow")]
            | Div => [Term(3, "Div")]
            | Domain => [Term(6, "Domain")]
            | Fail(message) =>
              [Term(4, "Fail"), Term(1, ":"), Term(size message, message)]
            | OS.SysErr(message, syserrOpt) =>
              [Term(6, "SysErr"), Term(1, ":"), Term(size message, message)]
            | SMLSharp.MatchCompBug message =>
              [
                Term(12, "MatchCompBug"),
                Term(1, ":"),
                Term(size message, message)
              ]
            | Formatter message =>
              [
                Term(9, "Formatter"),
                Term(1, ":"),
                Term(size message, message)
              ]
            | SMLSharp.Bootstrap =>
              [Term(9, "Bootstrap")]
        )
in
val '_format_exnRef' = ref formatPredefinedExn
end

fun '_format_exn' exn = case '_format_exnRef' of ref format => format exn

structure SMLSharp = struct open SMLSharp
fun '_format_exntag' x = Term(1, "-")
end

fun '_format_list' format_element list =
    let
      val isCutOff =
          case Control_maxWidth
           of ref NONE => (fn _ => false)
            | ref (SOME maxWidth) => (fn w => maxWidth <= w)
      fun format _ [] = []
        | format n (head :: tail) =
          if isCutOff n
          then [Term(3, "...")]
          else
            case tail of
              [] => [format_element head]
            | _ => 
              format_element head
              :: Term(1, ",")
              :: Indicator
                     {space = true, newline = SOME{priority = Preferred 1}}
              :: format (n + 1) tail
    in
      Guard
          (
            SOME{cut = true, strength = 0, direction = Neutral},
            Term(1, "[")
            :: StartOfIndent 2
            :: Indicator{space = false, newline = SOME{priority = Preferred 1}}
            :: Guard(NONE, format 0 list)
            :: [
                 EndOfIndent,
                 Indicator
                     {space = false, newline = SOME{priority = Preferred 1}},
                 Term(1, "]")
               ]
          )
    end

fun '_format_array' (format_arg : 'a -> string) (arg : 'a array) =
    Term(5, "array")

structure Word8 = struct open Word8
fun '_format_word' (arg : word) =
    let
      val string =
          "0wx" ^ (SMLSharp.Runtime.Word_toString (Word.fromInt (toIntX arg)))
    in Term(size string, string) end
end

fun '_format_option' format_element NONE = Term(4, "NONE")
  | '_format_option' format_element (SOME arg) =
    Guard
        (
          NONE,
          [
            Term(4, "SOME"),
            Indicator{space = true, newline = NONE},
            format_element arg
          ])

structure SMLSharp = struct open SMLSharp
structure SMLFormat = struct open SMLFormat
fun '_format_assocDirection' (Left) = Term(4, "Left")
  | '_format_assocDirection' (Right) = Term(5, "Right")
  | '_format_assocDirection' (Neutral) = Term(7, "Neutral")

fun '_format_priority' (Preferred n) =
    Guard(NONE, [Term(9, "Preferred"), '_format_int' n])
  | '_format_priority' (Deferred) = Term(8, "Deferred")

fun '_format_assoc' {cut, strength, direction} = Term(4, "assoc")
(*
    "{cut = " ^ '_format_bool' cut ^ ", "
    ^ "strength = " ^ '_format_int' strength ^ ", "
    ^ "direction = " ^ '_format_assocDirection' direction
    ^ "}";
*)

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
  | '_format_expression' (Newline) = Term(7, "Newline")
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
  | '_format_expression' (EndOfIndent) = Term(11, "EndOfIndent")

end
end

end (* open SMLSharp.SMLFormat *)
