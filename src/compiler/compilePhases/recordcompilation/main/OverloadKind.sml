(**
 * @copyright (c) 2011, Tohoku University.
 * @author UENO Katsuhiro
 * @author Atsushi Ohori
 *)
structure OverloadKind : KIND_INSTANCE =
struct
  structure RC = RecordCalc
  structure T = Types

  type singleton_ty_body = Types.oprimSelector
  type kind = {instances : Types.ty list, operators : Types.oprimSelector list}
  val singletonTy = T.INSTCODEty

  datatype instance =
      APP of {appExp: RecordCalc.rcexp -> RecordCalc.rcexp,
              argTy: Types.ty, bodyTy: Types.ty,
              singletonTy: Types.singletonTy, loc: RecordCalc.loc}
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

  fun compare
        ({oprimId=id1, longsymbol=_, match=match1}
         :T.oprimSelector,
         {oprimId=id2, longsymbol=_, match=match2}
         :T.oprimSelector) =
      case OPrimID.compare (id1, id2) of
        EQUAL => compareKeyTyList (matchToKeyList match1, matchToKeyList match2)
      | x => x

  fun evalMatch (match, sty, loc) =
      case match of
        T.OVERLOAD_EXVAR {exVarInfo as {ty,...}, instTyList} =>
        let
          val varExp = RC.RCEXVAR exVarInfo
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

  fun generateInstance {btvEnv, lookup} (selector as {oprimId, match, ...})
                       loc =
      evalMatch (match, T.INSTCODEty selector, loc)

  fun generateArgs (btvEnv:Types.btvEnv) (btv, {instances, operators}) =
      map (fn operator as {match, ...} =>
              (app (fn ty => case TypesBasics.derefTy ty of
                               T.BOUNDVARty t =>
                               if BoundTypeVarID.Map.inDomain (btvEnv, t)
                               then ()
                               else raise Bug.Bug "generateSingletonTy"
                             | _ => ())
                   (matchToKeyList match);
               T.INSTCODEty operator))
          operators

end
