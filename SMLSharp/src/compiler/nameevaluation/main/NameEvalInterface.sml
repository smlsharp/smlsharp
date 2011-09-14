(* the initial error code of this file : EI-001 *)
structure NameEvalInterface =
struct
local
  structure I = IDCalc
  structure T = Types
  structure IT = IDTypes
  structure V = NameEvalEnv
  structure BV = BuiltinEnv
  structure PI = PatternCalcInterface
  structure PC = PatternCalc
  structure U = NameEvalUtils
  structure EU = UserErrorUtils
  structure E = NameEvalError
  structure AI = AbsynInterface
  structure A = Absyn
  structure N = NormalizeTy
  structure Ty = EvalTy
  structure ITy = EvalIty
  structure Sig = EvalSig
  fun bug s = Control.Bug ("NameEvalInterface: " ^ s)
  val nilPath = nil

  (* FIXME factor out this def into some unique plcae *)
  val FUNCORPREFIX = "_"


in

  val revealKey = RevealID.generate() (* global reveal key *)
  val emptyContext = 
      {
       oprimEnv=OPrimMap.empty,
       tvarEnv=TvarMap.empty,
       varEnv=VarMap.empty
      }

  fun evalPidec path (topEnv as {Env=env, FunE, SigE}) pidec =
      case pidec of
        PI.PIVAL {scopedTvars, vid=name, body, loc} =>
        let
          val (tvarEnv, kindedTvars) =
              Ty.evalScopedTvars loc Ty.emptyTvarEnv env scopedTvars
          val path = path@[name]
          fun evalOverloadCase {tyvar, expTy, matches, loc} =
              let
                val tvar = Ty.evalTvar loc tvarEnv tyvar
                val expTy = Ty.evalTy tvarEnv env expTy
                val matches = map evalMatch matches
              in
                {tvar=tvar, expTy=expTy, matches=matches, loc=loc}
              end
          and evalMatch {instTy, instance} =
              let
                val instTy = Ty.evalTy tvarEnv env instTy
                val instance = evalInstance instance
              in
                {instTy=instTy, instance=instance}
              end
          and evalInstance instance =
              case instance of
                AI.INST_OVERLOAD overloadCase =>
                I.INST_OVERLOAD (evalOverloadCase overloadCase)
              | AI.INST_LONGVID {vid} =>
                let
                  fun error e =
                      (EU.enqueueError (loc, e);
                       I.INST_EXVAR ({path=path, ty=IT.TYERROR}, loc))
                in
                  (case V.lookupId env vid of
                     IT.IDEXVAR {path, ty} =>
                     I.INST_EXVAR ({path=path, ty=ty}, loc)
                   | IT.IDBUILTINVAR {primitive, ty} =>
                     I.INST_PRIM ({primitive=primitive, ty=ty}, loc)
                   | IT.IDVAR id =>
                     error (E.InvalidOverloadInst("EI-010", {longid=vid}))
                   | IT.IDOPRIM id =>
                     error (E.InvalidOverloadInst("EI-020", {longid=vid}))
                   | IT.IDCON _ =>
                     error (E.InvalidOverloadInst("EI-030", {longid=vid}))
                   | IT.IDEXN _ =>
                     error (E.InvalidOverloadInst("EI-040", {longid=vid}))
                   | IT.IDEXNREP _ =>
                     error (E.InvalidOverloadInst("EI-050", {longid=vid}))
                   | IT.IDEXEXN {path,ty} =>
                     error (E.InvalidOverloadInst("EI-060", {longid=vid}))
                   | IT.IDSPECVAR _ => raise bug "SPEC id status"
                   | IT.IDSPECEXN _ => raise bug "SPEC id status"
                   | IT.IDSPECCON => raise bug "SPEC id status")
                  handle V.LookupId =>
                         error (E.VarNotFound("EI-070",{longid=vid}))
                end
        in
          case body of
            AI.VAL_EXTERN {ty} =>
            let
              val ty = Ty.evalTy tvarEnv env ty
              val ty = 
                  case kindedTvars of
                    nil => ty
                  | _ => IT.TYPOLY(kindedTvars,ty)
              val idstatus = IT.IDEXVAR {path=path, ty=ty}
              val icdecl = I.ICEXTERNVAR ({path=path, ty=ty}, loc)
            in
              (V.rebindId (V.emptyEnv, name, idstatus), [icdecl])
            end
          | AI.VAL_BUILTIN {builtinName, ty} =>
            let
              val ty = Ty.evalTy tvarEnv env ty
              val ty = 
                  case kindedTvars of
                    nil => ty
                  | _ => IT.TYPOLY(kindedTvars,ty)
            in
              case BuiltinPrimitive.findPrimitive builtinName of
                SOME primitive => 
                let
                  val idstatus = IT.IDBUILTINVAR {primitive=primitive, ty=ty}
                in
                  (V.rebindId (V.emptyEnv, name, idstatus), nil)
                end
              | NONE => 
                (EU.enqueueError
                   (loc, E.PrimitiveNotFound("EI-080", {name = builtinName}));
                 (V.emptyEnv, nil))
            end
          | AI.VAL_OVERLOAD overloadCase =>
            let
              val id = OPrimID.generate()
              val idstatus = IT.IDOPRIM id
              val overloadCase = evalOverloadCase overloadCase
              val decl = I.ICOVERLOADDEF {boundtvars=kindedTvars,
                                          id=id,
                                          path=path,
                                          overloadCase=overloadCase,
                                          loc = loc}
              in
              (V.rebindId (V.emptyEnv, name, idstatus), [decl])
            end
        end
      | PI.PITYPE {tyvars, tycon, ty, opacity, loc} =>
        let
          val _ = EU.checkNameDuplication
                    (fn {name, eq} => name)
                    tyvars
                    loc
                    (fn s => E.DuplicateTypParms("EI-090",s))
          val (tvarEnv, tvarList) = Ty.genTvarList Ty.emptyTvarEnv tyvars
          val ty = Ty.evalTy tvarEnv env ty
          val tfun =
              case N.tyForm tvarList ty of
                N.TYNAME {tfun,...} => tfun
              | N.TYTERM ty =>
                let
                  val iseq = N.admitEq tvarList ty
                  val tfun =
                      IT.TFUN_DEF {iseq=iseq,
                                  formals=tvarList,
                                  realizerTy=ty
                                 }
                in
                  tfun
                end
        in
          (case opacity of
             AI.TRANSPARENT =>
             (V.rebindTstr (V.emptyEnv, tycon, V.TSTR tfun), nil)
           | _ =>
             let
               val iseq = case opacity of AI.OPAQUE_NONEQ => false
                                        | _ => true
               val id = TypID.generate()
               val absTfun =
                   IT.TFUN_VAR
                     (IT.mkTfv(
                      IT.TFUN_DTY {id = id,
                                  iseq=iseq,
                                  formals=tvarList,
                                  conSpec=SEnv.empty,
                                  liftedTys=IT.emptyLiftedTys,
                                  dtyKind=
                                    IT.OPAQUE
                                    {tfun=tfun, revealKey=revealKey}
                                 }
                      )
                     )
(*
               val decl = I.ICOPAQUETYPE{tfun=absTfun,refTfun=tfun}
*)
             in
               (V.rebindTstr (V.emptyEnv, tycon, V.TSTR absTfun), nil)
             end
          )
        end               
      | PI.PITYPEBUILTIN {tycon, builtinName, opacity, loc} =>
        (case BV.findTfun builtinName of
           SOME tfun =>
             (V.rebindTstr (V.emptyEnv, tycon, V.TSTR tfun), nil)
         | NONE =>
           (EU.enqueueError
              (loc, E.BuiltinTyNotFound("EI-100", {name = builtinName}));
            (V.emptyEnv, nil))
        )

      | PI.PIDATATYPE {datbind, loc} =>
        let
          (* FIXME *)
          val datbind =
              map (fn {tyvars,tycon,conbind,opacity} =>
                      {tyvars=tyvars,tycon=tycon,conbind=conbind})
                  datbind
        in
          Ty.evalDatatype path env (datbind, loc)
        end

      | PI.PITYPEREP {tycon, origTycon=path, opacity, loc} =>
      (*
       *                syntax                           opacity
       * datatype foo = datatype bar                   TRANSPARENT
       * datatype foo ( = datatype bar )               OPAQUE_NONEQ
       * datatype foo ( = datatype bar ) as eqtype     OPAQUE_EQ
       *)
        (
         case V.findTstr(env, path) of
           NONE => (EU.enqueueError
                      (loc, E.DataTypeNameUndefined("EI-110", {longid = path}));
                    (V.emptyEnv, nil))
         | SOME tstr =>
           let
             val (tstr, varE) =
                 case tstr of
                   V.TSTR_DTY {tfun, varE, formals, conSpec} => 
                   (case opacity of
                      AI.TRANSPARENT => (tstr, varE)
                    | _ => 
                      let
                        val revealKey = RevealID.generate() (* any key is OK *)
                        val id = TypID.generate()
                        val iseq =
                            case opacity of
                              AI.OPAQUE_NONEQ => false
                            | AI.OPAQUE_EQ => 
                              if IT.tfunIseq tfun then true
                              else 
                                (EU.enqueueError
                                   (loc,
                                    E.TypArity("EI-120", {longid = path}));
                                 false)
                            | _ => raise bug "impossible"
                        val tfun =
                            IT.TFUN_VAR
                              (IT.mkTfv(
                               IT.TFUN_DTY {id=id,
                                            iseq=iseq,
                                            formals=formals,
                                            conSpec = SEnv.empty,
                                            liftedTys = IT.tfunLiftedTys tfun,
                                            dtyKind =
                                            IT.OPAQUE{tfun=tfun,
                                                      revealKey=revealKey}
                                           }
                               )
                              )
                      in
                        (V.TSTR_DTY{tfun=tfun,
                                    varE=SEnv.empty,
                                    formals=formals,
                                    conSpec=SEnv.empty},
                         SEnv.empty)
                      end
                   )
                 | _ => 
                   (EU.enqueueError
                      (loc, E.DataTypeNameExpected("EI-130", {longid = path}));
                    (tstr, SEnv.empty))
             val env = V.rebindTstr (V.emptyEnv, tycon, tstr)
             val env = SEnv.foldri
                       (fn (name, idstatus, env) =>
                           V.rebindId(env, name, idstatus))
                       env
                       varE
           in
             (env, nil)
           end
        )
      | PI.PIEXCEPTION {vid=name, ty=tyOpt, loc} =>
        let
          val ty =
              case tyOpt of
                NONE => BV.exnTy
              | SOME ty => 
                IT.TYFUNM([Ty.evalTy Ty.emptyTvarEnv env ty],
                          BV.exnTy)
          val idstatus = IT.IDEXEXN {path=path@[name], ty=ty}
          val icdecl = I.ICEXTERNEXN ({path=path@[name], ty=ty}, loc)
        in
          (V.rebindId  (V.emptyEnv, name, idstatus), [icdecl])
        end

      | PI.PIEXCEPTIONREP {vid=name, origId=path, loc} =>
        (
         case V.findId(env, path) of
           NONE =>
           (
            EU.enqueueError
              (loc, E.ExceptionNameUndefined("EI-140", {longid = path}));
            (V.emptyEnv, nil))
         | SOME (idstatus as IT.IDEXEXN exnInfo) => 
           let
             val icdecl = I.ICEXTERNEXN (exnInfo, loc)
           in
             (V.rebindId  (V.emptyEnv, name, idstatus), [icdecl])
           end
         | SOME (idstatus as IT.IDEXN exnInfo) => 
           (V.rebindId  (V.emptyEnv, name, IT.IDEXNREP exnInfo), nil)
         | _ => 
           (EU.enqueueError
              (loc, E.ExceptionExpected("EI-150", {longid = path}));
            (V.emptyEnv, nil))
        )

      | PI.PISTRUCTURE {strid, strexp, loc} =>
        let
          val (newEnv, newdecls) = evalPistr (path@[strid]) topEnv strexp
        in
          (V.rebindStr (V.emptyEnv, strid, newEnv), newdecls)
        end
          
  and evalPistr path topEnv pistrexp = 
      case pistrexp of

        PI.PISTRUCT {decs, loc} =>
