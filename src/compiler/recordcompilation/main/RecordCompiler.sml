(**
 * Copyright (c) 2006, Tohoku University.
 *
 TODO:
  1.  ***compTy in RecordCompile.sml loop bug**** the fix is temporary
 *
 * A Typed-Directed Polymorohic Record Compiler.
 * @author Atsushi Ohori 
 * @version $Id: RecordCompiler.sml,v 1.80 2006/02/18 04:59:26 ohori Exp $
 *
 * the possible places where polytype occurrs:
   RCVAR,
   PRIM
   
 *)
structure RecordCompiler : RECORD_COMPILER =
struct
    structure SE = StaticEnv
    val tyToString = TypeFormatter.tyToString
    fun printTy ty = print (tyToString ty ^ "\n")
    fun terpri () = print "\n"
    type label = string
    type ty = Types.ty
    type tyCon = Types.tyCon
    type conIdInfo = Types.conInfo
    type varIdInfo = Types.varIdInfo
    type valId = Types.valId
    type primInfo = Types.primInfo
    type idState = Types.idState
    type btvEnv = Types.btvEnv
    datatype constant = datatype Types.constant
    structure TU = TypesUtils
    open RecordCalc
    open TypedLambda
    open Types

    structure IXord:ordsig =
    struct
      fun compare ((i, l), (i', l')) = 
          (case Int.compare(i, i') of
             EQUAL => String.compare(l, l') 
           | x => x)
      type ord_key = int * string
    end

    structure IXEnv = BinaryMapFn(IXord)

    type varEnvEntry = {fromTy : ty, toTy: ty, castedTerm : tlexp}

    type rvEnv = varEnvEntry VEnv.map

    fun isVar (TLVAR _) = true
      | isVar _ = false
    fun newVar ty = Vars.newTLVar(SE.newVarId(),ty)

    fun fieldTypes ty =
        case TU.derefTy ty of
          RECORDty tyfields => tyfields
        | _ => raise Control.Bug "Record type is expected"
                    
  (**
   *  find the index term for the kery (type var, label) from the index
   * environment 
   *)
  fun findIndex (iEnv, (n, l)) =
      case iEnv of 
        nil => raise Control.Bug "index variable not found"
      | (env1 :: rest) => 
        (case IXEnv.find(env1, (n, l)) of 
           SOME v => v
         | NONE => findIndex (rest, (n, l)))

  (**
   * construct a list of index terms correspoding 
   *  to the instance of the polyty ty with  tyl 
   *) 
  fun genIndexTys btvEnv =
      IEnv.foldri
          (fn (i, k, idxtys) =>
              case (k : btvKind) of 
                {recKind = REC tyfl, ...} => 
                SEnv.foldri
                  (fn (l, _, idxtys) => INDEXty(BOUNDVARty i, l) :: idxtys)
                  idxtys
                  tyfl
              | _ => idxtys)
          nil
          btvEnv

  fun rcompTy ty =
      case ty of
        SPECty specTy => raise Control.Bug "SPECty is not instantiated to other types"
      | ABSSPECty(ty1,ty2) => ABSSPECty(ty1,rcompTy ty2)
      | ALIASty(ty1, ty2) => ALIASty(ty1, rcompTy ty2)
      | FUNMty (argtys, ty) => FUNMty(argtys, rcompTy ty)
      | POLYty {boundtvars, body} =>
        POLYty
            {
              boundtvars = boundtvars, 
              body =
                let 
                  val idxtys = genIndexTys boundtvars
                in
                  case idxtys of 
                    nil => rcompTy body
                  | _ => 
                      (case TU.derefTy body of
                         FUNMty(domTyList, ranTy) => FUNMty(idxtys@domTyList, rcompTy ranTy)
                       | body => FUNMty(idxtys, rcompTy body)
                   )
              end
            }
      | RECORDty tyfl => RECORDty (SEnv.map rcompTy tyfl)
      | TYVARty (ref (SUBSTITUTED ty)) => rcompTy ty
      | ty => ty

  fun makeFlatRecordTy ty =
  (*
   ty is an old type.
   *)
      case TU.derefTy ty of
        RECORDty tyfl => RECORDty (SEnv.insert(SEnv.map rcompTy tyfl, 
                                               "0", 
                                               StaticEnv.tagty))
      | _ => raise Control.Bug "non record to makeFlatRecordTy"

  fun makeRecordTy ty =
  (*
   ty is an old type.
   *)
    RECORDty(SEnv.insert(SEnv.singleton("0", StaticEnv.tagty), 
                         "1", 
                         rcompTy ty))

  fun makeArrayTy ty = RECORDty(SEnv.singleton("0", ty))

  fun inlineRecordArgTy ty =
    case TU.pruneTy ty of
      FUNMty([RECORDty tyFields], ranty) => 
        (case SEnv.listItems tyFields of
           nil => FUNMty([SE.unitty], ranty)
         | tyList => FUNMty(tyList, ranty))
    | POLYty{boundtvars, body} => POLYty{boundtvars = boundtvars, body = inlineRecordArgTy body}
    | _ =>(printTy ty;raise Control.Bug "non function primi")

  fun transForeignFunInfo {name, ty} = 
    {
     name = name, 
     ty = rcompTy (inlineRecordArgTy ty)
     }

  fun transVar {id, displayName, ty} = 
      {id = id, displayName = displayName , ty = rcompTy ty}

  fun transVarWithIndexes ({id, displayName, ty}, idxtys) =
    case ty of
      FUNMty (domtyList, ranty) =>
        {
         id = id,
         displayName = displayName, 
         ty = FUNMty(idxtys@(map rcompTy domtyList), rcompTy ranty)
        }
      | _ => 
        {
        id = id,
        displayName = displayName, 
        ty = case idxtys of 
                nil => rcompTy ty 
              | _ => FUNMty(idxtys, rcompTy ty)
        }


  fun transValId (VALIDENT v) = (VALIDENT (transVar v))
    | transValId (VALIDENTWILD ty) = VALIDENTWILD (rcompTy ty)
           
  (** construct an index Environment for the set of bound type variables. *)
  fun mkIndexEnv (btvEnv : Types.btvEnv) =
      let val indextys = genIndexTys btvEnv
      in
        foldr
            (fn (INDEXty(BOUNDVARty i, l), iEnv) =>
                IXEnv.insert
                (iEnv, (i, l), newVar (INDEXty (BOUNDVARty i, l))))
            IXEnv.empty
            indextys
      end

  fun makeGroundRecordTy ty =
      case ty of
        TYVARty (ref (TVAR {recKind = REC tyFields, ...})) => RECORDty tyFields
      | TYVARty(ref (SUBSTITUTED ty)) => makeGroundRecordTy ty
      | RECORDty _ => ty
      | _ =>
        (printTy ty; raise Control.Bug "makeGroundRecordTy in recordcompile")

  fun evalIndexTy loc iEnv ty  =
    case TU.derefTy ty of
      INDEXty(recordTy as RECORDty _, l) => TLOFFSET{recordTy = recordTy , label = l, loc = loc}
    | INDEXty(BOUNDVARty tid, l) =>
        TLVAR {varInfo = findIndex (iEnv, (tid, l)), loc=loc}
    | INDEXty(TYVARty (ref (SUBSTITUTED ty)), l) => 
        evalIndexTy loc iEnv (INDEXty(ty, l))
    | INDEXty(tyarg as (TYVARty _), l) => 
        let 
          val recordTy as (RECORDty tyfl) = makeGroundRecordTy tyarg
        in
          TU.performSubst(tyarg, recordTy);
          TLOFFSET{recordTy = recordTy,label = l,loc=loc}
        end
    | _ => (printTy ty;
            raise Control.Bug "evalIndexTy")


  fun genIterms (iEnv, oldPolyTy, oldTyArgs, loc) =
      let 
        val newPolyTy = rcompTy oldPolyTy
        val newTyArgs = map rcompTy oldTyArgs
        val newInstTy = TU.tpappTy(newPolyTy, newTyArgs)
      in
        case TU.derefTy newInstTy of
          FUNMty(argTys, ranty) => 
            let
              val (extras, realArgTys) =
                foldr 
                (fn (ty, (extras, realArgTys)) => 
                   (case TU.derefTy ty of
                      ty as INDEXty _ => ((evalIndexTy loc iEnv ty)  :: extras, realArgTys)
                    | ty => (extras, ty::realArgTys)
                   )
                )
                (nil,nil)
                argTys
            in
              (newPolyTy, newTyArgs, extras, realArgTys, ranty, newInstTy)
            end
        | _ => (newPolyTy, newTyArgs, nil, nil, newInstTy, newInstTy)
      end

  fun isNumeric n nil = true
    | isNumeric n (l :: tail) = 
      (case Int.fromString l  of
         SOME k => if k = n then isNumeric (n + 1) tail else false
       | _ => false)

  fun mkArgs id ty [] L loc = L
    | mkArgs id ty (label::rest) L loc = 
      mkArgs id ty rest (L @ [TLSELECT {recordExp=id,
                                        indexExp=TLOFFSET{recordTy = ty,label = label,loc= loc},
                                        recordTy=ty, 
                                        loc=loc} ]) loc

  fun mkUnitval loc = TLRECORD{expList=nil, internalTy=SE.unitty, externalTy=NONE, loc=loc}

  fun rcompPrim {name, ty} =
    let
      val newTy =
        case ty of
          FUNMty([ty1], ty2) =>
            (case TU.derefTy ty1 of
               RECORDty tySEnvMap =>
                 FUNMty(
                        if SEnv.isEmpty tySEnvMap then
                          [SE.unitty]
                        else
                          SEnv.listItems tySEnvMap,
                          ty2)
             | _ => ty
                 )
        | POLYty{boundtvars, body} => 
           (case body of
               FUNMty([ty1], ty2) =>
                 POLYty{boundtvars = boundtvars,
                        body =  FUNMty(case TU.derefTy ty1 of
                                            RECORDty tySEnvMap =>
                                              if SEnv.isEmpty tySEnvMap then
                                                [SE.unitty]
                                              else
                                                SEnv.listItems tySEnvMap
                                          | ty1 => [ty1],
                                       ty2)
                        }
             | _ => raise Control.Bug "non fun ty in primInfo"
                 )
        | _ => raise Control.Bug "non fun ty in primInfo"
    in
      {name = name, ty = newTy}
    end
      
  fun mkPrimApply (prim, instantiatedTys, argExps, loc) =
      (* ToDo : the primitive name should be defined as a constant at
       *      somewhere. *)
      case (#name prim, instantiatedTys, argExps) of
        (":=", [valueTy], [refExp, valueExp]) =>
        TLSETFIELD {
                    valueExp = valueExp,
                    arrayExp = refExp,
                    indexExp = TLCONSTANT{value = WORD 0w0, loc = loc},
                    elementTy = valueTy,
                    loc = loc
                    }

      | ("Array_array", [valueTy], [sizeExp, valueExp]) =>
        let val resultType = CONty{tyCon = SE.arrayTyCon, args = [valueTy]}
        in TLARRAY {
                    sizeExp = sizeExp, 
                    initialValue = valueExp, 
                    elementTy = valueTy, 
                    resultTy = resultType, 
                    loc = loc
                    }
        end
        
      | ("Array_sub", [valueTy], [arrayExp, indexExp]) =>
        TLGETFIELD {arrayExp = arrayExp, indexExp = indexExp, elementTy = valueTy, loc=loc}

      | ("Array_update", [valueTy], [arrayExp, indexExp, valueExp]) =>
        TLSETFIELD {valueExp = valueExp, 
                    arrayExp = arrayExp, 
                    indexExp = indexExp, 
                    elementTy = valueTy, 
                    loc=loc}

      | _ => TLPRIMAPPLY {primOp = rcompPrim prim, 
                          instTyList = instantiatedTys, 
                          argExpList = argExps, 
                          loc = loc}

  fun mkForeignApply {funExp, argExpList, argTyList, loc} =
      TLFOREIGNAPPLY {funExp=funExp, instTyList=nil, argExpList=argExpList, argTyList=argTyList, loc= loc}

  fun rcompOprim ({name, ty, instances}, instty) =
      case TU.derefTy instty of
        CONty {tyCon, args} => 
        (case SEnv.find(instances, #name tyCon) of
           SOME prim => prim
         | _ => (print name;
                 terpri();
                 printTy instty;
                 raise Control.Bug ("rcompOprim (1):" ^ tyToString instty)
                   )
             )
      | _ => (print name;
              terpri();
              printTy instty;
              raise Control.Bug ("rcompOprim(2):" ^ tyToString instty)
              )
                   
  fun isRefTy ty = 
    case TU.derefTy ty of
      CONty{tyCon, ...} =>
        StaticEnv.isSameTyCon (StaticEnv.refTyCon, tyCon)
    | _ => false

  fun isSingleConTy ty = 
    case TU.derefTy ty of
      CONty{tyCon, ...} => TU.tyconSpan tyCon = 1
    | _ => false

  fun isRecordArgTycon ty =
    case TU.derefTy ty of
      (FUNMty ([RECORDty ty], _)) => true
    | (POLYty {body, ...}) => isRecordArgTycon body
    | _ => false

  fun isFlattened ty =
      case TU.derefTy ty of
        (FUNMty ([argTy], _)) => 
        (
         case TU.derefTy argTy of
           RECORDty tyfields =>
             if SEnv.numItems tyfields < (!Control.limitOfBlockFields)
           then true 
           else false
         | _ => false
        )
      | (POLYty {body, ...}) => isFlattened body
      | _ => false

  fun argTyInConTy ty =
    case TU.derefTy ty of
      (FUNMty ([ty], _)) => ty
    | (POLYty {body, ...}) => argTyInConTy body
    | _ => raise Control.Bug "non function type to argTyInTyconTy"

  fun rcomp vEnv iEnv rexp =
      case rexp of
          (* RCFOREIGNAPPLY
           * Ohori:
           * The domain type in the function variable has been computed from the argTyList,
           * which is the primary information. In this version the function type is also 
           * restricted to mono type, i.e. instTyList = nil. Here we assume these.
           * I will rewrite this representation.
           *)
        RCFOREIGNAPPLY {funExp, instTyList=nil, argExp, argTyList=nil, loc=loc} => 
          mkForeignApply 
            {
             funExp = rcomp vEnv iEnv funExp, 
             argExpList = nil, 
             argTyList = nil, 
             loc = loc
             }                  
      | RCFOREIGNAPPLY {funExp, instTyList=nil, argExp, argTyList=[argTy], loc=loc} => 
          mkForeignApply 
          {
           funExp = rcomp vEnv iEnv funExp, 
           argExpList = [rcomp vEnv iEnv argExp], 
           argTyList = [argTy], 
           loc = loc
           }
      | RCFOREIGNAPPLY {
                        funExp = RCVAR({ty=FUNMty([domTy],ranTy),
                                         id=funId, 
                                         displayName=funDisplayName},
                                        funLoc),
                        instTyList=nil, 
                        argExp, 
                        argTyList, 
                        loc=loc
                        } => 
          let
            val newArgExp = rcomp vEnv iEnv argExp
            val (localBinds, newArgExp) =
              case newArgExp of
                TLVAR _ => (nil, newArgExp)
              | _ => 
                  let val newId = newVar domTy
                  in
                    ([(newId, newArgExp)], TLVAR {varInfo = newId, loc= loc})
                  end
            val args =
              List.rev
              (#2 
              (foldl
              (fn (ty, (i, args)) =>
               (i + 1,
                TLSELECT {
                          recordExp = newArgExp,
                          indexExp = TLOFFSET{recordTy = domTy,label = Int.toString i,loc=loc}, 
                          recordTy = domTy, 
                          loc=loc
                          }
                :: args)
               )
               (1,nil)
               argTyList
               )
               )
              val newFunExp = RCVAR({ty=FUNMty(argTyList,ranTy),
                                                     id=funId, 
                                                     displayName=funDisplayName},
                                     funLoc)
          in
            case localBinds of
                 nil => 
                   mkForeignApply 
                   {
(*
                    funExp = rcomp vEnv iEnv funExp, 
*)
                    funExp = rcomp vEnv iEnv newFunExp, 
                    argExpList = args, 
                    argTyList = argTyList, 
                    loc = loc
                    }

               | _ => 
               TLMONOLET
                 {
                  binds = localBinds,
                  bodyExp = 
                   mkForeignApply 
                   {
(*
                    funExp = rcomp vEnv iEnv funExp, 
*)
                    funExp = rcomp vEnv iEnv newFunExp, 
                    argExpList = args, 
                    argTyList = argTyList, 
                    loc = loc
                    },
                   loc = loc
                   }
          end
      | RCFOREIGNAPPLY _ => raise Control.Bug "ill formed foreign fun"
      | RCCONSTANT (constant, loc) => TLCONSTANT {value=constant, loc=loc}
      | RCVAR (varIdInfo as {ty, ...}, loc) =>
          (
          case VEnv.find(vEnv, varIdInfo) of
             SOME {fromTy, toTy, castedTerm}
              =>
            (*
              Here we reconstruct a record.
              This may become unnecessary when we implement
              type-directed equality compilation.

              This is for a case expression someting like:
                datatype foo = D of int * int 
                val w = D (1,2)
                case w of 
                  D (x as (y,z)) => (y,z,x)
                  ...
              This is compiled to
                 case w of
                   switch (cast w: tag*int*int)["0"] of
                       D => ((cast w: tag*int*int)["1"], 
                             (cast w: tag*int*int)["2"], 
                             ((cast w: tag*int*int)["1"], 
                              (cast w: tag*int*int)["2"])
                            )
             with the vEnv = {x => (cast x from foo to to tag * int * int)}
             This is the case for "x" in "(y,z,x)".
             *)
              let
                 fun makeFieldExp label =
                   TLSELECT {recordExp = castedTerm, 
                             indexExp = TLOFFSET{recordTy = toTy,label =  label, loc=loc}, 
                             recordTy = toTy, 
                             loc = loc}
                 val tyfields = fieldTypes fromTy
              in
                TLRECORD
                {
                 expList=map makeFieldExp (SEnv.listKeys tyfields), 
                 internalTy = fromTy, 
                 externalTy = NONE,
                 loc=loc
                 }
              end
          | NONE => TLVAR {varInfo = transVar varIdInfo, loc= loc}
          )
      | RCGETGLOBAL (string, ty, loc) => TLGETGLOBAL(string, rcompTy ty, loc)
      | RCGETGLOBALVALUE (arrayIndex, offset, ty, loc) =>
        let
          val newOffsetExp = TLCONSTANT{value=WORD(Word32.fromInt offset), loc=loc}
        in
          TLGETGLOBALVALUE {
                            arrayIndex = arrayIndex,
                            offset = offset,
                            ty = rcompTy ty,
                            loc = loc
                            }
        end
      | RCGETFIELD (rcexp, int, ty, loc) => 
          TLGETFIELD
          {
           arrayExp = rcomp vEnv iEnv rcexp,
           indexExp = TLCONSTANT {value=WORD (Word32.fromInt int), loc=loc},
           elementTy = rcompTy ty,
           loc = loc
          }
      | RCARRAY {sizeExp, initExp, elementTy , resultTy, loc}  => 
          TLARRAY
          {
           sizeExp = rcomp vEnv iEnv sizeExp,
           initialValue = rcomp vEnv iEnv initExp,
           elementTy = elementTy,
           resultTy = resultTy,
           loc = loc
           }
      | RCPRIMAPPLY 
         {
          primOp, 
          instTyList, 
          argExpOpt = SOME (RCRECORD {fields=fl, recordTy=ty, loc=argLoc}), 
          loc
          } =>
         let
            val primArgs = 
              case (SEnv.listItems fl) of 
                nil => [mkUnitval argLoc]
              | rcexps => map (rcomp vEnv iEnv) rcexps
          in
            mkPrimApply (primOp, instTyList, primArgs, loc)
          end
      | RCPRIMAPPLY
         {
          primOp = primInfo as {ty, ...},
          instTyList,
          argExpOpt = SOME argExp,
          loc
          } =>
          (* We inline the primitive, i.e.
             op x => op (x[1], x[2], ...)
            for any op with more than one arguments.
           *)
          let
            val primTy = TU.tpappTy (ty, instTyList)
          in
            (case TU.derefTy primTy of
               FUNMty([ty1], ty2) =>
                 (case TU.derefTy ty1 of
                    RECORDty tySEnvMap =>
                      if SEnv.isEmpty tySEnvMap then
                       (* The argument is of type unit. *)
                        mkPrimApply (primInfo, instTyList, [mkUnitval loc], loc )
                      else
                        let 
                          val id = newVar ty1
                          val args = 
                            SEnv.foldri
                            (fn (label, ty, args) => TLSELECT {recordExp = TLVAR {varInfo = id, loc= loc},
                                                               indexExp = TLOFFSET{recordTy = ty1,label = label,loc=loc}, 
                                                               recordTy = ty1, 
                                                               loc = loc}
                                                      :: args)
                            nil
                            tySEnvMap
                        in
                          TLMONOLET
                          {
                           binds = [(id, rcomp vEnv iEnv argExp)], 
                           bodyExp = mkPrimApply (primInfo, instTyList, args, loc),
                           loc = loc
                           }
                        end
                  | _ =>
                     mkPrimApply
                        (
                         primInfo,
                         instTyList,
                         [rcomp vEnv iEnv argExp],
                         loc
                         )
                        )
             | _ => raise Control.Bug "rcomp1")
          end
      | RCPRIMAPPLY {primOp = {ty = ty as FUNMty _, ...}, argExpOpt= NONE, ...} =>
          raise Control.Bug "primop should have been eta-expanded."
      | RCPRIMAPPLY {argExpOpt=NONE, ...} => 
          raise Control.Bug "there should not be a constant primitive."
      | RCOPRIMAPPLY {oprimOp = oprimInfo, 
                      instances = [ty], 
                      argExpOpt = rcexpOpt, 
                      loc} => 
          rcomp vEnv iEnv (RCPRIMAPPLY{primOp = rcompOprim (oprimInfo, ty), 
                                       instTyList = nil, 
                                       argExpOpt = rcexpOpt, 
                                       loc= loc})
      | RCOPRIMAPPLY _ => raise Control.Bug "rcomp RCOPRIMAPPLY has multiple parameters"
      | RCCONSTRUCT {con = con as {funtyCon = true, ...}, argExpOpt = NONE, ...} =>
          raise Control.Bug "funtycon but no args"
      | RCCONSTRUCT {con = con as {ty as POLYty{boundtvars, body}, ...}, 
                     instTyList = [], 
                     argExpOpt=NONE, 
                     loc} =>
          if TU.isBoxedType ty then
             TLPOLY
              {
                btvEnv = boundtvars,
                expTyWithoutTAbs = body,
                exp = TLRECORD {
                                    expList = [TLCONSTANT{value=INT(Int32.fromInt(#tag con)), loc=loc}], 
                                    internalTy = RECORDty(SEnv.singleton("0", StaticEnv.tagty)),
                                    externalTy = SOME body,
                                    loc=loc
                                    },
                loc = loc
               }
          else 
            TLCONSTANT{value=INT(Int32.fromInt(#tag con)), loc=loc}
      | RCCONSTRUCT {con = con as {ty,...}, instTyList = tys, argExpOpt = NONE, loc} =>
          if TU.isBoxedType ty then
            TLRECORD
            {
             expList = [TLCONSTANT{value=INT(Int32.fromInt(#tag con)), loc=loc}], 
             internalTy = RECORDty(SEnv.singleton("0", StaticEnv.tagty)),
             externalTy = SOME ty,
             loc=loc
             }
          else TLCONSTANT{value=INT(Int32.fromInt(#tag con)), loc=loc}
      | RCCONSTRUCT {con = con as {funtyCon = false, ...}, argExpOpt=SOME _,...} =>
          raise Control.Bug "nonfuntycon with args"
      | RCCONSTRUCT {con = con as {ty, tyCon, ...}, instTyList = tys, argExpOpt = SOME argExp, loc} =>
          if StaticEnv.isSameTyCon (StaticEnv.refTyCon, tyCon) then
            case tys of
              [elemTy] =>
                let
                  val resTy = CONty{tyCon = #tyCon con, args = [elemTy]}
                  val newArgExp = rcomp vEnv iEnv argExp
                in
                  TLARRAY {
                           sizeExp = TLCONSTANT{value=INT 1, loc=loc}, 
                           initialValue = newArgExp, 
                           elementTy = elemTy, 
                           resultTy = resTy, 
                           loc=loc
                           }
                end
            | _ => raise Control.Bug "ref constructor expects one argument."
          else
           (***rcompTy in RecordCompile.sml loop bug****
            We supress this optimization
            if TU.tyconSpan tyCon = 1 then
              (* This is the case of A(e) where A is a single datacon like:
               *    datatype foo = A of tau
               *)
              rcomp vEnv iEnv argExp
            else
           *)
            let
              val (oldArgTy, oldExternalTy) =
                  case TU.tpappTy (ty, tys) of
                    FUNMty([ty1], ty2) => (ty1, ty2)
                  | _ => raise Control.Bug "non well formed type in CONSTRUCT" 
            in 
              if isFlattened ty
              then
                case argExp of
                  RCRECORD {fields=fl,...} => 
                  (*
                   Here we compile A (x,y) to (i, x, y) 
                        where A is defined as
                         datatype foo = ... | A of tau1 * tau2 ..
                         and i is the tag of A.
                   *)
                  TLRECORD
                      {
                       expList = TLCONSTANT{value=INT(Int32.fromInt(#tag con)), loc=loc}
                                  :: (map (rcomp vEnv iEnv) (SEnv.listItems fl)), 
                       internalTy=makeFlatRecordTy oldArgTy,
                       externalTy = SOME oldExternalTy,
                       loc=loc
                      }
                | _ =>
                    (*
                     Here we compile A e to 
                        (i, e[0], e[1]) if e is a variable 
                        monolet x = e in (i, x[0], x[1]), otherwise
                     where A is defined as
                        datatype foo = ... | A of tau1 * tau2 ..
                     and i is the tag of A
                     *)
                  let
                    val tyfields = 
                        case TU.derefTy oldArgTy of
                          RECORDty tyfields => tyfields
                        | _ => raise Control.Bug "Record type is expected"
                    val argExp = rcomp vEnv iEnv argExp
                    val (makeTerm, rootTerm) = 
                        if isVar argExp
                        then (fn x => x, argExp)
                        else 
                          let val id = newVar oldArgTy
                          in
                            (
                              fn x => TLMONOLET {binds = [(id, argExp)], 
                                                 bodyExp = x, 
                                                 loc =loc},
                              TLVAR {varInfo = id, loc= loc}
                            )
                          end
                    val args =
                        SEnv.foldri
                            (fn (label, ty, args) => 
                                TLSELECT {recordExp = rootTerm,
                                          indexExp = TLOFFSET{recordTy = oldArgTy, label= label,loc=loc}, 
                                          recordTy = oldArgTy, 
                                          loc = loc}
                                :: args)
                            nil
                            tyfields
                  in 
                    makeTerm
                        (TLRECORD
                             {
                              expList = (TLCONSTANT{value=INT(Int32.fromInt(#tag con)), loc=loc})
                                         :: args, 
                              internalTy = makeFlatRecordTy oldArgTy,
                              externalTy = SOME oldExternalTy,
                              loc=loc
                              }
                       )
                  end
              else
                TLRECORD
                    {
                     expList = [
                                TLCONSTANT{value=INT(Int32.fromInt(#tag con)), loc=loc},
                                rcomp vEnv iEnv argExp
                                ],
                     internalTy = makeRecordTy oldArgTy,
                     externalTy = SOME oldExternalTy,
                     loc=loc
                    }
            end
      | RCAPPM {funExp = rcexp as RCVAR (varIdInfo, loc1), 
                funTy=oldFunTy, 
                argExpList=rcexpList, 
                loc=loc2}  => 
          let
            val tlexpList = map (rcomp vEnv iEnv) rcexpList
          in
            case VEnv.find(vEnv, varIdInfo) of
              SOME _ => raise Control.Bug "casted record in fun position"
            | _ => TLAPPM {
                           funExp = rcomp vEnv iEnv rcexp, 
                           funTy = rcompTy oldFunTy, 
                           argExpList = tlexpList,
                           loc = loc2
                           }
          end
      | RCAPPM {funExp = RCTAPP {exp = rcexp, expTy = oldPolyFunTy, instTyList = oldTyArgs, loc = loc1}, 
                funTy = oldFunTy, 
                argExpList = rcexpList, 
                loc=loc2}  => 
          let
            val tlexp = rcomp vEnv iEnv rcexp
            val tlexpList = map (rcomp vEnv iEnv) rcexpList
            val newPolyFunTy = rcompTy oldPolyFunTy
            val newTyArgs = map rcompTy oldTyArgs
            val funTerm = TLTAPP {
                                  exp = tlexp, 
                                  expTy = newPolyFunTy, 
                                  instTyList = newTyArgs, 
                                  loc = loc1
                                  }
            val newInstFunTy = TU.tpappTy (newPolyFunTy, newTyArgs)
            val argstys = 
              case newInstFunTy  of
                FUNMty(argstys, _) => argstys
              | _ => raise Control.Bug "non function type in RCAPP"
            val extras =
              foldr 
              (fn (ty as INDEXty _ , extras) => (evalIndexTy loc1 iEnv ty)  :: extras
                | (ty, extras) => extras)
              nil
              argstys
          in
             TLAPPM{funExp = funTerm, funTy = newInstFunTy, argExpList = extras @ tlexpList, loc = loc2}
          end
      | RCAPPM {funExp, funTy, argExpList, loc}  =>
        TLAPPM {
                funExp = rcomp vEnv iEnv funExp, 
                funTy = rcompTy funTy, 
                argExpList = map (rcomp vEnv iEnv) argExpList, 
                loc = loc
                }
      | RCMONOLET {binds, bodyExp, loc} =>
          TLMONOLET{
                    binds= map (fn (v, e) => (transVar v, rcomp vEnv iEnv e)) binds,
                    bodyExp = rcomp vEnv iEnv bodyExp, 
                    loc = loc}
      | RCLET (rcdeclList, rcexpList, tyList, loc) =>
          TLLET{
                localDeclList = rcompDecls vEnv iEnv rcdeclList,
                mainExpList = map (rcomp vEnv iEnv) rcexpList, 
                mainExpTyList = map rcompTy tyList, 
                loc = loc
                }
      | RCRECORD {fields, recordTy, loc} => 
          TLRECORD {
                    expList = map (rcomp vEnv iEnv) (SEnv.listItems fields), 
                    internalTy = recordTy, 
                    externalTy = NONE,
                    loc=loc
                    }
      | RCSELECT {exp=rcexp, label, expTy=ty, loc} =>
          let
            val (castedNewTy, castedTlexp) =
              case rcexp of
                RCVAR (varIdInfo, loc) =>
                  (case VEnv.find(vEnv, varIdInfo) of
                     SOME {fromTy, toTy, castedTerm} => (toTy, castedTerm)
                   | _ => (rcompTy ty, TLVAR {varInfo = transVar varIdInfo, loc= loc}))
              | _ => (rcompTy ty, rcomp vEnv iEnv rcexp)
          in
            (case TU.derefTy castedNewTy of 
               RECORDty tyf =>
                 TLSELECT {
                           recordExp = castedTlexp, 
                           indexExp = TLOFFSET{recordTy = castedNewTy, label = label, loc=loc}, 
                           recordTy = castedNewTy, 
                           loc = loc
                           }
             | BOUNDVARty i => 
                 let 
                   val ix =  findIndex (iEnv, (i, label)) 
                 in
                   TLSELECT {recordExp = castedTlexp, 
                             indexExp = TLVAR {varInfo = ix, loc= loc}, 
                             recordTy = castedNewTy, 
                             loc = loc}
                 end
             | TYVARty _ =>raise Control.Bug "vacuous type variable in record compile (2)"
             | (* 
                  ->fn f => fn x => f x;
                  val it = fn : ['a,'b.('a -> 'b) -> 'a -> 'b]
                  ->it #a;
                  stdIn:6.1-6.5 Warning: dummy type variable(s) X1, X0 
                     are introduced due to value  restriction
                  BUG :Rcomp RCSELECT
                  ../../../recordcompilation/main/RecordCompiler.sml:708.25-708.53
                This bug is due to the missing case for DUMMYty.
                The following is a quick fix, but it is type inconsistent.
                We need to supply some type correct term here. 
                Its actual semantics does not matter, since it will not be 
                 evaluated anyway.
                A cleaner solution would be to change DUMMYty to have record kind 
                like a type variable, but the following would be enough.
              *)
               DUMMYty _ => TLCONSTANT{value=INT 0, loc=loc} 
             | _ => raise Control.Bug "Rcomp RCSELECT")
          end
      | RCMODIFY {label, 
                  recordExp = rcexp1, 
                  recordTy = oldRecordTy, 
                  elementExp = rcexp2, 
                  elementTy = oldFieldTy, 
                  loc = loc} =>
          (case TU.derefTy oldRecordTy of 
             RECORDty tyf => 
             let
               val recordTy = rcompTy oldRecordTy
             in
               TLMODIFY
                   {
                    recordExp = rcomp vEnv iEnv rcexp1,
                    recordTy = recordTy,
                    indexExp = TLOFFSET{recordTy = recordTy, label = label, loc=loc},
                    elementExp = rcomp vEnv iEnv rcexp2,
                    elementTy = oldFieldTy,
                    loc = loc
                   }
             end
           | BOUNDVARty i => 
             let 
               val ix =  findIndex (iEnv, (i, label)) 
             in 
               TLMODIFY
                   {
                     recordExp = rcomp vEnv iEnv rcexp1,
                     recordTy = rcompTy oldRecordTy,
                     indexExp = TLVAR {varInfo = ix, loc= loc},
                     elementExp = rcomp vEnv iEnv rcexp2,
                     elementTy = rcompTy oldFieldTy,
                     loc = loc
                   }
             end
           | TYVARty _ => raise Control.Bug "vacuous type variable in record compile (3)"
           | (* see the note on SELECT term having a dummy type above.
             *)
             DUMMYty _ => TLCONSTANT{value=INT 0, loc=loc} 
           | _ => raise Control.Bug "Rcomp RCMODIFY")
      | RCRAISE (rcexp, oldTy, loc) => 
          TLRAISE {argExp = rcomp vEnv iEnv rcexp, resultTy = rcompTy oldTy, loc = loc}
      | RCHANDLE {exp=rcexp1, exnVar = varIdInfo, handler = rcexp2, loc=loc} =>
          TLHANDLE{
                   exp = rcomp vEnv iEnv rcexp1, 
                   exnVar = transVar varIdInfo, 
                   handler = rcomp vEnv iEnv rcexp2, 
                   loc = loc
                   }
      | RCCASE {exp=rcexp1, 
                expTy = oldArgTy, 
                ruleList = conIdInfoVarIdInfoOptRcexpList, 
                defaultExp = rcexp2, 
                loc= loc} =>
        (* Here, a case expression is translated into a switch expression.
          (1) case e of ref x => exp
            ==> let x = e[0] in exp end 
          (2) case e of A x => exp  (where the span of the type of e is 1)
            ==> let x = e in exp
          (3) case e of  .... C x => exp ...,
            case (a)  C : (t0,...,tn) -> foo
              ==> let x = e in 
                  switch x[0] of
                         ...
                    i => exp[cast(x)/x]
              where cast(x) is treated as follows:
                the type of x => (tag, t0, ..., tn) (flattened record with inlied tag)
                 x[i] => x[i+1]
                 x => (x[1], ..., x[n+1])
            case (b) C : tau -> foo (where tau is non-record type)
              ==> let x = e in 
                  switch x[0] of
                         ...
                    i => let x = x[1] in exp
         *)
        if isRefTy oldArgTy then
          case (conIdInfoVarIdInfoOptRcexpList, TU.derefTy oldArgTy) of
            ([(c, SOME v, ex)],  CONty{tyCon, args = [elemTy]}) =>
              let 
                val argExp = rcomp vEnv iEnv rcexp1
                val arrayArgTy = makeArrayTy (rcompTy elemTy)
              in
                TLMONOLET
                {
                 binds = [(
                           v,
                           TLSELECT
                           {
                            recordExp =  TLCAST {exp = argExp, targetTy = arrayArgTy, loc = loc}, 
                            indexExp = TLOFFSET{recordTy = arrayArgTy,label = "0",loc=loc},
                            (*
                             indexExp = TLCONSTANT(WORD 0w0, loc),
                             *)
                            (* was "rcompTy elemTy". A bug? Need to check with Duc kun. *)
                            recordTy = arrayArgTy,
                            loc = loc
                            }
                           )], 
                 bodyExp = rcomp vEnv iEnv ex,
                 loc = loc
                 }
              end
          | _ => raise Control.Bug "multiple rules for ref tycon"
        else
         (***rcompTy in RecordCompile.sml loop bug****
             we temporarily supress this optimization
          if isSingleConTy oldArgTy then
            case conIdInfoVarIdInfoOptRcexpList of
              [(c, SOME v, ex)] =>
                let 
                  val argExp = rcomp vEnv iEnv rcexp1
                in
                  TLMONOLET {binds = [(v, argExp)], bodyExp = rcomp vEnv iEnv ex, loc=loc}
                end
            | [(c, NONE, ex) ] => rcomp vEnv iEnv ex
            | _ => raise Control.Bug "multiple rules for single con tycon"
          else
          ***rcompTy in RecordCompile.sml loop bug***
          *)
            let
              val tlexp1 = rcomp vEnv iEnv rcexp1
              val (mkTerm, argTerm) =
                  case tlexp1 of
                    TLVAR {varInfo = v,...} => (fn x => x, tlexp1)
                  | _ => 
                    let 
                      val v' = newVar oldArgTy 
                    in
                      (
                        fn x => TLMONOLET{ binds=[(v', tlexp1)], bodyExp = x, loc=loc},
                        TLVAR {varInfo = v', loc= loc }
                      )
                    end
              val switchTerm = 
                  if TU.isBoxedType oldArgTy then 
                    TLSELECT {
                              recordExp = TLCAST{exp=argTerm, targetTy=makeArrayTy SE.tagty, loc=loc},
                              indexExp = TLOFFSET{recordTy = makeArrayTy SE.tagty,label = "0",loc= loc}, 
                              recordTy = makeArrayTy SE.tagty, 
                              loc=loc
                              }
                  else argTerm
              val tyArgs = 
                  case TU.derefTy oldArgTy of
                    CONty {args,...} => args
                  | _ => raise Control.Bug "CONty is expected"
              fun processRule
                    (
                     conIdInfo:conIdInfo as {ty=conTy, ...}, 
                     SOME (varIdInfo as {ty, ...}), 
                     rcexp
                     ) =
                  let
                    val (mkRuleTerm, vEnv) =
                        if isFlattened conTy then
                          let
                            val newFromRootTy = (rcompTy ty)
                            val newToRootTy = makeFlatRecordTy ty
                          in
                            (
                              fn x => x,
                              VEnv.insert
                                  (
                                    vEnv,
                                    varIdInfo,
                                      {
                                        fromTy = newFromRootTy,
                                        toTy = newToRootTy,
                                        castedTerm = TLCAST {exp = argTerm, targetTy = newToRootTy, loc = loc}
                                      }
                                  )
                            )
                          end
                        else 
                          let 
                            val recordTy = makeRecordTy (rcompTy ty)
                          in
                            (
                             fn x =>
                              TLMONOLET
                               {
                                binds = [(
                                          varIdInfo, 
                                          TLSELECT
                                          {
                                           recordExp = TLCAST {exp = argTerm, targetTy = recordTy, loc = loc}, 
                                           indexExp = TLOFFSET{recordTy = recordTy,label = "1",loc = loc},
                                           (*  was : "rcompTy ty"; need to check with Duc kun *)
                                           recordTy = recordTy,
                                           loc = loc
                                           }
                                          )],
                                bodyExp = x,
                                loc = loc
                                },
                               vEnv
                               )
                          end
                  in
                    (
                      INT(Int32.fromInt(#tag conIdInfo)), 
                      mkRuleTerm (rcomp vEnv iEnv rcexp)
                    )
                  end
                | processRule (c, NONE, rcexp) =
                    (INT(Int32.fromInt(#tag c)), rcomp vEnv iEnv rcexp)
              val tlRules = map processRule conIdInfoVarIdInfoOptRcexpList
              val tlexp2 = rcomp vEnv iEnv rcexp2
            in
              mkTerm (TLSWITCH {
                                switchExp= switchTerm, 
                                expTy = SE.tagty, 
                                branches = tlRules, 
                                defaultExp = tlexp2, 
                                loc =loc
                                }
                      )
            end
      | RCSWITCH {switchExp, expTy, branches, defaultExp, loc} =>
          TLSWITCH
          {
           switchExp = rcomp vEnv iEnv switchExp,
           expTy = expTy,
           branches = map (fn (c, e) => (c, rcomp vEnv iEnv e)) branches,
           defaultExp = rcomp vEnv iEnv defaultExp,
           loc = loc
           }
     | RCFNM {argVarList, bodyTy, bodyExp, loc} =>
         TLFNM {
                argVarList = map transVar argVarList, 
                bodyTy = rcompTy bodyTy, 
                bodyExp = rcomp vEnv iEnv bodyExp, 
                loc = loc
                }
     | RCPOLYFNM {btvEnv=tvEnv, 
                  argVarList=varIdInfoList, 
                  bodyTy=oldBodyTy, 
                  bodyExp = rcexp, 
                  loc=loc} => 
         let 
           val newBodyTy = rcompTy oldBodyTy
           val newiEnv = mkIndexEnv tvEnv 
           val argTyList = map #ty varIdInfoList
         in 
           if IXEnv.isEmpty newiEnv then
             TLPOLY
             {
              btvEnv = tvEnv,
              expTyWithoutTAbs = FUNMty(argTyList, newBodyTy),
              exp = TLFNM {
                           argVarList = varIdInfoList, 
                           bodyTy = newBodyTy, 
                           bodyExp = rcomp  vEnv iEnv rcexp, 
                           loc = loc
                           },
              loc = loc
              }
           else
             let
               val idxvars = IXEnv.listItems newiEnv
               val idxtys = map (fn {ty, ...} => ty) idxvars
             in
               TLPOLY
                 {
                  btvEnv = tvEnv, 
                  expTyWithoutTAbs = FUNMty(idxtys@argTyList, newBodyTy),
                  exp = TLFNM {
                               argVarList = (IXEnv.listItems newiEnv) @ varIdInfoList,
                               bodyTy = newBodyTy,
                               bodyExp = rcomp vEnv (newiEnv :: iEnv) rcexp,
                               loc = loc
                               },
                    loc = loc
                    }
             end
         end
     | RCPOLY {btvEnv, expTyWithoutTAbs=ty, exp=rcexp, loc=loc} => 
         let 
           val newiEnv = mkIndexEnv btvEnv 
         in 
           if IXEnv.isEmpty newiEnv then 
             TLPOLY{btvEnv = btvEnv, expTyWithoutTAbs = rcompTy ty, exp = rcomp vEnv iEnv rcexp, loc = loc}
           else
             let
               val idxvars = IXEnv.listItems newiEnv
               val idxtys = map (fn {ty, ...} => ty) idxvars
               val newTy = rcompTy ty
             in
               TLPOLY
                   {
                     btvEnv = btvEnv,
                     expTyWithoutTAbs = FUNMty(idxtys, newTy),
                     exp = TLFNM{
                                 argVarList = idxvars, 
                                 bodyTy = newTy, 
                                 bodyExp = rcomp vEnv (newiEnv :: iEnv) rcexp, 
                                 loc = loc
                                 },
                     loc = loc
                   }
             end
         end
     | RCTAPP {exp=rcexp, expTy, instTyList=oldTyArgs, loc=loc} => 
         let 
           val (newPolyTy, newTyArgs, extras, realArgTys, ranty, newInstTy) = 
                genIterms (iEnv, expTy, oldTyArgs, loc)
         in
           case extras of
             nil => TLTAPP {
                            exp = rcomp vEnv iEnv rcexp, 
                            expTy = newPolyTy, 
                            instTyList = newTyArgs, 
                            loc = loc
                            }
           | _ => 
               (case realArgTys of
                  [realArgTy] =>
                    let
                      val newx = newVar realArgTy
                    in
                      TLFNM{
                            argVarList = [newx],
                            bodyTy = ranty,
                            bodyExp = TLAPPM
                              {
                               funExp = TLTAPP {
                                                exp = rcomp vEnv iEnv rcexp, 
                                                expTy = newPolyTy, 
                                                instTyList = newTyArgs, 
                                                loc = loc
                                                },
                               funTy = newInstTy,
                               argExpList = extras@[TLVAR {varInfo = newx, loc = loc}],
                               loc = loc
                               },
                            loc = loc
                            }
                    end
                | nil => 
                    TLAPPM
                    {
                     funExp = TLTAPP {
                                      exp = rcomp vEnv iEnv rcexp, 
                                      expTy = newPolyTy, 
                                      instTyList =newTyArgs, 
                                      loc = loc
                                      },
                     funTy = newInstTy,
                     argExpList = extras,
                     loc = loc
                     }
                | _ => (
                        map printTy realArgTys;
                        raise Control.Bug "multiple realArgTys"
                       )
              )
         end
     | RCSEQ {expList, expTyList, loc} =>
         TLSEQ {expList=map (rcomp vEnv iEnv) expList, 
                expTyList=expTyList, 
                loc=loc}
     | RCFFIVAL {funExp, libExp, argTyList, resultTy, funTy, loc} =>
       let
         val newFunExp = rcomp vEnv iEnv funExp
         val newLibExp = rcomp vEnv iEnv libExp
       in
         TLFFIVAL {
                   funExp = newFunExp, 
                   libExp = newLibExp, 
                   argTyList= argTyList, 
                   resultTy = resultTy, 
                   funTy = funTy, 
                   loc = loc
                   }
       end
     | RCCAST (rcexp, oldTy, loc) =>
       (* rcompTy not necessary *)
         TLCAST {exp = rcomp vEnv iEnv rcexp, targetTy = rcompTy oldTy, loc = loc} 

  and rcompDecl  vEnv iEnv decl =
      case decl of 
        RCVAL (decls, loc) =>
          TLVAL 
              {
               bindList = 
                 map 
                     (fn (VALIDENT v, e) => 
                         {boundValIdent = VALIDENT (transVar v), boundExp = rcomp vEnv iEnv e}
                       | (VALIDENTWILD ty, e) => 
                         {boundValIdent = VALIDENTWILD (rcompTy ty), boundExp = rcomp vEnv iEnv e}
                     )
                     decls, 
               loc = loc
              }
      | RCVALREC (decls, loc) =>
        TLVALREC
            {
             recbindList = 
               map
                   (fn {var, expTy, exp} => 
                       {boundVar = transVar var, boundTy = rcompTy expTy, boundExp = rcomp vEnv iEnv exp})
                   decls,
             loc = loc
            }
      | RCVALPOLYREC (btvEnv, decls, loc) =>
        let
          val newiEnv = mkIndexEnv btvEnv 
	  val idxvars = IXEnv.listItems newiEnv
        in
            TLVALPOLYREC
                {
                  btvEnv = btvEnv,
		  indexVars = idxvars,
                  recbindList =
                    map
                        (fn {var, expTy, exp} =>
			    {boundVar = transVar var, 
                             boundTy = rcompTy expTy, 
                             boundExp = rcomp vEnv (newiEnv::iEnv) exp})
                        decls,
                  loc = loc
                }
          end
      | RCLOCALDEC (l1, l2, loc) =>
          TLLOCALDEC 
              {
               localDeclList = rcompDecls vEnv iEnv l1, 
               mainDeclList = rcompDecls vEnv iEnv l2, 
               loc = loc
              }
      | RCSETFIELD (valueExp, arrayExp, index, ty, loc) =>
          let
            val newValueExp = rcomp vEnv iEnv valueExp
            val newArrayExp = rcomp vEnv iEnv arrayExp
            val indexExp = TLCONSTANT{value=WORD(Word32.fromInt index), loc=loc}
          in
            TLVAL
            {
             bindList =
               [{
                 boundValIdent = VALIDENTWILD StaticEnv.unitty,
                 boundExp = 
                   TLSETFIELD 
                       {
                        valueExp = newValueExp, 
                        arrayExp = newArrayExp, 
                        indexExp = indexExp, 
                        elementTy = ty, 
                        loc= loc
                       }
               }],
             loc = loc
            }
          end
      | RCSETGLOBAL(string,exp,loc) =>
          TLSETGLOBAL(string, rcomp vEnv iEnv exp,loc)
      | RCSETGLOBALVALUE (arrayIndex, offset, valueExp, ty, loc) =>
        let
          val newValueExp = rcomp vEnv iEnv valueExp
          val newOffsetExp = TLCONSTANT{value=WORD(Word32.fromInt offset), loc=loc}
        in
          TLVAL
            {
             bindList =
               [{
                  boundValIdent = VALIDENTWILD StaticEnv.unitty,
                  boundExp = 
                     TLSETGLOBALVALUE 
                         { 
                          arrayIndex = arrayIndex, 
                          offset = offset,
                          valueExp = newValueExp,
                          ty = rcompTy ty, 
                          loc = loc
                         }
               }],
             loc = loc
            }
        end
      | RCINITARRAY (arrayIndex, size, ty, loc) =>
        let
          val newSizeExp = TLCONSTANT{value=WORD(Word32.fromInt size), loc=loc}
        in
          TLVAL
            {
             bindList =
               [{
                  boundValIdent = VALIDENTWILD StaticEnv.unitty,
                  boundExp = 
                    TLINITARRAY
                        { 
                         arrayIndex = arrayIndex, 
                         size = size,
                         elemTy = ty, 
                         loc = loc
                        }
               }],
             loc = loc
            }
        end
      | RCEMPTY loc => TLEMPTY loc

  and rcompDecls vEnv iEnv decls = map (rcompDecl vEnv iEnv) decls

  fun compile decls = rcompDecls VEnv.empty nil decls

end
