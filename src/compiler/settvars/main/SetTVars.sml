(**
 * resolve the scope of user declaraed type variables.
 * @copyright (c) 2006, Tohoku University.
 * @author Atsushi Ohori 
 * @version $Id: SetTVars.sml,v 1.14.2.1 2007/11/05 12:57:38 ohori Exp $
 *)
structure SetTVars : SETTVARS = struct
local
  open PatternCalc PatternCalcWithTvars 
  structure A = Absyn
  structure C = Control
  structure PL = PatternCalc
  structure UE = UserError
  structure E = SetTVarsError
in
 type env = A.tvar SEnv.map

 fun tvarNameSetUnion (tvarNameSet1, tvarNameSet2) =
   SEnv.unionWith  (fn (ifeq1, ifeq2) =>
                    if ifeq1 = ifeq2 then
                      ifeq1
                    else raise E.DifferentEqattrivOfSameTvar{tvar1 = ifeq1, tvar2 = ifeq2})
   (tvarNameSet1, tvarNameSet2)

 fun extendTvarNameSet ({name, ifeq}, tvarNameSet) = tvarNameSetUnion(SEnv.singleton (name, ifeq), tvarNameSet)

 fun tvarNameSetDifference (tvarNameSet1, tvarNameSet2) =
   let 
     val removeKeys = 
       SEnv.listKeys
       (SEnv.intersectWith
        (fn (ifeq1, ifeq2) =>
         if ifeq1 = ifeq2 then
           ifeq1
         else raise E.DifferentEqattrivOfSameTvar{tvar1 = ifeq1, tvar2 = ifeq2})
        (tvarNameSet1, tvarNameSet2))
   in
     foldl (fn (string, tvarNameSet) => #1 (SEnv.remove(tvarNameSet, string)))
     tvarNameSet1
     removeKeys
   end

 fun tvarsInTy ty = 
   (case ty of
      A.TYID ({name, ifeq},loc) =>  SEnv.singleton (name, ifeq)
    | A.TYRECORD (stringTyList, loc) =>
        foldr (fn ((l,ty), tvarNameSet) =>
               tvarNameSetUnion(tvarNameSet, tvarsInTy ty)) 
        SEnv.empty 
        stringTyList
    | A.TYCONSTRUCT (tyList, string, loc) =>
        foldr (fn (ty, tvarNameSet)=> 
               tvarNameSetUnion(tvarNameSet, tvarsInTy ty))
        SEnv.empty tyList
    | A.TYTUPLE (tyList, loc) => 
        foldr (fn (ty, tvarNameSet)=> 
               tvarNameSetUnion(tvarNameSet, tvarsInTy ty))
        SEnv.empty tyList
    | A.TYFUN (ty1, ty2, loc) =>
         tvarNameSetUnion(tvarsInTy ty1, tvarsInTy ty2)
    | A.TYFFI (cconv, domTys, ranTy, loc) =>
        foldr (fn (ty, tvarNameSet)=>
               tvarNameSetUnion(tvarNameSet, tvarsInTy ty))
              (tvarsInTy ranTy)
              (domTys))
      handle exn as UE.UserErrors _ => raise exn
           | exn as C.Bug _ => raise exn
           | exn => raise UE.UserErrors([(A.getLocTy ty, UE.Error, exn)])

 fun setExpList env plexpList =
     foldr 
     (fn (plexp, (ptexpList, tvarset)) =>
      let val (ptexp,tvarset1) = setExp env plexp
      in (ptexp::ptexpList, tvarNameSetUnion(tvarset,tvarset1))
      end)
     (nil, SEnv.empty)
     plexpList

 and setExp env exp = 
   (case exp of
     PLCONSTANT (constant , loc) => (PTCONSTANT (constant , loc), SEnv.empty)
   | PLVAR (path , loc) => (PTVAR (path,loc), SEnv.empty)
   | PLTYPED (plexp ,  ty , loc) =>
       let 
         val tvars1 = tvarsInTy ty
         val (ptexp, tvars2) = setExp env plexp
       in
         (PTTYPED (ptexp ,  ty , loc), tvarNameSetUnion (tvars1, tvars2))
       end
   | PLAPPM (plexp , plexpList , loc) => 
       let 
         val (ptexp, tvars1) = setExp env plexp
         val (ptexpList,tvars2) = setExpList env plexpList 
       in
           (PTAPPM (ptexp , ptexpList , loc), tvarNameSetUnion(tvars1,tvars2))
       end
   | PLLET (pdeclList , plexpList , loc) => 
       let 
         val (ptdecls, tvarset1) = 
           foldr (fn (pldecl, (ptdecls, tvarset)) => 
                  let
                    val (ptdecl, tvarset1) = setDecl env pldecl
                  in
                    (ptdecl::ptdecls, tvarNameSetUnion(tvarset1, tvarset))
                  end)
           (nil, SEnv.empty)
           pdeclList

         val (ptexps, tvarset2) = 
           foldr (fn (plexp, (ptexps, tvarset)) => 
                  let val (ptexp , tvarset1) = setExp env plexp
                  in (ptexp::ptexps, tvarNameSetUnion(tvarset, tvarset1))
                  end)
           (nil, SEnv.empty)
           plexpList
         val tvarset3 = tvarNameSetUnion(tvarset1, tvarset2)
       in
         (PTLET (ptdecls , ptexps, loc), tvarset3)
       end
   | PLRECORD (stringPlexpList , loc) => 
       let
         val (fields, tvarset) = 
           foldr (fn ((l,plexp1),(binds,tvarset)) =>
                  let val (ptexp1,tvarset1) = setExp env plexp1
                  in ((l,ptexp1)::binds, tvarNameSetUnion(tvarset,tvarset1))
                  end)
           (nil, SEnv.empty)
           stringPlexpList
       in
         (PTRECORD (fields, loc), tvarset)
       end
   | PLRECORD_UPDATE (plexp, stringPlexpList, loc) => 
       let
         val (ptexp, tvarset) = setExp env plexp
         val (fields, tvarset) = 
           foldr (fn ((l,plexp1),(binds,tvarset)) =>
                  let val (ptexp1,tvarset1) = setExp env plexp1
                  in ((l,ptexp1)::binds, tvarNameSetUnion(tvarset,tvarset1))
                  end)
           (nil, tvarset)
           stringPlexpList
       in
         (PTRECORD_UPDATE (ptexp, fields, loc), tvarset)
       end
   | PLTUPLE (plexpList , loc) => 
       let
         val (ptexpList, tvarset) = 
             foldr (fn (plexp, (ptexpList, tvarset)) => 
                    let val (ptexp , tvarset1) = setExp env plexp
                    in (ptexp::ptexpList, tvarNameSetUnion(tvarset, tvarset1))
                    end)
             (nil, SEnv.empty)
             plexpList
       in
         (PTTUPLE(ptexpList, loc), tvarset)
       end
   | PLLIST (plexpList , loc) => 
       let
         val (ptexpList, tvarset) = 
             foldr (fn (plexp, (ptexpList, tvarset)) => 
                    let val (ptexp , tvarset1) = setExp env plexp
                    in (ptexp::ptexpList, tvarNameSetUnion(tvarset, tvarset1))
                    end)
             (nil, SEnv.empty)
             plexpList
       in
         (PTLIST(ptexpList, loc), tvarset)
       end
   | PLRAISE (plexp , loc) => 
       let 
         val (ptexp,tvarset) = setExp env plexp
       in
         (PTRAISE (ptexp , loc), tvarset)
       end
   | PLHANDLE (plexp , plpatPlexpList, loc) => 
       let 
         val (ptexp, tvarset) = setExp env plexp
         val (ptrules, tvarset2) = 
           foldr (fn ((plpat, plexp1), (ptrules, tvarset2)) =>
                  let
                    val (ptpat, tvarset3) = setPat env plpat
                    val (ptexp1, tvarset4) = setExp env plexp1
                  in ((ptpat,ptexp1)::ptrules,
                      tvarNameSetUnion(tvarNameSetUnion(tvarset2, tvarset3), tvarset4))
                  end)
           (nil, SEnv.empty)
           plpatPlexpList
       in
         (PTHANDLE (ptexp, ptrules, loc), tvarNameSetUnion(tvarset, tvarset2))
       end
   | PLFNM (plpatListPlexpList , loc) => 
       let 
         val (ptrules, tvarset) = 
           foldr (fn ((plpatList, plexp), (ptrules, tvarset)) =>
                  let
                    val (ptpatList, tvarset1) = setPatList env plpatList
                    val (ptexp, tvarset2) = setExp env plexp
                  in ((ptpatList, ptexp)::ptrules,
                      tvarNameSetUnion(tvarNameSetUnion(tvarset, tvarset1), tvarset2))
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
   | PLCASEM (plexpList ,  plpatListPlexpList , caseKind , loc) => 
       let 
         val (ptexpList, tvarset1) = setExpList env plexpList
         val (ptrules, tvarset2) = 
           foldr (fn ((plpatList, plexp1), (ptrules, tvarset)) =>
                  let
                    val (ptpatList, tvarset1) = setPatList env plpatList
                    val (ptexp1, tvarset2) = setExp env plexp1
                  in ((ptpatList,ptexp1)::ptrules,
                      tvarNameSetUnion(tvarNameSetUnion(tvarset, tvarset1), tvarset2))
                  end)
           (nil, SEnv.empty)
           plpatListPlexpList
       in
         (PTCASEM (ptexpList ,  ptrules , caseKind , loc) , tvarNameSetUnion(tvarset1, tvarset2))
       end
   | PLRECORD_SELECTOR (string , loc) => (PTRECORD_SELECTOR (string , loc), SEnv.empty)
   | PLSELECT (string , plexp , loc) => 
       let 
         val (ptexp, tvarset) = setExp env plexp
       in
         (PTSELECT (string , ptexp , loc), tvarset)
       end
   | PLSEQ (plexpList , loc) => 
       let
         val (ptexps, tvarset) = 
           foldr (fn (plexp, (ptexps, tvarset)) => 
                  let val (ptexp , tvarset1) = setExp env plexp
                  in (ptexp::ptexps, tvarNameSetUnion(tvarset, tvarset1))
                  end)
           (nil, SEnv.empty)
           plexpList
       in
         (PTSEQ(ptexps, loc), tvarset)
       end
   | PLCAST (plexp , loc) => 
       let 
         val (ptexp, tvarset) = setExp env plexp
       in
         (PTCAST (ptexp , loc), tvarset)
       end
   | PLFFIIMPORT (plexp , ty , loc) =>
       let 
         val tvars1 = tvarsInTy ty
         val (ptexp, tvars2) = setExp env plexp
       in
         (PTFFIIMPORT (ptexp , ty , loc), tvarNameSetUnion (tvars1, tvars2))
       end
   | PLFFIEXPORT (plexp , ty , loc) =>
       let 
         val tvars1 = tvarsInTy ty
         val (ptexp, tvars2) = setExp env plexp
       in
         (PTFFIEXPORT (ptexp , ty , loc), tvarNameSetUnion (tvars1, tvars2))
       end
   | PLFFIAPPLY (cconv , funExp , args , retTy , loc) =>
       let
         val tvars1 = tvarsInTy retTy
         val (ptfunExp, tvars2) = setExp env funExp
         val (ptargs, tvars) =
             foldr (fn (arg, (ptargs, tvars)) =>
                       let
                         val (ptarg, tvars3) = setFFIArg env arg
                         val tvars = tvarNameSetUnion (tvars, tvars3)
                       in
                         (ptarg::ptargs, tvars)
                       end)
                   (nil, tvarNameSetUnion (tvars1, tvars2))
                   args
       in
         (PTFFIAPPLY (cconv , ptfunExp, ptargs, retTy, loc), tvars)
       end)
      handle exn as UE.UserErrors _ => raise exn
           | exn as C.Bug _ => raise exn
           | exn => raise UE.UserErrors([(PL.getLocExp exp, UE.Error, exn)])

 and setFFIArg env arg =
     case arg of
       PLFFIARG (exp, ty) =>
       let
         val (ptexp, tvars1) = setExp env exp
         val tvars2 = tvarNameSetUnion (tvars1, tvarsInTy ty)
       in
         (PTFFIARG (ptexp, ty), tvars2)
       end
     | PLFFIARGSIZEOF (ty, SOME exp) =>
       let
         val (ptexp, tvars1) = setExp env exp
         val tvars2 = tvarNameSetUnion (tvars1, tvarsInTy ty)
       in
         (PTFFIARGSIZEOF (ty, SOME ptexp), tvars2)
       end
     | PLFFIARGSIZEOF (ty, NONE) =>
       (PTFFIARGSIZEOF (ty, NONE), tvarsInTy ty)

 and setDecl env pdecl = 
   (case pdecl of
     PDVAL (tvarList , plpatPlexpList , loc ) => 
       let 
         val gardedSet = foldr extendTvarNameSet SEnv.empty tvarList
         val newEnv = tvarNameSetUnion(env, gardedSet)
         val (ptrules, tvarset) = 
           foldr (fn ((plpat, plexp1), (ptrules, tvarset)) =>
                  let
                    val (ptpat, tvarset1) = setPat newEnv plpat
                    val (ptexp1, tvarset2) = setExp newEnv plexp1
                  in ((ptpat,ptexp1)::ptrules,
                      tvarNameSetUnion(tvarNameSetUnion(tvarset, tvarset1), tvarset2))
                  end)
           (nil, SEnv.empty)
           plpatPlexpList
       in
         (PTVAL (gardedSet, tvarset, ptrules , loc), SEnv.empty)
       end
   | PDDECFUN (tvarList, plpatPlpatListPlexpListList, loc)  => 
       let 
         val gardedSet = foldr extendTvarNameSet SEnv.empty tvarList
         val newEnv = tvarNameSetUnion(env,gardedSet)
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
                         val (ptpatList, tvarset1) = setPatList newEnv plpatList
                         val (ptexp, tvarset2) = setExp newEnv plexp
                         val  tvarset3 = 
                           tvarNameSetUnion (tvarNameSetUnion (tvarset,tvarset1), tvarset2)
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
         (PTDECFUN (gardedSet, newTvarset, newPlpatPlpatListPlexpListList, loc), SEnv.empty)
       end
   | PDNONRECFUN (tvarList, (funPat,plpatListPlexpList), loc)  => 
       let
         val gardedSet = foldr extendTvarNameSet SEnv.empty tvarList
         val newEnv = tvarNameSetUnion(env,gardedSet)
         val (newFunPat, tvarset) = setPat newEnv funPat
         val (ptruleMList, tvarset) = 
           foldr (fn ((plpatList, plexp), (ptruleMList, tvarset)) =>
                  let
                    val (ptpatList, tvarset1) = setPatList newEnv plpatList
                    val (ptexp, tvarset2) = setExp newEnv plexp
                    val  tvarset3 = tvarNameSetUnion(tvarNameSetUnion(tvarset, tvarset1), tvarset2)
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
         (PTNONRECFUN (gardedSet, tvarset, (newFunPat,ptruleMList), loc), SEnv.empty)
       end
   | PDVALREC (tvarList , plpatPlexpList , loc) => 
       let 
         val gardedSet = foldr extendTvarNameSet SEnv.empty tvarList
         val newEnv = tvarNameSetUnion(env,gardedSet)
         val (ptrules, tvarset) = 
           foldr (fn ((plpat, plexp1), (ptrules, tvarset)) =>
                  let
                    val (ptpat, tvarset1) = setPat newEnv plpat
                    val (ptexp1, tvarset2) = setExp newEnv plexp1
                  in ((ptpat,ptexp1)::ptrules,
                      tvarNameSetUnion(tvarNameSetUnion(tvarset, tvarset1), tvarset2))
                  end)
           (nil, SEnv.empty)
           plpatPlexpList
       in
         (PTVALREC (gardedSet, tvarset, ptrules , loc), SEnv.empty)
       end
   | PDVALRECGROUP (idList, pdeclList, loc) =>
     let
       val (ptdecls, tvarset) = 
           foldr (fn (pldecl, (ptdecls, tvarset)) => 
                  let
                    val (ptdecl, tvarset1) = setDecl env pldecl
                  in
                    (ptdecl::ptdecls, tvarNameSetUnion(tvarset1, tvarset))
                  end)
           (nil, SEnv.empty)
           pdeclList
     in
       (PTVALRECGROUP (idList, ptdecls, loc), tvarset)
     end
   | PDTYPE x => (PTTYPE x, SEnv.empty)
   | PDDATATYPE x =>  (PTDATATYPE x, SEnv.empty)
   | PDABSTYPE (datbinds, pdeclList, loc) =>  
     let
       val (ptdeclList, tvarset) = 
           foldr (fn (pldecl, (ptdecls, tvarset)) => 
                  let
                    val (ptdecl, tvarset1) = setDecl env pldecl
                  in
                    (ptdecl::ptdecls, tvarNameSetUnion(tvarset1, tvarset))
                  end)
           (nil, SEnv.empty)
           pdeclList
     in
       (PTABSTYPE(datbinds, ptdeclList, loc), tvarset)
     end
   | PDREPLICATEDAT x => (PTREPLICATEDAT x, SEnv.empty)
   | PDEXD (exbinds, loc) =>
     let
       fun setExBind (PLEXBINDDEF  (arg as (bool, namePath, SOME ty, loc))) =
           (PTEXBINDDEF arg, tvarsInTy ty)
         | setExBind (PLEXBINDDEF  (arg as (bool, namePath, NONE, loc))) =
           (PTEXBINDDEF arg, SEnv.empty)
         | setExBind (PLEXBINDREP  arg) =
           (PTEXBINDREP arg, SEnv.empty)
       fun setExBindList nil = (nil, SEnv.empty)
         | setExBindList (exBind::exBindList) =
           let
             val (newExBind, tvarset1) = setExBind exBind
             val (newExBindList, tvarset2) = setExBindList exBindList
           in
             (newExBind::newExBindList, tvarNameSetUnion(tvarset1, tvarset2))
           end
       val (newExBindList, tvarset) = setExBindList exbinds
     in
       (PTEXD (newExBindList, loc), tvarset)
     end
   | PDLOCALDEC (pdeclList1 , pdeclList2 , loc) => 
       let
         val (ptdecls1, tvarset) = 
           foldr (fn (pldecl, (ptdecls, tvarset)) => 
                  let
                    val (ptdecl, tvarset1) = setDecl env pldecl
                  in
                    (ptdecl::ptdecls, tvarNameSetUnion(tvarset1, tvarset))
                  end)
           (nil, SEnv.empty)
           pdeclList1
         val (ptdecls2, tvarset) = 
           foldr (fn (pldecl, (ptdecls, tvarset)) => 
                  let
                    val (ptdecl, tvarset1) = setDecl env pldecl
                  in
                    (ptdecl::ptdecls, tvarNameSetUnion(tvarset1, tvarset))
                  end)
           (nil, SEnv.empty)
           pdeclList2
       in
         (PTLOCALDEC (ptdecls1, ptdecls2, loc), tvarset)
       end
   | PDOPEN(paths,loc) => (PTOPEN(paths,loc), SEnv.empty)
   | PDINFIXDEC(n,idlist,loc) => (PTINFIXDEC(n,idlist,loc), SEnv.empty)
   | PDINFIXRDEC(n,idlist,loc) => (PTINFIXRDEC(n,idlist,loc), SEnv.empty)
   | PDNONFIXDEC(idlist,loc) => (PTNONFIXDEC(idlist,loc), SEnv.empty)
   | PDEMPTY => (PTEMPTY, SEnv.empty))
      handle exn as UE.UserErrors _ => raise exn
           | exn as C.Bug _ => raise exn
           | exn => raise UE.UserErrors([(PL.getLocDec pdecl, UE.Error, exn)])

 and setPatList env plpatList = 
     foldr 
     (fn (plpat, (ptpatList, tvarset)) =>
      let val (ptpat, tvarset1) = setPat env plpat
      in (ptpat::ptpatList, tvarNameSetUnion(tvarset, tvarset1))
      end)
     (nil, SEnv.empty)
     plpatList
 and setPat env plpat =
   (case plpat of
     PLPATWILD loc => (PTPATWILD loc, SEnv.empty)
   | PLPATID (string , loc) => (PTPATID (string , loc), SEnv.empty)
   | PLPATCONSTANT (constant , loc) => 
       (PTPATCONSTANT (constant , loc), SEnv.empty)
   | PLPATCONSTRUCT (plpat1 , plpat2 , loc) => 
       let
         val (ptpat1, tvarset1) = setPat env plpat1
         val (ptpat2, tvarset2) = setPat env plpat2
       in
         (PTPATCONSTRUCT (ptpat1 , ptpat2 , loc), tvarNameSetUnion(tvarset1, tvarset2))
       end
   | PLPATRECORD (bool , stringPlpatList , loc) => 
       let
         val (fields, tvarset) = foldr (fn ((l,plpat), (fields, tvarset)) =>
                                        let val (ptpat, tvarset1) = setPat env plpat
                                        in ((l,ptpat)::fields, tvarNameSetUnion(tvarset, tvarset1))
                                        end)
           (nil, SEnv.empty)
           stringPlpatList
       in
         (PTPATRECORD(bool, fields, loc), tvarset)
       end
   | PLPATLAYERED (string , SOME ty , plpat , loc) => 
       let
         val tvarset1 = tvarsInTy ty
         val (ptpat, tvarset2) = setPat env plpat
       in
         (PTPATLAYERED (string , SOME ty , ptpat , loc), tvarNameSetUnion(tvarset1, tvarset2))
       end
   | PLPATLAYERED (string , NONE , plpat , loc) => 
       let
         val (ptpat, tvarset) = setPat env plpat
       in
         (PTPATLAYERED (string , NONE , ptpat , loc), tvarset)
       end
   | PLPATTYPED (plpat , ty , loc) => 
       let
         val (ptpat, tvarset1) = setPat env plpat
         val tvarset2 = tvarsInTy ty
       in
         (PTPATTYPED (ptpat , ty , loc), tvarNameSetUnion(tvarset1, tvarset2))
       end
   | PLPATORPAT (plpat1 , plpat2 , loc) => 
       let
         val (ptpat1, tvarset1) = setPat env plpat1
         val (ptpat2, tvarset2) = setPat env plpat2
       in
         (PTPATORPAT (ptpat1 , ptpat2 , loc), tvarNameSetUnion(tvarset1, tvarset2))
       end)
   handle exn as UE.UserErrors _ => raise exn
        | exn as C.Bug _ => raise exn
        | exn => raise UE.UserErrors([(PL.getLocPat plpat, UE.Error, exn)])
(**************** module language ************)
 
 and setstrdec env plstrdec =
   let
     val setDecl =
       fn env => fn ptdeclList =>
         let
           val (ptdeclList, _) = setDecl env ptdeclList
         in
           ptdeclList
         end
   in
     case plstrdec of
         PLCOREDEC (pdecl,loc) => PTCOREDEC(setDecl env pdecl,loc)
       | PLSTRUCTBIND (plstrbinds,loc) =>
         let
             val ptstrbinds = foldr (fn (plstrbind as (strid,strexp),ptstrbinds ) => 
                                        ((strid,setstrexp env strexp):: ptstrbinds))
                                    nil 
                                    plstrbinds
         in PTSTRUCTBIND(ptstrbinds,loc) end
       | PLSTRUCTLOCAL(plstrdecs1,plstrdecs2,loc) =>
         let
             val ptstrdecs1 = foldr (fn (plstrdec,ptstrdecs) => 
                                        (setstrdec env plstrdec :: ptstrdecs))
                                    nil 
                                    plstrdecs1
             val ptstrdecs2 = foldr (fn (plstrdec,ptstrdecs) => 
                                        (setstrdec env plstrdec :: ptstrdecs))
                                    nil 
                                    plstrdecs2
         in
             PTSTRUCTLOCAL(ptstrdecs1,ptstrdecs2,loc)
         end
   end
 and setstrexp env plstrexp =
     case plstrexp of
         PLSTREXPBASIC(plstrdecs,loc) =>
         let
             val ptstrdecs =  foldr (fn (plstrdec,ptstrdecs) => 
                                        (setstrdec env plstrdec :: ptstrdecs))
                                    nil 
                                    plstrdecs
         in
            PTSTREXPBASIC(ptstrdecs,loc)
         end
       | PLSTRID(x) => PTSTRID(x)
       | PLSTRTRANCONSTRAINT(plstrexp,plsigexp,loc) =>
         let
             val ptstrexp = setstrexp env plstrexp
             val ptsigexp = setsigexp env plsigexp
         in 
             PTSTRTRANCONSTRAINT(ptstrexp,ptsigexp,loc)
         end
       | PLSTROPAQCONSTRAINT(plstrexp,plsigexp,loc) =>
         let
             val ptstrexp = setstrexp env plstrexp
             val ptsigexp = setsigexp env plsigexp
         in 
             PTSTROPAQCONSTRAINT(ptstrexp,ptsigexp,loc)
         end
       | PLFUNCTORAPP(string,plstrexp,loc) =>
         let
             val ptstrexp = setstrexp env plstrexp
         in
             PTFUNCTORAPP(string,ptstrexp,loc)
         end
       | PLSTRUCTLET(plstrdecs,plstrexp,loc) =>
         let
             val ptstrdecs =  foldr (fn (plstrdec,ptstrdecs) => 
                                        (setstrdec env plstrdec :: ptstrdecs))
                                    nil 
                                    plstrdecs
             val ptstrexp = setstrexp env plstrexp
         in 
             PTSTRUCTLET(ptstrdecs,ptstrexp,loc)
         end

 and setsigexp env plsigexp =
     case plsigexp of
         PLSIGEXPBASIC(plspec,loc) => PTSIGEXPBASIC(setspec env plspec,loc)
       | PLSIGID(x) => PTSIGID(x)
       | PLSIGWHERE(plsigexp,rlstn,loc) =>
         PTSIGWHERE(setsigexp env plsigexp,rlstn,loc)
 and setspec env plspec = 
     case plspec of
         PLSPECVAL(x) => PTSPECVAL(x)
       | PLSPECTYPE(x) => PTSPECTYPE(x)
       | PLSPECTYPEEQUATION (x) => PTSPECTYPEEQUATION (x)
       | PLSPECEQTYPE(x) => PTSPECEQTYPE(x)
       | PLSPECDATATYPE(x) => PTSPECDATATYPE(x)
       | PLSPECREPLIC(x) => PTSPECREPLIC(x)
       | PLSPECEXCEPTION(x) => PTSPECEXCEPTION(x)
       | PLSPECSTRUCT (stringPlsigexpList, loc) =>
           PTSPECSTRUCT(map (fn (string,plsigexp) => (string, setsigexp env plsigexp)) stringPlsigexpList,
                        loc)
       | PLSPECINCLUDE(plsigexp,loc) => PTSPECINCLUDE(setsigexp env plsigexp,loc)
       | PLSPECSEQ (plspec1, plspec2, loc) => PTSPECSEQ (setspec env plspec1, setspec env plspec2, loc)
       | PLSPECSHARE(plspec, patpathList, loc) => PTSPECSHARE(setspec env plspec, patpathList, loc)
       | PLSPECSHARESTR(plspec, patpathList, loc) => PTSPECSHARESTR(setspec env plspec, patpathList, loc)
       | PLSPECEMPTY => PTSPECEMPTY

 and settopdec env topdec = 
     case topdec of 
         PLTOPDECSTR(plstrdec,loc) => PTTOPDECSTR(setstrdec env plstrdec,loc)
       | PLTOPDECSIG(plsigdecs,loc) => PTTOPDECSIG(map (fn (sigid,plsigexp) => 
                                                           (sigid,setsigexp env plsigexp))
                                                       plsigdecs,
                                                       loc)
       | PLTOPDECFUN(plfunbinds,loc) => 
         PTTOPDECFUN(map (
                          fn (funid,strid,argSigexp,strexp,loc) => 
                             (funid,strid,setsigexp env argSigexp,setstrexp env strexp,loc)
                          ) 
                         plfunbinds,
                         loc
                         )
       | PLTOPDECIMPORT(import,loc) => PTTOPDECIMPORT(setspec env import,loc)
       | PLTOPDECEXPORT(export,loc) => PTTOPDECEXPORT(setspec env export,loc)

end
end
