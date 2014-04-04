(*  built-in types. *)
structure BuiltinTypes =
struct
  structure I = IDCalc
  structure T = Types
  structure Ity = EvalIty
  structure B = BuiltinTypeNames
  fun bug s = Bug.Bug ("BuiltinTypes: " ^ s)

  val pos = Loc.makePos {fileName="BuiltinTypes.sml", line=0, col=0}
  val loc = (pos,pos)
  fun mkLongsymbol path = Symbol.mkLongsymbol path loc
  fun mkSymbol name = Symbol.mkSymbol name loc

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
    | RECORD of (string * ty) list
    | FUN of ty * ty

  datatype dtyKind =
      BUILTIN of BuiltinTypeNames.bty
    | REF of string * ty option
    | DTY of (string * ty option) list

  fun makeConSpec stringTyOptionList =
      foldr
      (fn ((string, tyoption), conSpec) =>
          SymbolEnv.insert(conSpec, mkSymbol string, tyoption)
      )
      SymbolEnv.empty
      stringTyOptionList

  type btyDef =
      {printName : string list,
       admitsEq : bool,
       formals : string list,
       dtyKind : dtyKind}

  type btyInfo =
       tstrInfo
       * T.tyCon
       * I.ty
       * T.ty
       * (I.conInfo * T.conInfo) list

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
          (foldl
             (fn ((label, ty), fields) =>
                 LabelEnv.insert(fields, label, evalTy env ty))
             LabelEnv.empty
             fields)
      | TUPLE tys =>
        evalTy env (RECORD (Utils.listToTuple tys))
      | CON ({tfun,...}, args) =>
        I.TYCONSTRUCT {tfun = tfun, args = map (evalTy env) args}
      | SELF args =>
        I.TYCONSTRUCT {tfun = self, args = map (evalTy env) args}
      | FUN(bty1, bty2) =>
        I.TYFUNM([evalTy env bty1], evalTy env bty2)

  fun runtimeTyOfConspec conSpec =
      if SymbolEnv.isEmpty (SymbolEnv.filter isSome conSpec)
      then I.BUILTINty B.CONTAGty
      else I.BUILTINty B.BOXEDty

  local
    val builtinConEnvRef = ref ConID.Map.empty : (I.conInfo ConID.Map.map) ref
  in
    fun builtinConEnvAdd (id, conInfo) = 
        builtinConEnvRef := ConID.Map.insert(!builtinConEnvRef, id, conInfo)
    fun builtinConEnv ()= !builtinConEnvRef
  end
  fun makeTfun ({printName, admitsEq, formals, dtyKind}:btyDef) : btyInfo =
      let
        val longsymbol = mkLongsymbol printName
        val (dtyKind, runtimeTy, conSpec) =
            case dtyKind of
              BUILTIN x => (I.BUILTIN x, I.BUILTINty x, nil)
            | REF conSpec =>
              (I.DTY, I.BUILTINty B.REFty, [conSpec])
            | DTY conSpec =>
              (I.DTY, 
               runtimeTyOfConspec 
                 (makeConSpec conSpec), 
               conSpec)
        val formalTvars =
            map (fn tvarName =>
                    {symbol = mkSymbol tvarName,
                     eq = Absyn.NONEQ,
                     id = TvarID.generate (),
                     lifted = false})
                formals
        val tvarEnv =
            ListPair.foldlEq
              (fn (name, tvar, tvarEnv) => SymbolEnv.insert (tvarEnv, mkSymbol name, tvar))
              SymbolEnv.empty
              (formals, formalTvars)
        val id = TypID.generate()
        val dtySpec =
            {id = id,
             iseq = admitsEq,
             formals = formalTvars,
             runtimeTy = runtimeTy,
             conSpec = SymbolEnv.empty,
             conIDSet = ConID.Set.empty,
             longsymbol = longsymbol,
             liftedTys = I.emptyLiftedTys,
             dtyKind = dtyKind}
        val tfv = I.mkTfv (I.TFUN_DTY dtySpec)
        val tfun = I.TFUN_VAR tfv
        val conSpec =
            map
              (fn (name, NONE) => (name, NONE)
                | (name, SOME ty) => (name, SOME (evalTy (tvarEnv, tfun) ty)))
              conSpec
        val conSpec =
            foldl (fn ((k,v),z) => SymbolEnv.insert (z, mkSymbol k,v))
                  SymbolEnv.empty
                  conSpec
        val boundtvars = map (fn tv => (tv, I.UNIV)) formalTvars
        val returnTy =
            I.TYCONSTRUCT {tfun=tfun, args = map I.TYVAR formalTvars}
        val (varE, conIDSet) =
            SymbolEnv.foldri
              (fn (name, tyopt, (varE, conIDSet)) =>
                  let
                    val conId = ConID.generate()
                    val conBodyTy =
                        case tyopt of
                          NONE => returnTy
                        | SOME ty => I.TYFUNM ([ty], returnTy)
                    val conTy =
                        case formalTvars of
                          nil => conBodyTy
                        | _ => I.TYPOLY (boundtvars, conBodyTy)
                    val conInfo = {id=conId, ty=conTy, longsymbol=[name]}
                    val _ = builtinConEnvAdd (conId, conInfo)
                  in
                    (SymbolEnv.insert(varE, name, I.IDCON conInfo),
                     ConID.Set.add(conIDSet, conId))
                  end)
              (SymbolEnv.empty, ConID.Set.empty)
              conSpec
        val dtySpec = dtySpec # {conSpec = conSpec}
        val dtySpec = dtySpec # {conIDSet = conIDSet}
        val _ = tfv := I.TFUN_DTY dtySpec  
        val tyCon = Ity.evalTfun Ity.emptyContext tfun
                    handle e => (print "bug: evalTfun failed 2\n"; raise e)
        val ity =
            case formalTvars of
              nil => I.TYCONSTRUCT {tfun=tfun, args=nil}
            | _::_ => I.TYERROR
        val ty = Ity.evalIty Ity.emptyContext ity
        val conList =
            map (fn I.IDCON (conInfo as {id, ty, longsymbol}) =>
                    (conInfo, {id=id, ty = Ity.evalIty Ity.emptyContext ty,
                               longsymbol = longsymbol})
                  | _ => raise bug "con not found")
                (SymbolEnv.listItems varE)
      in
        ({tfun=tfun, varE=varE, formals=formalTvars, conSpec=conSpec},
         tyCon,
         ity,
         ty,
         conList)
      end

  val (intTstrInfo, intTyCon, intITy, intTy, _) =
      makeTfun
        {printName = ["int"],
         admitsEq = true,
         formals = nil,
         dtyKind = BUILTIN B.INTty}

  val (intInfTstrInfo, intInfTyCon, intInfITy, intInfTy, _) =
      makeTfun
        {printName = ["intInf"],
         admitsEq = true,
         formals = nil,
         dtyKind = BUILTIN B.INTINFty}

  val (wordTstrInfo, wordTyCon, wordITy, wordTy, _) =
      makeTfun
        {printName = ["word"],
         admitsEq = true,
         formals = nil,
         dtyKind = BUILTIN B.WORDty}

  val (word8TstrInfo, word8TyCon, word8ITy, word8Ty, _) =
      makeTfun
        {printName = ["word8"],
         admitsEq = true,
         formals = nil,
         dtyKind = BUILTIN B.WORD8ty}

  val (charTstrInfo, charTyCon, charITy, charTy, _) =
      makeTfun
        {printName = ["char"],
         admitsEq = true,
         formals = nil,
         dtyKind = BUILTIN B.CHARty}

  val (stringTstrInfo, stringTyCon, stringITy, stringTy, _) =
      makeTfun
        {printName = ["string"],
         admitsEq = true,
         formals = nil,
         dtyKind = BUILTIN B.STRINGty}

  val (realTstrInfo, realTyCon, realITy, realTy, _) =
      makeTfun
        {printName = ["real"],
         admitsEq = false,
         formals = nil,
         dtyKind = BUILTIN B.REALty}

  val (real32TstrInfo, real32TyCon, real32ITy, real32Ty, _) =
      makeTfun
        {printName = ["real32"],
         admitsEq = false,
         formals = nil,
         dtyKind = BUILTIN B.REAL32ty}

  val (unitTstrInfo, unitTyCon, unitITy, unitTy, _) =
      makeTfun
        {printName = ["unit"],
         admitsEq = true,
         formals = nil,
         dtyKind = BUILTIN B.UNITty}

  val (ptrTstrInfo, ptrTyCon, _, _, _) =
      makeTfun
        {printName = ["ptr"],
         admitsEq = true,
         formals = ["a"],
         dtyKind = BUILTIN B.PTRty}

  val unitPtr = CON (ptrTstrInfo, [CON (unitTstrInfo, nil)])

  val (codeptrTstrInfo, codeptrTyCon, codeptrITy, codeptrTy, _) =
      makeTfun
        {printName = ["codeptr"],
         admitsEq = true,
         formals = nil,
         dtyKind = BUILTIN B.CODEPTRty}

  val (arrayTstrInfo, arrayTyCon, _, _, _) =
      makeTfun
        {printName = ["array"],
         admitsEq = true,
         formals = ["a"],
         dtyKind = BUILTIN B.ARRAYty}

  val (vectorTstrInfo, vectorTyCon, _, _, _) =
      makeTfun
        {printName = ["vector"],
         admitsEq = true,
         formals = ["a"],
         dtyKind = BUILTIN B.VECTORty}

  val (exnTstrInfo, exnTyCon, exnITy, exnTy, _) =
      makeTfun
        {printName = ["exn"],
         admitsEq = false,
         formals = nil,
         dtyKind = BUILTIN B.EXNty}

  val (boxedTstrInfo, boxedTyCon, boxedITy, boxedTy, _) =
      makeTfun
        {printName = ["boxed"],
         admitsEq = false,
         formals = nil,
         dtyKind = BUILTIN B.BOXEDty}

  val (exntagTstrInfo, exntagTyCon, exntagITy, exntagTy, _) =
      makeTfun
        {printName = ["exntag"],
         admitsEq = false,
         formals = nil,
         dtyKind = BUILTIN B.EXNTAGty}

  val (contagTstrInfo, contagTyCon, contagITy, contagTy, _) =
      makeTfun
        {printName = ["contag"],
         admitsEq = false,
         formals = nil,
         dtyKind = BUILTIN B.CONTAGty}

  val (refTstrInfo, refTyCon, _, _, conList) =
      makeTfun
        {printName = ["ref"],
         admitsEq = true,
         formals = ["a"],
         dtyKind = REF ("ref", SOME(TVAR "a"))}

  val (refICConInfo, refTPConInfo) =
      case conList of [x] => x | _ => raise bug "conList ref"

  (* datatype bool = false | true *)
  val (boolTstrInfo, boolTyCon, boolITy, boolTy, conList) =
      makeTfun
        {printName = ["bool"],
         admitsEq = true,
         formals = nil,
         dtyKind = DTY [("false", NONE), ("true", NONE)]}

  val ((falseICConInfo, falseTPConInfo),
       (trueICConInfo, trueTPConInfo)) =
      case conList of [x,y] => (x,y) | _ => raise bug "conList bool"

  (* datatype 'a list = :: of 'a * 'a list | nil *)
  val (listTstrInfo, listTyCon, _, _, conList) =
      makeTfun
        {printName = ["list"],
         admitsEq = true,
         formals = ["a"],
         dtyKind = DTY [("::", SOME(TUPLE [TVAR "a", SELF [TVAR "a"]])),
                        ("nil", NONE)]}

  val ((consICConInfo, consTPConInfo),
       (nilICConInfo, nilTPConInfo)) =
      case conList of [x,y] => (x,y) | _ => raise bug "conList list"

  (* datatype 'a option = NONE | SOME of 'a *)
  val (optionTstrInfo, optionTyCon, _, _, conList) =
      makeTfun
        {printName = ["option"],
         admitsEq = true,
         formals = ["a"],
         dtyKind = DTY [("NONE", NONE),
                        ("SOME", SOME (TVAR "a"))]}

  val ((NONEICConInfo, NONETPConInfo),
       (SOMEICConInfo, SOMETPConInfo)) =
      case conList of [x,y] => (x,y) | _ => raise bug "conList option"

  (* datatype 'a dbi = DBI *)
  val (dbiTstrInfo, dbiTyCon, _, _, conList) =
      makeTfun
        {printName = ["SQL", "dbi"],
         admitsEq = true,
         formals = ["a"],
         dtyKind = DTY [("DBI", NONE)]}

  val (DBIICConInfo, DBITPConInfo) =
      case conList of [x] => x | _ => raise bug "conList dbi"

  (* datatype ('a,'b) value = VALUE of (string * 'b dbi) * 'a *)
  val (valueTstrInfo, valueTyCon, _, _, conList) =
      makeTfun
        {printName = ["SQL", "value"],
         admitsEq = true,
         formals = ["a", "b"],
         dtyKind =
           DTY [("VALUE",
                 SOME (TUPLE [TUPLE [CON (stringTstrInfo, nil),
                                     CON (dbiTstrInfo, [TVAR "b"])],
                              TVAR "a"]))]}

  val (VALUEICConInfo, VALUETPConInfo) =
      case conList of [x] => x | _ => raise bug "conList value"

  fun evalExn (longid, tyopt) : T.exExnInfo =
      let
        val ty = case tyopt of
                     NONE => exnTy
                   | SOME ty => T.FUNMty([ty], exnTy)
      in
        {longsymbol= mkLongsymbol longid, ty=ty}
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
      case name of
        "int" => SOME intTstrInfo
      | "intInf" => SOME intInfTstrInfo
      | "word" => SOME wordTstrInfo
      | "word8" => SOME word8TstrInfo
      | "char" => SOME charTstrInfo
      | "string" => SOME stringTstrInfo
      | "real" => SOME realTstrInfo
      | "real32" => SOME real32TstrInfo
      | "unit" => SOME unitTstrInfo
      | "ptr" => SOME ptrTstrInfo
      | "codeptr" => SOME codeptrTstrInfo
      | "array" => SOME arrayTstrInfo
      | "vector" => SOME vectorTstrInfo
      | "exn" => SOME exnTstrInfo
      | "boxed" => SOME boxedTstrInfo
      | "exntag" => SOME exntagTstrInfo
      | "ref" => SOME refTstrInfo
      | "bool" => SOME boolTstrInfo
      | "list" => SOME listTstrInfo
      | "option" => SOME optionTstrInfo
      | "dbi" => SOME dbiTstrInfo
      | "value" => SOME valueTstrInfo
      | _ => NONE

end
