(**
 * @copyright (c) 2011, Tohoku University.
 * @author UENO Katsuhiro
 *)
structure TypeCheckBitmapANormal : sig

  val typecheck : BitmapANormal.baexp -> unit

end =
struct

  structure T = AnnotatedTypes
  structure A = BitmapANormal
  structure BV = BuiltinEnv
  
  val dummyAnnotation =
      ref {labels = T.LE_LABELS AnnotationLabelID.Set.empty,
           boxed = true, align = true}
      : T.recordAnnotation ref

  fun error (loc, msg) =
      TextIO.output
        (TextIO.stdErr,
         Control.prettyPrint (Loc.format_loc loc) ^ ": " ^ msg ^ "\n")

  fun flattenTy ty =
      case ty of
        T.MVALty tys => flattenTyList tys
      | _ => [ty]

  and flattenTyList tys = List.concat (map flattenTy tys)

  fun PolyTy (btvEnv, ty) =
      if BoundTypeVarID.Map.isEmpty btvEnv
      then ty
      else T.POLYty {boundtvars = btvEnv, body = ty}

  datatype expTy =
      RETURN of T.ty list
    | MERGE of T.ty list
    | RAISE

  fun expTyToString expTy =
      case expTy of
        RETURN tys =>
        "RETURN " ^ Control.prettyPrint (T.format_ty (T.MVALty tys))
      | MERGE tys =>
        "MERGE " ^ Control.prettyPrint (T.format_ty (T.MVALty tys))
      | RAISE => "RAISE"

  fun recordFieldTys (btvEnv:T.btvEnv, ty) =
      case ty of
        T.SINGLETONty _ => NONE
      | T.ERRORty => NONE
      | T.DUMMYty _ => NONE
      | T.FUNMty _ => NONE
      | T.MVALty _ => NONE
      | T.RECORDty {fieldTypes,...} => SOME fieldTypes
      | T.CONty _ => NONE
      | T.POLYty _ => NONE
      | T.BOUNDVARty id =>
        case BoundTypeVarID.Map.find (btvEnv, id) of
          NONE => NONE
        | SOME {tvarKind, ...} =>
          case tvarKind of
            T.UNIV => NONE
          | T.OPRIMkind _ => NONE
          | T.REC fields => SOME fields

  fun selectFieldTy (msg, loc) env (recordTy, label) =
      case recordFieldTys (env, recordTy) of
        NONE =>
        (error (loc, msg ^ ": is not a record type: "
                     ^ Control.prettyPrint (T.format_ty recordTy));
         T.ERRORty)
      | SOME map =>
        case LabelEnv.find (map, label) of
          NONE =>
          (error (loc, msg ^ ": label `" ^ label ^ "'not found in recordTy: "
                       ^ Control.prettyPrint (T.format_ty recordTy));
           T.ERRORty)
        | SOME ty => ty

  fun checkTy (arg as (msg, loc)) (env:T.btvEnv) ty =
      case ty of
        T.SINGLETONty sty => checkSingletonTy arg env sty
      | T.ERRORty => error (loc, msg ^ ": ERRORty found")
      | T.DUMMYty id => ()
      | T.BOUNDVARty id =>
        if BoundTypeVarID.Map.inDomain (env, id) then ()
        else error (loc, msg ^ ": unbound BOUNDVARty "
                         ^ Control.prettyPrint (T.format_ty ty))
      | T.FUNMty {argTyList, bodyTy, annotation, funStatus} =>
        (app (checkTy arg env) argTyList;
         checkTy arg env bodyTy)
      | T.MVALty tys => app (checkTy arg env) tys
      | T.RECORDty {fieldTypes, annotation} =>
        app (checkTy arg env) (LabelEnv.listItems fieldTypes)
      | T.CONty {tyCon, args} => app (checkTy arg env) args
      | T.POLYty {boundtvars, body} =>
        let
          val env = BoundTypeVarID.Map.unionWith #2 (env, boundtvars)
          val _ = app (checkBtvKind arg env)
                      (BoundTypeVarID.Map.listItemsi boundtvars)
        in
          checkTy arg env body
        end

  and checkSingletonTy (arg as (msg, loc)) env sty =
      case sty of
        T.INSTCODEty {oprimId, path, keyTyList} =>
        app (checkTy arg env) keyTyList
      | T.INDEXty (label, ty) =>
        (* ty must have "label" field *)
        checkTy arg env ty
      | T.TAGty ty => checkTy arg env ty
      | T.SIZEty ty => checkTy arg env ty
      | T.RECORDSIZEty ty =>
        (if isSome (recordFieldTys (env, ty)) then ()
         else error (loc, msg ^ ": expected record type: "
                          ^ Control.prettyPrint (T.format_singletonTy sty));
         checkTy arg env ty)
      | T.RECORDBITMAPty (i, ty) =>
        (if isSome (recordFieldTys (env, ty)) then ()
         else error (loc, msg ^ ": expected record type: "
                          ^ Control.prettyPrint (T.format_singletonTy sty));
         checkTy arg env ty)

  and checkTvarKind arg env kind =
      case kind of
        T.UNIV => ()
      | T.OPRIMkind instances => app (checkTy arg env) instances
      | T.REC fields => app (checkTy arg env) (LabelEnv.listItems fields)

  and checkBtvKind (arg as (msg, loc)) env
                   (btvId, {id, tvarKind, eqKind}:T.btvKind) =
      (
        if btvId = id then ()
        else error (loc, msg ^ ": bound type id mismatch\n"
                         ^ "\tid: " ^ BoundTypeVarID.toString btvId
                         ^ "\n\tbtvKind: " ^ BoundTypeVarID.toString id);
        checkTvarKind arg env tvarKind
      )

  local
    exception Unify

    fun unifyError' tyToString (msg, loc) (ty1, ty2) =
        error (loc, msg ^ ": type unification failed"
                    ^ "\n\tty1: " ^ tyToString ty1
                    ^ "\n\tty2: " ^ tyToString ty2)

    fun unifyError arg pair =
        unifyError' (fn ty => Control.prettyPrint (T.format_ty ty)) arg pair

    fun unifyExpTyError arg pair =
        unifyError' expTyToString arg pair

    datatype tvState =
        SUBSTITUTED of unit ref
      | TVAR of T.btvKind

    type btvSubst =
         tvState ref BoundTypeVarID.Map.map
         * tvState ref BoundTypeVarID.Map.map

    val emptyBtvSubst =
        (BoundTypeVarID.Map.empty, BoundTypeVarID.Map.empty) : btvSubst

    fun extendBtvSubst ((subst11, subst12), (subst21, subst22)) =
        (BoundTypeVarID.Map.unionWith #1 (subst11, subst21),
         BoundTypeVarID.Map.unionWith #2 (subst12, subst22)) : btvSubst

    fun allSubstituted subst =
        BoundTypeVarID.Map.foldl
          (fn (ref (SUBSTITUTED _), z) => z
            | (ref (TVAR _), z) => false)
          true
          subst
  in

  fun unifyTy (btv:btvSubst) (ty1, ty2) =
      case (ty1, ty2) of
        (T.SINGLETONty sty1, T.SINGLETONty sty2) =>
        unifySingletonTy btv (sty1, sty2)
      | (T.ERRORty, T.ERRORty) => ()
      | (T.DUMMYty id1, T.DUMMYty id2) =>
        if id1 = id2 then () else raise Unify
      | (T.BOUNDVARty id1, T.BOUNDVARty id2) =>
        (
          case (BoundTypeVarID.Map.find (#1 btv, id1),
                BoundTypeVarID.Map.find (#2 btv, id2)) of
            (SOME (ref (SUBSTITUTED id1)), SOME (ref (SUBSTITUTED id2))) =>
            if id1 = id2 then () else raise Unify
          | (SOME (r1 as ref (TVAR kind1)), SOME (r2 as ref (TVAR kind2))) =>
            (unifyBtvKind btv (kind1, kind2);
             let val id = ref ()
             in r1 := SUBSTITUTED id; r2 := SUBSTITUTED id
             end)
          | (NONE, NONE) =>
            if BoundTypeVarID.eq (id1, id2) then () else raise Unify
          | _ => raise Unify
        )
      | (T.FUNMty {argTyList=argTys1, bodyTy=retTy1, ...},
         T.FUNMty {argTyList=argTys2, bodyTy=retTy2, ...}) =>
        (unifyTyList btv (argTys1, argTys2);
         unifyTy btv (retTy1, retTy2))
      | (T.MVALty tys1, T.MVALty tys2) =>
        unifyTyList btv (flattenTyList tys1, flattenTyList tys2)
      | (T.RECORDty {fieldTypes=fields1, ...},
         T.RECORDty {fieldTypes=fields2, ...}) =>
        unifyRecordFields btv (fields1, fields2)
      | (T.CONty {tyCon=tyCon1, args=args1},
         T.CONty {tyCon=tyCon2, args=args2}) =>
        (if TypID.eq (#id tyCon1, #id tyCon2) then () else raise Unify;
         unifyTyList btv (args1, args2))
      | (T.POLYty {boundtvars=btvEnv1, body=body1},
         T.POLYty {boundtvars=btvEnv2, body=body2}) =>
        let
          val btv2 = unifyBtvEnv (btvEnv1, btvEnv2)
          val _ = unifyTy (extendBtvSubst (btv, btv2)) (body1, body2)
        in
          if allSubstituted (#1 btv2) andalso allSubstituted (#2 btv2)
          then () else raise Unify
        end
      | (T.SINGLETONty _, _) => raise Unify
      | (T.ERRORty, _) => raise Unify
      | (T.DUMMYty _, _) => raise Unify
      | (T.BOUNDVARty _, _) => raise Unify
      | (T.FUNMty _, _) => raise Unify
      | (T.MVALty _, _) => raise Unify
      | (T.RECORDty _, _) => raise Unify
      | (T.CONty _, _) => raise Unify
      | (T.POLYty _, _) => raise Unify

  and unifyTyList btv (tys1, tys2) =
      app (unifyTy btv)
          (ListPair.zipEq (tys1, tys2)
           handle ListPair.UnequalLengths => raise Unify)

  and unifyRecordFields btv (fields1, fields2) =
      let
        val (labels1, tys1) = ListPair.unzip (LabelEnv.listItemsi fields1)
        val (labels2, tys2) = ListPair.unzip (LabelEnv.listItemsi fields2)
        val pairs = ListPair.zipEq (labels1, labels2)
                    handle ListPair.UnequalLengths => raise Unify
        val _ = app (fn (l1, l2) => if l1 = l2 then () else raise Unify) pairs
      in
        unifyTyList btv (tys1, tys2)
      end

  and unifySingletonTy btv (sty1, sty2) =
      case (sty1, sty2) of
        (T.INSTCODEty {oprimId=id1,...}, T.INSTCODEty {oprimId=id2,...}) =>
        if OPrimID.eq (id1, id2) then () else raise Unify
      | (T.INDEXty (label1, ty1), T.INDEXty (label2, ty2)) =>
        (if label1 = label2 then () else raise Unify;
         unifyTy btv (ty1, ty2))
      | (T.TAGty ty1, T.TAGty ty2) =>
        unifyTy btv (ty1, ty2)
      | (T.SIZEty ty1, T.SIZEty ty2) =>
        unifyTy btv (ty1, ty2)
      | (T.RECORDSIZEty ty1, T.RECORDSIZEty ty2) =>
        unifyTy btv (ty1, ty2)
      | (T.RECORDBITMAPty (i1, ty1), T.RECORDBITMAPty (i2, ty2)) =>
        (if i1 = i2 then () else raise Unify;
         unifyTy btv (ty1, ty2))
      | (T.INSTCODEty _, _) => raise Unify
      | (T.INDEXty _, _) => raise Unify
      | (T.TAGty _, _) => raise Unify
      | (T.SIZEty _, _) => raise Unify
      | (T.RECORDSIZEty _, _) => raise Unify
      | (T.RECORDBITMAPty _, _) => raise Unify

  and unifyTvarKind btv (kind1, kind2) =
      case (kind1, kind2) of
        (T.UNIV, T.UNIV) => ()
      | (T.OPRIMkind inst1, T.OPRIMkind inst2) =>
        unifyTyList btv (inst1, inst2)
      | (T.REC fields1, T.REC fields2) =>
        unifyRecordFields btv (fields1, fields2)
      | (T.UNIV, _) => raise Unify
      | (T.OPRIMkind _, _) => raise Unify
      | (T.REC _, _) => raise Unify

  and unifyBtvEnv (btvEnv1, btvEnv2) =
      let
        val btvs1 = BoundTypeVarID.Map.listItemsi btvEnv1
        val btvs2 = BoundTypeVarID.Map.listItemsi btvEnv2
        val pairs = ListPair.zipEq (btvs1, btvs2)
                    handle UnequalLengths => raise Unify
      in
        foldl
          (fn (((id1, kind1), (id2, kind2)), (subst1, subst2)) =>
              (BoundTypeVarID.Map.insert (subst1, id1, ref (TVAR kind1)),
               BoundTypeVarID.Map.insert (subst2, id2, ref (TVAR kind2))))
          emptyBtvSubst
          pairs
      end

  and unifyBtvKind btv ({id=_, tvarKind=kind1, eqKind=eq1}:T.btvKind,
                        {id=_, tvarKind=kind2, eqKind=eq2}:T.btvKind) =
      (* ignore id *)
      (unifyTvarKind btv (kind1, kind2);
       unifyEqKind (eq1, eq2))

  and unifyEqKind (eqKind1, eqKind2) =
      case (eqKind1, eqKind2) of
        (Absyn.EQ, Absyn.EQ) => ()
      | (Absyn.EQ, Absyn.NONEQ) => raise Unify
      | (Absyn.NONEQ, Absyn.NONEQ) => ()
      | (Absyn.NONEQ, Absyn.EQ) => raise Unify

  fun unify arg (ty1, ty2) =
      unifyTy emptyBtvSubst (ty1, ty2)
      handle Unify => unifyError arg (ty1, ty2)

  fun unifyMVAL arg (tys1, tys2) =
      unifyTyList emptyBtvSubst (tys1, tys2)
      handle Unify => unifyError arg (T.MVALty tys1, T.MVALty tys2)

  fun unifyExpTy (arg as (msg, loc)) (ty1, ty2) =
      case (ty1, ty2) of
        (RETURN tys1, RETURN tys2) =>
        (unifyTyList emptyBtvSubst (tys1, tys2)
         handle Unify => unifyExpTyError arg (ty1, ty2))
      | (RETURN _, MERGE _) => unifyExpTyError arg (ty1, ty2)
      | (RETURN _, RAISE) => ()
      | (MERGE tys1, MERGE tys2) =>
        (unifyTyList emptyBtvSubst (tys1, tys2)
         handle Unify => unifyExpTyError arg (ty1, ty2))
      | (MERGE _, RETURN _) => unifyExpTyError arg (ty1, ty2)
      | (MERGE _, RAISE) => ()
      | (RAISE, RETURN _) => ()
      | (RAISE, MERGE _) => ()
      | (RAISE, RAISE) => ()

  end (* local *)

  type env =
      {
        funTy: T.ty,
        varEnv: A.varInfo VarID.Map.map,
        exVarEnv: A.exVarInfo PathEnv.map,
        btvEnv: T.btvEnv
      }

  fun emptyEnv () =
      {funTy = AnnotatedTypesUtils.makeClosureFunTy (nil, T.MVALty nil),
       varEnv = VarID.Map.empty,
       exVarEnv = PathEnv.empty,
       btvEnv = BoundTypeVarID.Map.empty} : env

  fun setFunTy (env:env, funTy) =
      {funTy = funTy,
       varEnv = #varEnv env,
       exVarEnv = #exVarEnv env,
       btvEnv = #btvEnv env} : env

  fun bindVar (env:env, var as {id, ...}) =
      {funTy = #funTy env,
       varEnv = VarID.Map.insert (#varEnv env, id, var),
       exVarEnv = #exVarEnv env,
       btvEnv = #btvEnv env} : env

  fun bindVars (env, vars) =
      foldl (fn (v,z) => bindVar (z,v)) env vars

  fun bindExternVar (env:env, exVarInfo as {path,...}) =
      {funTy = #funTy env,
       varEnv = #varEnv env,
       exVarEnv = PathEnv.insert (#exVarEnv env, path, exVarInfo),
       btvEnv = #btvEnv env} : env

  fun bindTyvars (env:env, btvEnv) =
      {funTy = #funTy env,
       varEnv = #varEnv env,
       exVarEnv = #exVarEnv env,
       btvEnv = BoundTypeVarID.Map.unionWith #2 (#btvEnv env, btvEnv)} : env

  fun typecheckTy (msg, loc) (env:env) ty =
      checkTy (msg, loc) (#btvEnv env) ty

  fun typecheckFunTy (msg, loc) (env:env) ty =
      (
        typecheckTy (msg, loc) env ty;
        case ty of
          T.FUNMty {argTyList, bodyTy, ...} =>
          (flattenTyList argTyList, flattenTy bodyTy)
        | _ =>
          (error (loc, msg ^ ": not a function type: "
                       ^ Control.prettyPrint (T.format_ty ty));
           ([T.ERRORty], [T.ERRORty]))
      )

  fun typecheckForeignFunTy (msg, loc) env
                            ({argTyList, resultTy, attributes}:T.foreignFunTy) =
      (
        app (typecheckTy (msg ^ ": argTyList", loc) env) argTyList;
        typecheckTy (msg ^ ": resultTy", loc) env resultTy;
        (flattenTyList argTyList, flattenTy resultTy)
      )

  fun typecheckVar (msg, loc) (env:env) (var as {path, ty, id}:A.varInfo) =
      (
        typecheckTy (msg, loc) env ty;
        case VarID.Map.find (#varEnv env, id) of
          NONE => (error (loc, msg ^ ": unbound variable "
                               ^ Control.prettyPrint (A.format_varInfo var));
                   T.ERRORty)
        | SOME (var2 as {path=path2, ty=ty2, id=id2}) =>
          (if PathEnv.Key.compare (path, path2) = EQUAL then ()
           else error (loc, msg ^ ": variable path mismatch:\n\tvar: "
                            ^ Control.prettyPrint (A.format_varInfo var)
                            ^ "\n\tenv: "
                            ^ Control.prettyPrint (A.format_varInfo var2));
           unify (msg, loc) (ty, ty2);
           ty)
      )

  fun typecheckExVar (msg, loc) (env:env) (var as {path, ty}:A.exVarInfo) =
      (
        typecheckTy (msg, loc) env ty;
        case PathEnv.find (#exVarEnv env, path) of
          NONE => (error (loc, msg ^ ": unbound external variable "
                               ^ Control.prettyPrint (A.format_exVarInfo var));
                   T.ERRORty)
        | SOME {path, ty=ty2} =>
          (unify (msg, loc) (ty, ty2); ty)
      )

  fun typecheckConstTerm const =
      case const of
        ConstantTerm.INT _ => T.intty
      | ConstantTerm.LARGEINT _ => T.largeIntty
      | ConstantTerm.WORD _ => T.wordty
      | ConstantTerm.BYTE _ => T.bytety
      | ConstantTerm.STRING _ => T.stringty
      | ConstantTerm.REAL _ => T.realty
      | ConstantTerm.FLOAT _ => T.floatty
      | ConstantTerm.CHAR _ => T.charty
      | ConstantTerm.UNIT => T.unitty
      | ConstantTerm.NULLPOINTER =>
        T.CONty {tyCon = BV.PTRtyCon, args = [T.unitty]}
      | ConstantTerm.NULLBOXED =>
        T.CONty {tyCon = BV.BOXEDtyCon, args = []}

  fun typecheckConst loc env baconst =
      case baconst of
        A.BAGLOBALSYMBOL {name, kind, ty} =>
        (typecheckTy ("BAGLOBALSYMBOL", loc) env ty; ty)
      | A.BACONSTANT const =>
        typecheckConstTerm const

  fun typecheckValue loc env bavalue =
      case bavalue of
        A.BACONST const => typecheckConst loc env const
      | A.BAVAR var => typecheckVar ("BAVAR", loc) env var
      | A.BACAST {exp, expTy, targetTy} =>
        let
          val ty = typecheckValue loc env exp
          val _ = typecheckTy ("BACAST: expTy", loc) env expTy
          val _ = typecheckTy ("BACAST: targetTy", loc) env targetTy
          val _ = unify ("BACAST", loc) (ty, expTy)
          val rty1 =
              case TypeLayout.runtimeTy (#btvEnv env) expTy of
                NONE =>
                (error (loc, "BACAST: expTy: runtime type not found: "
                             ^ Control.prettyPrint (T.format_ty expTy)); NONE)
              | SOME ty => SOME ty
          val rty2 =
              case TypeLayout.runtimeTy (#btvEnv env) expTy of
                NONE =>
                (error (loc, "BACAST: targetTy: runtime type not found: "
                             ^ Control.prettyPrint (T.format_ty expTy)); NONE)
              | SOME ty => SOME ty
          val _ =
                if rty1 = rty2 then ()
                else error (loc, "BACAST: incompatible types"
                                 ^ "\n\tty1: "
                                 ^ Control.prettyPrint (T.format_ty expTy)
                                 ^ "\n\tty2: "
                                 ^ Control.prettyPrint (T.format_ty targetTy))
        in
          targetTy
        end
      | A.BATAPP {exp, expTy, instTyList} =>
        let
          val ty = typecheckValue loc env exp
          val _ = typecheckTy ("BATAPP: expTy", loc) env expTy
          val _ = app (typecheckTy ("BATAPP: instTy", loc) env) instTyList
          val _ = unify ("BATAPP", loc) (ty, expTy)
        in
          AnnotatedTypesUtils.tpappTy (expTy, instTyList)
        end

  fun typecheckPrim loc env baprim =
      case baprim of
        A.BAVALUE value =>
        typecheckValue loc env value
      | A.BAEXVAR {exVarInfo, varSize} =>
        let
          val varTy = typecheckExVar ("BAEXVAR", loc) env exVarInfo
          val varSizeTy = typecheckValue loc env varSize
          val sizeTy = T.SINGLETONty (T.SIZEty (#ty exVarInfo))
          val _ = unify ("BAEXVAR", loc) (varSizeTy, sizeTy)
        in
          varTy
        end
      | A.BAPRIMAPPLY {primInfo, argExpList, instTyList, instTagList,
                       instSizeList} =>
        let
          val primTy = AnnotatedTypesUtils.tpappTy (#ty primInfo, instTyList)
          val (argTys, retTys) = typecheckFunTy ("BAPRIMAPPLY", loc) env primTy
          val argExpTys = map (typecheckValue loc env) argExpList
          val _ = app (typecheckTy ("BAPRIMAPPLY: instTy", loc) env) instTyList
          val instTagTys = map (typecheckValue loc env) instTagList
          val instSizeTys = map (typecheckValue loc env) instSizeList
          val _ = unifyMVAL ("BAPRIMAPPLY: arg", loc) (argExpTys, argTys)
          val tagTys = map (fn ty => T.SINGLETONty (T.TAGty ty)) instTyList
          val sizeTys = map (fn ty => T.SINGLETONty (T.SIZEty ty)) instTyList
          val _ = unifyMVAL ("BAPRIMAPPLY: tag", loc) (instTagTys, tagTys)
          val _ = unifyMVAL ("BAPRIMAPPLY: size", loc) (instSizeTys, sizeTys)
        in
          case retTys of
            [ty] => ty
          | _ => (error (loc, "BAPRIMAPPLY: invalid return type: "
                              ^ Control.prettyPrint (T.format_ty primTy));
                  T.ERRORty)
        end
      | A.BARECORD {fieldList, recordTy, annotation, isMutable, totalSizeExp,
                    bitmapExpList, clearPad} =>
        let
          val fieldTys =
              map
                (fn {fieldExp, fieldTy, fieldLabel, fieldSize, fieldIndex} =>
                    let
                      val expTy = typecheckValue loc env fieldExp
                      val _ = typecheckTy ("BARECORD: fieldTy", loc) env fieldTy
                      val sizeExpTy = typecheckValue loc env fieldSize
                      val indexExpTy = typecheckValue loc env fieldIndex
                      val _ = unify ("BARECORD: field", loc) (expTy, fieldTy)
                      val sizeTy = T.SINGLETONty (T.SIZEty fieldTy)
                      val _ = unify ("BARECORD: size", loc) (sizeExpTy, sizeTy)
                      val indexTy =
                          T.SINGLETONty (T.INDEXty (fieldLabel, recordTy))
                      val _ =
                          unify ("BARECORD: index", loc) (indexExpTy, indexTy)
                    in
                      (fieldLabel, fieldTy)
                    end)
                fieldList
          val _ = typecheckTy ("BARECORD: recordTy", loc) env recordTy
          val totalExpTy = typecheckValue loc env totalSizeExp
          val bitmapExpTys = map (typecheckValue loc env) bitmapExpList
          val fieldTys =
              foldl (fn ((label, ty), z) =>
                        (if LabelEnv.inDomain (z, label)
                         then error (loc, "BARECORD: doubled label: " ^ label)
                         else ();
                         LabelEnv.insert (z, label, ty)))
                    LabelEnv.empty
                    fieldTys
          val actualRecordTy =
              T.RECORDty {fieldTypes = fieldTys,
                          annotation = dummyAnnotation}
          val _ = unify ("BARECORD: recordTy", loc) (actualRecordTy, recordTy)
          val totalTy = T.SINGLETONty (T.RECORDSIZEty recordTy)
          val _ = unify ("BARECORD: totalSize", loc) (totalExpTy, totalTy)
          val bitmapTys =
              List.tabulate
                (length bitmapExpList,
                 fn i => T.SINGLETONty (T.RECORDBITMAPty (i, recordTy)))
          val bitmapExpTys = map (typecheckValue loc env) bitmapExpList
          val _ = unifyMVAL ("BARECORD: bitmap", loc) (bitmapExpTys, bitmapTys)
        in
          recordTy
        end
      | A.BASELECT {recordExp, indexExp, label, recordTy, resultTy,
                    resultSize} =>
        let
          val expTy = typecheckValue loc env recordExp
          val indexExpTy = typecheckValue loc env indexExp
          val _ = typecheckTy ("BASELECT: recordTy", loc) env recordTy
          val _ = typecheckTy ("BASELECT: resultTy", loc) env resultTy
          val resultSizeTy = typecheckValue loc env resultSize
          val _ = unify ("BASELECT: record", loc) (expTy, recordTy)
          val fieldTy =
              selectFieldTy ("BASELECT", loc) (#btvEnv env) (recordTy, label)
          val _ = unify ("BASELECT: label", loc) (fieldTy, resultTy)
          val indexTy = T.SINGLETONty (T.INDEXty (label, recordTy))
          val _ = unify ("BASELECT: index", loc) (indexExpTy, indexTy)
          val sizeTy = T.SINGLETONty (T.SIZEty resultTy)
          val _ = unify ("BASELECT: size", loc) (resultSizeTy, sizeTy)
        in
          resultTy
        end
      | A.BAMODIFY {recordExp, recordTy, indexExp, label, valueExp, valueTy,
                    valueTag, valueSize} =>
        let
          val expTy = typecheckValue loc env recordExp
          val _ = typecheckTy ("BAMODIFY: recordTy", loc) env recordTy
          val indexExpTy = typecheckValue loc env indexExp
          val valueExpTy = typecheckValue loc env valueExp
          val valueTagTy = typecheckValue loc env valueTag
          val valueSizeTy = typecheckValue loc env valueSize
          val _ = unify ("BAMODIFY: record", loc) (expTy, recordTy)
          val _ = unify ("BAMODIFY: value", loc) (valueExpTy, valueTy)
          val fieldTy =
              selectFieldTy ("BAMODIFY", loc) (#btvEnv env) (recordTy, label)
          val _ = unify ("BAMODIFY: label", loc) (fieldTy, valueTy)
          val indexTy = T.SINGLETONty (T.INDEXty (label, recordTy))
          val _ = unify ("BAMODIFY: index", loc) (indexExpTy, indexTy)
          val tagTy = T.SINGLETONty (T.TAGty valueTy)
          val _ = unify ("BAMODIFY: tag", loc) (valueTagTy, tagTy)
          val sizeTy = T.SINGLETONty (T.SIZEty valueTy)
          val _ = unify ("BAMODIFY: size", loc) (valueSizeTy, sizeTy)
        in
          recordTy
        end

  fun typecheckCall loc env bacall =
      case bacall of
        A.BAFOREIGNAPPLY {funExp, foreignFunTy, argExpList} =>
        let
          val funExpTy = typecheckValue loc env funExp
          val (argTys, retTys) =
              typecheckForeignFunTy ("BAFOREIGNAPPLY", loc) env foreignFunTy
          val argExpTys = map (typecheckValue loc env) argExpList
          val _ = unify ("BAFOREIGNAPPLY: funTy", loc)
                        (funExpTy, T.foreignfunty)
          val _ = unifyMVAL ("BAFOREIGNAPPLY: arg", loc) (argExpTys, argTys)
        in
          retTys
        end
      | A.BAAPPM {funExp, funTy, argExpList} =>
        let
          val funExpTy = typecheckValue loc env funExp
          val (argTys, retTys) = typecheckFunTy ("BAAPPM", loc) env funTy
          val argExpTys = map (typecheckValue loc env) argExpList
          val _ = unify ("BAAPPM: funTy", loc) (funExpTy, funTy)
          val _ = unifyMVAL ("BAAPPM: arg", loc) (argExpTys, argTys)
        in
          retTys
        end

  fun typecheckFunction env ({argVarList, funTy, bodyExp, annotation,
                              closureLayout, loc}:A.function) =
      let
        val argVarTys = map #ty argVarList
        val _ = app (typecheckTy ("fn arg", loc) env) argVarTys
        val (argTys, retTys) = typecheckFunTy ("fn", loc) env funTy
        val _ = unifyMVAL ("fn arguments", loc) (argVarTys, argTys)
        val env = bindVars (env, argVarList)
        val env = setFunTy (env, funTy)
        val bodyTy = typecheckExp env bodyExp
        val _ = unifyExpTy ("fn body", loc) (bodyTy, RETURN retTys)
      in
        funTy
      end

  and typecheckSwitch env ({switchExp, expTy, branches, defaultExp, loc}
                           :A.switch) =
      let
        val switchTy = typecheckValue loc env switchExp
        val _ = typecheckTy ("BASWITCH: expTy", loc) env expTy
        val _ = unify ("BASWITCH: switchExp", loc) (switchTy, expTy)
        val defaultTy = typecheckExp env defaultExp
        val _ =
            app
              (fn {constant, branchExp} =>
                  let
                    val constTy = typecheckConstTerm constant
                    val _ = unify ("BASWITCH: constant", loc) (constTy, expTy)
                    val branchTy = typecheckExp env branchExp
                  in
                    unifyExpTy ("BASWITCH: branchExp", loc)
                               (branchTy, defaultTy)
                  end)
              branches
      in
        defaultTy
      end

  and typecheckExp (env:env) baexp =
      case baexp of
        A.BAVAL {boundVar, boundExp, nextExp, loc} =>
        let
          val _ = typecheckTy ("BAVAL", loc) env (#ty boundVar)
          val expTy = typecheckPrim loc env boundExp
          val _ = unify ("BAVAL", loc) (expTy, #ty boundVar)
          val env = bindVar (env, boundVar)
        in
          typecheckExp env nextExp
        end
      | A.BACALL {resultVars, callExp, nextExp, loc} =>
        let
          val varTys = map #ty resultVars
          val _ = app (typecheckTy ("BACALL", loc) env) varTys
          val expTys = typecheckCall loc env callExp
          val _ = unifyMVAL ("BACALL", loc) (expTys, varTys)
          val env = bindVars (env, resultVars)
        in
          typecheckExp env nextExp
        end
      | A.BAEXTERNVAR {exVarInfo, nextExp, loc} =>
        let
          val _ = typecheckTy ("BAEXTERNVAR", loc) env (#ty exVarInfo)
          val env = bindExternVar (env, exVarInfo)
        in
          typecheckExp env nextExp
        end
      | A.BAEXPORTVAR {varInfo as {id,ty,path}, varSize, varTag, nextExp,
                       loc} =>
        let
          (* path may be different from bound varInfo. *)
          val _ = typecheckTy ("BAEXPORTVAR: varInfo", loc) env ty
          val _ = case VarID.Map.find (#varEnv env, id) of
                    NONE => error (loc, "BAEXPORTVAR: unbound variable "
                                        ^ Control.prettyPrint
                                            (A.format_varInfo varInfo))
                  | SOME {path=_, ty=ty2, id=_} =>
                    unify ("BAEXPORTVAR", loc) (ty, ty2)
          val varSizeTy = typecheckValue loc env varSize
          val varTagTy = typecheckValue loc env varTag
          val sizeTy = T.SINGLETONty (T.SIZEty ty)
          val _ = unify ("BAEXPORTVAR: varSize", loc) (varSizeTy, sizeTy)
          val tagTy = T.SINGLETONty (T.TAGty ty)
          val _ = unify ("BAEXPORTVAR: varTag", loc) (varTagTy, tagTy)
        in
          typecheckExp env nextExp
        end
      | A.BAFNM {boundVar, btvEnv, function as {loc,...}, nextExp} =>
        let
          val _ = typecheckTy ("BAFNM", loc) env (#ty boundVar)
          val nestEnv = bindTyvars (env, btvEnv)
          val funTy = typecheckFunction nestEnv function
          val actualTy = PolyTy (btvEnv, funTy)
          val _ = unify ("BAFNM", #loc function) (actualTy, #ty boundVar)
          val env = bindVar (env, boundVar)
        in
          typecheckExp env nextExp
        end
      | A.BACALLBACKFNM {boundVar, function as {loc,...}, foreignFunTy,
                         nextExp} =>
        let
          val _ = typecheckTy ("BACALLBACKFNM", loc) env (#ty boundVar)
          val _ = unify ("BACALLBACKFNM", loc) (#ty boundVar, T.foreignfunty)
          val funTy = typecheckFunction env function
          val (argTys1, retTys1) =
              typecheckFunTy ("BACALLBACKFNM: funTy", loc) env funTy
          val (argTys2, retTys2) =
              typecheckForeignFunTy ("BACALLBACKFNM", loc) env foreignFunTy
          val _ = unifyMVAL ("BACALLBACKFNM: argTys", loc) (argTys1, argTys2)
          val _ = unifyMVAL ("BACALLBACKFNM: retTys", loc) (retTys1, retTys2)
          val env = bindVar (env, boundVar)
        in
          typecheckExp env nextExp
        end
      | A.BAVALREC {recbindList, nextExp, loc} =>
        let
          val env = bindVars (env, map #boundVar recbindList)
          val _ = app (fn {boundVar as {ty,...}, function} =>
                          let
                            val _ = typecheckTy ("BAVALREC", loc) env ty
                            val funTy = typecheckFunction env function
                          in
                            unify ("BAVALREC", loc) (funTy, ty)
                          end)
                      recbindList
        in
          typecheckExp env nextExp
        end
      | A.BAHANDLE {resultVars, tryExp, exnVar, handlerExp, nextExp, loc} =>
        let
          val varTys = map #ty resultVars
          val _ = app (typecheckTy ("BAHANDLE", loc) env) varTys
          val tryTy = typecheckExp env tryExp
          val _ = unifyExpTy ("BAHANDLE: try", loc) (tryTy, MERGE varTys)
          val _ = typecheckTy ("BAHANDLE: exnVar", loc) env (#ty exnVar)
          val _ = unify ("BAHANDLE: exnVar", loc) (#ty exnVar, T.exnty)
          val handlerEnv = bindVar (env, exnVar)
          val handlerTy = typecheckExp handlerEnv handlerExp
          val _ =
              unifyExpTy ("BAHANDLE: handler", loc) (handlerTy, MERGE varTys)
          val env = bindVars (env, resultVars)
        in
          typecheckExp env nextExp
        end
      | A.BASWITCH {resultVars, switch as {loc,...}, nextExp} =>
        let
          val varTys = map #ty resultVars
          val _ = app (typecheckTy ("BASWITCH", loc) env) varTys
          val switchTy = typecheckSwitch env switch
          val _ = unifyExpTy ("BASWITCH: switch", loc) (switchTy, MERGE varTys)
          val env = bindVars (env, resultVars)
        in
          typecheckExp env nextExp
        end
      | A.BATAILSWITCH switch =>
        typecheckSwitch env switch
      | A.BAPOLY {resultVars, btvEnv, expTyWithoutTAbs, exp, nextExp, loc} =>
        let
          val varTys = map #ty resultVars
          val _ = app (typecheckTy ("BAPOLY", loc) env) varTys
          val nestEnv = bindTyvars (env, btvEnv)
          val expTys = flattenTy expTyWithoutTAbs
          val expTy = typecheckExp nestEnv exp
          val _ = unifyExpTy ("BAPOLY", loc) (expTy, MERGE expTys)
          val polyTys = map (fn ty => PolyTy (btvEnv, ty)) expTys
          val _ = unifyMVAL ("BAPOLY: vars", loc) (polyTys, varTys)
          val env = bindVars (env, resultVars)
        in
          typecheckExp env nextExp
        end
      | A.BAMERGE vars =>
        let
          val tys = map (typecheckVar ("BAMERGE", Loc.noloc) env) vars
        in
          MERGE tys
        end
      | A.BARETURN {resultVars, funTy, loc} =>
        let
          val resultTys = map (typecheckVar ("BARETURN", loc) env) resultVars
          val (_, retTys) = typecheckFunTy ("BARETURN", loc) env funTy
          val _ = unify ("BARETURN: funTy", loc) (#funTy env, funTy)
          val _ = unifyMVAL ("BARETURN", loc) (resultTys, retTys)
        in
          RETURN resultTys
        end
      | A.BATAILAPPM {funExp, funTy, argExpList, loc} =>
        let
          val funExpTy = typecheckValue loc env funExp
          val argExpTys = map (typecheckValue loc env) argExpList
          val (argTys, retTys) = typecheckFunTy ("BATAILAPPM", loc) env funTy
          val _ = unify ("BATAILAPPM: funTy", loc) (funExpTy, funTy)
          val _ = unifyMVAL ("BATAILAPPM", loc) (argTys, argExpTys)
        in
          RETURN retTys
        end
      | A.BARAISE {argExp, loc} =>
        let
          val _ = typecheckValue loc env argExp
        in
          RAISE
        end

  fun typecheck baexp =
      (typecheckExp (emptyEnv ()) baexp; ())

end
