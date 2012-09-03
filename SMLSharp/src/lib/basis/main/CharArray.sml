(**
 * CharArray structure.
 * @author YAMATODANI Kiyoshi
 * @version $Id: CharArray.sml,v 1.5 2007/12/19 02:00:56 kiyoshiy Exp $
 *)
structure CharArray =
struct

  (***************************************************************************)

  structure V = CharVector

  (***************************************************************************)

  type elem = char
  type array = String.string
  type vector = String.string

  (***************************************************************************)

  val maxLen = V.maxLen

  fun array (length, initial) =
      if (length < 0) orelse (maxLen < length)
      then raise General.Size
      else SMLSharp.PrimString.array (length, initial)

  fun fromList chars =
      let
        val len = List.length chars
        val buffer = array (len, #"a")
        fun scan i (c :: cs) =
            (SMLSharp.PrimString.update_unsafe (buffer, i, c); scan (i + 1) cs)
          | scan i [] = ()
      in
        scan 0 chars; buffer
      end

  fun tabulate (number, generator) =
      if number = 0
      then array (0, #"a")
      else
        if number < 0
        then raise General.Size
        else
          let
            val target = array (number, generator 0)
            fun fill i = 
                if i = number
                then ()
                else (SMLSharp.PrimString.update_unsafe(target, i, generator i);
                      fill (i + 1))
            val _ = fill 1
          in
            target
          end

  val length = V.length
  val sub = V.sub

  fun update (array, index, newValue) =
      let val length = String.size array
      in
        if index < 0 orelse length <= index
        then raise Subscript
        else SMLSharp.PrimString.update_unsafe (array, index, newValue)
      end

  fun copySlice {src, si, dst, di, len} =
      SMLSharp.PrimString.copy_unsafe (src, si, dst, di, len)

  fun copy {src, dst, di} =
      if (di < 0) orelse (length dst < di + length src)
      then raise General.Subscript
      else
        (
          copySlice {src = src, si = 0, dst = dst, di = di, len = length src};
          ()
        )
  val copyVec = copy

  (* NOTE: A fresh copy is generated. *)
  fun vector array =
      let
        val length = length array
        val target = SMLSharp.PrimString.vector (length, #"a")
        val _ = copy {src = array, dst = target, di = 0}
    in
      target
    end

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