(**
 * @copyright (c) 2018 Tohoku University.
 * @author Atsushi Ohori
 *)

structure DynamicKindUtils =
struct
  structure D = DynamicKind 
  structure T = Types 

  fun bug s = Bug.Bug ("DynamicKindUtils: " ^ s)

  fun recordKindOfTy ty =
      case ty of
        T.ERRORty => #record D.topKind  (* avoid aborting by type error *)
      | T.TYVARty (ref (T.SUBSTITUTED ty)) => recordKindOfTy ty
      | T.TYVARty (ref (T.TVAR {kind = T.KIND {dynamicKind, ...}, ...})) =>
        (case dynamicKind of
           SOME {record, ...} => record
         | NONE => #record D.topKind)
      | T.DUMMYty (_, T.KIND {dynamicKind, ...}) =>
        (case dynamicKind of
           SOME {record, ...} => record
         | NONE => #record D.topKind)
      | T.EXISTty (_, T.KIND {dynamicKind, ...}) =>
        (case dynamicKind of
           SOME {record, ...} => record
         | NONE => #record D.topKind)
      | T.FUNMty _ => #record D.topKind
      | T.CONSTRUCTty {tyCon = {dtyKind, ...}, args} => #record D.topKind
        (*
          (* Opaque types are distinguished from record types. *)
          case dtyKind of
            T.DTY _ => #record D.topKind
          | T.OPAQUE {opaqueRep = T.TYCON tyCon, ...} =>
            recordKindOfTy (T.CONSTRUCTty {tyCon = tyCon, args = args})
          | T.OPAQUE {opaqueRep = T.TFUNDEF {polyTy, ...}, ...} =>
            recordKindOfTy (TypesBasics.tpappTy (polyTy, args))
          | T.INTERFACE (T.TYCON tyCon) =>
            recordKindOfTy (T.CONSTRUCTty {tyCon = tyCon, args = args})
          | T.INTERFACE (T.TFUNDEF {polyTy, ...}) =>
            recordKindOfTy (TypesBasics.tpappTy (polyTy, args))
        *)
      | T.BOUNDVARty btvId => raise bug "BOUNDVARty to kindOfInstacneTy"
      | T.SINGLETONty _ => raise bug "SINGLETONTy to kindOfInstanceTy"
      | T.BACKENDty _ => raise bug "BACKENDty to kindOfInstanceTy"
      | T.POLYty _ => raise bug "POLYty to kindOfInstanceTy"
      | T.RECORDty record =>
        let
          fun align (index, size) =
              Word.andb (index + size - 0w1, 0w0 - size)
          val recordKind =
              (* ToDo: integrate with RecordLayout *)
              RecordLabel.Map.foldli
                (fn (label, ty, NONE) => NONE
                  | (label, ty, SOME (index, indexMap)) =>
                    case TypeLayout2.propertyOf BoundTypeVarID.Map.empty ty of
                      NONE => NONE
                    | SOME {size = D.ANYSIZE, ...} => NONE
                    | SOME {size = D.SIZE size, ...} =>
                      let
                        val size = Word.fromInt (D.getSize size)
                        val nextIndex = align (index, size)
                      in
                        SOME (nextIndex + size,
                              RecordLabel.Map.insert
                                (indexMap, label, nextIndex))
                      end)
                (SOME (0w0, RecordLabel.Map.empty))
                record
        in
          case recordKind of
            NONE => #record D.topKind
          | SOME (_, fields) => fields
        end

  fun kindOfTy ty =
      case ty of
        T.TYVARty (ref (T.SUBSTITUTED ty)) => kindOfTy ty
      | T.BOUNDVARty tid => raise bug "kindOfTy does not work for BOUNDVARty"
      | T.ERRORty => D.topKind  (* avoid aborting by type error *)
      | _ =>
        case TypeLayout2.propertyOf BoundTypeVarID.Map.empty ty of
          NONE => raise bug "kindOfTy"
        | SOME {tag, size, rep} =>
          {tag = tag, size = size, record = recordKindOfTy ty}

  and kindOfStaticKind (T.KIND {properties, tvarKind, dynamicKind}) =
      case TypeLayout2.propertyOfKind
             BoundTypeVarID.Map.empty
             (T.KIND {properties = properties,
                      tvarKind = tvarKind,
                      dynamicKind = NONE}) of
        NONE => NONE
      | SOME {tag, size, rep} =>
        SOME {tag = tag, size = size, record = RecordLabel.Map.empty}

  val lubSizeKind = RuntimeTypes.lubSize
  val lubTagKind = RuntimeTypes.lubTag
  fun lubRecKind (indexMap1, indexMap2) =
      RecordLabel.Map.mergeWith
        (fn (SOME x, SOME y) => if x = y then SOME x else NONE | _ => NONE)
        (indexMap1, indexMap2)
  fun lubKind ({size=s1, tag=t1, record=r1}, {size=s2,tag=t2, record=r2}) = 
      {size = lubSizeKind (s1, s2),
       tag = lubTagKind (t1, t2),
       record = lubRecKind (r1, r2)}
  fun eqKind ({tag=t1, size=s1, record=r1}, {tag=t2, size=s2, record=r2}) =
      t1 = t2 andalso s1 = s2 andalso RecordLabel.Map.eq (op =) (r1, r2)

end
