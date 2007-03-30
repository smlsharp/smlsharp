(**
 *
 * Utility functions to manipulate the typed flat pattern calculus.
 * @copyright (c) 2006, Tohoku University.
 * @author YAMATODANI Kiyoshi
 * @author Satoshi Osaka
 * @version $Id: TypedFlatCalcUtils.sml,v 1.9 2007/02/28 15:31:26 katsu Exp $
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
      | TFPVAR (_, loc) => loc
      | TFPGETGLOBAL (field, ty, loc) => loc
      | TFPGETFIELD (tpexp, index, ty, loc) => loc
      | TFPGETGLOBALVALUE (_, _, _, loc) => loc
      | TFPARRAY {loc,...} => loc
      | TFPPRIMAPPLY {loc,...} => loc
      | TFPOPRIMAPPLY {loc,...} => loc
      | TFPCONSTRUCT {loc,...} => loc
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
      | TFPCAST (tfpexp,ty,loc) => loc

  structure VIdOrd : ordsig =
  struct
    fun compare ({id = id1, displayName = n1, ty = ty1}, 
	         {id = id2, displayName = n2, ty = ty2}) =
        ID.compare(id1, id2)
    type ord_key = varIdInfo
  end
  
  structure VIdEnv = BinaryMapFn(VIdOrd)
  structure VIdSet = BinarySetFn(VIdOrd)

  structure VIdMap = VIdEnv

  val ++ = VIdSet.union
  val -- = VIdSet.difference
  infix ++
  infix --

  fun VIdSetDelete ( set, item ) =
      if VIdSet.member ( set, item )
      then VIdSet.delete ( set, item )
      else set

  fun foldlUnion f = foldl (fn ( e, z ) => z ++ (f e)) VIdSet.empty

  fun deleteSet ( env, set ) = 
      VIdSet.foldl 
      (fn ( var, env ) =>
       #1 (VIdMap.remove ( env, var ))
       handle LibBase.NotFound => env
(*
          if VIdMap.inDomain ( env, var )
	  then #1 (VIdMap.remove ( env, var ))
	  else env
*)
         )
      env
      set
  fun deleteList ( env, vars ) =
      foldl
      (fn ( var, env ) =>
       #1 (VIdMap.remove ( env, var ))
       handle LibBase.NotFound => env
(*
          if VIdMap.inDomain ( env, var )
	  then #1 (VIdMap.remove ( env, var ))
	  else env
*)
            )
      env
      vars

  fun getFV (TFPFOREIGNAPPLY {funExp, argExpList,...}) =
      getFV funExp ++ foldlUnion getFV argExpList
    | getFV (TFPEXPORTCALLBACK {funExp,...}) = getFV funExp
    | getFV (TFPSIZEOF _) = VIdSet.empty
    | getFV (TFPCONSTANT _) = VIdSet.empty
    | getFV (TFPVAR (var, loc)) = VIdSet.singleton var
    | getFV (TFPGETGLOBAL _) = VIdSet.empty
    | getFV (TFPGETFIELD (exp1, int, ty, loc)) = getFV exp1
    | getFV (TFPGETGLOBALVALUE _) = VIdSet.empty
    | getFV (TFPARRAY {sizeExp, initExp,...}) = getFV sizeExp ++ getFV initExp
    | getFV (TFPOPRIMAPPLY {argExpOpt=NONE, ...}) = VIdSet.empty
    | getFV (TFPOPRIMAPPLY {argExpOpt=SOME exp, ...}) = getFV exp
    | getFV (TFPPRIMAPPLY {argExpOpt= NONE,...}) = VIdSet.empty
    | getFV (TFPPRIMAPPLY {argExpOpt= SOME exp,...}) = getFV exp
    | getFV (TFPCONSTRUCT {argExpOpt= NONE,...}) = VIdSet.empty
    | getFV (TFPCONSTRUCT {argExpOpt= SOME exp,...}) = getFV exp
    | getFV (TFPAPPM {funExp, argExpList, ...}) =
      foldl (fn (exp,S) => getFV exp ++ S)  (getFV funExp) argExpList
    | getFV (TFPLET ( decs, exps, tyl, loc)) =
      (getDecsFV decs) ++ ((foldlUnion getFV exps) -- (foldlUnion getBV decs))
    | getFV (TFPMONOLET {binds, bodyExp, loc}) =
      let val (FV, BV) =
        foldl
        (fn ( (var, exp), (FV, BV) ) =>
         (FV ++ getFV exp, VIdSet.add (BV, var)))
        (VIdSet.empty,VIdSet.empty)
        binds
      in
        FV ++ ((getFV bodyExp) -- BV)
      end
    | getFV (TFPRECORD {fields, ...}) =
      SEnv.foldl (fn ( field, FV ) => (getFV field) ++ FV) VIdSet.empty fields
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
      (fn (var, S) => VIdSetDelete ( S, var ))
      (getFV bodyExp)
      argVarList
    | getFV (TFPPOLYFNM {argVarList,bodyExp,...}) = 
      foldl
      (fn (var, S) => VIdSetDelete ( S, var ))
      (getFV bodyExp)
      argVarList
    | getFV (TFPPOLY {exp,...}) =  getFV exp
    | getFV (TFPTAPP {exp, ...}) = getFV exp
    | getFV (TFPSEQ {expList,...}) = foldlUnion getFV expList
    | getFV (TFPCAST (exp, ty, loc)) =  getFV exp

  and getDecFVBV (TFPVAL (binds, loc)) =
      foldl
      (fn ( (VALIDENT var, exp ), ( FV, BV ) ) =>
          ( 
	    FV ++ (VIdSetDelete ( getFV exp, var )),
	    VIdSet.add ( BV, var )
	  )
      | ( (VALIDENTWILD _, exp), ( FV, BV) ) => 
          ( 
	    FV ++ (getFV exp), 
	    BV
	  )
          )
      ( VIdSet.empty, VIdSet.empty )
      binds
(*
      foldl
      (fn ( (VALDECIDENT var, exp ), ( FV, BV ) ) =>
          ( 
	    FV ++ (VIdSetDelete ( getFV exp, var )),
	    VIdSet.add ( BV, var )
	  )
      | ( (VALDECIDENTWILD _, exp), ( FV, BV) ) => 
          ( 
	    FV ++ (getFV exp), 
	    BV
	  )
          )
      ( VIdSet.empty, VIdSet.empty )
      binds
*)
    | getDecFVBV (TFPVALREC (decs, loc)) = 
      let
	val BV = 
	  foldl (fn ( ( var, _, _ ), BV ) => VIdSet.add ( BV, var )) VIdSet.empty decs
      in
	( foldlUnion (fn ( _, _, exp ) => (getFV exp) -- BV) decs, BV )
      end
    | getDecFVBV (TFPVALPOLYREC (btvenv,decs,loc)) = 
      let
	val BV = 
	  foldl (fn ( ( var, _, _ ), BV ) => VIdSet.add ( BV, var )) VIdSet.empty decs
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
    | getDecFVBV (TFPSETFIELD _ ) = (VIdSet.empty, VIdSet.empty)
    | getDecFVBV (TFPSETGLOBAL _ ) = (VIdSet.empty, VIdSet.empty)
    | getDecFVBV (TFPSETGLOBALVALUE _ ) = (VIdSet.empty, VIdSet.empty)
    | getDecFVBV (TFPINITARRAY _ ) = (VIdSet.empty, VIdSet.empty)

  and getDecsFVBV decs =
      foldl
      (fn ( dec, ( FV, BV ) ) =>
          let
	    val ( FV', BV' ) = getDecFVBV dec
	  in
	    ( FV ++ (FV' -- BV), BV ++ BV' )
	  end)
      ( VIdSet.empty, VIdSet.empty )
      decs

  and getDecsFV decs = #1 (getDecsFVBV decs)

  and getBV (TFPVAL (decs, loc)) = 
(*
      foldl (fn ( (VALDECIDENT var, _ ), BV ) => VIdSet.add ( BV, var )
             | ((VALDECIDENTWILD _, _), BV) => BV
             ) 
      VIdSet.empty decs
*)
      foldl (fn ( (VALIDENT var, _ ), BV ) => VIdSet.add ( BV, var )
             | ((VALIDENTWILD _, _), BV) => BV
             ) 
      VIdSet.empty decs
    | getBV (TFPVALREC (decs, loc)) =
      foldl (fn ( ( var, _ , _ ), BV ) => VIdSet.add ( BV, var )) VIdSet.empty decs
    | getBV (TFPVALPOLYREC (_,decs,loc)) =
      foldl (fn ( ( var, _ , _ ), BV ) => VIdSet.add ( BV, var )) VIdSet.empty decs
    | getBV (TFPLOCALDEC ( _, decs2, loc )) = foldlUnion getBV decs2
    | getBV (TFPSETFIELD _ ) = VIdSet.empty
    | getBV (TFPSETGLOBAL _ ) = VIdSet.empty
    | getBV (TFPSETGLOBALVALUE _ ) = VIdSet.empty
    | getBV (TFPINITARRAY _ ) = VIdSet.empty

end
end
