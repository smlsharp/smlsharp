(* the initial error code of this file : CP-001 *)
structure CheckProvide =
struct
local
  structure I = IDCalc
  structure T = IDTypes
  structure V = NameEvalEnv
  structure BV = BuiltinEnv
  structure PI = PatternCalcInterface
  structure U = NameEvalUtils
  structure EU = UserErrorUtils
  structure E = NameEvalError
  structure A = AbsynInterface
  structure N = NormalizeTy
  structure Ty = EvalTy
  structure Sig = EvalSig
  structure FU = FunctorUtils
  structure EI = NameEvalInterface
  val nilPath = nil
  fun bug s = Control.Bug ("CheckProvide: " ^ s)
  exception Fail

  fun opaqueTfun loc path tfun =
      case T.derefTfun tfun of
        T.TFUN_DEF _ => 
        (EU.enqueueError(loc,E.ProvideOpaqueExpected("CP-010",{longid=path}));
         raise Fail)
      | T.TFUN_VAR (ref tfunkind) =>
        (case tfunkind of
           T.TFUN_DTY {dtyKind=T.OPAQUE{tfun,...},...} => tfun 
         | _ => 
           (EU.enqueueError
              (loc,E.ProvideOpaqueExpected("CP-020",{longid=path}));
            raise Fail)
        )
  fun originalTfun tfun =
      let
        val tfun = T.derefTfun tfun 
      in
        case tfun of
          T.TFUN_DEF _ => tfun
        | T.TFUN_VAR (ref tfunkind) =>
          (case tfunkind of
             T.TFUN_DTY {dtyKind=T.OPAQUE{tfun,...},...} =>
             originalTfun tfun 
           | _ => tfun
          )
      end


  fun checkDatbind
        loc
        path
        evalEnv
        env
        (name,
         defTstr,
         defRealTstr,
         defRealTfun,
         {tyvars, tycon, conbind, opacity}) =
      (*
       *                syntax                           opacity (in datbind)
       * datatype 'a foo = FOO of 'a | BAR                  TRANSPARENT
       * datatype 'a foo ( = FOO of 'a | BAR )              OPAQUE_NONEQ
       * datatype 'a foo ( = FOO of 'a | BAR ) as eqtype    OPAQUE_EQ
       *)
      let
        val (tvarEnv, tvarList) = Ty.genTvarList Ty.emptyTvarEnv tyvars
      in
        let
          val {id, iseq, formals, conSpec, dtyKind,...} =
              case T.derefTfun defRealTfun of 
                T.TFUN_DEF _ =>
                (EU.enqueueError
                   (loc,E.ProvideDtyExpected ("CP-030",{longid=path@[tycon]}));
                 raise Fail)
              | T.TFUN_VAR(ref(T.TFUN_DTY x)) => x
              | _ =>
                (EU.enqueueError
                   (loc,E.ProvideDtyExpected ("CP-040",{longid=path@[tycon]}));
                 raise Fail)
          val eqEnv =
              if length tvarList = length formals then
                let
                  val tvarPairs = ListPair.zip (tvarList, formals)
                in
                  foldr
                    (fn (({id=tv1,...}, {id=tv2,...}), eqEnv) =>
                        TvarID.Map.insert(eqEnv, tv1, tv2)
                    )
                    TvarID.Map.empty
                    tvarPairs
                end
              else
                (EU.enqueueError
                   (loc, E.ProvideDtyArity("CP-050",{longid = path@[tycon]}));
                 raise Fail
                )
          val (nameTyPairList, conSpec) =
                foldr
                (fn ({vid, ty}, (nameTyPairList, conSpec)) =>
                    let
                      val ty =
                          Option.map 
                          (Ty.evalTy tvarEnv evalEnv)
                          ty
                          handle e => raise e                          
                      val (actualTyOpt, conSpec) = 
                          case SEnv.find(conSpec, vid) of
                            NONE =>
                            (EU.enqueueError
                               (loc,
                                E.ProvideUndefinedCon
                                  ("CP-060",{longid=path@[vid]}));
                             raise Fail
                            )
                          | SOME tyOpt => 
                            (tyOpt, #1 (SEnv.remove(conSpec, vid))
                             handle LibBase.NotFound => raise bug "SEnv.remove"
                            )
                    in
                      ((vid, ty, actualTyOpt)::nameTyPairList, conSpec)
                    end
                )
                (nil, conSpec)
                conbind
            val _ = 
                SEnv.appi
                (fn (name, _) => 
                    EU.enqueueError
                      (loc,
                       E.ProvideRedundantCon("CP-070",{longid=path@[name]}))
                )
                conSpec
            val _ = if SEnv.isEmpty conSpec then () 
                    else raise Fail
            val _ = 
                List.app
                  (fn (name, tyOpt1, tyOpt2) =>
                      case (tyOpt1, tyOpt2) of
                        (NONE, NONE) => ()
                      | (SOME ty1, SOME ty2) => 
                        if N.equalTy eqEnv (ty1, ty2) then ()
                        else 
                          (EU.enqueueError
                             (loc,
                              E.ProvideConType("CP-080",{longid=path@[name]}));
                           raise Fail)
                      | _ => 
                        (EU.enqueueError
                           (loc,
                            E.ProvideConType("CP-090",{longid = path@[name]}));
                         raise Fail)

                  )
                  nameTyPairList
        in
          V.rebindTstr (V.emptyEnv, tycon, defTstr)
        end
      end
      
  fun checkDatbindList loc path evalEnv env datbinds =
      let
        val nameTstrTfunDatbindList =
            foldr
            (fn (datbind as {tyvars, tycon, conbind, opacity},
                nameTstrTfunDatbindList) =>
                let
                  val defTstr = 
                      case V.findTstr(env, [tycon]) of
                        NONE => (EU.enqueueError
                                   (loc,
                                    E.ProvideUndefinedTypeName
                                      ("CP-100",{longid = path}));
                                 raise Fail)
                      | SOME tstr => tstr
                  val (defTfun, varE) = 
                      case defTstr of
                        V.TSTR tfun => (tfun, SEnv.empty)
(*
                        V.TSTR _ => 
                        (EU.enqueueError
                           (loc,E.ProvideDtyExpected
                                  ("CP-110",{longid=path@[tycon]}));
                         raise Fail)
*)
                      | V.TSTR_DTY {tfun, varE,...}
                        => (T.derefTfun tfun, varE)
                      | V.TSTR_TOTVAR _ =>
                        raise bug "TSTR_TOTVAR in checkProvide"
                  val originalDefTfun = 
                      case opacity of
                        A.TRANSPARENT => defTfun
                      | A.OPAQUE_NONEQ =>
                        originalTfun (opaqueTfun loc path defTfun)
                      | A.OPAQUE_EQ =>
                        if T.tfunIseq defTfun then 
                          originalTfun (opaqueTfun loc path defTfun)
                        else 
                          (EU.enqueueError
                             (loc,E.ProvideEquality
                                    ("CP-120",{longid=path@[tycon]}));
                           raise Fail)
                  val (conSpec, formals) = 
                      case T.derefTfun originalDefTfun of
                        T.TFUN_VAR(ref (T.TFUN_DTY{formals, conSpec,...})) =>
                        (conSpec, formals)
                      | _ => 
                        (EU.enqueueError
                           (loc,E.ProvideDtyExpected
                                  ("CP-130",{longid=path@[tycon]}));
                         raise Fail)

                  val defRealTstr =
                      V.TSTR_DTY{tfun=originalDefTfun,
                                 varE = varE,
                                 formals=formals,
                                 conSpec=conSpec}
                in
                  (tycon, defTstr, defRealTstr, originalDefTfun, datbind)::
                  nameTstrTfunDatbindList
                end
            )
            nil
            datbinds
        val evalEnv =
            foldl
            (fn ((name, defTstr, defRealTstr, tfun, dtbind), evalEnv) =>
                V.rebindTstr(evalEnv, name, defRealTstr))
            evalEnv
            nameTstrTfunDatbindList
      in
        foldl
          (fn (nameTstrTfunBind, returnEnv) => 
              let
                val newEnv =
                    checkDatbind loc path evalEnv env nameTstrTfunBind
              in
                V.unionEnv "CP-140" loc (returnEnv, newEnv)
              end
          )
          V.emptyEnv
          nameTstrTfunDatbindList
      end

  
      
  fun checkPidec exnSet path evalEnv (env, pidec) =
      case pidec of
        PI.PIVAL {scopedTvars, vid=name, body, loc} =>
        let
          val path = path@[name] (* for declaration and error message *)
          val (tvarEnv, scopedTvars) =
              Ty.evalScopedTvars loc Ty.emptyTvarEnv evalEnv scopedTvars
        in
          case body of
            A.VAL_EXTERN {ty} =>
            let
              val ty = Ty.evalTy tvarEnv evalEnv ty
                  handle e => raise e
              val ty = case scopedTvars of
                         nil => ty
                       | _ => T.TYPOLY(scopedTvars, ty)
