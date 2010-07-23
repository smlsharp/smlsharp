(**
 * TypedLambda normalization
 * @copyright (c) 2006, Tohoku University.
 * @author Huu-Duc Nguyen
 * @version $$
 *)
structure TLNormalization : TLNORMALIZATION =
struct
  structure PT = PredefinedTypes
  structure RC = RecordCalc
  structure T = Types
  structure TU = TypesUtils
  structure CT = ConstantTerm
  structure TLU = TypedLambdaUtils
  structure P = BuiltinPrimitive
  open TypedLambda
       
  fun newVar ty =
      let
        val id = VarID.generate ()
      in
        {displayName = "$" ^ VarID.toString id,
         ty = ty,
         varId = Types.INTERNAL id}
       end


  val CONTAG_LABEL = "0"
  val CONVAL_LABEL = "1"
  val DUMMY_LABEL = "1"

  val HD_LABEL = "1"
  val TL_LABEL = "2"
                    
  
  datatype constructionLayoutType = 
           FLAT_CONSTRUCT of ty  (*argRecordTy*)
         | NESTED_CONSTRUCT of ty  (*argTy*)
                    
  type varEnvEntry = {fromTy : ty, toTy: ty, castedTerm : tlexp}
                     
  type varEnv = varEnvEntry VarEnv.map
               
  val newVar = newVar

  val tyToString = TypeFormatter.tyToString

  val tagty = PT.intty

  fun isAtomicTyCon ({constructorHasArgFlagList,id, ...}:Types.tyCon) =
    case TyConID.Map.find (#runtimeTyEnv BuiltinContext.builtinContext, id) of
      SOME _ => true
    | NONE => List.all (fn hasArg => not hasArg) constructorHasArgFlagList
                  
  fun fieldTypes ty =
      case TU.derefTy ty of
        T.RECORDty tyfields => tyfields
      | _ => raise Control.Bug "Record type is expected"
                   
  fun expandFunTy ty =
      case TU.derefTy ty of
        T.FUNMty ([domTy], ranTy) => 
        (
         case TU.derefTy domTy of
           T.RECORDty flty => 
           let
             val keys = SEnv.listKeys flty
             val argTyList = SEnv.listItems flty
             val argLabelTyList = SEnv.listItemsi flty
             val newFunTy = T.FUNMty (argTyList, ranTy) 
           in
             (argLabelTyList, T.RECORDty flty, ranTy, newFunTy)
           end
         | ty => ([(DUMMY_LABEL, ty)], ty, ranTy, T.FUNMty ([ty], ranTy))
        )
      | _ => raise Control.Bug "Function type is expected"
                   
  val tagRecordType = T.RECORDty(SEnv.singleton(CONTAG_LABEL, tagty))
  val exntagRecordType = T.RECORDty(SEnv.singleton(CONTAG_LABEL, PT.exntagty))

  fun makeFlatConstructType tagty ty =
      case TU.derefTy ty of
        T.RECORDty tyfl => 
        T.RECORDty (SEnv.insert(tyfl, CONTAG_LABEL, tagty))
      | _ => raise Control.Bug "non record to makeFlatContructTypes"

  fun makeNestedConstructType tagty ty =
      T.RECORDty(SEnv.insert(SEnv.singleton(CONTAG_LABEL, tagty),
                             CONVAL_LABEL, ty))

  fun makeRefType elementTy = T.RAWty{tyCon = PT.refTyCon, args = [elementTy]}

  fun makeArrayType elementTy = 
      T.RAWty{tyCon = PT.arrayTyCon, args = [elementTy]}

  fun makeUnitVal loc = 
      TLCAST
          {
           exp = TLCONSTANT{value = CT.INT(Int32.fromInt 0), loc = loc},
           targetTy = PT.unitty,
           loc = loc
          }


  fun makeRefValIndex loc = 
      TLCONSTANT{value = CT.INT(Int32.fromInt 0), loc = loc}

  fun transformPrimOp ({name, ty}, instTyList) =
      let
        fun transformDomTy domTy =
            case TU.derefTy domTy of
              T.RECORDty flty =>
              if SEnv.isEmpty flty then [PT.unitty] else SEnv.listItems flty
            | ty => [ty]
        val newTy =
            case TU.derefTy(TU.tpappTy(ty, instTyList)) of
              T.FUNMty([domTy], ranTy) => T.FUNMty(transformDomTy domTy, ranTy)
            | _ => raise Control.Bug "non fun ty in primInfo"
      in
        {name = name, ty = newTy}
      end

  fun normalizeLetExp exp =
      case exp of 
        TLLET {localDeclList = localDeclList1, mainExp, loc} =>
        let
          val (newLocalDeclList, newMainExp) =
              case normalizeLetExp mainExp of
                TLLET {localDeclList = localDeclList2, mainExp, loc} =>
                (localDeclList1 @ localDeclList2, mainExp)
              | newMainExp => (localDeclList1, newMainExp)
        in
          case newLocalDeclList of
            [] => newMainExp
          | _ => TLLET {localDeclList = newLocalDeclList,
                        mainExp = newMainExp, loc = loc}
        end
      | _ => exp

  fun normalizeValDecl (decl as (TLVAL {boundVar, boundExp, loc})) =
      (
       case boundExp of
         TLLET {localDeclList, mainExp, ...} =>
         localDeclList 
         @
         [TLVAL {boundVar = boundVar, boundExp = mainExp, loc = loc}]
       | _ => [decl]
      )
    | normalizeValDecl decl = [decl]
      
  fun makePrimApply (primOp:RC.primInfo, instTyList, argExpList, loc) =
    case (#prim_or_special primOp, instTyList, argExpList) of
       (P.S P.List_first, _, [first, second]) => first
     | (P.S P.List_first, _, _) => raise Control.Bug "List_first"
     | (P.S P.Int_first, _, [first, second]) => first
     | (P.S P.Int_first, _, _) => raise Control.Bug "Int_first"
     | (P.S P.Real_second, _, [first, second]) => second
     | (P.S P.Real_second, _, _) => raise Control.Bug "Real_second"
     | (P.S P.Array_first, _, [first, second]) => first
     | (P.S P.Array_first, _, _) => raise Control.Bug "List_first"
     | (P.S P.List_second, _, [first, second]) => second
     | (P.S P.List_second, _, _) => raise Control.Bug "List_first"
     | (P.S P.Array_second, _, [first, second]) => second
     | (P.S P.Array_second, _, _) => raise Control.Bug "List_first"
     | (P.S P.Assign, [valueTy], [refExp, valueExp]) =>
      TLSETFIELD 
        {
         valueExp = valueExp,
         arrayExp = TLCAST {exp = refExp,
                            targetTy = makeArrayType valueTy,
                            loc = loc},
         indexExp = TLCONSTANT {value = CT.INT (Int32.fromInt 0), loc = loc},
         elementTy = valueTy,
         loc = loc
        }
    | (P.S P.Assign, _, _) => raise Control.Bug "Assign"
    | (P.S P.Array_array, [valueTy], [sizeExp, valueExp]) =>
      TLARRAY 
        {
         sizeExp = sizeExp, 
         initialValue = valueExp, 
         elementTy = valueTy,
         isMutable = true,
         loc = loc
        }
    | (P.S P.Array_array, _, _) => raise Control.Bug "Array_array"
    | (P.S P.Array_vector, [valueTy], [sizeExp, valueExp]) =>
      TLARRAY 
        {
         sizeExp = sizeExp, 
         initialValue = valueExp, 
         elementTy = valueTy,
         isMutable = false,
         loc = loc
        }
    | (P.S P.Array_vector, _, _) => raise Control.Bug "Vector_vector"
    | (P.S P.Array_sub_unsafe, [valueTy], [arrayExp, indexExp]) =>
      TLGETFIELD 
        {
         arrayExp = arrayExp, 
         indexExp = indexExp, 
         elementTy = valueTy, 
         loc = loc
        }
    | (P.S P.Array_sub_unsafe, _, _) => raise Control.Bug "Array_sub_unsafe"
    | (P.S P.Array_update_unsafe, [valueTy], [arrayExp, indexExp, valueExp]) =>
      TLSETFIELD 
        {
         valueExp = valueExp, 
         arrayExp = arrayExp, 
         indexExp = indexExp, 
         elementTy = valueTy, 
         loc=loc
        }
    | (P.S P.Array_update_unsafe, _, _) => 
      raise Control.Bug "Array_update_unsafe"
    | (
       P.S P.Array_copy_unsafe,
       [valueTy],
       [srcExp, srcIndexExp, dstExp, dstIndexExp, lengthExp]
      ) =>
      TLCOPYARRAY
        {
         srcExp = srcExp,
         srcIndexExp = srcIndexExp, 
         dstExp = dstExp,
         dstIndexExp = dstIndexExp,
         lengthExp = lengthExp,
         elementTy = valueTy, 
         loc=loc
        }
    | (P.S P.Array_copy_unsafe, _, _) => raise Control.Bug "Array_copy_unsafe"
    | (P.P prim, _, _) => 
      TLPRIMAPPLY 
        {
         primInfo = transformPrimOp ({name = prim, ty = #ty primOp}, 
                                     instTyList), 
         argExpList = argExpList, 
         instTyList = instTyList,
         loc = loc
        }

  fun makeConstruct (exp, externalTy, loc) =
    case externalTy of
      T.POLYty {boundtvars, body} =>
      TLPOLY
        {
         btvEnv = boundtvars,
         expTyWithoutTAbs = body,
         exp = TLCAST {exp = exp, targetTy = body, loc = loc},
         loc = loc
        }
    | _ => TLCAST {exp = exp, targetTy = externalTy, loc = loc}

  fun isRefTy ty = 
    case TU.derefTy ty of
      T.RAWty{tyCon, ...} =>
        TyConID.eq (#id PT.refTyCon, #id tyCon)
    | _ => false

  fun isFlattened ty =
    case TU.derefTy ty of
      (T.FUNMty ([argTy], _)) => 
      (
       case TU.derefTy argTy of
         T.RECORDty tyfields =>
         if SEnv.numItems tyfields < (!Control.limitOfBlockFields)
         then true 
         else false
       | _ => false
      )
    | (T.POLYty {body, ...}) => isFlattened body
    | _ => false

  fun constructionLayout (ty, instTyList) =
    let
      val argTy = 
          case TU.derefTy(TU.tpappTy(ty,instTyList)) of
            (T.FUNMty ([argTy],_)) => argTy
          | _ => 
            raise 
              Control.Bug 
                "non FUNMty in constructionLayout\
                \ (tlnormalization/main/TLNormalization.sml)"
    in
      if isFlattened ty 
      then FLAT_CONSTRUCT (TU.derefTy argTy)
      else NESTED_CONSTRUCT (TU.derefTy argTy)
    end

  fun makeLetExp (boundVar, boundExp, mainExp, loc) =
    TLLET
      {
       localDeclList = [TLVAL {boundVar = boundVar,
                               boundExp = boundExp,
                               loc = loc}],
       mainExp = mainExp,
       loc = loc
      }

  fun makeTagExpForDataCon  (con : Types.conInfo) loc =
    TLCONSTANT{value = CT.INT(Int32.fromInt(#tag con)), loc = loc}

  fun makeTagExpForExnCon (exn : Types.exnInfo) loc =
    TLEXCEPTIONTAG{tagValue = (#tag exn), displayName = #displayName exn,
                   loc = loc}

  fun makeLocalBind (boundExp, boundTy, loc) K =
    case boundExp of
      TLVAR _ => K boundExp
    | _ =>
      let
        val boundVar = newVar boundTy
      in
        makeLetExp(boundVar,
                   boundExp,
                   K (TLVAR {varInfo = boundVar, loc = loc}), 
                   loc)
      end

  fun transformExp vEnv rexp =
    case rexp of
      RC.RCFOREIGNAPPLY 
        {
         funExp, 
         funTy, 
         instTyList = nil, 
         argExpList = nil, 
         argTyList = nil, 
         attributes, 
         loc
        } => 
      TLFOREIGNAPPLY
        {
         funExp = transformExp vEnv funExp, 
         funTy = funTy,
         argExpList = nil, 
         attributes = attributes,
         loc = loc
        }                  
    | RC.RCFOREIGNAPPLY 
        {
         funExp, 
         funTy, 
         instTyList = nil, 
         argExpList = [argExp], 
         argTyList = [argTy], 
         attributes, 
         loc
        } => 
      TLFOREIGNAPPLY
        {
         funExp = transformExp vEnv funExp,
         funTy = funTy,
         argExpList = [transformExp vEnv argExp], 
         attributes = attributes,
         loc = loc
        }
    | RC.RCFOREIGNAPPLY 
        {
         funExp,
         funTy,
         instTyList = nil,
         argExpList, 
         argTyList, 
         attributes,
         loc
        } => 
      TLFOREIGNAPPLY
        {
         funExp = transformExp vEnv funExp,
         funTy = funTy,
         argExpList = map (transformExp vEnv) argExpList, 
         attributes = attributes,
         loc = loc
        }
      
    | RC.RCFOREIGNAPPLY _ => raise Control.Bug "ill formed foreign function"
                                   
    | RC.RCEXPORTCALLBACK {funExp, argTyList, resultTy, attributes, loc} =>
      TLEXPORTCALLBACK
        {
         funExp = transformExp vEnv funExp,
         funTy = T.FUNMty (argTyList, resultTy),
         attributes = attributes,
         loc = loc
        }

    | RC.RCSIZEOF (ty, loc) => TLSIZEOF {ty = ty, loc = loc}

    | RC.RCCONSTANT (UNIT, loc) => makeUnitVal loc

    | RC.RCCONSTANT (constant, loc) => TLCONSTANT {value = constant, loc = loc}

    | RC.RCGLOBALSYMBOL (name, kind, ty, loc) =>
      TLGLOBALSYMBOL {name=name,kind=kind,ty=ty,loc=loc}

    | RC.RCVAR (varInfo as {ty, ...}, loc) =>
      (
       case VarEnv.find(vEnv, varInfo) of
         SOME {argRecordTy, flatConstructTy, castedTerm}
         =>
         (*
          * Here we reconstruct a record.
          * This may become unnecessary when we implement
          * type-directed equality compilation.
          *
          * This is for a case expression someting like:
          *     datatype foo = D of int * int 
          *     val w = D (1,2)
          *     case w of 
          *       D (x as (y,z)) => (y,z,x)
          *       ...
          * This is compiled to
          *     case w of
          *       switch (cast w: {"0":tag})["0"] of
          *           D => ((cast w: {"0" : tag, "1" : int, "2" : int})["1"], 
          *                 (cast w: {"0" : tag, "1" : int, "2" : int})["2"], 
          *                 ((cast w: {"0" : tag, "1" : int, "2" : int})["1"], 
          *                  (cast w: {"0" : tag, "1" : int, "2" : int})["2"])
          *                )
          * with the vEnv = {x => (cast x from foo
                                   to {"0" : tag, "1" : int, "2" : int})}
          * This is the case for "x" in "(y,z,x)".
          *)
          let
            fun makeFieldExp (label, fieldTy) =
                TLSELECT {recordExp = castedTerm, 
                          label = label, 
                          recordTy = flatConstructTy, 
                          resultTy = fieldTy,
                          loc = loc}
          in
            TLRECORD
              {
               isMutable = false,
               expList = map
                           makeFieldExp
                           (SEnv.listItemsi (fieldTypes argRecordTy)),
               recordTy = argRecordTy,
               loc=loc
              }
          end
       | NONE => TLVAR {varInfo = varInfo, loc = loc}
      )

    | RC.RCGETFIELD (arrayExp, index, elementTy, loc) => 
      TLGETFIELD
        {
         arrayExp = transformExp vEnv arrayExp,
         indexExp = TLCONSTANT {value = CT.INT (Int32.fromInt index),
                                loc = loc},
         elementTy = elementTy,
         loc = loc
        }

    | RC.RCARRAY {sizeExp, initExp, elementTy , resultTy, loc}  => 
      TLARRAY
        {
         sizeExp = transformExp vEnv sizeExp,
         initialValue = transformExp vEnv initExp,
         elementTy = elementTy,
         isMutable = true,
         loc = loc
        }

    | RC.RCPRIMAPPLY
        {primOp,
         instTyList,
         argExpOpt = SOME (RC.RCRECORD {fields, loc = argLoc,...}), 
         loc} =>
      (
       case SEnv.listItems fields of
         [] => 
         makePrimApply (primOp, instTyList, [makeUnitVal argLoc], loc )
       | argExpList =>
         makePrimApply 
           (primOp,
            instTyList,
            map (transformExp vEnv) argExpList , 
            loc)
      )
    | RC.RCPRIMAPPLY
        {primOp as {ty,...}, instTyList, argExpOpt = SOME argExp, loc} =>
      (* We inline the primitive, i.e.
       * op x => op (x[1], x[2], ...)
       * for any op with more than one arguments.
       *)
        let
          val (argLabelTyList, domTy, ranTy, newFunTy) =
              expandFunTy (TU.tpappTy (ty, instTyList))
        in
          case argLabelTyList of
            [] => makePrimApply (primOp, instTyList, [makeUnitVal loc], loc )
          | [(l,_)] => makePrimApply
                         (primOp, instTyList, [transformExp vEnv argExp],loc)
          | _ =>
            let
              val newArgExp = transformExp vEnv argExp
              fun K var = 
                  let
                    val argExpList = 
                        map
                        (fn (label, argTy) => 
                         TLSELECT {recordExp = var, 
                                   label = label, 
                                   recordTy = domTy, 
                                   resultTy = argTy,
                                   loc = loc})
                        argLabelTyList
                  in
                    makePrimApply (primOp, instTyList, argExpList, loc)
                  end
            in
              makeLocalBind (newArgExp, domTy, loc) K
            end
        end
    | RC.RCPRIMAPPLY {primOp = {ty = T.FUNMty _, ...},
                      argExpOpt = NONE, ...} =>
      raise Control.Bug "primop should have been eta-expanded."
    | RC.RCPRIMAPPLY {argExpOpt=NONE, ...} => 
      raise Control.Bug "there should not be a constant primitive."
    | RC.RCOPRIMAPPLY _ => 
      raise
        Control.Bug 
          "OPRIMAPPLY in tlnormalization"
    | RC.RCDATACONSTRUCT
        {con as {funtyCon = true, ...}, argExpOpt = NONE, ...} =>
      raise Control.Bug "funtycon but no args"
    | RC.RCEXNCONSTRUCT
        {exn as {funtyCon = true, ...}, argExpOpt = NONE, ...} =>
      raise Control.Bug "funtycon but no args"
    | RC.RCDATACONSTRUCT
        {con as {ty, ...},  instTyList, argExpOpt=NONE, loc} =>
      let
        val externalTy = TU.derefTy (TU.tpappTy(ty, instTyList))
        val isAtom = 
            case TU.derefTy externalTy of
              T.RAWty {tyCon, ...}=> isAtomicTyCon tyCon
            | T.POLYty{body = T.RAWty {tyCon, ...},...} => isAtomicTyCon tyCon
            | _ => false
      in
        if isAtom then
          makeConstruct 
          (
           makeTagExpForDataCon con loc,
           externalTy,
           loc
           )             
(*
          TLCAST 
            {
             exp = makeTagExpForDataCon con loc, 
             targetTy = externalTy,
             loc = loc
            }
*)
        else
          makeConstruct
            (
             TLRECORD 
               {
                isMutable = false,
                expList = [makeTagExpForDataCon con loc], 
                recordTy = tagRecordType,
                loc = loc
               },
             externalTy,
             loc
            )
      end
(*
          if TU.isBoxedType externalTy
          then
            makeConstruct
                (
                 TLRECORD 
                     {
                      isMutable = false,
                      expList = [makeTagExpForDataCon con loc], 
                      recordTy = tagRecordType,
                      loc = loc
                     },
                 externalTy,
                 loc
                )
          else 
            TLCAST 
                {
                 exp = makeTagExpForDataCon con loc, 
                 targetTy = externalTy,
                 loc = loc
                }
        end
*)
    | RC.RCEXNCONSTRUCT
        {exn as {ty, ...},  instTyList, argExpOpt=NONE, loc} =>
      let
        val externalTy = TU.derefTy (TU.tpappTy(ty, instTyList))
      in
        makeConstruct
          (
           TLRECORD 
             {
              isMutable = false,
              expList = [makeTagExpForExnCon exn loc], 
              recordTy = exntagRecordType,
              loc = loc
             },
           externalTy,
           loc
          )
      end
(*
          if TU.isBoxedType externalTy
          then
            makeConstruct
                (
                 TLRECORD 
                     {
                      isMutable = false,
                      expList = [makeTagExpForExnCon exn loc], 
                      recordTy = tagRecordType,
                      loc = loc
                     },
                 externalTy,
                 loc
                )
          else 
            TLCAST 
                {
                 exp = makeTagExpForExnCon exn loc, 
                 targetTy = externalTy,
                 loc = loc
                }
        end
*)
    | RC.RCDATACONSTRUCT
        {con as {funtyCon = false, ...}, argExpOpt = SOME _,...} =>
      raise Control.Bug "nonfuntycon with args"
    | RC.RCEXNCONSTRUCT
        {exn as {funtyCon = false, ...}, argExpOpt = SOME _,...} =>
      let
        val _  =
            print (Control.prettyPrint (RecordCalc.format_rcexp nil rexp))
      in
        raise Control.Bug "nonfuntycon with args"
      end
    | RC.RCDATACONSTRUCT
        {con as {ty, tyCon, ...},
         instTyList,
         argExpOpt = SOME argExp, loc} =>
      let 
        val externalTy = 
            case TU.derefTy (TU.tpappTy(ty, instTyList)) of
              T.FUNMty (argTyList, bodyTy) => bodyTy
            | _ => raise Control.Bug "invalid type"
      in
        if TyConID.eq(#id PT.refTyCon, #id tyCon)
        then
          case instTyList of
            [elementTy] =>
            TLCAST
              {
               exp = TLARRAY 
                       {
                        sizeExp = TLCONSTANT
                                    {value = CT.INT (Int32.fromInt 1),
                                     loc = loc}, 
                        initialValue = transformExp vEnv argExp, 
                        elementTy = elementTy,
                        isMutable = true,
                        loc = loc
                       },
               targetTy = externalTy,
               loc = loc
              }
          | _ => raise Control.Bug "ref constructor expects one argument."
        else
          let
            val newExp =
                case constructionLayout(ty, instTyList) of
                  FLAT_CONSTRUCT argTy =>
                  (
                   case argExp of 
                     RC.RCRECORD {fields,...} => 
                     TLRECORD
                       {
                        isMutable = false,
                        expList = 
                          (makeTagExpForDataCon con loc)
                          ::(map (transformExp vEnv) (SEnv.listItems fields)),
                        recordTy = makeFlatConstructType tagty argTy,
                        loc = loc
                        }
                   | _ =>
                     let
                       val newArgExp = transformExp vEnv argExp
                       fun K var =
                         let
                           val argExpList = 
                             map
                               (fn (label,fieldTy) =>
                                   TLSELECT {recordExp = var, 
                                             label = label, 
                                             recordTy = argTy, 
                                             resultTy = fieldTy,
                                             loc = loc}
                               )
                               (SEnv.listItemsi (fieldTypes argTy))
                         in
                           TLRECORD
                             {
                              isMutable = false,
                              expList = (makeTagExpForDataCon con loc)
                                        ::argExpList,
                              recordTy = makeFlatConstructType tagty argTy,
                              loc = loc
                             }
                         end
                     in
                       makeLocalBind (newArgExp, argTy, loc) K
                     end
                  )
                | NESTED_CONSTRUCT argTy =>
                  TLRECORD
                    {
                     isMutable = false,
                     expList = [makeTagExpForDataCon con loc,
                                transformExp vEnv argExp],
                     recordTy = makeNestedConstructType tagty argTy,
                     loc = loc
                    }
          in
            makeConstruct (newExp, externalTy, loc)
          end
      end
    | RC.RCEXNCONSTRUCT
        {exn as {ty, tyCon, ...}, instTyList, argExpOpt = SOME argExp, loc} =>
      let 
        val externalTy = 
            case TU.derefTy (TU.tpappTy(ty, instTyList)) of
              T.FUNMty (argTyList, bodyTy) => bodyTy
            | _ => raise Control.Bug "invalid type"
      in
        if TyConID.eq(#id PT.refTyCon, #id tyCon)
        then
          case instTyList of
            [elementTy] =>
            TLCAST
              {
               exp = TLARRAY 
                       {
                        sizeExp = TLCONSTANT{value = CT.INT (Int32.fromInt 1),
                                             loc = loc}, 
                        initialValue = transformExp vEnv argExp, 
                        elementTy = elementTy,
                        isMutable = true,
                        loc = loc
                       },
               targetTy = externalTy,
               loc = loc
              }
          | _ => raise Control.Bug "ref constructor expects one argument."
        else
          let
            val newExp =
                case constructionLayout(ty, instTyList) of
                  FLAT_CONSTRUCT argTy =>
                  (
                   case argExp of 
                     RC.RCRECORD {fields,...} => 
                     TLRECORD
                       {
                        isMutable = false,
                        expList = (makeTagExpForExnCon exn loc)
                                  ::(map
                                       (transformExp vEnv)
                                       (SEnv.listItems fields)),
                        recordTy = makeFlatConstructType PT.exntagty argTy,
                        loc = loc
                       }
                   | _ =>
                     let
                       val newArgExp = transformExp vEnv argExp
                       fun K var =
                         let
                           val argExpList = 
                             map
                               (fn (label,fieldTy) =>
                                   TLSELECT {recordExp = var, 
                                             label = label, 
                                             recordTy = argTy, 
                                             resultTy = fieldTy, 
                                             loc = loc}
                               )
                               (SEnv.listItemsi (fieldTypes argTy))
                         in
                           TLRECORD
                             {
                              isMutable = false,
                              expList = (makeTagExpForExnCon exn loc)
                                        ::argExpList,
                              recordTy = makeFlatConstructType
                                           PT.exntagty argTy,
                              loc = loc
                             }
                         end
                     in
                       makeLocalBind (newArgExp, argTy, loc) K
                     end
                  )
                | NESTED_CONSTRUCT argTy =>
                  TLRECORD
                    {
                     isMutable = false,
                     expList = [makeTagExpForExnCon exn loc,
                                transformExp vEnv argExp],
                     recordTy = makeNestedConstructType PT.exntagty argTy,
                     loc = loc
                    }
          in
            makeConstruct (newExp, externalTy, loc)
          end
      end
    | RC.RCAPPM {funExp, funTy, argExpList, loc}  =>
      TLAPPM 
        {
         funExp = transformExp vEnv funExp, 
         funTy = funTy, 
         argExpList = map (transformExp vEnv) argExpList, 
         loc = loc
        }

    | RC.RCMONOLET {binds, bodyExp, loc} =>
      let
        val localDeclList =
            map 
              (fn (v, e) =>
                  TLVAL {boundVar = v,
                         boundExp = transformExp vEnv e,
                         loc = loc} )
              binds
      in
        normalizeLetExp
          (
           TLLET
             {
              localDeclList = localDeclList,
              mainExp = transformExp vEnv bodyExp, 
              loc = loc
             }
          )              
      end

    | RC.RCLET (localDeclList, expList, tyList, loc) =>
      let
        val localDeclList = transformDeclList vEnv localDeclList
        val revExpList = rev (map (transformExp vEnv) expList)
        val revTyList = rev tyList
        val mainExp = List.hd revExpList
        val localExpList = rev(List.tl revExpList)
        val localTyList = rev(List.tl revTyList)
        val declList =
          ListPair.map 
            (fn (exp,ty) =>
                TLVAL {boundVar = newVar ty, boundExp = exp, loc = loc}
            )
            (localExpList,localTyList)
      in
        normalizeLetExp
          (
           TLLET 
             {
              localDeclList = localDeclList @ declList,
              mainExp = mainExp, 
              loc = loc
             }
          )
      end

    | RC.RCRECORD {fields, recordTy, loc} => 
      TLRECORD 
        {
         isMutable = false,
         expList = map (transformExp vEnv) (SEnv.listItems fields), 
         recordTy = recordTy, 
         loc = loc
        }

    | RC.RCSELECT {exp, label, expTy, resultTy, loc} =>
      let
        val (recordTy, recordExp) =
            case exp of
              RC.RCVAR (varInfo, loc) =>
              (case VarEnv.find(vEnv, varInfo) of
                 SOME {argRecordTy, flatConstructTy, castedTerm} =>
                 (flatConstructTy, castedTerm)
               | _ => (expTy, TLVAR {varInfo = varInfo, loc = loc}))
            | _ => (expTy, transformExp vEnv exp)
      in
        TLSELECT {recordExp = recordExp, 
                  label = label, 
                  recordTy = recordTy, 
                  resultTy = resultTy, 
                  loc = loc}
      end

    | RC.RCMODIFY {label, recordExp, recordTy, elementExp, elementTy, loc} =>
      TLMODIFY
        {
         recordExp = transformExp vEnv recordExp,
         recordTy = recordTy,
         label = label,
         valueExp = transformExp vEnv elementExp,
         loc = loc
        }

    | RC.RCRAISE (exp, ty, loc) => 
      TLRAISE 
        {
         argExp = transformExp vEnv exp, 
         resultTy = ty, 
         loc = loc
        }

    | RC.RCHANDLE {exp, exnVar, handler, loc} =>
      TLHANDLE
        {
         exp = transformExp vEnv exp, 
         exnVar = exnVar, 
         handler = transformExp vEnv handler, 
         loc = loc
        }

    | RC.RCCASE {exp, expTy, ruleList, defaultExp, loc} =>
      (* Here, a case expression is translated into a switch expression.
       * (1) case e of ref x => exp
       *   ==> let x = e[0] in exp end 
       * (2) case e of A x => exp  (where the span of the type of e is 1)
       *   ==> let x = e in exp
       * (3) case e of  .... C x => exp ...,
       *   case (a)  C : (t0,...,tn) -> foo
       *     ==> let x = e in 
       *         switch x[0] of
       *                ...
       *           i => exp[cast(x)/x]
       *     where cast(x) is treated as follows:
       *       the type of x => (tag, t0, ..., tn)
       *                       (flattened record with inlied tag)
       *        x[i] => x[i+1]
       *        x => (x[1], ..., x[n+1])
       *   case (b) C : tau -> foo (where tau is non-record type)
       *     ==> let x = e in 
       *         switch x[0] of
       *                ...
       *           i => let x = x[1] in exp
       *)
      if isRefTy expTy 
      then
        case (ruleList, TU.derefTy expTy) of
          ([(c, SOME boundVar, mainExp)],
           T.RAWty{tyCon, args = [elementTy]}) =>
          let 
            val boundExp =
                TLGETFIELD
                  {
                   arrayExp =  TLCAST 
                                 {
                                  exp = transformExp vEnv exp, 
                                  targetTy = makeArrayType elementTy, 
                                  loc = loc
                                 }, 
                   indexExp = makeRefValIndex loc,
                   elementTy = elementTy,
                   loc = loc
                  }
            val mainExp = transformExp vEnv mainExp
          in
            makeLetExp (boundVar, boundExp, mainExp, loc)
          end
        | _ => raise Control.Bug "multiple rules for ref tycon"
      else
        let
          val (isAtom, tyArgList) = 
              case TU.derefTy expTy of
                T.RAWty {tyCon, args} => (isAtomicTyCon tyCon, args)
              | _ => raise Control.Bug "RAWty is expected"
          val newExp = transformExp vEnv exp
          fun K selector =
            let
              val switchExp = 
                if isAtom then 
                  TLCAST{exp = selector, 
                         targetTy = tagty, 
                         loc = loc}
                else
                  TLSELECT 
                    {
                     recordExp = TLCAST{exp = selector, 
                                        targetTy = tagRecordType, 
                                        loc = loc},
                     label = CONTAG_LABEL,
                     recordTy = tagRecordType,
                     resultTy = tagty,
                     loc=loc
                     }
              fun processRule
                    (con, SOME (varInfo as {ty = argTy,...}), body) = 
                  (
                   case constructionLayout (#ty con,tyArgList) of
                     FLAT_CONSTRUCT _ =>
                     let
                       val flatConstructTy = makeFlatConstructType tagty argTy
                       val varEnvEntry =
                           {
                            argRecordTy = argTy,
                            flatConstructTy = flatConstructTy,
                            castedTerm = TLCAST {exp = selector,
                                                 targetTy = flatConstructTy,
                                                 loc = loc}
                           }
                       val newVarEnv =
                           VarEnv.insert(vEnv, varInfo, varEnvEntry)
                     in
                       {
                        constant = makeTagExpForDataCon con loc, 
                        exp = transformExp newVarEnv body
                       }
                     end
                   | NESTED_CONSTRUCT _ =>
                     let
                       val nestedConstructTy =
                           makeNestedConstructType tagty argTy
                       val boundExp =
                           TLSELECT
                             {
                              recordExp = TLCAST{exp = selector, 
                                                 targetTy = nestedConstructTy, 
                                                 loc = loc},
                              recordTy = nestedConstructTy,
                              resultTy = argTy,
                              label = CONVAL_LABEL,
                              loc = loc
                             }
                     in
                       {
                        constant = makeTagExpForDataCon con loc, 
                        exp = makeLetExp 
                                (varInfo, boundExp, transformExp vEnv body, loc)
                       }
                     end
                  )
                | processRule (con, NONE, body) =
                  {
                   constant = makeTagExpForDataCon con loc, 
                   exp = transformExp vEnv body
                  }
            in
              TLSWITCH
                {
                 switchExp = switchExp, 
                 expTy = tagty, 
                 branches = map processRule ruleList, 
                 defaultExp = transformExp vEnv defaultExp, 
                 loc =loc
                }
            end
        in
          makeLocalBind (newExp, expTy, loc) K
        end

    | RC.RCEXNCASE {exp, expTy, ruleList, defaultExp, loc} =>
      if isRefTy expTy 
      then
        case (ruleList, TU.derefTy expTy) of
          ([(c, SOME boundVar, mainExp)],
           T.RAWty{tyCon, args = [elementTy]}) =>
          let 
            val boundExp =
              TLGETFIELD
                {
                 arrayExp =  TLCAST 
                               {
                                exp = transformExp vEnv exp, 
                                targetTy = makeArrayType elementTy, 
                                loc = loc
                               }, 
                 indexExp = makeRefValIndex loc,
                 elementTy = elementTy,
                 loc = loc
                }
            val mainExp = transformExp vEnv mainExp
          in
            makeLetExp (boundVar, boundExp, mainExp, loc)
          end
        | _ => raise Control.Bug "multiple rules for ref tycon"
      else
        (
         case TU.derefTy expTy of
           T.RAWty {tyCon, args = tyArgList} => 
           let
             val newExp = transformExp vEnv exp
             fun K selector =
                 let
                   (* exn type is always boxed *)
             val switchExp = 
                 TLSELECT 
                   {
                    recordExp = TLCAST{exp = selector,
                                       targetTy = exntagRecordType,
                                       loc = loc},
                    label = CONTAG_LABEL,
                    recordTy = exntagRecordType,
                    resultTy = PT.exntagty,
                    loc=loc
                   }
             fun processRule (con, SOME (varInfo as {ty = argTy,...}), body) = 
                 (
                  case constructionLayout (#ty con,tyArgList) of
                    FLAT_CONSTRUCT _ =>
                    let
                      val flatConstructTy =
                          makeFlatConstructType PT.exntagty argTy
                      val varEnvEntry =
                          {
                           argRecordTy = argTy,
                           flatConstructTy = flatConstructTy,
                           castedTerm = TLCAST {exp = selector, 
                                                targetTy = flatConstructTy, 
                                                loc = loc}
                          }
                      val newVarEnv = VarEnv.insert(vEnv, varInfo, varEnvEntry)
                    in
                      {
                       constant = makeTagExpForExnCon con loc, 
                       exp = transformExp newVarEnv body
                      }
                    end
                  | NESTED_CONSTRUCT _ =>
                    let
                      val nestedConstructTy =
                          makeNestedConstructType PT.exntagty argTy
                      val boundExp =
                          TLSELECT
                            {
                             recordExp = TLCAST{exp = selector, 
                                                targetTy = nestedConstructTy, 
                                                loc = loc},
                             recordTy = nestedConstructTy,
                             resultTy = argTy,
                             label = CONVAL_LABEL,
                             loc = loc
                            }
                    in
                      {
                       constant = makeTagExpForExnCon con loc, 
                       exp = makeLetExp 
                               (varInfo, boundExp, transformExp vEnv body, loc)
                      }
                    end
                 )
               | processRule (con, NONE, body) =
                 {
                  constant = makeTagExpForExnCon con loc, 
                  exp = transformExp vEnv body
                 }
                 in
                   TLSWITCH
                     {
                      switchExp = switchExp, 
                      expTy = PT.exntagty, 
                      branches = map processRule ruleList, 
                      defaultExp = transformExp vEnv defaultExp, 
                      loc =loc
                      }
                 end
           in
             makeLocalBind (newExp, expTy, loc) K
           end
         | _ => raise Control.Bug "RAWty is expected")
    | RC.RCSWITCH {switchExp, expTy, branches, defaultExp, loc} =>
      TLSWITCH
        {
         switchExp = transformExp vEnv switchExp,
         expTy = expTy,
         branches = map 
                      (fn (c, e) => 
                          ({constant = TLCONSTANT{value = c ,loc = loc},
                            exp = transformExp vEnv e})
                      )
                      branches,
         defaultExp = transformExp vEnv defaultExp,
         loc = loc
        }

    | RC.RCFNM {argVarList, bodyTy, bodyExp, loc} =>
      TLFNM 
        {
         argVarList = argVarList, 
         bodyTy = bodyTy, 
         bodyExp = transformExp vEnv bodyExp, 
         loc = loc
        }

    | RC.RCPOLYFNM {btvEnv, argVarList, bodyTy, bodyExp, loc} => 
      TLPOLY
        {
         btvEnv = btvEnv,
         expTyWithoutTAbs = T.FUNMty (map #ty argVarList, bodyTy),
         exp =
         TLFNM
           {
            argVarList = argVarList,
            bodyTy = bodyTy,
            bodyExp = transformExp vEnv bodyExp,
            loc = loc
           },
         loc = loc
        }

    | RC.RCPOLY {btvEnv, expTyWithoutTAbs, exp, loc} => 
      TLPOLY
        {
         btvEnv = btvEnv,
         expTyWithoutTAbs = expTyWithoutTAbs,
         exp = transformExp vEnv exp,
         loc = loc
        }

    | RC.RCTAPP {exp, expTy, instTyList, loc} => 
      let
        val resultTy = TU.derefTy(TU.tpappTy(expTy, instTyList))
(*
        val isAtom = 
            case TU.derefTy resultTy of
              T.RAWty {tyCon, ...} => isAtomicTyCon tyCon
            | T.POLYty{body = T.RAWty {tyCon, ...},...} => isAtomicTyCon tyCon
            | _ => false
*)
      in
(*
        if isAtom then
          TLCAST
            {
             exp = transformExp vEnv exp,
             targetTy = resultTy,
             loc = loc
            }
        else
*)
          TLTAPP
            {
             exp = transformExp vEnv exp,
             expTy = expTy,
             instTyList = instTyList,
             loc = loc
            }
      end
(*
         if TU.isBoxedType resultTy 
         then
         (* Liu :in separate/functor compilation mode,
          *  if boxedKind = GENERICty  then adopt this case ?
          * temparary fix for mlyacc. 
          *)
           TLTAPP
           {
            exp = transformExp vEnv exp,
            expTy = expTy,
            instTyList = instTyList,
            loc = loc
           }
         else (* this is the case of datatype -> int*)
           TLCAST
           {
            exp = transformExp vEnv exp,
            targetTy = resultTy,
            loc = loc
           }
         end
*)

    | RC.RCSEQ {expList, expTyList, loc} =>
      (
       case expList of
         [] => raise Control.Bug "ill formed sequent expression"
       | [exp] => transformExp vEnv exp
       | _ =>
         let
           val expList = map (transformExp vEnv) expList
           val expListRev = rev expList
           val tyListRev = rev expTyList
           val mainExp = hd expListRev
           val (localExpList, localTyList) =
               (rev(tl expListRev),rev (tl tyListRev))
           fun makeDecl (exp,ty) =
               TLVAL {boundVar = newVar ty, boundExp = exp, loc = loc}
         in
           TLLET
             {
              localDeclList = ListPair.map 
                                makeDecl
                                (localExpList, localTyList),
              mainExp = mainExp,
              loc = loc
             }
         end
      )

    | RC.RCLIST {expList, listTy, loc} =>
      let
        val elemTy = 
            case listTy of
              T.RAWty{tyCon, args=[elemTy]} => elemTy
            | _ => raise Control.Bug "TLNormalization : list type exprected"
        fun makeNil loc = 
            makeConstruct 
              (
               TLRECORD 
                 {
                  isMutable = false,
                  expList = [makeTagExpForDataCon
                               (T.conPathInfoToConInfo PT.nilConPathInfo)
                               loc], 
                  recordTy = tagRecordType,
                  loc = loc
                 },
               listTy,
               loc
              )
        val consRecordTy = 
            T.RECORDty
             (SEnv.fromList[
                            (CONTAG_LABEL, tagty),
                            (HD_LABEL, elemTy),
                            (TL_LABEL, listTy)
                            ])

        fun makeNilCons consExp = 
          let
            val loc = TLU.getLocOfExp consExp 
            val newExp = 
              TLRECORD
                {
                 isMutable = true,
                 expList = [makeTagExpForDataCon
                              (T.conPathInfoToConInfo PT.consConPathInfo) 
                              loc,
                            consExp, 
                            makeNil loc],
                 recordTy = consRecordTy,
                 loc = loc
                 }
          in
            makeConstruct (newExp, listTy, loc)
          end
            
        fun makeSetTail (consExp, newTailExp) = 
            TLSETTAIL{
                      consExp = consExp,
                      newTailExp = newTailExp,
                      listTy = listTy,
                      consRecordTy = consRecordTy,
                      tailLabel = TL_LABEL,
                      loc = TLU.getLocOfExp consExp
                      }

      in
        case expList of
          nil => makeNil loc
        | [exp] => makeNilCons (transformExp vEnv exp)
        | (headExp::tailExp) => 
          let
            fun makeHeadCell headExp =
                let
                  val headVar = newVar elemTy 
                  val newHeadExp = transformExp  vEnv headExp
                  val loc = TLU.getLocOfExp newHeadExp
                  val headDecl =
                      TLVAL {boundVar = headVar,
                             boundExp = newHeadExp,
                             loc = loc}
                  val headVarExp = TLVAR {varInfo = headVar, loc = loc}
                  val consVar = newVar listTy
                  val consDecl = TLVAL {boundVar = consVar, 
                                        boundExp = makeNilCons headVarExp, 
                                        loc = loc}
                  val consVarExp = TLVAR {varInfo = consVar, loc = loc}
                in
                  (headVarExp, consVarExp, [headDecl, consDecl])
                end
            val (initHeadVarExp, initConsVarExp, initDecls) =
                makeHeadCell headExp
            val (_, decls) =
                foldl
                  (fn (head, (prevConsVarExp, decls)) =>
                      let
                        val (headVarExp, consVarExp, headDecls) =
                            makeHeadCell head
                        val unitVar = newVar PT.unitty
                        val setTailExp =
                            makeSetTail (prevConsVarExp, consVarExp)
                        val setTailDecl = 
                            TLVAL {boundVar = unitVar, 
                                   boundExp = setTailExp, 
                                   loc = TLU.getLocOfExp prevConsVarExp}
                      in
                        (consVarExp, (decls @ headDecls @ [setTailDecl]))
                      end)
                  (initConsVarExp, initDecls)
                  tailExp
          in
            TLLET
              {
               localDeclList = decls,
               mainExp = initConsVarExp,
               loc = loc
              }
          end
      end
    | RC.RCCAST (exp, targetTy, loc) =>
      TLCAST {exp = transformExp vEnv exp, targetTy = targetTy, loc = loc} 

  and transformDecl vEnv decl =
    case decl of 
      RC.RCVAL (binds, loc) =>
      foldr
        (fn (bind, L) => 
            let
              val declList =
                  case bind of
                    (T.VALIDENT v, e) =>
                    normalizeValDecl
                      (TLVAL {boundVar = v,
                              boundExp = transformExp vEnv e,
                              loc = loc})
                  | (T.VALIDENTWILD ty, e) => 
                    normalizeValDecl
                      (TLVAL {boundVar = newVar ty,
                              boundExp = transformExp vEnv e,
                              loc = loc})
            in
              declList @ L
            end
        )
        []
        binds
    | RC.RCVALREC (decls, loc) =>
      [
       TLVALREC
         {
          recbindList = 
          map
            (fn {var, expTy, exp} =>
                {boundVar = var, boundExp = transformExp vEnv exp})
            decls,
          loc = loc
         }
      ]
    | RC.RCVALPOLYREC (btvEnv, decls, loc) =>
      [
       TLVALPOLYREC
         {
          btvEnv = btvEnv,
          recbindList =
          map
            (fn {var, expTy, exp} =>
                {boundVar = var, boundExp = transformExp vEnv exp})
            decls,
          loc = loc
         }
      ]
    | RC.RCLOCALDEC (localDeclList, mainDeclList, loc) =>
      (transformDeclList vEnv localDeclList)
      @ (transformDeclList vEnv mainDeclList)
    | RC.RCSETFIELD (valueExp, arrayExp, indexExp, ty, loc) =>
      let 
        val boundVar = newVar PT.unitty
        val boundExp =
            TLSETFIELD
              {
               arrayExp = transformExp vEnv arrayExp,
               indexExp = TLCONSTANT
                            {value = CT.INT (Int32.fromInt indexExp),
                             loc = loc},
               valueExp = transformExp vEnv valueExp,
               elementTy = ty,
               loc = loc
              }
        in
        [TLVAL {boundVar = boundVar, boundExp = boundExp, loc = loc}]
      end
    | RC.RCEMPTY loc => []

  and transformDeclList vEnv ([]) = []
    | transformDeclList vEnv (decl::rest) =
      (transformDecl vEnv decl) @ (transformDeclList vEnv rest)

  fun transformBasicBlock vEnv basicBlock = 
      case basicBlock of
          RC.RCVALBLOCK {code, exnIDSet} =>
          TLVALBLOCK {code = transformDeclList vEnv code, exnIDSet = exnIDSet}
        | RC.RCLINKFUNCTORBLOCK x => TLLINKFUNCTORBLOCK x

  fun transformTopBlock vEnv topBlock = 
      case topBlock of
        RC.RCBASICBLOCK basicBlock =>
        TLBASICBLOCK (transformBasicBlock vEnv basicBlock)
      | RC.RCFUNCTORBLOCK {name,
                           formalAbstractTypeIDSet,
                           formalVarIDSet,
                           formalExnIDSet,
                           generativeExnIDSet,
                           generativeVarIDSet,
                           bodyCode} => 
        let
          val originalMode = !Control.doFunctorCompile
          val _ = Control.doFunctorCompile := true
          val newBodyCode = map (transformBasicBlock vEnv) bodyCode
          val _ = Control.doFunctorCompile := originalMode
        in
          TLFUNCTORBLOCK {name = name, 
                          formalAbstractTypeIDSet = formalAbstractTypeIDSet, 
                          formalVarIDSet = formalVarIDSet, 
                          formalExnIDSet = formalExnIDSet, 
                          generativeExnIDSet = generativeExnIDSet,
                          generativeVarIDSet = generativeVarIDSet,
                          bodyCode = newBodyCode}
        end
          
  fun normalize topBlocks = 
      let
        val topBlocks = map (transformTopBlock VarEnv.empty) topBlocks
      in
        topBlocks
      end
      handle exn => raise exn

end
