(**
 * @copyright (c) 2012- Tohoku University.
 * @author Atsushi Ohori
 *)
(* the initial error code of this file : Ty-001 *)
structure EvalTy =
struct
local
  structure I = IDCalc
  structure P = PatternCalc
  structure V = NameEvalEnv
  structure VP = NameEvalEnvPrims
  structure N = NormalizeTy
  structure BT = BuiltinTypes
  structure U = NameEvalUtils
  structure EU = UserErrorUtils
  structure E = NameEvalError
  structure A = AbsynTy
  structure L = SetLiftedTys
  (* structure PI = PatternCalcInterface *)
  structure R = RuntimeTypes
  fun bug s = Bug.Bug ("NameEval(EvalTy): " ^ s)
  type freeTvarEnv = I.tvarId SymbolEnv.map
  val freeTvarEnv = ref SymbolEnv.empty : freeTvarEnv ref
  fun findFreeTvarId symbol = 
      case SymbolEnv.find(!freeTvarEnv, symbol) of
        NONE => 
        let
          val id = TvarID.generate()
        in
          (freeTvarEnv := SymbolEnv.insert(!freeTvarEnv, symbol, id);
           id)
        end
      | SOME id => id
in
  fun resetFreeTvarEnv () = freeTvarEnv := SymbolEnv.empty
  type tvarEnv = I.tvar SymbolEnv.map
  val emptyTvarEnv = SymbolEnv.empty : tvarEnv

  fun genTvar (tvarEnv:tvarEnv) {symbol, isEq} : tvarEnv * I.tvar =
      let
        val id = TvarID.generate()
        val tvar = {symbol=symbol, isEq=isEq, id=id, lifted=false}
      in
        (SymbolEnv.insert(tvarEnv, symbol, tvar), tvar)
      end

  fun genTvarList (tvarEnv:tvarEnv) tvarList : tvarEnv * I.tvar list =
      U.evalTailList {env=tvarEnv, eval=genTvar} tvarList

  fun checkCyclicKind tvarKindList =
      let
        val kindEnv =
            foldl 
            (fn ((tvar, kind), tvarMap) => TvarMap.insert(tvarMap, tvar, kind))
            TvarMap.empty
            tvarKindList
        fun EFTVkind (kind, tvarSet) =
            case kind of
              I.UNIV prop => tvarSet
            | I.REC {properties, recordKind=fields} =>
              RecordLabel.Map.foldl
              (fn (ty, tvarSet) => EFTVty (ty, tvarSet))
              tvarSet
              fields
        and EFTVty (ty, tvarSet) =
            case ty of
              I.TYWILD => tvarSet
            | I.TYERROR => tvarSet
            | I.TYFREE_TYVAR freeTvar =>  tvarSet 
            | I.TYVAR tvar => 
              if TvarSet.member(tvarSet, tvar) then tvarSet
              else 
                (case TvarMap.find(kindEnv, tvar) of
                   NONE => TvarSet.add(tvarSet, tvar)
                 | SOME kind => 
                   EFTVkind(kind, TvarSet.add(tvarSet, tvar))
                )
            | I.TYRECORD {ifFlex,fields} =>
              RecordLabel.Map.foldl
              (fn (ty, tvarSet) => EFTVty (ty, tvarSet))
              tvarSet
              fields
            | I.TYCONSTRUCT {tfun, args} =>
              foldl
              (fn (ty, tvarSet) => EFTVty (ty, tvarSet))
              tvarSet
              args
            | I.TYFUNM (tyList, ty) =>
              foldl
              (fn (ty, tvarSet) => EFTVty (ty, tvarSet))
              (EFTVty (ty, tvarSet))
              tyList
            | I.TYPOLY (kindedTvarList,ty) =>
              let
                val boundTvars =
                    foldl
                    (fn ((tvar, kind), boundTvars) =>
                        TvarSet.add(boundTvars, tvar))
                    TvarSet.empty
                    kindedTvarList
              in
                TvarSet.difference(EFTVty (ty,tvarSet), boundTvars)
              end
            | I.INFERREDTY typesTy => tvarSet
        fun checkTvarKind ((tvar, kind), cycleList) = 
            let
              val eftv = 
                  case TvarMap.find(kindEnv, tvar) of
                    NONE => TvarSet.empty
                  | SOME kind => EFTVkind(kind, TvarSet.empty)
            in
              if TvarSet.member(eftv, tvar) then tvar::cycleList
              else cycleList
            end
      in
        foldr checkTvarKind nil tvarKindList
      end


  (* type variable evaluators *)
  fun evalTvar (tvarEnv:tvarEnv) {symbol, isEq} : I.tvar =
      case SymbolEnv.find(tvarEnv, symbol) of
        SOME tvar => tvar
      | NONE =>
        (EU.enqueueError
           (Symbol.symbolToLoc symbol, E.TvarNotFound("Ty-010",{symbol = symbol}));
         {symbol=symbol, isEq=isEq, id=TvarID.generate(), lifted=false})

  (* type evaluators, which return a type etc and liftedtys *)
  fun evalTyAux allowFlex (tvarEnv:tvarEnv) (env:V.env) (ty:A.ty) : I.ty  =
    case ty of
      A.TYWILD loc => I.TYWILD
    | A.TYID (tvar, loc) => I.TYVAR (evalTvar tvarEnv tvar)
    | A.FREE_TYID {freeTvar = {symbol, isEq}, tvarKind, loc} => 
      let
        val id = findFreeTvarId symbol
        val tvarKind = evalTvarKindAux allowFlex tvarEnv env tvarKind
      in
        I.TYFREE_TYVAR {symbol=symbol, isEq=isEq, id=id, tvarKind=tvarKind}
      end
    | A.TYRECORD {ifFlex, fields=tyFields, loc} =>
      (EU.checkRecordLabelDuplication
         #1 tyFields loc 
         (fn s => E.DuplicateRecordLabelInRawType("Ty-020",s));
       if not allowFlex andalso ifFlex then
         EU.enqueueError
           (loc, E.FlexRecordNotAllowed("Ty-025",ty))
       else ();
       I.TYRECORD
         {ifFlex = ifFlex,
          fields = 
          foldl
            (fn ((l,ty), fields) =>
                RecordLabel.Map.insert(fields, l, evalTyAux allowFlex tvarEnv env ty))
            RecordLabel.Map.empty
            tyFields
         }
      )
    | A.TYCONSTRUCT (tyList, path, loc) =>
      let
        exception Arity
      in
        let
          fun makeTy tfun =
              let
                val tyList = map (evalTyAux allowFlex tvarEnv env) tyList
                val _ = if length tyList = I.tfunArity tfun then ()
                        else raise Arity
              in
                case I.pruneTfun tfun of 
                  I.TFUN_DEF {longsymbol, admitsEq,formals,realizerTy} =>
                  let
                    val reduceEnv =
                        foldr
                          (fn ((tvar, ty), tvarEnv) =>
                              TvarMap.insert(tvarEnv, tvar, ty))
                          TvarMap.empty
                          (ListPair.zip(formals, tyList))
                    val newTy = N.reduceTy reduceEnv realizerTy
                  in
                    newTy
                  end
                | I.TFUN_VAR _ =>
                  I.TYCONSTRUCT {tfun=tfun, args=tyList}
              end
        in
          case VP.lookupTstr env path handle e => raise e
           of
            V.TSTR tfun => makeTy tfun
          | V.TSTR_DTY {tfun, varE, formals, conSpec} => makeTy tfun
        end
        handle Arity =>
               (EU.enqueueError (loc, E.TypArity("Ty-030",{longsymbol =  path}));
                I.TYERROR
               )
             | VP.LookupTstr =>
               (EU.enqueueError (loc, E.TypNotFound("Ty-040",{longsymbol = path}));
                I.TYERROR
               )

      end
    | A.TYTUPLE(nil, loc) => BT.unitITy
    | A.TYTUPLE(tyList, loc) =>
      evalTyAux allowFlex tvarEnv env 
             (A.TYRECORD {ifFlex=false, fields = RecordLabel.tupleList tyList, loc=loc})
    | A.TYFUN(ty1,ty2, loc) =>
      I.TYFUNM([evalTyAux allowFlex tvarEnv env ty1], evalTyAux allowFlex tvarEnv env ty2)
    | A.TYPOLY (kindedTvarList, ty, loc) =>
      let
        val (tvarEnv, kindedTvarList) =
            evalKindedTvarList allowFlex tvarEnv env kindedTvarList