val _ = U.print "checkPidec\n"
val _ = U.print "ty\n"
val _ = U.printTy ty
val _ = U.print "\n"

            in
              case V.findId(env, [name]) of
                NONE =>
                (EU.enqueueError
                   (loc, E.ProvideUndefinedID("CP-150", {longid = path}));
                 raise Fail)
              | SOME (idstatus as T.IDVAR varid) =>
                (exnSet,
                 V.rebindId(V.emptyEnv,name,idstatus),
                 [I.ICEXPORTVAR ({id=varid, path=path}, ty, loc)]
                )
              | SOME (idstatus as T.IDEXVAR {path=exVarPath, ty}) =>
                (* bug 069_open *)
                (* bug 124_open *)
                let
                  val icexp  =I.ICEXVAR ({path=exVarPath,ty=ty},loc)
                  val newId = VarID.generate()
                  val icpat = I.ICPATVAR ({path=path,id=newId},loc)
                  val valDecl = 
                      I.ICVAL(Ty.emptyScopedTvars,[(icpat,icexp)],loc)
                  val icdecls = 
                      [valDecl,
                       I.ICEXPORTVAR({id=newId,path=path},ty,loc)]
                in
                  (exnSet,
                   V.rebindId(V.emptyEnv,name,idstatus),
                   icdecls
                  )
                end
              | SOME (idstatus as T.IDBUILTINVAR {primitive, ty}) =>
                (* bug 075_builtin *)
                let
                  val icexp =I.ICBUILTINVAR{primitive=primitive,ty=ty,loc=loc}
                  val newId = VarID.generate()
                  val icpat = I.ICPATVAR ({path=path,id=newId},loc)
                  val valDecl = 
                      I.ICVAL(Ty.emptyScopedTvars,[(icpat,icexp)],loc)
                  val icdecls = 
                      [valDecl,
                       I.ICEXPORTVAR({id=newId,path=path},ty,loc)]
                in
                  (exnSet,
                   V.rebindId(V.emptyEnv,name,idstatus),
                   icdecls)
                end

              | SOME (idstatus as T.IDCON {id=conId, ty}) =>
                let
                  val icexp  =I.ICCON ({path=path,ty=ty, id=conId},loc)
                  val newId = VarID.generate()
                  val icpat = I.ICPATVAR ({path=path,id=newId},loc)
                  val valDecl = 
                      I.ICVAL(Ty.emptyScopedTvars,[(icpat,icexp)],loc)
                  val icdecls = 
                      [valDecl,
                       I.ICEXPORTVAR({id=newId,path=path},ty,loc)]
                in
                  (exnSet,
                   V.rebindId(V.emptyEnv,name,idstatus),
                   icdecls)
                end
              | SOME (idstatus as T.IDEXN {id, ty}) =>
                let
                  val icexp  =I.ICEXN ({path=path,ty=ty,id=id}, loc)
                  val newId = VarID.generate()
                  val icpat = I.ICPATVAR ({path=path,id=newId},loc)
                  val valDecl = 
                      I.ICVAL(Ty.emptyScopedTvars,[(icpat,icexp)],loc)
                in
                  (exnSet,
                   V.rebindId(V.emptyEnv,name,idstatus),
                   [valDecl])
                end
              | SOME (idstatus as T.IDEXNREP {id, ty}) =>
                let
                  val icexp  =I.ICEXN ({path=path,ty=ty,id=id}, loc)
                  val newId = VarID.generate()
                  val icpat = I.ICPATVAR ({path=path,id=newId},loc)
                  val valDecl = 
                      I.ICVAL(Ty.emptyScopedTvars,[(icpat,icexp)],loc)
                  val icdecls = 
                      [valDecl,
                       I.ICEXPORTVAR ({id=newId,path=path},ty, loc)]
                in
                  (exnSet, V.rebindId(V.emptyEnv,name,idstatus), icdecls)
                end
              | SOME (T.IDEXEXN {path, ty}) => raise bug "IDEXEXN in env"
              | SOME (T.IDOPRIM oprimId) => raise bug "IDOPRIM in env"
              | SOME (T.IDSPECVAR _) => raise bug "IDSPECVAR in provideEnv"
              | SOME (T.IDSPECEXN _ ) => raise bug "IDSPECEXN in provideEnv"
              | SOME T.IDSPECCON => raise bug "IDSPECCON in provideEnv"
            end
          | A.VAL_BUILTIN {builtinName, ty} =>
            raise bug "VAL_BUILTIN in provideSpec"
          | A.VAL_OVERLOAD overloadCase =>
            (exnSet, V.emptyEnv, nil)
        end
      | PI.PITYPE {tyvars, tycon=name, ty, opacity, loc} =>
       (*
        *       syntax                  opacity
        * type 'a foo = ty            TRANSPARENT
        * type 'a foo ( = ty )        OPAQUE_NONEQ
        * eqtype 'a foo ( = ty )      OPAQUE_EQ
        *)
        let
          val path = path@[name]
          val _ = EU.checkNameDuplication
                    (fn {name, eq} => name)
                    tyvars
                    loc
                    (fn s => E.DuplicateTypParms("CP-160",s))
          val (tvarEnv, tvarList) = Ty.genTvarList Ty.emptyTvarEnv tyvars
          val ty = Ty.evalTy tvarEnv evalEnv ty handle e => raise e
          val tfunSpec =
              case N.tyForm tvarList ty of
                N.TYNAME {tfun,...} => tfun
              | N.TYTERM ty =>
                let
                  val iseq = N.admitEq tvarList ty
                in
                  T.TFUN_DEF {iseq=iseq,
                              formals=tvarList,
                              realizerTy=ty
                             }
                end
          val tstrDef =
              case V.findTstr(env, [name]) of
                NONE =>
                (EU.enqueueError
                   (loc,
                    E.ProvideUndefinedTypeName("CP-170",{longid = path}));
                 raise Fail)
              | SOME tstr => tstr
          val tfunDef = 
              case tstrDef of
                V.TSTR tfun => T.derefTfun tfun
              | V.TSTR_DTY {tfun,...} => T.derefTfun tfun
              | V.TSTR_TOTVAR _ => raise bug "TSTR_TOTVAR in checkProvide"
          val tfunDefImpl = 
              case opacity of
                A.TRANSPARENT => tfunDef
              | _ => 
                (case tfunDef of
                   T.TFUN_VAR
                     (ref(T.TFUN_DTY{dtyKind=T.OPAQUE{tfun,...},...})) => tfun
                 | _ =>
                   (EU.enqueueError
                      (loc, E.ProvideOpaqueExpected("CP-180",{longid = path}));
                    raise Fail
                   )
                )
          val _ =
              if N.equalTfun (tfunSpec, tfunDefImpl) then 
                (case opacity of
                   A.OPAQUE_EQ => 
                   if T.tfunIseq tfunDef then ()
                   else
                     (EU.enqueueError
                        (loc, E.ProvideEquality("CP-190",{longid = path}));
                      raise Fail
                     )
                 | _ => ()
                )
              else 
                (
U.print "equalTfun check fail in PITYPE in CheckProvide\n";
U.print "tfunSpec\n";
U.printTfun tfunSpec;
U.print "\n";
U.print "tfunDefImpl\n";
U.printTfun tfunDefImpl;
U.print "\n";


                 EU.enqueueError
                   (loc, E.ProvideInequalTfun("CP-200",{longid = path}));
                 raise Fail)
        in
          (exnSet, V.rebindTstr (V.emptyEnv, name, tstrDef), nil)
        end

      | PI.PITYPEBUILTIN {tycon, builtinName, opacity, loc} =>
        raise bug "PITYPEBUILTIN in provideSpec"

      | PI.PITYPEREP {tycon, origTycon, opacity, loc} =>
        (*
         *                syntax                           opacity
         * datatype foo = datatype bar                   TRANSPARENT
         * datatype foo ( = datatype bar )               OPAQUE_NONEQ
         * datatype foo ( = datatype bar ) as eqtype     OPAQUE_EQ
         *)
         let
           val path = path @ [tycon]
           val specTstr =
               case V.findTstr(evalEnv, origTycon) of
                 NONE => (EU.enqueueError
                            (loc,
                             E.ProvideUndefinedTypeName
                               ("CP-210",{longid = path}));
                          raise Fail)
               | SOME tstr => tstr
           val specTfun =
               case specTstr of
                 V.TSTR tfun => T.derefTfun tfun
               | V.TSTR_DTY {tfun,...} => T.derefTfun tfun
               | V.TSTR_TOTVAR _ => raise bug "TSTR_TOTVAR in checkProvide"
           val orignialSpecTfun = 
               case opacity of
                 A.TRANSPARENT => specTfun
               | _ => originalTfun specTfun
           val defTstr = 
               case V.findTstr(env, [tycon]) of
                 NONE => (EU.enqueueError
                            (loc,
                             E.ProvideUndefinedTypeName
                               ("CP-220",{longid = path}));
                          raise Fail)
               | SOME tstr => tstr
           val defTfun = 
               case defTstr of
                 V.TSTR tfun => T.derefTfun tfun
               | V.TSTR_DTY {tfun,...} => T.derefTfun tfun
               | V.TSTR_TOTVAR _ => raise bug "TSTR_TOTVAR in checkProvide"
           val originalDefTfun = 
               case opacity of
                 A.TRANSPARENT => defTfun
               | A.OPAQUE_NONEQ => originalTfun (opaqueTfun loc path defTfun)
               | A.OPAQUE_EQ => 
                 if T.tfunIseq defTfun then 
                   (EU.enqueueError
                      (loc,E.ProvideEquality
                             ("CP-230",{longid=path@[tycon]}));
                    raise Fail)
                 else originalTfun (opaqueTfun loc path defTfun)
         in
           if N.equalTfun (originalDefTfun, orignialSpecTfun) then 
             let
               val returnEnv = V.rebindTstr(V.emptyEnv,tycon, defTstr)
             in
               (exnSet, returnEnv, nil)
             end
           else 
             (EU.enqueueError
                (loc,
                 E.ProvideDtyExpected ("CP-240",{longid = path}));
              raise Fail)
         end

      | PI.PIEXCEPTION {vid=name, ty=tyOpt, loc} =>
        let
          val path = path@[name]
          val tySpec =
              case tyOpt of 
                NONE => BuiltinEnv.exnTy
              | SOME ty => T.TYFUNM([Ty.evalTy Ty.emptyTvarEnv evalEnv ty],
                                    BuiltinEnv.exnTy)
                handle e => raise e
        in
          case V.findId (env, [name]) of
            NONE =>
            (EU.enqueueError
               (loc, E.ProvideUndefinedID("CP-250", {longid = path@[name]}));
             raise Fail)
          | SOME (idstatus as T.IDEXN {id,ty}) => 
            if N.equalTy TvarID.Map.empty (ty, tySpec) then
              (ExnID.Set.add(exnSet, id),
               V.rebindId(V.emptyEnv, name, idstatus),
               [I.ICEXPORTEXN ({id=id,ty=ty,path=path},loc)]
              )
            else 
              (EU.enqueueError
                 (loc, E.ProvideExceptionType("CP-260", {longid = path}));
               raise Fail)
          | SOME (T.IDEXNREP {id,ty}) => 
            (* BUG 128_functor.sml *)
            if N.equalTy TvarID.Map.empty (ty, tySpec) 
            then
              if not (ExnID.Set.member(exnSet, id)) then
                (ExnID.Set.add(exnSet, id),
                 V.rebindId(V.emptyEnv, name, T.IDEXN {id=id, ty=ty}),
                 [I.ICEXPORTEXN ({id=id,ty=ty,path=path},loc)]
                )
              else 
              (EU.enqueueError
                 (loc, E.ProvideExceptionDef("CP-260", {longid = path}));
               raise Fail)
            else 
              (EU.enqueueError
                 (loc, E.ProvideExceptionType("CP-260", {longid = path}));
               raise Fail)
