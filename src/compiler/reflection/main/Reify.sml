(**
 * @copyright (c) 2012- Tohoku University.
 * @author Atsushi Ohori
 *)
structure Reify =
struct
local
  fun bug s = Control.Bug ("Reiy:" ^ s)
  structure I = IDCalc
  structure T = Types
  structure ITy = EvalIty
  structure TC = TypedCalc
  structure TU = TypesUtils
  structure TCU = TypedCalcUtils
  structure TIU = TypeInferenceUtils
  structure RD = ReifiedTermData
  structure BE = BuiltinEnv
  structure V = NameEvalEnv
  structure BN = BuiltinName

  val idstatusWidth = 60
  val tstrWidth = 70
  val sigWidth = 75

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
      TC.TPCONSTANT {const=Absyn.STRING (string, Loc.noloc),
                     ty=BuiltinEnv.STRINGty,
                     loc=Loc.noloc}
  fun makeInt int =
      TC.TPCONSTANT {const=Absyn.INT (int, Loc.noloc),
                     ty=BuiltinEnv.INTty,
                     loc=Loc.noloc}
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
  fun reify (ty, tpexp) =
      case TU.derefTy ty of
      T.SINGLETONty _ => RD.unprintable()
    | T.ERRORty => RD.unprintable()
    | T.DUMMYty _ => RD.unprintable()
    | T.TYVARty _ => RD.unprintable()
    | T.BOUNDVARty _ => RD.unprintable()
    | T.FUNMty _ => RD.mkFUNtyRepTerm()
    | T.RECORDty tyLabelEnvMap =>
      let
        val stringTyList = LabelEnv.listItemsi tyLabelEnvMap
        fun reifyField (label, fieldTy) =
            let
              val fieldExp = 
                  TC.TPSELECT {label=label, 
                               exp=tpexp,
                               expTy=ty, 
                               resultTy=fieldTy, 
                               loc=Loc.noloc}
              val term = reify (fieldTy, fieldExp)
            in
              makeMonoApply2 RD.makeFieldTerm (makeString label) term
            end
        fun reifyElem (label, fieldTy) =
            let
              val fieldExp = 
                  TC.TPSELECT {label=label, 
                               exp=tpexp,
                               expTy=ty, 
                               resultTy=fieldTy,
                               loc=Loc.noloc}
            in
              reify (fieldTy, fieldExp)
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
          RD.mkTUPLEtyRepTerm
            (foldr
               (fn (field, fieldListTerm) =>
                   makeMonoApply2
                     RD.makeConsTerm
                     (reifyElem field)
                     fieldListTerm
               )
               reifiedTermNil
               stringTyList
            )
        else 
          RD.mkRECORDtyRepTerm
            (foldr
               (fn (field, fieldListTerm) =>
                   makeMonoApply2
                     RD.makeConsField
                     (reifyField field)
                     fieldListTerm
               )
               fieldNil
               stringTyList
            )
      end
    | T.CONSTRUCTty {tyCon=tyCon as {path,...}, args} =>
      reifyTyCon (tyCon, args, path, tpexp)
    | T.POLYty  {boundtvars, body} => RD.unprintable()
    (* FIXME: we can do someting more for poly *)

  and makeReifyFun ty =
      let
        val newVarInfo = TCU.newTCVarInfo ty
        val argVar = TC.TPVAR (newVarInfo, Loc.noloc)
        val mapBody = reify (ty, argVar)
        val bodyTy = reifiedTerm()
      in
        TC.TPFNM {argVarList=[newVarInfo], 
                  bodyTy=bodyTy,
                  bodyExp=mapBody, 
                  loc=Loc.noloc}
      end
  and makePolyReify argTys (makeTermVar, makeTermVarTy) exp =
      case argTys of
        [argTy] => 
        let
          val reifyFun = makeReifyFun argTy
          (* makeTermVar: ['a. ('a -> reifiedTerm) -> 'a tycon -> reifiedTerm *)
          val makeTermVarInst =
              TC.TPTAPP{exp=makeTermVar,
                        expTy=makeTermVarTy,
                        instTyList=[argTy],
                        loc=Loc.noloc}
           val instTy = TIU.instOfPolyTy(makeTermVarTy, [argTy])
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

  and reifyTyCon (tyCon, args, path, exp) =
      if eqTyCon(tyCon, BE.INTtyCon) then
        RD.mkINTtyRepTerm exp
      else if eqTyCon(tyCon, BE.lookupTyCon BN.boolTyName) then
        RD.mkBOOLtyRepTerm exp
      else if eqTyCon(tyCon, BE.INTINFtyCon) then
        RD.mkINTINFtyRepTerm exp
      else if eqTyCon(tyCon, BE.WORDtyCon) then
        RD.mkWORDtyRepTerm exp
      else if eqTyCon(tyCon, BE.WORD8tyCon) then
        RD.mkWORD8tyRepTerm exp
      else if eqTyCon(tyCon, BE.CHARtyCon) then
        RD.mkCHARtyRepTerm exp
      else if eqTyCon(tyCon, BE.PTRtyCon) then
        RD.mkPTRtyRepTerm ()
      else if eqTyCon(tyCon, BE.REALtyCon) then
        RD.mkREALtyRepTerm exp
      else if eqTyCon(tyCon, BE.REAL32tyCon) then
        RD.mkREAL32tyRepTerm exp
      else if eqTyCon(tyCon, BE.STRINGtyCon) then
        RD.mkSTRINGtyRepTerm exp
      else if eqTyCon(tyCon, BE.UNITtyCon) then
        RD.mkUNITtyRepTerm ()
      else if eqTyCon(tyCon, BE.EXNtyCon) then
        RD.mkEXNtyRepTerm ()
      else if eqTyCon(tyCon, BE.LISTtyCon()) then
        let
          val (makeTermVar, makeTermVarTy) = 
              case !RD.makeListTerm of
                SOME (var, ty) => (var, ty)
              | NONE => raise bug "makeListTerm not set"
        in
          makePolyReify args (makeTermVar, makeTermVarTy) exp
        end
      else if eqTyCon(tyCon, BE.ARRAYtyCon) then
        let
          val (makeTermVar, makeTermVarTy) = 
              case !RD.makeArrayTerm of
                SOME (var, ty) => (var, ty)
              | NONE => raise bug "makeArrayTerm not set"
        in
          makePolyReify args (makeTermVar, makeTermVarTy) exp
        end
      else if eqTyCon(tyCon, BE.EXNtyCon) then
        RD.mkEXNtyRepTerm ()
      else 
        let
          val pathName = String.concatWith "." path
          val pathNameTerm = makeString pathName
        in
          RD.mkCONSTRUCTtyRepTerm pathNameTerm
        end

  fun reifyIdstatus (name, idstatus) =
      case idstatus of
      I.IDVAR varId => NONE
    | I.IDVAR_TYPED _ => NONE
    | I.IDEXVAR {path, ty=ity, used, loc, version, internalId = SOME id} =>
      let
        val accessPath = I.setVersion(path, version)
        val tyTerm = makeString (prettyPrint idstatusWidth (I.print_ty (nil,nil) ity))
        val ty = ITy.evalIty ITy.emptyContext ity
        val nameTerm = makeString name
        val var = TC.TPVAR ({path=accessPath, ty=ty, id=id}, Loc.noloc)
        val reifiedTerm = reify (ty, var)
        val newIdstatus = 
            I.IDEXVAR {path=path, ty=ity, used=used, loc=loc, 
                       version=version, internalId = NONE}
      in
        SOME (newIdstatus, makeMonoApply3 RD.makeEXVAR nameTerm reifiedTerm tyTerm)
      end
    | I.IDEXVAR {path, ty, used, internalId = NONE, version,...} =>
      let
        val accessPath = I.setVersion(path, version)
        val tyTerm = makeString (prettyPrint idstatusWidth (I.print_ty (nil,nil) ty))
        val ty = ITy.evalIty ITy.emptyContext ty
        val nameTerm = makeString name
        val var = TC.TPEXVAR ({path=accessPath, ty=ty}, Loc.noloc)
        val reifiedTerm = reify (ty, var)
      in
        SOME (idstatus, makeMonoApply3 RD.makeEXVAR nameTerm reifiedTerm tyTerm)
      end
    | I.IDEXVAR_TOBETYPED _ => NONE
    | I.IDBUILTINVAR {primitive, ty} => 
      let
        val tyTerm = makeString (prettyPrint idstatusWidth (I.print_ty (nil,nil) ty))
        val nameTerm = makeString name
        val reifiedTerm = RD.builtin()
      in
        SOME (idstatus, makeMonoApply3 RD.makeEXVAR nameTerm reifiedTerm tyTerm)
      end
    | I.IDCON _ => NONE
    | I.IDEXN _ => NONE
    | I.IDEXNREP _ => NONE
    | I.IDEXEXN {path, ty, version,...} =>
      let
        val accessPath = I.setVersion(path, version)
        val ty = ITy.evalIty ITy.emptyContext ty
        val exnArgTy = 
            case ty of 
              T.FUNMty([argTy], _) => SOME argTy
            | _ => NONE
        val argTyTerm =
            case exnArgTy of 
              NONE => makeString ""
            | SOME argTy => makeString (prettyPrint idstatusWidth (T.format_ty nil argTy))
        val nameTerm = makeString name
      in
        SOME (idstatus, makeMonoApply2 RD.makeEXEXN nameTerm argTyTerm)
      end
    | I.IDEXEXNREP {path, ty, version,...} =>
      let
        val ty = ITy.evalIty ITy.emptyContext ty
        val pathTerm = makeString (String.concatWith "." path)
        val nameTerm = makeString name
      in
        SOME (idstatus, makeMonoApply2 RD.makeEXEXNREP nameTerm pathTerm)
      end
    | I.IDOPRIM _ => NONE
    | I.IDSPECVAR _ => NONE
    | I.IDSPECEXN _ => NONE
    | I.IDSPECCON => NONE

  fun reifyTstr (name, tstr) =
      let
        val name = SmlppgUtil.makeToken name
        val tyVal = 
            case tstr of
              V.TSTR tfun => makeString (prettyPrint tstrWidth (I.print_tfun (nil,name) tfun))
            | V.TSTR_DTY {tfun, varE, formals, conSpec} => 
              makeString (prettyPrint tstrWidth (I.print_tfun (SmlppgUtil.makeToken "DTY",name) tfun))
      in
        makeMonoApply2 RD.makeSigentry (makeString "") tyVal
      end

  fun reifyEnv (env:V.env as V.ENV {varE, tyE, strE=V.STR strE}) =
      let
        (* tyE *)
        val stringTstrList = SEnv.listItemsi tyE
        val termList = map reifyTstr stringTstrList
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
            SEnv.foldri
            (fn (name, {env, strKind}, (newStrE, listTermStrentry)) =>
                let
                  val nameTerm = makeString name
                  val (newEnv,envTerm) = reifyEnv env
                  val termStrEntry = makeMonoApply2 RD.makeStrentry nameTerm envTerm
                  val newStrE = SEnv.insert(newStrE, name, {env=newEnv, strKind=strKind})
                in
                  (newStrE, makeMonoApply2 RD.strentryCons termStrEntry listTermStrentry)
                end
            )
            (SEnv.empty, listTermStrentry)
            strE
        val strE = V.updateStrE(V.STR strE, V.STR newStrE)

        (* varE *)
        val listTermVarE = case !RD.idstatusNil of
                        NONE => raise bug "idstatusNil not set"
                      | SOME (term, ty) => term
        val (newVarE, listTermVarE) =
            SEnv.foldri
            (fn (name, idstatus, (newVarE, listTermVarE)) =>
                let
                  val termIdstatusOpt = reifyIdstatus (name, idstatus)
                in
                  case termIdstatusOpt of
                    NONE => (newVarE, listTermVarE)
                  | SOME(idstatus, term) => 
                    (SEnv.insert(newVarE, name, idstatus),
                     makeMonoApply2 RD.idstatusCons term listTermVarE
                    )
                end
            )
            (SEnv.empty,listTermVarE)
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
      | I.IDSPECCON => false

  fun filterVarE varE = 
      SEnv.foldri 
      (fn (name, idstatus, varE) => 
          if printableIdstatus idstatus then SEnv.insert(varE, name, idstatus)
          else varE
      )
      SEnv.empty
      varE
  fun filterEnv (V.ENV {varE, tyE, strE=V.STR strE}) =
      let
        val varE = filterVarE varE
        val strE = SEnv.map (fn {env, strKind} => {env=filterEnv env, strKind=strKind}) strE
      in
        V.ENV {varE=varE, tyE=tyE, strE=V.STR strE}
      end

  fun reifySigE (sigE:V.sigE) =
      let
        val sigE = SEnv.map filterEnv sigE
        val sigE = SEnv.listItemsi sigE
      in
        makeString (prettyPrint sigWidth (V.printTy_sigEList sigE))
      end
  fun reifyFunE (funE:V.funE) =
      let
        val stringList = SEnv.listKeys funE
        val nilTerm = case !RD.stringNil of
                        NONE => raise bug "funeNil not set"
                      | SOME (term, ty) => term
        val termList =
            foldr 
              (fn (name, listTerm) => 
                  makeMonoApply2 RD.stringCons (makeString name) listTerm
              )
              nilTerm
              stringList
      in
        termList
      end

  fun reifyTopEnv (topEnv:V.topEnv as {Env, SigE, FunE}) =
      let
        val (newEnv, envTerm) = reifyEnv Env
        val Env = V.updateEnv(Env,newEnv)
        val funETerm = reifyFunE FunE
        val sigETerm = reifySigE SigE
        val tpexp = makeMonoApply3 RD.makeReifiedTopenv envTerm funETerm sigETerm
      in
        ({Env=Env, SigE=SigE, FunE=FunE}, tpexp)
      end
end
end
