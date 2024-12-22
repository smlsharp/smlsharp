(**
 * Platform indepedent type-directed compilation for:
 *  record polymorphism, 
 *  natural data representation, and
 *  type-reification/dynamic typing.
 *
 * @copyright (C) 2021 SML# Development Team.
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

  fun newVar ty =
      {path = [],
       ty = ty,
       id = VarID.generate ()} : RC.varInfo

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
    | INST_VALUE of RC.rcvalue * Loc.loc
    | INST_TLEXP of TL.tlexp

  fun compileTy ty =
      case ty of
        T.SINGLETONty _ => ty
      | T.BACKENDty _ => ty
      | T.ERRORty => ty
      | T.DUMMYty _ => ty
      | T.EXISTty _ => ty
      | T.TYVARty (ref (T.SUBSTITUTED ty)) => compileTy ty
      | T.TYVARty (ref (T.TVAR _)) => raise Bug.Bug "compileTy"
      | T.BOUNDVARty tid => ty
      | T.FUNMty (argTys, retTy) =>
        (* argTys may contain polyTy due to functor. *)
        T.FUNMty (map compileTy argTys, compileTy retTy)
      | T.RECORDty fields =>
        T.RECORDty (RecordLabel.Map.map compileTy fields)
      | T.CONSTRUCTty {tyCon, args} =>
        T.CONSTRUCTty {tyCon = tyCon, args = map compileTy args}
      | T.POLYty {boundtvars, constraints, body} =>
        if BoundTypeVarID.Map.isEmpty boundtvars andalso null constraints
        then T.FUNMty (generateExtraArgs boundtvars, compileTy body)
        else T.POLYty {boundtvars = boundtvars,
                       constraints = constraints,
                       body = T.FUNMty (generateExtraArgs boundtvars,
                                        compileTy body)}

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
          T.TAGty arg =>
          Option.map INST_VALUE (TagKind.generateInstance env arg loc)
        | T.SIZEty arg =>
          Option.map INST_VALUE (SizeKind.generateInstance env arg loc)
        | T.REIFYty arg =>
          Option.map INST_TLEXP (ReifyKind.generateInstance env arg loc)
        | T.INDEXty arg =>
          Option.map INST_TLEXP (RecordKind.generateInstance env arg loc)
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
          SOME var => INST_VALUE (RC.RCVAR var, loc)
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
        INST_VALUE value => RC.RCVALUE value
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

  and generateSize context loc ty =
      case generateInstance context (T.SIZEty ty) loc of
        INST_VALUE (value, loc) => value
      | _ => raise Bug.Bug "generateSize"

  and generateTag context loc ty =
      case generateInstance context (T.TAGty ty) loc of
        INST_VALUE (value, loc) => value
      | _ => raise Bug.Bug "generateTag"

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
        RC.RCVALUE (generateSize context loc ty, loc)
      | TL.TLINDEXOF {label, recordTy, loc} =>
        (
          case TypesBasics.derefTy recordTy of
            T.DUMMYty (_, T.KIND {tvarKind = T.REC _, ...}) =>
            (* dummy index *)
            RC.RCCAST
              {exp = RC.RCVALUE (RC.RCCONSTANT (RC.INT (RC.WORD32 0w0)), loc),
               expTy = BuiltinTypes.word32Ty,
               targetTy = T.SINGLETONty (T.INDEXty (label, recordTy)),
               cast = RC.TypeCast,
               loc = loc}
          | T.RECORDty fields =>
            RC.RCINDEXOF
              {label = label,
               fields =
                 RecordLabel.Map.map
                   (fn ty =>
                       let
                         val ty = compileTy ty
                       in
                         {ty = ty, size = generateSize context loc ty}
                       end)
                   fields,
               loc = loc}
          | _ =>
            toExp context
                  (generateInstance context (T.INDEXty (label, recordTy)) loc)
        )
      | TL.TLREIFYTY {ty, loc} =>
        toExp context (generateInstance context (T.REIFYty ty) loc)
      | TL.TLINT (const, loc) =>
        RC.RCVALUE (RC.RCCONSTANT (RC.INT const), loc)
      | TL.TLCONSTANT (const, loc) =>
        RC.RCVALUE (RC.RCCONSTANT (RC.CONST const), loc)
      | TL.TLSTRING (string, loc) =>
        RC.RCSTRING (string, loc)
      | TL.TLVAR (varInfo, loc) =>
        RC.RCVALUE (RC.RCVAR (compileVarInfo varInfo), loc)
      | TL.TLEXVAR (exVarInfo as {path, ty}, loc) =>
        RC.RCEXVAR (compileExVarInfo exVarInfo, loc)
      | TL.TLAPPM {funExp, funTy, argExpList, loc} =>
        RC.RCAPPM
          {funExp = compileExp context funExp,
           funTy = compileTy funTy,
           instTyList = nil,
           argExpList = map (compileExp context) argExpList,
           loc = loc}
      | TL.TLLET {decl, body, loc} =>
        foldr
          (fn (decl, exp) => RC.RCLET {decl = decl, body = exp, loc = loc})
          (compileExp context body)
          (compileDecl context decl)
      | TL.TLRECORD {fields, recordTy, loc} =>
        RC.RCRECORD
          {fields =
             RecordLabel.Map.mergeWith
               (fn (SOME exp, SOME ty) =>
                   let
                     val ty = compileTy ty
                   in
                     SOME {exp = compileExp context exp,
                           ty = ty,
                           size = generateSize context loc ty,
                           tag = generateTag context loc ty}
                   end
                 | _ => raise Bug.Bug "compileExp: TLRECORD")
               (fields, recordTy),
           loc = loc}
      | TL.TLSELECT {label, recordExp, recordTy, resultTy, loc} =>
        let
          val resultTy = compileTy resultTy
        in
          RC.RCSELECT
            {indexExp =
               toExp
                 context
                 (generateInstance context (T.INDEXty (label, recordTy)) loc),
             label = label,
             recordExp = compileExp context recordExp,
             recordTy = compileTy recordTy,
             resultTy = resultTy,
             resultSize = generateSize context loc resultTy,
             resultTag = generateTag context loc resultTy,
             loc = loc}
        end
      | TL.TLMODIFY {label, recordExp, recordTy, elementExp, elementTy, loc} =>
        let
          val elementTy = compileTy elementTy
        in
          RC.RCMODIFY
            {indexExp =
               toExp
                 context
                 (generateInstance context (T.INDEXty (label, recordTy)) loc),
             label = label,
             recordExp = compileExp context recordExp,
             recordTy = compileTy recordTy,
             elementExp = compileExp context elementExp,
             elementTy = elementTy,
             elementSize = generateSize context loc elementTy,
             elementTag = generateTag context loc elementTy,
             loc = loc}
        end
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
          {recursive = false,
           rules = [{catchLabel = catchLabel,
                     argVarList = map compileVarInfo argVarList,
                     catchExp = compileExp context catchExp}],
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
          {btvEnv = BoundTypeVarID.Map.empty,
           constraints = nil,
           argVarList = map compileVarInfo argVarList,
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
          RC.RCFNM {btvEnv = btvEnv,
                    constraints = constraints,
                    argVarList = extraArgs,
                    bodyTy = newExpTyWithoutTAbs,
                    bodyExp = newExp,
                    loc = loc}
        end
      | TL.TLPRIMAPPLY {primOp, instTyList, argExpList, loc} =>
        RC.RCPRIMAPPLY
          {primOp = primOp,
           instTyList = instTyList, (* contains no POLYty *)
           instSizeList = map (generateSize context loc) instTyList,
           instTagList = map (generateTag context loc) instTyList,
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
          | INST_VALUE value =>
            RC.RCAPPM
              {funExp = RC.RCCAST {exp = RC.RCVALUE value,
                                   expTy = T.SINGLETONty singletonTy,
                                   targetTy = funTy,
                                   cast = RC.TypeCast,
                                   loc = loc},
               funTy = funTy,
               instTyList = nil,
               argExpList = [compileExp context argExp],
               loc = loc}
        end
      | TL.TLTAPP {exp, expTy, instTyList, loc} =>
        let
          val newExp = compileExp context exp
          val newExpTy = compileTy expTy
          val newInstTyList = map compileTy instTyList
          val funTy = TypesBasics.tpappTy (newExpTy, newInstTyList)
          val extraArgs =
              case TypesBasics.derefTy funTy of
                T.FUNMty (argTys, retTy) =>
                if List.exists (fn T.SINGLETONty _ => true | _ => false) argTys
                then map (toExp context) (generateInstances context argTys loc)
                else nil
              | _ => nil
        in
          RC.RCAPPM {funExp = newExp,
                     funTy = newExpTy,
                     instTyList = newInstTyList,
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
          val newExp = compileExp context exp
          val newExpTy = compileTy expTy
          val newInstTyList = map compileTy instTyList
          val funTy = TypesBasics.tpappTy (newExpTy, newInstTyList)
          val extraArgTys =
              case funTy of
                T.FUNMty (argTys, retTy) =>
                if List.exists (fn T.SINGLETONty _ => true | _ => false) argTys
                then argTys
                else nil
              | _ => nil
          val _ = case extraArgTys of
                    nil => raise Bug.Bug "TLDYNAMICEXISTTAPP"
                  | _ => ()
          val extraArgs =
              DynamicExistInstance.generateExtraArgs
                loc existInstMap extraArgTys
        in
          RC.RCAPPM {funExp = newExp,
                     funTy = newExpTy,
                     instTyList = newInstTyList,
                     argExpList = map (compileExp context) extraArgs,
                     loc = loc}
        end

  and compileDecl context tldecl =
      case tldecl of
        TL.TLEXPORTVAR {weak, var, exp} =>
        [RC.RCEXPORTVAR {weak = weak,
                         var = compileExVarInfo var,
                         exp = SOME (compileExp context exp)}]
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
      | TL.TLVALPOLYREC {btvEnv, constraints, recbinds as [{var, exp}], loc} =>
        let
          (*
           * ['a. val rec f = exp]
           *        ||
           *        vv
           * val f = ['a. let val rec f = exp in f end]
           *)
          val polyTy = T.POLYty {boundtvars = btvEnv,
                                 constraints = nil,
                                 body = #ty var}
        in
          compileDecl
            context
            (TL.TLVAL
               {var = var # {ty = polyTy},
                exp =
                  TL.TLPOLY
                    {btvEnv = btvEnv,
                     constraints = nil,
                     expTyWithoutTAbs = #ty var,
                     exp =
                       TL.TLLET
                         {decl = TL.TLVALREC (recbinds, loc),
                          body = TL.TLVAR (var, loc),
                          loc = loc},
                     loc = loc},
                loc = loc})
        end
      | TL.TLVALPOLYREC {btvEnv, constraints, recbinds, loc} =>
        let
          (*
           * ['a. val rec f = exp1 and g = exp2]
           *        ||
           *        vv
           * val x = ['a. let val rec f = exp1 and g = exp2 in (f, g) end]
           * val f = ['a. #1 (x {'a})]
           * val g = ['a. #2 (x {'a})]
           *)
          val recbindMap = RecordLabel.tupleMap recbinds
          val tupleTyMap = RecordLabel.Map.map (#ty o #var) recbindMap
          val tupleTy = T.RECORDty tupleTyMap
          val tupleVar =
              newVar (T.POLYty {boundtvars = btvEnv,
                                constraints = constraints,
                                body = tupleTy})
          val dec =
              TL.TLVAL
                {var = tupleVar,
                 exp =
                   TL.TLPOLY
                     {btvEnv = btvEnv,
                      constraints = constraints,
                      expTyWithoutTAbs = tupleTy,
                      exp =
                        TL.TLLET
                          {decl = TL.TLVALREC (recbinds, loc),
                           body =
                             TL.TLRECORD
                               {fields = RecordLabel.Map.map
                                           (fn {var, ...} =>
                                               TL.TLVAR (var, loc))
                                           recbindMap,
                                recordTy = tupleTyMap,
                                loc = loc},
                           loc = loc},
                      loc = loc},
                 loc = loc}
          val instTyList =
              map T.BOUNDVARty (BoundTypeVarID.Map.listKeys btvEnv)
          val decs =
              RecordLabel.Map.foldri
                (fn (label, {var, exp}, decs) =>
                    let
                      val polyTy = T.POLYty {boundtvars = btvEnv,
                                             constraints = constraints,
                                             body = #ty var}
                    in
                      TL.TLVAL
                        {var = var # {ty = polyTy},
                         exp =
                           TL.TLPOLY
                             {btvEnv = btvEnv,
                              constraints = constraints,
                              expTyWithoutTAbs = #ty var,
                              exp =
                                TL.TLSELECT
                                  {label = label,
                                   recordExp =
                                     TL.TLTAPP
                                       {exp = TL.TLVAR (tupleVar, loc),
                                        expTy = #ty tupleVar,
                                        instTyList = instTyList,
                                        loc = loc},
                                   recordTy = tupleTy,
                                   resultTy = #ty var,
                                   loc = loc},
                              loc = loc},
                         loc = loc}
                      :: decs
                    end)
                nil
                recbindMap
        in
          List.concat (map (compileDecl context) (dec :: decs))
        end

  fun makeUerlelvelPrimitiveExternDecls externList =
      let
        fun makeExtern (exVarInfo, provider) =
            RC.RCEXTERNVAR (compileExVarInfo exVarInfo, provider)
      in
        map makeExtern externList
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
