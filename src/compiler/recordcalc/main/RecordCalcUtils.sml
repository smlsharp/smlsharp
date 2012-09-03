(**
 * Utility functions for record calculus. This needs re-write.
 * <p>
 * Atsushi Ohori 
 * JAIST, Ishikawa Japan.
 * </p>
 * @author Atushi Ohori
 * @author Satoshi Osaka
 * @version $Id: RecordCalcUtils.sml,v 1.3 2006/02/09 10:24:30 ohori Exp $
 *)
structure RecordCalcUtils = struct
local 
    open RecordCalc
    open Types 
    open Vars
    open TypesUtils
in

  (* match compileで使用。纓坂が追加 *)
  structure VMap = VEnv

  val ++ = VSet.union
  val -- = VSet.difference
  infix ++
  infix --

  fun VSetDelete ( set, item ) =
      if VSet.member ( set, item )
      then VSet.delete ( set, item )
      else set

  fun foldlUnion f = foldl (fn ( e, z ) => z ++ (f e)) VSet.empty

  fun deleteSet ( env, set ) = 
      VSet.foldl 
      (fn ( var, env ) =>
       #1 (VMap.remove ( env, var ))
       handle LibBase.NotFound => env
(*
          if VMap.inDomain ( env, var )
	  then #1 (VMap.remove ( env, var ))
	  else env
*)
         )
      env
      set

  fun deleteList ( env, vars ) =
      foldl
      (fn ( var, env ) =>
       #1 (VMap.remove ( env, var ))
       handle LibBase.NotFound => env
(*
          if VMap.inDomain ( env, var )
	  then #1 (VMap.remove ( env, var ))
	  else env
*)
            )
      env
      vars

  fun getFV (RCFOREIGNAPPLY {argExp,...}) =
      getFV argExp
    | getFV (RCCONSTANT _) = VSet.empty
    | getFV (RCVAR (var, loc)) = VSet.singleton var
    | getFV (RCGETGLOBAL _) = VSet.empty
    | getFV (RCGETGLOBALVALUE _) = VSet.empty
    | getFV (RCGETFIELD (exp1, int, ty, loc)) = getFV exp1
    | getFV (RCARRAY {sizeExp, initExp,...}) = getFV sizeExp ++ getFV initExp
    | getFV (RCOPRIMAPPLY {argExpOpt=NONE, ...}) = VSet.empty
    | getFV (RCOPRIMAPPLY {argExpOpt=SOME exp,...}) = getFV exp
    | getFV (RCPRIMAPPLY {argExpOpt=NONE, ...}) = VSet.empty
    | getFV (RCPRIMAPPLY {argExpOpt=SOME exp,...}) = getFV exp
    | getFV (RCCONSTRUCT {argExpOpt=NONE, ...}) = VSet.empty
    | getFV (RCCONSTRUCT {argExpOpt=SOME exp,...}) = getFV exp
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
            FV ++ (VSetDelete (getFV exp, var)),
            VSet.add ( BV, var )
            )
           )
          (VSet.empty,VSet.empty)
          binds
      in
        FV ++ ((getFV bodyExp) -- BV)
      end
    | getFV (RCRECORD {fields, ...}) =
      SEnv.foldl (fn ( field, FV ) => (getFV field) ++ FV) VSet.empty fields
    | getFV (RCSELECT {exp, ...}) = getFV exp
    | getFV (RCMODIFY {recordExp, elementExp, ...}) = (getFV recordExp) ++ (getFV elementExp)
    | getFV (RCRAISE (exp, _, _)) = getFV exp
    | getFV (RCHANDLE {exp, handler,...}) = (getFV exp) ++ (getFV handler)
    | getFV (RCCASE {exp, ruleList, defaultExp, ...}) = 
      (getFV exp) ++
      (foldlUnion 
       (fn ( _, NONE, exp ) => getFV exp
	 | ( _, SOME var, exp ) => VSetDelete ( getFV exp, var ))
       ruleList) ++
      (getFV defaultExp)
    | getFV (RCSWITCH {switchExp, branches, defaultExp, ...}) = 
      (getFV switchExp) ++
      (foldlUnion (getFV o #2) branches) ++
      (getFV defaultExp)
    | getFV (RCFNM {argVarList, bodyExp, ...}) = 
        foldl (fn (varIdInfo, FV) => VSetDelete (FV, varIdInfo)) (getFV bodyExp) argVarList
    | getFV (RCPOLYFNM {argVarList, bodyExp,...}) = 
        foldl (fn (varIdInfo, FV) => VSetDelete (FV, varIdInfo)) (getFV bodyExp) argVarList
    | getFV (RCPOLY {exp,...}) =  getFV exp
    | getFV (RCTAPP {exp, ...}) = getFV exp
    | getFV (RCSEQ {expList, ...}) = foldlUnion getFV expList
    | getFV (RCFFIVAL {funExp, libExp, ...}) = (getFV funExp) ++ (getFV libExp)
    | getFV (RCCAST (exp, ty, loc)) =  getFV exp

  and getDecFVBV (RCVAL (binds, loc)) =
      foldl
      (fn ( (VALIDENT var, exp ), ( FV, BV ) ) =>
          ( 
	    FV ++ (VSetDelete ( getFV exp, var )),
	    VSet.add ( BV, var )
	  )
      | ( (VALIDENTWILD _, exp), ( FV, BV) ) => 
          ( 
	    FV ++ (getFV exp), 
	    BV
	  )
          )
      ( VSet.empty, VSet.empty )
      binds
    | getDecFVBV (RCVALREC (decs, loc)) = 
      let
	val BV = 
	  foldl (fn ( {var, ...}, BV ) => VSet.add ( BV, var )) VSet.empty decs
      in
	( foldlUnion (fn {exp,...} => (getFV exp) -- BV) decs, BV )
      end
    | getDecFVBV (RCVALPOLYREC (btvenv,decs,loc)) = 
      let
	val BV = 
	  foldl (fn ( {var, ...}, BV ) => VSet.add ( BV, var )) VSet.empty decs
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
    | getDecFVBV (RCSETFIELD _ ) = (VSet.empty, VSet.empty)
    | getDecFVBV (RCSETGLOBAL _ ) = (VSet.empty, VSet.empty)
    | getDecFVBV (RCSETGLOBALVALUE _ ) = (VSet.empty, VSet.empty)
    | getDecFVBV (RCINITARRAY _ ) = (VSet.empty, VSet.empty)
    | getDecFVBV (RCEMPTY _) = ( VSet.empty, VSet.empty )

  and getDecsFVBV decs =
      foldl
      (fn ( dec, ( FV, BV ) ) =>
          let
	    val ( FV', BV' ) = getDecFVBV dec
	  in
	    ( FV ++ (FV' -- BV), BV ++ BV' )
	  end)
      ( VSet.empty, VSet.empty )
      decs

  and getDecsFV decs = #1 (getDecsFVBV decs)

  and getBV (RCVAL (decs, loc)) = 
      foldl (fn ( ( VALIDENT var, _ ), BV ) => VSet.add ( BV, var )
             | ((VALIDENTWILD _, _), BV) => BV
             ) 
      VSet.empty decs
    | getBV (RCVALREC (decs, loc)) =
      foldl (fn ( {var,...}, BV ) => VSet.add ( BV, var )) VSet.empty decs
    | getBV (RCVALPOLYREC (_,decs,loc)) =
      foldl (fn ( {var, ...}, BV ) => VSet.add ( BV, var )) VSet.empty decs
    | getBV (RCLOCALDEC ( _, decs2, loc )) = foldlUnion getBV decs2
    | getBV (RCSETFIELD _ ) = VSet.empty
    | getBV (RCSETGLOBAL _ ) = VSet.empty
    | getBV (RCSETGLOBALVALUE _ ) = VSet.empty
    | getBV (RCINITARRAY _ ) = VSet.empty
    | getBV (RCEMPTY _) = VSet.empty

end
end
