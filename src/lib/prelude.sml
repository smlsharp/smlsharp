(* following globals are referred from formatters in basis and SMLSharpControl
 * structure. *)
val Control_columns = ref 80;
val Control_maxDepth = ref (SOME 10 : int option);
val Control_maxWidth = ref (SOME 20 : int option);
val Control_maxRefDepth = ref 5;

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
            | Indicator{space, newline} => ()
            | StartOfIndent int => ()
            | EndOfIndent => ()
    in
      pr exp
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

  structure FE = SMLFormat.FormatExpression

  fun transAssocDirection Left = FE.Left
    | transAssocDirection Right = FE.Right
    | transAssocDirection Neutral = FE.Neutral
  fun transAssoc {cut, strength, direction} =
      {
        cut = cut,
        strength = strength,
        direction = transAssocDirection direction
      }
  fun transPriority (Preferred int) = FE.Preferred int
    | transPriority Deferred = FE.Deferred
  fun trans exp =
      case exp
       of Term(int, string) => FE.Term(int, string)
        | Guard(assocOpt, exps) =>
          FE.Guard(Option.map transAssoc assocOpt, map trans exps)
        | Indicator{space, newline = newlineOpt} =>
          FE.Indicator
              {
                space = space,
                newline =
                Option.map
                    (fn {priority} => {priority = transPriority priority})
                    newlineOpt
              }
        | StartOfIndent int => FE.StartOfIndent int
        | EndOfIndent => FE.EndOfIndent

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
fun printFormat exp =
    let
      val exp' = trans exp
    in
      print (SMLFormat.prettyPrint (getPrinterParameters ()) [exp'])
    end;
fun printFormatOfValBinding (name, valExp, tyExp) =
    let
      val valExp' = cutOff (trans valExp)
      val tyExp' = trans tyExp
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
                          valExp',
                          s_1_Indicator,
                          FE.Term(2, ": "),
                          tyExp'
                        ]
                      )
                ])
    end;

structure General : GENERAL =
struct

  open General
  local
    fun leftMostTerm (Guard(_, left :: _)) = leftMostTerm left
      | leftMostTerm (Term(_, string)) = string
      | leftMostTerm _ = raise Fail "BUG: leftMostTerm"
  in
  fun exnName exn =
      let val exp = '_format_exn' exn
      in leftMostTerm exp
      end
  end

  fun exnMessage exn =
      let val exp' = trans ('_format_exn' exn)
      in SMLFormat.prettyPrint [SMLFormat.Columns (valOf Int.maxInt)] [exp']
      end

end

val exnMessage = General.exnMessage;
val exnName = General.exnName;

end
