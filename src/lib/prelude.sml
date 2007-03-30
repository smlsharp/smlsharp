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
in
fun printFormat exp =
    let val exp' = trans exp
    in print (SMLFormat.prettyPrint [SMLFormat.Columns 80] [exp'])
    end

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
