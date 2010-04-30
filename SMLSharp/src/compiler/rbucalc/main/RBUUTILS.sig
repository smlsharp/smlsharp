(**
 * @copyright (c) 2006, Tohoku University.
 * @author Huu-Duc Nguyen
 * @version $$
 *)
signature RBUUTILS = sig

  datatype optimizedBitmapOffset =
           BO_CONST of word
         | BO_TYVAR of RBUTypes.ty
         | BO_NONE

  val word_constant : Word32.word * Loc.loc -> RBUCalc.rbuexp

  val int_constant : Int32.int * Loc.loc -> RBUCalc.rbuexp

  val wordOf : RBUCalc.rbuexp -> Word32.word

  val emptyRecord : Loc.loc -> RBUCalc.rbuexp
  val isEmptyRecord : RBUCalc.rbuexp -> bool

  val atomTagExp : Loc.loc -> RBUCalc.rbuexp

  val boxedTagExp : Loc.loc -> RBUCalc.rbuexp

  val makePrimApply : BuiltinPrimitive.primitive * RBUCalc.rbuexp list * RBUTypes.ty list * RBUTypes.ty list * Loc.loc -> RBUCalc.rbuexp
      
  val word_fromInt : RBUCalc.rbuexp * Loc.loc -> RBUCalc.rbuexp

  val word_add : RBUCalc.rbuexp * RBUCalc.rbuexp * Loc.loc -> RBUCalc.rbuexp

  val word_mul : RBUCalc.rbuexp * RBUCalc.rbuexp * Loc.loc -> RBUCalc.rbuexp

  val word_leftShift : RBUCalc.rbuexp * RBUCalc.rbuexp * Loc.loc -> RBUCalc.rbuexp

  val word_logicalRightShift : RBUCalc.rbuexp * RBUCalc.rbuexp * Loc.loc -> RBUCalc.rbuexp

  val word_andb : RBUCalc.rbuexp * RBUCalc.rbuexp * Loc.loc -> RBUCalc.rbuexp

  val word_orb : RBUCalc.rbuexp * RBUCalc.rbuexp * Loc.loc -> RBUCalc.rbuexp

(*
  val newVar : RBUCalc.varKind -> RBUTypes.ty -> RBUCalc.varInfo
*)

  val maxSize : unit -> word
  val pointerSize : unit -> word
  val pointerSizeScale : unit -> word

  val constSize : RBUTypes.ty -> word option

  val constTag : RBUTypes.ty -> word option

  val constBitmap : RBUTypes.ty list -> word option

  val constEnvBitmap : RBUTypes.ty list * Word32.word list -> word option

  val constOffset : RBUTypes.ty list -> word option

  val optimizeBitmap : RBUTypes.ty list -> optimizedBitmapOffset

  val optimizeEnvBitmap : RBUTypes.ty list * Word32.word list -> optimizedBitmapOffset

  val optimizeOffset : RBUTypes.ty list -> optimizedBitmapOffset

  val constSizeExp : RBUCalc.ty * RBUCalc.loc -> RBUCalc.rbuexp

  val constTagExp : RBUCalc.ty * RBUCalc.loc -> RBUCalc.rbuexp

  val getLocOfExp : RBUCalc.rbuexp -> Loc.loc

  val generateExtraArgTyList : AnnotatedTypes.btvEnv -> AnnotatedTypes.btvEnv -> RBUTypes.ty list

  val toRBUType : AnnotatedTypes.btvEnv * AnnotatedTypes.ty -> RBUTypes.ty

end

