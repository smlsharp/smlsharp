(**
 * @copyright (c) 2012- Tohoku University.
 * @author Atsushi Ohori
 *)
structure Reify =
struct
local
  fun bug s = Bug.Bug ("Reiy:" ^ s)
  structure I = IDCalc
  structure T = Types
  structure ITy = EvalIty
  structure TC = TypedCalc
  structure TB = TypesBasics
  structure TCU = TypedCalcUtils
  structure TIU = TypeInferenceUtils
  structure U = Unify
  structure RD = ReifiedTermData
  structure BT = BuiltinTypes
  structure V = NameEvalEnv

  val idstatusWidth = 60
  val tstrWidth = 70
  val sigWidth = 75

  val pos = Loc.makePos {fileName="ReifiedTermData.sml", line=0, col=0}
  val loc = (pos,pos)

  (* this is a copy from Control
   *)
  fun prettyPrint width expressions =
      let
        val ppgenParameter = [SMLFormat.Columns width]
      in
        SMLFormat.prettyPrint ppgenParameter expressions
      end

  fun eqTyCon ({id=id1,...}:T.tyCon, {id=id2,...}:T.tyCon) =
      TypID.eq(id1,id2)

  fun reifiedTerm () =
      case !RD.reifiedTerm of
        SOME ty => ty
      | NONE => raise bug "reifiedTerm not set"

  fun makeString string =
      TC.TPCONSTANT {const=Absyn.STRING (string, loc),
                     ty=BT.stringTy,
                     loc=loc}

  fun makeSymbol symbol =
      let
        val string = Symbol.symbolToString symbol
      in
        TC.TPCONSTANT {const=Absyn.STRING (string, loc),
                       ty=BT.stringTy,
                       loc=loc}
      end
  fun makeInt int =
      TC.TPCONSTANT {const=Absyn.INT (int, loc),
                     ty=BT.intTy,
                     loc=loc}
  fun makeMonoApply2 funOptRef arg1 arg2 =
      let
        val (funterm, funTy) =
            case !funOptRef of
              SOME (funterm, funTy) => (funterm, funTy)
            | NONE => raise bug "funterm not set"
        val term1 = 
            TC.TPAPPM
              {funExp=funterm, 
               funTy=funTy,
               argExpList=[arg1],
               loc=Loc.noloc}
        val funTy = case funTy of
                      T.FUNMty(_, ty) => ty
                    | _ => raise bug "non fun ty"
        val term2 = 
            TC.TPAPPM
              {funExp=term1, 
               funTy=funTy,
               argExpList=[arg2],
               loc=Loc.noloc}
      in
        term2
      end
  fun makeMonoApply3 funOptRef arg1 arg2 arg3 =
      let
        val (funterm, funTy) =
            case !funOptRef of
              SOME (funterm, funTy) => (funterm, funTy)
            | NONE => raise bug "funterm not set"
        val term1 = 
            TC.TPAPPM
              {funExp=funterm, 
               funTy=funTy,
               argExpList=[arg1],
               loc=Loc.noloc}
        val funTy = case funTy of
                      T.FUNMty(_, ty) => ty
                    | _ => raise bug "non fun ty"
        val term2 = 
            TC.TPAPPM
              {funExp=term1, 
               funTy=funTy,
               argExpList=[arg2],
               loc=Loc.noloc}
        val funTy = case funTy of
                      T.FUNMty(_, ty) => ty
                    | _ => raise bug "non fun ty"
        val term3 = 
            TC.TPAPPM
              {funExp=term2, 
               funTy=funTy,
               argExpList=[arg3],
               loc=Loc.noloc}
      in
        term3
      end

