(**
 * signature check for module.
 * @copyright (c) 2006, Tohoku University.
 * @author Liu Bochao
 * @version $Id: signatureCheck.sml,v 1.117 2007/02/28 15:31:26 katsu Exp $
 *)
structure SigCheck =
struct 
local

  structure TU = TypesUtils
  structure SU = SigUtils
  structure TCU = TypeContextUtils
  structure E = TypeInferenceError
  structure TU = TypesUtils
  structure T = Types
  fun printTy ty = print (TypeFormatter.tyToString ty ^ "\n")  
in

  fun freshTyConIdSetInSig (tyConIdSet, Env)  =
    let
      val Env = SU.freshRefAddressOfTyConInEnv Env
      val (tyConIdSubst,tyConIdSet) = 
          ID.Set.foldr 
             (fn (i,(tyConIdSubst,newTyConIdSet)) => 
                let
                  val newTyConId = T.newTyConId()
                in
                  (
                   ID.Map.insert(tyConIdSubst, i, newTyConId),
                   ID.Set.add(newTyConIdSet, newTyConId)
                   )
                end
            )
            (ID.Map.empty,ID.Set.empty)
            tyConIdSet
      val (visited, Env) = TCU.substTyConIdInEnv ID.Set.empty tyConIdSubst Env             
    in
      (tyConIdSet, Env)
    end

  fun sigTyNameRename (tyConIdSet,Env) =
      let
        val (tyConIdSet, Env) = freshTyConIdSetInSig (tyConIdSet,Env)
      in
        Env
      end

  (* functor is generative.
   * generate new id for flexible type name
   * generate new exception Tag for bound exnTag
   *)
  fun makeGenerativeFunctorSig {
                                exnTagSet = exnT,
                                tyConIdSet = T, 
                                func = {
                                        arg = E, 
                                        body = {constrained = (T1, E1),
                                                unConstrained = bareResultEnv}
                                        }
                           }
      =
      let
        val exnTagSubst = 
            ISet.foldr 
              (fn (i, exnTagSubst) => IEnv.insert(exnTagSubst, i, T.newExnTag()))
              IEnv.empty
              exnT
        val tyConIdSubst =
            ID.Set.foldr 
              (fn (i,tyConIdSubst) => ID.Map.insert(tyConIdSubst, i, T.newTyConId()))
              ID.Map.empty
              T1
        val E = SU.freshRefAddressOfTyConInEnv E
        val resultEnv  = SU.freshRefAddressOfTyConInEnv E1
        val bareResultEnv as (te,ve,se) = SU.freshRefAddressOfTyConInEnv bareResultEnv
        val (visited, resultEnv as (te,ve,se)) = TCU.substTyConIdInEnv ID.Set.empty tyConIdSubst resultEnv
      in
        (exnTagSubst, E, resultEnv, bareResultEnv)
      end

  fun computeBoxedKindInEnv (E as (TE,VE,SE)) = 
      let
        fun computeBoxedKindInTE TE =
            SEnv.foldli (fn (tyCon,tyBindInfo,(tyConSubst,boxedKindSubst)) =>
                            case tyBindInfo of
                              T.TYCON (tycon as {id, datacon,...}) =>
                              let
                                val newBoxedKind = TU.calcTyConBoxedKind (!datacon)
                                val _ = #boxedKind tycon:= newBoxedKind
                              in
                                (
                                 ID.Map.insert(tyConSubst,id,T.TYCON tycon),
                                 ID.Map.insert(boxedKindSubst,id, !(#boxedKind tycon))
                                 )
                              end
                            | T.TYSPEC({spec = {id, boxedKind,...}, impl}) =>
                              (
                               tyConSubst,
                               ID.Map.insert(boxedKindSubst,id,boxedKind)
                               )
                            | T.TYFUN({name, tyargs, body = T.ALIASty(aliasTy,actTy)}) =>
                              let
                                val boxedKindValue = TU.boxedKindOfType actTy
                                val (id,tyCon) = 
                                    case aliasTy of
                                      T.CONty{tyCon= tyCon as {id,boxedKind,...},...} => 
                                      let
                                        val _ = boxedKind := boxedKindValue
                                      in
                                        (id,tyCon)
                                      end
                                    | _ => raise Control.Bug "illegal ALIASty"

                              in
                                (
                                 ID.Map.insert(tyConSubst,id,T.TYCON tyCon),
                                 ID.Map.insert(boxedKindSubst,id,boxedKindValue)
                                 )
                              end
                             | _ => (tyConSubst,boxedKindSubst))
                        (ID.Map.empty,ID.Map.empty)
                        TE
        fun computeBoxedKindInSE (T.STRUCTURE  SECont) =
            SEnv.foldli (fn (str,{env = (TE,VE,SE),...},(tyConSubst,boxedKindSubst)) =>
                            let
                              val (tyConSubst1,boxedKindSubst1) = computeBoxedKindInTE TE
                              val (tyConSubst2,boxedKindSubst2) = computeBoxedKindInSE SE
                            in
                              (ID.Map.unionWith #1 (tyConSubst,
                                                  ID.Map.unionWith #1 (tyConSubst1,
                                                                     tyConSubst2)
                                                  ),
                               ID.Map.unionWith #1 (boxedKindSubst,
                                                  ID.Map.unionWith #1 (boxedKindSubst1,
                                                                     boxedKindSubst2)
                                                  )
                               )
                            end
                        )
                        (ID.Map.empty, ID.Map.empty)
                        SECont 
        val (tyConSubst1,boxedKindSubst1) = computeBoxedKindInTE TE
        val (tyConSubst2,boxedKindSubst2) = computeBoxedKindInSE SE
      in
        (ID.Map.unionWith #1 (tyConSubst1,tyConSubst2),
         ID.Map.unionWith #1 (boxedKindSubst1,boxedKindSubst2))
      end                        

  fun computeBoxedKindSubst (sigEnv as (TE,VE,SE), strEnv as (TE1,VE1,SE1)) = 
      let
        fun computeBoxedKindTE (sigTE, strTE) =
            SEnv.foldli (fn (tyCon, tyBindInfo, (tyConSubst, boxedKindSubst)) =>
                            case tyBindInfo of
                              T.TYCON (tycon as {name,strpath,abstract,
                                                 tyvars,id,eqKind,
                                                 boxedKind = ref T.GENERICty,
                                                 datacon = ref data})
                              =>
                              (
                               case SEnv.find(strTE, tyCon) of
                                 NONE => (tyConSubst, boxedKindSubst) 
                               | SOME tyBindInfo1 =>
                                 let
                                     val boxedKind = TU.boxedKindOfTyBindInfo tyBindInfo1
                                     val _ = #boxedKind tycon:= boxedKind
                                 in
                                   (
                                    ID.Map.insert(tyConSubst, id, T.TYCON tycon),
                                    ID.Map.insert(boxedKindSubst, id, boxedKind)
                                    )
                                 end
                              )
                            | T.TYSPEC({spec = {name, id, boxedKind = T.GENERICty, ...},impl}) =>
                              (
                               case SEnv.find(TE1,tyCon) of
                                 NONE => (tyConSubst, boxedKindSubst)
                               | SOME tyBindInfo1 =>
                                 let
                                   val boxedKind = TU.boxedKindOfTyBindInfo tyBindInfo1
                                 in
                                   (
                                    tyConSubst,
                                    ID.Map.insert(boxedKindSubst, id, boxedKind)
                                    )
                                 end
                               )
                            | T.TYFUN({name, tyargs, 
                                       body = 
                                       T.ALIASty(
                                           T.CONty{tyCon= tyCon as{id,
                                                                   boxedKind = ref T.GENERICty,...},...},
                                           actTy)
                                       }
                                    ) 
                              =>
                              (case SEnv.find(TE1,name) of
                                 NONE => (tyConSubst, boxedKindSubst)
                               | SOME tyBindInfo1 =>
                                 let
                                   val boxedKind = TU.boxedKindOfTyBindInfo tyBindInfo1
                                   val _ = #boxedKind tyCon := boxedKind
                                 in
                                   (
                                    ID.Map.insert(tyConSubst, id, T.TYCON tyCon),
                                    ID.Map.insert(boxedKindSubst, id, boxedKind)
                                    )
                                 end)
                            | _ => (tyConSubst,boxedKindSubst))
                        (ID.Map.empty, ID.Map.empty)
                        sigTE
        fun computeBoxedKindSE (T.STRUCTURE SECont, T.STRUCTURE SECont1) =
            SEnv.foldli (fn (
                             strid,
                             {env = (subTE,subVE,subSE),...}, 
                             (tyConSubst,boxedKindSubst)
                             ) =>
                            case SEnv.find(SECont1,strid) of
                              NONE => (tyConSubst,boxedKindSubst)
                            | SOME {env = (subTE1,subVE1,subSE1),...} =>
                              let
                                val (tyConSubst1,boxedKindSubst1) = computeBoxedKindTE (subTE,subTE1)
                                val (tyConSubst2,boxedKindSubst2) = computeBoxedKindSE (subSE,subSE1)
                              in
                                (
                                 ID.Map.unionWith 
                                  #1 
                                  (ID.Map.unionWith #1 (tyConSubst2,tyConSubst1),
                                   tyConSubst),
                                  ID.Map.unionWith 
                                    #1 
                                    (ID.Map.unionWith #1 (boxedKindSubst2,boxedKindSubst1),
                                     boxedKindSubst)
                                    )
                              end
                                )
                        (ID.Map.empty,ID.Map.empty)
                        SECont 
        val (tyConSubst1, boxedKindSubst1) = computeBoxedKindTE (TE,TE1)
        val (tyConSubst2, boxedKindSubst2) = computeBoxedKindSE (SE,SE1)
      in
        (
         ID.Map.unionWith #1 (tyConSubst1, tyConSubst2),
         ID.Map.unionWith #1 (boxedKindSubst1, boxedKindSubst2)
         )
      end                        

  fun computeTyBindInfoEquationsTE (tyConEnv, sigTyConEnv) tyBindInfoEquations =
    SEnv.foldli (fn (tyConName, sigTyBindInfo, tyBindInfoEquations) =>
                    case SEnv.find(tyConEnv, tyConName) of
                      SOME strTyBindInfo => 
                      (sigTyBindInfo, strTyBindInfo) :: tyBindInfoEquations
                    | _ => raise E.unboundTyconInSigMatch {name = tyConName })
                tyBindInfoEquations
                sigTyConEnv

  fun computeTyBindInfoEquationsSE 
      (T.STRUCTURE strEnvCont1, T.STRUCTURE sigStrEnvCont1) 
      tyBindInfoEquations =
    SEnv.foldli (fn (
                     strName,
                     {env = (sigTyConEnv, _, sigStrEnv), ...},
                     tyBindInfoEquations
                     ) =>
                    case SEnv.find(strEnvCont1, strName) of
                      SOME {env = (tyConEnv2, _, strEnv2), ...} =>
                      computeTyBindInfoEquationsSE
                        (strEnv2, sigStrEnv)
                        (
                         computeTyBindInfoEquationsTE 
                           (tyConEnv2, sigTyConEnv) 
                           tyBindInfoEquations
                           )
                    | _ => raise E.unboundStructureInSigMatch {strName = strName }
                                 )
                tyBindInfoEquations
                sigStrEnvCont1
                
  fun computeTyBindInfoEquationsEnv ((tyConEnv, varEnv, strEnv), 
                                    (sigTyConEnv, sigVarEnv, sigStrEnv)) =
    computeTyBindInfoEquationsSE (strEnv, sigStrEnv)
                                 (
                                  computeTyBindInfoEquationsTE 
                                    (tyConEnv, sigTyConEnv) 
                                    nil
                                 )


  fun equivTy (ty1, ty2)  =
    let
      fun eq btvEqEnv (ty1, ty2) =
        case (ty1, ty2) of
          (T.ERRORty, _) => true
        | ( _, T.ERRORty) => true 
        | (T.DUMMYty _, _) => raise Control.Bug "dummyty in equivty"
        | (_, T.DUMMYty _) => raise Control.Bug "dummyty in equivty"
        | (T.TYVARty (ref (T.SUBSTITUTED ty1)), _) => eq btvEqEnv (ty1, ty2)
        | (_, T.TYVARty (ref (T.SUBSTITUTED ty2))) => eq btvEqEnv (ty1, ty2)
        | (T.TYVARty _, _) => raise Control.Bug "TYVARty in equivty"
        | (_, T.TYVARty _) => raise Control.Bug "TYVARty in equivty"
        | (T.BOUNDVARty i1, T.BOUNDVARty i2) => 
            (case IEnv.find(btvEqEnv, i1) of
               NONE => raise Control.Bug "btv not found in equivty"
             | SOME i1 =>  i1 = i2)
        | (T.ALIASty (ty11,ty12), _) =>
          eq btvEqEnv (ty12,ty2)
        | (_, T.ALIASty(ty21,ty22)) =>
          eq btvEqEnv (ty1,ty22)
        | (T.ABSSPECty(ty11,_),ty2) => eq btvEqEnv (ty11, ty2)
        | (ty1, T.ABSSPECty (ty21,_)) => eq btvEqEnv (ty1, ty21)
        | (T.SPECty(ty11),ty2) => eq btvEqEnv (ty11, ty2)
        | (ty1, T.SPECty (ty21)) => eq btvEqEnv (ty1, ty21)
        | (T.FUNMty (domTyList1, ranTy1), T.FUNMty (domTyList2, ranTy2)) =>
          if length domTyList1 = length domTyList2 then
            foldl 
             (fn ((ty1,ty2), bool) => eq btvEqEnv (ty1,ty2) andalso bool)
             (eq btvEqEnv (ranTy1,ranTy2))
             (ListPair.zip(domTyList1, domTyList2))
          else false
        | (T.RECORDty tyFields1, T.RECORDty tyFields2) =>
             (SEnv.foldli (fn (label, _,  bool) =>
                           case SEnv.find(tyFields1, label) of
                             NONE => false
                           | SOME _ => bool)
              true
              tyFields2)
             andalso
             (SEnv.foldli (fn (label, ty1,  bool) =>
                           case SEnv.find(tyFields1, label) of
                             NONE => false
                           | SOME ty2 => eq btvEqEnv (ty1, ty2) andalso bool)
              true
              tyFields2)
        | (T.CONty {tyCon ={id=id1,...}, args = args1}, T.CONty {tyCon={id=id2,...}, args = args2}) =>
             ID.eq(id1, id2)
             andalso
             List.length args1 = List.length args2
             andalso
             foldl 
             (fn ((ty1,ty2), bool) => eq btvEqEnv (ty1,ty2) andalso bool)
             true
             (ListPair.zip(args1,args2))
        | (T.POLYty {boundtvars=btvEnv1, body=ty1},T.POLYty {boundtvars=btvEnv2, body=ty2}) =>
             IEnv.numItems btvEnv1 = IEnv.numItems btvEnv2
             andalso
             let
               val btvids1 = IEnv.listKeys btvEnv1
               val btvids2 = IEnv.listKeys btvEnv2
               val newBtvEnv = foldr (fn ((id1,id2), newBtvEnv) =>
                                      IEnv.insert(newBtvEnv, id1, id2))
                                     btvEqEnv
                                     (ListPair.zip (btvids1, btvids2))
             in
               eq newBtvEnv (ty1,ty2)
             end
        | (T.BOXEDty, _) => raise Control.Bug "BOXEDty in equivty"
        | (_, T.BOXEDty) => raise Control.Bug "BOXEDty in equivty"
        | (T.INDEXty _, _) => raise Control.Bug "INDEXty in equivty"
        | (_,T.INDEXty _) => raise Control.Bug "INDEXty in equivty"
        | (T.BMABSty _,_) => raise Control.Bug "BMABSty in equivty"
        | (_, T.BMABSty _) => raise Control.Bug "BMABSty in equivty"
        | (T.BITMAPty _,_) => raise Control.Bug "MITMAPty in equivty"
        | (_, T.BITMAPty _) => raise Control.Bug "MITMAPty in equivty"
        | _ => false
    in
      eq IEnv.empty (ty1, ty2)
    end

  (* according to section 4.4, type function equality does not 
   * invlove the equality attribute of type variable
   *)
  fun equivTyFcn (tyargs1, body1) (tyargs2, body2) =
      let
        val tyargsList1 = IEnv.listItemsi tyargs1
        val tyargsList2 = IEnv.listItemsi tyargs2
        val (substEnv1, substEnv2) =
            ListPair.foldl
              (fn ((x,_),(y,_),(substEnv1,substEnv2)) =>
                 let
                   val tyvarTy = T.newty {recKind = T.UNIV, eqKind = T.NONEQ,tyvarName = NONE}
(*
 Ohroi: Dec 5, 2006.
                    val tyvarTy = T.TYVARty (ref (T.TVAR {
                                                          lambdaDepth = T.infiniteDepth,
                                                          id = T.nextTid(),
                                                          recKind = T.UNIV,
                                                          eqKind = T.NONEQ,
                                                          tyvarName = NONE
                                                          }
                                                )
                                           )
*)
                  in 
                    (
                     IEnv.insert(substEnv1, x, tyvarTy),
                     IEnv.insert(substEnv2, y, tyvarTy)
                     )
                  end
                    )
              (IEnv.empty,IEnv.empty)
              (tyargsList1,tyargsList2)
        val body1 = TU.substBTvar substEnv1 body1
        val body2 = TU.substBTvar substEnv2 body2
        val _ = Unify.unify [(body1, body2)]
      in
        true 
      end
        handle Unify.Unify => false

  fun equivIdstate (idstate1, idstate2) =
    case (idstate1, idstate2) of
      (
       T.CONID {name = name1, funtyCon = bool1, ty = ty1, tyCon={id=id1,...},...},
       T.CONID {name = name2, funtyCon = bool2, ty = ty2, tyCon={id=id2,...},...}
       ) =>
      bool1 = bool2
      andalso 
      name1 = name2 
      andalso 
      ID.eq(id1, id2)
      andalso
      equivTy (ty1, ty2)
    | (_,_) => raise Control.Bug "equivIdstate: not CONID occurring in datacon"

  fun equivVarEnv (varEnv1, varEnv2) =
    let
      fun redundantVarEnv varEnv1 varEnv2 =
          SEnv.filteri (fn (name,idstate) =>
                           not (SEnv.inDomain(varEnv2,name)))
                       varEnv1
      fun redundantConstructor varEnv = 
          SEnv.foldli (fn (name,_,errStr) =>
                          name ^ " " ^ errStr)
                      ""
                      varEnv
      val num1 = SEnv.numItems(varEnv1)
      val num2 = SEnv.numItems(varEnv2)
      val itemsNumEqual = 
          if num1 = num2 then true
          else
            if num1 > num2 then
              raise E.RedunantConstructorInSignatureInSigMatch 
                      {Cons = (redundantConstructor (redundantVarEnv varEnv1 varEnv2))}
            else
                raise E.RedunantConstructorInStructureInSigMatch 
                        {Cons = (redundantConstructor (redundantVarEnv varEnv2 varEnv1))}
      val items1 = SEnv.listItemsi varEnv1
      val items2 = SEnv.listItemsi varEnv1
      fun checkEquiv (nil,nil) = true
        | checkEquiv ((name1,idstate1)::t1, (name2,idstate2)::t2) = 
          if name1 = name2 andalso equivIdstate (idstate1,idstate2) then
            checkEquiv (t1,t2)
          else false
        | checkEquiv (_,_) = raise Control.Bug "checkEquiv:items number not equal"
    in
      itemsNumEqual andalso checkEquiv (items1, items2)
    end

  fun substTyConInTyBindEqsDomain tyConSubst tyConEqs =
      (map (fn (tyBindInfo1, tyBindInfo2) => 
             let
               val (visited,tyBindInfo1) = 
                   TCU.substTyConInTyBindInfo ID.Set.empty tyConSubst tyBindInfo1
             in
               (tyBindInfo1,tyBindInfo2)
             end)
         tyConEqs)
    handle TCU.ExTySpecInstantiatedWithNonEqTyBindInfo name =>
           raise E.EqErrorInSigMatch {tyConName=name}


  fun unifyTyConId tyConIdSet nil tyConIdSubst = tyConIdSubst
    | unifyTyConId tyConIdSet ((sigTyBindInfo, strTyBindInfo)::rest) tyConIdSubst =
      (case (sigTyBindInfo, strTyBindInfo) of
         (T.TYSPEC {spec = {id=id1, name = name1, eqKind = eqKind1, 
                            tyvars = tyvars1,strpath = strpath,...},...}, 
          T.TYCON {id=id2, name = name2, eqKind = ref eqKind2, tyvars = tyvars2, ...}) => 
         if List.length tyvars1 <> List.length tyvars2 then
           raise E.ArityMismatchInSigMatch {tyConName = name2}
         else
           if eqKind1 = T.EQ andalso eqKind2 = T.NONEQ then
             raise E.EqErrorInSigMatch {tyConName=name2}
           else
             unifyTyConId tyConIdSet rest (ID.Map.insert(tyConIdSubst, id1, id2))
       | (T.TYCON {name = name, tyvars = tyvars1, id = id1, eqKind = ref eqKind1, ...}, 
          T.TYCON {tyvars = tyvars2, id = id2, eqKind = ref eqKind2, ...}) =>
         if ID.Set.member(tyConIdSet, id1) then
           (* flexible tyConId *)
           if List.length tyvars2 <> List.length tyvars1 then
             raise E.ArityMismatchInSigMatch {tyConName=name}
           else if eqKind1 = T.EQ andalso eqKind2 = T.NONEQ then
             raise E.EqErrorInSigMatch {tyConName=name}
           else unifyTyConId tyConIdSet rest (ID.Map.insert(tyConIdSubst, id1, id2))
         else
           (* non-flexible tyConId *)
           if ID.eq(id1, id2) andalso List.length tyvars2 = List.length tyvars1 
                        andalso eqKind1 = eqKind2 
           then
             unifyTyConId tyConIdSet rest tyConIdSubst
           else
             raise E.TyConMisMatchInSigMatch {tyConName=name}
       | (T.TYSPEC {spec ={name, id = id1, tyvars = tyvars1, eqKind = eqKind1,...},...},
          T.TYSPEC {spec ={id = id2, tyvars = tyvars2, eqKind = eqKind2,...},...}) =>
         if List.length tyvars2 <> List.length tyvars1 then
           raise E.ArityMismatchInSigMatch {tyConName = name}
         else if eqKind1 = T.EQ andalso eqKind2 = T.NONEQ then
           raise E.EqErrorInSigMatch {tyConName=name}
         else
           unifyTyConId tyConIdSet rest (ID.Map.insert(tyConIdSubst, id1, id2))
       | (T.TYCON {id=id1, eqKind = ref eqKind1, tyvars = tyvars1, ...},
          T.TYSPEC {spec = {id=id2, name, eqKind = eqKind2, 
                            tyvars = tyvars2,...},...}
          ) => 
         if !Control.doLinking then
             if List.length tyvars1 <> List.length tyvars2 then
                 raise E.ArityMismatchInSigMatch {tyConName = name}
             else
                 if eqKind2 = T.EQ andalso eqKind1 = T.NONEQ then
                     raise E.EqErrorInSigMatch {tyConName=name}
                 else
                     unifyTyConId tyConIdSet rest (ID.Map.insert(tyConIdSubst, id1, id2))
         else raise Control.Bug "only occurs at unclosed objects linking"
       | _ => unifyTyConId tyConIdSet rest tyConIdSubst)
      
  fun substTyConIdInTyBindInfoEqsDomain tyConIdSubst tyBindInfoEqs =
    map (
         fn (tyBindInfo1, tyBindInfo2) => 
            let
                val (visited, tyBindInfo1) = 
                    TCU.substTyConIdInTyBindInfo  ID.Set.empty tyConIdSubst tyBindInfo1
            in
                (tyBindInfo1, tyBindInfo2)
            end
        )
    tyBindInfoEqs

  fun unifyTySpec nil tyConSubst = tyConSubst
    | unifyTySpec ((tyBindInfo1, tyBindInfo2)::rest) (tyConSubst:T.tyBindInfo ID.Map.map) =
      case (tyBindInfo1, tyBindInfo2) of
          (T.TYSPEC {spec = {id=id1, name = name1, eqKind = eqKind1, 
                             tyvars = tyvars1, boxedKind = requiredBoxedKind, ...},...}, 
           T.TYCON {id=id2, name = name2, eqKind = ref eqKind2, 
                    tyvars = tyvars2, boxedKind = objectBoxedKind, ...}) => 
          (
           TCU.kindCheckAtLinking {tyConName = name1,
                                   requiredKind = requiredBoxedKind,
                                   objectKind = !objectBoxedKind};
           if List.length tyvars1 <> List.length tyvars2 then
               raise E.ArityMismatchInSigMatch {tyConName = name2}
           else if eqKind1 = T.EQ andalso eqKind2 = T.NONEQ then
               raise E.EqErrorInSigMatch {tyConName=name2}
           else if ID.eq(id1, id2) then
               unifyTySpec rest
                           (ID.Map.insert(tyConSubst, id1, tyBindInfo2))
           else raise E.TyConMisMatchInSigMatch {tyConName=name2}
          )
        | (T.TYSPEC {spec = {name = name1, id = id1, tyvars = tyvars1, 
                             eqKind = eqKind, boxedKind = requiredBoxedKind,...},...} ,
           T.TYFUN  (tyFun as {name = name2, tyargs = tyargs2 , body = body2}) ) => 
          (
           TCU.kindCheckAtLinking {tyConName = name1,
                                   requiredKind = requiredBoxedKind,
                                   objectKind = TU.boxedKindOfType body2};
           if eqKind = T.EQ andalso not (TU.admitEqTyFun tyFun) then
               raise E.EqErrorInSigMatch {tyConName=name2}
           else if List.length tyvars1 <> IEnv.numItems(tyargs2) then
               raise E.ArityMismatchInSigMatch {tyConName=name1}
           else unifyTySpec rest (ID.Map.insert(tyConSubst, id1, tyBindInfo2))
          )
        | (T.TYSPEC {spec = {name = name1, id = id1, 
                             tyvars = tyvars1, eqKind = eqKind1,
                             boxedKind = requiredBoxedKind,...} ,
                     ...},
           T.TYSPEC {spec = {name = name2, 
                             id = id2, 
                             tyvars = tyvars2, 
                             eqKind = eqKind2,
                             boxedKind = objectBoxedKind,
                             strpath = strpath2},
                     impl = impl2}) 
          =>
          if List.length tyvars1 <> List.length tyvars2 then
              raise E.ArityMismatchInSigMatch {tyConName=name2}
          else if eqKind1 = T.EQ  andalso eqKind2 = T.NONEQ then
              raise E.EqErrorInSigMatch {tyConName=name2}
          else if not (ID.eq(id1, id2)) then
              raise E.TyConMisMatchInSigMatch {tyConName = name1}
          else let
                  val tyBindInfo2 = 
                      if !Control.doLinking = true then
                          T.TYSPEC {spec = {name = name2, 
                                            id = id2, 
                                            tyvars = tyvars2, 
                                            eqKind = eqKind2,
                                            boxedKind = 
                                            TCU.unifyBoxedKind {tyConName = name2,
                                                                requiredKind = requiredBoxedKind,
                                                                objectKind = objectBoxedKind},
                                            strpath = strpath2},
                                    impl = impl2}
                      else tyBindInfo2
              in
                  unifyTySpec rest (ID.Map.insert(tyConSubst, id1, tyBindInfo2))
              end
        | _ => unifyTySpec rest tyConSubst
      
  fun unifyTyConAndTyFun nil tyConSubst = tyConSubst
    | unifyTyConAndTyFun ((tyBindInfo1, tyBindInfo2)::rest) tyConSubst =
      case (tyBindInfo1, tyBindInfo2) of
        (T.TYCON {name, tyvars = tyvars1, id = id1, eqKind = ref eqKind1, 
                datacon = datacon1 as ref varEnv1, strpath = strpath, ...}, 
         T.TYCON {tyvars = tyvars2, id = id2, eqKind = ref eqKind2, 
                datacon = datacon2 as ref varEnv2, ...}) =>
        if List.length tyvars1 <> List.length tyvars2 then
          raise E.ArityMismatchInSigMatch {tyConName=name}
        else if eqKind1 = T.EQ andalso eqKind2 = T.NONEQ then
          raise E.EqErrorInSigMatch {tyConName=name}
        else if not (ID.eq(id1, id2)) then
          raise E.TyConMisMatchInSigMatch {tyConName=name}
        else if not (equivVarEnv (varEnv1, varEnv2)) then
          raise E.TyConMisMatchInSigMatch {tyConName=name}
        else 
          unifyTyConAndTyFun
            (substTyConInTyBindEqsDomain (ID.Map.singleton(id1,tyBindInfo2)) rest)
            (ID.Map.insert(tyConSubst, id1, tyBindInfo2))
      | (T.TYCON {name = name1, tyvars = tyvars1, id = id1, eqKind = ref eqKind1, 
                  datacon = ref varEnv1, ...}, 
         T.TYFUN {name = name2, tyargs = tyargs2 , body = body2}) 
        =>
        ( case (TU.extractAliasTyImpl body2) of
            T.CONty({tyCon = {name = name3,
                            tyvars = tyvars3, 
                            id = id3, eqKind = ref eqKind3,
                            datacon = ref varEnv3,...},...})
            => 
            if List.length tyvars1 <> List.length tyvars3 then
              raise E.ArityMismatchInSigMatch {tyConName=name2}
            else if eqKind1 = T.EQ andalso eqKind3 = T.NONEQ then
              raise E.EqErrorInSigMatch {tyConName=name2}
            else if not (ID.eq(id1, id3)) then
              raise E.TyConMisMatchInSigMatch {tyConName=name2}
            else if not (equivVarEnv (varEnv1, varEnv3)) then
              raise E.TyConMisMatchInSigMatch {tyConName=name2}
            else 
              unifyTyConAndTyFun rest tyConSubst
          | _ => 
            raise E.TyConMisMatchInSigMatch {tyConName = name2}
        )
      | (T.TYFUN  ( {name = name1, tyargs = tyargs1 , body = body1}),
         T.TYFUN  ( {name = name2, tyargs = tyargs2 , body = body2}))
        =>
        if IEnv.numItems(tyargs1) <> IEnv.numItems(tyargs2) then
          raise E.ArityMismatchInSigMatch {tyConName = name1 ^ " " ^ name2}
        else
          if equivTyFcn (tyargs1, body1) (tyargs2,body2) then
            unifyTyConAndTyFun rest tyConSubst 
          else
            raise E.SharingTypeMismatchInSigMatch{tyConName1 = name1, 
                                                  tyConName2 = name2}
                  
      | (T.TYFUN  ( {name = name1, tyargs = tyargs1 , body = body1}),
         T.TYCON {name = name2, tyvars=tyvars2, id = id2, eqKind = ref eqKind2, 
                datacon = datacon2 as ref varEnv2, ...})
        => 
        (
         case (TU.extractAliasTyImpl body1) of
           T.CONty({tyCon = {name = name3, tyvars = tyvars3,
                             id = id3, eqKind = ref eqKind3,
                             datacon = ref varEnv3,...},...})
           => 
           if List.length tyvars2 <> List.length tyvars2 then
             raise E.ArityMismatchInSigMatch {tyConName=name2}
           else if eqKind2 = T.EQ andalso eqKind3 = T.NONEQ then
             raise E.EqErrorInSigMatch {tyConName=name2}
           else if not (ID.eq(id2, id3)) then
             raise E.TyConMisMatchInSigMatch {tyConName=name2}
           else if not (equivVarEnv (varEnv2, varEnv3)) then
             raise E.TyConMisMatchInSigMatch {tyConName=name2}
           else 
             unifyTyConAndTyFun rest tyConSubst 
         | _ => 
           raise E.TyConMisMatchInSigMatch {tyConName = name2}
                 )
      | _ => unifyTyConAndTyFun rest tyConSubst 
             
  fun unifyTyBindInfo nil tyConSubst = tyConSubst
    | unifyTyBindInfo (equations as (tyBindInfo1, tyBindInfo2)::rest) tyConSubst =
      let
        val tySpecSubst = unifyTySpec equations ID.Map.empty
        val newEquations = substTyConInTyBindEqsDomain tySpecSubst equations
      in
        unifyTyConAndTyFun newEquations tySpecSubst
      end

  fun checkInstTy name (strTy,sigTy) =
      let
        val strTy = TU.freshInstTy strTy
        val sigTy = TU.freshRigidInstTy sigTy
      in
           Unify.unify [(strTy, sigTy)]
      end
        handle Unify.Unify => 
               (raise E.InstanceCheckInSigMatch
                       {tyConName=name, ty1 = strTy, ty2 = sigTy})

  fun checkInstVarEnv (strVE, sigVE) =
      SEnv.mapi
        (fn (name, sigIdState) =>
            case sigIdState of
              T.VARID { ty = ty2, ...} =>
              (
               case SEnv.find(strVE, name) of
                 SOME (T.VARID{ ty = ty1, ...}) =>
                 checkInstTy name (ty1,ty2)
               | SOME (strIdState as T.CONID{ ty = ty1, ...}) =>
                 checkInstTy name (ty1,ty2)
               | NONE => raise E.unboundVarInSigMatch {varName = name}
               | _    => raise Control.Bug "checkInstVarEnv:Not variable or constructor(1)"
                               )
            | T.CONID { ty = ty2, ...} =>
              (case SEnv.find(strVE, name) of
                 SOME (T.VARID _) => raise E.DataConRequiredInSigMatch {tyConName=name}
               | SOME (T.CONID {ty = ty1, ...}) => 
                 checkInstTy name (ty1,ty2)
               | NONE => raise E.unboundVarInSigMatch { varName = name}
               | _    => raise Control.Bug "checkInstVarEnv:Not variable or constructor(2)"
                               )
            | _ => raise Control.Bug "checkInstVarEnv:Not variable or constructor(3)"
        )
        sigVE
        
  fun checkInstStrEnv (T.STRUCTURE strSECont, T.STRUCTURE sigSECont) =
      SEnv.mapi
      (fn (name, {env = (subSigTE, subSigVE, subSigSE), 
                  id = strId,
                  name = strName,
                  strpath = strpath}) => 
          case SEnv.find(strSECont,name) of
            SOME {env = (_, subStrVE, subStrSE), ...} =>
            (checkInstVarEnv(subStrVE, subSigVE);
             checkInstStrEnv(subStrSE, subSigSE);
             ())
          | NONE => raise E.unboundStructureInSigMatch {strName = name}
       )
      sigSECont

  fun checkInstEnv ((strTE, strVE, strSE), (sigTE, sigVE, sigSE)) =
      (checkInstVarEnv(strVE, sigVE);
       checkInstStrEnv(strSE, sigSE))

  fun transparentSigMatch (Env, sigma) = 
    let
      val (tyConIdSet,sigEnv) = freshTyConIdSetInSig sigma
      (* tyConEqs : [(sigTybindInfo,strTybindInfo),...] *)
      val tyConEqs = computeTyBindInfoEquationsEnv (Env, sigEnv)
      val tyConIdSubst = unifyTyConId tyConIdSet tyConEqs ID.Map.empty
      val tyConEqs = substTyConIdInTyBindInfoEqsDomain tyConIdSubst tyConEqs
      val tyConSubst = unifyTyBindInfo tyConEqs ID.Map.empty
      val (_, sigEnv) = TCU.substTyConIdInEnv ID.Set.empty tyConIdSubst sigEnv
      val (_, sigEnv) = TCU.substTyConInEnv ID.Set.empty tyConSubst sigEnv
      val _ = checkInstEnv (Env, sigEnv)  
      val sigEnv = SU.instStrpathOfStructureInEnv (Env,sigEnv) 
      (* instantiate the followings :
       * 1. Exception tag
       * 2. FFID actual arguments list
       *)
      val sigEnv = SU.instEnvWithExnAndIdState(Env,sigEnv)
    in
      sigEnv
    end
      
  fun opaqueSigMatch (Env, sigma as (_, absSigEnv)) = 
    let
      val (tyConIdSet,sigEnv) = freshTyConIdSetInSig sigma 
      val tyConEqs = computeTyBindInfoEquationsEnv (Env, sigEnv)
      val tyConIdSubst = unifyTyConId tyConIdSet tyConEqs ID.Map.empty
      val tyConEqs = substTyConIdInTyBindInfoEqsDomain tyConIdSubst tyConEqs
      val tyConSubst = unifyTyBindInfo tyConEqs ID.Map.empty
      val (_, sigEnv) = TCU.substTyConIdInEnv ID.Set.empty tyConIdSubst sigEnv
      val (_, sigEnv) = TCU.substTyConInEnv ID.Set.empty tyConSubst sigEnv
      val _ = checkInstEnv (Env, sigEnv)
      (* instantiate the followings :
       * 1. Exception tag
       * 2. FFID actual arguments list
       *)
      val absSigEnv = SU.instEnvWithExnAndIdState(Env, absSigEnv)
      (* instantiate the followings:
       * 1. boxedKind
       * 2. strPath
       * 3. tySpec implemantation field
       *)
(*        val _ = print "\n opaque sig 3 \n"
        val _ = print (Control.prettyPrint (Types.format_Env nil absSigEnv))
        val _ = print "\n ******************* \n"
*)

      val absSigEnv = SU.instTopSigEnv (Env, absSigEnv)
(*        val _ = print "\n inner sig 4 \n"
        val _ = print (Control.prettyPrint (Types.format_Env nil Env))
        val _ = print "\n ******************* \n"

        val _ = print "\n opaque sig 4 \n"
        val _ = print (Control.prettyPrint (Types.format_Env nil absSigEnv))
        val _ = print "\n ******************* \n"
*)
    in
      (absSigEnv, sigEnv)
    end

  (*
   * Env : actual functor argument environment
   * funcSig : functor signature
   * return :
   *   resSigEnv : the instantiated functor body signature
   *   argSigEnv : the instantiated functor argument signature used 
   *               to generate instEnv for functor argument
   *   tyConSubstOnTemplate: remembers the boxedKind instantiated tyCon defined 
   *                         in the functor body
   * 
   *)
  fun functorSigMatch (Env ,functorSig as  {tyConIdSet = tyConIdSet, ...}) 
      =
      let
        (* bareResSigEnv: represents the unconstrained functor body 
         *                We accumulate the tyConSubstOnTemplate to
         *                set the boxkind field
         * resSigEnv : represents the infered environment needed by 
         *             typeinference; it needs to compute the 
         *             boxkind field of tyCon to propogate in typeinference
         *)
        val (exnTagBodySubst, argSigEnv , resSigEnv, bareResSigEnv) = 
            makeGenerativeFunctorSig functorSig
        val (_, boxedKindArgSubst) = computeBoxedKindSubst (argSigEnv, Env)
        val tyConEqs = computeTyBindInfoEquationsEnv (Env, argSigEnv)
        val tyConIdSubst = unifyTyConId tyConIdSet tyConEqs ID.Map.empty
        val tyConEqs = substTyConIdInTyBindInfoEqsDomain tyConIdSubst tyConEqs
        val tyConSubst = unifyTyBindInfo tyConEqs ID.Map.empty
        val (_, argSigEnv) = TCU.substTyConIdInEnv ID.Set.empty tyConIdSubst argSigEnv
        val (_, argSigEnv) = TCU.substTyConInEnv ID.Set.empty tyConSubst argSigEnv
        val _ = checkInstEnv (Env,argSigEnv)
        val (_, resSigEnv) = TCU.substTyConIdInEnv ID.Set.empty tyConIdSubst resSigEnv
        val (visited, resSigEnv) = TCU.substTyConInEnv ID.Set.empty tyConSubst resSigEnv
        val (_, bareResSigEnv) = TCU.substTyConIdInEnv ID.Set.empty tyConIdSubst bareResSigEnv
        val (_, bareResSigEnv) = TCU.substTyConInEnv ID.Set.empty tyConSubst bareResSigEnv
        val (tyConSubstInTemplate, boxedKindBodySubst) = computeBoxedKindInEnv bareResSigEnv
        (* 
         * after signature type intantiation for the functor body, 
         * functor body may contains tyCon whose boxedKind = NONE coming from signature,
         *)
        val (tyConSubstInEnrichedSig, boxedKindSubstInSig) = 
            computeBoxedKindSubst (resSigEnv,bareResSigEnv)
        val boxedKindSubst = 
            ID.Map.unionWith 
              #1
              (ID.Map.unionWith #1 (boxedKindArgSubst,boxedKindBodySubst),
               boxedKindSubstInSig)
        val (_, resSigEnv) = SU.instSigEnv ID.Set.empty boxedKindSubst SU.strPathEnv.empty
                                           ID.Map.empty resSigEnv
        val exnTagArgSubst = SU.computeExnTagSubst (argSigEnv, Env)
        val exnTagSubst = IEnv.unionWith
                            (fn _ => 
                                raise Control.Bug 
                                        "generative exnTag duplicates"
                            )
                            (exnTagArgSubst, exnTagBodySubst)
        val resSigEnv  = SU.instExnTagBySubstOnEnv exnTagSubst resSigEnv
      in
        (
         resSigEnv, 
         argSigEnv, 
         ID.Map.unionWith #1 (tyConSubstInTemplate,tyConSubstInEnrichedSig),
         exnTagSubst
         )
      end

  
  (**************************************************************************)
  fun kindCheckTyFun requiredBoxedKind {name,tyargs,body} =
      case (TU.boxedKindOfType body) of
          T.BOUNDVARty _ => ()
        | objectBoxedKind => TCU.kindCheckAtLinking {tyConName = name,
                                                     requiredKind = requiredBoxedKind,
                                                     objectKind = objectBoxedKind}
                                       
  fun kindCheckTySpecTyBindInfoPair (sigTyBindInfo, strTyBindInfo) =
      case (sigTyBindInfo, strTyBindInfo) of
          (T.TYSPEC {spec = {name, boxedKind = requiredBoxedKind,...}, impl = NONE}, 
           T.TYCON {boxedKind = objectBoxedKind, ...})
          => TCU.kindCheckAtLinking {tyConName = name,
                                     requiredKind = requiredBoxedKind,
                                     objectKind = !objectBoxedKind}
        | (T.TYSPEC {spec = {boxedKind = requiredBoxedKind,...},...} ,
           T.TYFUN  tyFun) 
          => kindCheckTyFun requiredBoxedKind tyFun
        | (T.TYSPEC {spec = {name, boxedKind = requiredBoxedKind,...} ,
                     ...},
           T.TYSPEC {spec = {boxedKind = objectBoxedKind,...},
                     ...})
          => TCU.kindCheckAtLinking {tyConName = name,
                                     requiredKind = requiredBoxedKind,
                                     objectKind = objectBoxedKind}
        | _ => raise Control.Bug "the first component should be tyspec"
             
  fun kindCheckTyBindInfoList nil = ()
    | kindCheckTyBindInfoList ((sigTyBindInfo, strTyBindInfo) :: rest) =
      case (sigTyBindInfo, strTyBindInfo) of
          (T.TYSPEC _ , _) => kindCheckTySpecTyBindInfoPair (sigTyBindInfo, strTyBindInfo)
        | _ => kindCheckTyBindInfoList rest

  fun checkEnvAndSigma (Env, sigma) =
      let
          val (tyConIdSet, sigEnv) = freshTyConIdSetInSig sigma
          val tyConEqs = computeTyBindInfoEquationsEnv (Env, sigEnv)
          val tyConIdSubst = unifyTyConId tyConIdSet tyConEqs ID.Map.empty
          val tyConEqs = substTyConIdInTyBindInfoEqsDomain tyConIdSubst tyConEqs
          val _ = kindCheckTyBindInfoList tyConEqs 
          val tyConSubst = unifyTyBindInfo tyConEqs ID.Map.empty
          val (_, sigEnv) = TCU.substTyConIdInEnv ID.Set.empty tyConIdSubst sigEnv
          val (_, sigEnv) = TCU.substTyConInEnv ID.Set.empty tyConSubst sigEnv
          val _ = checkInstEnv (Env, sigEnv)
      in 
          sigEnv
      end
  (********************************************************************************)
end
end
