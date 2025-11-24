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
  datatype loc = datatype Loc.loc

  structure Name =
  struct
    val fun_ForeachArray = (["ForeachArray"], "ForeachArray")
    val fun_ForeachData = (["ForeachData"], "ForeachData")
  end

  fun Pat pat (_ : A.loc) : P.pat = pat

  fun Exp exp (_ : A.loc) : P.exp = exp

  fun Loc (loc : A.loc) x = fn (_ : A.loc) => x loc

  fun PatVar vid (_ : A.loc) =
      P.PATID (nil, vid, #2 vid)

  fun PatRecord fields loc =
      P.PATRECORD
        (map (fn (l, pat) => (l, pat loc, LOC loc)) fields, false, LOC loc)

  fun PatTuple pats loc =
      PatRecord (map (fn (l, p) => ((l, loc), p)) (RecordLabel.tupleList pats))
                loc

  fun Fn (pat, exp) loc =
      P.EXPFN ([(pat loc, exp loc, LOC loc)], LOC loc)

  fun App exp1 exp2 loc =
      P.EXPAPP (exp1 loc, exp2 loc, LOC loc)

  fun ExVar (names, name) loc =
      P.EXPID (map (fn s => (Symbol.intern s, loc)) names,
               (Symbol.intern name, loc),
               loc)

  fun Fun_FoeachArray e1 e2 e3 =
      App (App (App (ExVar Name.fun_ForeachArray) e1) e2) e3

  fun Fun_ForeachData e1 e2 e3 e4 =
      App (App (App (App (ExVar Name.fun_ForeachData) e1) e2) e3) e4

  fun elaborateForeachArray {elabExp, elabPat}
                            (id, data, pat, iterate, pred, loc) =
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

  fun elaborateForeachData {elabExp, elabPat}
                           (id, data, whereParam, pat, iterate, pred, loc) =
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