(*
        val cyclicTvars = checkCyclicKind kindedTvarList 
        fun tvarLoc {symbol, id, eq, lifted} = Symbol.symbolToLoc symbol
        val kindedTvarList =
            case cyclicTvars of
              nil => kindedTvarList
            | tvar1 :: rest => 
              let
                val tvarsLoc =
                    foldl
                    (fn (loc1, loc) => Loc.mergeLoc (loc1, loc))
                    (tvarLoc tvar1)
                    (map tvarLoc rest)
              in
                (EU.enqueueError
                 (tvarsLoc, 
                  E.CyclicKind("Ty-045", {tvarList = cyclicTvars}));
                 map (fn (tvar, kind) => (tvar, I.UNIV)) kindedTvarList)
*)
        val ty = evalTyAux allowFlex tvarEnv env ty
      in
        I.TYPOLY (kindedTvarList,ty)
      end
  and evalTvarKindAux allowFlex (tvarEnv:tvarEnv) (env:V.env) kind : I.tvarKind  =
      let
        fun transProperties props loc =
            foldr
            (fn  (prop, kindList) =>
                 case prop of
                   "reify" => Types.addProperties I.REIFY kindList
                 | "boxed" => Types.addProperties I.BOXED kindList
                 | "unboxed" => Types.addProperties I.UNBOXED kindList
                 | "eq" => Types.addProperties I.EQ kindList
                 | name =>
                   (EU.enqueueError (loc, E.InvalidKindName("Ty-060", name)); 
                    kindList)
            )
            I.emptyProperties
            props
      in
        case kind of
          A.UNIV (props, loc) =>
          let
            val props = transProperties props loc
          in
            (* check kind consistency *)
            case DynamicKindUtils.kindOfStaticKind
                   (Types.KIND {properties = props,
                                tvarKind = Types.UNIV,
                                dynamicKind = NONE}) of
              SOME _ => ()
            | NONE => EU.enqueueError (loc, E.InvalidKind("Ty-061", kind));
            I.UNIV props
          end
        | A.REC ({properties, recordKind}, loc) =>
          let
            val props = transProperties properties loc
            val newRecordKind =
                foldl
                  (fn ((l,ty), fields) =>
                      RecordLabel.Map.insert
                        (fields, l, evalTyAux allowFlex tvarEnv env ty)
                  )
                  RecordLabel.Map.empty
                  recordKind
          in
            EU.checkRecordLabelDuplication
              #1 recordKind loc
              (fn s => E.DuplicateRecordLabelInKind("Ty-050",s));
            (* check kind consistency *)
            case DynamicKindUtils.kindOfStaticKind
                   (Types.KIND {properties = props,
                                tvarKind = Types.REC RecordLabel.Map.empty,
                                dynamicKind = NONE}) of
              SOME _ => ()
            | NONE => EU.enqueueError (loc, E.InvalidKind("Ty-061", kind));
            I.REC {properties = props, recordKind = newRecordKind}
          end
      end
  and evalKindedTvarList allowFlex (tvarEnv:tvarEnv) (env:V.env) tvarKindList
      : tvarEnv * I.kindedTvar list =
      let
        fun evalTvar tvarEnv (tvar, kind)  =
            let
              val (tvarEnv, tvar) = genTvar tvarEnv tvar
            in
              (tvarEnv, (tvar, kind))
            end
        val (tvarEnv, tvarKindList) =
            U.evalTailList {env=tvarEnv,eval=evalTvar} tvarKindList
        val tvarKindList =
            map (fn (tvar, kind) => (tvar, evalTvarKindAux allowFlex tvarEnv env kind))
                tvarKindList
        val cyclicTvars = checkCyclicKind tvarKindList
        fun tvarLoc {symbol, id, isEq, lifted} = Symbol.symbolToLoc symbol
        val tvarKindList =
            case cyclicTvars of
              nil => tvarKindList
            | tvar1 :: rest => 
              let
                val tvarsLoc =
                    foldl
                    (fn (loc1, loc) => Loc.mergeLocs (loc1, loc))
                    (tvarLoc tvar1)
                    (map tvarLoc rest)
              in
                (EU.enqueueError
                 (tvarsLoc, 
                  E.CyclicKind("Ty-070", {tvarList = cyclicTvars}));
                 map (fn (tvar, kind) => (tvar, I.UNIV I.emptyProperties)) tvarKindList)
              end
