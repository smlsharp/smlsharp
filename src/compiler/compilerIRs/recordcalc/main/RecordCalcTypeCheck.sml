(**
 * @copyright (C) 2024 SML# Development Team.
 * @author Katsuhiro Ueno
 *)
structure RecordCalcTypeCheck =
struct

  structure R = RecordCalc
  structure T = Types
  exception B = Bug.Bug

  type env = {varEnv : Types.ty VarID.Map.map,
              btvEnv : Types.btvEnv,
              exVarEnv : Types.ty LongsymbolEnv.map,
              catchEnv : Types.ty list FunLocalLabel.Map.map}

  val emptyEnv : env =
      {varEnv = VarID.Map.empty,
       btvEnv = BoundTypeVarID.Map.empty,
       exVarEnv = LongsymbolEnv.empty,
       catchEnv = FunLocalLabel.Map.empty}

  fun addBoundVar (env as {varEnv, ...} : env) (var : RecordCalc.varInfo) =
      env # {varEnv = VarID.Map.insert (varEnv, #id var, #ty var)}

  fun addBoundVars env vars =
      foldl (fn (v, z) => addBoundVar z v) env vars

  fun addBtvEnv (env as {btvEnv, ...} : env) btvEnv2 =
      env # {btvEnv = BoundTypeVarID.Map.unionWith #2 (btvEnv, btvEnv2)}

  fun addCatchRule (env as {catchEnv, ...} : env)
                   {catchLabel, argVarList, ...} =
      env # {catchEnv = FunLocalLabel.Map.insert
                          (catchEnv, catchLabel, map #ty argVarList)}

  fun addCatchRules env rules =
      foldl (fn (v, z) => addCatchRule z v) env rules

  fun addExVar (env as {exVarEnv, ...} : env) (var : RecordCalc.exVarInfo) =
      env # {exVarEnv = LongsymbolEnv.insert (exVarEnv, #path var, #ty var)}

  fun eqTy format exp bug ty1 ty2 =
      if Unify.eqTy
           BoundTypeVarID.Map.empty
           (TyRevealTy.revealTy ty1, TyRevealTy.revealTy ty2)
      then ()
      else (print "----\n";
            print (Bug.prettyPrint (format exp));
            print "\n----\n";
            print (Bug.prettyPrint (Types.format_ty ty1));
            print "\n----\n";
            print (Bug.prettyPrint (Types.format_ty ty2));
            print "\n----\n";
            raise bug "eqTy")

  fun checkValue env value =
      let
        fun format v = R.format_rcexp (R.RCVALUE (v, Loc.noloc))
        val eqTy = eqTy format value
      in
        case value of
          R.RCCONSTANT const =>
          RecordCalcType.typeOfConst const
        | R.RCVAR {id, ty, ...} =>
          case VarID.Map.find (#varEnv env, id) of
            NONE => raise Bug.Bug "RCVAR"
          | SOME ty2 => (eqTy B ty ty2; ty2)
      end

  fun checkExp env exp =
      let
        val eqTy = eqTy R.formatWithType_rcexp exp
      in
        case exp of
          R.RCVALUE (value, loc) =>
          checkValue env value
        | R.RCSTRING (string, loc) =>
          RecordCalcType.typeOfString string
        | R.RCEXVAR ({path, ty, ...}, loc) =>
          (
            case LongsymbolEnv.find (#exVarEnv env, path) of
              NONE =>
              raise Bug.Bug ("RCEXVAR " ^ Symbol.longsymbolToString path)
            | SOME ty2 => (eqTy B ty ty2; ty2)
          )
        | R.RCFNM {argVarList, bodyTy, bodyExp, loc} =>
          let
            val env = addBoundVars env argVarList
            val env = env # {catchEnv = FunLocalLabel.Map.empty}
            val bodyExpTy = checkExp env bodyExp
          in
            eqTy B bodyTy bodyExpTy;
            T.FUNMty (map #ty argVarList, bodyExpTy)
          end
        | R.RCAPPM {funExp, funTy, argExpList, loc} =>
          let
            val funExpTy = checkExp env funExp
            val argTyList = map (checkExp env) argExpList
          in
            eqTy B funTy funExpTy;
            case TypesBasics.revealTy funExpTy of
              T.FUNMty (argTys, retTy) =>
              (ListPair.appEq
                 (fn (ty1, ty2) => eqTy B ty1 ty2)
                 (argTys, argTyList)
               handle ListPair.UnequalLengths => raise B "RCAPPM";
               retTy)
            | _ => raise Bug.Bug "RCAPPM"
          end
        | R.RCSWITCH {exp, expTy, branches, defaultExp, resultTy, loc} =>
          let
            val expTy2 = checkExp env exp
            val branchConstTys =
                map (RecordCalcType.typeOfInt o #const) branches
            val branchBodyTys = map (checkExp env o #body) branches
            val defaultTy = checkExp env defaultExp
          in
            eqTy B expTy expTy2;
            eqTy B resultTy defaultTy;
            app (fn ty => eqTy B ty defaultTy) branchBodyTys;
            app (fn ty => eqTy B ty expTy2) branchConstTys;
            defaultTy
          end
        | R.RCPRIMAPPLY {primOp, instTyList, instSizeList, instTagList,
                         argExpList, loc} =>
          let
            val instSizeTyList = map (checkValue env) instSizeList
            val instTagTyList = map (checkValue env) instTagList
            val argTyList = map (checkExp env) argExpList
            val primTy = TypesBasics.tpappPrimTy (#ty primOp, instTyList)
          in
            ListPair.appEq
              (fn (ty1, ty2) => eqTy B ty1 (T.SINGLETONty (T.SIZEty ty2)))
              (instSizeTyList, instTyList)
            handle ListPair.UnequalLengths => raise B "RCPRIMAPPLY";
            ListPair.appEq
              (fn (ty1, ty2) => eqTy B ty1 (T.SINGLETONty (T.TAGty ty2)))
              (instTagTyList, instTyList)
            handle ListPair.UnequalLengths => raise B "RCPRIMAPPLY";
            ListPair.appEq
              (fn (ty1, ty2) => eqTy B ty1 ty2)
              (argTyList, #argTyList primTy)
            handle ListPair.UnequalLengths => raise B "RCPRIMAPPLY";
            #resultTy primTy
          end
        | R.RCRECORD {fields, loc} =>
          let
            val fields = RecordLabel.Map.listItemsi fields
            val expTyList = map (checkExp env o #exp o #2) fields
            val sizeTyList = map (checkValue env o #size o #2) fields
            val tagTyList = map (checkValue env o #tag o #2) fields
          in
            ListPair.appEq
              (fn (ty1, (_, {ty, ...})) => eqTy B ty ty1)
              (expTyList, fields)
            handle ListPair.UnequalLengths => raise B "RCRECORD";
            ListPair.appEq
              (fn (ty1, ty2) => eqTy B ty1 (T.SINGLETONty (T.SIZEty ty2)))
              (sizeTyList, expTyList)
            handle ListPair.UnequalLengths => raise B "RCRECORD";
            ListPair.appEq
              (fn (ty1, ty2) => eqTy B ty1 (T.SINGLETONty (T.TAGty ty2)))
              (tagTyList, expTyList)
            handle ListPair.UnequalLengths => raise B "RCRECORD";
            T.RECORDty
              (ListPair.foldlEq
                 (fn ((label, _), ty, z) =>
                     RecordLabel.Map.insert (z, label, ty))
                 RecordLabel.Map.empty
                 (fields, expTyList))
          end
        | R.RCSELECT {label, recordExp, recordTy, indexExp, resultTy,
                      resultSize, resultTag, loc} =>
          let
            val recordTy2 = checkExp env recordExp
            val indexTy = checkExp env indexExp
            val resultSizeTy = checkValue env resultSize
            val resultTagTy = checkValue env resultTag
            val fields =
                case TypesBasics.revealTy recordTy2 of
                  T.RECORDty fields => fields
                | T.BOUNDVARty tid =>
                  (case BoundTypeVarID.Map.find (#btvEnv env, tid) of
                     SOME (T.KIND {tvarKind = T.REC fields, ...}) => fields
                   | _ => RecordLabel.Map.empty)
                | T.DUMMYty (_, T.KIND {tvarKind = T.REC fields, ...}) => fields
                | _ => RecordLabel.Map.empty
            val resultTy2 =
                case RecordLabel.Map.find (fields, label) of
                  NONE => raise Bug.Bug "RCSELECT"
                | SOME ty => ty
          in
            eqTy B recordTy recordTy2;
            eqTy B resultTy resultTy2;
            eqTy B indexTy (T.SINGLETONty (T.INDEXty (label, recordTy2)));
            eqTy B resultSizeTy (T.SINGLETONty (T.SIZEty resultTy2));
            eqTy B resultTagTy (T.SINGLETONty (T.TAGty resultTy2));
            resultTy2
          end
        | R.RCMODIFY {label, recordExp, recordTy, indexExp, elementExp,
                      elementTy, elementSize, elementTag, loc} =>
          let
            val recordTy2 = checkExp env recordExp
            val indexTy = checkExp env indexExp
            val elementTy2 = checkExp env elementExp
            val elementSizeTy = checkValue env elementSize
            val elementTagTy = checkValue env elementTag
            val fields =
                case TypesBasics.revealTy recordTy2 of
                  T.RECORDty fields => fields
                | T.BOUNDVARty tid =>
                  (case BoundTypeVarID.Map.find (#btvEnv env, tid) of
                     SOME (T.KIND {tvarKind = T.REC fields, ...}) => fields
                   | _ => RecordLabel.Map.empty)
                | _ => RecordLabel.Map.empty
            val elementTy3 =
                case RecordLabel.Map.find (fields, label) of
                  NONE => raise Bug.Bug "RCMODIFY"
                | SOME ty => ty
          in
            eqTy B recordTy recordTy2;
            eqTy B elementTy elementTy2;
            eqTy B elementTy elementTy3;
            eqTy B indexTy (T.SINGLETONty (T.INDEXty (label, recordTy2)));
            eqTy B elementSizeTy (T.SINGLETONty (T.SIZEty elementTy3));
            eqTy B elementTagTy (T.SINGLETONty (T.TAGty elementTy3));
            recordTy2
          end
        | R.RCLET {decl, body, loc} =>
          checkExp (checkDecl env decl) body
        | R.RCRAISE {exp, resultTy, loc} =>
          let
            val expTy = checkExp env exp
          in
            eqTy B expTy BuiltinTypes.exnTy;
            resultTy
          end
        | R.RCHANDLE {exp, exnVar, handler, resultTy, loc} =>
          let
            val expTy = checkExp env exp
            val handlerTy = checkExp (addBoundVar env exnVar) handler
          in
            eqTy B resultTy expTy;
            eqTy B handlerTy expTy;
            expTy
          end
        | R.RCTHROW {catchLabel, argExpList, resultTy, loc} =>
          let
            val argTyList = map (checkExp env) argExpList
          in
            case FunLocalLabel.Map.find (#catchEnv env, catchLabel) of
              NONE => raise Bug.Bug "RCTHROW"
            | SOME argTys =>
              (ListPair.appEq
                 (fn (ty1, ty2) => eqTy B ty1 ty2)
                 (argTys, argTyList)
               handle ListPair.UnequalLengths => raise B "RCTHROW";
               resultTy)
          end
        | R.RCCATCH {recursive, rules, tryExp, resultTy, loc} =>
          let
            val ruleEnv = if recursive then addCatchRules env rules else env
            val ruleTys =
                map (fn {catchLabel, argVarList, catchExp} =>
                        checkExp (addBoundVars ruleEnv argVarList) catchExp)
                    rules
            val tryTy = checkExp (addCatchRules env rules) tryExp
          in
            eqTy B resultTy tryTy;
            app (fn ty => eqTy B ty tryTy) ruleTys;
            tryTy
          end
        | R.RCPOLY {btvEnv, constraints, expTyWithoutTAbs, exp, loc} =>
          let
            val env = addBtvEnv env btvEnv
            val env = env # {catchEnv = FunLocalLabel.Map.empty}
            val expTy = checkExp env exp
          in
            eqTy B expTy expTyWithoutTAbs;
            T.POLYty {boundtvars = btvEnv,
                      constraints = constraints,
                      body = expTy}
          end
        | R.RCTAPP {exp, expTy, instTyList, loc} =>
          let
            val expTy2 = checkExp env exp
            val resultTy = TypesBasics.tpappTy (expTy2, instTyList)
          in
            eqTy B expTy expTy2;
            resultTy
          end
        | R.RCFOREIGNAPPLY {funExp, argExpList, attributes, resultTy, loc} =>
          let
            val funTy = checkExp env funExp
            val argTyList = map (checkExp env) argExpList
          in
            case TypesBasics.revealTy funTy of
              T.BACKENDty (T.FOREIGNFUNPTRty arg) =>
              let
                val argTys = case #varArgTyList arg of
                               NONE => #argTyList arg
                             | SOME tys => #argTyList arg @ tys
              in
                ListPair.appEq
                  (fn (ty1, ty2) => eqTy B ty1 ty2)
                  (argTys, argTyList)
                handle ListPair.UnequalLengths => raise B "RCFOREIGNAPPLY";
                case (resultTy, #resultTy arg) of
                  (NONE, NONE) => BuiltinTypes.unitTy
                | (SOME ty1, SOME ty2) => (eqTy B ty1 ty2; ty2)
                | _ => raise Bug.Bug "RCFOREIGNAPPLY"
              end
            | _ => raise Bug.Bug "RCFOREIGNAPPLY"
          end
        | R.RCCALLBACKFN {attributes, argVarList, bodyExp, resultTy, loc} =>
          let
            val bodyTy = checkExp (addBoundVars env argVarList) bodyExp
          in
            case resultTy of
              NONE => eqTy B bodyTy BuiltinTypes.unitTy
            | SOME ty => eqTy B ty bodyTy;
            T.BACKENDty
              (T.FOREIGNFUNPTRty
                 {argTyList = map #ty argVarList,
                  varArgTyList = NONE,
                  resultTy = resultTy,
                  attributes = attributes})
          end
        | R.RCCAST {exp, expTy, targetTy, cast, loc} =>
          let
            val expTy2 = checkExp env exp
          in
            eqTy B expTy expTy2;
            targetTy
          end
        | R.RCINDEXOF {fields, label, loc} =>
          let
            val recordTy = T.RECORDty (RecordLabel.Map.map #ty fields)
          in
            RecordLabel.Map.app
              (fn {ty, size} =>
                  let
                    val sizeTy = checkValue env size
                  in
                    eqTy B sizeTy (T.SINGLETONty (T.SIZEty ty))
                  end)
              fields;
            if RecordLabel.Map.inDomain (fields, label)
            then ()
            else raise Bug.Bug "RCINDEXOF";
            T.SINGLETONty (T.INDEXty (label, recordTy))
          end
      end

  and checkDecl env decl =
      let
        val eqTy = eqTy R.formatWithType_rcdecl decl
      in
        case decl of
          R.RCVAL {var, exp, loc} =>
          let
            val expTy = checkExp env exp
          in
            eqTy B (#ty var) expTy;
            env # {varEnv = VarID.Map.insert (#varEnv env, #id var, expTy)}
          end
        | R.RCVALREC (binds, loc) =>
          let
            val env = addBoundVars env (map #var binds)
            val expTys = map (checkExp env o #exp) binds
            val varEnv =
                foldl (fn ({var = {id, ty, ...}, ...}, z) =>
                          VarID.Map.insert (z, id, ty))
                      (#varEnv env)
                      binds
          in
            ListPair.appEq
              (fn ({var = {ty, ...}, ...}, ty2) => eqTy B ty ty2)
              (binds, expTys)
            handle ListPair.UnequalLengths => raise B "RCVALREC";
            env # {varEnv = varEnv}
          end
        | R.RCEXPORTVAR {weak, var, exp} =>
          let
            val expTy = checkExp env exp
          in
            eqTy B (#ty var) expTy;
            addExVar env var
          end
        | R.RCEXTERNVAR (var, _) =>
          addExVar env var
      end

  fun checkDecls env nil = env
    | checkDecls env (decl :: decls) =
      checkDecls (checkDecl env decl) decls

  fun check decls =
      ignore (checkDecls emptyEnv decls)

end