(*
  structure ExnConOrd =
  struct
    type ord_key = TC.exnCon
    fun compare (exncon1, exncon2) =
        case (exncon1, exncon2) of
          (TC.EXN _, TC.EXEXN _) => LESS
        | (TC.EXEXN _, TC.EXN _) => GREATER
        | (TC.EXN {id=id1,...}, TC.EXN {id=id2, ...})  => ExnID.compare(id1,id2)
        | (TC.EXEXN {longsymbol=longsymbol1,...}, 
           TC.EXEXN {longsymbol=longsymbol2,...})  =>
          let
            val string1 = Symbol.longsymbolToString longsymbol1
            val string2 = Symbol.longsymbolToString longsymbol2
          in
            String.compare(string1, string2)
          end
  end
  structure ExnConSet = BinarySetFn(ExnConOrd)
  val exnConSetRef = ref ExnConSet.empty
*)

   val exnConListRef = ref nil : NameEval.exnCon list ref
in

  fun makeMonoApply funOptRef arg =
      let
        val (funterm, funTy) =
            case !funOptRef of
              SOME (funterm, funTy) => (funterm, funTy)
            | NONE => raise bug "funterm not set"
      in
        TC.TPAPPM
          {funExp=funterm, 
           funTy=funTy,
           argExpList=[arg],
           loc=Loc.noloc}
      end

  fun reify (dataL, exnL) (ty, tpexp) =
      case TB.derefTy ty of
      T.SINGLETONty _ => RD.unprintable()
    | T.BACKENDty _ => RD.unprintable()
    | T.ERRORty => RD.unprintable()
    | T.DUMMYty _ => RD.unprintable()
    | T.TYVARty _ => RD.unprintable()
    | T.BOUNDVARty _ => RD.unprintable()
    | T.FUNMty _ => RD.mkFUNtyRepTerm()
    | T.RECORDty tyLabelEnvMap =>
      let
        val stringTyList = LabelEnv.listItemsi tyLabelEnvMap
        fun reifyField (dataL, exnL) (label, fieldTy) =
            let
              val fieldExp = 
                  TC.TPSELECT {label=label, 
                               exp=tpexp,
                               expTy=ty, 
                               resultTy=fieldTy, 
                               loc=Loc.noloc}
              val term = reify (dataL, exnL) (fieldTy, fieldExp)
            in
              makeMonoApply2 RD.makeFieldTerm (makeString label) term
            end
        fun reifyElem (dataL, exnL) (label, fieldTy) =
            let
              val fieldExp = 
                  TC.TPSELECT {label=label, 
                               exp=tpexp,
                               expTy=ty, 
                               resultTy=fieldTy,
                               loc=Loc.noloc}
            in
              reify (dataL, exnL) (fieldTy, fieldExp)
            end
        val fieldNil = case !RD.fieldNil of
                         NONE => raise bug "fieldNil not set"
                       | SOME (term, ty) => term
        val reifiedTermNil = 
            case !RD.reifiedTermNil of
              NONE => raise bug "reifiedTermNil not set"
            | SOME (term, ty) => term
      in
        if SmlppgUtil.isNumeric stringTyList
        then 
          let
            val reifiedFieldList = map (reifyElem (dataL, exnL)) stringTyList
          in
            RD.mkTUPLEtyRepTerm
              (foldr
                 (fn (reifiedField, fieldListTerm) =>
                     makeMonoApply2
                       RD.makeConsTerm
                       reifiedField
                       fieldListTerm
                 )
                 reifiedTermNil
                 reifiedFieldList
              )
          end
        else 
          RD.mkRECORDtyRepTerm
            (foldr
               (fn (field, fieldListTerm) =>
                   makeMonoApply2
                     RD.makeConsField
                     (reifyField (dataL, exnL) field)
                     fieldListTerm
               )
               fieldNil
               stringTyList
            )
      end
    | T.CONSTRUCTty {tyCon=tyCon as {longsymbol,...}, args} =>
      reifyTyCon (dataL, exnL) (ty, tyCon, args, longsymbol, tpexp)
    | T.POLYty  {boundtvars, body} =>
      let
        val (newTy, newExp) = 
            TCU.toplevelInstWithInstTy (ty, tpexp, BT.unitTy)
      in
        reify (dataL, exnL)(newTy, newExp)