(
U.print "PISTRUCT decs\n";
map U.printPidec decs;
U.print "\n";
        foldl
          (fn (decl, (env, icdecls)) =>
              let
                val evalTopEnv = V.topEnvWithEnv (topEnv,env)
                val (newEnv, newdecls) = evalPidec path evalTopEnv decl
              in
                (V.unionEnv "210" loc (env, newEnv), icdecls@newdecls)
              end
          )
        (V.emptyEnv, nil)
        decs
)
  fun internalizeIdstatus idstatus =
      case idstatus of
        IT.IDEXEXN {path, ty} =>
        let
          val newId = ExnID.generate() (* dummy *)
        in
          IT.IDEXN {id=newId, ty= ty}
        end
      | _ => idstatus
  fun internalizeEnv (V.ENV {tyE, varE, strE=V.STR envMap}) =
      let
        val varE = SEnv.map internalizeIdstatus varE
        val strE = V.STR (SEnv.map internalizeEnv envMap)
      in
        V.ENV{tyE=tyE, varE=varE, strE=strE}
      end
  fun evalFunDecl topEnv {funid=functorName,
                          param={strid=argStrName, sigexp=argSig},
                          strexp=bodyStr, loc} =
      let
val _ = U.print "argplsig in nameeval interface\n"
val _ = U.printPlsigexp argSig
val _ = U.print "\n"
        val 
        {
         argSig=argSig,
         argEnv=argEnv,
         extraTvars=extraTvars,
         polyArgPats=polyArgPats,
         exnTagDecls=exnTagDecls,
         dummyIdfunArgTy=dummyIdfunArgTy,
         firstArgPat=firstArgPat,
         tfvDecls = tfvDecls
        } = FunctorUtils.evalFunArg (topEnv, argSig, loc)

