(**
 * base of implementations of the MONO_ARRAY signature.
 * @author YAMATODANI Kiyoshi
 * @version $Id: MonoArrayBase.sml,v 1.5 2006/02/20 01:41:11 kiyoshiy Exp $
 *)
functor MonoArrayBase
            (B
             : sig
               type elem
               type array
               val maxLen : int
               val makeArray : int * elem -> array
               val length : array -> int
               val update : array * int * elem -> unit
               val sub : array * int -> elem
               val emptyArray : unit -> array
             end) =
struct

  (***************************************************************************)

  structure Vector = MonoVectorBase(B)
  open Vector

  (***************************************************************************)

  type array = vector

  (***************************************************************************)

  fun update (array, index, newValue) = 
      if index < 0 orelse (B.length array) <= index
      then raise Subscript (* if buffer = NONE, the sub always fails. *)
      else B.update (array, index, newValue)

  local
    fun copyArray srcArray destArray destStart =
        case B.length srcArray of
          0 => B.emptyArray ()
        | len => 
          let
            fun write ~1 = ()
              | write index =
                let val value = sub(srcArray, index)
                in
                  update (destArray, destStart + index, value);
                  write (index - 1)
                end
          in
            write (len - 1); destArray
          end
  in
  fun copy {src, dst, di} =
      if (di < 0) orelse (length dst < di + length src)
      then raise General.Subscript
      else let val _ = copyArray src dst di in () end
  val copyVec = copy
  end

  (* NOTE: A fresh copy is generated. *)
  fun vector array =
      fromList(foldr (fn (element, accum) => element :: accum) [] array)

  fun modifyi modifyFun array =
      appi
          (fn (index, element) =>
              update (array, index, (modifyFun (index, element))))
          array

  fun modify modifyFun array =
      modifyi (fn (_, element) => modifyFun element) array

  fun array (length, initial) =
      if (length < 0) orelse (maxLen < length)
      then raise General.Size
      else B.makeArray(length, initial)

  (***************************************************************************)

end;