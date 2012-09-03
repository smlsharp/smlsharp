(**
 * @copyright (c) 2006, Tohoku University.
 * @author Huu-Duc Nguyen
 * @version $$
 *)
structure RBUUtils : RBUUTILS = struct
  structure BT = BasicTypes
  structure AT = AnnotatedTypes
  structure ATU = AnnotatedTypesUtils
  structure RT = RBUTypes
  structure CT = ConstantTerm
  structure RN = RuntimeTypes
  structure P = BuiltinPrimitive
  open RBUCalc

  datatype optimizedBitmapOffset =
           BO_CONST of word
         | BO_TYVAR of RT.ty
         | BO_NONE

  fun word_constant (w, loc) =  RBUCONSTANT {value = CT.WORD w, loc = loc}
  fun int_constant (i, loc) =  RBUCONSTANT {value = CT.INT i, loc = loc}
  fun wordOf (RBUCONSTANT {value = CT.WORD w,...}) = w
    | wordOf _ = raise Control.Bug "invalid word constant"

  fun emptyRecord loc =
      RBURECORD
          {
           bitmapExp = RBUCONSTANT {value = CT.WORD 0w0, loc = loc},
           totalSizeExp = RBUCONSTANT {value = CT.WORD 0w0, loc = loc},
           fieldList = [],
           fieldTyList = [],
           fieldSizeExpList = [],
           isMutable = false,
           loc = loc
          }

  fun isEmptyRecord (RBURECORD {fieldList = [], isMutable = false, ...}) = true
    | isEmptyRecord _ = false

  fun atomTagExp loc = word_constant (0w0,loc)
  fun boxedTagExp loc = word_constant (0w1,loc)

