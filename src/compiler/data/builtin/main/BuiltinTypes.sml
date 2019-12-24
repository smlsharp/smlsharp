(*  built-in types. *)
structure BuiltinTypes =
struct
  structure I = IDCalc
  structure T = Types
  structure Ity = EvalIty
  structure R = RuntimeTypes
  fun bug s = Bug.Bug ("BuiltinTypes: " ^ s)

  fun mkLongsymbol path = Symbol.mkLongsymbol path Loc.noloc
  fun mkSymbol name = Symbol.mkSymbol name Loc.noloc

  type tstrInfo =
      {tfun : I.tfun,
       varE : I.varE,
       formals : I.formals,
       conSpec : I.conSpec}

  datatype ty =
      TVAR of string
    | SELF of ty list
    | CON of tstrInfo * ty list
    | TUPLE of ty list
    | RECORD of (RecordLabel.label * ty) list
    | FUN of ty * ty

  datatype dtyKind =
      BUILTIN of RuntimeTypes.property
    | DTY of (string * ty option) list
    | BOOL of string * string
    | REF of string * ty option

  fun evalTy (env as (tvarMap, self)) ty =
      case ty of
        TVAR s => (case SymbolEnv.find (tvarMap, mkSymbol s) of
                     SOME tv => I.TYVAR tv
                   | NONE =>
                     (print "bug tvar not found\n";
                     raise bug "tvar not found")
                  )
      | RECORD fields =>
        I.TYRECORD
          {ifFlex = false,
           fields =
           foldl
             (fn ((label, ty), fields) =>
                 RecordLabel.Map.insert(fields, label, evalTy env ty))
             RecordLabel.Map.empty
             fields
          }
      | TUPLE tys =>
        evalTy env (RECORD (RecordLabel.tupleList tys))
      | CON ({tfun,...}, args) =>
        I.TYCONSTRUCT {tfun = tfun, args = map (evalTy env) args}
      | SELF args =>
        I.TYCONSTRUCT {tfun = self, args = map (evalTy env) args}
      | FUN(bty1, bty2) =>
        I.TYFUNM([evalTy env bty1], evalTy env bty2)

  val tstrinfoMap = ref SymbolEnv.empty

  fun makeTfun typIdOpt {printName, admitsEq, formals, dtyKind} =
      let
        val symbol = mkSymbol printName
        val formalTvars =
            map (fn tvarName =>
                    {symbol = mkSymbol tvarName,
                     isEq = false,
                     id = TvarID.generate (),
                     lifted = false})
                formals
        val tvarEnv =
            ListPair.foldlEq
              (fn (name, tvar, tvarEnv) =>
                  SymbolEnv.insert (tvarEnv, mkSymbol name, tvar))
              SymbolEnv.empty
              (formals, formalTvars)
        val tfvSpec =
            {longsymbol = [symbol],
             id = case typIdOpt of NONE => TypID.generate () | SOME id => id,
             admitsEq = admitsEq,
             formals = formalTvars}
        val tfv = I.mkTfv (I.TFV_SPEC tfvSpec)
        val tfun = I.TFUN_VAR tfv
        val boundtvars = map (fn tv => (tv, I.UNIV T.emptyProperties)) formalTvars
        val conList =
            case dtyKind of
              BUILTIN _ => nil
            | DTY l => l
            | BOOL (t, f) => [(t, NONE), (f, NONE)]
            | REF x => [x]
        val conList =
            map (fn (name, tyOpt) =>
                    {name = mkSymbol name,
                     id = ConID.generate (),
                     ty = Option.map (evalTy (tvarEnv, tfun)) tyOpt})
                conList
        val conSpec =
            foldl (fn ({name, ty, ...}, z) => SymbolEnv.insert (z, name, ty))
                  SymbolEnv.empty
                  conList
        val conIDSet =
            foldl (fn ({id, ...}, z) => ConID.Set.add (z, id))
                  ConID.Set.empty
                  conList
        val property =
            case dtyKind of
              BUILTIN prop => prop
            | DTY _ => DatatypeLayout.datatypeLayout conSpec
            | REF _ => R.recordProp # {rep = R.DATA R.LAYOUT_REF}
            | BOOL (f, t) =>
              RuntimeTypes.contagProp
              # {rep = R.DATA (R.LAYOUT_CHOICE {falseName = f})}
        val dty =
            {id = #id tfvSpec,
             admitsEq = #admitsEq tfvSpec,
             longsymbol = #longsymbol tfvSpec,
             formals = #formals tfvSpec,
             conSpec = conSpec,
             conIDSet = conIDSet,
             liftedTys = I.emptyLiftedTys,
             dtyKind = I.DTY property}
        val _ = tfv := I.TFUN_DTY dty
        val returnTy = I.TYCONSTRUCT {tfun=tfun, args = map I.TYVAR formalTvars}
        val conInfoList =
            map (fn {name, id, ty} =>
                  let
                    val conMonoTy =
                        case ty of
                          NONE => returnTy
                        | SOME ty => I.TYFUNM ([ty], returnTy)
                    val conTy =
                          case boundtvars of
                            nil => conMonoTy
                          | _::_ => I.TYPOLY (boundtvars, conMonoTy)
                    val conInfo : I.conInfo =
                        {id = id, ty = conTy, longsymbol = [name]}
                    in
                      (name, conInfo)
                    end)
                conList
        val varE =
            foldl (fn ((k,v),z) => SymbolEnv.insert (z, k, I.IDCON v))
                  SymbolEnv.empty
                  conInfoList
        val tyCon =
            Ity.evalTfun Ity.emptyContext tfun
            handle e => (print "bug: evalTfun failed 2\n"; raise e)
        val ity =
            case formalTvars of
              nil => I.TYCONSTRUCT {tfun=tfun, args=nil}
            | _::_ => I.TYERROR
        val ty = Ity.evalIty Ity.emptyContext ity
        val conList =
            map (fn (_, conInfo as {id, ty, longsymbol}) =>
                    (conInfo, {id = id,
                               ty = Ity.evalIty Ity.emptyContext ty,
                               path = longsymbol}))
                conInfoList
        val tstrInfo =
            {tfun=tfun, varE=varE, formals=formalTvars, conSpec=conSpec}
      in
        tstrinfoMap := SymbolEnv.insert (!tstrinfoMap, symbol, tstrInfo);
        (tstrInfo, tyCon, ity, ty, conList)
      end

  val (int32TstrInfo, int32TyCon, int32ITy, int32Ty, _) =
      makeTfun NONE
        {printName = "int32",
         admitsEq = true,
         formals = nil,
         dtyKind = BUILTIN R.int32Prop}

  val (int8TstrInfo, int8TyCon, int8ITy, int8Ty, _) =
      makeTfun NONE
        {printName = "int8",
         admitsEq = true,
         formals = nil,
         dtyKind = BUILTIN R.int8Prop}

  val (int16TstrInfo, int16TyCon, int16ITy, int16Ty, _) =
      makeTfun NONE
        {printName = "int16",
         admitsEq = true,
         formals = nil,
         dtyKind = BUILTIN R.int16Prop}

  val (int64TstrInfo, int64TyCon, int64ITy, int64Ty, _) =
      makeTfun NONE
        {printName = "int64",
         admitsEq = true,
         formals = nil,
         dtyKind = BUILTIN R.int64Prop}

  val (intInfTstrInfo, intInfTyCon, intInfITy, intInfTy, _) =
      makeTfun NONE
        {printName = "intInf",
         admitsEq = true,
         formals = nil,
         dtyKind = BUILTIN R.recordProp}

  val (word32TstrInfo, word32TyCon, word32ITy, word32Ty, _) =
      makeTfun NONE
        {printName = "word32",
         admitsEq = true,
         formals = nil,
         dtyKind = BUILTIN R.word32Prop}

  val (word8TstrInfo, word8TyCon, word8ITy, word8Ty, _) =
      makeTfun NONE
        {printName = "word8",
         admitsEq = true,
         formals = nil,
         dtyKind = BUILTIN R.word8Prop}

  val (word16TstrInfo, word16TyCon, word16ITy, word16Ty, _) =
      makeTfun NONE
        {printName = "word16",
         admitsEq = true,
         formals = nil,
         dtyKind = BUILTIN R.word16Prop}

  val (word64TstrInfo, word64TyCon, word64ITy, word64Ty, _) =
      makeTfun NONE
        {printName = "word64",
         admitsEq = true,
         formals = nil,
         dtyKind = BUILTIN R.word64Prop}

  val (charTstrInfo, charTyCon, charITy, charTy, _) =
      makeTfun NONE
        {printName = "char",
         admitsEq = true,
         formals = nil,
         dtyKind = BUILTIN R.word8Prop}

  val (stringTstrInfo, stringTyCon, stringITy, stringTy, _) =
      makeTfun NONE
        {printName = "string",
         admitsEq = true,
         formals = nil,
         dtyKind = BUILTIN R.recordProp}

  val (real64TstrInfo, real64TyCon, real64ITy, real64Ty, _) =
      makeTfun NONE
        {printName = "real64",
         admitsEq = false,
         formals = nil,
         dtyKind = BUILTIN R.real64Prop}

  val (real32TstrInfo, real32TyCon, real32ITy, real32Ty, _) =
      makeTfun NONE
        {printName = "real32",
         admitsEq = false,
         formals = nil,
         dtyKind = BUILTIN R.real32Prop}

  val (unitTstrInfo, unitTyCon, unitITy, unitTy, _) =
      makeTfun NONE
        {printName = "unit",
         admitsEq = true,
         formals = nil,
         dtyKind = BUILTIN R.unitProp}

  val (ptrTstrInfo, ptrTyCon, _, _, _) =
      makeTfun NONE
        {printName = "ptr",
         admitsEq = true,
         formals = ["a"],
         dtyKind = BUILTIN R.ptrProp}

  val unitPtr = CON (ptrTstrInfo, [CON (unitTstrInfo, nil)])

  val (codeptrTstrInfo, codeptrTyCon, codeptrITy, codeptrTy, _) =
      makeTfun NONE
        {printName = "codeptr",
         admitsEq = true,
         formals = nil,
         dtyKind = BUILTIN R.codeptrProp}

  val (arrayTstrInfo, arrayTyCon, _, _, _) =
      makeTfun (SOME T.arrayTypId)
        {printName = "array",
         admitsEq = true,
         formals = ["a"],
         dtyKind = BUILTIN R.recordProp}

  val (vectorTstrInfo, vectorTyCon, _, _, _) =
      makeTfun NONE
        {printName = "vector",
         admitsEq = true,
         formals = ["a"],
         dtyKind = BUILTIN R.recordProp}

  val (exnTstrInfo, exnTyCon, exnITy, exnTy, _) =
      makeTfun NONE
        {printName = "exn",
         admitsEq = false,
         formals = nil,
         dtyKind = BUILTIN R.recordProp}

  val (boxedTstrInfo, boxedTyCon, boxedITy, boxedTy, _) =
      makeTfun NONE
        {printName = "boxed",
         admitsEq = false,
         formals = nil,
         dtyKind = BUILTIN R.boxedProp}

  val (exntagTstrInfo, exntagTyCon, exntagITy, exntagTy, _) =
      makeTfun NONE
        {printName = "exntag",
         admitsEq = false,
         formals = nil,
         dtyKind = BUILTIN R.recordProp}

  val (contagTstrInfo, contagTyCon, contagITy, contagTy, _) =
      makeTfun NONE
        {printName = "contag",
         admitsEq = false,
         formals = nil,
         dtyKind = BUILTIN RuntimeTypes.contagProp}

  val _ = (* for opaque record/tuple types *)
      makeTfun NONE
        {printName = "record",
         admitsEq = false,
         formals = nil,
         dtyKind = BUILTIN RuntimeTypes.recordProp}

  val (sizeTstrInfo, sizeTyCon, sizeITy, sizeTy, _) =
      makeTfun NONE
        {printName = "size",
         admitsEq = true,
         formals = ["a"],
         dtyKind = BUILTIN R.uintptrProp}

  val (refTstrInfo, refTyCon, _, _, conList) =
      makeTfun (SOME T.refTypId)
        {printName = "ref",
         admitsEq = true,
         formals = ["a"],
         dtyKind = REF ("ref", SOME (TVAR "a"))}

  val (refICConInfo, refTPConInfo) =
      case conList of [x] => x | _ => raise bug "conList ref"

  (* datatype bool = false | true *)
  val (boolTstrInfo, boolTyCon, boolITy, boolTy, conList) =
      makeTfun NONE
        {printName = "bool",
         admitsEq = true,
         formals = nil,
         dtyKind = BOOL ("false", "true")}

  val ((falseICConInfo, falseTPConInfo),
       (trueICConInfo, trueTPConInfo)) =
      case conList of [x,y] => (x,y) | _ => raise bug "conList bool"

  (* datatype 'a list = :: of 'a * 'a list | nil *)
  val (listTstrInfo, listTyCon, _, listTy, conList) =
      makeTfun NONE
        {printName = "list",
         admitsEq = true,
         formals = ["a"],
         dtyKind = DTY [("::", SOME(TUPLE [TVAR "a", SELF [TVAR "a"]])),
                        ("nil", NONE)]}

  val ((consICConInfo, consTPConInfo),
       (nilICConInfo, nilTPConInfo)) =
      case conList of [x,y] => (x,y) | _ => raise bug "conList list"

  (* datatype 'a option = NONE | SOME of 'a *)
  val (optionTstrInfo, optionTyCon, _, _, conList) =
      makeTfun NONE
        {printName = "option",
         admitsEq = true,
         formals = ["a"],
         dtyKind = DTY [("NONE", NONE),
                        ("SOME", SOME (TVAR "a"))]}

  val ((NONEICConInfo, NONETPConInfo),
       (SOMEICConInfo, SOMETPConInfo)) =
      case conList of [x,y] => (x,y) | _ => raise bug "conList option"

  fun evalExn (longid, tyopt) : T.exExnInfo =
      let
        val ty = case tyopt of
                     NONE => exnTy
                   | SOME ty => T.FUNMty([ty], exnTy)
      in
        {path = mkLongsymbol longid, ty=ty}
      end

  val BindExExn = evalExn (["Bind"], NONE)
  val MatchExExn = evalExn (["Match"], NONE)
  val SubscriptExExn = evalExn (["Subscript"], NONE)
  val SizeExExn = evalExn (["Size"], NONE)
  val OverflowExExn = evalExn (["Overflow"], NONE)
  val DivExExn = evalExn (["Div"], NONE)
  val DomainExExn = evalExn (["Domain"], NONE)
  val FailExExn = evalExn (["Fail"], SOME stringTy)
  val ChrExExn = evalExn (["Chr"], NONE)

  fun findTstrInfo name =
      SymbolEnv.find (!tstrinfoMap, name)

  (* 以下は，builtin typesか否かの判定に使用 *)
  val _ = TypID.setReservedId ()

end
