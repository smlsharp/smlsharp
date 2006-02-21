(**
 * CharArray structure.
 * @author YAMATODANI Kiyoshi
 * @version $Id: CharArray.sml,v 1.3 2005/08/16 23:25:00 kiyoshiy Exp $
 *)
structure CharArray =
struct

  (***************************************************************************)

  open CharVector

  (***************************************************************************)

  type array = String.string

  (***************************************************************************)

  fun update (array, index, newValue) =
      let val length = String.size array
      in
        if index < 0 orelse length <= index
        then raise Subscript
        else String_update (array, index, newValue)
      end

  (* NOTE: A fresh copy is generated. *)
  fun vector array =
      fromList(foldr (fn (element, accum) => element :: accum) [] array)

  fun copy {src, dst, di} =
      if (di < 0) orelse (String.size dst < di + String.size src)
      then raise General.Subscript
      else
        let
          val length = String.size src
          fun write ~1 = ()
            | write index =
              (update(dst, di + index, sub(src, index)); write (index - 1))
        in
          write (length - 1)
        end

  val copyVec = copy

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
      else String_allocate (length, initial)

  (***************************************************************************)

end;

