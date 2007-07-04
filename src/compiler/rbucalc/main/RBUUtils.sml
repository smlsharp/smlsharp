(**
 * @copyright (c) 2006, Tohoku University.
 * @author Huu-Duc Nguyen
 * @version $$
 *)
structure RBUUtils : RBUUTILS = struct
  structure BT = BasicTypes
  structure AT = AnnotatedTypes
  structure CT = ConstantTerm
  open RBUCalc

  datatype optimizedBitmapOffset =
           BO_CONST of word
         | BO_TYVAR of AT.ty
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

  fun singleSizeExp loc = word_constant (0w1,loc)
  fun doubleSizeExp loc = word_constant (0w2,loc)
  fun atomTagExp loc = word_constant (0w0,loc)
  fun boxedTagExp loc = word_constant (0w1,loc)

  (* FIXME: currently we assume that the size of one word is 4 bytes,
   *        but this should be varied depending on both the platform
   *        and the runtime system. *)
  fun wordBytesExp loc = int_constant (4,loc)

  fun makePrimApply (primName, argList, argTyList, loc) =
      let
        fun sizeOf AT.ATOMty = singleSizeExp loc
          | sizeOf AT.DOUBLEty = doubleSizeExp loc
          | sizeOf AT.BOXEDty = singleSizeExp loc
      in
        RBUPRIMAPPLY
            {
             primName = primName,
             argExpList = argList,
             argTyList = argTyList,
             argSizeExpList = map sizeOf argTyList,
             loc = loc
            }
      end
      
  fun word_fromInt (intExp, loc) = 
      makePrimApply ("Word_fromInt",[intExp],[AT.ATOMty],loc)

  fun word_add (e1,e2,loc) = 
      makePrimApply ("addWord",[e1,e2],[AT.ATOMty,AT.ATOMty],loc)

  fun word_leftShift (e1,e2,loc) = 
      makePrimApply ("Word_leftShift",[e1,e2],[AT.ATOMty,AT.ATOMty],loc)

  fun word_logicalRightShift (e1,e2,loc) = 
      makePrimApply ("Word_logicalRightShift",[e1,e2],[AT.ATOMty,AT.ATOMty],loc)

  fun word_andb (e1,e2,loc) = 
      makePrimApply ("Word_andb",[e1,e2],[AT.ATOMty,AT.ATOMty],loc)

  fun word_orb (e1,e2,loc) = 
      makePrimApply ("Word_andb",[e1,e2],[AT.ATOMty,AT.ATOMty],loc)

  fun newVar varKind ty = 
      let
        val id = ID.generate()
      in
        {id = id, displayName = "$" ^ (ID.toString id), ty = ty, varKind = ref varKind}
      end

  fun constSize ty =
      if !Control.enableUnboxedFloat
      then
        (
         case ty of
           AT.ATOMty => SOME 0w1
         | AT.BOXEDty => SOME 0w1
         | AT.DOUBLEty => SOME 0w2
         | AT.BOUNDVARty tid => NONE
         | AT.SINGLEty _ => SOME 0w1
         | AT.UNBOXEDty tid => NONE
         | AT.PADty {condTy, tyList} =>
           (
            case constSize condTy of
              SOME 0w1 => SOME 0w0
            | SOME 0w2 => 
              (
               case constOffset tyList of
                 SOME n =>
                 if Word.andb(n,0w1) = 0w1 then SOME 0w1 else SOME 0w0
               | NONE => NONE
              )
            | NONE => NONE
           )
         | AT.TAGty _ => SOME 0w1
         | AT.SIZEty _ => SOME 0w1
         | AT.INDEXty _ => SOME 0w1
         | AT.BITMAPty _ => SOME 0w1
         | AT.OFFSETty _ => SOME 0w1
         | AT.ENVBITMAPty _ => SOME 0w1
         | AT.FRAMEBITMAPty _ => SOME 0w1
         | AT.PADSIZEty _ => SOME 0w1
         | _ => raise Control.Bug "sizeOf: invalid compact type"
        )                  
      else SOME 0w1
  and constTag ty =
      case ty of
        AT.ATOMty => SOME 0w0
      | AT.BOXEDty => SOME 0w1
      | AT.DOUBLEty => SOME 0w0
      | AT.BOUNDVARty _ => NONE
      | AT.SINGLEty _ => NONE
      | AT.UNBOXEDty _ => SOME 0w0
      | AT.PADty {condTy, tyList} => SOME 0w0
      | AT.TAGty _ => SOME 0w0
      | AT.SIZEty _ => SOME 0w0
      | AT.INDEXty _ => SOME 0w0
      | AT.BITMAPty _ => SOME 0w0
      | AT.OFFSETty _ => SOME 0w0
      | AT.ENVBITMAPty _ => SOME 0w0
      | AT.FRAMEBITMAPty _ => SOME 0w0
      | AT.PADSIZEty _ => SOME 0w0
      | _ => raise Control.Bug "sizeOf: invalid compact type"

  and constBitmap [] = SOME 0w0
    | constBitmap (ty::tyList) =
      (
       case constTag ty of
         SOME tag =>
         (case constSize ty of
            SOME size =>
            (
             case constBitmap tyList of
               SOME bitmap => SOME (Word.orb(Word.<<(bitmap, size),tag))
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
            SOME (Word.orb(Word.<<(bitmap,BT.UInt32ToWord fixedSize),tag))
          | NONE => NONE
         )
       | NONE => NONE
      )

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
               SOME size => BO_CONST (Word.orb(Word.<<(bitmap,size),tag))
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
            SOME tag => BO_CONST (Word.orb(Word.<<(bitmap,BT.UInt32ToWord size),tag))
          | NONE => BO_NONE
         )
       | NONE => BO_NONE
      )

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

  fun getLocOfExp exp =
      case exp of
        RBUFOREIGNAPPLY {loc,...} => loc
      | RBUEXPORTCALLBACK {loc,...} => loc
      | RBUCONSTANT {loc,...} => loc
      | RBUEXCEPTIONTAG {loc,...} => loc
      | RBUVAR {loc,...} => loc
      | RBULABEL {loc,...} => loc
      | RBUGETGLOBAL {loc,...} => loc
      | RBUSETGLOBAL {loc,...} => loc
      | RBUINITARRAY {loc,...} => loc
      | RBUGETFIELD {loc,...} => loc
      | RBUSETFIELD {loc,...} => loc
      | RBUSETTAIL {loc,...} => loc
      | RBUARRAY {loc,...} => loc
      | RBUPRIMAPPLY {loc,...} => loc
      | RBUAPPM {loc,...} => loc
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


end

