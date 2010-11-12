(**
 *
 * Utility functions to manipulate the typed flat pattern calculus.
 * @copyright (c) 2006, Tohoku University.
 * @author YAMATODANI Kiyoshi
 * @author Satoshi Osaka
 * @version $Id: TypedFlatCalcUtils.sml,v 1.19 2008/02/23 15:49:54 bochao Exp $
 *)
structure TypedFlatCalcUtils  = 
struct
local 
    datatype valIdent = datatype Types.valIdent
    open TypedFlatCalc 
in
  fun getLocOfExp exp =
      case exp of
        TFPFOREIGNAPPLY {loc,...} => loc
      | TFPEXPORTCALLBACK {loc,...} => loc
      | TFPSIZEOF (_, loc) => loc
      | TFPCONSTANT (_, loc) => loc
      | TFPGLOBALSYMBOL (_, _, _, loc) => loc
      | TFPVAR (_, loc) => loc
      | TFPGETFIELD (tpexp, index, ty, loc) => loc
(*      | TFPGETGLOBALVALUE (_, _, _, loc) => loc*)
      | TFPARRAY {loc,...} => loc
      | TFPPRIMAPPLY {loc,...} => loc
      | TFPOPRIMAPPLY {loc,...} => loc
      | TFPDATACONSTRUCT {loc,...} => loc
      | TFPEXNCONSTRUCT {loc,...} => loc
      | TFPAPPM {loc,...} => loc
      | TFPMONOLET {loc,...} => loc
      | TFPLET (_,_,_,loc) => loc
      | TFPRECORD {loc,...} => loc
      | TFPSELECT {loc,...} => loc
      | TFPMODIFY {loc,...} => loc
      | TFPRAISE  (tfpexp,ty,loc) => loc
      | TFPHANDLE {loc,...} => loc
      | TFPCASEM  {loc,...} => loc
      | TFPFNM {loc,...} => loc
      | TFPPOLYFNM {loc,...} => loc
      | TFPPOLY {loc,...} => loc
      | TFPTAPP {loc,...} => loc
      | TFPSEQ {loc,...} => loc
      | TFPLIST {loc,...} => loc
      | TFPCAST (tfpexp,ty,loc) => loc
      | TFPSQLSERVER {server, schema, resultTy, loc} => loc

(*
  structure VIdOrd : ORD_KEY =
  struct
    fun compare ({displayName = n1, ty = ty1, varId = varId1}, 
	         {displayName = n2, ty = ty2, varId = varId2}) =
        Types.compareVarId (varId1, varId2)
    type ord_key = varIdInfo
  end
*)  

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

  fun getFV (TFPFOREIGNAPPLY {funExp, argExpList,...}) =
      getFV funExp ++ foldlUnion getFV argExpList
    | getFV (TFPEXPORTCALLBACK {funExp,...}) = getFV funExp
    | getFV (TFPSIZEOF _) = VarSet.empty
    | getFV (TFPCONSTANT _) = VarSet.empty
    | getFV (TFPGLOBALSYMBOL _) = VarSet.empty
    | getFV (TFPVAR (var, loc)) = VarSet.singleton var
    | getFV (TFPGETFIELD (exp1, int, ty, loc)) = getFV exp1
