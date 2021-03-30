(**
 * ElaborateForeach.sml
 * @copyright (C) 2021 SML# Development Team.
 * @author UENO Katsuhiro
 * @author Atsushi Ohori
 *)

structure ElaborateForeach =
struct

  structure A = Absyn
  structure P = PatternCalc

  structure Name =
  struct
    val fun_ForeachArray = ["ForeachArray", "ForeachArray"]
    val fun_ForeachData = ["ForeachData", "ForeachData"]
  end

  fun Pat x (_:P.loc) = x : P.plpat

  fun Exp x (_:P.loc) = x : P.plexp

  fun Loc (loc:P.loc) x = fn (_:P.loc) => x loc

  fun PatVar symbol (_:P.loc) =
      P.PLPATID [symbol]

  fun PatRecord fields loc =
      P.PLPATRECORD (false, map (fn (l, pat) => (l, pat loc)) fields, loc)

  fun PatTuple pats =
      PatRecord (RecordLabel.tupleList pats)

  fun Fn (pat, exp) loc =
      P.PLFNM ([([pat loc], exp loc, loc)], loc)

  fun App exp1 exp2 loc =
      P.PLAPPM (exp1 loc, [exp2 loc], loc)

  fun ExVar name loc =
      P.PLVAR (Symbol.mkLongsymbol name loc)

  fun Fun_FoeachArray e1 e2 e3 =
      App (App (App (ExVar Name.fun_ForeachArray) e1) e2) e3

  fun Fun_ForeachData e1 e2 e3 e4 =
      App (App (App (App (ExVar Name.fun_ForeachData) e1) e2) e3) e4

  fun elaborateExp {elabExp, elabPat} (foreach, loc) =
      case foreach of
        A.FOREACHARRAY {id, pat, data, iterate, pred} =>
        (*
         * _foreach <id> in <data> with <pat> do <iterate> while <pred> end
         *   ||
         *   vv
         * ForeachArray.ForeachArray
         *   <data>
         *   (fn (<id>, <pat>) => <iterate>)
         *   (fn (<id>, <pat>) => <pred>)
         *)
        let
          val pat = Pat (elabPat pat)
          val idPat = PatVar id
          val pat = PatTuple [idPat, pat]
          val data = Exp (elabExp data)
          val iterator = Fn (pat, Exp (elabExp iterate))
          val pred = Fn (pat, Exp (elabExp pred))
        in
          Fun_FoeachArray data iterator pred loc
        end
      | A.FOREACHDATA {id, whereParam, pat, data, iterate, pred} =>
        (*
         * _foreach <id> in <data> where <whereParam> with <pat>
         * do <iterate> while <pred> end
         *      ||
         *      vv
         * ForeachData.ForeachData
         *   <whereParam>
         *   <data>
         *   (fn (<id>, <pat>) => <iterate>)
         *   (fn (<id>, <pat>) => <pred>)
         *)
        let
          val pat = Pat (elabPat pat)
          val idPat = PatVar id
          val pat = PatTuple [idPat, pat]
          val data = Exp (elabExp data)
          val whereParam = Exp (elabExp whereParam)
          val iterator = Fn (pat, Exp (elabExp iterate))
          val pred = Fn (pat, Exp (elabExp pred))
        in
          Fun_ForeachData whereParam data iterator pred loc
        end

end