(*
        (case body of
           T.FUNMty _ => RD.mkFUNtyRepTerm()
         | _ => RD.unprintable()
        )
*)
      end
    (* FIXME: we can do someting more for poly *)

  and makeReifyFun (dataL, exnL) ty =
      let
        val newVarInfo = TCU.newTCVarInfo loc ty
        val argVar = TC.TPVAR newVarInfo
        val mapBody = reify (dataL, exnL) (ty, argVar)
        val bodyTy = reifiedTerm()
      in
        TC.TPFNM {argVarList=[newVarInfo], 
                  bodyTy=bodyTy,
                  bodyExp=mapBody, 
                  loc=Loc.noloc}
      end

  and makePolyReify (dataL, exnL) argTys (makeTermVar, makeTermVarTy) exp =
      case argTys of
        [argTy] => 
        let
          val reifyFun = makeReifyFun (dataL, exnL) argTy
          (* makeTermVar: ['a. ('a -> reifiedTerm) -> 'a tycon -> reifiedTerm *)
          val makeTermVarInst =
              TC.TPTAPP{exp=makeTermVar,
                        expTy=makeTermVarTy,
                        instTyList=[argTy],
                        loc=Loc.noloc}
           val instTy = U.instOfPolyTy(makeTermVarTy, [argTy])
           val termFun =
               TC.TPAPPM
                 {funExp=makeTermVarInst, 
                  funTy=instTy,
                  argExpList=[reifyFun],
                  loc=Loc.noloc}
           val ranTy = case instTy of
                         T.FUNMty(_, ty) => ty
                       | _ => raise bug "non funty"
        in
          TC.TPAPPM
            {funExp=termFun, 
             funTy=ranTy,
             argExpList = [exp], 
             loc=Loc.noloc}
        end
      | _ => raise bug "term tycon arg"

  and reifyTyCon (dataL, exnL) (ty, tyCon, args, longsymbol, exp) =
      if eqTyCon(tyCon, BT.intTyCon) then
        RD.mkINTtyRepTerm exp
      else if eqTyCon(tyCon, BT.boolTyCon) then
        RD.mkBOOLtyRepTerm exp
      else if eqTyCon(tyCon, BT.intInfTyCon) then
        RD.mkINTINFtyRepTerm exp
      else if eqTyCon(tyCon, BT.wordTyCon) then
        RD.mkWORDtyRepTerm exp
      else if eqTyCon(tyCon, BT.word8TyCon) then
        RD.mkWORD8tyRepTerm exp
      else if eqTyCon(tyCon, BT.charTyCon) then
        RD.mkCHARtyRepTerm exp
      else if eqTyCon(tyCon, BT.ptrTyCon) then
        RD.mkPTRtyRepTerm ()
      else if eqTyCon(tyCon, BT.realTyCon) then
        RD.mkREALtyRepTerm exp
      else if eqTyCon(tyCon, BT.real32TyCon) then
        RD.mkREAL32tyRepTerm exp
      else if eqTyCon(tyCon, BT.stringTyCon) then
        RD.mkSTRINGtyRepTerm exp
      else if eqTyCon(tyCon, BT.unitTyCon) then
        RD.mkUNITtyRepTerm ()
      else if eqTyCon(tyCon, BT.listTyCon) then
        let
          val (makeTermVar, makeTermVarTy) = 
              case !RD.makeListTerm of
                SOME (var, ty) => (var, ty)
              | NONE => raise bug "makeListTerm not set"
        in
          makePolyReify (dataL, exnL) args (makeTermVar, makeTermVarTy) exp
        end
      else if eqTyCon(tyCon, BT.arrayTyCon) then
        let
          val (makeTermVar, makeTermVarTy) = 
              case !RD.makeArrayTerm of
                SOME (var, ty) => (var, ty)
              | NONE => raise bug "makeArrayTerm not set"
        in
          makePolyReify (dataL, exnL) args (makeTermVar, makeTermVarTy) exp
        end
      else if eqTyCon(tyCon, BT.exnTyCon) then
(*
        reifyExn (dataL, exnL) (ty, args, exp)
*)
        reifyExn (dataL, exnL) exp
      else 
        let
          val conIDSet = #conIDSet tyCon
        in
          reifyDatatype (dataL, exnL) (ty, args, conIDSet, exp)
        end

   and reifyDatatype (dataL, exnL) (ty, instTyList, conIDSet, exp) =
       if dataL > 0 then
         let
           val dataL = dataL - 1
           fun makePatExp (argTyOpt, conTy, conInfo) =
               let
                 val longsymbol = #longsymbol conInfo
                 val longid = Symbol.longsymbolToLongid longsymbol
                 val conName = case List.rev longid of
                                 nil => ""
                               | [s] => s
                               | h1::h2::_ =>
                                 (case Int.fromString h1 of
                                    NONE => h1
                                  | SOME _ =>  h2)
                 val conNameTerm = makeString conName
                 val (argPatOpt, body) =
                     case argTyOpt of
                       NONE =>
                       (NONE, makeMonoApply RD.makeDATATYPEtyRepNOARG conNameTerm)
                     | SOME argTy =>
                       let
                         val var = {longsymbol=longsymbol, id=VarID.generate(), ty=argTy, opaque=false}
                         val argTerm = reify (dataL, exnL) (argTy, TC.TPVAR var)
                       in
                         (SOME (TC.TPPATVAR var),
                          makeMonoApply2 RD.makeDATATYPEtyRepWITHARG conNameTerm argTerm
                         )
                       end
                 val tppat = 
                     TC.TPPATDATACONSTRUCT
                       {argPatOpt = argPatOpt,
                        conPat = conInfo,
                        instTyList=instTyList,
                        loc=Loc.noloc,
                        patTy=conTy}
               in
                 (tppat, body)
               end
           fun makeRule id =
               let
                 val {longsymbol, ty=ity, id} = NameEvalEnv.conEnvFind id
                 val polyTy = ITy.evalIty ITy.emptyContext ity
                 val ty = TypesBasics.tpappTy (polyTy, instTyList)
                 val conInfo = {longsymbol=longsymbol, ty=polyTy, id=id}
                 val (agrTyOpt, conTy) =
                     case ty of
                       T.FUNMty ([argTy], conTy) => (SOME argTy, conTy)
                     | _ => (NONE, ty)
                 val (tppat, tpexp) = makePatExp (agrTyOpt, conTy, conInfo)
               in
                 {args=[tppat], body=tpexp}
               end
           val ruleList = map makeRule (ConID.Set.listItems conIDSet)
         in
           case ruleList of
             nil => RD.unprintable()
           | _ => 
             TC.TPCASEM
               {caseKind=PatternCalc.MATCH, 
                expList = [exp],
                expTyList = [ty], 
                ruleBodyTy = reifiedTerm (),
                ruleList = ruleList,
                loc = Loc.noloc
               }
         end
       else
         RD.elipsis()

   and reifyExn (dataL, exnL) exp =
       if exnL > 0 then
         let
           val exnL = exnL - 1
           fun makePatExp (argTyOpt, exnTy, exnCon) =
               let
                 val longsymbol = 
                     case exnCon of
                       TC.EXN {longsymbol, ...} => longsymbol
                     | TC.EXEXN {longsymbol, ...} => longsymbol
                 val longid = Symbol.longsymbolToLongid longsymbol
                 val exnName = case List.rev longid of
                                 nil => ""
                               | [s] => s
                               | h1::h2::_ =>
                                 (case Int.fromString h1 of
                                    NONE => h1
                                  | SOME _ =>  h2)
                 val exnNameTerm = makeString exnName
                 val (argPatOpt, body) =
                     case argTyOpt of
                       NONE =>
                       (NONE, makeMonoApply RD.makeDATATYPEtyRepNOARG exnNameTerm)
                     | SOME argTy =>
                       let
                         val var = {longsymbol=longsymbol, id=VarID.generate(), ty=argTy, opaque=false}
                         val argTerm = reify (dataL, exnL) (argTy, TC.TPVAR var)
                       in
                         (SOME (TC.TPPATVAR var),
                          makeMonoApply2 RD.makeDATATYPEtyRepWITHARG exnNameTerm argTerm
                         )
                       end
                 val tppat = 
                     TC.TPPATEXNCONSTRUCT
                       {
                        exnPat = exnCon, 
                        instTyList = nil,
                        argPatOpt = argPatOpt,
                        patTy=exnTy, 
                        loc=Loc.noloc
                       }
               in
                 (tppat, body)
               end
           fun makeRule exnCon =
               let
                 val exnCon = 
                     case exnCon of
                       NameEval.EXN {longsymbol, id, ty} =>
                       TC.EXN {longsymbol = longsymbol,
                               id = id,
                               ty = ITy.evalIty ITy.emptyContext ty}
                     | NameEval.EXEXN {longsymbol, version, ty} =>
                       TC.EXEXN {longsymbol = Symbol.setVersion(longsymbol, version),
                                 ty = ITy.evalIty ITy.emptyContext ty}
                 val ty =
                     case exnCon of 
                       TC.EXN {ty, ...} => ty
                     | TC.EXEXN {ty, ...} => ty
                 val (agrTyOpt, exnTy) =
                     case ty of
                       T.FUNMty ([argTy], exnTy) => (SOME argTy, exnTy)
                     | _ => (NONE, ty)
                 val (tppat, tpexp) = makePatExp (agrTyOpt, exnTy, exnCon)
               in
                 {args=[tppat], body=tpexp}
               end
           val ruleList = map makeRule (!exnConListRef)
           val defaultCase = 
               {args = [TC.TPPATWILD (BT.exnTy, Loc.noloc)], body=RD.mkEXNtyRepTerm ()}
         in
           case ruleList of
             nil => RD.mkEXNtyRepTerm ()
           | _ => 
             TC.TPCASEM
               {caseKind=PatternCalc.MATCH, 
                expList = [exp],
                expTyList = [BT.exnTy], 
                ruleBodyTy = reifiedTerm (),
                ruleList = ruleList @ [defaultCase],
                loc = Loc.noloc
               }
         end
       else
         RD.elipsis()

  fun reifyFn (dataL, exnL) (ty, arg) () = reify (dataL, exnL) (ty, arg) 
  fun reifyIdstatus (dataL, exnL) (name, idstatus) =
      case idstatus of
      I.IDVAR varId => NONE
    | I.IDVAR_TYPED _ => NONE
    | I.IDEXVAR {exInfo=exInfo as {longsymbol, ty=ity, version}, used, internalId = SOME id} =>
      let
        val loc = Symbol.longsymbolToLoc longsymbol
        val accessLongsymbol = Symbol.setVersion(longsymbol, version)
        val tyTerm = makeString (prettyPrint idstatusWidth (I.print_ty (nil,nil) ity))
        val ty = ITy.evalIty ITy.emptyContext ity
        val nameTerm = makeSymbol name
        val var = TC.TPVAR {longsymbol=accessLongsymbol, ty=ty, id=id, opaque=false}
        val reifiedTerm = reify (dataL, exnL) (ty, var)
        val newIdstatus = 
            I.IDEXVAR {exInfo=exInfo, used=used, internalId = NONE}
      in
        SOME (newIdstatus, makeMonoApply3 RD.makeEXVAR nameTerm reifiedTerm tyTerm)
      end
    | I.IDEXVAR {exInfo={longsymbol, ty, version}, used, internalId = NONE,...} =>
      let
        val accessLongsymbol = Symbol.setVersion(longsymbol, version)
        val tyTerm = makeString (prettyPrint idstatusWidth (I.print_ty (nil,nil) ty))
        val ty = ITy.evalIty ITy.emptyContext ty
        val nameTerm = makeSymbol name
        val var = TC.TPEXVAR {longsymbol=accessLongsymbol, ty=ty}
        val reifiedTerm = reify (dataL, exnL) (ty, var)
      in
        SOME (idstatus, makeMonoApply3 RD.makeEXVAR nameTerm reifiedTerm tyTerm)
      end
    | I.IDEXVAR_TOBETYPED _ => NONE
    | I.IDBUILTINVAR {primitive, ty} => 
      let
        val tyTerm = makeString (prettyPrint idstatusWidth (I.print_ty (nil,nil) ty))
        val nameTerm = makeSymbol name
        val reifiedTerm = RD.builtin()
      in
        SOME (idstatus, makeMonoApply3 RD.makeEXVAR nameTerm reifiedTerm tyTerm)
      end
    | I.IDCON _ => NONE
    | I.IDEXN _ => NONE
    | I.IDEXNREP _ => NONE
    | I.IDEXEXN ({longsymbol, ty, version}, used) =>
      let
        val ty = ITy.evalIty ITy.emptyContext ty
        val exnArgTy = 
            case ty of 
              T.FUNMty([argTy], _) => SOME argTy
            | _ => NONE
        val argTyTerm =
            case exnArgTy of 
              NONE => makeString ""
            | SOME argTy => makeString (prettyPrint idstatusWidth (T.format_ty nil argTy))
        val nameTerm = makeSymbol name
      in
        SOME (idstatus, makeMonoApply2 RD.makeEXEXN nameTerm argTyTerm)
      end
    | I.IDEXEXNREP ({longsymbol, ty, version}, used) =>
      let
        val ty = ITy.evalIty ITy.emptyContext ty
        val pathTerm = makeString (Symbol.longsymbolToString longsymbol)
        val nameTerm = makeSymbol name
      in
        SOME (idstatus, makeMonoApply2 RD.makeEXEXNREP nameTerm pathTerm)
      end
    | I.IDOPRIM _ => NONE
    | I.IDSPECVAR _ => NONE
    | I.IDSPECEXN _ => NONE
    | I.IDSPECCON _ => NONE

  fun reifyTstr (dataL, exnL) (symbol, tstr) =
      let
        val name = Symbol.symbolToString symbol
        val name = SmlppgUtil.makeToken name
        val tyVal = 
            case tstr of
              V.TSTR tfun => makeString (prettyPrint tstrWidth (I.print_tfun (nil,name) tfun))
            | V.TSTR_DTY {tfun, varE, formals, conSpec} => 
              makeString (prettyPrint tstrWidth (I.print_tfun (SmlppgUtil.makeToken "DTY",name) tfun))
      in
        makeMonoApply2 RD.makeSigentry (makeString "") tyVal
      end

  fun filterSpecConVarE varE =
      SymbolEnv.foldri
        (fn (name, I.IDSPECCON _, varE) => varE
          | (name, idstatus, varE) => SymbolEnv.insert(varE, name, idstatus))
      SymbolEnv.empty
      varE
  fun filterSpecConEnv (V.ENV {varE, tyE, strE}) =
      let
        val varE = filterSpecConVarE varE
      in
        V.ENV{varE=varE, tyE=tyE, strE=strE}
      end
  fun filterSpecCon 
        {id,
         version,
         used,
         argSigEnv,
         argStrEntry,
         argStrName,
         dummyIdfunArgTy,
         polyArgTys,
         typidSet,
         exnIdSet,
         bodyEnv,
         bodyVarExp
        } =
        {id = id,
         version = version,
         used = used,
         argSigEnv = filterSpecConEnv argSigEnv,
         argStrEntry = argStrEntry,
         argStrName = argStrName,
         dummyIdfunArgTy = dummyIdfunArgTy,
         polyArgTys = polyArgTys,
         typidSet = typidSet,
         exnIdSet = exnIdSet,
         bodyEnv = bodyEnv,
         bodyVarExp = bodyVarExp
        }

  fun reifyFunEntry (dataL, exnL) (symbol, funEEntry) =
      let
        (* 2012-8-7 ohori ad-hoc fix for bug 232_functorSigNewLines.sml
         *)
        val funEEntry = filterSpecCon funEEntry
        val name = ("functor " ^ (Symbol.symbolToString symbol))
        val funE = makeString (name ^ (prettyPrint tstrWidth (V.printTy_funEEntry funEEntry)))
      in
        funE
      end

  fun reifyEnv (dataL, exnL) env = 
      let
        val env = NormalizeTy.reduceEnv env
        (* tyE *)
        val V.ENV {varE, tyE, strE=V.STR strE} = env
        val symbolTstrList = SymbolEnv.listItemsi tyE
        val termList = map (reifyTstr (dataL, exnL)) symbolTstrList
        val listTermTyE = case !RD.tstrNil of
                        NONE => raise bug "idstatusNil not set"
                      | SOME (term, ty) => term
        val listTermTyE =
            foldr 
              (fn (term, listTerm) =>
                  makeMonoApply2 RD.tstrCons term listTerm
              )
              listTermTyE
              termList

        (* strE *)
        val listTermStrentry = case !RD.strentryNil of
                        NONE => raise bug "rstrentryNil not set"
                      | SOME (term, ty) => term
        val (newStrE, listTermStrentry) =
            SymbolEnv.foldri
            (fn (name, {env, strKind}, (newStrE, listTermStrentry)) =>
                let
                  val nameTerm = makeSymbol name
                  val (newEnv,envTerm) = reifyEnv (dataL, exnL) env
                  val termStrEntry = makeMonoApply2 RD.makeStrentry nameTerm envTerm
                  val newStrE = SymbolEnv.insert(newStrE, name, {env=newEnv, strKind=strKind})
                in
                  (newStrE, makeMonoApply2 RD.strentryCons termStrEntry listTermStrentry)
                end
            )
            (SymbolEnv.empty, listTermStrentry)
            strE
        val strE = V.updateStrE(V.STR strE, V.STR newStrE)

        (* varE *)
        val listTermVarE = case !RD.idstatusNil of
                        NONE => raise bug "idstatusNil not set"
                      | SOME (term, ty) => term
        val (newVarE, listTermVarE) =
            SymbolEnv.foldri
            (fn (name, idstatus, (newVarE, listTermVarE)) =>
                let
                  val termIdstatusOpt = reifyIdstatus (dataL, exnL) (name, idstatus)
                in
                  case termIdstatusOpt of
                    NONE => (newVarE, listTermVarE)
                  | SOME(idstatus, term) => 
                    (SymbolEnv.insert(newVarE, name, idstatus),
                     makeMonoApply2 RD.idstatusCons term listTermVarE
                    )
                end
            )
            (SymbolEnv.empty,listTermVarE)
            varE
        val varE = V.varEWithVarE(varE, newVarE)
        val env = V.ENV {varE=varE, tyE=tyE, strE=strE}
      in
        (env, makeMonoApply3 RD.makeENV listTermVarE listTermTyE listTermStrentry)
      end

  fun printableIdstatus idstatus =
      case idstatus of
        I.IDVAR _ => false
      | I.IDVAR_TYPED  _ => false
      | I.IDEXVAR  _ => false
      | I.IDEXVAR_TOBETYPED  _ => false
      | I.IDBUILTINVAR  _ => false
      | I.IDCON  _ => false
      | I.IDEXN  _ => false
      | I.IDEXNREP  _ => false
      | I.IDEXEXN  _ => false
      | I.IDEXEXNREP  _ => false
      | I.IDOPRIM  _ => false
      | I.IDSPECVAR  _ => true
      | I.IDSPECEXN  _ => true
      | I.IDSPECCON _ => false

  fun filterVarE varE = 
      SymbolEnv.foldri 
      (fn (name, idstatus, varE) => 
          if printableIdstatus idstatus then SymbolEnv.insert(varE, name, idstatus)
          else varE
      )
      SymbolEnv.empty
      varE
  fun filterEnv (V.ENV {varE, tyE, strE=V.STR strE}) =
      let
        val varE = filterVarE varE
        val strE = SymbolEnv.map
                     (fn {env, strKind} => {env=filterEnv env, strKind=strKind}) strE
      in
        V.ENV {varE=varE, tyE=tyE, strE=V.STR strE}
      end

  fun reifySigE (dataL, exnL) (sigE:V.sigE) =
      let
        val sigE = SymbolEnv.map (fn env => filterEnv env) sigE
        val sigE = SymbolEnv.listItemsi sigE
      in
        makeString (prettyPrint sigWidth (V.printTy_sigEList sigE))
      end
  fun reifyFunE (dataL, exnL) (funE:V.funE) =
      let
        val symbolFunEntryList = SymbolEnv.listItemsi funE
        val nilTerm = case !RD.stringNil of
                        NONE => raise bug "funeNil not set"
                      | SOME (term, ty) => term
        val termList =
            foldr 
              (fn (symbolFunEntry, listTerm) => 
                  makeMonoApply2 RD.stringCons (reifyFunEntry (dataL, exnL) symbolFunEntry) listTerm
              )
              nilTerm
              symbolFunEntryList
      in
        termList
      end

  fun reifyTopEnv exnConList (topEnv:V.topEnv as {Env, SigE, FunE}) =
      let
        val _ = exnConListRef := exnConList
        val (newEnv, envTerm) = 
            reifyEnv 
              (!ReflectionControl.maxNestLevel, !ReflectionControl.maxExnNestLevel)
              Env
        val Env = V.updateEnv(Env,newEnv)
        val funETerm = reifyFunE (!ReflectionControl.maxNestLevel, !ReflectionControl.maxExnNestLevel) FunE
        val sigETerm = reifySigE (!ReflectionControl.maxNestLevel, !ReflectionControl.maxExnNestLevel) SigE
        val tpexp = makeMonoApply3 RD.makeReifiedTopenv envTerm funETerm sigETerm
      in
        ({Env=Env, SigE=SigE, FunE=FunE}, tpexp)
      end
  val reify = fn arg => reify (!ReflectionControl.maxNestLevel, !ReflectionControl.maxExnNestLevel) arg
  val reifyEnv = fn arg => reifyEnv (!ReflectionControl.maxNestLevel, !ReflectionControl.maxExnNestLevel) arg
  val reifySigE = fn arg => reifySigE (!ReflectionControl.maxNestLevel, !ReflectionControl.maxExnNestLevel) arg
  val reifyFunE = fn arg => reifyFunE (!ReflectionControl.maxNestLevel, !ReflectionControl.maxExnNestLevel) arg
  val reifyExn = fn arg => reifyExn (!ReflectionControl.maxNestLevel, !ReflectionControl.maxExnNestLevel) arg
  fun exnToString () =
      let
        val newVarInfo = TCU.newTCVarInfo loc BT.exnTy
        val argVar = TC.TPVAR newVarInfo
        val bodyTerm = reifyExn argVar
        val printTerm = makeMonoApply RD.termToString bodyTerm
        val exnToStringFunTerm =
            TC.TPFNM {argVarList=[newVarInfo], 
                      bodyTy=BT.stringTy,
                      bodyExp=printTerm, 
                      loc=Loc.noloc}
      in
        makeMonoApply RD.updateExnToString exnToStringFunTerm
      end
end
end