val _ = U.print "argSig in nameeval interface\n"
val _ = U.printEnv argSig
val _ = U.print "\n"
val _ = U.print "extraTvars\n"
val _ = map U.printTvar extraTvars
val _ = U.print "\n"


        val topArgEnv = V.ENV {varE=SEnv.empty,
                            tyE=SEnv.empty,
                            strE=V.STR (SEnv.singleton(argStrName, argEnv))
                            }
        val evalEnv = V.topEnvWithEnv (topEnv, topArgEnv)

        val startTypid = TypID.generate()

        val (bodyInterfaceEnv,_) = evalPistr [functorName] evalEnv bodyStr
        val bodyEnv = internalizeEnv bodyInterfaceEnv
        val
        {
         allVars = allVars,
         typidSet = typidSet,
         exnIdSet = exnIdSet
        } = FunctorUtils.makeBodyEnv bodyEnv loc

        (* FIXME (not a bug):
           The following is to restrict the typids to be refreshed
           are those that are created in the functor body.
           Not very elegant. Need to review.
         *)
        val typidSet =
            TypID.Set.filter
            (fn id => 
                case TypID.compare(id, startTypid) of
                  GREATER => true
                | _ => false)
            typidSet

        fun varToTy (_,var) =
            case var of
              I.ICEXVAR ({path, ty},_) => ty
            | I.ICEXN ({path, id, ty},_) => ty
            | I.ICEXN_CONSTRUCTOR ({id, ty, path}, loc) => BV.exntagTy
            | _ => 
              (
               raise bug "*** VARTOTY ***"
              )

        val bodyTy =
            case allVars of
              nil => BV.unitTy
            | _ => IT.TYRECORD (Utils.listToFields (map varToTy allVars))
        val polyArgTys = map (fn (x,ty) => ty) polyArgPats 
        val firstArgTy =
            case dummyIdfunArgTy of
              SOME ty => SOME(IT.TYFUNM([ty],ty))
            | NONE => NONE
        val functorTy1 =
            case polyArgTys of
              nil => bodyTy
            | _ => IT.TYFUNM(polyArgTys, bodyTy)
        val functorTy2 =
            case firstArgTy of
              NONE => functorTy1
            | SOME ty  => 
              IT.TYPOLY(map (fn x => (x, IT.UNIV)) extraTvars,
                        IT.TYFUNM([ty], functorTy1))
        val functorTy =
            case functorTy2 of
              IT.TYPOLY _ => functorTy2
            | IT.TYFUNM _ => functorTy2
            | _ => IT.TYFUNM([BV.unitTy], functorTy2)

        val decl =
            I.ICEXTERNVAR ({path=[FUNCORPREFIX,functorName], ty=functorTy},
                           loc)
                   
        val functorExp = I.ICEXVAR ({path=[FUNCORPREFIX,functorName],
                                     ty=functorTy}, loc)

        val funEEntry:V.funEEntry =
            {argSig = argSig,
             argStrName = argStrName,
             argEnv = argEnv,
             dummyIdfunArgTy = dummyIdfunArgTy,
             polyArgTys = polyArgTys,
             typidSet=typidSet,  (* FIXME: is this right? *)
             exnIdSet=exnIdSet,  (* FIXME: is this right? *)
             bodyEnv = bodyEnv,
             bodyVarExp = functorExp
            }
            
        val funE =  SEnv.singleton(functorName, funEEntry)
        val returnTopEnv = V.topEnvWithFunE(V.emptyTopEnv, funE)
      in
        (returnTopEnv, [decl])
      end

  fun evalPitopdec topEnv pitopDec =
      case pitopDec of
        PI.PIDEC pidec => 
        let
          val (returnEnv, decls) = evalPidec nilPath topEnv pidec
        in
          (V.topEnvWithEnv(V.emptyTopEnv, returnEnv), decls)
        end
      | PI.PIFUNDEC fundec =>
        let
          val (returnTopEnv, decls) = evalFunDecl topEnv fundec
        in
          (returnTopEnv, decls)
        end


  fun evalPitopdecList topEnv pitopdecList =
      foldl
      (fn (pitopdec, (returnTopEnv, icdecls)) =>
          let
            val evalTopEnv = V.topEnvWithTopEnv (topEnv, returnTopEnv)
            val (newTopEnv, newdecls) = evalPitopdec evalTopEnv pitopdec
            val loc = PI.pitopdecLoc pitopdec
          in
            (V.unionTopEnv "211" loc (returnTopEnv,newTopEnv),
             icdecls @ newdecls)
          end
      )
      (V.emptyTopEnv, nil)
      pitopdecList

  fun evalInterfaceDec env ({interfaceId,requires=idLocList,topdecs,...}
                            :PI.interfaceDec, IntEnv) =
      let
        val evalTopEnv =
            foldl
            (fn ({id,loc}, evalTopEnv) =>
                let
                  val newTopEnv = 
                      case InterfaceID.Map.find (IntEnv, id) of
                        NONE => raise bug "InterfaceID undefined"
                      | SOME {topEnv,...} => topEnv
                in
                  V.unionTopEnv "212" loc (evalTopEnv, newTopEnv)
                end
            )
            env
            idLocList
        val (topEnv, icdecls) = evalPitopdecList evalTopEnv topdecs
      in
        case InterfaceID.Map.find(IntEnv, interfaceId) of
          NONE => InterfaceID.Map.insert
                    (IntEnv,
                     interfaceId,
                     {source=topdecs, topEnv=topEnv, decls=icdecls}
                    )
        | SOME _ => raise bug "duplicate interfaceid"
      end

  fun evalInterfaces env interfaceDecList =
      foldl (evalInterfaceDec env) InterfaceID.Map.empty interfaceDecList


end
end