(*
  fun newVar varKind ty = 
      let
        val id = ID.generate()
      in
        {id = id, displayName = "$" ^ (ID.toString id), ty = ty, varKind = ref varKind}
      end
*)

  fun align (x, y) =
      (x + y - 0w1) - (x + y - 0w1) mod y

  fun maxSize () =
      if !Control.enableUnboxedFloat
      then if Control.nativeGen() then 0w8 else 0w2
      else if Control.nativeGen() then 0w4 else 0w1
  fun pointerSize () = if Control.nativeGen() then 0w4 else 0w1
  fun pointerSizeScale () = if Control.nativeGen() then 0w2 else 0w0

  fun constSize ty =
      if Control.nativeGen()
      then
        case ty of
          RT.ATOMty => SOME 0w4
        | RT.BOXEDty => SOME 0w4
        | RT.DOUBLEty =>
          if !Control.enableUnboxedFloat
          then SOME 0w8
          else SOME 0w4
        | RT.BOUNDVARty tid =>
          if !Control.enableUnboxedFloat
          then NONE
          else SOME 0w4
        | RT.SINGLEty _ => SOME 0w4
        | RT.UNBOXEDty tid =>
          if !Control.enableUnboxedFloat
          then NONE
          else SOME 0w4
        | RT.PADty {condTy, tyList} =>
          if !Control.enableUnboxedFloat
          then
            case constOffset tyList of
              NONE => NONE
            | SOME offset =>
              if offset mod maxSize () = 0w0 then SOME 0w0
              else
                case constSize condTy of
                  NONE => NONE
                | SOME size =>
                  if offset mod size = 0w0 then SOME 0w0
                  else SOME (align (offset, size) - offset)
          else SOME 0w0
        | RT.TAGty _ => SOME 0w4
        | RT.SIZEty _ => SOME 0w4
        | RT.INDEXty _ => SOME 0w4
        | RT.BITMAPty _ => SOME 0w4
        | RT.OFFSETty _ => SOME 0w4
        | RT.ENVBITMAPty _ => SOME 0w4
        | RT.FRAMEBITMAPty _ => SOME 0w4
        | RT.PADSIZEty _ => SOME 0w4
      else

      case ty of
        RT.ATOMty => SOME 0w1
      | RT.BOXEDty => SOME 0w1
      | RT.DOUBLEty =>
        if !Control.enableUnboxedFloat
        then SOME 0w2
        else SOME 0w1
      | RT.BOUNDVARty tid =>
        if !Control.enableUnboxedFloat
        then NONE
        else SOME 0w1
      | RT.SINGLEty _ => SOME 0w1
      | RT.UNBOXEDty tid =>
        if !Control.enableUnboxedFloat
        then NONE
        else SOME 0w1
      | RT.PADty {condTy, tyList} =>
        if !Control.enableUnboxedFloat
        then
          case constSize condTy of
            SOME 0w1 => SOME 0w0
          | size =>
            case constOffset tyList of
              NONE => NONE
            | SOME n =>
              if Word.andb(n,0w1) = 0w0 then SOME 0w0
              else
                case size of
                  NONE => NONE
                | SOME 0w2 => SOME 0w1
                | _ => raise Control.Bug "illeagal size to constSize (rbucalc/main/RBUUtils.sml)"
        else SOME 0w0
      | RT.TAGty _ => SOME 0w1
      | RT.SIZEty _ => SOME 0w1
      | RT.INDEXty _ => SOME 0w1
      | RT.BITMAPty _ => SOME 0w1
      | RT.OFFSETty _ => SOME 0w1
      | RT.ENVBITMAPty _ => SOME 0w1
      | RT.FRAMEBITMAPty _ => SOME 0w1
      | RT.PADSIZEty _ => SOME 0w1
  and constTag ty =
      case ty of
        RT.ATOMty => SOME 0w0
      | RT.BOXEDty => SOME 0w1
      | RT.DOUBLEty => SOME 0w0
      | RT.BOUNDVARty _ => NONE
      | RT.SINGLEty _ => NONE
      | RT.UNBOXEDty _ => SOME 0w0
      | RT.PADty {condTy, tyList} => SOME 0w0
      | RT.TAGty _ => SOME 0w0
      | RT.SIZEty _ => SOME 0w0
      | RT.INDEXty _ => SOME 0w0
      | RT.BITMAPty _ => SOME 0w0
      | RT.OFFSETty _ => SOME 0w0
      | RT.ENVBITMAPty _ => SOME 0w0
      | RT.FRAMEBITMAPty _ => SOME 0w0
      | RT.PADSIZEty _ => SOME 0w0

  and constBitmap [] = SOME 0w0
    | constBitmap (ty::tyList) =
      (
       case constTag ty of
         SOME tag =>
         (case constSize ty of
            SOME size =>
            (
             case constBitmap tyList of
               SOME bitmap => SOME (Word.orb(Word.<<(bitmap,Word.>>(size, pointerSizeScale())),tag))
             | NONE => NONE
            )
          | NONE => NONE
         )
       | NONE => NONE
      )

  and constEnvBitmap ([],[]) = SOME 0w0
    | constEnvBitmap (ty::tyList, fixedSize::fixedSizeList) =
      (
       case constTag ty of
         SOME tag =>
         (
          case constEnvBitmap (tyList,fixedSizeList) of
            SOME bitmap =>
            SOME (Word.orb(Word.<<(bitmap,Word.>>(BT.UInt32ToWord fixedSize, pointerSizeScale())),tag))
          | NONE => NONE
         )
       | NONE => NONE
      )
    | constEnvBitmap _ = 
      raise Control.Bug "tylist and sizelist disagree consEnvBitmap (rbucalc/main/RBUUtils.sml)"

  and constOffset [] = SOME 0w0
    | constOffset (ty::tyList) =
      (
       case constSize ty of
         SOME size =>
         (
          case constOffset tyList of
            SOME offset => SOME (size + offset)
          | NONE => NONE
         )
       | NONE => NONE
      )

  fun optimizeBitmap [] = BO_CONST 0w0
    | optimizeBitmap (tyList as (ty::tyRest)) =
      (
       case constBitmap tyRest of 
         SOME 0w0 =>
         (
          case constTag ty of 
            SOME w => BO_CONST w 
          | NONE => BO_TYVAR ty
         )
       | SOME bitmap =>
         (
          case constTag ty of
            SOME tag =>
            (
             case constSize ty of
               SOME size => BO_CONST (Word.orb(Word.<<(bitmap,Word.>>(size,pointerSizeScale())),tag))
             | NONE => BO_NONE
            )
          | NONE => BO_NONE
         )
       | NONE => BO_NONE
      )

  fun optimizeEnvBitmap ([],[]) = BO_CONST 0w0
    | optimizeEnvBitmap (tyList as (ty::tyRest), fixedSizeList as (size::sizeRest)) =
      (
       case constEnvBitmap (tyRest, sizeRest) of 
         SOME 0w0 =>
         (
          case constTag ty of 
            SOME w => BO_CONST w 
          | NONE => BO_TYVAR ty
         )
       | SOME bitmap =>
         (
          case constTag ty of
            SOME tag => BO_CONST (Word.orb(Word.<<(bitmap,Word.>>(BT.UInt32ToWord size,pointerSizeScale())),tag))
          | NONE => BO_NONE
         )
       | NONE => BO_NONE
      )
    | optimizeEnvBitmap _ = 
      raise Control.Bug "tylist and sizelist disagree optimizeEnvBitmap (rbucalc/main/RBUUtils.sml)"

  fun optimizeOffset [] = BO_CONST 0w0
    | optimizeOffset [ty] =
      (
       case constSize ty of
         SOME w => BO_CONST w
       | NONE => BO_TYVAR ty
      )
    | optimizeOffset tyList =
      (
       case constOffset tyList of
         SOME w => BO_CONST w
       | NONE => BO_NONE
      )

  fun constSizeExp (ty, loc) =
      case constSize ty of
        SOME x => word_constant (BT.WordToUInt32 x, loc)
      | NONE => raise Control.Bug "constSizeExp"

  fun constTagExp (ty, loc) =
      case constTag ty of
        SOME x => word_constant (BT.WordToUInt32 x, loc)
      | NONE => raise Control.Bug "constTagExp"

  fun makePrimApply (prim, argList, argTyList, resultTyList, loc) =
      RBUPRIMAPPLY
          {
           prim = prim,
           argExpList = argList,
           argTyList = argTyList,
           resultTyList = resultTyList,
           argSizeExpList = map (fn ty => constSizeExp (ty,loc)) argTyList,
           instSizeExpList = nil,
           instTagExpList = nil,
           loc = loc
          }

  fun word_fromInt (intExp, loc) = 
      makePrimApply (P.Word_fromInt,[intExp],[RT.ATOMty],[RT.ATOMty],loc)

  fun word_add (e1,e2,loc) = 
      makePrimApply (P.Word_add,[e1,e2],[RT.ATOMty,RT.ATOMty],[RT.ATOMty],loc)

  fun word_mul (e1,e2,loc) = 
      makePrimApply (P.Word_mul,[e1,e2],[RT.ATOMty,RT.ATOMty],[RT.ATOMty],loc)

  fun word_leftShift (e1,e2,loc) = 
      makePrimApply (P.Word_lshift,[e1,e2],[RT.ATOMty,RT.ATOMty],[RT.ATOMty],loc)

  fun word_logicalRightShift (e1,e2,loc) = 
      makePrimApply (P.Word_rshift,[e1,e2],[RT.ATOMty,RT.ATOMty],[RT.ATOMty],loc)

  fun word_andb (e1,e2,loc) = 
      makePrimApply (P.Word_andb,[e1,e2],[RT.ATOMty,RT.ATOMty],[RT.ATOMty],loc)

  fun word_orb (e1,e2,loc) = 
      makePrimApply (P.Word_orb,[e1,e2],[RT.ATOMty,RT.ATOMty],[RT.ATOMty],loc)

  fun getLocOfExp exp =
      case exp of
        RBUFOREIGNAPPLY {loc,...} => loc
      | RBUCALLBACKCLOSURE {loc,...} => loc
      | RBUCONSTANT {loc,...} => loc
      | RBUGLOBALSYMBOL {loc,...} => loc
      | RBUEXCEPTIONTAG {loc,...} => loc
      | RBUVAR {loc,...} => loc
      | RBULABEL {loc,...} => loc
      | RBUGETFIELD {loc,...} => loc
      | RBUSETFIELD {loc,...} => loc
      | RBUSETTAIL {loc,...} => loc
      | RBUARRAY {loc,...} => loc
      | RBUCOPYARRAY {loc,...} => loc
      | RBUPRIMAPPLY {loc,...} => loc
      | RBUAPPM {loc,...} => loc
      | RBULOCALAPPM {loc,...} => loc
      | RBURECCALL {loc,...} => loc
      | RBUINNERCALL {loc,...} => loc
      | RBULET {loc,...} => loc
      | RBUMVALUES {loc,...} => loc
      | RBURECORD {loc,...} => loc
      | RBUENVRECORD {loc,...} => loc
      | RBUSELECT {loc,...} => loc
      | RBUMODIFY {loc,...} => loc
      | RBURAISE {loc,...} => loc
      | RBUHANDLE {loc,...} => loc
      | RBUSWITCH {loc,...} => loc
      | RBUCLOSURE {loc,...} => loc
      | RBUENTRYCLOSURE {loc,...} => loc
      | RBUINNERCLOSURE {loc,...} => loc

  (* FIXME: we need more runtime types. *)
  datatype rep =
      UNKNOWN_REP
    | GENERIC_REP
    | ATOM_REP
    | BOXED_REP
    | DOUBLE_REP
    | SINGLE_REP
    | UNBOXED_REP

  fun antiUnify (rep1,rep2) =
      case (rep1,rep2) of
        (UNKNOWN_REP, _) => rep2
      | (_, UNKNOWN_REP) => rep1
      | (GENERIC_REP, _) => GENERIC_REP
      | (_,GENERIC_REP) => GENERIC_REP
      | (ATOM_REP,ATOM_REP) => ATOM_REP
      | (ATOM_REP,BOXED_REP) => SINGLE_REP
      | (ATOM_REP,DOUBLE_REP) => UNBOXED_REP
      | (ATOM_REP,SINGLE_REP) => SINGLE_REP
      | (ATOM_REP,UNBOXED_REP) => UNBOXED_REP

      | (BOXED_REP,ATOM_REP) => SINGLE_REP
      | (BOXED_REP,BOXED_REP) => BOXED_REP
      | (BOXED_REP,DOUBLE_REP) => GENERIC_REP
      | (BOXED_REP,SINGLE_REP) => SINGLE_REP
      | (BOXED_REP,UNBOXED_REP) => GENERIC_REP

      | (DOUBLE_REP,ATOM_REP) => UNBOXED_REP
      | (DOUBLE_REP,BOXED_REP) => GENERIC_REP
      | (DOUBLE_REP,DOUBLE_REP) => DOUBLE_REP
      | (DOUBLE_REP,SINGLE_REP) => GENERIC_REP
      | (DOUBLE_REP,UNBOXED_REP) => UNBOXED_REP

      | (SINGLE_REP,ATOM_REP) => SINGLE_REP
      | (SINGLE_REP,BOXED_REP) => SINGLE_REP
      | (SINGLE_REP,DOUBLE_REP) => GENERIC_REP
      | (SINGLE_REP,SINGLE_REP) => SINGLE_REP
      | (SINGLE_REP,UNBOXED_REP) => GENERIC_REP

      | (UNBOXED_REP,ATOM_REP) => UNBOXED_REP
      | (UNBOXED_REP,BOXED_REP) => GENERIC_REP
      | (UNBOXED_REP,DOUBLE_REP) => UNBOXED_REP
      | (UNBOXED_REP,SINGLE_REP) => GENERIC_REP
      | (UNBOXED_REP,UNBOXED_REP) => UNBOXED_REP


  fun repOf btvEnv ty =
      case ty of
        AT.ERRORty => ATOM_REP
      | AT.DUMMYty _ => ATOM_REP
      | AT.BOUNDVARty tid =>
        (
         case IEnv.find(btvEnv,tid) of 
           NONE => raise Control.Bug ("type variable not found: t"^Int.toString tid)
         | SOME btvKind => computeRep btvEnv btvKind
        )
      | AT.FUNMty _ => BOXED_REP
      | AT.MVALty _ => raise Control.Bug "repOf: MVALty"
      | AT.RECORDty _ => BOXED_REP
      | AT.RAWty {tyCon = tyCon as {id, constructorHasArgFlagList, ...}, ...} =>
        (
          case TyConID.Map.find (#runtimeTyEnv BuiltinContext.builtinContext, id) of
            SOME RN.UCHARty => ATOM_REP
          | SOME RN.INTty => ATOM_REP
          | SOME RN.UINTty => ATOM_REP
          | SOME RN.BOXEDty => BOXED_REP
          | SOME RN.POINTERty => ATOM_REP
          | SOME RN.DOUBLEty =>
            if !Control.enableUnboxedFloat then DOUBLE_REP else BOXED_REP
          | SOME RN.FLOATty => ATOM_REP
          | SOME RN.EXNTAGty =>
            if Control.nativeGen() andalso
               #cpu (Control.targetInfo ()) <> "newvm"
            then BOXED_REP else ATOM_REP
          | NONE => 
            if TLNormalization.isAtomicTyCon tyCon
            then ATOM_REP else BOXED_REP
        )
      | AT.POLYty {boundtvars, body} =>
        (
         case body of
           AT.BOUNDVARty tid =>
           (
            case IEnv.find(boundtvars,tid) of
              SOME _ => BOXED_REP
            | _ => repOf boundtvars (AT.BOUNDVARty tid)
           )
         | _ => repOf (IEnv.unionWith #2 (btvEnv, boundtvars)) body
        )
      | AT.SPECty ty => GENERIC_REP

  and computeRep btvEnv ({instancesRef, recordKind, ...} : AT.btvKind) =
      case recordKind of
        AT.REC _ => BOXED_REP
      | _ => GENERIC_REP
(*
 * FIXME: instancesRef may contain free BOUNDVARty and we cannot compute
 * representations of such free BOUNDVARty only with btvEnv of current
 * context.
 *)
(*
        if !Control.doRepresentationAnalysis
        then
          case !instancesRef of
            nil => GENERIC_REP
          | l => foldl (fn (ty,rep) => antiUnify (repOf btvEnv ty, rep))
                       UNKNOWN_REP l
        else GENERIC_REP
*)

  fun toRBUType (btvEnv, atty) =
      case (atty, repOf btvEnv atty) of
        (_, ATOM_REP) => RT.ATOMty
      | (_, BOXED_REP) => RT.BOXEDty
      | (_, DOUBLE_REP) => RT.DOUBLEty
      | (AT.BOUNDVARty id, SINGLE_REP) => RT.SINGLEty id
      | (AT.BOUNDVARty id, UNBOXED_REP) => RT.UNBOXEDty id
      | (AT.BOUNDVARty id, GENERIC_REP) => RT.BOUNDVARty id
      | (AT.SPECty _, GENERIC_REP) => raise Control.Bug "FIXME: not implemented"
      | _ => raise Control.Bug "toRBUType"

  fun generateExtraArgTyList btvEnv (newBtvEnv : AT.btvEnv) =
      let
        fun generate (btvKind as {id,recordKind,...}) =
            case recordKind of
              AT.REC flty =>
              map (fn label => RT.INDEXty{label = label, recordTy = RT.BOUNDVARty id}) (SEnv.listKeys flty)
            | _ =>
              case computeRep btvEnv btvKind of
                ATOM_REP => []
              | BOXED_REP => []
              | DOUBLE_REP => []
              | SINGLE_REP => [RT.TAGty id]
              | UNBOXED_REP => [RT.SIZEty id]
              | _ => 
                if !Control.enableUnboxedFloat
                then [RT.TAGty id, RT.SIZEty id]
                else [RT.TAGty id]
      in
        IEnv.foldr (fn (btvKind, L) => (generate btvKind) @ L) [] newBtvEnv
      end

end
