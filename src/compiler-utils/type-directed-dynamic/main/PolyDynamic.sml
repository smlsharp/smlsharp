(**
 * Type-unsafe polymorphic Dynamic primitives. 
 *
 * @copyright (c) 2016, Tohoku University.
 * @author Atsushi Ohori
 *
 * It uses the type-directed type computation: _typeOf(\tau)
 *
 * This module is not for the genral use; it is mainly for implementing 
 * toJsonObj : ['a#dynamic. 'a -> JSON.json]. The user must use reified JSONObjects.
 * See DynamicToJson structure.
 * 
 *)

structure PolyDynamic =
struct

  local
    structure D = SMLSharp_Builtin.Dynamic
    structure PP = SMLSharp_Builtin.Pointer
    structure P = Pointer
    open JSONTypes
  in
    type object = boxed * word
    type dynamic = {ty : jsonTy, obj : object}
    type tyRep = jsonTy
    exception IlleagalJsonTy
    exception IlleagalObject

    fun ('a#dynamic) dynamic (x:'a) : dynamic = 
        let
          val ty = _typeof('a)
          val obj = (PP.refToBoxed (ref x) : boxed, 0w0)
        in
          {ty = ty, obj = obj}
        end

    fun typeOf (dyn : dynamic) = #ty dyn
    fun objOf (dyn : dynamic) = #obj dyn
    fun objOffset ((boxed, offset):object) = offset
    fun setOffset ((boxed, _):object, offset) = (boxed, offset) : object
    fun mkDynamic x = x

    (* objects *)
    fun offset ((boxed, word), offset) = (boxed, word + offset)
    fun size (boxed, offset) = D.objectSize boxed

    (* offsets *)
    val intSize = 0w4
    val ptrSize = 0w8
    val realSize = 0w8

    fun sizeOf jsonTy = 
        case jsonTy of
          ARRAYty jsonTy => ptrSize
        | BOOLty => intSize
        | INTty => intSize
        | REALty => realSize
        | STRINGty => ptrSize
        | PARTIALBOOLty => ptrSize
        | PARTIALINTty => ptrSize
        | PARTIALREALty => ptrSize
        | PARTIALSTRINGty => ptrSize
        | RECORDty _ => ptrSize
        | OPTIONty jsonTy => ptrSize
        | DYNty => ptrSize
        | PARTIALRECORDty _ => ptrSize
        | NULLty =>raise IlleagalJsonTy

    (* align *)
    val intAlign = 0w4
    val ptrAlign = 0w8
    val realAlign = 0w8

    fun alignOf jsonTy = 
        case jsonTy of
          ARRAYty jsonTy => ptrAlign
        | BOOLty => intAlign
        | INTty => intAlign
        | REALty => realAlign
        | STRINGty => ptrAlign
        | PARTIALBOOLty => ptrAlign
        | PARTIALINTty => ptrAlign
        | PARTIALREALty => ptrAlign
        | PARTIALSTRINGty => ptrAlign
        | RECORDty _ => ptrAlign
        | OPTIONty jsonTy => ptrAlign
        | DYNty => ptrAlign
        | PARTIALRECORDty _ => ptrAlign
        | NULLty =>raise IlleagalJsonTy

    fun align (obj, ty) = 
        let
          val align = alignOf ty
          val delta = objOffset obj
        in
          if delta mod align = 0w0 then obj
          else offset (obj, align - (delta mod align))
        end

    (* primitive objects *)
    fun boolRep 0 = false 
      | boolRep 1 = true 
      | boolRep _ = raise Bug.Bug "illeagal boolean representation"

(*
    fun deref obj = (D.readBoxed (align(obj, RECORDty nil)), 0w0)
    fun getInt obj = D.readInt (align(obj, INTty))
    fun getString obj = D.readString (align(obj, STRINGty))
    fun getReal obj = D.readReal (align(obj, REALty))
    fun getBool obj = boolRep (getInt (align(obj,INTty)))
*)
    fun deref obj = (D.readBoxed obj, 0w0)
    fun getInt obj = D.readInt32 obj
    fun getString obj = D.readString obj
    fun getReal obj = D.readReal64 obj
    fun getBool obj = boolRep (getInt obj)
    (* list primitives *)
    fun isNull obj = P.isNull (D.readPtr obj)
    fun car obj = obj
    fun cdr (ty, obj) = align (offset(obj, sizeOf ty), RECORDty nil)
(*
    fun getList (jsonTy, objGetter) obj =
        let
          fun getRest (obj, listRev) = 
              if isNull obj then listRev
              else 
                let
                  val obj = deref obj
                  val first = objGetter (car obj)
                in
                  getRest (cdr obj, first::listRev)
                end
        in
          List.rev (getRest (obj, nil))
        end
*)
  end

end