(*
            (EU.enqueueError
               (loc, E.ProvideExceptionDef("CP-270", {longid = path}));
             raise Fail)
*)
          | SOME (idstatus as T.IDEXEXN {path=_,ty}) => 
            (EU.enqueueError
               (loc, E.ProvideExceptionType("CP-280", {longid = path}));
             raise Fail)
          | _ => 
            (EU.enqueueError
               (loc,
                E.ProvideUndefinedException("CP-290", {longid = path}));
             raise Fail)
        end
      | PI.PIEXCEPTIONREP {vid=name, origId=origPath, loc} =>
        (
        let
val _ = U.print "checkprovide PIEXCEPTIONREP\n"
val _ = U.print name
val _ = U.print "\n"
          val refIdstatus = 
(*
              case V.findId (env, origPath) of
*)
              case V.findId (evalEnv, origPath) of
                NONE =>
                (EU.enqueueError
                   (loc, E.ExceptionNameUndefined
                           ("CP-300",{longid = origPath}));
                 raise Fail)
              | SOME (idstatus as T.IDEXN {id,ty}) => idstatus
              | SOME (idstatus as T.IDEXNREP {id,ty}) => idstatus
              | SOME (idstatus as T.IDEXEXN {path,ty}) => idstatus
              | _ => 
                (EU.enqueueError
                   (loc, E.ExceptionExpected
                           ("CP-310",{longid = origPath}));
                 raise Fail)
          val defIdstatus =
              case V.findId (env, [name]) of
                NONE =>
                (EU.enqueueError
                   (loc, E.ProvideUndefinedID
                           ("CP-320",{longid = origPath}));
                 raise Fail)
              | SOME (T.IDEXN {id,ty}) => 
                (EU.enqueueError
                   (loc, E.ProvideExceptionRep
                           ("CP-330",{longid = origPath}));
                 raise Fail)
              | SOME (idstatus as T.IDEXNREP _) => idstatus
              | SOME (idstatus as T.IDEXEXN _) => idstatus
              | _ => 
                (EU.enqueueError
                   (loc, E.ExceptionExpected
                           ("CP-340",{longid = origPath}));
                 raise Fail)
        in
          case defIdstatus of
            T.IDEXNREP {id=id1, ...} =>
            (case refIdstatus of
               T.IDEXN {id=id2,...} =>
               if ExnID.eq(id1, id2) then 
                 (ExnID.Set.add(exnSet, id2),
                  V.rebindId(V.emptyEnv, name, defIdstatus),
                  nil)
               else
                 (EU.enqueueError
                    (loc, E.ProvideExceptionRepID("CP-350", {longid = path}));
                  raise Fail)
             | T.IDEXNREP {id=id2,...} => 
               if ExnID.eq(id1, id2) then 
                 (exnSet, V.rebindId(V.emptyEnv, name, defIdstatus),nil)
               else
                 (EU.enqueueError
                    (loc, E.ProvideExceptionRepID("CP-360", {longid = path}));
                  raise Fail)
             | _ =>
               (EU.enqueueError
                  (loc, E.ProvideExceptionRepID("CP-370", {longid = path}));
                raise Fail)
            )
          | T.IDEXEXN {path=path1, ...} =>
            (case refIdstatus of
               T.IDEXEXN {path=path2,...} =>
               if String.concat path1 = String.concat path2 then 
                 (exnSet, V.rebindId(V.emptyEnv, name, defIdstatus),nil)
               else
                 (EU.enqueueError
                    (loc, E.ProvideExceptionRepID("CP-380", {longid = path}));
                  raise Fail)
             | _ =>
               (EU.enqueueError
                  (loc, E.ProvideExceptionRepID("CP-390", {longid = path}));
                raise Fail)
            )
          | _ => raise bug "impossible"
        end
        handle Fail => (exnSet, V.emptyEnv, nil)
        )
      | PI.PIDATATYPE {datbind, loc} =>
        (exnSet,
         checkDatbindList loc path evalEnv env datbind,
         nil)
