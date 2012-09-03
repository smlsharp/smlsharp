(**
 * resolve the scope of user declaraed type variables.
 * @copyright (c) 2006, Tohoku University.
 * @author Atsushi Ohori 
 * @version $Id: SetTVars.sml,v 1.24 2008/08/24 03:54:41 ohori Exp $
 *)
structure SetTVars : SETTVARS = struct
local
  structure A = Absyn
  structure C = Control
  structure PCF = PatternCalcFlattened
  structure UE = UserError
  structure E = SetTVarsError
  open PatternCalcWithTvars 
in

 fun tvarNameSetUnion (tvarNameSet1, tvarNameSet2, loc) =
   SEnv.unionWithi  
   (fn (name, eq1, eq2) =>
    case (eq1, eq2) of
      (A.EQ, A.EQ) => eq1
    | (A.NONEQ, A.NONEQ) => eq1
    | _ => raise E.DifferentEqattrivOfSameTvar{name = name, tvar1 = eq1, tvar2 = eq2}
   )
   (tvarNameSet1, tvarNameSet2)

 fun extendTvarNameSetWithKindedTvar loc (({name, eq},_), tvarNameSet) =
   tvarNameSetUnion(SEnv.singleton (name, eq), tvarNameSet, loc)

 fun extendKindedTvarSet (({name, eq},tvarKind), kindedTvarSet) = 
   SEnv.unionWith
   (fn _ => raise E.DuplicateUserTvars {name = name})
   (SEnv.singleton (name, {eqKind = eq, recordKind = tvarKind}), kindedTvarSet)

 fun tvarNameSetDifference (tvarNameSet1, tvarNameSet2) =
   let 
     val removeKeys = 
       SEnv.listKeys
       (SEnv.intersectWithi
        (fn (name, eq1, eq2) =>
         case (eq1, eq2) of
           (A.EQ, A.EQ) => eq1
         | (A.NONEQ, A.NONEQ) => eq1
         | _ => raise E.DifferentEqattrivOfSameTvar{name = name, tvar1 = eq1, tvar2 = eq2}
        )
       (tvarNameSet1, tvarNameSet2))
   in
     foldl (fn (string, tvarNameSet) => #1 (SEnv.remove(tvarNameSet, string)))
     tvarNameSet1
     removeKeys
   end

 fun tvarsInTy ty = 
   (case ty of
      A.TYID ({name, eq},loc) =>  SEnv.singleton (name, eq)
    | A.TYRECORD (stringTyList, loc) =>
        foldr (fn ((l,ty), tvarNameSet) =>
               tvarNameSetUnion(tvarNameSet, tvarsInTy ty, loc)) 
        SEnv.empty 
        stringTyList
    | A.TYCONSTRUCT (tyList, string, loc) =>
        raise Control.Bug "TYCONSTRUCT in SetTvar"
    | A.TYCONSTRUCT_WITH_NAMEPATH (tyList, string, loc) =>
        foldr (fn (ty, tvarNameSet)=> 
               tvarNameSetUnion(tvarNameSet, tvarsInTy ty, loc))
        SEnv.empty tyList
    | A.TYTUPLE (tyList, loc) => 
        foldr (fn (ty, tvarNameSet)=> 
               tvarNameSetUnion(tvarNameSet, tvarsInTy ty, loc))
        SEnv.empty tyList
    | A.TYFUN (ty1, ty2, loc) =>
         tvarNameSetUnion(tvarsInTy ty1, tvarsInTy ty2, loc)
    | A.TYFFI (attributes, _, domTys, ranTy, loc) =>
        foldr (fn (ty, tvarNameSet)=>
               tvarNameSetUnion(tvarNameSet, tvarsInTy ty, loc))
              (tvarsInTy ranTy)
              (domTys)
   | A.TYPOLY (kindedTvarList, ty1, loc) => 
        raise Control.Bug "PolyType in a term"
      )
      handle exn as UE.UserErrors _ => raise exn
           | exn as C.Bug _ => raise exn
           | exn => raise UE.UserErrors([(A.getLocTy ty, UE.Error, exn)])

 fun setExpList env plexpList loc =
     foldr 
     (fn (plexp, (ptexpList, tvarset)) =>
      let val (ptexp,tvarset1) = setExp env plexp
      in (ptexp::ptexpList, tvarNameSetUnion(tvarset,tvarset1,loc))
      end)
     (nil, SEnv.empty)
     plexpList

 and setExp env exp = 
   (case exp of
     PCF.PLFCONSTANT (constant , loc) => (PTCONSTANT (constant , loc), SEnv.empty)
   | PCF.PLFGLOBALSYMBOL (name,kind,loc) => (PTGLOBALSYMBOL (name,kind,loc), SEnv.empty)
   | PCF.PLFVAR (path , loc) => (PTVAR (path,loc), SEnv.empty)
   | PCF.PLFTYPED (plexp ,  ty , loc) =>
       let 
         val tvars1 = tvarsInTy ty
         val (ptexp, tvars2) = setExp env plexp
       in
         (PTTYPED (ptexp ,  ty , loc), tvarNameSetUnion (tvars1, tvars2, loc))
       end
   | PCF.PLFAPPM (plexp , plexpList , loc) => 
       let 
         val (ptexp, tvars1) = setExp env plexp
         val (ptexpList,tvars2) = setExpList env plexpList loc
       in
           (PTAPPM (ptexp , ptexpList , loc), tvarNameSetUnion(tvars1,tvars2, loc))
       end
   | PCF.PLFLET (pdeclList , plexpList , loc) => 
       let 
         val (ptdecls, tvarset1) = 
           foldr (fn (pldecl, (ptdecls, tvarset)) => 
                  let
                    val (ptdecl, tvarset1) = setDecl env pldecl
                  in
                    (ptdecl::ptdecls, tvarNameSetUnion(tvarset1, tvarset, loc))
                  end)
           (nil, SEnv.empty)
           pdeclList

         val (ptexps, tvarset2) = 
           foldr (fn (plexp, (ptexps, tvarset)) => 
                  let val (ptexp , tvarset1) = setExp env plexp
                  in (ptexp::ptexps, tvarNameSetUnion(tvarset, tvarset1, loc))
                  end)
           (nil, SEnv.empty)
           plexpList
         val tvarset3 = tvarNameSetUnion(tvarset1, tvarset2, loc)
       in
         (PTLET (ptdecls , ptexps, loc), tvarset3)
       end
   | PCF.PLFRECORD (stringPlexpList , loc) => 
       let
         val (fields, tvarset) = 
           foldr (fn ((l,plexp1),(binds,tvarset)) =>
                  let val (ptexp1,tvarset1) = setExp env plexp1
                  in ((l,ptexp1)::binds, tvarNameSetUnion(tvarset,tvarset1,loc))
                  end)
           (nil, SEnv.empty)
           stringPlexpList
       in
         (PTRECORD (fields, loc), tvarset)
       end
   | PCF.PLFRECORD_UPDATE (plexp, stringPlexpList, loc) => 
       let
         val (ptexp, tvarset) = setExp env plexp
         val (fields, tvarset) = 
           foldr (fn ((l,plexp1),(binds,tvarset)) =>
                  let val (ptexp1,tvarset1) = setExp env plexp1
                  in ((l,ptexp1)::binds, tvarNameSetUnion(tvarset,tvarset1,loc))
                  end)
           (nil, tvarset)
           stringPlexpList
       in
         (PTRECORD_UPDATE (ptexp, fields, loc), tvarset)
       end
   | PCF.PLFTUPLE (plexpList , loc) => 
       let
         val (ptexpList, tvarset) = 
             foldr (fn (plexp, (ptexpList, tvarset)) => 
                    let val (ptexp , tvarset1) = setExp env plexp
                    in (ptexp::ptexpList, tvarNameSetUnion(tvarset, tvarset1,loc))
                    end)
             (nil, SEnv.empty)
             plexpList
       in
         (PTTUPLE(ptexpList, loc), tvarset)
       end
   | PCF.PLFLIST (plexpList , loc) => 
       let
         val (ptexpList, tvarset) = 
             foldr (fn (plexp, (ptexpList, tvarset)) => 
                    let val (ptexp , tvarset1) = setExp env plexp
                    in (ptexp::ptexpList, tvarNameSetUnion(tvarset, tvarset1, loc))
                    end)
             (nil, SEnv.empty)
             plexpList
       in
         (PTLIST(ptexpList, loc), tvarset)
       end
   | PCF.PLFRAISE (plexp , loc) => 
       let 
         val (ptexp,tvarset) = setExp env plexp
       in
         (PTRAISE (ptexp , loc), tvarset)
       end
   | PCF.PLFHANDLE (plexp , plpatPlexpList, loc) => 
       let 
         val (ptexp, tvarset) = setExp env plexp
         val (ptrules, tvarset2) = 
           foldr (fn ((plpat, plexp1), (ptrules, tvarset2)) =>
                  let
                    val (ptpat, tvarset3) = setPat env plpat
                    val (ptexp1, tvarset4) = setExp env plexp1
                  in ((ptpat,ptexp1)::ptrules,
                      tvarNameSetUnion(tvarNameSetUnion(tvarset2, tvarset3, loc), tvarset4, loc))
                  end)
           (nil, SEnv.empty)
           plpatPlexpList
       in
         (PTHANDLE (ptexp, ptrules, loc), tvarNameSetUnion(tvarset, tvarset2, loc))
       end
   | PCF.PLFFNM (plpatListPlexpList , loc) => 
       let 
         val (ptrules, tvarset) = 
           foldr (fn ((plpatList, plexp), (ptrules, tvarset)) =>
                  let
                    val (ptpatList, tvarset1) = setPatList env plpatList loc
                    val (ptexp, tvarset2) = setExp env plexp
                  in ((ptpatList, ptexp)::ptrules,
                      tvarNameSetUnion(tvarNameSetUnion(tvarset, tvarset1, loc), tvarset2, loc))
                  end)
           (nil, SEnv.empty)
           plpatListPlexpList
         val ungardedTvars = tvarNameSetDifference(tvarset, env)
       in
(*
         (PTFNM  (ungardedTvars, ptrules, loc), SEnv.empty)
*)
         (PTFNM  (ungardedTvars, ptrules, loc), ungardedTvars)
       end
   | PCF.PLFCASEM (plexpList ,  plpatListPlexpList , caseKind , loc) => 
       let 
         val (ptexpList, tvarset1) = setExpList env plexpList loc
         val (ptrules, tvarset2) = 
           foldr (fn ((plpatList, plexp1), (ptrules, tvarset)) =>
                  let
                    val (ptpatList, tvarset1) = setPatList env plpatList loc
                    val (ptexp1, tvarset2) = setExp env plexp1
                  in ((ptpatList,ptexp1)::ptrules,
                      tvarNameSetUnion(tvarNameSetUnion(tvarset, tvarset1, loc), tvarset2, loc))
                  end)
           (nil, SEnv.empty)
           plpatListPlexpList
       in
         (PTCASEM (ptexpList ,  ptrules , caseKind , loc) , tvarNameSetUnion(tvarset1, tvarset2, loc))
       end
   | PCF.PLFRECORD_SELECTOR (string , loc) => (PTRECORD_SELECTOR (string , loc), SEnv.empty)
   | PCF.PLFSELECT (string , plexp , loc) => 
       let 
         val (ptexp, tvarset) = setExp env plexp
       in
         (PTSELECT (string , ptexp , loc), tvarset)
       end
   | PCF.PLFSEQ (plexpList , loc) => 
       let
         val (ptexps, tvarset) = 
           foldr (fn (plexp, (ptexps, tvarset)) => 
                  let val (ptexp , tvarset1) = setExp env plexp
                  in (ptexp::ptexps, tvarNameSetUnion(tvarset, tvarset1, loc))
                  end)
           (nil, SEnv.empty)
           plexpList
       in
         (PTSEQ(ptexps, loc), tvarset)
       end
   | PCF.PLFCAST (plexp , loc) => 
       let 
         val (ptexp, tvarset) = setExp env plexp
       in
         (PTCAST (ptexp , loc), tvarset)
       end
   | PCF.PLFFFIIMPORT (plexp , ty , loc) =>
       let 
         val tvars1 = tvarsInTy ty
         val (ptexp, tvars2) = setExp env plexp
       in
         (PTFFIIMPORT (ptexp , ty , loc), tvarNameSetUnion (tvars1, tvars2, loc))
       end
   | PCF.PLFFFIEXPORT (plexp , ty , loc) =>
       let 
         val tvars1 = tvarsInTy ty
         val (ptexp, tvars2) = setExp env plexp
       in
         (PTFFIEXPORT (ptexp , ty , loc), tvarNameSetUnion (tvars1, tvars2, loc))
       end
   | PCF.PLFFFIAPPLY (cconv , funExp , args , retTy , loc) =>
       let
         val tvars1 = tvarsInTy retTy
         val (ptfunExp, tvars2) = setExp env funExp
         val (ptargs, tvars) =
             foldr (fn (arg, (ptargs, tvars)) =>
                       let
                         val (ptarg, tvars3) = setFFIArg env arg
                         val tvars = tvarNameSetUnion (tvars, tvars3, loc)
                       in
                         (ptarg::ptargs, tvars)
                       end)
                   (nil, tvarNameSetUnion (tvars1, tvars2, loc))
                   args
       in
         (PTFFIAPPLY (cconv , ptfunExp, ptargs, retTy, loc), tvars)
       end)
      handle exn as UE.UserErrors _ => raise exn
           | exn as C.Bug _ => raise exn
           | exn => raise UE.UserErrors([(PCF.getLocExp exp, UE.Error, exn)])

 and setFFIArg env arg =
     case arg of
       PCF.PLFFFIARG (exp, ty, loc) =>
       let
         val (ptexp, tvars1) = setExp env exp
         val tvars2 = tvarNameSetUnion (tvars1, tvarsInTy ty, loc)
       in
         (PTFFIARG (ptexp, ty, loc), tvars2)
       end
     | PCF.PLFFFIARGSIZEOF (ty, SOME exp, loc) =>
       let
         val (ptexp, tvars1) = setExp env exp
         val tvars2 = tvarNameSetUnion (tvars1, tvarsInTy ty, loc)
       in
         (PTFFIARGSIZEOF (ty, SOME ptexp, loc), tvars2)
       end
     | PCF.PLFFFIARGSIZEOF (ty, NONE, loc) =>
       (PTFFIARGSIZEOF (ty, NONE, loc), tvarsInTy ty)

 and setDecl env pdecl = 
   (case pdecl of
     PCF.PDFVAL (kindedTvarList, plpatPlexpList, loc ) => 
       let 
         val gardedSet = foldr (extendTvarNameSetWithKindedTvar loc) SEnv.empty kindedTvarList
         val kindedTvarSet = foldr extendKindedTvarSet SEnv.empty kindedTvarList
         val newEnv = tvarNameSetUnion(env, gardedSet,loc)
         val (ptrules, tvarset) = 
           foldr (fn ((plpat, plexp1), (ptrules, tvarset)) =>
                  let
                    val (ptpat, tvarset1) = setPat newEnv plpat
                    val (ptexp1, tvarset2) = setExp newEnv plexp1
                  in ((ptpat,ptexp1)::ptrules,
                      tvarNameSetUnion(tvarNameSetUnion(tvarset, tvarset1, loc), tvarset2, loc))
                  end)
           (nil, SEnv.empty)
           plpatPlexpList
       in
         (PTVAL (kindedTvarSet, tvarset, ptrules , loc), SEnv.empty)
       end
   | PCF.PDFDECFUN (kindedTvarList, plpatPlpatListPlexpListList, loc)  => 
       let 
         val gardedSet = foldr (extendTvarNameSetWithKindedTvar loc) SEnv.empty kindedTvarList
         val kindedTvarSet = foldr extendKindedTvarSet SEnv.empty kindedTvarList
         val newEnv = tvarNameSetUnion(env,gardedSet, loc)
         val (newPlpatPlpatListPlexpListList, newTvarset) =
           foldr 
           (fn ((funPat, plpatListPlexpList), 
                (newPlpatPlpatListPlexpListList, tvarset))
            =>
            let
              val (ptFunPat, tvarset) = setPat newEnv funPat
              val (ptruleMList, tvarset) = 
                foldr (fn ((plpatList, plexp), (ptruleMList, tvarset)) =>
                       let
                         val (ptpatList, tvarset1) = setPatList newEnv plpatList loc
                         val (ptexp, tvarset2) = setExp newEnv plexp
                         val  tvarset3 = 
                           tvarNameSetUnion (tvarNameSetUnion (tvarset,tvarset1,loc), tvarset2,loc)
                       in 
                         (
                          (ptpatList, ptexp)::ptruleMList,
                          tvarset3
                          )
                       end
                     )
                (nil, tvarset)
                plpatListPlexpList
            in
              (
               (ptFunPat, ptruleMList)::newPlpatPlpatListPlexpListList,
               tvarset
               )
            end
            )
           (nil, SEnv.empty)
           plpatPlpatListPlexpListList
       in
         (PTDECFUN (kindedTvarSet, newTvarset, newPlpatPlpatListPlexpListList, loc), SEnv.empty)
       end
   | PCF.PDFNONRECFUN (kindedTvarList, (funPat,plpatListPlexpList), loc)  => 
       let
         val gardedSet = foldr (extendTvarNameSetWithKindedTvar loc) SEnv.empty kindedTvarList
         val kindedTvarSet = foldr extendKindedTvarSet SEnv.empty kindedTvarList
         val newEnv = tvarNameSetUnion(env,gardedSet, loc)
         val (newFunPat, tvarset) = setPat newEnv funPat
         val (ptruleMList, tvarset) = 
           foldr (fn ((plpatList, plexp), (ptruleMList, tvarset)) =>
                  let
                    val (ptpatList, tvarset1) = setPatList newEnv plpatList loc
                    val (ptexp, tvarset2) = setExp newEnv plexp
                    val  tvarset3 = tvarNameSetUnion(tvarNameSetUnion(tvarset, tvarset1, loc), tvarset2,loc)
                  in 
                    (
                     (ptpatList, ptexp)::ptruleMList,
                     tvarset3
                     )
                  end
                  )
           (nil, tvarset)
           plpatListPlexpList
       in
         (PTNONRECFUN (kindedTvarSet, tvarset, (newFunPat,ptruleMList), loc), SEnv.empty)
       end
   | PCF.PDFVALREC (kindedTvarList , plpatPlexpList , loc) => 
       let 
         val gardedSet = foldr (extendTvarNameSetWithKindedTvar loc) SEnv.empty kindedTvarList
         val kindedTvarSet = foldr extendKindedTvarSet SEnv.empty kindedTvarList
         val newEnv = tvarNameSetUnion(env,gardedSet, loc)
         val (ptrules, tvarset) = 
           foldr (fn ((plpat, plexp1), (ptrules, tvarset)) =>
                  let
                    val (ptpat, tvarset1) = setPat newEnv plpat
                    val (ptexp1, tvarset2) = setExp newEnv plexp1
                  in ((ptpat,ptexp1)::ptrules,
                      tvarNameSetUnion(tvarNameSetUnion(tvarset, tvarset1, loc), tvarset2,loc))
                  end)
           (nil, SEnv.empty)
           plpatPlexpList
       in
         (PTVALREC (kindedTvarSet, tvarset, ptrules , loc), SEnv.empty)
       end
   | PCF.PDFVALRECGROUP (idList, pldeclList, loc) =>
     let
       val (ptdecls, tvarset) = 
           foldr (fn (pldecl, (ptdecls, tvarset)) => 
                  let
                    val (ptdecl, tvarset1) = setDecl env pldecl
                  in
                    (ptdecl::ptdecls, tvarNameSetUnion(tvarset1, tvarset, loc))
                  end)
           (nil, SEnv.empty)
           pldeclList
     in
       (PTVALRECGROUP (idList, ptdecls, loc), tvarset)
     end
   | PCF.PDFTYPE x => (PTTYPE x, SEnv.empty)
   | PCF.PDFDATATYPE x =>  (PTDATATYPE x, SEnv.empty)
   | PCF.PDFABSTYPE (prefix, datbinds, pdeclList, loc) =>  
     let
       val (ptdeclList, tvarset) = 
           foldr (fn (pldecl, (ptdecls, tvarset)) => 
                  let
                    val (ptdecl, tvarset1) = setDecl env pldecl
                  in
                    (ptdecl::ptdecls, tvarNameSetUnion(tvarset1, tvarset, loc))
                  end)
           (nil, SEnv.empty)
           pdeclList
     in
         (PTABSTYPE(prefix, datbinds, ptdeclList, loc), tvarset)
     end
   | PCF.PDFREPLICATEDAT x => (PTREPLICATEDAT x,  SEnv.empty)
   | PCF.PDFEXD (exbinds, loc) =>
     let
       fun setExBind (PCF.PLFEXBINDDEF  (arg as (bool, namePath, SOME ty, loc))) =
           (PTEXBINDDEF arg, tvarsInTy ty)
         | setExBind (PCF.PLFEXBINDDEF  (arg as (bool, namePath, NONE, loc))) =
           (PTEXBINDDEF arg, SEnv.empty)
         | setExBind (PCF.PLFEXBINDREP  arg) =
           (PTEXBINDREP arg, SEnv.empty)
       fun setExBindList nil = (nil, SEnv.empty)
         | setExBindList (exBind::exBindList) =
           let
             val (newExBind, tvarset1) = setExBind exBind
             val (newExBindList, tvarset2) = setExBindList exBindList
           in
             (newExBind::newExBindList, tvarNameSetUnion(tvarset1, tvarset2, loc))
           end
       val (newExBindList, tvarset) = setExBindList exbinds
     in
       (PTEXD (newExBindList, loc), tvarset)
     end
   | PCF.PDFLOCALDEC (pdeclList1 , pdeclList2 , loc) => 
       let
         val (ptdecls1, tvarset) = 
           foldr (fn (pldecl, (ptdecls, tvarset)) => 
                  let
                    val (ptdecl, tvarset1) = setDecl env pldecl
                  in
                    (ptdecl::ptdecls, tvarNameSetUnion(tvarset1, tvarset, loc))
                  end)
           (nil, SEnv.empty)
           pdeclList1
         val (ptdecls2, tvarset) = 
           foldr (fn (pldecl, (ptdecls, tvarset)) => 
                  let
                    val (ptdecl, tvarset1) = setDecl env pldecl
                  in
                    (ptdecl::ptdecls, tvarNameSetUnion(tvarset1, tvarset, loc))
                  end)
           (nil, SEnv.empty)
           pdeclList2
       in
         (PTLOCALDEC (ptdecls1, ptdecls2, loc), tvarset)
       end
   | PCF.PDFINTRO (basicNameNPEnv, strNameList, loc) =>
     (PTINTRO (basicNameNPEnv, strNameList, loc), SEnv.empty)
   | PCF.PDFINFIXDEC(n,idlist,loc) => (PTINFIXDEC(n,idlist,loc), SEnv.empty)
   | PCF.PDFINFIXRDEC(n,idlist,loc) => (PTINFIXRDEC(n,idlist,loc), SEnv.empty)
   | PCF.PDFNONFIXDEC(idlist,loc) => (PTNONFIXDEC(idlist,loc), SEnv.empty)
   | PCF.PDFEMPTY => (PTEMPTY, SEnv.empty))
      handle exn as UE.UserErrors _ => raise exn
           | exn as C.Bug _ => raise exn
                | exn => raise UE.UserErrors([(PCF.getLocDec pdecl, UE.Error, exn)])

 and setPatList env plpatList loc = 
     foldr 
     (fn (plpat, (ptpatList, tvarset)) =>
      let val (ptpat, tvarset1) = setPat env plpat
      in (ptpat::ptpatList, tvarNameSetUnion(tvarset, tvarset1, loc))
      end)
     (nil, SEnv.empty)
     plpatList

 and setPat env plpat =
   (case plpat of
     PCF.PLFPATWILD loc => (PTPATWILD loc, SEnv.empty)
   | PCF.PLFPATID (string , loc) => (PTPATID (string , loc), SEnv.empty)
   | PCF.PLFPATCONSTANT (constant , loc) => 
       (PTPATCONSTANT (constant , loc), SEnv.empty)
   | PCF.PLFPATCONSTRUCT (plpat1 , plpat2 , loc) => 
       let
         val (ptpat1, tvarset1) = setPat env plpat1
         val (ptpat2, tvarset2) = setPat env plpat2
       in
         (PTPATCONSTRUCT (ptpat1 , ptpat2 , loc), tvarNameSetUnion(tvarset1, tvarset2, loc))
       end
   | PCF.PLFPATRECORD (bool , stringPlpatList , loc) => 
       let
         val (fields, tvarset) = foldr (fn ((l,plpat), (fields, tvarset)) =>
                                        let val (ptpat, tvarset1) = setPat env plpat
                                        in ((l,ptpat)::fields, tvarNameSetUnion(tvarset, tvarset1, loc))
                                        end)
           (nil, SEnv.empty)
           stringPlpatList
       in
         (PTPATRECORD(bool, fields, loc), tvarset)
       end
   | PCF.PLFPATLAYERED (string , SOME ty , plpat , loc) => 
       let
         val tvarset1 = tvarsInTy ty
         val (ptpat, tvarset2) = setPat env plpat
       in
         (PTPATLAYERED (string , SOME ty , ptpat , loc), tvarNameSetUnion(tvarset1, tvarset2, loc))
       end
   | PCF.PLFPATLAYERED (string , NONE , plpat , loc) => 
       let
         val (ptpat, tvarset) = setPat env plpat
       in
         (PTPATLAYERED (string , NONE , ptpat , loc), tvarset)
       end
   | PCF.PLFPATTYPED (plpat , ty , loc) => 
       let
         val (ptpat, tvarset1) = setPat env plpat
         val tvarset2 = tvarsInTy ty
       in
         (PTPATTYPED (ptpat , ty , loc), tvarNameSetUnion(tvarset1, tvarset2, loc))
       end
   | PCF.PLFPATORPAT (plpat1 , plpat2 , loc) => 
       let
         val (ptpat1, tvarset1) = setPat env plpat1
         val (ptpat2, tvarset2) = setPat env plpat2
       in
         (PTPATORPAT (ptpat1 , ptpat2 , loc), tvarNameSetUnion(tvarset1, tvarset2, loc))
       end)
   handle exn as UE.UserErrors _ => raise exn
        | exn as C.Bug _ => raise exn
        | exn => raise UE.UserErrors([(PCF.getLocPat plpat, UE.Error, exn)])

 and setspec plspec = 
     case plspec of
         PCF.PLFSPECVAL(x) => PTSPECVAL(x)
       | PCF.PLFSPECTYPE(x) => PTSPECTYPE(x)
       | PCF.PLFSPECTYPEEQUATION (x) => PTSPECTYPEEQUATION (x)
       | PCF.PLFSPECEQTYPE(x) => PTSPECEQTYPE(x)
       | PCF.PLFSPECDATATYPE(x) => PTSPECDATATYPE(x)
       | PCF.PLFSPECREPLIC(x) => PTSPECREPLIC(x)
       | PCF.PLFSPECEXCEPTION(x) => PTSPECEXCEPTION(x)
       | PCF.PLFSPECSEQ (plspec1, plspec2, loc) => PTSPECSEQ (setspec plspec1, setspec plspec2, loc)
       | PCF.PLFSPECSHARE(plspec, patpathList, loc) => PTSPECSHARE(setspec plspec, patpathList, loc)
       | PCF.PLFSPECEMPTY => PTSPECEMPTY
       | PCF.PLFSPECPREFIXEDSIGID (namePath, loc) => 
         PTSPECPREFIXEDSIGID (namePath, loc)
       | PCF.PLFSPECSIGWHERE (plspec, longtycons, loc) =>
         PTSPECSIGWHERE (setspec plspec, longtycons, loc) 
(*
       | PCF.PLFSPECFUNCTOR(fundescList, loc) =>
         PTSPECFUNCTOR 
           (map (fn (funName, (argSpec, argNamePathEnv), (bodySpec, bodyNamePathEnv)) =>
           (funName, (setspec argSpec, argNamePathEnv), (setspec bodySpec, bodyNamePathEnv))
           )
           fundescList,
           loc)
*)

 and setStrDecl env plStrdec =
   let
     val setDecl =
       fn env => fn ptdeclList =>
         let
           val (ptdeclList, _) = setDecl env ptdeclList
         in
           ptdeclList
         end
   in
     case plStrdec of
         PCF.PDFCOREDEC (pldecs , loc) => PTCOREDEC(map (setDecl env) pldecs, loc)
       | PCF.PDFTRANCONSTRAINT (pdecls, namemap, plspec, specnamemap, loc) =>
         PTTRANCONSTRAINT (map (setStrDecl env) pdecls, namemap, setspec plspec, specnamemap, loc) 
       | PCF.PDFOPAQCONSTRAINT (pdecls, namemap, plspec, specnamemap, loc) =>
         PTOPAQCONSTRAINT (map (setStrDecl env) pdecls, namemap , setspec plspec, specnamemap, loc) 
       | PCF.PDFFUNCTORAPP x => PTFUNCTORAPP x
       | PCF.PDFSTRLOCAL(decs1, decs2, loc) =>
         PTSTRLOCAL(map (setStrDecl env) decs1, map (setStrDecl env) decs2, loc) 
       | PCF.PDFANDFLATTENED (decUnits, loc) => 
         let
             val newDecUnits = map (fn (printSigInfo, decs) => 
                                       (printSigInfo, map (setStrDecl env) decs))
                                   decUnits
         in
             PTANDFLATTENED(newDecUnits, loc)
         end
   end

 fun setTopDec env plTopDec =
     case plTopDec of
         PCF.PLFDECSTR (strDecs, loc) => PTDECSTR (map (setStrDecl env) strDecs, loc)
       | PCF.PLFDECSIG (newSigDecs, loc) => PTDECSIG ((map (fn (name,(spec, sigExpForPrint)) => 
                                                           (name, (setspec spec, sigExpForPrint))) 
                                                     newSigDecs),
                                                 loc)
       | PCF.PLFDECFUN(funDecs, loc) => 
         PTDECFUNCTOR (map (fn (
                                funName, 
                                (argSpec, argName, argNameMap, sigExpForPrint), 
                                (bodyDecls, bodyNameMap, bodySigExpOpt), 
                                loc) =>
                               (
                                funName, 
                                (setspec argSpec, argName, argNameMap, sigExpForPrint),
                                (map (setStrDecl env) bodyDecls, bodyNameMap, bodySigExpOpt),
                                loc))
                           funDecs,
                           loc)
 fun setInterface (package, interfaceSpec, loc) = (package, setspec interfaceSpec, loc)
end
end
