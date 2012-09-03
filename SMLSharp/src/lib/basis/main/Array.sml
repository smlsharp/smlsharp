(**
 * Array structure.
 * @author YAMATODANI Kiyoshi
 * @copyright 2010, Tohoku University.
 * @version $Id: Array.sml,v 1.12 2008/03/11 08:53:57 katsu Exp $
 *)
structure Array =
struct

  (***************************************************************************)

  (*
   * The primitive operations on array type are same with those of
   * Vector.vector type.
   *)
  structure V = Vector

  structure P =
  struct
    val maxLen = V.maxLen
    fun makeArray (intSize, initial) =
        if intSize < 0 orelse maxLen < intSize
        then raise General.Size
        else SMLSharp.PrimArray.array(intSize, initial)
    fun makeVector (intSize, initial) =
        if intSize < 0 orelse maxLen < intSize
        then raise General.Size
        else SMLSharp.PrimArray.vector(intSize, initial)
    (* ToDo : to create an empty array, new primitive should be added ? *)
    fun makeEmptyArray _ = _cast (SMLSharp.PrimArray.array(0, 0)) : 'a array
    fun makeEmptyVector _ = _cast (SMLSharp.PrimArray.vector(0, 0)) : 'a V.vector

    fun update (array, intIndex, value) =
        SMLSharp.PrimArray.update_unsafe (array, intIndex, value)
    fun copy (src, srcIndex, dst, dstIndex, length) =
        SMLSharp.PrimArray.copy_unsafe (src, srcIndex, dst, dstIndex, length)
    fun sub (array, intIndex) = SMLSharp.PrimArray.sub_unsafe (array, intIndex)
    fun length array = SMLSharp.PrimArray.length array
  end

  type 'a array = 'a array
  type 'a vector = 'a V.vector

  val maxLen = P.maxLen

  val array = P.makeArray

  fun fromList [] = P.makeEmptyArray ()
    | fromList (head :: tail) =
      let
        val bufferLength = 1 + List.length tail
        val buffer = P.makeArray (bufferLength, head)
        fun write [] _ = ()
          | write (next :: remains) index =
            (P.update (buffer, index, next); write remains (index + 1))
      in
        (* write elements from the second element. *)
        write tail 1; 
        buffer
      end

  fun tabulate (number, generator) =
      if number = 0
      then P.makeEmptyArray ()
      else
        let
          val target = P.makeArray (number, generator 0)
          fun fill i = 
              if i = number
              then ()
              else (P.update(target, i, generator i); fill (i + 1))
          val _ = fill 1
        in
          target
        end

  fun length array = P.length array

  fun sub (array, index) =
      if index < 0 orelse P.length array <= index
      then raise Subscript (* if buffer = NONE, the sub always fails. *)
      else P.sub (array, index)

  fun 'a update (array, index, newValue) = 
      if index < 0 orelse length array <= index
      then raise Subscript (* if buffer = NONE, the sub always fails. *)
      else P.update (array, index, newValue)

  fun copy {src, dst, di} =
      let val srclen = length src
      in
        if (di < 0) orelse (length dst < di + srclen)
        then raise General.Subscript
        else P.copy (src, 0, dst, di, srclen)
      end
  val copyVec = copy

  (* NOTE: A fresh copy is generated. *)
  fun vector array =
      case P.length array of
        0 => P.makeEmptyVector ()
      | len => 
      let val dst = P.makeVector (len, P.sub (array, 0))
      in copy {src = array, dst = dst, di = 0}; dst end

  val appi = V.appi
  val app = V.app

  fun modifyi modifyFun array =
      appi
          (fn (index, element) =>
              update (array, index, (modifyFun (index, element))))
          array

  fun modify modifyFun array =
      modifyi (fn (_, element) => modifyFun element) array

  val foldli = V.foldli
  val foldri = V.foldri
  val foldl = V.foldl
  val foldr = V.foldr

  val findi = V.findi
  val find = V.find
  val exists = V.exists
  val all = V.all
  val collate = V.collate

  (***************************************************************************)

end;