(*
        (foldl
           (fn (bind, returnEnv) => 
               let
                 val newEnv = checkDatbind loc path evalEnv env bind
               in
                 V.unionEnv "CP-400" loc (returnEnv, newEnv)
               end
           )
           V.emptyEnv
           datbind,
         nil
        )
*)
      | PI.PISTRUCTURE {strid, strexp=PI.PISTRUCT {decs,loc=strLoc}, loc} =>
        (case V.findStr(env, [strid]) of
           SOME env => 
           let
             val (exnSet, returnEnv, icdecls) =
                 checkPidecList
                   exnSet strLoc (path@[strid]) evalEnv (env, decs)
           in
             (exnSet, V.singletonStr(strid, returnEnv), icdecls)
           end
         | NONE =>
           (EU.enqueueError
              (loc, E.ProvideUndefinedStr("CP-410", {longid=path@[strid]}));
            raise Fail)
        )
          
  and checkPidecList exnSet loc path evalEnv (env, declList) =
      foldl
        (fn (decl, (exnSet, returnEnv, icdecls)) =>
            let
               val evalEnv = V.envWithEnv (evalEnv, returnEnv)
               val (exnSet, newEnv, newIcdecls) =
                   checkPidec exnSet path evalEnv (env, decl)
               val returnEnv = V.unionEnv "CP-420" loc (returnEnv, newEnv)
            in
              (exnSet, returnEnv, icdecls@newIcdecls)
            end
        )
        (exnSet, V.emptyEnv, nil)
        declList

  fun checkIdstatus (st1, st2) = 
      (* the type consistency should be checked by functor type 
         at functor definition so this is not needed.
       *)
      ()
        
  fun checkVarE (defVarE, specVarE) =
      let
        val _ =
            if length (SEnv.listItems defVarE) =
               length (SEnv.listItems specVarE)
            then ()
            else raise Fail
      in
        SEnv.appi
          (fn (name, status1) =>
              case SEnv.find(specVarE, name) of
                NONE => raise Fail
              | SOME status2 => checkIdstatus(status1, status2)
          )
          defVarE
    end

  fun checkTfunkind (tfunkind1, tfunkind2) =
      case (tfunkind1, tfunkind2) of
        (T.TFUN_DTY {id=id1,
                      iseq=iseq1,
                      formals=formals1,
                      conSpec=conSpec1,
                      liftedTys=liftedTys1,
                      dtyKind=dtyKind1
                     },
         T.TFUN_DTY {id=id2,
                      iseq=iseq2,
                      formals=formals2,
                      conSpec=conSpec2,
                      liftedTys=liftedTys2,
                      dtyKind=dtyKind2
                     }
        ) =>
        if TypID.eq(id1, id2) andalso iseq1 = iseq2 then
          FU.eqConSpec((formals1,conSpec1),(formals2,conSpec2)) 
        else raise Fail
      | (T.FUN_TOTVAR {tvar={id=id1,...},...},
         T.FUN_TOTVAR {tvar={id=id2,...},...}) =>
        if TvarID.eq(id1,id2) then () else raise Fail
      | (T.FUN_DTY _, _) => raise bug "FUN_DTY in functor provide"
      | (_, T.FUN_DTY _) => raise bug "FUN_DTY in functor provide"
      | (T.TFV_SPEC _, _) => raise bug "TFV_SPEC in functor provide"
      | (_, T.TFV_SPEC _) => raise bug "TFV_SPEC in functor provide"
      | (T.TFV_DTY _, _) => raise bug "TFV_DTY in functor provide"
      | (_, T.TFV_DTY _) => raise bug "TFV_DTY in functor provide"
      | _ => raise Fail

  fun checkTfun (tfun1, tfun2) =
      case (T.pruneTfun tfun1, T.pruneTfun tfun2) of
      (T.TFUN_DEF {iseq=iseq1, formals=formals1, realizerTy=ty1},
       T.TFUN_DEF {iseq=iseq2, formals=formals2, realizerTy=ty2}) =>
      let
        val _ = if iseq1 = iseq2 then () else raise Fail
        val tvarPairs = if length formals1 = length formals2 then 
                          ListPair.zip (formals1, formals2)
                        else raise Fail
        val eqEnv = foldl
                      (fn (({id=tv1,name=_,eq=_,lifted=_},
                            {id=tv2,name=_,eq=_,lifted=_}),
                           eqEnv) =>
                          TvarID.Map.insert(eqEnv, tv1, tv2)
                      )
                      TvarID.Map.empty
                      tvarPairs
      in
        if N.equalTy eqEnv (ty1, ty2) then ()
        else raise Fail
      end
    | (T.TFUN_VAR(ref(tfunKind1)),T.TFUN_VAR(ref(tfunKind2))) => 
      checkTfunkind (tfunKind1, tfunKind2)
    | _ => raise Fail

  fun checkTstr (tstr1, tstr2) =
      case (tstr1, tstr2) of
        (V.TSTR tfun1, V.TSTR tfun2) => checkTfun (tfun1, tfun2)
      | (V.TSTR_DTY{tfun=tfun1,...}, V.TSTR_DTY{tfun=tfun2,...})
        => checkTfun (tfun1, tfun2)
      | (V.TSTR_TOTVAR{id=id1, ...},V.TSTR_TOTVAR {id=id2,...}) => 
        if TypID.eq(id1,id2) then () else raise Fail
      | _ => raise Fail

  fun checkTyE (defTyE, specTyE) =
      let
        val _ =
            if length (SEnv.listItems defTyE) =
               length (SEnv.listItems specTyE)
            then ()
            else raise Fail
      in
        SEnv.appi
          (fn (name, tstr1) =>
              case SEnv.find(specTyE, name) of
                NONE => raise Fail
              | SOME tstr2 => checkTstr(tstr1, tstr2)
          )
          defTyE
    end

  fun visitTfun (tfun1, tfun2) =
      case (T.derefTfun tfun1, T.derefTfun tfun2) of
        (T.TFUN_VAR (ref(T.TFUN_DTY{id=id1,...})),
         T.TFUN_VAR
           (tfv as (ref(T.TFUN_DTY{id=id2,
                                   iseq,
                                   formals,
                                   conSpec,
                                   liftedTys,
                                   dtyKind})))
        ) =>
        tfv := T.TFUN_DTY{id=id1,
                          iseq=iseq,
                          formals=formals,
                          conSpec=conSpec,
                          liftedTys=liftedTys,
                          dtyKind=dtyKind
                        }
      | _ => ()

  fun visitTstr (tstr1, tstr2) =
      case (tstr1, tstr2) of
        (V.TSTR tfun1, V.TSTR tfun2) => visitTfun (tfun1, tfun2)
      | (V.TSTR_DTY {tfun=tfun1,...}, V.TSTR_DTY {tfun=tfun2,...}) =>
        visitTfun (tfun1, tfun2)
      | _ => ()

  fun visitEnv (V.ENV {varE=varE1, tyE=tyE1, strE=V.STR envMap1},
                V.ENV {varE=varE2, tyE=tyE2, strE=V.STR envMap2}
               )
      =
      let
        val tyE2rest =
            SEnv.foldli
            (fn (name, tstr1, tyE2rest) =>
                let
                  val (tyE2rest, tstr2) =
                      if SEnv.inDomain(tyE2, name) then
                        SEnv.remove(tyE2, name)
                      else raise Fail
                  val _ = visitTstr (tstr1, tstr2)
                in
                  tyE2rest
                end
            )
            tyE2
            tyE1
        val envMap2rest = 
            SEnv.foldli
            (fn (name, env1, envMap2rest) =>
                let
                  val (envMap2rest, env2) =
                      if SEnv.inDomain(envMap2rest, name) then
                        SEnv.remove(envMap2rest, name)
                      else raise Fail
                  val _ = visitEnv (env1, env2)
                in
                  envMap2rest
                end
            )
            envMap2
            envMap1
      in
        ()
      end

  fun checkFunbodyEnv
      (defEnv as V.ENV{varE=defVarE, tyE=defTyE, strE=V.STR defEnvMap},
       specEnv as V.ENV{varE=specVarE, tyE=specTyE, strE=V.STR specEnvMap})
    =
    let
      val _ = visitEnv (defEnv, specEnv)
      val _ = checkTyE (defTyE, specTyE)
      val _ = checkVarE (defVarE, specVarE)
    in
      if length (SEnv.listItems defEnvMap) =
         length (SEnv.listItems specEnvMap)
      then 
        SEnv.appi
          (fn (name, env1) =>
              case SEnv.find(specEnvMap, name) of
                NONE => raise Fail
              | SOME env2 => checkFunbodyEnv (env1, env2)
          )
          defEnvMap
      else raise Fail
    end


  fun checkPitopdec 
        exnSet
        (evalTopEnv as {Env=evalEnv, FunE=evalFunE, SigE=evalSigE})
        (topEnv as {Env, FunE, SigE}, pitopDec) =
      case pitopDec of
        PI.PIDEC pidec =>
        let
          val (exnSet, env, decls) =
              checkPidec exnSet nilPath evalEnv (Env, pidec)
        in
          (exnSet, V.topEnvWithEnv(V.emptyTopEnv, env), decls)
        end
      | PI.PIFUNDEC {funid=functorName,
                     param={strid=specArgStrName, sigexp=specArgSig},
                     strexp=specBodyStr,
                     loc}
        =>
        let
          val funEEntry
                as
                {argSig,
                 argEnv,
                 argStrName,
                 dummyIdfunArgTy,
                 polyArgTys,
                 typidSet,
                 exnIdSet,
                 bodyEnv,
                 bodyVarExp
                }
            =
            case SEnv.find(FunE, functorName) of
              NONE =>
              (EU.enqueueError
                 (loc,
                  E.ProvideUndefinedFun("CP-430",{longid=[functorName]}));
               raise Fail
              )
            | SOME entry => entry

