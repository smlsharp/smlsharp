(**
 * Platform indepedent type-directed compilation for:
 *  record polymorphism, 
 *  natural data representation, and
 *  type-reification/dynamic typing.
 *
 * @copyright (c) 2011-2016, Tohoku University.
 * @author UENO Katsuhiro
 * @author Atsushi Ohori
 *
 * This module relys on the type structure of rank-1 polymorphism.
 *)
structure RecordCompilation =
struct

  structure TL = TypedLambda
  structure RC = RecordCalc
  structure T = Types
  structure TB = TypesBasics

  fun newVar ty =
      {path = [Symbol.generate ()],
       ty = ty,
       id = VarID.generate ()} : RC.varInfo

  fun mapToLabelEnv f nil = RecordLabel.Map.empty
    | mapToLabelEnv f (h::t) =
      let
        val (label, value) = f h
      in
        RecordLabel.Map.insert (mapToLabelEnv f t, label, value)
      end

  fun Exp (exp, expTy) =
      (fn loc => exp, expTy)

  fun Var (var as {ty,...}) =
      (fn loc => RC.RCVAR (var, loc), ty)

  fun SELECT (label, (exp, expTy)) =
      let
        val resultTy =
            case expTy of
              T.RECORDty fields =>
              (case RecordLabel.Map.find (fields, label) of
                 SOME ty => ty
               | NONE => raise Bug.Bug ("SELECT " ^ RecordLabel.toString label))
            | _ => raise Bug.Bug "SELECT (not record)"
      in
        (fn loc => RC.RCSELECT {indexExp = RC.RCINDEXOF
                                             {label = label,
                                              recordTy = expTy,
                                              loc = loc},
                                label = label,
                                recordExp = exp loc,
                                recordTy = expTy,
                                resultTy = resultTy,
                                loc = loc},
         resultTy)
      end

  fun RECORD fields =
      let
        val recordTy =
            T.RECORDty (RecordLabel.Map.map (fn (exp, expTy) => expTy) fields)
      in
        (fn loc =>
            RC.RCRECORD
              {fields = RecordLabel.Map.map (fn (exp, expTy) => exp loc) fields,
               recordTy = recordTy,
               loc = loc},
         recordTy)
      end

  fun APPM ((exp, expTy), args) =
      (fn loc => RC.RCAPPM {funExp = exp loc,
                            funTy = expTy,
                            argExpList = map (fn (exp,ty) => exp loc) args,
                            loc = loc},
       case TB.derefTy expTy of
         T.FUNMty (argTys, retTy) => retTy
       | _ => raise Bug.Bug "APPM")

  fun POLYFNM (btvEnv, args, (bodyExp, bodyTy)) =
      (fn loc =>
          RC.RCPOLY
            {btvEnv = btvEnv,
             constraints = nil,
             expTyWithoutTAbs = T.FUNMty (map #ty args, bodyTy),
             exp = RC.RCFNM
                     {argVarList = args,
                      bodyTy = bodyTy,
                      bodyExp = bodyExp loc,
                      loc = loc},
             loc = loc},
       T.POLYty {boundtvars = btvEnv,
                 constraints = nil,
                 body = T.FUNMty (map #ty args, bodyTy)})

  fun TAPP ((exp, expTy), instTyList) =
      (fn loc => RC.RCTAPP {exp = exp loc,
                            expTy = expTy,
                            instTyList = instTyList,
                            loc = loc},
       TB.tpappTy (expTy, instTyList))
      handle e => raise e

  fun LET (dec, (exp, expTy)) =
      (fn loc => RC.RCLET {decl=dec loc, body=exp loc, loc=loc},
       expTy)

  fun VALDEC binds loc =
      map
        (fn (var,(exp,expTy:T.ty)) =>
            RC.RCVAL {var = var, exp = exp loc, loc = loc})
        binds

  fun VALRECDEC binds loc =
      RC.RCVALREC
        (map (fn (var,(exp,_)) =>
                 {var = var, exp = exp loc})
             binds,
         loc)

  structure SingletonTyOrd : ORD_KEY =
  struct

    type ord_key = T.singletonTy

    fun order sty =
        case sty of
          T.TAGty _ => 0
        | T.SIZEty _ => 1
        | T.INDEXty _ => 2
        | T.INSTCODEty _ => 3
        | T.REIFYty _ => 5

    fun compare (sty1, sty2) =
        case (sty1, sty2) of
          (T.INSTCODEty op1, T.INSTCODEty op2) =>
          OverloadKind.compare (op1, op2)
        | (T.INDEXty i1, T.INDEXty i2) =>
          RecordKind.compare (i1, i2)
        | (T.SIZEty ty1, T.SIZEty ty2) =>
          SizeKind.compare (ty1, ty2)
        | (T.REIFYty ty1, T.REIFYty ty2) =>
          ReifyKind.compare (ty1, ty2)
        | (T.TAGty ty1, T.TAGty ty2) =>
          TagKind.compare (ty1, ty2)
        | (T.INSTCODEty _, _) => Int.compare (order sty1, order sty2)
        | (T.INDEXty _, _) => Int.compare (order sty1, order sty2)
        | (T.SIZEty _, _) => Int.compare (order sty1, order sty2)
        | (T.TAGty _, _) => Int.compare (order sty1, order sty2)
        | (T.REIFYty _, _) => Int.compare (order sty1, order sty2)

  end

  structure SingletonTyMap = BinaryMapFn(SingletonTyOrd)
  structure SingletonTySet = BinarySetFn(SingletonTyOrd)

  fun generateExtraArgsOfKind btvEnv (btv, kind as T.KIND {properties, tvarKind, dynamicKind}) =
      let
        val dynamicKind =
            case dynamicKind of
              SOME dynamicKind => dynamicKind
            | NONE => case DynamicKindUtils.kindOfStaticKind kind of
                        SOME dynamicKind => dynamicKind
                      | NONE => raise Bug.Bug "generateExtraArgsOfKind"
      in
      SizeKind.generateArgs btvEnv (btv, #size dynamicKind) 
      @ TagKind.generateArgs btvEnv (btv, #tag dynamicKind) 
      @ (case tvarKind of
           T.OPRIMkind k =>
           OverloadKind.generateArgs btvEnv (btv, k)
         | T.REC r =>
           RecordKind.generateArgs btvEnv (btv, (#record dynamicKind, r))
         | _ => nil
        )
      @ ReifyKind.generateArgs btvEnv (btv, T.isProperties T.REIFY properties)
      end

  fun generateExtraArgs btvEnv =
      let
        val args =
            map (fn (tid, kind) =>
                    foldl (fn (x,z) => SingletonTySet.add (z,x))
                          SingletonTySet.empty
                          (generateExtraArgsOfKind btvEnv (tid, kind)))
                (BoundTypeVarID.Map.listItemsi btvEnv)
        fun unique (occurred, nil) = nil
          | unique (occurred, h::t) =
            SingletonTySet.listItems
              (SingletonTySet.difference (h, occurred))
            @ unique (SingletonTySet.union (occurred, h), t)
      in
        map T.SINGLETONty (unique (SingletonTySet.empty, args))
      end

  fun generateExtraArgVars btvEnv =
      map newVar (generateExtraArgs btvEnv)

  type context =
      {
        instanceEnv: RC.varInfo SingletonTyMap.map,
        btvEnv: T.btvEnv
      }

  fun extendBtvEnv ({instanceEnv, btvEnv}:context) newBtvEnv =
      {instanceEnv = instanceEnv,
       btvEnv = BoundTypeVarID.Map.unionWith #2 (btvEnv, newBtvEnv)}
      : context

  fun addExtraBinds ({instanceEnv, btvEnv}:context) vars =
      {
        instanceEnv =
          foldl
            (fn (var as {ty = T.SINGLETONty sty, ...} : RC.varInfo,
                 instanceEnv) =>
                SingletonTyMap.insert (instanceEnv, sty, var)
              | _ => raise Bug.Bug "addExtraBinds")
            instanceEnv
            vars,
        btvEnv = btvEnv
      } : context

  datatype instance =
      INST_APP of {appExp: TL.tlexp -> TL.tlexp, argTy: T.ty, bodyTy: T.ty,
                   singletonTy: T.singletonTy, loc: Loc.loc}
    | INST_EXP of RC.rcexp
    | INST_TLEXP of TL.tlexp

  fun compileTy ty =
      case ty of
        T.SINGLETONty _ => ty
      | T.BACKENDty _ => ty
      | T.ERRORty => ty
      | T.DUMMYty _ => ty
      | T.EXISTty _ => ty
      | T.TYVARty tv => ty  (* what used to be tyvar contains no POLYty. *)
      | T.BOUNDVARty tid => ty
      | T.FUNMty (argTys, retTy) =>
        (* argTys may contain polyTy due to functor. *)
        T.FUNMty (map compileTy argTys, compileTy retTy)
      | T.RECORDty fields =>
        T.RECORDty (RecordLabel.Map.map compileTy fields)
      | T.CONSTRUCTty {tyCon, args} =>
        T.CONSTRUCTty {tyCon = tyCon, args = map compileTy args}
      | T.POLYty {boundtvars, constraints, body} =>
        case generateExtraArgs boundtvars of
          nil =>
          T.POLYty {boundtvars = boundtvars,
                    constraints = constraints,
                    body = compileTy body}
        | extraTys =>
          T.POLYty {boundtvars = boundtvars,
                    constraints = constraints, 
                    body = T.FUNMty (extraTys, compileTy body)}

  fun compileVarInfo ({path, ty, id} : TL.varInfo) =
      {path = path, ty = compileTy ty, id = id} : RC.varInfo

  fun compileExVarInfo ({path, ty} : TL.exVarInfo) =
      {path = path, ty = compileTy ty} : RC.exVarInfo

  fun generateConcreteInstance (context as {btvEnv, instanceEnv}:context)
                               sty loc =
      let
        val env = {btvEnv = btvEnv,
                   lookup = fn sty => SingletonTyMap.find (instanceEnv, sty)}
      in
        case sty of
          T.INDEXty arg =>
          Option.map INST_EXP (RecordKind.generateInstance env arg loc)
        | T.TAGty arg =>
          Option.map INST_EXP (TagKind.generateInstance env arg loc)
        | T.SIZEty arg =>
          Option.map INST_EXP (SizeKind.generateInstance env arg loc)
        | T.REIFYty arg =>
          Option.map INST_TLEXP (ReifyKind.generateInstance env arg loc)
        | T.INSTCODEty arg =>
          case OverloadKind.generateInstance env arg loc of
            NONE => NONE
          | SOME (OverloadKind.APP app) => SOME (INST_APP app)
          | SOME (OverloadKind.EXP exp) => SOME (INST_TLEXP exp)
      end

  fun generateInstance (context as {instanceEnv,...}) sty loc =
      case generateConcreteInstance context sty loc of
        SOME inst => inst
      | NONE =>
        case SingletonTyMap.find (instanceEnv, sty) of
          SOME var => INST_EXP (RC.RCVAR (var, loc))
        | NONE => 
          (
           print "generateInstacne\n";
           print (Bug.prettyPrint (T.format_singletonTy sty));
           raise Bug.Bug "generateInstance (SingletonTyMap.find NONE)"
          )

  fun generateInstances context tys loc =
      map (fn ty as T.SINGLETONty sty => generateInstance context sty loc
            | _ => raise Bug.Bug "generateExtraInstExps")
          tys

  fun toExp context instance =
      case instance of
        INST_EXP exp => exp
      | INST_TLEXP exp => compileExp context exp
      | INST_APP {appExp, argTy, bodyTy, singletonTy, loc} =>
        let
          val arg = newVar argTy
        in
          compileExp
            context
            (TL.TLCAST
               {exp = TL.TLFNM {argVarList = [arg],
                                bodyTy = bodyTy,
                                bodyExp = appExp (TL.TLVAR (arg, loc)),
                                loc = loc},
                expTy = T.FUNMty ([#ty arg], bodyTy),
                targetTy = T.SINGLETONty singletonTy,
                cast = TL.TypeCast,
                loc = loc})
        end

  and compileExp context tpexp =
      case tpexp of
        TL.TLFOREIGNAPPLY {funExp, attributes, resultTy, argExpList, loc} =>
        RC.RCFOREIGNAPPLY
          {funExp = compileExp context funExp,
           argExpList = map (compileExp context) argExpList,
           attributes = attributes,
           resultTy = resultTy,  (* contains no POLYty *)
           loc = loc}
      | TL.TLCALLBACKFN {argVarList, bodyExp, attributes, resultTy, loc} =>
        RC.RCCALLBACKFN
          {argVarList = map compileVarInfo argVarList,
           bodyExp = compileExp context bodyExp,
           attributes = attributes,
           resultTy = resultTy,  (* contains no POLYty *)
           loc = loc}
      | TL.TLSIZEOF {ty, loc} =>
        (* contains no POLYty *)
        toExp context (generateInstance context (T.SIZEty ty) loc)
      | TL.TLINDEXOF {label, recordTy, loc} =>
        toExp context
              (generateInstance context (T.INDEXty (label, recordTy)) loc)
      | TL.TLREIFYTY {ty, loc} =>
        toExp context (generateInstance context (T.REIFYty ty) loc)
      | TL.TLCONSTANT (const, loc) =>
        RC.RCCONSTANT (RC.CONST const, loc)
      | TL.TLSTRING (string, loc) =>
        RC.RCSTRING (string, loc)
      | TL.TLFOREIGNSYMBOL symbol =>
        (* contains no POLYty *)
        RC.RCFOREIGNSYMBOL symbol
      | TL.TLVAR (varInfo, loc) =>
        RC.RCVAR (compileVarInfo varInfo, loc)
      | TL.TLEXVAR (exVarInfo, loc) =>
        RC.RCEXVAR (compileExVarInfo exVarInfo, loc)
      | TL.TLAPPM {funExp, funTy, argExpList, loc} =>
        RC.RCAPPM
          {funExp = compileExp context funExp,
           funTy = compileTy funTy,
           argExpList = map (compileExp context) argExpList,
           loc = loc}
      | TL.TLLET {decl, body, loc} =>
        foldr
          (fn (decl, exp) => RC.RCLET {decl = decl, body = exp, loc = loc})
          (compileExp context body)
          (compileDecl context decl)
      | TL.TLRECORD {fields, recordTy, loc} =>
        RC.RCRECORD
          {fields = RecordLabel.Map.map (compileExp context) fields,
           recordTy = compileTy recordTy,
           loc = loc}
      | TL.TLSELECT {label, recordExp, recordTy, resultTy, loc} =>
        RC.RCSELECT
          {indexExp =
             toExp context
                   (generateInstance context (T.INDEXty (label, recordTy)) loc),
           label = label,
           recordExp = compileExp context recordExp,
           recordTy = compileTy recordTy,
           resultTy = compileTy resultTy,
           loc = loc}
      | TL.TLMODIFY {label, recordExp, recordTy, elementExp, elementTy, loc} =>
        RC.RCMODIFY
          {indexExp =
             toExp context
                   (generateInstance context (T.INDEXty (label, recordTy)) loc),
           label = label,
           recordExp = compileExp context recordExp,
           recordTy = compileTy recordTy,
           elementExp = compileExp context elementExp,
           elementTy = compileTy elementTy,
           loc = loc}
      | TL.TLRAISE {exp, resultTy, loc} =>
        (* ty may contain POLYty due to rank-1 poly.
         * Consider the following example:
         *   fun f 0 = fn x => x
         * TypeInference infers the type of f as "int -> ['a.'a -> 'a]" and
         * MatchCompiler generates the default case branch which just raises
         * "Match" exception.  The RCRAISE in the default branch may have
         * polymorphic type ['a. 'a -> 'a] due to the typing rule of RCSWITCH.
         *)
        RC.RCRAISE {exp = compileExp context exp,
                    resultTy = compileTy resultTy,
                    loc = loc}
      | TL.TLHANDLE {exp, exnVar, handler, resultTy, loc} =>
        RC.RCHANDLE
          {exp = compileExp context exp,
           exnVar = compileVarInfo exnVar,
           handler = compileExp context handler,
           resultTy = compileTy resultTy,
           loc = loc}
      | TL.TLSWITCH {exp, expTy, branches, defaultExp, resultTy, loc} =>
        RC.RCSWITCH
          {exp = compileExp context exp,
           expTy = expTy, (* contains no POLYty *)
           branches = map (fn {const, body} =>
                              {const = const,
                               body = compileExp context body})
                          branches,
           defaultExp = compileExp context defaultExp,
           resultTy = compileTy resultTy,
           loc = loc}
      | TL.TLCATCH {catchLabel, argVarList, catchExp, tryExp, resultTy, loc} =>
        RC.RCCATCH
          {catchLabel = catchLabel,
           argVarList = map compileVarInfo argVarList,
           catchExp = compileExp context catchExp,
           tryExp = compileExp context tryExp,
           resultTy = compileTy resultTy,
           loc = loc}
      | TL.TLTHROW {catchLabel, argExpList, resultTy, loc} =>
        RC.RCTHROW
          {catchLabel = catchLabel,
           argExpList = map (compileExp context) argExpList,
           resultTy = compileTy resultTy,
           loc = loc}
      | TL.TLFNM {argVarList, bodyTy, bodyExp, loc} =>
        (* argVarList may contain POLYty due to functor *)
        RC.RCFNM
          {argVarList = map compileVarInfo argVarList,
           bodyTy = compileTy bodyTy,
           bodyExp = compileExp context bodyExp,
           loc = loc}
      | TL.TLPOLY {btvEnv, constraints, expTyWithoutTAbs, exp, loc} =>
        let
          val extraArgs = generateExtraArgVars btvEnv
          val newContext = addExtraBinds context extraArgs
          val newContext = extendBtvEnv newContext btvEnv
          val newExpTyWithoutTAbs = compileTy expTyWithoutTAbs
          val newExp = compileExp newContext exp
        in
          case extraArgs of
            nil =>
            RC.RCPOLY {btvEnv = btvEnv,
                       constraints = nil,
                       expTyWithoutTAbs = expTyWithoutTAbs,
                       exp = newExp,
                       loc = loc}
          | _::_ =>
            RC.RCPOLY {btvEnv = btvEnv,
                       constraints = nil,
                       expTyWithoutTAbs =
                         T.FUNMty (map #ty extraArgs, newExpTyWithoutTAbs),
                       exp =
                         RC.RCFNM
                           {argVarList = extraArgs,
                            bodyTy = newExpTyWithoutTAbs,
                            bodyExp = newExp,
                            loc = loc},
                       loc = loc}
        end
      | TL.TLPRIMAPPLY {primOp, instTyList, argExpList, loc} =>
        RC.RCPRIMAPPLY
          {primOp = primOp,
           instTyList = instTyList, (* contains no POLYty *)
           argExpList = map (compileExp context) argExpList,
           loc = loc}
      | TL.TLOPRIMAPPLY {oprimOp={id, ty, path}, instTyList, argExp, loc} =>
        let
          val funTy = TypesBasics.tpappTy (ty, instTyList)
          val primTy = compileTy ty
          val primTy = TypesBasics.tpappTy (primTy, instTyList)
          val (extraArgTys, funTy) =
              case primTy of
                T.FUNMty (argTys, retTy) => (argTys, funTy)
              | _ => raise Bug.Bug "compileExp: TLOPRIMAPPLY: not function"
          (* it is sufficient to instantiate only the first (i.e., the
           * innermost) singleton type because it includes the entire
           * structure of oprimSelector. *)
          val singletonTy =
              case List.find
                     (fn T.SINGLETONty (T.INSTCODEty {oprimId, ...}) =>
                         id = oprimId
                       | _ => false)
                     extraArgTys of
                SOME (T.SINGLETONty sty) => sty
              | _ => raise Bug.Bug "compileExp: TLOPRIMAPPLY: no singleton ty"
          val primInst = generateInstance context singletonTy loc
        in
          case primInst of
            INST_APP {appExp, ...} =>
            compileExp context (appExp argExp)
          | INST_TLEXP exp =>
            compileExp
              context
              (TL.TLAPPM
                 {funExp = TL.TLCAST {exp = exp,
                                      expTy = T.SINGLETONty singletonTy,
                                      targetTy = funTy,
                                      cast = TL.TypeCast,
                                      loc = loc},
                  funTy = funTy,
                  argExpList = [argExp],
                  loc = loc})
          | INST_EXP exp =>
            RC.RCAPPM
              {funExp = RC.RCCAST {exp = exp,
                                   expTy = T.SINGLETONty singletonTy,
                                   targetTy = funTy,
                                   cast = RC.TypeCast,
                                   loc = loc},
               funTy = funTy,
               argExpList = [compileExp context argExp],
               loc = loc}
        end
      | TL.TLTAPP {exp, expTy, instTyList, loc} =>
        let
          val newExp = compileExp context exp
          val newExpTy = compileTy expTy
          val newInstTyList = instTyList (* contains no POLYty *)
          val funTy = TypesBasics.tpappTy (newExpTy, newInstTyList)
          val extraArgs =
              case funTy of
                T.FUNMty (argTys, retTy) =>
                if List.exists (fn T.SINGLETONty _ => true | _ => false) argTys
                then map (toExp context) (generateInstances context argTys loc)
                else nil
              | _ => nil
        in
          case extraArgs of
            nil =>
            RC.RCTAPP {exp = newExp,
                       expTy = newExpTy,
                       instTyList = newInstTyList,
                       loc = loc}
          | _::_ =>
            RC.RCAPPM {funExp = RC.RCTAPP {exp = newExp,
                                           expTy = newExpTy,
                                           instTyList = newInstTyList,
                                           loc = loc},
                       funTy = funTy,
                       argExpList = extraArgs,
                       loc = loc}
        end
      | TL.TLCAST {exp, expTy, targetTy, cast, loc} =>
        RC.RCCAST {exp = compileExp context exp,
                   expTy = compileTy expTy,
                   targetTy = compileTy targetTy,
                   cast = cast,
                   loc = loc}
      | TL.TLDYNAMICEXISTTAPP {existInstMap, exp, expTy, instTyList, loc} =>
        let
          val expTy = compileTy expTy
          val instTyList = instTyList (* contains no POLYty *)
          val funTy = TB.tpappTy (expTy, instTyList)
          val extraArgTys =
              case funTy of
                T.FUNMty (argTys, retTy) =>
                if List.exists (fn T.SINGLETONty _ => true | _ => false) argTys
                then argTys
                else nil
              | _ => nil
          val _ = case extraArgTys of
                    nil => raise Bug.Bug "RCDYNAMICEXISTTAPP"
                  | _ => ()
          val extraArgs =
              DynamicExistInstance.generateExtraArgs
                loc existInstMap extraArgTys
        in
          compileExp
            context
            (TL.TLAPPM
               {funExp = TL.TLTAPP {exp = exp,
                                    expTy = expTy,
                                    instTyList = instTyList,
                                    loc = loc},
                funTy = funTy,
                argExpList = extraArgs,
                loc = loc})
        end

  and compileDecl context rcdecl =
      case rcdecl of
        TL.TLEXPORTVAR {weak, var, exp} =>
        [RC.RCEXPORTVAR {weak = weak,
                         var = compileExVarInfo var,
                         exp = compileExp context exp}]
      | TL.TLEXTERNVAR (exVarInfo, provider) =>
        [RC.RCEXTERNVAR (compileExVarInfo exVarInfo, provider)]
      | TL.TLVAL {var, exp, loc} =>
        [RC.RCVAL {var = compileVarInfo var,
                   exp = compileExp context exp,
                   loc = loc}]
      | TL.TLVALREC (bindList, loc) =>
        [RC.RCVALREC (map (fn {var, exp} =>
                              {var = compileVarInfo var,
                               exp = compileExp context exp})
                          bindList,
                      loc)]
      | TL.TLVALPOLYREC {btvEnv, constraints,
                         recbinds = {var as {path, ty, id}, exp}::nil,
                         loc} =>
        (* to suppress redundant one-element record creation *)
        let
          val extraArgs = generateExtraArgVars btvEnv
          val newContext = extendBtvEnv context btvEnv
        in
          case extraArgs of
            nil =>
            let
              val var = compileVarInfo var
              val varTy = T.POLYty {boundtvars = btvEnv,
                                    constraints = nil,
                                    body = #ty var}
            in
              [RC.RCVAL
                 {var = var # {ty = varTy},
                  exp =
                    RC.RCPOLY
                      {btvEnv = btvEnv,
                       constraints = nil,
                       expTyWithoutTAbs = #ty var,
                       exp =
                         RC.RCLET
                           {decl =
                            RC.RCVALREC
                              ([{var = var,
                                 exp = compileExp newContext exp}],
                               loc),
                            body = RC.RCVAR (var, loc),
                            loc = loc},
                       loc = loc},
                  loc = loc}]
            end
          | _::_ =>
            let
              val newContext = addExtraBinds newContext extraArgs
              val localVar = {id = id, ty = ty, path = path}
              val var = {path = path,
                         ty = compileTy (T.POLYty {boundtvars = btvEnv,
                                                   constraints = nil,
                                                   body = ty}),
                         id = id} : RC.varInfo
              val expTy = compileTy ty
              val exp = compileExp newContext exp
              val recExp =
                  POLYFNM
                    (btvEnv, extraArgs,
                     LET (VALRECDEC [(localVar, Exp (exp, expTy))],
                          Var localVar)
                    )
            in
              VALDEC [(var, recExp)] loc
            end
        end

      | TL.TLVALPOLYREC {btvEnv, constraints, recbinds=bindList, loc} =>
        let
          val extraArgs = generateExtraArgVars btvEnv
          val newContext = extendBtvEnv context btvEnv
        in
          case extraArgs of
            nil =>
            let
              val newBindList =
                  map (fn (label, {var, exp}) =>
                          (label,
                           {var = compileVarInfo var,
                            exp = compileExp newContext exp}))
                      (RecordLabel.tupleList bindList)
              val tupleFields =
                  mapToLabelEnv
                    (fn (label, {var, ...}) => (label, RC.RCVAR (var, loc)))
                    newBindList
              val tupleTy =
                  T.RECORDty
                    (mapToLabelEnv
                       (fn (label, {var, ...}) => (label, #ty var))
                       newBindList)
              val tuplePolyTy =
                  T.POLYty
                    {boundtvars = btvEnv,
                     constraints = nil,
                     body = tupleTy}
              val tupleVar = newVar tuplePolyTy
            in
              RC.RCVAL
                {var = tupleVar,
                 exp =
                   RC.RCPOLY
                     {btvEnv = btvEnv,
                      constraints = nil,
                      expTyWithoutTAbs = tupleTy,
                      exp =
                        RC.RCLET
                          {decl =
                             RC.RCVALREC (map #2 newBindList, loc),
                           body =
                             RC.RCRECORD
                               {fields = tupleFields,
                                recordTy = tupleTy,
                                loc = loc},
                           loc = loc},
                      loc = loc},
                 loc = loc}
              :: map
                   (fn (label, {var, exp}) =>
                       let
                         val (_, btvEnv) = TyAlphaRename.newBtvEnv
                                             TyAlphaRename.emptyBtvMap
                                             btvEnv
                         val polyTy = T.POLYty {boundtvars = btvEnv,
                                                constraints = nil,
                                                body = #ty var}
                         val instTyList =
                             map T.BOUNDVARty
                                 (BoundTypeVarID.Map.listKeys btvEnv)
                         val (exp, expTy) =
                             SELECT (label, TAPP (Var tupleVar, instTyList))
                       in
                         RC.RCVAL
                           {var = var # {ty = polyTy},
                            exp =
                              RC.RCPOLY
                                {btvEnv = btvEnv,
                                 constraints = nil,
                                 expTyWithoutTAbs = expTy,
                                 exp = exp loc,
                                 loc = loc},
                            loc = loc}
                       end)
                   newBindList
            end
          | _::_ =>
            let
              (*
               * ['a#K. val rec f_1 = e_1 ... and f_n = e_n]
               *       ||
               *       vv
               * val F = ['a#K. fn A => let val rec f_1 = e_1'
               *                            ... and f_n = e_n'
               *                        in (f_1, ..., f_n) end]
               * val f_1 = ['a#K. fn A => #1 (F {'a} A)]
               * ...
               * val f_n = ['a#K. fn A => #n (F {'a} A)]
               *
               * This case breaks the uniqueness condition of bound type
               * variables for efficiency.
               *
               * This compilation introduces new POLYtys for each variable
               * f_1, ..., f_n. To give fresh ids to those bound type
               * variables, we need to manipulate all occurrance of f_1,
               * ..., f_n in this program in order to replace type
               * information. This does not make sense.
               *
               * 2012-9-10 Ohori. Changed to maintain Barendregt condition.
               * In order to keep the uniqueness we have only to introduce
               * new 'a's and the corresponding A's for each f_i to form:
               *   val f_i = ['a#K. fn A => #i (F {'a} A)]
               * This is local and simple, and does not introduce overhead.
               *)
              val newContext = addExtraBinds newContext extraArgs
              val recBinds =
                  map
                    (fn (label, {var as {path, ty, id}, exp}) =>
                        {localVar = {id = id, path = path, ty = ty},
                         var = {path = path,
                                ty = compileTy (T.POLYty {boundtvars = btvEnv,
                                                          constraints = nil,
                                                          body = ty}),
                                id = id} : RC.varInfo,
                         label = label,
                         expTy = compileTy ty,
                         exp = compileExp newContext exp})
                    (RecordLabel.tupleList bindList)

              val localRecExp =
                  POLYFNM
                    (btvEnv, extraArgs,
                     LET (VALRECDEC (map (fn {localVar, exp, expTy, ...} =>
                                             (localVar, Exp (exp, expTy)))
                                         recBinds),
                          RECORD (mapToLabelEnv (fn {localVar, label, ...} =>
                                                (label, Var localVar))
                                            recBinds)))
              val localRecVar = newVar (#2 localRecExp)

              val bodyBinds =
                  map
                    (fn {var, label, ...} =>
                        let
                          val (_, btvEnv) = TyAlphaRename.newBtvEnv TyAlphaRename.emptyBtvMap btvEnv
                          val extraArgs = generateExtraArgVars btvEnv
                          val instTyList =
                              map T.BOUNDVARty (BoundTypeVarID.Map.listKeys btvEnv)
                        in
                          (var,
                           POLYFNM
                             (btvEnv,
                              extraArgs,
                              SELECT (label,
                                      APPM (TAPP (Var localRecVar, instTyList),
                                            map Var extraArgs))))
                        end
                    )
                      recBinds
                      handle e => raise e
            in
              VALDEC [(localRecVar, localRecExp)] loc
              @ VALDEC bodyBinds loc
            end
        end

  fun compile topBlockList =
      let
        val context = {instanceEnv = SingletonTyMap.empty,
                       btvEnv = BoundTypeVarID.Map.empty} : context
        val rcdeclList = List.concat (map (compileDecl context) topBlockList)
      in
        rcdeclList
      end

end
