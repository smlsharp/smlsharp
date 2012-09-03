(**
 * AnnotatedCalc utilities
 * @copyright (c) 2006, Tohoku University.
 * @author Huu-Duc Nguyen
 * @version $$
 *)

structure AnnotatedTypesUtils : ANNOTATEDTYPESUTILS = struct

  structure T = Types
  structure AT = AnnotatedTypes
  structure CT = ConstantTerm

  (* Types utilities*)

  fun flatTyList (AT.MVALty tyList) = tyList
    | flatTyList ty = [ty]

  fun constDefaultTy const = 
      case const of
        CT.INT _ => AT.intty
      | CT.WORD _ => AT.wordty
      | CT.REAL _ => AT.realty
      | CT.FLOAT _ => AT.floatty
      | CT.STRING _ => AT.stringty
      | CT.CHAR _ => AT.charty
      | CT.UNIT => AT.unitty

  fun fieldTypes (AT.RECORDty{fieldTypes,...}) = fieldTypes
    | fieldTypes _ = raise Control.Bug "record type is expected"

  fun recordFieldTy (AT.RECORDty{fieldTypes,...}, label) =
      (
       case SEnv.find(fieldTypes, label) of
         SOME ty => ty
       | _ => raise Control.Bug "label not found"
      )
    | recordFieldTy _ = raise Control.Bug "record type is expected"

  fun arrayElementTy (AT.CONty{args=[ty],...}) = ty
    | arrayElementTy _ = raise Control.Bug "array type is expected"

  fun argTyList (AT.FUNMty {argTyList,...}) = argTyList
    | argTyList _ = raise Control.Bug "function type is expected"

  fun expandFunTy (AT.FUNMty arg) = arg
    | expandFunTy _ = raise Control.Bug "function type is expected"

  fun expandRecordTy (AT.RECORDty arg) = arg
    | expandRecordTy _ = raise Control.Bug "record type is expected"
 
  fun substitute subst ty =
      case ty of
        AT.BOUNDVARty tid =>
        (case IEnv.find(subst,tid) of
           SOME ty => ty
         | NONE => ty
        )
      | AT.FUNMty {argTyList, bodyTy, annotation} =>
        AT.FUNMty
            {
             argTyList = map (substitute subst) argTyList,
             bodyTy = substitute subst bodyTy,
             annotation = annotation
            }
      | AT.MVALty tyList => AT.MVALty (map (substitute subst) tyList)
      | AT.RECORDty {fieldTypes, annotation} =>
        AT.RECORDty
            {
             fieldTypes = SEnv.map (substitute subst) fieldTypes,
             annotation = annotation
            }
      | AT.CONty {tyCon, args} =>
        AT.CONty {tyCon = tyCon, args = map (substitute subst) args}
      | AT.POLYty {boundtvars, body} =>
        AT.POLYty
            {
             boundtvars = boundtvars,  (* keep original kinds*)
             body = substitute subst body
            }
      | _ => ty

  and substituteBtvEnv subst btvEnv =
      IEnv.map (substituteBtvKind subst) btvEnv

  and substituteBtvKind subst {id, recKind, eqKind, instancesRef, representationRef} =
      {
       id = id,
       recKind = substituteRecKind subst recKind,
       eqKind = eqKind,
       instancesRef = instancesRef,
       representationRef = representationRef
      }

  and substituteRecKind subst recKind =
      case recKind of 
        AT.UNIV => AT.UNIV
      | AT.REC flty => AT.REC (SEnv.map (substitute subst) flty)
      | AT.OVERLOADED tyList => AT.OVERLOADED (List.map (substitute subst) tyList)


  fun makeSubst (btvEnv, tyList) =
      ListPair.foldr
          (fn ((i, _), ty, S) => IEnv.insert(S, i, ty))
          IEnv.empty
          (IEnv.listItemsi btvEnv, tyList)
      

  fun tpappTy (ty, nil) = ty
    | tpappTy (AT.POLYty{boundtvars, body, ...}, tyl) = 
      substitute (makeSubst (boundtvars, tyl)) body
    | tpappTy _ = raise Control.Bug "tpappTy" 

  fun cardinality ty =
      case ty of 
        AT.MVALty tyList => List.length tyList
      | _ => 1

  val numericalLabelLength = 2

  fun convertNumericalLabel i =
      let
        fun pad 0 = ""
          | pad n = "0" ^ (pad (n - 1))
        val s = Int.toString i
        val n = String.size s
      in
        if n > numericalLabelLength
        then raise Control.Bug "record index is too big"
        else "$" ^ (pad (numericalLabelLength - n)) ^ s
      end

  fun convertLabel label = 
      case Int.fromString label of
        SOME i => convertNumericalLabel i
      | _ => label 

  fun newVar ty = 
      let
        val id = ID.generate()
      in
        {id = id, displayName = "$" ^ ID.toString id, ty = ty}
      end

  fun listCompare f (argList1, argList2) = 
      let
        fun compare ([],[]) = EQUAL 
          | compare (arg1::rest1, arg2::rest2) = 
            (
             case f(arg1,arg2) of
               EQUAL => compare(rest1,rest2)
             | d => d
            )
          | compare _ = raise Control.Bug "argsCompare"
        val n1 = List.length argList1
        val n2 = List.length argList2
      in
        if n1 < n2 
        then LESS 
        else if n1 = n2 then compare(argList1, argList2) else GREATER
      end
      
  fun wordPairCompare ((x1,y1),(x2,y2)) =
      case Word32.compare (x1,x2) of
        GREATER => GREATER
      | EQUAL => Word32.compare(y1,y2)
      | LESS => LESS

  local
    val labelSeed = ref 0
  in
    fun initialize () = labelSeed := 0
    fun freshAnnotationLabel () = !labelSeed before (labelSeed := !labelSeed + 1)
    (* by default, all records are unboxed and not aligned,
     * these properties will be constrainted by unification
     *)
    fun freshRecordAnnotation () = {labels = AT.LE_UNKNOWN, boxed = false, align = false}
    fun freshFunctionAnnotation () = {labels = AT.LE_UNKNOWN, boxed = false}
  end

end