(*
          val specArgSig = Sig.evalPlsig topEnv specArgSig
*)
val _ = U.print "getting funEEntry\n"

          val specArgSig = Sig.evalPlsig evalTopEnv specArgSig

val _ = U.print "evalated specArgSig\n"
val _ = U.print "specArgSig\n"
val _ = U.printEnv specArgSig
val _ = U.print "\n"
val _ = U.print "argSig\n"
val _ = U.printEnv argSig
val _ = U.print "\n"

          val _ = if EU.isAnyError () then raise Fail
                  else if FU.eqEnv(specArgSig, argSig) then ()
                  else 
                    (EU.enqueueError
                       (loc,
                        E.ProvideFunparamMismatch("CP-430",
                                                  {longid=[functorName]}));
                     raise Fail
                    )
val _ = U.print "eqEnv checke\n"

          val argEnv =
              V.ENV {varE=SEnv.empty,
                     tyE=SEnv.empty,
                     strE=V.STR (SEnv.singleton(specArgStrName, argEnv))
                    }
(*
   bug 102
          val evalEnv = V.topEnvWithEnv (topEnv, argEnv)
*)
          val evalEnv = V.topEnvWithEnv (evalTopEnv, argEnv)
          val (specBodyInterfaceEnv,_) =
              EI.evalPistr [functorName] evalEnv specBodyStr

