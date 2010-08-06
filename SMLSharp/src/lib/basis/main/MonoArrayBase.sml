(**
 * base of implementations of the MONO_ARRAY signature.
 * @author YAMATODANI Kiyoshi
 * @version $Id: MonoArrayBase.sml,v 1.7 2007/12/19 02:00:56 kiyoshiy Exp $
 *)
functor MonoArrayBase
            (B
             : sig
               type elem
               type array
               val maxLen : int
               val makeMutableArray : int * elem -> array
               val makeEmptyMutableArray : unit -> array
               val makeImmutableArray : int * elem -> array
               val makeEmptyImmutableArray : unit -> array
               val length : array -> int
               val sub : array * int -> elem
               val update : array * int * elem -> unit
               val copy
                   : {src : array, si : int, dst : array, di : int, len : int}
                     -> unit
             end) =
struct

  (***************************************************************************)

  structure VB =
  struct
    type elem = B.elem
    type vector = B.array
    val maxLen = B.maxLen
    val makeVector = B.makeImmutableArray
    val makeEmptyVector = B.makeEmptyImmutableArray
    val length = B.length
    val sub = B.sub
    val update = B.update
    val copy = B.copy
  end
  structure V = MonoVectorBase(VB)

  (***************************************************************************)

  type array = B.array
  type vector = V.vector
  type elem = B.elem

  (***************************************************************************)

  val maxLen = B.maxLen

  fun makeArray (intSize, init) =
      if intSize < 0 orelse maxLen < intSize
      then raise General.Size
      else B.makeMutableArray (intSize, init)
  fun makeVector (intSize, init) =
      if intSize < 0 orelse maxLen < intSize
      then raise General.Size
      else B.makeImmutableArray (intSize, init)
  val makeEmptyArray = B.makeEmptyMutableArray
  val makeEmptyVector = B.makeEmptyImmutableArray

  fun array (length, initial) = makeArray(length, initial)

  fun fromList [] = makeEmptyVector ()
    | fromList (head :: tail) =
      let
        val bufferLength = 1 + List.length tail
        val buffer = makeArray (bufferLength, head)
        fun write [] _ = ()
          | write (next :: remains) index =
            (B.update (buffer, index, next); write remains (index + 1))
      in
        (* write elements from the second element. *)
        write tail 1; 
        buffer
      end

  fun tabulate (number, generator) =
      if number = 0
      then makeEmptyVector ()
      else
        let
          val target = makeArray (number, generator 0)
          fun fill i =
              if i = number
              then ()
              else (B.update(target, i, generator i); fill (i + 1))
          val _ = fill 1
        in
          target
        end

  fun length vector = B.length vector

  fun sub (vector, index) =
      if index < 0 orelse (B.length vector) <= index
      then raise Subscript (* if buffer = NONE, the sub always fails. *)
      else B.sub (vector, index)

  fun update (array, index, newValue) = 
      if index < 0 orelse (B.length array) <= index
      then raise Subscript (* if buffer = NONE, the sub always fails. *)
      else B.update (array, index, newValue)

  fun copy {src, dst, di} =
      if (di < 0) orelse (length dst < di + length src)
      then raise General.Subscript
      else
        case B.length src of
          0 => ()
        | len => B.copy {src = src, si = 0, dst = dst, di = di, len = len}

  val copyVec = copy

  (* NOTE: A fresh copy is generated. *)
  fun vector array =
      case B.length array of
        0 => makeEmptyVector ()
      | len => 
      let val dst = makeVector (len, B.sub (array, 0))
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