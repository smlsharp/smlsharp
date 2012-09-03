structure TypeCheck : sig

  val typecheck : InsnDef.def_elaborated list -> InsnDef.def_typechecked list

end =
struct

  structure I = InsnDef
  structure IMap = Utils.IMap
  structure SMap = Utils.SMap

  val sizeTys = [I.SSZ, I.LSZ]
  val largeIntTys = [I.L, I.NL]
  val largeFloatTys = [I.FL]
  val sintTys = [I.N]
  val uintTys = [I.W]
  val floatTys = [I.F, I.FS]
  val intTys = sintTys @ uintTys
  val signedArithmeticTys = sintTys @ floatTys
  val arithmeticTys = signedArithmeticTys @ uintTys
  val eqTys = arithmeticTys @ [I.P]
  val numTys = sintTys @ uintTys @ floatTys @ sizeTys
               @ [I.RI, I.LI, I.SC, I.SH, I.SZ]

  val immTys = [I.W, I.L, I.N, I.NL, I.F, I.FS, I.P]


  type environment =
      {
        insnTy: I.ty option,
        args: I.arg list,
        subst: I.ty IMap.map,
        overloadEnv: I.ty list IMap.map,
        tmpvarEnv: I.ty SMap.map
      }

  exception InsnTy

  fun getInsnTy ({insnTy, ...}:environment) =
      case insnTy of
        SOME ty => ty
      | NONE => raise InsnTy

  fun addSubst (env as {subst, ...}:environment) tid ty =
      {
        insnTy = #insnTy env,
        args = #args env,
        subst = IMap.insert (subst, tid, ty),
        overloadEnv = #overloadEnv env,
        tmpvarEnv = #tmpvarEnv env
      } : environment

  fun addOverload (env as {overloadEnv, ...}:environment) (I.UN tid) tys =
      {
        insnTy = #insnTy env,
        args = #args env,
        subst = #subst env,
        overloadEnv = IMap.insert (overloadEnv, tid, tys),
        tmpvarEnv = #tmpvarEnv env
      } : environment
    | addOverload env ty tys =
      raise Control.Bug "addOverload: intended to add overloads to concrete ty"

  fun setTmpvarEnv (env:environment) tmpvarEnv =
      {
        insnTy = #insnTy env,
        args = #args env,
        subst = #subst env,
        overloadEnv = #overloadEnv env,
        tmpvarEnv = tmpvarEnv
      } : environment


  fun formatTy (env as {subst, overloadEnv, ...}:environment) ty =
      let
        fun sub (ty as I.UN tid) =
            (case IMap.find (subst, tid) of SOME ty => sub ty | NONE => ty)
          | sub ty = ty

        val ty = sub ty
        val s = I.formatTy ty
      in
        case ty of
          I.UN tid =>
          (case IMap.find (overloadEnv, tid) of
             SOME tys => s ^ "#{"^Utils.join "," (map (formatTy env) tys)^"}"
           | NONE => s)
        | _ => s
      end


  local
    exception Unify

    fun unifyOverload (ty::tys1) tys2 =
        if List.exists (fn x:I.ty => x = ty) tys2
        then ty :: unifyOverload tys1 tys2
        else unifyOverload tys1 tys2
      | unifyOverload nil tys2 = nil

    fun subst (env:environment) (ty as I.UN tid) =
        (case IMap.find (#subst env, tid) of
           SOME ty => subst env ty
         | NONE => ty)
      | subst env I.TY = getInsnTy env
      | subst env ty = ty

    fun unifyTy (env as {overloadEnv, ...}:environment) (ty1, ty2) =
        case (subst env ty1, subst env ty2) of
          (ty1 as I.UN tid1, ty2 as I.UN tid2) =>
          if tid1 = tid2
          then env
          else
            let
              val overload1 = IMap.find (overloadEnv, tid1)
              val overload2 = IMap.find (overloadEnv, tid2)
              val env =
                  case (overload1, overload2) of
                    (SOME tys1, SOME tys2) =>
                    let
                      val overloads = unifyOverload tys1 tys2
                      val _ = case overloads of nil => raise Unify | _ => ()
                      val env = addOverload env ty1 overloads
                      val env = addOverload env ty2 overloads
                    in
                      env
                    end
                  | _ => env
            in
              addSubst env tid1 ty2
            end
        | (ty1 as I.UN tid1, ty2) =>
          let
            val overload1 = IMap.find (overloadEnv, tid1)
          in
            case overload1 of
              NONE => addSubst env tid1 ty2
            | SOME tys1 =>
              if List.exists (fn x => x = ty2) tys1
              then addSubst env tid1 ty2
              else raise Unify
          end
        | (ty1, ty2 as I.UN tid1) => unifyTy env (ty2, ty1)
        | (ty1, ty2) => if ty1 = ty2 then env else raise Unify

    fun unifyTyList (env, ty1::tys1, ty2::tys2) =
        unifyTyList (unifyTy env (ty1, ty2), tys1, tys2)
      | unifyTyList (env, nil, nil) = env
      | unifyTyList (env, _, _) = raise Unify

  in

  fun unify env pos (tys1, tys2) =
      unifyTyList (env, tys1, tys2)
      handle Unify =>
             raise Control.Error
                   [(pos,
                     "type unification failed\n\
                     \\tdomain: "^Utils.join ", " (map (formatTy env) tys1)^"\n\
                     \\t   arg: "^Utils.join ", " (map (formatTy env) tys2))]
           | InsnTy =>
             raise Control.Error [(pos, "ty occurs but no type suffix")]

  end


  fun typeinfArg env pos arg =
      (
        if List.exists (fn x => x = arg) (#args env)
        then ()
        else raise Control.Error
                     [(pos, "unbound operand `"^I.formatArg arg^"'")];

        case arg of
          I.VARX _ => (env, [I.VI])
        | I.LSIZE _ => (env, [I.LSZ])
        | I.SIZE => (env, [I.SZ])
        | I.SHIFT => (env, [I.SH])
        | I.SCALE => (env, [I.SC])
        | I.DISPLACEMENT => (env, [I.SSZ])
        | I.IMM =>
          let
            val ty = getInsnTy env
                     handle InsnTy =>
                            raise Control.Error
                                    [(pos, "const occurs but no type suffix")]
          in
            if List.exists (fn x => x = ty) immTys
            then (env, [ty])
            else
              raise Control.Error
                    [(pos,
                      "invalid immediate value type\n\
                      \\tvalid: "^
                      Utils.join ", " (map (formatTy env) immTys)^"\n\
                      \\t type: "^formatTy env ty^"\n")]
          end
        | I.LABEL => (env, [I.OA])
        | I.EXTERN _ => (env, [I.P])
      )

  fun typeinfPtr env pos ptr =
      case ptr of
        I.VAR exp =>
        let
          val (env, ty) = typeinfExp env exp
          val env = unify env pos ([I.VI], ty)
        in
          env
        end
      | I.REG exp =>
        let
          val (env, ty) = typeinfExp env exp
          val env = unify env pos ([I.RI], ty)
        in
          env
        end
      | I.LOCAL exp =>
        let
          val (env, ty) = typeinfExp env exp
          val env = unify env pos ([I.LI], ty)
        in
          env
        end
      | I.MEM {base, offset, scale} =>
        let
          val (env, ty1) = typeinfExp env base
          val (env, ty2) = typeinfExp env offset
          val (env, ty3) = typeinfExp env scale
          val env = unify env pos ([I.P, I.SSZ, I.SC], ty1 @ ty2 @ ty3)
        in
          env
        end

  and typeinfAcc env pos acc =
      case acc of
        I.REF (ty, ptr) =>
        (typeinfPtr env pos ptr, [ty])
      | I.IPREG => (env, [I.P])
      | I.SPREG => (env, [I.P])
      | I.HRREG => (env, [I.P])
      | I.TMPVAR (var, ty, pos) =>
        let
          val ty2 =
              case SMap.find (#tmpvarEnv env, var) of
                SOME ty => ty
              | NONE => raise Control.Error
                                  [(pos, "undefined tmpvar `"^var^"'")]
          val env = unify env pos ([ty], [ty2])

        in
          (env, [ty2])
        end

  and typeinfAccList env pos (acc::accList) =
      let
        val (env, tys1) = typeinfAcc env pos acc
        val (env, tys2) = typeinfAccList env pos accList
      in
        (env, tys1 @ tys2)
      end
    | typeinfAccList env pos nil = (env, nil)

  and typeinfExp env exp =
      case exp of
        I.NULL pos => (env, [I.P])
      | I.NUM (n, ty, pos) => (addOverload env ty numTys, [ty])
      | I.SIZEOF (cty, ty, pos) => (addOverload env ty numTys, [ty])
      | I.LABELREF (exp, pos) =>
        let
          val (env, ty) = typeinfExp env exp
          val env = unify env pos ([I.OA], ty)
        in
          (env, [I.P])
        end
      | I.ARG (arg, ty, pos) =>
        let
          val (env, ty2) = typeinfArg env pos arg
          val env = unify env pos ([ty], ty2)
        in
          (env, ty2)
        end
      | I.PTR (ptr, pos) => (typeinfPtr env pos ptr, [I.P])
      | I.ACC (acc, pos) => typeinfAcc env pos acc
      | I.COND cond => (typeinfCond env cond, [I.W])
      | I.ADD x => typeinfOp2 env arithmeticTys x
      | I.SUB x => typeinfOp2 env arithmeticTys x
      | I.MUL x => typeinfOp2 env arithmeticTys x
      | I.DIV x => typeinfOp2 env arithmeticTys x
      | I.MOD x => typeinfOp2 env intTys x
      | I.DVMD x => typeinfOp2_2 env intTys x
      | I.QUOT x => typeinfOp2 env sintTys x
      | I.REM x => typeinfOp2 env sintTys x
      | I.QTRM x => typeinfOp2_2 env sintTys x
      | I.ADDO x => typeinfOp2 env sintTys x
      | I.SUBO x => typeinfOp2 env sintTys x
      | I.MULO x => typeinfOp2 env sintTys x
      | I.DIVO x => typeinfOp2 env sintTys x
      | I.QUOTO x => typeinfOp2 env sintTys x
      | I.DVMDO x => typeinfOp2_2 env sintTys x
      | I.QTRMO x => typeinfOp2_2 env sintTys x
      | I.LSHIFT x => typeinfShift env x
      | I.RSHIFT x => typeinfShift env x
      | I.RASHIFT x => typeinfShift env x
      | I.ANDB x => typeinfOp2 env uintTys x
      | I.ORB x => typeinfOp2 env uintTys x
      | I.XORB x => typeinfOp2 env uintTys x
      | I.NOTB x => typeinfOp1 env uintTys x
      | I.ABS x => typeinfOp1 env signedArithmeticTys x
      | I.ABSO x => typeinfOp1 env signedArithmeticTys x
      | I.CAST {fromTy, toTy, exp, pos} =>
        let
          val (env, ty1) = typeinfExp env exp
          val env = unify env pos ([fromTy], ty1)
        in
          (env, [toTy])
        end
      | I.FFEXPORT {entry, env=cenv, ffty, pos} =>
        let
          val (env, ty1) = typeinfExp env entry
          val (env, ty2) = typeinfExp env cenv
          val (env, ty3) = typeinfExp env ffty
          val env = unify env pos ([I.P, I.P, I.P], ty1 @ ty2 @ ty3)
        in
          (env, [I.P])
        end

  and typeinfExpList env (exp::expList) =
      let
        val (env, tys1) = typeinfExp env exp
        val (env, tys2) = typeinfExpList env expList
      in
        (env, tys1 @ tys2)
      end
    | typeinfExpList env nil = (env, nil)

  and typeinfOp1 env tys (exp1, ty, pos) =
      let
        val env = addOverload env ty tys
        val (env, ty1) = typeinfExp env exp1
        val env = unify env pos ([ty], ty1)
      in
        (env, [ty])
      end

  and typeinfOp2 env tys (exp1, exp2, ty, pos) =
      let
        val env = addOverload env ty tys
        val (env, ty1) = typeinfExp env exp1
        val (env, ty2) = typeinfExp env exp2
        val env = unify env pos ([ty, ty], ty1 @ ty2)
      in
        (env, [ty])
      end

  and typeinfOp2_2 env tys x =
      let
        val (env, ty) = typeinfOp2 env tys x
      in
        (env, ty @ ty)
      end

  and typeinfShift env (exp1, exp2, ty, pos) =
      let
        val env = addOverload env ty intTys
        val (env, ty1) = typeinfExp env exp1
        val (env, ty2) = typeinfExp env exp2
        val env = unify env pos ([ty, I.SH], ty1 @ ty2)
      in
        (env, [ty])
      end

  and typeinfCond env cond =
      case cond of
        I.GE x => #1 (typeinfOp2 env arithmeticTys x)
      | I.GT x => #1 (typeinfOp2 env arithmeticTys x)
      | I.LE x => #1 (typeinfOp2 env arithmeticTys x)
      | I.LT x => #1 (typeinfOp2 env arithmeticTys x)
      | I.EQ x => #1 (typeinfOp2 env eqTys x)

  fun typeinfStatement env stmt =
      case stmt of
        I.IF (cond, thenStmt, elseStmt, pos) =>
        let
          val env = typeinfCond env cond
          val env = typeinfStatementList env thenStmt
          val env = typeinfStatementList env elseStmt
        in
          env
        end
      | I.ASSIGN (accs, exp, tys, pos) =>
        let
          val (env, ty1) = typeinfAccList env pos accs
          val (env, ty2) = typeinfExp env exp
        in
          unify env pos (tys @ tys, ty1 @ ty2)
        end
      | I.ALLOC {dst, size, pos} =>
        let
          val (env, ty1) = typeinfAcc env pos dst
          val (env, ty2) = typeinfExp env size
        in
          unify env pos ([I.P, I.LSZ], ty1 @ ty2)
        end
      | I.COPY {size, src, dst, pos} =>
        let
          val (env, ty1) = typeinfExp env size
          val (env, ty2) = typeinfExp env src
          val (env, ty3) = typeinfExp env dst
        in
          unify env pos ([I.SZ, I.P, I.P], ty1 @ ty2 @ ty3)
        end
      | I.BARRIER {objbase, ptr, pos} =>
        let
          val (env, ty1) = typeinfExp env objbase
          val (env, ty2) = typeinfExp env ptr
        in
          unify env pos ([I.P, I.P], ty1 @ ty2)
        end
      | I.ENTER (size, pos) =>
        let
          val (env, ty1) = typeinfExp env size
        in
          unify env pos ([I.LSZ], ty1)
        end
      | I.LEAVE (size, pos) =>
        let
          val (env, ty1) = typeinfExp env size
        in
          unify env pos ([I.LSZ], ty1)
        end
      | I.UNWIND (size, pos) =>
        let
          val (env, ty1) = typeinfExp env size
        in
          unify env pos ([I.LSZ], ty1)
        end
      | I.FUNCALL {func, args, pos} =>
        let
          val (env, ty1) = typeinfExp env func
          val (env, ty2) = typeinfExpList env args
          val argTys = map (fn _ => I.P) args
        in
          unify env pos ([I.P] @ argTys, ty1 @ ty2)
        end
      | I.FFCALL {ffty, entry, dst, args, pos} =>
        let
          val (env, ty1) = typeinfExp env ffty
          val (env, ty2) = typeinfExp env entry
          val (env, ty3) = typeinfExp env dst
          val (env, ty4) = typeinfExpList env args
          val argTys = map (fn _ => I.P) args
        in
          unify env pos ([I.P, I.P, I.P] @ argTys, ty1 @ ty2 @ ty3 @ ty4)
        end
      | I.SYSCALL {prim, pos} =>
        let
          val (env, ty1) = typeinfExp env prim
        in
          unify env pos ([I.P], ty1)
        end
      | I.PUSHTRAP (exp, pos) =>
        let
          val (env, ty1) = typeinfExp env exp
        in
          unify env pos ([I.P], ty1)
        end
      | I.POPTRAP pos => env
      | I.RAISE pos => env
      | I.CONTINUE pos => env
      | I.NEXT pos => env

  and typeinfStatementList env stmtList =
      foldl (fn (stmt, env) => typeinfStatement env stmt) env stmtList

  fun typeinfSemantics env {tmpvars, statements} =
      let
        val tmpvarEnv =
            foldl
              (fn ((var, ty, pos), map) =>
                  case SMap.find (map, var) of
                    SOME _ =>
                    raise Control.Error [(pos, "doubled tmpvar `"^var^"'")]
                  | NONE => SMap.insert (map, var, ty))
              SMap.empty
              tmpvars
        val env = setTmpvarEnv env tmpvarEnv
      in
        typeinfStatementList env statements
      end

  fun typeinfMetaif env metaif =
      case metaif of
        I.METAIF (conds, metaThen, metaElse) =>
        let
          val env = typeinfMetaif env metaThen
          val env = typeinfMetaif env metaElse
        in
          env
        end
      | I.META (semantics, pos) =>
        typeinfSemantics env semantics

  fun substTy env (I.TY, pos) =
      (getInsnTy env
       handle InsnTy =>
              raise Control.Error [(pos, "ty occurs but no type suffix")])
    | substTy env (I.UN tid, pos) =
      (case IMap.find (#subst env, tid) of
         SOME ty => substTy env (ty, pos)
       | NONE => raise Control.Error [(pos, "type variable remained")])
    | substTy env (ty, pos) = ty

  fun substMetaif env metaif =
      case metaif of
        I.METAIF (conds, metaThen, metaElse) =>
        I.METAIF (conds, substMetaif env metaThen, substMetaif env metaElse)
      | I.META (sem, pos) =>
        I.META (Substitute.substTy (substTy env) sem, pos)

  fun evalMetaif env metaif =
      Utils.evalMetaif
          (fn I.METAEQ _ => NONE
            | I.METAEQTY (ty, pos) => SOME (ty = getInsnTy env)
            | I.METAEQSUFFIX _ => NONE)
          metaif

  fun checkPreprocess ({args, ...}:environment) preprocess =
      case preprocess of
        NONE => ()
      | SOME {name, args=prepArgs, pos} =>
        app (fn arg =>
                if List.exists (fn x => x = arg) args
                then ()
                else raise Control.Error
                             [(pos, "unbound operand `"^I.formatArg arg^"'")])
            prepArgs

  fun argTy env pos arg =
      case #2 (typeinfArg env pos arg) of
        [ty] => (arg, ty)
      | _ => raise Control.Bug "typeinfDef: codeArgs"

  fun typeinfDef insnTy
                 ({codeArgs, preprocess, semantics, alternate, pos, ...}
                  :I.def_elaborated) =
      let
        val env =
           {
             insnTy = insnTy,
             args = codeArgs,
             subst = IMap.empty,
             overloadEnv = IMap.empty,
             tmpvarEnv = SMap.empty
           } : environment

        val _ = checkPreprocess env preprocess

        val semantics = evalMetaif env semantics
        val semEnv = typeinfMetaif env semantics
        val semantics = substMetaif semEnv semantics

        val alternate =
            case alternate of
              NONE => alternate
            | SOME sem =>
              let
                val altEnv = typeinfSemantics env sem
              in
                SOME (Substitute.substTy (substTy altEnv) sem)
              end

        val codeArgs = map (argTy env pos) codeArgs
      in
        {
          ty = insnTy,
          codeArgs = codeArgs,
          preprocess = preprocess,
          semantics = semantics,
          alternate = alternate,
          pos = pos
        }
      end

  fun typecheckDef (def as {name, tyList, mnemonicArgs, syntax, pos, ...}
                           :I.def_elaborated) =
      {
        name = name,
        mnemonicArgs = mnemonicArgs,
        syntax = syntax,
        variants =
            case tyList of
              nil => [typeinfDef NONE def]
            | _ => map (fn ty => typeinfDef (SOME ty) def) tyList,
        pos = pos
      } : I.def_typechecked

  fun typecheck defs =
      map typecheckDef defs

end
