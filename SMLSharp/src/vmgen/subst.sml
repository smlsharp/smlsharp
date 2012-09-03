structure Substitute : sig

  val substArg :
      (InsnDef.arg * InsnDef.ty * InsnDef.pos -> InsnDef.exp * InsnDef.ty)
      -> InsnDef.semantics
      -> InsnDef.semantics

  val substTy :
      (InsnDef.ty * InsnDef.pos -> InsnDef.ty)
      -> InsnDef.semantics
      -> InsnDef.semantics

end =
struct

  structure I = InsnDef

  type env = {substArg: I.arg * I.ty * I.pos -> I.exp * I.ty,
              substTy: I.ty * I.pos -> I.ty}

  fun unify pos ty1 (exp, ty2:I.ty list) =
      if length ty1 = length ty2 andalso ListPair.all (op =) (ty1, ty2)
      then exp
      else
        (
          print (Utils.join "," (map I.formatTy ty1) ^ "\n");
          print (Utils.join "," (map I.formatTy ty2) ^ "\n");
          raise Control.Bug ("Subst.unify: unification failed at "^
                             Control.loc pos)
        )

  fun appCon con (x, ty) = (con x, ty)

  fun unzip l =
      foldr (fn ((x,y),(xs,ys)) => (x::xs, y @ ys)) (nil, nil) l

  fun substPtr (env:env) pos ptr =
      case ptr of
        I.VAR exp =>
        let
          val (exp, ty) = substExp env exp
        in
          case ty of
            [I.RI] => I.REG exp
          | [I.LI] => I.LOCAL exp
          | [I.VI] => I.VAR exp
          | _ => raise Control.Bug "substPtr"
        end
      | I.REG exp => I.REG (unify pos [I.RI] (substExp env exp))
      | I.LOCAL exp => I.LOCAL (unify pos [I.LI] (substExp env exp))
      | I.MEM {base, offset, scale} =>
        I.MEM {base = unify pos [I.P] (substExp env base),
               offset = unify pos [I.SSZ] (substExp env offset),
               scale = unify pos [I.SC] (substExp env scale)}

  and substAcc (env:env) pos acc =
      case acc of
        I.REF (ty, ptr) =>
        let
          val ty = #substTy env (ty, pos)
        in
          (I.REF (ty, substPtr env pos ptr), [ty])
        end
      | I.IPREG => (acc, [I.P])
      | I.SPREG => (acc, [I.P])
      | I.HRREG => (acc, [I.P])
      | I.TMPVAR (var, ty, pos) =>
        let
          val ty = #substTy env (ty, pos)
        in
          (I.TMPVAR (var, ty, pos), [ty])
        end

  and substExp (env:env) exp =
      case exp of
        I.NULL pos => (exp, [I.P])
      | I.NUM (n, ty, pos) =>
        let
          val ty = #substTy env (ty, pos)
        in
          (I.NUM (n, ty, pos), [ty])
        end
      | I.SIZEOF (cty, ty, pos) =>
        let
          val ty = #substTy env (ty, pos)
        in
          (I.SIZEOF (cty, ty, pos), [ty])
        end
      | I.LABELREF (exp, pos) =>
        (I.LABELREF (unify pos [I.OA] (substExp env exp), pos), [I.P])
      | I.ARG (arg, ty, pos) =>
        let
          val ty = #substTy env (ty, pos)
          val (exp, ty) = #substArg env (arg, ty, pos)
        in
          (exp, [ty])
        end
      | I.PTR (ptr, pos) => (I.PTR (substPtr env pos ptr, pos), [I.P])
      | I.ACC (acc, pos) =>
        let
          val (acc, ty) = substAcc env pos acc
        in
          (I.ACC (acc, pos), ty)
        end
      | I.COND cond => (I.COND (substCond env cond), [I.W])
      | I.ADD x => appCon I.ADD (substOp2 env x)
      | I.SUB x => appCon I.SUB (substOp2 env x)
      | I.MUL x => appCon I.MUL (substOp2 env x)
      | I.DIV x => appCon I.DIV (substOp2 env x)
      | I.MOD x => appCon I.MOD (substOp2 env x)
      | I.DVMD x => appCon I.DVMD (substOp2_2 env x)
      | I.QUOT x => appCon I.QUOT (substOp2 env x)
      | I.REM x => appCon I.REM (substOp2 env x)
      | I.QTRM x => appCon I.QTRM (substOp2_2 env x)
      | I.ADDO x => appCon I.ADDO (substOp2 env x)
      | I.SUBO x => appCon I.SUBO (substOp2 env x)
      | I.MULO x => appCon I.MULO (substOp2 env x)
      | I.DIVO x => appCon I.DIVO (substOp2 env x)
      | I.QUOTO x => appCon I.QUOTO (substOp2 env x)
      | I.DVMDO x => appCon I.DVMDO (substOp2_2 env x)
      | I.QTRMO x => appCon I.QTRMO (substOp2_2 env x)
      | I.LSHIFT x => appCon I.LSHIFT (substOp2' env I.SH x)
      | I.RSHIFT x => appCon I.RSHIFT (substOp2' env I.SH x)
      | I.RASHIFT x => appCon I.RASHIFT (substOp2' env I.SH x)
      | I.ANDB x => appCon I.ANDB (substOp2 env x)
      | I.ORB x => appCon I.ORB (substOp2 env x)
      | I.XORB x => appCon I.XORB (substOp2 env x)
      | I.NOTB x => appCon I.NOTB (substOp1 env x)
      | I.ABS x => appCon I.ABS (substOp1 env x)
      | I.ABSO x => appCon I.ABSO (substOp1 env x)
      | I.CAST {fromTy, toTy, exp, pos} =>
        let
          val fromTy = #substTy env (fromTy, pos)
          val toTy = #substTy env (toTy, pos)
        in
          (I.CAST {fromTy = fromTy,
                   toTy = toTy,
                   exp = unify pos [fromTy] (substExp env exp),
                   pos = pos},
           [toTy])
        end
      | I.FFEXPORT {entry, env = cenv, ffty, pos} =>
        (I.FFEXPORT {entry = unify pos [I.P] (substExp env entry),
                     env = unify pos [I.P] (substExp env cenv),
                     ffty = unify pos [I.P] (substExp env ffty),
                     pos = pos},
         [I.P])

  and substOp1 (env:env) (exp, ty, pos) =
      let
        val ty = #substTy env (ty, pos)
      in
        ((unify pos [ty] (substExp env exp), ty, pos), [ty])
      end

  and substOp2 (env:env) (exp1, exp2, ty, pos) =
      let
        val ty = #substTy env (ty, pos)
      in
        ((unify pos [ty] (substExp env exp1),
          unify pos [ty] (substExp env exp2), ty, pos),
         [ty])
      end

  and substOp2' (env:env) ty2 (exp1, exp2, ty, pos) =
      let
        val ty = #substTy env (ty, pos)
      in
        ((unify pos [ty] (substExp env exp1),
          unify pos [ty2] (substExp env exp2), ty, pos),
         [ty])
      end

  and substOp2_2 env x =
      let
        val (exp, ty) = substOp2 env x
      in
        (exp, ty @ ty)
      end

  and substCond env cond =
      case cond of
        I.GE x => I.GE (#1 (substOp2 env x))
      | I.GT x => I.GT (#1 (substOp2 env x))
      | I.LE x => I.LE (#1 (substOp2 env x))
      | I.LT x => I.LT (#1 (substOp2 env x))
      | I.EQ x => I.EQ (#1 (substOp2 env x))

  fun substStatement (env:env) stmt =
      case stmt of
        I.IF (cond, thenStmt, elseStmt, pos) =>
        I.IF (substCond env cond,
              map (substStatement env) thenStmt,
              map (substStatement env) elseStmt, pos)
      | I.ASSIGN (acc, exp, ty, pos) =>
        let
          val ty = map (fn t => #substTy env (t, pos)) ty
        in
          I.ASSIGN (unify pos ty (unzip (map (substAcc env pos) acc)),
                    unify pos ty (substExp env exp),
                    ty, pos)
        end
      | I.ALLOC {dst, size, pos} =>
        I.ALLOC {dst = unify pos [I.P] (substAcc env pos dst),
                 size = unify pos [I.LSZ] (substExp env size),
                 pos = pos}
      | I.COPY {size, src, dst, pos} =>
        I.COPY {size = unify pos [I.SZ] (substExp env size),
                src = unify pos [I.P] (substExp env src),
                dst = unify pos [I.P] (substExp env dst),
                pos = pos}
      | I.BARRIER {objbase, ptr, pos} =>
        I.BARRIER {objbase = unify pos [I.P] (substExp env objbase),
                   ptr = unify pos [I.P] (substExp env ptr),
                   pos = pos}
      | I.ENTER (size, pos) =>
        I.ENTER (unify pos [I.LSZ] (substExp env size), pos)
      | I.LEAVE (size, pos) =>
        I.LEAVE (unify pos [I.LSZ] (substExp env size), pos)
      | I.UNWIND (size, pos) =>
        I.UNWIND (unify pos [I.LSZ] (substExp env size), pos)
      | I.FUNCALL {func, args, pos} =>
        I.FUNCALL {func = unify pos [I.P] (substExp env func),
                   args = map (fn x => unify pos [I.P] (substExp env x)) args,
                   pos = pos}
      | I.FFCALL {ffty, entry, dst, args, pos} =>
        I.FFCALL {ffty = unify pos [I.P] (substExp env ffty),
                  entry = unify pos [I.P] (substExp env entry),
                  dst = unify pos [I.P] (substExp env dst),
                  args = map (fn x => unify pos [I.P] (substExp env x)) args,
                  pos = pos}
      | I.SYSCALL {prim, pos} =>
        I.SYSCALL {prim = unify pos [I.P] (substExp env prim), pos = pos}
      | I.PUSHTRAP (exp, pos) =>
        I.PUSHTRAP (unify pos [I.P] (substExp env exp), pos)
      | I.POPTRAP _ => stmt
      | I.RAISE _ => stmt
      | I.CONTINUE _ => stmt
      | I.NEXT _ => stmt

  fun substSemantics env ({tmpvars, statements}:I.semantics) =
      {
        tmpvars = map (fn (v,ty,pos) => (v, #substTy env (ty, pos), pos))
                      tmpvars,
        statements = map (substStatement env) statements
      } : I.semantics

  fun identTy (x:I.ty, pos:I.pos) =
      case x of I.UN _ =>
                raise Control.Bug ("tyvar at "^ Control.loc pos)
              | _ => x

  fun identArg (arg, ty, pos) = (I.ARG (arg, ty, pos), ty)

  fun substArg env semantics =
      substSemantics {substArg = env, substTy = identTy} semantics

  fun substTy env semantics =
      substSemantics {substArg = identArg, substTy = env} semantics

end
