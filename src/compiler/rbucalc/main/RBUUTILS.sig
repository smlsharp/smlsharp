(**
 * @copyright (c) 2006, Tohoku University.
 * @author Huu-Duc Nguyen
 * @version $$
 *)
signature RBUUTILS = sig

  datatype optimizedBitmapOffset =
           BO_CONST of word
         | BO_TYVAR of AnnotatedTypes.ty
         | BO_NONE

  val word_constant : Word32.word * Loc.loc -> RBUCalc.rbuexp

  val int_constant : Int32.int * Loc.loc -> RBUCalc.rbuexp

  val wordOf : RBUCalc.rbuexp -> Word32.word

  val emptyRecord : Loc.loc -> RBUCalc.rbuexp

  val singleSizeExp : Loc.loc -> RBUCalc.rbuexp

  val doubleSizeExp : Loc.loc -> RBUCalc.rbuexp

  val atomTagExp : Loc.loc -> RBUCalc.rbuexp

  val boxedTagExp : Loc.loc -> RBUCalc.rbuexp

  val wordBytesExp : Loc.loc -> RBUCalc.rbuexp

  val makePrimApply : string * RBUCalc.rbuexp list * AnnotatedTypes.ty list * Loc.loc -> RBUCalc.rbuexp
      
  val word_fromInt : RBUCalc.rbuexp * Loc.loc -> RBUCalc.rbuexp

  val word_add : RBUCalc.rbuexp * RBUCalc.rbuexp * Loc.loc -> RBUCalc.rbuexp

  val word_leftShift : RBUCalc.rbuexp * RBUCalc.rbuexp * Loc.loc -> RBUCalc.rbuexp

  val word_logicalRightShift : RBUCalc.rbuexp * RBUCalc.rbuexp * Loc.loc -> RBUCalc.rbuexp

  val word_andb : RBUCalc.rbuexp * RBUCalc.rbuexp * Loc.loc -> RBUCalc.rbuexp

  val word_orb : RBUCalc.rbuexp * RBUCalc.rbuexp * Loc.loc -> RBUCalc.rbuexp

  val newVar : RBUCalc.varKind -> AnnotatedTypes.ty -> RBUCalc.varInfo

  val constSize : AnnotatedTypes.ty -> word option

  val constTag : AnnotatedTypes.ty -> word option

  val constBitmap : AnnotatedTypes.ty list -> word option

  val constEnvBitmap : AnnotatedTypes.ty list * Word32.word list -> word option

  val constOffset : AnnotatedTypes.ty list -> word option

  val optimizeBitmap : AnnotatedTypes.ty list -> optimizedBitmapOffset

  val optimizeEnvBitmap : AnnotatedTypes.ty list * Word32.word list -> optimizedBitmapOffset

  val optimizeOffset : AnnotatedTypes.ty list -> optimizedBitmapOffset

  val getLocOfExp : RBUCalc.rbuexp -> Loc.loc
end

