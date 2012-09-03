(**
 * AnnotatedCalc utilities
 * @copyright (c) 2006, Tohoku University.
 * @author Huu-Duc Nguyen
 * @version $$
 *)
signature ANNOTATEDTYPESUTILS = sig
(*
  val flatTyList : AnnotatedTypes.ty -> AnnotatedTypes.ty list

*)
  val constDefaultTy : ConstantTerm.constant -> AnnotatedTypes.ty
(*

  val fieldTypes : AnnotatedTypes.ty -> AnnotatedTypes.ty SEnv.map

  val recordFieldTy : AnnotatedTypes.ty * string -> AnnotatedTypes.ty

  val arrayElementTy : AnnotatedTypes.ty -> AnnotatedTypes.ty

  val argTyList : AnnotatedTypes.ty -> AnnotatedTypes.ty list

*)
  val expandFunTy : 
      AnnotatedTypes.ty -> 
      {
       argTyList : AnnotatedTypes.ty list,
       bodyTy : AnnotatedTypes.ty,
       annotation : AnnotatedTypes.functionAnnotation ref,
       funStatus : AnnotatedTypes.funStatus
      }
(*

  val expandRecordTy :
      AnnotatedTypes.ty -> 
      {
       fieldTypes : AnnotatedTypes.ty SEnv.map,
       annotation : AnnotatedTypes.recordAnnotation ref
      }
 
  val substitute : AnnotatedTypes.ty BoundTypeVarID.Map.map -> AnnotatedTypes.ty -> AnnotatedTypes.ty

  val makeSubst : AnnotatedTypes.btvEnv * AnnotatedTypes.ty list -> AnnotatedTypes.ty BoundTypeVarID.Map.map

*)
  val tpappTy : AnnotatedTypes.ty * AnnotatedTypes.ty list -> AnnotatedTypes.ty

  val cardinality : AnnotatedTypes.ty -> int

  val convertNumericalLabel : int -> string

  val convertLabel : string -> string
(*
(*
  val newVar : AnnotatedTypes.ty -> AnnotatedTypes.varInfo
*)

  val isGlobal : AnnotatedTypes.varInfo -> bool

  val listCompare :  ('a * 'a -> order) -> ('a list * 'a list) -> order
      
  val wordPairCompare : ((Word32.word * Word32.word) * (Word32.word * Word32.word)) -> order

  val freshAnnotationLabel : unit -> AnnotatedTypes.annotationLabel

  val freshRecordAnnotation : unit -> AnnotatedTypes.recordAnnotation
*)
  val freshFunctionAnnotation : unit -> AnnotatedTypes.functionAnnotation ref
(*
  val coerceClosure : AnnotatedTypes.ty -> unit

  val globalFunStatus : unit -> AnnotatedTypes.funStatus
*)
  val newClosureFunStatus : unit -> AnnotatedTypes.funStatus
(*
  val newLocalFunStatus : AnnotatedTypes.funStatus -> AnnotatedTypes.funStatus

  val substituteBtvEnv : AnnotatedTypes.ty BoundTypeVarID.Map.map -> AnnotatedTypes.btvEnv
			 -> AnnotatedTypes.btvEnv
*)
  val makeClosureFunTy : AnnotatedTypes.ty list
                         * AnnotatedTypes.ty
                         -> AnnotatedTypes.ty
(*
  val makeLocalFunTy : AnnotatedTypes.ty list
                       * AnnotatedTypes.ty
                       -> AnnotatedTypes.ty
*)
  val isLocalFunTy : AnnotatedTypes.ty -> bool
(*
(*
  val generateExtraList : {tagTyCon : int -> 'a, sizeTyCon : int -> 'a, indexTyCon : (int * string) -> 'a} ->
                           AnnotatedTypes.btvEnv -> 'a list
*)
*)
end
