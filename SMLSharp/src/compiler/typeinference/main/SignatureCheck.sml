(**
 * signature check for module.
 * @copyright (c) 2006, Tohoku University.
 * @author Liu Bochao
 * @version $Id: SignatureCheck.sml,v 1.22 2008/08/06 12:59:09 ohori Exp $
 *)
structure SignatureCheck =
struct 
local
  structure TU = TypesUtils
  structure TIU = TypeInferenceUtils
  structure SU = SigUtils
  structure TCU = TypeContextUtils
  structure E = TypeInferenceError
  structure TU = TypesUtils
  structure T = Types
  structure NM = NameMap
  structure NPEnv = NameMap.NPEnv
  structure TIC = TypeInferenceContext
  fun printTy ty = print (TypeFormatter.tyToString ty ^ "\n")  
in

  fun freshTyConIdSetInSig (tyConIdSet, Env:T.Env) =
      let
          val (tyConIdSubst,tyConIdSet) = 
              TyConID.Set.foldr 
                  (fn (oldId,(tyConIdSubst,newTyConIdSet)) => 
                      let
                          val newTyConId = Counters.newTyConId ()
                      in
                          (
                           TyConID.Map.insert(tyConIdSubst, oldId, newTyConId),
                           TyConID.Set.add(newTyConIdSet, newTyConId)
                          )
                      end
                  )
                  (TyConID.Map.empty, TyConID.Set.empty)
                  tyConIdSet
          val Env = TCU.substTyConIdInEnv tyConIdSubst Env             
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
  fun makeGenerativeFunctorSig {generativeExnTagSet = exnT,
                                argTyConIdSet = T, 
                                argSigEnv = sigE, 
                                argStrPrefixedEnv = strE,
                                body = (T1, E1)
                               } =
      let
          val exnTagSubst = 
              ExnTagID.Set.foldr 
                  (fn (oldTag, exnTagSubst) => 
                      ExnTagID.Map.insert(exnTagSubst, 
                                          oldTag,
                                          Counters.newExnTagID ()
                                         )
                  )
                  ExnTagID.Map.empty
                  exnT

          val tyConIdSubst =
              TyConID.Set.foldr 
                  (fn (oldId,tyConIdSubst) => 
                      TyConID.Map.insert(tyConIdSubst, 
                                         oldId, 
                                         Counters.newTyConId ()
                                        )
                  )
                  TyConID.Map.empty
                  T1

          val resultEnv = TCU.substTyConIdInEnv tyConIdSubst E1
      in
          (exnTagSubst, sigE, resultEnv)
      end
  (*
   fun computeBoxedKindSubst (sigEnv as (TE, VE), strEnv as (TE1, VE1)) = 
       let
           fun computeBoxedKindTE (sigTE, strTE) =
               NPEnv.foldli (fn (tyConNamePath, tyBindInfo, boxedKindSubst) =>
                                case tyBindInfo of
                                    T.TYCON (tycon as {name, strpath, abstract,
                                                       tyvars,id,eqKind,
                                                       boxedKind = ref T.GENERICty,
                                                       datacon = data})
                                    =>
                                    (
                                     case NPEnv.find(strTE, tyConNamePath) of
                                         NONE => boxedKindSubst
                                       | SOME tyBindInfo1 =>
                                         let
                                             val boxedKind = TU.boxedKindOfTyBindInfo tyBindInfo1
                                         in
                                             TyConID.Map.insert(boxedKindSubst, id, boxedKind)
                                         end
                                    )
                                  | T.TYSPEC({spec = {name, strpath, id, boxedKind = T.GENERICty, ...},impl}) =>
                                    (
                                     case NPEnv.find(TE1, tyConNamePath) of
                                         NONE => boxedKindSubst
                                       | SOME tyBindInfo1 =>
                                         let
                                             val boxedKind = TU.boxedKindOfTyBindInfo tyBindInfo1
                                         in
                                             TyConID.Map.insert(boxedKindSubst, id, boxedKind)
                                         end
                                    )
                                  | T.TYFUN({name, strpath, tyargs, 
                                             body = 
                                             T.ALIASty(T.CONty{tyName= tyName as{id,
                                                                                 boxedKind = ref T.GENERICty,...},...},
                                                       actTy)
                                            }
                                           ) 
                                    =>
                                    (case NPEnv.find(TE1, tyConNamePath) of
                                         NONE => boxedKindSubst
                                       | SOME tyBindInfo1 =>
                                         let
                                             val boxedKind = TU.boxedKindOfTyBindInfo tyBindInfo1
                                         in
                                             TyConID.Map.insert(boxedKindSubst, id, boxedKind)
                                         end)
                                  | _ => boxedKindSubst)
                            TyConID.Map.empty
                            sigTE
       in
           computeBoxedKindTE (TE,TE1)
       end                        
   *)

  fun computeTyBindInfoEquationsTE (tyConEnv, sigTyConEnv) tyBindInfoEquations =
      NPEnv.foldli (fn (tyConNamePath, sigTyBindInfo, tyBindInfoEquations) =>
                       case NPEnv.find(tyConEnv, tyConNamePath) of
                           SOME strTyBindInfo => 
                           (sigTyBindInfo, strTyBindInfo) :: tyBindInfoEquations
                         | _ => raise E.unboundTyconInSigMatch
                                          {name = NM.namePathToString(tyConNamePath) })
                   tyBindInfoEquations
                   sigTyConEnv

                   
  fun computeTyBindInfoEquationsEnv ((tyConEnv, varEnv), (sigTyConEnv, sigVarEnv)) =
      computeTyBindInfoEquationsTE (tyConEnv, sigTyConEnv) nil


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
                       NONE => 
                       raise Control.Bug ("btv("^(Int.toString(i1))^")not found in equivty")
                     | SOME i1 =>  i1 = i2)
                | (T.ALIASty (ty11,ty12), _) =>
                  eq btvEqEnv (ty12,ty2)
                | (_, T.ALIASty(ty21,ty22)) =>
                  eq btvEqEnv (ty1,ty22)
                | (T.OPAQUEty {spec ={tyCon = {id = id1, ...}, args = args1 }, ...},
                   T.OPAQUEty {spec ={tyCon = {id = id2, ...}, args = args2 }, ...}) =>
                  TyConID.eq(id1, id2)
                  andalso
                  List.length args1 = List.length args2
                  andalso
                  foldl 
                      (fn ((ty1,ty2), bool) => eq btvEqEnv (ty1,ty2) andalso bool)
                      true
                      (ListPair.zip(args1,args2))
                | (T.OPAQUEty {spec ={tyCon = {id = id1, ...}, args = args1 }, ...},
                   T.RAWty {tyCon = {id = id2, ...}, args = args2 }) =>
                  TyConID.eq(id1, id2)
                  andalso
                  List.length args1 = List.length args2
                  andalso
                  foldl 
                      (fn ((ty1,ty2), bool) => eq btvEqEnv (ty1,ty2) andalso bool)
                      true
                      (ListPair.zip(args1,args2))
                | (T.RAWty  {tyCon = {id = id1, ...}, args = args1 },
                   T.OPAQUEty  {spec ={tyCon = {id = id2, ...}, args = args2 }, ...})=>
                  TyConID.eq(id1, id2)
                  andalso
                  List.length args1 = List.length args2
                  andalso
                  foldl 
                      (fn ((ty1,ty2), bool) => eq btvEqEnv (ty1,ty2) andalso bool)
                      true
                      (ListPair.zip(args1,args2))
                | (T.SPECty {tyCon = {id = id1, ...}, args = args1}, 
                   T.SPECty {tyCon = {id = id2,...}, args = args2}) => 
                  TyConID.eq(id1, id2)
                  andalso
                  List.length args1 = List.length args2
                  andalso
                  foldl 
                      (fn ((ty1,ty2), bool) => eq btvEqEnv (ty1,ty2) andalso bool)
                      true
                      (ListPair.zip(args1,args2))
                | (T.SPECty {tyCon = {id = id1, ...}, args = args1}, 
                   T.RAWty {tyCon = {id = id2,...}, args = args2}) => 
                  TyConID.eq(id1, id2)
                  andalso
                  List.length args1 = List.length args2
                  andalso
                  foldl 
                      (fn ((ty1,ty2), bool) => eq btvEqEnv (ty1,ty2) andalso bool)
                      true
                      (ListPair.zip(args1,args2))
                | (T.RAWty {tyCon = {id = id1, ...}, args = args1}, 
                   T.SPECty {tyCon = {id = id2,...}, args = args2}) => 
                  TyConID.eq(id1, id2)
                  andalso
                  List.length args1 = List.length args2
                  andalso
                  foldl 
                      (fn ((ty1,ty2), bool) => eq btvEqEnv (ty1,ty2) andalso bool)
                      true
                      (ListPair.zip(args1,args2))
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
                  (SEnv.foldli (fn (label, ty2,  bool) =>
                                   case SEnv.find(tyFields1, label) of
                                       NONE => false
                                     | SOME ty1 => eq btvEqEnv (ty1, ty2) andalso bool)
                               true
                               tyFields2)
                | (T.RAWty {tyCon ={id=id1,...}, args = args1}, 
                   T.RAWty {tyCon ={id=id2,...}, args = args2}) =>
                  TyConID.eq(id1, id2)
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
                | _ => false
      in
          eq IEnv.empty (ty1, ty2)
      end

  (* according to section 4.4, type function equality does not 
   * invlove the equality attribute of type variable
   *)
  fun equivTyFcn  (tyargs1, body1) (tyargs2, body2) =
      let
          val tyargsList1 = IEnv.listItemsi tyargs1
          val tyargsList2 = IEnv.listItemsi tyargs2
          val (substEnv1, substEnv2) =
              ListPair.foldl
                  (fn ((x,_),(y,_),(substEnv1,substEnv2)) =>
                      let
                          val tyvarTy = 
                              T.newty {recordKind = T.UNIV, eqKind = T.NONEQ,tyvarName = NONE}
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
           T.CONID {namePath = namePath1, funtyCon = bool1, ty = ty1, tyCon = {id=id1,...},...},
           T.CONID {namePath = namePath2, funtyCon = bool2, ty = ty2, tyCon = {id=id2,...},...}
          ) =>
          bool1 = bool2 
          andalso 
          (#1 namePath1) = (#1 namePath2)
          andalso 
          TyConID.eq(id1, id2)
          andalso
          equivTy (ty1, ty2)
        |
        (
         T.EXNID {namePath = namePath1, funtyCon = bool1, ty = ty1, tyCon = {id=id1,...},...},
         T.EXNID {namePath = namePath2, funtyCon = bool2, ty = ty2, tyCon = {id=id2,...},...}
        ) =>
        bool1 = bool2 
        andalso 
        (#1 namePath1) = (#1 namePath2)
        andalso 
        TyConID.eq(id1, id2)
        andalso
        equivTy (ty1, ty2)
        | (_,_) => raise Control.Bug "equivIdstate: not CONID occurring in datacon"


  fun unmatchedNames SEnv = 
      SEnv.foldli (fn (name,_,errStr) =>
                      name ^ " " ^ errStr)
                  ""
                  SEnv

  fun equivDatacon (varEnv1, varEnv2) =
      let
          fun redundantVarEnv varEnv1 varEnv2 =
              SEnv.filteri (fn (name,idstate) =>
                               not (SEnv.inDomain(varEnv2,name)))
                           varEnv1
          val num1 = SEnv.numItems(varEnv1)
          val num2 = SEnv.numItems(varEnv2)
          val itemsNumEqual = 
              if num1 = num2 then true
              else
                  if num1 > num2 then
                      raise E.RedunantConstructorInSignatureInSigMatch 
                                {Cons = (unmatchedNames (redundantVarEnv varEnv1 varEnv2))}
                  else
                      raise E.RedunantConstructorInStructureInSigMatch 
                                {Cons = (unmatchedNames (redundantVarEnv varEnv2 varEnv1))}
          val items1 = SEnv.listItemsi varEnv1
          val items2 = SEnv.listItemsi varEnv2
          fun checkEquiv (nil,nil) = true
            | checkEquiv ((name1:string,idstate1)::t1, (name2,idstate2)::t2) = 
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
                   val tyBindInfo1 = 
                       TCU.substTyConInTyBindInfoFully tyConSubst tyBindInfo1
               in
                   (tyBindInfo1,tyBindInfo2)
               end)
           tyConEqs)
      handle TCU.ExTySpecInstantiatedWithNonEqTyBindInfo name =>
             raise E.EqErrorInSigMatch {tyConName=name}


  fun unifyTyConId tyConIdSet nil tyConIdSubst = tyConIdSubst
    | unifyTyConId tyConIdSet ((sigTyBindInfo, strTyBindInfo)::rest) tyConIdSubst =
      (case (sigTyBindInfo, strTyBindInfo) of
           (T.TYSPEC {id=id1, name = name1, eqKind = ref eqKind1, tyvars = tyvars1,...},
            T.TYCON {tyCon = {id=id2, name = name2, eqKind = ref eqKind2, tyvars = tyvars2, ...}, ...}) => 
           if List.length tyvars1 <> List.length tyvars2 then
               raise E.ArityMismatchInSigMatch {tyConName = name2}
           else
               if eqKind1 = T.EQ andalso eqKind2 = T.NONEQ then
                   raise E.EqErrorInSigMatch {tyConName=name2}
               else
                   unifyTyConId tyConIdSet rest (TyConID.Map.insert(tyConIdSubst, id1, id2))
         | (T.TYCON {tyCon = {name = name, tyvars = tyvars1, id = id1, eqKind = ref eqKind1, ...}, ...}, 
            T.TYCON {tyCon = {tyvars = tyvars2, id = id2, eqKind = ref eqKind2, ...}, ...}) =>
           if TyConID.Set.member(tyConIdSet, id1) then
               (* flexible tyConId *)
               if List.length tyvars2 <> List.length tyvars1 then
                   raise E.ArityMismatchInSigMatch {tyConName=name}
               else if eqKind1 = T.EQ andalso eqKind2 = T.NONEQ then
                   raise E.EqErrorInSigMatch {tyConName=name}
               else unifyTyConId tyConIdSet rest (TyConID.Map.insert(tyConIdSubst, id1, id2))
           else
               (* non-flexible tyConId *)
               if TyConID.eq(id1, id2) andalso List.length tyvars2 = List.length tyvars1 
                  andalso eqKind1 = eqKind2 
               then
                   unifyTyConId tyConIdSet rest tyConIdSubst
               else
                   raise E.TyConMisMatchInSigMatch {tyConName=name}
         | (T.TYSPEC {name, id = id1, tyvars = tyvars1, eqKind = ref eqKind1,...},
            T.TYSPEC {id = id2, tyvars = tyvars2, eqKind = ref eqKind2,...}) =>
           if List.length tyvars2 <> List.length tyvars1 then
               raise E.ArityMismatchInSigMatch {tyConName = name}
           else if eqKind1 = T.EQ andalso eqKind2 = T.NONEQ then
               raise E.EqErrorInSigMatch {tyConName=name}
           else
               unifyTyConId tyConIdSet rest (TyConID.Map.insert(tyConIdSubst, id1, id2))
         | (T.TYSPEC {name, id = id1, tyvars = tyvars1, eqKind = ref eqKind1,...},
            T.TYOPAQUE {spec = {id = id2, tyvars = tyvars2, eqKind = ref eqKind2,...}, ...}) =>
           if List.length tyvars2 <> List.length tyvars1 then
               raise E.ArityMismatchInSigMatch {tyConName = name}
           else if eqKind1 = T.EQ andalso eqKind2 = T.NONEQ then
               raise E.EqErrorInSigMatch {tyConName=name}
           else
               unifyTyConId tyConIdSet rest (TyConID.Map.insert(tyConIdSubst, id1, id2))
         | _ => unifyTyConId tyConIdSet rest tyConIdSubst)
      
  fun substTyConIdInTyBindInfoEqsDomain tyConIdSubst tyBindInfoEqs =
      map (
      fn (tyBindInfo1, tyBindInfo2) => 
         let
             val tyBindInfo1 = 
                 TCU.substTyConIdInTyBindInfo tyConIdSubst tyBindInfo1
         in
             (tyBindInfo1, tyBindInfo2)
         end
      )
          tyBindInfoEqs

  fun unifyTySpec nil tyConSubst = tyConSubst
    | unifyTySpec ((tyBindInfo1, tyBindInfo2)::rest) tyConSubst =
      case (tyBindInfo1, tyBindInfo2) of
          (T.TYSPEC {id=id1, name = name1, strpath = strpath1, eqKind = ref eqKind1, 
                     tyvars = tyvars1, ...},
           T.TYCON {tyCon = {id=id2, name = name2, strpath = strpath2, eqKind = ref eqKind2, 
                             tyvars = tyvars2, ...},...}) => 
          (
           if List.length tyvars1 <> List.length tyvars2 then
               raise E.ArityMismatchInSigMatch {tyConName = name2}
           else if eqKind1 = T.EQ andalso eqKind2 = T.NONEQ then
               raise E.EqErrorInSigMatch {tyConName=name2}
           else if TyConID.eq(id1, id2) then
               unifyTySpec rest
                           (TyConID.Map.insert(tyConSubst, id1, tyBindInfo2))
           else raise E.TyConMisMatchInSigMatch {tyConName=name2}
          )
        | (T.TYSPEC {name = name1, strpath = strpath1, id = id1, tyvars = tyvars1, eqKind = ref eqKind, ...}, 
           T.TYFUN  (tyFun as {name = name2, strpath = strpath2, tyargs = tyargs2 , body = body2}) ) => 
          (
           if eqKind = T.EQ andalso not (TU.admitEqTyFun tyFun) then
               raise E.EqErrorInSigMatch {tyConName=name2}
           else if List.length tyvars1 <> IEnv.numItems(tyargs2) then
               raise E.ArityMismatchInSigMatch {tyConName=name1}
           else unifyTySpec rest (TyConID.Map.insert(tyConSubst, id1, tyBindInfo2))
          )
        | (T.TYSPEC {name = name1, strpath = strpath1, id = id1, tyvars = tyvars1, eqKind = ref eqKind1, ...},
           T.TYSPEC {name = name2, strpath = strpath2, id = id2, tyvars = tyvars2, eqKind = ref eqKind2, ...})
          =>
          if List.length tyvars1 <> List.length tyvars2 then
              raise E.ArityMismatchInSigMatch {tyConName = NM.namePathToString(name2, strpath2)}
          else if eqKind1 = T.EQ  andalso eqKind2 = T.NONEQ then
              raise E.EqErrorInSigMatch {tyConName=NM.namePathToString(name2, strpath2)}
          else if not (TyConID.eq(id1, id2)) then
              raise E.TyConMisMatchInSigMatch {tyConName = NM.namePathToString(name2, strpath2)}
          else unifyTySpec rest (TyConID.Map.insert(tyConSubst, id1, tyBindInfo2))
        | (T.TYSPEC {name = name1, strpath = strpath1, id = id1, tyvars = tyvars1, eqKind = ref eqKind1, ...},
           T.TYOPAQUE {spec = {name = name2, strpath = strpath2, id = id2, tyvars = tyvars2, eqKind = ref eqKind2, ...},
                       ...})
          =>
          if List.length tyvars1 <> List.length tyvars2 then
              raise E.ArityMismatchInSigMatch {tyConName = NM.namePathToString(name2, strpath2)}
          else if eqKind1 = T.EQ  andalso eqKind2 = T.NONEQ then
              raise E.EqErrorInSigMatch {tyConName=NM.namePathToString(name2, strpath2)}
          else if not (TyConID.eq(id1, id2)) then
              raise E.TyConMisMatchInSigMatch {tyConName = NM.namePathToString(name2, strpath2)}
          else unifyTySpec rest (TyConID.Map.insert(tyConSubst, id1, tyBindInfo2))
        | _ => unifyTySpec rest tyConSubst
               
  fun unifyTyConAndTyFun  nil tyConSubst = tyConSubst
    | unifyTyConAndTyFun  ((sigTyBindInfo, strTyBindInfo)::rest) tyConSubst =
      case (sigTyBindInfo, strTyBindInfo) of
          (T.TYCON {tyCon = {name, tyvars = tyvars1, id = id1, eqKind = ref eqKind1,...},
                    datacon = datacon1 as varEnv1}, 
           T.TYCON {tyCon = {tyvars = tyvars2, id = id2, eqKind = ref eqKind2, ...},
                    datacon = datacon2 as varEnv2}) =>
          if List.length tyvars1 <> List.length tyvars2 then
              raise E.ArityMismatchInSigMatch {tyConName=name}
          else if eqKind1 = T.EQ andalso eqKind2 = T.NONEQ then
              raise E.EqErrorInSigMatch {tyConName=name}
          else if not (TyConID.eq(id1, id2)) then
              raise E.TyConMisMatchInSigMatch {tyConName=name}
          else if not (equivDatacon (varEnv1, varEnv2)) then
              raise E.TyConMisMatchInSigMatch {tyConName=name}
          else 
              unifyTyConAndTyFun
                  (substTyConInTyBindEqsDomain (TyConID.Map.singleton(id1, strTyBindInfo)) rest)
                  (TyConID.Map.insert(tyConSubst, id1, strTyBindInfo))
        | (T.TYCON {tyCon = {name = name1, strpath = strpath1, tyvars = tyvars1, id = id1, 
                             eqKind = ref eqKind1, ...},
                    datacon = varEnv1}, 
           T.TYFUN {name = name2, strpath = strpath2, tyargs = tyargs2 , body = body2}) 
          =>
          ( case (TU.extractAliasTyImpl body2) of
                T.RAWty({tyCon = {name = name3,tyvars = tyvars3, id = id3, eqKind = ref eqKind3, ...},...})
                => 
                if List.length tyvars1 <> List.length tyvars3 then
                    raise E.ArityMismatchInSigMatch {tyConName=name2}
                else if eqKind1 = T.EQ andalso eqKind3 = T.NONEQ then
                    raise E.EqErrorInSigMatch {tyConName=name2}
                else if not (TyConID.eq(id1, id3)) then
                    raise E.TyConMisMatchInSigMatch {tyConName=name2}
                else 
                    unifyTyConAndTyFun  rest tyConSubst
              | _ => 
                raise E.TyConMisMatchInSigMatch {tyConName = name2}
          )
        | (T.TYFUN  ( {name = name1, strpath = strpath1, tyargs = tyargs1 , 
                       body = body1 as T.ALIASty(T.RAWty{tyCon = {id = id1,...},...}, _)}),
           T.TYFUN  ( {name = name2, strpath = strpath2, tyargs = tyargs2 , 
                       body = body2 as T.ALIASty(T.RAWty{tyCon,...}, _)}))
          =>
          if IEnv.numItems(tyargs1) <> IEnv.numItems(tyargs2) then
              raise E.ArityMismatchInSigMatch {tyConName = name1 ^ " " ^ name2}
          else
              if equivTyFcn  (tyargs1, body1) (tyargs2, body2) then
                  unifyTyConAndTyFun 
                      rest
                      ((* this incremental map only accounts for
                        * strpath substitution
                        *)
                       TyConID.Map.insert(tyConSubst, id1, T.TYCON {tyCon = tyCon, datacon = SEnv.empty})
                      )
              else
                  (raise E.SharingTypeMismatchInSigMatch{tyConName1 = name1, 
                                                         tyConName2 = name2})
        | (T.TYFUN  ( {body = body1,...}),
           T.TYFUN  ( {body = body2,...})) =>
          raise Control.Bug "illegal body of tyFun(unifyTyConAndTyFun)"
        | (T.TYFUN  ( {name = name1, strpath = strpath1, tyargs = tyargs1 , body = body1}),
           T.TYCON {tyCon = {name = name2, strpath = strpath2, tyvars=tyvars2, id = id2, 
                             eqKind = ref eqKind2, ...},
                    datacon = datacon2 as varEnv2})
          => 
          (
           case (TU.extractAliasTyImpl body1) of
               T.RAWty({tyCon = {name = name3, tyvars = tyvars3, id = id3, eqKind = ref eqKind3, ...},...})
               => 
               if List.length tyvars2 <> List.length tyvars2 then
                   raise E.ArityMismatchInSigMatch {tyConName=name2}
               else if eqKind2 = T.EQ andalso eqKind3 = T.NONEQ then
                   raise E.EqErrorInSigMatch {tyConName=name2}
               else if not (TyConID.eq(id2, id3)) then
                   raise E.TyConMisMatchInSigMatch {tyConName=name2}
               else 
                   unifyTyConAndTyFun  rest tyConSubst 
             | _ => 
               raise E.TyConMisMatchInSigMatch {tyConName = name2}
          )
        | _ => unifyTyConAndTyFun  rest tyConSubst 
               
  fun unifyTyBindInfo  nil tyConSubst = tyConSubst
    | unifyTyBindInfo  (equations as (tyBindInfo1, tyBindInfo2)::rest) tyConSubst =
      let
          val tySpecSubst = unifyTySpec equations TyConID.Map.empty
          val newEquations = substTyConInTyBindEqsDomain tySpecSubst equations
      in
          unifyTyConAndTyFun  newEquations tySpecSubst
      end

  fun checkInstTy name (strTy,sigTy) =
      let
          val (strTy : Types.ty)  = 
              TU.freshInstTy (strTy : Types.ty)
          val sigTy = 
              TU.freshRigidInstTy sigTy
      in
          (Unify.unify [(strTy, sigTy)])
      end
      handle Unify.Unify => 
             (raise E.InstanceCheckInSigMatch
                        {tyConName=NM.namePathToString(name), ty1 = strTy, ty2 = sigTy})

  fun checkInstVarEnv  (strVE, sigVE) =
      NPEnv.mapi
          (fn (name, sigIdState) =>
              case sigIdState of
                  T.VARID { ty = ty2, ...} =>
                  (
                   case NPEnv.find(strVE, name) of
                       SOME (T.VARID{ ty = ty1, ...}) =>
                       checkInstTy  name (ty1,ty2)
                     | SOME (strIdState as T.CONID{ ty = ty1, ...}) =>
                       checkInstTy  name (ty1,ty2)
                     | SOME (strIdState as T.EXNID{ ty = ty1, ...}) =>
                       checkInstTy  name (ty1,ty2)
                     | SOME (strIdState as T.PRIM {ty = ty1, ...}) =>
                       checkInstTy  name (ty1,ty2)
                     | NONE => raise E.unboundVarInSigMatch {varName = NM.namePathToString(name)}
                     | _    => raise Control.Bug "checkInstVarEnv:Not variable or constructor(1)"
                  )
                | T.CONID { ty = ty2, ...} =>
                  (case NPEnv.find(strVE, name) of
                       SOME (T.VARID _) => raise E.DataConRequiredInSigMatch
                                                     {tyConName=NM.namePathToString(name)}
                     | SOME (T.CONID {ty = ty1, ...}) => 
                       checkInstTy  name (ty1,ty2)
                     | NONE => raise E.unboundVarInSigMatch {varName = NM.namePathToString(name)}
                     | _    => raise Control.Bug "checkInstVarEnv:Not variable or constructor(2)"
                  )
                | T.EXNID { ty = ty2, ...} =>
                  (case NPEnv.find(strVE, name) of
                       SOME (T.VARID _) => raise E.DataConRequiredInSigMatch
                                                     {tyConName=NM.namePathToString(name)}
                     | SOME (T.CONID _) => raise E.ExnConRequiredInSigMatch
                                                     {tyConName=NM.namePathToString(name)}
                     | SOME (T.EXNID {ty = ty1, ...}) => 
                       checkInstTy  name (ty1,ty2)
                     | NONE => raise E.unboundVarInSigMatch {varName = NM.namePathToString(name)}
                     | _    => raise Control.Bug "checkInstVarEnv:Not variable or constructor(2)")
                | _ => raise Control.Bug "checkInstVarEnv:Not variable or constructor(3)"
          )
          sigVE
          

  fun checkInstEnv ((strTE, strVE), (sigTE, sigVE)) =
      checkInstVarEnv (strVE, sigVE)

  (*******************************************************************************)
  fun transparentSigMatch (Env, sigma)  = 
      let
          val (tyConIdSet,sigEnv) = freshTyConIdSetInSig sigma
          (* tyConEqs : [(sigTybindInfo,strTybindInfo),...] *)
          val tyConEqs = computeTyBindInfoEquationsEnv (Env, sigEnv)
          val tyConIdSubst = unifyTyConId tyConIdSet tyConEqs TyConID.Map.empty
          val tyConEqs = substTyConIdInTyBindInfoEqsDomain tyConIdSubst tyConEqs
          val tyConSubst = unifyTyBindInfo tyConEqs TyConID.Map.empty
          val sigEnv = TCU.substTyConIdInEnv tyConIdSubst sigEnv
          val sigEnv = TCU.substTyConInEnvFully tyConSubst sigEnv
          val _ = checkInstEnv (Env, sigEnv) 
          val sigEnv = SU.instEnvWithExnAndIdState(Env, sigEnv)
      in
          sigEnv
      end
      
  fun opaqueSigMatch (Env, sigma as (_, absSigEnv)) = 
      let
          val (tyConIdSet,sigEnv) = freshTyConIdSetInSig sigma 
          (* tyConEqs : [(sigTybindInfo,strTybindInfo),...] *)
          val tyConEqs = computeTyBindInfoEquationsEnv (Env, sigEnv)
          val tyConIdSubst = unifyTyConId tyConIdSet tyConEqs TyConID.Map.empty
          val tyConEqs = substTyConIdInTyBindInfoEqsDomain tyConIdSubst tyConEqs
          val tyConSubst = unifyTyBindInfo tyConEqs TyConID.Map.empty
          val sigEnv = TCU.substTyConIdInEnv tyConIdSubst sigEnv
          val sigEnv = TCU.substTyConInEnvFully tyConSubst sigEnv
          val _ = checkInstEnv (Env, sigEnv)
          (* instantiate the followings :
           * 1. Exception tag
           * 2. FFID actual arguments list
           *)
          val absSigEnv = SU.instEnvWithExnAndIdState(Env, absSigEnv)
          (* instantiate the followings:
           * 1. strPath
           * 2. tySpec implemantation field
           * 3. SPECty is intantitated into OPAQUEty.
           *)
          val absSigEnv = SU.instTopSigEnv (Env, absSigEnv)
      in
          (absSigEnv, sigEnv)
      end

  fun functorSigMatch (Env ,functorSig as  {argTyConIdSet = tyConIdSet, ...}) 
      =
      let
          val (exnTagBodySubst, argSigEnv , resSigEnv) = makeGenerativeFunctorSig  functorSig
          val tyConEqs = computeTyBindInfoEquationsEnv (Env, argSigEnv)
          val tyConIdSubst = unifyTyConId tyConIdSet tyConEqs TyConID.Map.empty
          val tyConEqs = substTyConIdInTyBindInfoEqsDomain tyConIdSubst tyConEqs
          val tyConSubst = unifyTyBindInfo  tyConEqs TyConID.Map.empty
          val argSigEnv = TCU.substTyConIdInEnv tyConIdSubst argSigEnv
          val argSigEnv = TCU.substTyConInEnvPartially tyConSubst argSigEnv
          val _ = checkInstEnv (Env,argSigEnv)
          val resSigEnv = TCU.substTyConIdInEnv tyConIdSubst resSigEnv
          val resSigEnv = TCU.substTyConInEnvPartially tyConSubst resSigEnv
                          
          val exnTagArgSubst = SU.computeExnTagSubst (argSigEnv, Env)
          val exnTagSubst = ExnTagID.Map.unionWith
                                (fn _ => 
                                    raise Control.Bug 
                                              "generative exnTag duplicates")
                                (exnTagArgSubst, exnTagBodySubst)
          val resSigEnv  = SU.instExnTagBySubstOnEnv exnTagSubst resSigEnv
      in
          (resSigEnv, argSigEnv, exnTagBodySubst, exnTagArgSubst)
      end

  fun computeFunBindInfoEquationsEnv (implFunEnv, interfaceSigFunEnv) loc =
      SEnv.foldli (fn (funName, interfaceSigFunBindInfo, equations) =>
                      case SEnv.find(implFunEnv, funName) of
                          NONE => 
                          (E.enqueueError 
                               (loc, 
                                E.unboundFunctorInSigMatch {name = funName});
                           equations)
                        | SOME implFunBindInfo =>
                          (interfaceSigFunBindInfo, implFunBindInfo) :: equations)
                  nil
                  interfaceSigFunEnv

  fun interfaceMatch 
          ((implEnv, implFunEnv): (Types.Env * Types.funEnv), 
           {boundTyConIdSet, env = env as (interfaceSigEnv, interfaceSigFunEnv)} : Types.basicInterfaceSig) 
          loc
    =
      let
          (************** Env part ***********************)
          fun interfaceSigEnvToNPEnv interfaceSigEnv NPEnv =
              NPEnv.foldli (fn (namePath, _, (newInterfaceSigNPEnv, unmatchedInterfaceSigEnv)) =>
                               let
                                   val stringKey = NM.namePathToString namePath
                               in
                                   case SEnv.find(interfaceSigEnv, stringKey) of
                                       NONE => (newInterfaceSigNPEnv, unmatchedInterfaceSigEnv)
                                     | SOME entry => 
                                       (NPEnv.insert(newInterfaceSigNPEnv, namePath, entry),
                                        #1 (SEnv.remove(unmatchedInterfaceSigEnv, stringKey)))
                               end)
                           (NM.NPEnv.empty, interfaceSigEnv)
                           NPEnv
          val interfaceSigEnv =
              (* signature matching requires namePathEnv.
               * Module compiler guarantees the component name consistency.
               *)
              let
                  val (tyConEnv, unmatchedTyConEnv) = 
                      interfaceSigEnvToNPEnv (#1 interfaceSigEnv) (#1 implEnv)
                  val (varEnv, unmatchedVarEnv) = 
                      interfaceSigEnvToNPEnv (#2 interfaceSigEnv) (#2 implEnv)
                  val _ = if SEnv.isEmpty unmatchedTyConEnv then ()
                          else E.enqueueError 
                                   (loc, 
                                    E.TyConMisMatchInSigMatch {tyConName = unmatchedNames unmatchedTyConEnv})
                  val _ = if SEnv.isEmpty unmatchedVarEnv then ()
                          else E.enqueueError 
                                   (loc, 
                                    E.unboundVarInSigMatch {varName = unmatchedNames unmatchedVarEnv})
              in
                  (tyConEnv, varEnv)
              end
          val tyConEqs = computeTyBindInfoEquationsEnv (implEnv, interfaceSigEnv)
          val tyConIdSubst = unifyTyConId boundTyConIdSet tyConEqs TyConID.Map.empty
          val tyConEqs = substTyConIdInTyBindInfoEqsDomain tyConIdSubst tyConEqs
          val tyConSubst = unifyTyBindInfo tyConEqs TyConID.Map.empty
          val instInterfaceSigEnv = TCU.substTyConIdInEnv tyConIdSubst interfaceSigEnv
          val instInterfaceSigEnv = TCU.substTyConInEnvFully tyConSubst instInterfaceSigEnv
          val _ = checkInstEnv (implEnv, instInterfaceSigEnv)

          (************** Functor Env part ******************)
          val instInterfaceSigFunEnv = TCU.substTyConIdInFunEnv tyConIdSubst interfaceSigFunEnv
          val instInterfaceSigFunEnv = TCU.substTyConInFunEnv tyConSubst instInterfaceSigFunEnv

          val funBindInfoEqs = computeFunBindInfoEquationsEnv (implFunEnv, interfaceSigFunEnv) loc
          val functorInstInfoEnv =
              foldl (fn ((implFunBindInfo as {funName,
                                              functorSig = {argTyConIdSet = implFormalTyConIdSet,
		                                            argSigEnv = implArgSigEnv, 
                                                            body = (implBodyTyConIDSet, implBodyEnv),
                                                            ...},
                                              ...
                                             } : Types.funBindInfo,
                          interfaceSigFunBindInfo as {functorSig = {argTyConIdSet = interfaceSigFormalTyConIdSet,
		                                                    argSigEnv = interfaceSigArgSigEnv, 
                                                                    body = (interfaceSigBodyTyConIDSet, 
                                                                            interfaceSigBodyEnv),
                                                                    ...},
                                                      ...
                                                     } : Types.funBindInfo
                         ),
                         functorInstInfoEnv
                        ) =>
                        let
                            (* contravariant argument signature matching : 
                             * tyConEqs : [(implTyBindInfo, interfaceSigTyBindInfo)...]
                             *)
                            val tyConEqs = computeTyBindInfoEquationsEnv (interfaceSigArgSigEnv, implArgSigEnv)
                            val tyConIdSubst = unifyTyConId implFormalTyConIdSet tyConEqs TyConID.Map.empty
                            val tyConEqs = substTyConIdInTyBindInfoEqsDomain tyConIdSubst tyConEqs
                            val tyConSubst = unifyTyBindInfo  tyConEqs TyConID.Map.empty
                            val implArgSigEnv = TCU.substTyConIdInEnv tyConIdSubst implArgSigEnv
                            val implArgSigEnv = TCU.substTyConInEnvFully tyConSubst implArgSigEnv
                            val _ = checkInstEnv (interfaceSigArgSigEnv, implArgSigEnv)
                            (* covariant body signature matching *)
                            val implBodyEnv = TCU.substTyConIdInEnv tyConIdSubst implBodyEnv
                            val implBodyEnv = TCU.substTyConInEnvFully tyConSubst implBodyEnv
                            val tyConEqs = computeTyBindInfoEquationsEnv (implBodyEnv, interfaceSigBodyEnv)
                            val tyConIdSubst = unifyTyConId interfaceSigBodyTyConIDSet tyConEqs TyConID.Map.empty
                            val tyConEqs = substTyConIdInTyBindInfoEqsDomain tyConIdSubst tyConEqs
                            val tyConSubst = unifyTyBindInfo  tyConEqs TyConID.Map.empty
                            val interfaceSigBodyEnv = TCU.substTyConIdInEnv tyConIdSubst interfaceSigBodyEnv
                            val interfaceSigBodyEnv = TCU.substTyConInEnvFully tyConSubst interfaceSigBodyEnv
                            val _ = checkInstEnv (implBodyEnv, interfaceSigBodyEnv)

                            (* Prepare environment for type instantiation, two parts:
                             * 1. functor argument : since it is contravariant, the signature matching
                             * above instantiates implemenation functor argument abstract type specification
                             * with the interface ones. Thus the instantiated "implArgSigEnv" lost the
                             * typeConId information that is used in the functor body. We cannot use this 
                             * environment to generate type instantiation declarations for the functor
                             * argument. Instead, we only instantiate the tyConId part of those corresponding,
                             * i.e. having the same specified name, type specifications and datatypes in interface 
                             * with the corresponding tyConId in implemenation. Thus the type instantiation
                             * declaration only involves the types of the implementation tyConId, which 
                             * will be instantated at the functor appplication.
                             * 
                             * 2. functor body : ordinary as for transparent and opaque signature matching. No
                             * special treatment.
                             *)
                            (* 1. functor argument:  *)
                            val tyConEqs = computeTyBindInfoEquationsEnv (implArgSigEnv, interfaceSigArgSigEnv)
                            val tyConIdSubst = unifyTyConId interfaceSigFormalTyConIdSet tyConEqs TyConID.Map.empty
                            val interfaceSigArgSigEnv = TCU.substTyConIdInEnv tyConIdSubst interfaceSigArgSigEnv
                            val interfaceSigArgSigVarEnv =
                                NPEnv.filteri (fn (k, v) => 
                                                  NPEnv.inDomain(#2 implArgSigEnv, k))
                                              (#2 interfaceSigArgSigEnv)
                            (* 2. functor body : no special treament; just use the instantiated "interfaceSigBodyEnv"
                             * above
                             *)
                        in
                            SEnv.insert (functorInstInfoEnv, 
                                         funName,
                                         {argSigVarEnv = interfaceSigArgSigVarEnv, 
                                          bodySigVarEnv = (#2 interfaceSigBodyEnv)})
                        end
                    )
                    SEnv.empty
                    funBindInfoEqs
      in
          (* note:
           * the first returned the pair is the interface that will be
           * put in the object file. To simplify the object interface type
           * checking(linking only check the type equivalence), we directly use 
           * the untouched interface type environment, instead of some instantiated 
           * interface envrionment.
           *)
          ((interfaceSigEnv, interfaceSigFunEnv), (#2 instInterfaceSigEnv, functorInstInfoEnv))
      end
end
end