(*    | getFV (TFPGETGLOBALVALUE _) = VarSet.empty*)
    | getFV (TFPARRAY {sizeExp, initExp,...}) = getFV sizeExp ++ getFV initExp
    | getFV (TFPOPRIMAPPLY {argExpOpt=NONE, ...}) = VarSet.empty
    | getFV (TFPOPRIMAPPLY {argExpOpt=SOME exp, ...}) = getFV exp
    | getFV (TFPPRIMAPPLY {argExpOpt= NONE,...}) = VarSet.empty
    | getFV (TFPPRIMAPPLY {argExpOpt= SOME exp,...}) = getFV exp
    | getFV (TFPDATACONSTRUCT {argExpOpt= NONE,...}) = VarSet.empty
    | getFV (TFPDATACONSTRUCT {argExpOpt= SOME exp,...}) = getFV exp
    | getFV (TFPEXNCONSTRUCT {argExpOpt= NONE,...}) = VarSet.empty
    | getFV (TFPEXNCONSTRUCT {argExpOpt= SOME exp,...}) = getFV exp
    | getFV (TFPAPPM {funExp, argExpList, ...}) =
      foldl (fn (exp,S) => getFV exp ++ S)  (getFV funExp) argExpList
    | getFV (TFPLET ( decs, exps, tyl, loc)) =
      (getDecsFV decs) ++ ((foldlUnion getFV exps) -- (foldlUnion getBV decs))
    | getFV (TFPMONOLET {binds, bodyExp, loc}) =
      let val (FV, BV) =
        foldl
        (fn ( (var, exp), (FV, BV) ) =>
         (FV ++ getFV exp, VarSet.add (BV, var)))
        (VarSet.empty,VarSet.empty)
        binds
      in
        FV ++ ((getFV bodyExp) -- BV)
      end
    | getFV (TFPRECORD {fields, ...}) =
      SEnv.foldl (fn ( field, FV ) => (getFV field) ++ FV) VarSet.empty fields
    | getFV (TFPSELECT {exp, ...}) = getFV exp
    | getFV (TFPMODIFY {recordExp, elementExp, ...}) = (getFV recordExp) ++ (getFV elementExp)
    | getFV (TFPRAISE (exp, _, _)) = getFV exp
    | getFV (TFPHANDLE { exp, handler,...}) = (getFV exp) ++ (getFV handler)
    | getFV (TFPCASEM {expList, ruleList, ...}) = 
      (foldlUnion getFV expList) 
      ++
      (foldlUnion 
       (fn (_, tfpexp) => getFV tfpexp)
       ruleList)
    | getFV (TFPFNM {argVarList, bodyTy, bodyExp, loc})= 
      foldl
      (fn (var, S) => VarSetDelete ( S, var ))
      (getFV bodyExp)
      argVarList
    | getFV (TFPPOLYFNM {argVarList,bodyExp,...}) = 
      foldl
      (fn (var, S) => VarSetDelete ( S, var ))
      (getFV bodyExp)
      argVarList
    | getFV (TFPPOLY {exp,...}) =  getFV exp
    | getFV (TFPTAPP {exp, ...}) = getFV exp
    | getFV (TFPSEQ {expList,...}) = foldlUnion getFV expList
    | getFV (TFPLIST {expList,...}) = foldlUnion getFV expList
    | getFV (TFPCAST (exp, ty, loc)) =  getFV exp
    | getFV (TFPSQLSERVER {server, schema, resultTy, loc}) =
      foldlUnion (getFV o #2) server

  and getDecFVBV (TFPVAL (binds, loc)) =
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
(*
      foldl
      (fn ( (VALDECIDENT var, exp ), ( FV, BV ) ) =>
          ( 
	    FV ++ (VarSetDelete ( getFV exp, var )),
	    VarSet.add ( BV, var )
	  )
      | ( (VALDECIDENTWILD _, exp), ( FV, BV) ) => 
          ( 
	    FV ++ (getFV exp), 
	    BV
	  )
          )
      ( VarSet.empty, VarSet.empty )
      binds
*)
    | getDecFVBV (TFPVALREC (decs, loc)) = 
      let
	val BV = 
	  foldl (fn ( ( var, _, _ ), BV ) => VarSet.add ( BV, var )) VarSet.empty decs
      in
	( foldlUnion (fn ( _, _, exp ) => (getFV exp) -- BV) decs, BV )
      end
    | getDecFVBV (TFPVALPOLYREC (btvenv,decs,loc)) = 
      let
	val BV = 
	  foldl (fn ( ( var, _, _ ), BV ) => VarSet.add ( BV, var )) VarSet.empty decs
      in
	( foldlUnion (fn ( _, _, exp ) => (getFV exp) -- BV) decs, BV )
      end
    | getDecFVBV (TFPLOCALDEC ( decs1, decs2, loc )) = 
      let
	val ( FV1, BV1 ) = getDecsFVBV decs1
	val ( FV2, BV2 ) = getDecsFVBV decs2
      in
	( FV1 ++ (FV2 -- BV1), BV2 )
      end
    | getDecFVBV (TFPSETFIELD _ ) = (VarSet.empty, VarSet.empty)
    | getDecFVBV (TFPFUNCTORDEC _) = (VarSet.empty, VarSet.empty)
    | getDecFVBV (TFPLINKFUNCTORDEC _) = (VarSet.empty, VarSet.empty)
    | getDecFVBV (TFPEXNBINDDEF _) = (VarSet.empty, VarSet.empty)


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

  and getBV (TFPVAL (decs, loc)) = 
(*
      foldl (fn ( (VALDECIDENT var, _ ), BV ) => VarSet.add ( BV, var )
             | ((VALDECIDENTWILD _, _), BV) => BV
             ) 
      VarSet.empty decs
*)
      foldl (fn ( (VALIDENT var, _ ), BV ) => VarSet.add ( BV, var )
             | ((VALIDENTWILD _, _), BV) => BV
             ) 
      VarSet.empty decs
    | getBV (TFPVALREC (decs, loc)) =
      foldl (fn ( ( var, _ , _ ), BV ) => VarSet.add ( BV, var )) VarSet.empty decs
    | getBV (TFPVALPOLYREC (_,decs,loc)) =
      foldl (fn ( ( var, _ , _ ), BV ) => VarSet.add ( BV, var )) VarSet.empty decs
    | getBV (TFPLOCALDEC ( _, decs2, loc )) = foldlUnion getBV decs2
    | getBV (TFPSETFIELD _ ) = VarSet.empty
    | getBV (TFPFUNCTORDEC _ ) = VarSet.empty
    | getBV (TFPLINKFUNCTORDEC _ ) = VarSet.empty
    | getBV (TFPEXNBINDDEF _) = VarSet.empty
end
end