(*
        val tvarKindList =
            case cyclicTvars of
              nil => tvarKindList
            | _ => 
              (EU.enqueueError
                 (loc, 
                  E.CyclicKind("Ty-045", {stringList = cyclicTvars}));
               map (fn (tvar, kind) => (tvar, I.UNIV)) tvarKindList)
*)
      in
        (tvarEnv, tvarKindList)
      end

  val evalTy = fn tvarEnv => fn env => fn ty => evalTyAux false tvarEnv env ty
  val evalTyWithFlex = fn tvarEnv => fn env => fn ty => evalTyAux true tvarEnv env ty

  fun compatProperty {abs, impl} =
      case (abs, impl) of
        (I.LIFTED {id=id1,...}, I.LIFTED {id=id2,...}) => TvarID.eq (id1,id2)
      | (I.PROP prop1, I.PROP prop2) => R.canBeRegardedAs (prop2, prop1)
      | _ => false

  fun getProperty _ _ A.IMPL_TUPLE _ = I.PROP R.recordProp
    | getProperty _ _ A.IMPL_RECORD _ = I.PROP R.recordProp
    | getProperty _ _ A.IMPL_FUNC _ = I.PROP R.recordProp
    | getProperty tvarEnv evalEnv (A.IMPL_TY runtimeTyLongsymbol) loc =
      let
        val loc = Symbol.longsymbolToLoc runtimeTyLongsymbol
        val tstr =
            SOME (VP.lookupTstr evalEnv runtimeTyLongsymbol)
            handle VP.LookupTstr =>
                   (EU.enqueueError
                      (loc, E.TypNotFound("Ty-090", {longsymbol = runtimeTyLongsymbol}));
                    NONE)
        val prop =
            case tstr of
              SOME (V.TSTR tfun) => I.tfunProperty tfun
            | SOME (V.TSTR_DTY {tfun, ...}) => I.tfunProperty tfun
            | NONE => NONE
      in
        case prop of
          SOME prop => prop
        | NONE =>
          (EU.enqueueError
             (loc, E.IllegalBuiltinTy
                     ("Ty-090", {symbol = runtimeTyLongsymbol}));
           I.PROP R.recordProp)  (*dummy*)
      end

  fun ffiTyToAbsynTy ffiTy =
      case ffiTy of
        P.FFIFUNTY (attributes, [argTy], NONE, [retTy], loc) =>
        A.TYFUN (ffiTyToAbsynTy argTy, ffiTyToAbsynTy retTy, loc)
      | P.FFIFUNTY (attributes, argTys, varargTys, retTys, loc) =>
        (EU.enqueueError (loc, E.FFIFunTyIsNotAllowedHere("Ty-080", ffiTy));
         A.TYTUPLE (nil, loc))  (* dummy *)
      | P.FFITYVAR (tvar, loc) =>
        A.TYID (tvar, loc)
      | P.FFIRECORDTY (fields, loc) =>
        A.TYRECORD {ifFlex=false,
                    fields = map (fn (label, ty) => (label, ffiTyToAbsynTy ty)) fields,
                    loc=loc}
      | P.FFICONTY (argTyList, longsymbol, loc) =>
        A.TYCONSTRUCT (map ffiTyToAbsynTy argTyList, longsymbol, loc)

  fun tyToFfiTy tvarEnv env subst (ty, loc) =
      let
        fun toTy ty =
            N.reduceTy
              (TvarMap.map (evalTy tvarEnv env o ffiTyToAbsynTy) subst)
              ty
      in
        case ty of
          I.TYWILD => I.FFIBASETY (toTy ty, loc)
        | I.TYERROR => I.FFIBASETY (toTy ty, loc)
        | I.TYCONSTRUCT _ => I.FFIBASETY (toTy ty, loc)
        | I.TYFUNM _ => I.FFIBASETY (toTy ty, loc)
        | I.TYPOLY _ => I.FFIBASETY (toTy ty, loc)
        | I.INFERREDTY _ => I.FFIBASETY (toTy ty, loc) (* FIXME *)
        | I.TYFREE_TYVAR tvar => raise bug "TYFREE_TYVAR to tyToFfiTy"
        | I.TYVAR tvar =>
          (case TvarMap.find (subst, tvar) of
             NONE => I.FFIBASETY (toTy ty, loc)
           | SOME ffity => evalFfity tvarEnv env ffity)
        | I.TYRECORD {ifFlex,fields} =>
          let
            val fields = RecordLabel.Map.listItemsi fields
          in
            if RecordLabel.isOrderedList fields
            then I.FFIRECORDTY
                   (map (fn (label, ty) =>
                            (label, tyToFfiTy tvarEnv env subst (ty, loc)))
                        fields, loc)
            else I.FFIBASETY (toTy ty, loc)
          end
      end

  and evalFfity (tvarEnv:tvarEnv) (env:V.env) ffiTy =
      let
        val evalFfity = evalFfity tvarEnv env
      in
        case ffiTy of
          P.FFIFUNTY (ffiAttributesOption, argTys, varTys, retTys, loc) =>
          I.FFIFUNTY (ffiAttributesOption,
                      map evalFfity argTys,
                      Option.map (map evalFfity) varTys,
                      map evalFfity retTys,
                      loc)
        | P.FFITYVAR (tvar, loc) =>
          I.FFIBASETY (evalTy tvarEnv env (ffiTyToAbsynTy ffiTy), loc)
        | P.FFIRECORDTY (stringFfityList, loc) =>
          I.FFIRECORDTY
            (map (fn (l, ty) => (l, evalFfity ty)) stringFfityList,
             loc)
        | P.FFICONTY (argTyList, typath, loc) =>
          let
            val tfun =
                case VP.lookupTstr env typath of
                  V.TSTR tfun => tfun
                | V.TSTR_DTY {tfun, varE, formals, conSpec} => tfun
          in
            case I.pruneTfun tfun of
               I.TFUN_DEF {longsymbol, admitsEq, formals, realizerTy} =>
               let
                 val subst =
                     List.foldl
                       (fn ((key, item), m) => TvarMap.insert (m, key, item))
                       TvarMap.empty
                       (ListPair.zipEq (formals, argTyList))
               in
                 tyToFfiTy tvarEnv env subst (realizerTy, loc)
               end
            | _ => I.FFIBASETY (evalTy tvarEnv env (ffiTyToAbsynTy ffiTy), loc)
          end
          handle VP.LookupTstr =>
                 (EU.enqueueError
                    (loc, E.TypNotFound("Ty-100",{longsymbol = typath}));
                  I.FFIBASETY (I.TYERROR, loc))
               | UnqeualLengths =>
                 (EU.enqueueError
                    (loc, E.TypArity("Ty-110",{longsymbol = typath}));
                  I.FFIBASETY (I.TYERROR, loc))
      end

  val emptyScopedTvars = nil : I.scopedTvars
  fun evalScopedTvars (tvarEnv:tvarEnv) (env:V.env) (tvars:P.scopedTvars) =
      evalKindedTvarList false tvarEnv env tvars
 
  fun evalDatatype 
        (path:Symbol.symbol list) 
        (env:V.env) 
        (datbindList:PatternCalc.datbind list, loc:Loc.loc) 
       : NameEvalEnv.env * IDCalc.icdecl list
       =
      let
        val _ = EU.checkSymbolDuplication
                  (fn {tyvars, symbol, conbind} => symbol)
                  datbindList
                  (fn s => E.DuplicateTypInDty("Ty-120",s))
        val _ = EU.checkSymbolDuplication
                  (fn {symbol, ty=tyOption} => symbol)
                  (foldl
                     (fn ({tyvars, symbol, conbind}, allCons) =>
                         allCons@conbind)
                     nil
                     datbindList)
                  (fn s => E.DuplicateConNameInDty("Ty-130",s))
        val (newEnv, datbindListRev) =
            foldl
              (fn ({tyvars=tvarList,symbol,conbind},
                   (newEnv, datbindListRev)) =>
                  let
                    val _ = EU.checkSymbolDuplication
                              (fn {symbol, isEq} => symbol)
                              tvarList
                              (fn s => E.DuplicateTypParms("Ty-140",s))
                    val (tvarEnv, tvarList)=
                        genTvarList emptyTvarEnv tvarList
                    val id = TypID.generate()
                    val admitsEqRef = ref true
(*
                    val longsymbol = Symbol.prefixPath (path , symbol)
*)
                    val longsymbol = [symbol]
                    val tfv =
                        I.mkTfv(I.TFV_SPEC{longsymbol= longsymbol, id=id,admitsEq=true,formals=tvarList})
                    val tfun = I.TFUN_VAR tfv
                    val newEnv =VP.insertTstr(newEnv, symbol, V.TSTR tfun)
                    val datbindListRev =
                        {name= symbol,
                         id=id,
                         tfv=tfv,
                         tfun=tfun,
                         admitsEqRef=admitsEqRef,
                         args=tvarList,
                         tvarEnv=tvarEnv,
                         conbind=conbind}
                        :: datbindListRev
                  in
                    (newEnv, datbindListRev)
                  end
              )
              (V.emptyEnv, nil)
              datbindList
        val evalEnv = VP.envWithEnv (env, newEnv)
        val datbindList =
            foldl
              (fn ({name, id, tfv, tfun, admitsEqRef, args, tvarEnv, conbind},
                   datbindList) =>
                  let
                    val returnTy =
                        I.TYCONSTRUCT
                          {tfun=tfun,
                           args= map (fn tv=>I.TYVAR tv) args
                          }
                    val (conVarE, conSpec, conIDSet) =
                        foldl
                          (fn ({symbol,ty=tyOption},
                               (conVarE,conSpec, conIDSet)) =>
                              let
(*
                                val longsymbol = Symbol.prefixPath(path, symbol)
*)
                                val longsymbol = [symbol]
                                val conId = ConID.generate()
                                val conIDSet = ConID.Set.add (conIDSet, conId)
                                val (tyOption, conTy) =
                                    case tyOption of
                                      NONE => 
                                      (NONE, 
                                       case args of
                                         nil => returnTy
                                       | _ => I.TYPOLY
                                              (
                                               map (fn tv =>(tv, I.UNIV I.emptyProperties)) args,
                                               returnTy
                                              )
                                      )
                                    | SOME ty =>
                                      let
                                        val ty = evalTy tvarEnv evalEnv ty
                                      in
                                        (SOME ty,
                                         case args of
                                           nil => I.TYFUNM([ty], returnTy)
                                         | _ => 
                                           I.TYPOLY
                                             (
                                              map (fn tv =>(tv, I.UNIV I.emptyProperties)) args,
                                              I.TYFUNM([ty], returnTy)
                                             )
                                        )
                                      end
                                val conInfo = {id=conId, longsymbol=longsymbol, ty=conTy}
(*
                                val _ = V.conEnvAdd (conId, conInfo)
*)
                                val idstatus = I.IDCON conInfo
                              in
                                (SymbolEnv.insert(conVarE, symbol, idstatus),
                                 SymbolEnv.insert(conSpec, symbol, tyOption),
                                 conIDSet
                                )
                              end
                          )
                          (SymbolEnv.empty,SymbolEnv.empty,ConID.Set.empty)
                          conbind
                  in
                    {name=name,
                     id=id,
                     tfv=tfv,
                     conVarE=conVarE,
                     conSpec=conSpec,
                     conIDSet=conIDSet,
                     admitsEqRef=admitsEqRef,
                     args=args}
                    :: datbindList
                  end)
              nil
              datbindListRev
        val _ = N.setEq 
                  (map 
                     (fn {id, args, conSpec, admitsEqRef,...} =>
                         {id=id, args=args, conSpec=conSpec, admitsEqRef=admitsEqRef})
                     datbindList
                  )
        val newEnv =
            foldr
              (fn ({name,id,tfv,conVarE,conSpec,conIDSet,admitsEqRef,args},
                   newEnv) =>
                  let
                    val property = DatatypeLayout.datatypeLayout conSpec
                    val tfunkind =
                        I.TFUN_DTY
                          {id=id,
                           admitsEq = !admitsEqRef,
                           conSpec=conSpec,
                           conIDSet=conIDSet,
(*
                           longsymbol= Symbol.prefixPath (path , name),
*)
                           longsymbol= [name],
                           formals=args,
                           liftedTys=I.emptyLiftedTys,
                           dtyKind=I.DTY property
                          }
(*
                        I.TFV_DTY
                          {id=id,
                           iseq = !iseqRef,
                           conSpec=conSpec,
                           formals=args,
                           liftedTys=I.emptyLiftedTys
                          }
*)
                    val _ = tfv := tfunkind
                    val newEnv = 
                        VP.rebindTstr(newEnv,
                                     name,
                                     V.TSTR_DTY {tfun=I.TFUN_VAR tfv,
                                                 varE=conVarE,
                                                 formals=args,
                                                 conSpec=conSpec
                                                }
                                    )
                    val newEnv = VP.bindEnvWithVarE(newEnv, conVarE)
                  in
                    newEnv
                  end
              )
              V.emptyEnv
              datbindList
        val pathTfvListList = L.setLiftedTysEnv newEnv
      in
        (newEnv, nil)
      end
end
end