val _ = U.print "evalating specBodyStr\n"


          val specBodyEnv = EI.internalizeEnv specBodyInterfaceEnv

val _ = U.print "internalized env\n"
val _ = U.print "specBodyInterfaceEnv\n"
val _ = U.printEnv specBodyInterfaceEnv
val _ = U.print "\n"
val _ = U.print "specBodyEnv\n"
val _ = U.printEnv specBodyEnv
val _ = U.print "\n"
val _ = U.print "bodyEnv\n"
val _ = U.printEnv bodyEnv
val _ = U.print "\n"

          val _ = if EU.isAnyError () then raise Fail
                  else if FU.eqEnv(specBodyEnv, bodyEnv) then ()
                  else 
                    (EU.enqueueError
                       (loc,
                        E.ProvideFunctorMismatch("CP-431",
                                                  {longid=[functorName]}));
                     raise Fail
                    )
          val {allVars=allVars,
               typidSet=typidSet,
               exnIdSet = exnIdSet
              } =
              FU.makeBodyEnv specBodyEnv loc

val _ = U.print "makeBodyEnv\n"

          fun varToTy (_, var) =
              case var of
                I.ICEXVAR ({path, ty},_) => ty
              | I.ICEXN ({path, id, ty},_) => ty
              | I.ICEXN_CONSTRUCTOR ({id, ty, path}, loc) => BV.exntagTy
              | _ =>
                (U.print "VARTOTY\n";
                 U.printExp var;
                 U.print "\n";
                raise bug "VARTOTY\n"
                )
          val bodyTy =
              case allVars of
                nil => BV.unitTy
              | _ => T.TYRECORD (Utils.listToFields (map varToTy allVars))

          val (extraTvars, firstArgTy) = 
              case dummyIdfunArgTy of
                NONE => (nil, NONE)
              | SOME (ty as T.TYRECORD fields) => 
                (map (fn (T.TYVAR tvar) => tvar
                       | _ => raise bug "non tvar in dummyIdfunArgTy")
                     (SEnv.listItems fields),
                 SOME (T.TYFUNM([ty],ty)))
              | _ => raise bug "non record ty in dummyIdfunArgTy"

          (* four possibilities in functorTy 
             1. TYPOLY(btvs, TYFUNM([first], TYFUNM(polyList, body)))
                ICFNM1([first], ICFNM1_POLY(polyPats, BODY))
             2. TYPOLY(btvs, TYFUNM([first], body))
                ICFNM1([first], BODY)
             3. TYFUNM(polyList, body)
                ICFNM1_POLY(polyPats, BODY)
             4. TYFUNM([unit], body)
                ICFNM1(UNIT, BODY)
            where body is either
              unit (TYCONSTRUCT ..) 
             or
              record (TYRECORD ..)
            BODY is ICLET(..., ICCONSTANT or ICRECORD)
           *)
          val functorTy1 =
              case polyArgTys of
                nil => bodyTy
              | _ => T.TYFUNM(polyArgTys, bodyTy)

          val functorTy2 =
              case firstArgTy of
                NONE => functorTy1
              | SOME ty => 
                T.TYPOLY
                  (map (fn x => (x, T.UNIV)) extraTvars,
                   T.TYFUNM([ty], functorTy1))

          val functorTy =
              case functorTy2 of
                T.TYPOLY _ => functorTy2
              | T.TYFUNM _ => functorTy2
              | _ => T.TYFUNM([BV.unitTy], functorTy2)

          val decls =
              case bodyVarExp of 
                I.ICVAR (varInfo, loc) => 
