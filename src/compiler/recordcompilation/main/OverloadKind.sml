(**
 * @copyright (c) 2011, Tohoku University.
 * @author UENO Katsuhiro
 * @author Atsushi Ohori
 *)
structure OverloadKind : sig

  val compareSelector : Types.oprimSelector * Types.oprimSelector -> order

  val generateSingletonTy : Types.btvEnv
                            -> {instances: Types.ty list,
                                operators: Types.oprimSelector list}
                            -> Types.singletonTy list

  datatype instance =
      APP of {appExp: RecordCalc.rcexp -> RecordCalc.rcexp,
              argTy: Types.ty, bodyTy: Types.ty,
              singletonTy: Types.singletonTy, loc: Loc.loc}
    (* instance may contain RCTAPP. need more type-directed compilation *)
    | EXP of RecordCalc.rcexp

  val generateInstance : Types.oprimSelector
                         -> Loc.loc
                         -> instance option

end =
struct

  structure RC = RecordCalc
  structure T = Types

  datatype instance =
      APP of {appExp: RC.rcexp -> RC.rcexp, argTy: T.ty, bodyTy: T.ty,
              singletonTy: T.singletonTy, loc: Loc.loc}
    | EXP of RecordCalc.rcexp

  fun matchToKeyList match =
      case match of
        T.OVERLOAD_EXVAR _ => nil
      | T.OVERLOAD_PRIM _ => nil
      | T.OVERLOAD_CASE (ty1, matches) =>
        ty1 :: List.concat (map matchToKeyList (TypID.Map.listItems matches))

  fun compareKeyTy (ty1, ty2) =
      case (TypesBasics.derefTy ty1, TypesBasics.derefTy ty2) of
        (T.BOUNDVARty t1, T.BOUNDVARty t2) => BoundTypeVarID.compare (t1, t2)
      | (T.BOUNDVARty _, T.CONSTRUCTty _) => LESS
      | (T.CONSTRUCTty _, T.BOUNDVARty _) => GREATER
      | (T.CONSTRUCTty {tyCon={id=id1,...},...},
         T.CONSTRUCTty {tyCon={id=id2,...},...}) => TypID.compare (id1, id2)
      | _ => raise Bug.Bug "compareKeyTy"

  fun compareKeyTyList (nil, nil) = EQUAL
    | compareKeyTyList (nil, _::_) = LESS
    | compareKeyTyList (_::_, nil) = GREATER
    | compareKeyTyList (ty1::tys1, ty2::tys2) =
      case compareKeyTy (ty1, ty2) of
        EQUAL => compareKeyTyList (tys1, tys2)
      | x => x

  fun compareSelector
        ({oprimId=id1, longsymbol=_, keyTyList=_, match=match1, instMap=_}
         :T.oprimSelector,
         {oprimId=id2, longsymbol=_, keyTyList=_, match=match2, instMap=_}
         :T.oprimSelector) =
      case OPrimID.compare (id1, id2) of
        EQUAL => compareKeyTyList (matchToKeyList match1, matchToKeyList match2)
      | x => x

  fun evalMatch (match, sty, loc) =
      case match of
        T.OVERLOAD_EXVAR {exVarInfo={longsymbol, ty}, instTyList} =>
        let
          val varExp = RC.RCEXVAR {path=Symbol.longsymbolToLongid longsymbol,
                                   ty=ty}
          val (retExp, retTy) =
              case instTyList of
                nil => (varExp, ty)
              | _::_ => (RC.RCTAPP {exp = varExp, expTy = ty,
                                    instTyList = instTyList, loc = loc},
                         TypesBasics.tpappTy (ty, instTyList))
        in
          SOME (EXP (RC.RCCAST ((retExp, retTy), T.SINGLETONty sty, loc)))
        end
      | T.OVERLOAD_PRIM {primInfo, instTyList} =>
        let
          val (argTy, retTy) =
              case TypesBasics.tpappTy (#ty primInfo, instTyList) of
                T.FUNMty ([argTy], retTy) => (argTy, retTy)
              | _ => raise Bug.Bug "evalMatch: OVERLOAD_PRIM"
        in
          SOME (APP {appExp = fn argExp =>
                                 RC.RCPRIMAPPLY {primOp = primInfo,
                                                 instTyList = instTyList,
                                                 argExp = argExp,
                                                 loc = loc},
                     argTy = argTy,
                     bodyTy = retTy,
                     singletonTy = sty,
                     loc = loc})
        end
      | T.OVERLOAD_CASE (caseTy, matches) =>
        case TypesBasics.derefTy caseTy of
          T.CONSTRUCTty {tyCon={id,...},...} =>
          (case TypID.Map.find (matches, id) of
             SOME match => evalMatch (match, sty, loc)
           | NONE => NONE)
        | _ => NONE

  fun generateInstance (selector as {oprimId, match, ...}:T.oprimSelector) loc =
      evalMatch (match, T.INSTCODEty selector, loc)

  fun generateSingletonTy (btvEnv:Types.btvEnv) {instances:T.ty list, operators} =
      map (fn operator as {keyTyList, match, ...} =>
              (app (fn ty => case TypesBasics.derefTy ty of
                               T.BOUNDVARty t =>
                               if BoundTypeVarID.Map.inDomain (btvEnv, t)
                               then ()
                               else raise Bug.Bug "generateSingletonTy"
                             | _ => ())
                   (keyTyList @ matchToKeyList match);
               T.INSTCODEty operator))
          operators

end
