(**
 * compute least general type scheme,
 * only applied to type in top level
 * 
 * @copyright (c) 2006, Tohoku University. 
 * @author Liu Bochao
 * @version $Id: AntiUnifier.sml,v 1.5 2006/12/09 11:17:58 ohori Exp $
 *)
structure AntiUnifier =
struct
  local
      structure SC = SigCheck
      structure TU = TypesUtils
      structure LE = LinkError
      open Types
           
      fun tyToString ty = (TypeFormatter.tyToString ty ^ "\n")
      local
          fun toInt ty =
              case ty of 
                  ALIASty _ => 1
                | TYVARty _ => 2
                | CONty _ => 3
                | FUNMty _ => 4
                | RECORDty _ => 5
                | SPECty _ => 6
                | _ => raise Control.Bug ("illegal type in spec:"^ tyToString ty)
      in
          fun compareTy (ty1, ty2) = 
              let
                  exception exStop of order
                                      
                  fun compareList (tys1, tys2) =
                      (case Int.compare(length tys1, length tys2) of
                           EQUAL => 
                           foldl (fn ((ty1, ty2), order) =>
                                     case compareTy(ty1, ty2) of
                                         EQUAL => order
                                       | order => raise exStop order)
                                 EQUAL
                                 (ListPair.zip (tys1,tys2))
                         | order => order)
                      handle exStop order => order
                                             
                  fun compareTyFields (tyFields1, tyFields2) =
                      (SEnv.foldli 
                           (fn (label1, ty1, order) =>
                               case SEnv.find(tyFields2, label1) of
                                   NONE => GREATER
                                 | SOME ty2 =>
                                   (case compareTy (ty1, ty2) of
                                        EQUAL => order
                                      | order => raise exStop order)
                                   )
                           EQUAL
                           tyFields1)
                      handle exStop order => order
              in
                  case Int.compare(toInt ty1, toInt ty2) of
                      EQUAL =>
                      (case (ty1, ty2) of
                           (ALIASty (_, ty1), ALIASty (_, ty2)) =>
                           compareTy (ty1, ty2)
                         | (TYVARty(ref (TVAR {id = id1, ...})), 
                            TYVARty(ref (TVAR {id = id2, ...}))) =>
                           Int.compare (id1, id2)
                         | (CONty{tyCon = {id = id1,...}, args = args1},
                            CONty{tyCon = {id = id2,...}, args = args2}) =>
                           (case ID.compare(id1, id2) of
                                EQUAL => compareList (args1, args2)
                              | order => order)
                         | (FUNMty(domainTyList1, rangeTy1), 
                            FUNMty(domainTyList2, rangeTy2)) =>
                           compareList (domainTyList1 @ [rangeTy1],
                                        domainTyList2 @ [rangeTy2])
                         | (RECORDty tyFields1, RECORDty tyFields2) => 
                           (case Int.compare(SEnv.numItems (tyFields1),
                                             SEnv.numItems (tyFields2)) of
                                EQUAL =>
                                compareTyFields (tyFields1, tyFields2)
                              | order => order)
                         | (SPECty ty1, SPECty ty2) => compareTy (ty1, ty2)
                         | _ => 
                           raise Control.Bug ("illegal type in spec: ty1 = "^ (tyToString ty1) 
                                              ^ ", ty2 = " ^ (tyToString ty2))
                                 )
                    | order => order
              end
                  
         structure TypeOrd : ordsig = 
          struct 
               type ord_key = ty * ty
               fun compare ((ty11, ty12), (ty21, ty22)) =
                   case compareTy (ty11, ty21) of
                       EQUAL => compareTy (ty12, ty22)
                     | order => order
          end
      end
      structure TypeEnv = BinaryMapFn(TypeOrd)
  in
      fun antiUnifierList subst (tys1, tys2) =
          foldl 
              (fn ((ty1, ty2), (tys, subst)) =>
                  let
                      val (newTy, subst) =
                          antiUnifierImpl subst (ty1, ty2) 
                  in
                      (tys @ [newTy], subst)
                  end)
              (nil,  subst)
              (ListPair.zip(tys1, tys2))

      and antiUnifierImpl subst (ty1, ty2) =
          let
              fun genSubstTy (ty1,ty2) subst =
                  let
                      val newVar = newty univKind
                  in
                      (newVar, TypeEnv.insert(subst, (ty1, ty2), newVar))
                  end
              fun lookupSubstTy (ty1,ty2) subst =
                  case TypeEnv.find(subst, (ty1,ty2)) of
                      NONE => genSubstTy (ty1, ty2) subst
                    | SOME ty => (ty, subst)
          in
              case (ty1, ty2) of
                  (ALIASty (_,ty1), ty2) => antiUnifierImpl subst (ty1, ty2)
                | (ty1, ALIASty (_,ty2)) => antiUnifierImpl subst (ty1, ty2)
                | (SPECty ty1, SPECty ty2) => 
                  let
                      val (newTy1, subst) = antiUnifierImpl subst (ty1, ty2)
                      val newTy2 = 
                          case newTy1 of
                              CONty _ => SPECty newTy1
                            | TYVARty _ => newTy1
                  in
                      (newTy2, subst)
                  end
                | (FUNMty (domTyList1, ranTy1), FUNMty (domTyList2, ranTy2)) =>
                  if length domTyList1 = length domTyList2 then
                      let
                          val (domTyList, subst) = 
                              antiUnifierList subst (domTyList1, 
                                                     domTyList2)
                          val (ranTy, subst) = 
                              antiUnifierImpl subst (ranTy1, ranTy2)
                      in
                          (FUNMty (domTyList, ranTy), subst)
                      end
                  else lookupSubstTy (ty1,ty2) subst
                | (CONty{tyCon = 
                         {id = id1, name, strpath, abstract, tyvars, eqKind, boxedKind, datacon}, 
                         args = tyList1},
                   CONty{tyCon = {id = id2,...}, args = tyList2}) =>
                  let
                      val (newTyList, subst) =
                          antiUnifierList subst (tyList1, tyList2)
                      val (newTy, subst) = 
                          if ID.eq(id1, id2)
                          then
                              (CONty{tyCon = {id = id2, 
                                              name = name, 
                                              strpath = strpath, 
                                              abstract =  abstract, 
                                              tyvars = tyvars, 
                                              eqKind = eqKind, 
                                              boxedKind = boxedKind,
                                              datacon = datacon},
                                     args = newTyList},
                               subst)
                          else lookupSubstTy (ty1, ty2) subst
                  in (newTy, subst) end
            | (TYVARty(ref (TVAR {id = id1, ...})), 
               TYVARty(ref (TVAR {id = id2, ...}))) =>
              if id1 = id2 then raise Control.Bug "duplicate tyvar"
              else lookupSubstTy (ty1, ty2) subst
            | (RECORDty tys1, RECORDty tys2) =>
              let
                  exception ExnNotEqualType
                  fun checkEqualLabel nil nil subst = 
                      (SEnv.empty, subst)
                    | checkEqualLabel ((label1, ty1):: tail1) ((label2, ty2) :: tail2) subst =
                      if label1 = label2 
                      then
                          let
                              val (newTy, newSubst1) = 
                                  antiUnifierImpl subst (ty1,ty2)
                              val (newTyTail, newSubst2) =
                                  checkEqualLabel tail1 tail2 newSubst1
                          in
                              (SEnv.insert(newTyTail, label1, newTy), newSubst2)
                          end
                      else raise ExnNotEqualType
                    | checkEqualLabel _ _ subst = raise ExnNotEqualType
                  val tys1 = SEnv.listItemsi tys1
                  val tys2 = SEnv.listItemsi tys2
                  val (newTy, newSubst) = 
                      let
                          val (newTys, newSubst) = checkEqualLabel tys1 tys2 subst
                      in
                          (RECORDty newTys, newSubst)
                      end handle ExnNotEqualType => lookupSubstTy (ty1,ty2) subst
              in  
                  (newTy, newSubst)
              end 

            | (ty1, ty2) => lookupSubstTy (ty1,ty2) subst
          end

      fun antiUnifier (ty1, ty2) =
          let
              val (monoTy, subst) = 
                  antiUnifierImpl TypeEnv.empty (TU.freshInstTy ty1, TU.freshInstTy ty2)
              val generalizedTy = 
                  case monoTy of
                      TYVARty _ => raise LE.UnEquivalentImportType{ty1 = ty1, ty2 = ty2}
                    | _ => 
                      let
                          val {boundEnv, removedTyIds} = 
                            (* Ohori: Dec 6, 2006.
                              TU.generalizer (monoTy, SEnv.empty, SEnv.empty)
                            *)
                              TU.generalizer (monoTy, toplevelDepth)
                      in 
                          if IEnv.isEmpty boundEnv
                          then monoTy
                          else POLYty{boundtvars = boundEnv, body = monoTy}
                      end

          in
              generalizedTy 
          end
  end (* end local *)   
end (* end structure *)
