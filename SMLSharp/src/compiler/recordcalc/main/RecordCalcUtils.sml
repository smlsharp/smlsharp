(**
 * Utility functions for record calculus. This needs re-write.
 * <p>
 * Atsushi Ohori 
 * JAIST, Ishikawa Japan.
 * </p>
 * @author Atushi Ohori
 * @author Satoshi Osaka
 * @version $Id: RecordCalcUtils.sml,v 1.15 2008/06/08 07:56:59 ohori Exp $
 *)
structure RecordCalcUtils = struct
local 
    open RecordCalc
    open Types 
(*
    open Vars
*)
    open TypesUtils
in

  (* match compileで使用。纓坂が追加 *)
  val ++ = VarSet.union
  val -- = VarSet.difference
  infix ++
  infix --

  fun VarSetDelete ( set, item ) =
      if VarSet.member ( set, item )
      then VarSet.delete ( set, item )
      else set

  fun foldlUnion f = foldl (fn ( e, z ) => z ++ (f e)) VarSet.empty

  fun deleteSet ( env, set ) = 
      VarSet.foldl 
      (fn ( var, env ) =>
       #1 (VarEnv.remove ( env, var ))
       handle LibBase.NotFound => env
(*
          if VarEnv.inDomain ( env, var )
	  then #1 (VarEnv.remove ( env, var ))
	  else env
*)
         )
      env
      set

  fun deleteList ( env, vars ) =
      foldl
      (fn ( var, env ) =>
       #1 (VarEnv.remove ( env, var ))
       handle LibBase.NotFound => env
(*
          if VarEnv.inDomain ( env, var )
	  then #1 (VarEnv.remove ( env, var ))
	  else env
*)
            )
      env
      vars

  fun getFV (RCFOREIGNAPPLY {funExp,argExpList,...}) =
      getFV funExp ++ foldlUnion getFV argExpList
    | getFV (RCEXPORTCALLBACK {funExp,...}) = getFV funExp
    | getFV (RCSIZEOF _) = VarSet.empty
    | getFV (RCCONSTANT _) = VarSet.empty
    | getFV (RCGLOBALSYMBOL _) = VarSet.empty
    | getFV (RCVAR (var, loc)) = VarSet.singleton var
    | getFV (RCGETFIELD (exp1, int, ty, loc)) = getFV exp1
    | getFV (RCARRAY {sizeExp, initExp,...}) = getFV sizeExp ++ getFV initExp
    | getFV (RCOPRIMAPPLY {argExpOpt=NONE, ...}) = VarSet.empty
    | getFV (RCOPRIMAPPLY {argExpOpt=SOME exp,...}) = getFV exp
    | getFV (RCPRIMAPPLY {argExpOpt=NONE, ...}) = VarSet.empty
    | getFV (RCPRIMAPPLY {argExpOpt=SOME exp,...}) = getFV exp
    | getFV (RCDATACONSTRUCT {argExpOpt=NONE, ...}) = VarSet.empty
    | getFV (RCEXNCONSTRUCT {argExpOpt=NONE, ...}) = VarSet.empty
    | getFV (RCDATACONSTRUCT {argExpOpt=SOME exp,...}) = getFV exp
    | getFV (RCEXNCONSTRUCT {argExpOpt=SOME exp,...}) = getFV exp
    | getFV (RCAPPM {funExp, argExpList, ...}) =
      (getFV funExp) ++ (foldlUnion getFV argExpList)
    | getFV (RCLET ( decs, exps, tyl, loc)) =
      (getDecsFV decs) ++ ((foldlUnion getFV exps) -- (foldlUnion getBV decs))
    | getFV (RCMONOLET {binds, bodyExp, ...}) =
      let
        val (FV,BV) =
          foldl
          (fn ( (var, exp), (FV, BV)) =>
           (
            FV ++ (VarSetDelete (getFV exp, var)),
            VarSet.add ( BV, var )
            )
           )
          (VarSet.empty,VarSet.empty)
          binds
      in
        FV ++ ((getFV bodyExp) -- BV)
      end
    | getFV (RCRECORD {fields, ...}) =
      SEnv.foldl (fn ( field, FV ) => (getFV field) ++ FV) VarSet.empty fields
    | getFV (RCSELECT {exp, ...}) = getFV exp
    | getFV (RCMODIFY {recordExp, elementExp, ...}) = (getFV recordExp) ++ (getFV elementExp)
    | getFV (RCRAISE (exp, _, _)) = getFV exp
    | getFV (RCHANDLE {exp, handler,...}) = (getFV exp) ++ (getFV handler)
    | getFV (RCCASE {exp, ruleList, defaultExp, ...}) = 
      (getFV exp) ++
      (foldlUnion 
       (fn ( _, NONE, exp ) => getFV exp
	 | ( _, SOME var, exp ) => VarSetDelete ( getFV exp, var ))
       ruleList) ++
      (getFV defaultExp)
    | getFV (RCEXNCASE {exp, ruleList, defaultExp, ...}) = 
      (getFV exp) ++
      (foldlUnion 
       (fn ( _, NONE, exp ) => getFV exp
	 | ( _, SOME var, exp ) => VarSetDelete ( getFV exp, var ))
       ruleList) ++
      (getFV defaultExp)
    | getFV (RCSWITCH {switchExp, branches, defaultExp, ...}) = 
      (getFV switchExp) ++
      (foldlUnion (getFV o #2) branches) ++
      (getFV defaultExp)
    | getFV (RCFNM {argVarList, bodyExp, ...}) = 
        foldl (fn (varIdInfo, FV) => VarSetDelete (FV, varIdInfo)) (getFV bodyExp) argVarList
    | getFV (RCPOLYFNM {argVarList, bodyExp,...}) = 
        foldl (fn (varIdInfo, FV) => VarSetDelete (FV, varIdInfo)) (getFV bodyExp) argVarList
    | getFV (RCPOLY {exp,...}) =  getFV exp
    | getFV (RCTAPP {exp, ...}) = getFV exp
    | getFV (RCSEQ {expList, ...}) = foldlUnion getFV expList
    | getFV (RCLIST {expList, ...}) = foldlUnion getFV expList
    | getFV (RCCAST (exp, ty, loc)) =  getFV exp

  and getDecFVBV (RCVAL (binds, loc)) =
      foldl
      (fn ( (VALIDENT var, exp ), ( FV, BV ) ) =>
          ( 
	    FV ++ (VarSetDelete ( getFV exp, var )),
	    VarSet.add ( BV, var )
	  )
      | ( (VALIDENTWILD _, exp), ( FV, BV) ) => 
          ( 
	    FV ++ (getFV exp), 
	    BV
	  )
          )
      ( VarSet.empty, VarSet.empty )
      binds
    | getDecFVBV (RCVALREC (decs, loc)) = 
      let
	val BV = 
	  foldl (fn ( {var, ...}, BV ) => VarSet.add ( BV, var )) VarSet.empty decs
      in
	( foldlUnion (fn {exp,...} => (getFV exp) -- BV) decs, BV )
      end
    | getDecFVBV (RCVALPOLYREC (btvenv,decs,loc)) = 
      let
	val BV = 
	  foldl (fn ( {var, ...}, BV ) => VarSet.add ( BV, var )) VarSet.empty decs
      in
	( foldlUnion (fn {exp,...} => (getFV exp) -- BV) decs, BV )
      end
    | getDecFVBV (RCLOCALDEC ( decs1, decs2, loc )) = 
      let
	val ( FV1, BV1 ) = getDecsFVBV decs1
	val ( FV2, BV2 ) = getDecsFVBV decs2
      in
	( FV1 ++ (FV2 -- BV1), BV2 )
      end
    | getDecFVBV (RCSETFIELD _ ) = (VarSet.empty, VarSet.empty)
    | getDecFVBV (RCEMPTY _) = ( VarSet.empty, VarSet.empty )

  and getDecsFVBV decs =
      foldl
      (fn ( dec, ( FV, BV ) ) =>
          let
	    val ( FV', BV' ) = getDecFVBV dec
	  in
	    ( FV ++ (FV' -- BV), BV ++ BV' )
	  end)
      ( VarSet.empty, VarSet.empty )
      decs

  and getDecsFV decs = #1 (getDecsFVBV decs)

  and getBV (RCVAL (decs, loc)) = 
      foldl (fn ( ( VALIDENT var, _ ), BV ) => VarSet.add ( BV, var )
             | ((VALIDENTWILD _, _), BV) => BV
             ) 
      VarSet.empty decs
    | getBV (RCVALREC (decs, loc)) =
      foldl (fn ( {var,...}, BV ) => VarSet.add ( BV, var )) VarSet.empty decs
    | getBV (RCVALPOLYREC (_,decs,loc)) =
      foldl (fn ( {var, ...}, BV ) => VarSet.add ( BV, var )) VarSet.empty decs
    | getBV (RCLOCALDEC ( _, decs2, loc )) = foldlUnion getBV decs2
    | getBV (RCSETFIELD _ ) = VarSet.empty
    | getBV (RCEMPTY _) = VarSet.empty

end
end