(*                
                [I.ICEXPORTVAR (varInfo, functorTy, loc)]
*)
                [I.ICEXPORTFUNCTOR (varInfo, functorTy, loc)]
              | I.ICEXVAR ({path, ty}, loc) => nil
              | _ => raise bug "nonvar in bodyVarExp"

          val funE =  SEnv.singleton(functorName, funEEntry)
          val returnTopEnv = V.topEnvWithFunE(V.emptyTopEnv, funE)
val _ = U.print "PIFUNDEC\n"
val _ = U.print "returnTopEnv\n"
val _ = U.printTopEnv returnTopEnv
val _ = U.print "\n"
val _ = U.print "decls\n"
val _ = map (fn decl => (U.printDecl decl; U.print "\n")) decls
val _ = U.print "\n"
        in
          (exnSet, returnTopEnv, decls)
        end

in
  fun checkPitopdecList exnSet evalTopEnv (topEnv, pitopdecList) =
      let
        val (exnSet, returnTopEnv, icdecls) =
            foldl
              (fn (pitopdec, (exnSet, returnTopEnv, icdecls)) =>
                  let
                    val loc = PI.pitopdecLoc pitopdec
                    val evalTopEnv =
                        V.topEnvWithTopEnv (evalTopEnv, returnTopEnv)
                    val (exnSet, newTopEnv, newdecls) =
                        checkPitopdec exnSet evalTopEnv (topEnv,pitopdec)
                        handle e => raise e
                    val returnTopEnv =
                        V.unionTopEnv "CP-450" loc (returnTopEnv, newTopEnv)
                  in
                    (exnSet, returnTopEnv,icdecls@newdecls)
                  end
              )
              (ExnID.Set.empty, V.emptyTopEnv, nil)
              pitopdecList
      in
        (exnSet, returnTopEnv, icdecls)
      end
      handle Fail => (ExnID.Set.empty, V.emptyTopEnv, nil)
end
end
