(**
 * prelude definitions.
 * @author YAMATODANI Kiyoshi
 * @version $Id: prelude.sml,v 1.16 2008/02/28 13:08:30 kiyoshiy Exp $
 *)

val print = SMLSharp.Runtime.print

(* following globals are referred from formatters in basis and SMLSharpControl
 * structure. *)
val Control_columns = ref 80;
val Control_maxDepth = ref (SOME 10 : int option);
val Control_maxWidth = ref (SOME 20 : int option);
val Control_maxRefDepth = ref 5;

(* temporary printFormat.
 * Full version is defined after SMLFormat is loaded.
 *)
structure SMLSharp = struct open SMLSharp
fun printFormat exp =
    let
      open SMLSharp.SMLFormat
      fun prList [] = ()
        | prList (e :: es) = 
          (pr e; prList es)
      and pr exp =
          case exp
           of Term(int, string) => print string
            | Newline => print "\n"
            | Guard(assocOpt, exps) => prList exps
            | Indicator{space, newline} => ()
            | StartOfIndent int => ()
            | EndOfIndent => ()
    in
      pr exp
    end;
end;

use "./basis.sml";

(*
use "./smlnj-lib.sml";
*)

use "./RegExp.sml";
use "./script.sml";
open Script;
infix =~;

use "./SMLSharp.sml";
use "./FFI.sml";
use "./LMLML.sml";
use "./smlformatlib.sml";

local
  structure FT : FORMAT_EXPRESSION_TYPES =
  struct
    datatype priority = datatype SMLSharp.SMLFormat.priority
    datatype assocDirection = datatype SMLSharp.SMLFormat.assocDirection
    type assoc = {cut : bool, strength : int, direction : assocDirection}
    datatype expression = datatype SMLSharp.SMLFormat.expression
  end
in
structure SMLFormat = SMLFormatBase(FT)
end;

local

  structure FE = SMLFormat.FormatExpression

  fun getPrinterParameters () =
      [
        SMLFormat.Columns (SMLSharp.Control.Printer.getColumns ())
(*
        SMLFormat.MaxDepthOfGuards (Control.Printer.getMaxDepth ()),
        SMLFormat.MaxWidthOfGuards (Control.Printer.getMaxWidth ())
*)
      ]

  val s_Indicator = FE.Indicator{space = true, newline = NONE}
  val s_1_Indicator =
      FE.Indicator
      {space = true, newline = SOME{priority = FE.Preferred 1}}

  local
    val elision =
        FE.Term (3, "...")
(*
        FE.Guard
            (
              NONE,
              [
                FE.Indicator
                    {space = true, newline = SOME{priority = FE.Deferred}},
                FE.Term (3, "...")
              ]
            )
*)
  in
  (* cut-off format expressions according to parameters defined in
   * SMLSharp.Control.Printer structure.
   * That structure has two parameters: MaxDepth and MaxWidth.
   * These specify limitation of depth and width of a format expression seen as
   * a tree.
   * We ignore MaxWidth here, because we think cutting-off according to width
   * is type-dependent.
   * Only format expression generated for a 'list' is cut-off according to
   * width. See _format_list defined in basis/main/BasicFormatters.sml.
   *)
  fun cutOff symbol =
      let
        val maxDepth = SMLSharp.Control.Printer.getMaxDepth ()
(*
        val maxWidth = SMLSharp.Control.Printer.getMaxWidth ()
*)
        val isCutOffDepth =
            case maxDepth of
              NONE => (fn _ => false)
            | SOME depth => (fn d => depth <= d)
        fun keepSymbol (FE.StartOfIndent _) = true
          | keepSymbol FE.EndOfIndent = true
          | keepSymbol _ = false
        fun visit depth (FE.Guard (enclosedAssocOpt, symbols)) =
            if isCutOffDepth depth
            then elision
            else
              let val symbols' = map (visit (depth + 1)) symbols
              in FE.Guard (enclosedAssocOpt, symbols')
              end
          | visit depth symbol = symbol
      in
        visit 0 symbol
      end
  end
in
structure SMLSharp = struct open SMLSharp
fun printFormat exp =
    print (SMLFormat.prettyPrint (getPrinterParameters ()) [exp]);

fun printFormatOfValBinding (name, valExp, tyExp) =
    let
      val valExp = cutOff valExp
    in
      print
          (SMLFormat.prettyPrint
                (getPrinterParameters ())
                [
                  FE.Term(3, "val"),
                  s_Indicator,
                  FE.Guard
                      (
                        NONE,
                        [
                          FE.Term(size name, name),
                          s_Indicator,
                          FE.Term(1, "="),
                          s_1_Indicator,
                          valExp,
                          s_1_Indicator,
                          FE.Term(2, ": "),
                          tyExp
                        ]
                      )
                ])
    end;
end;

structure General : GENERAL =
struct

  open General
  local
    fun leftMostTerm (FE.Guard(_, left :: _)) = leftMostTerm left
      | leftMostTerm (FE.Term(_, string)) = string
      | leftMostTerm _ = raise Fail "BUG: leftMostTerm"
  in
  fun exnName exn =
      let val exp = '_format_exn' exn
      in leftMostTerm exp
      end
  end

  fun exnMessage exn =
      let val exp = '_format_exn' exn
      in SMLFormat.prettyPrint [SMLFormat.Columns (valOf Int.maxInt)] [exp]
      end

end;

val exnMessage = General.exnMessage;
val exnName = General.exnName;

end;

structure SMLSharp = SMLSharp : SMLSHARP
