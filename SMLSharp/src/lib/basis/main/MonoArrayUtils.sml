(**
 * base of implementations of the MONO_ARRAY signature.
 * @author YAMATODANI Kiyoshi
 * @version $Id: MonoArrayBase.sml,v 1.7 2007/12/19 02:00:56 kiyoshiy Exp $
 *)
structure MonoArrayUtils =
struct 
local
  structure V = MonoVectorUtils
  fun BtoVB {maxLen,
             makeMutableArray,
             makeEmptyMutableArray,
             makeImmutableArray,
             makeEmptyImmutableArray,
             length,
             sub,
             update,
             copy}
    =
    {maxLen = maxLen,
     makeVector = makeImmutableArray,
     makeEmptyVector = makeEmptyImmutableArray,
     length = length,
     sub = sub,
     update = update,
     copy = copy}
in

  fun ('elem, 'array) maxLen
    (B:{maxLen : int,
        makeMutableArray : int * 'elem -> 'array,
        makeEmptyMutableArray : unit -> 'array,
        makeImmutableArray : int * 'elem -> 'array,
        makeEmptyImmutableArray : unit -> 'array,
        length : 'array -> int,
        sub : 'array * int -> 'elem,
        update : 'array * int * 'elem -> unit,
        copy: {src : 'array, si : int, dst : 'array, di : int, len : int}
              -> unit
       })
    =
    #maxLen B

  fun ('elem, 'array)
        makeArray
        (B:{maxLen : int,
            makeMutableArray : int * 'elem -> 'array,
            makeEmptyMutableArray : unit -> 'array,
            makeImmutableArray : int * 'elem -> 'array,
            makeEmptyImmutableArray : unit -> 'array,
            length : 'array -> int,
            sub : 'array * int -> 'elem,
            update : 'array * int * 'elem -> unit,
            copy: {src : 'array, si : int, dst : 'array, di : int, len : int}
                  -> unit
        })
        (intSize, init)
    =
      if intSize < 0 orelse maxLen B < intSize
      then raise General.Size
      else #makeMutableArray B (intSize, init)

  fun ('elem, 'array)
        makeVector
        (B:{maxLen : int,
            makeMutableArray : int * 'elem -> 'array,
            makeEmptyMutableArray : unit -> 'array,
            makeImmutableArray : int * 'elem -> 'array,
            makeEmptyImmutableArray : unit -> 'array,
            length : 'array -> int,
            sub : 'array * int -> 'elem,
            update : 'array * int * 'elem -> unit,
            copy: {src : 'array, si : int, dst : 'array, di : int, len : int}
                  -> unit
        })
        (intSize, init)
    =
      if intSize < 0 orelse maxLen B < intSize
      then raise General.Size
      else #makeImmutableArray B (intSize, init)

  fun ('elem, 'array)
        makeEmptyArray
        (B:{maxLen : int,
            makeMutableArray : int * 'elem -> 'array,
            makeEmptyMutableArray : unit -> 'array,
            makeImmutableArray : int * 'elem -> 'array,
            makeEmptyImmutableArray : unit -> 'array,
            length : 'array -> int,
            sub : 'array * int -> 'elem,
            update : 'array * int * 'elem -> unit,
            copy: {src : 'array, si : int, dst : 'array, di : int, len : int}
                  -> unit
        })
    = #makeEmptyMutableArray B

  fun ('elem, 'array)
        makeEmptyVector
        (B:{maxLen : int,
            makeMutableArray : int * 'elem -> 'array,
            makeEmptyMutableArray : unit -> 'array,
            makeImmutableArray : int * 'elem -> 'array,
            makeEmptyImmutableArray : unit -> 'array,
            length : 'array -> int,
            sub : 'array * int -> 'elem,
            update : 'array * int * 'elem -> unit,
            copy: {src : 'array, si : int, dst : 'array, di : int, len : int}
                  -> unit
        })
    = #makeEmptyImmutableArray B

  fun ('elem, 'array)
        array
        (B:{maxLen : int,
            makeMutableArray : int * 'elem -> 'array,
            makeEmptyMutableArray : unit -> 'array,
            makeImmutableArray : int * 'elem -> 'array,
            makeEmptyImmutableArray : unit -> 'array,
            length : 'array -> int,
            sub : 'array * int -> 'elem,
            update : 'array * int * 'elem -> unit,
            copy: {src : 'array, si : int, dst : 'array, di : int, len : int}
                  -> unit
        })
        (length, initial)
    = makeArray B (length, initial)

  fun ('elem, 'array)
        fromList
        (B:{maxLen : int,
            makeMutableArray : int * 'elem -> 'array,
            makeEmptyMutableArray : unit -> 'array,
            makeImmutableArray : int * 'elem -> 'array,
            makeEmptyImmutableArray : unit -> 'array,
            length : 'array -> int,
            sub : 'array * int -> 'elem,
            update : 'array * int * 'elem -> unit,
            copy: {src : 'array, si : int, dst : 'array, di : int, len : int}
                  -> unit
        })
        L
    =
    case L of 
      [] => makeEmptyVector B ()
    | (head :: tail) =>
      let
        val bufferLength = 1 + List.length tail
        val buffer = makeArray B (bufferLength, head)
        fun write [] _ = ()
          | write (next :: remains) index =
            (#update B (buffer, index, next); write remains (index + 1))
      in
        (* write elements from the second element. *)
        write tail 1; 
        buffer
      end

  fun ('elem, 'array)
        tabulate
        (B:{maxLen : int,
            makeMutableArray : int * 'elem -> 'array,
            makeEmptyMutableArray : unit -> 'array,
            makeImmutableArray : int * 'elem -> 'array,
            makeEmptyImmutableArray : unit -> 'array,
            length : 'array -> int,
            sub : 'array * int -> 'elem,
            update : 'array * int * 'elem -> unit,
            copy: {src : 'array, si : int, dst : 'array, di : int, len : int}
                  -> unit
        })
        (number, generator)
    =
      fromList B (List.tabulate (number, fn index => generator index))

  fun ('elem, 'array)
        length
        (B:{maxLen : int,
            makeMutableArray : int * 'elem -> 'array,
            makeEmptyMutableArray : unit -> 'array,
            makeImmutableArray : int * 'elem -> 'array,
            makeEmptyImmutableArray : unit -> 'array,
            length : 'array -> int,
            sub : 'array * int -> 'elem,
            update : 'array * int * 'elem -> unit,
            copy: {src : 'array, si : int, dst : 'array, di : int, len : int}
                  -> unit
        })
        vector
    = #length B vector

  fun ('elem, 'array)
        sub
        (B:{maxLen : int,
            makeMutableArray : int * 'elem -> 'array,
            makeEmptyMutableArray : unit -> 'array,
            makeImmutableArray : int * 'elem -> 'array,
            makeEmptyImmutableArray : unit -> 'array,
            length : 'array -> int,
            sub : 'array * int -> 'elem,
            update : 'array * int * 'elem -> unit,
            copy: {src : 'array, si : int, dst : 'array, di : int, len : int}
                  -> unit
        })
        (vector, index)
    =
      if index < 0 orelse (#length B vector) <= index
      then raise Subscript (* if buffer = NONE, the sub always fails. *)
      else #sub B (vector, index)

  fun ('elem, 'array)
        update
        (B:{maxLen : int,
            makeMutableArray : int * 'elem -> 'array,
            makeEmptyMutableArray : unit -> 'array,
            makeImmutableArray : int * 'elem -> 'array,
            makeEmptyImmutableArray : unit -> 'array,
            length : 'array -> int,
            sub : 'array * int -> 'elem,
            update : 'array * int * 'elem -> unit,
            copy: {src : 'array, si : int, dst : 'array, di : int, len : int}
                  -> unit
        })
        (array, index, newValue)
    = 
      if index < 0 orelse (#length B array) <= index
      then raise Subscript (* if buffer = NONE, the sub always fails. *)
      else #update B (array, index, newValue)

  fun ('elem, 'array)
        copy
        (B:{maxLen : int,
            makeMutableArray : int * 'elem -> 'array,
            makeEmptyMutableArray : unit -> 'array,
            makeImmutableArray : int * 'elem -> 'array,
            makeEmptyImmutableArray : unit -> 'array,
            length : 'array -> int,
            sub : 'array * int -> 'elem,
            update : 'array * int * 'elem -> unit,
            copy: {src : 'array, si : int, dst : 'array, di : int, len : int}
                  -> unit
        })
        {src, dst, di}
    =
      if (di < 0) orelse (length B dst < di + length B src)
      then raise General.Subscript
      else
        case #length B src of
          0 => ()
        | len => #copy B {src = src, si = 0, dst = dst, di = di, len = len}

  fun ('elem, 'array)
        copyVec
        (B:{maxLen : int,
            makeMutableArray : int * 'elem -> 'array,
            makeEmptyMutableArray : unit -> 'array,
            makeImmutableArray : int * 'elem -> 'array,
            makeEmptyImmutableArray : unit -> 'array,
            length : 'array -> int,
            sub : 'array * int -> 'elem,
            update : 'array * int * 'elem -> unit,
            copy: {src : 'array, si : int, dst : 'array, di : int, len : int}
                  -> unit
        })
    = copy B

  (* NOTE: A fresh copy is generated. *)
  fun ('elem, 'array)
        vector
        (B:{maxLen : int,
            makeMutableArray : int * 'elem -> 'array,
            makeEmptyMutableArray : unit -> 'array,
            makeImmutableArray : int * 'elem -> 'array,
            makeEmptyImmutableArray : unit -> 'array,
            length : 'array -> int,
            sub : 'array * int -> 'elem,
            update : 'array * int * 'elem -> unit,
            copy: {src : 'array, si : int, dst : 'array, di : int, len : int}
                  -> unit
        })
        array
    =
      case #length B array of
        0 => makeEmptyVector B ()
      | len => 
      let val dst = makeVector B (len, #sub B (array, 0))
      in copy B {src = array, dst = dst, di = 0}; dst end

  fun ('elem, 'array)
        appi
        (B:{maxLen : int,
            makeMutableArray : int * 'elem -> 'array,
            makeEmptyMutableArray : unit -> 'array,
            makeImmutableArray : int * 'elem -> 'array,
            makeEmptyImmutableArray : unit -> 'array,
            length : 'array -> int,
            sub : 'array * int -> 'elem,
            update : 'array * int * 'elem -> unit,
            copy: {src : 'array, si : int, dst : 'array, di : int, len : int}
                  -> unit
        })
    = fn x => V.appi (BtoVB B) x


  fun ('elem, 'array)
        app
        (B:{maxLen : int,
            makeMutableArray : int * 'elem -> 'array,
            makeEmptyMutableArray : unit -> 'array,
            makeImmutableArray : int * 'elem -> 'array,
            makeEmptyImmutableArray : unit -> 'array,
            length : 'array -> int,
            sub : 'array * int -> 'elem,
            update : 'array * int * 'elem -> unit,
            copy: {src : 'array, si : int, dst : 'array, di : int, len : int}
                  -> unit
        })
    = fn x => V.app (BtoVB B) x

  fun ('elem, 'array)
        modifyi
        (B:{maxLen : int,
            makeMutableArray : int * 'elem -> 'array,
            makeEmptyMutableArray : unit -> 'array,
            makeImmutableArray : int * 'elem -> 'array,
            makeEmptyImmutableArray : unit -> 'array,
            length : 'array -> int,
            sub : 'array * int -> 'elem,
            update : 'array * int * 'elem -> unit,
            copy: {src : 'array, si : int, dst : 'array, di : int, len : int}
                  -> unit
        })
        modifyFun
        array
    =
      appi B
          (fn (index, element) =>
              update B (array, index, (modifyFun (index, element))))
          array

  fun ('elem, 'array)
        modify
        (B:{maxLen : int,
            makeMutableArray : int * 'elem -> 'array,
            makeEmptyMutableArray : unit -> 'array,
            makeImmutableArray : int * 'elem -> 'array,
            makeEmptyImmutableArray : unit -> 'array,
            length : 'array -> int,
            sub : 'array * int -> 'elem,
            update : 'array * int * 'elem -> unit,
            copy: {src : 'array, si : int, dst : 'array, di : int, len : int}
                  -> unit
        })
        modifyFun
        array
    =
      modifyi B (fn (_, element) => modifyFun element) array

  fun ('elem, 'array)
        foldli
        (B:{maxLen : int,
            makeMutableArray : int * 'elem -> 'array,
            makeEmptyMutableArray : unit -> 'array,
            makeImmutableArray : int * 'elem -> 'array,
            makeEmptyImmutableArray : unit -> 'array,
            length : 'array -> int,
            sub : 'array * int -> 'elem,
            update : 'array * int * 'elem -> unit,
            copy: {src : 'array, si : int, dst : 'array, di : int, len : int}
                  -> unit
        })
    = fn x => V.foldli (BtoVB B) x

  fun ('elem, 'array)
        foldri
        (B:{maxLen : int,
            makeMutableArray : int * 'elem -> 'array,
            makeEmptyMutableArray : unit -> 'array,
            makeImmutableArray : int * 'elem -> 'array,
            makeEmptyImmutableArray : unit -> 'array,
            length : 'array -> int,
            sub : 'array * int -> 'elem,
            update : 'array * int * 'elem -> unit,
            copy: {src : 'array, si : int, dst : 'array, di : int, len : int}
                  -> unit
        })
    = fn x => V.foldri (BtoVB B) x

  fun ('elem, 'array)
        foldl
        (B:{maxLen : int,
            makeMutableArray : int * 'elem -> 'array,
            makeEmptyMutableArray : unit -> 'array,
            makeImmutableArray : int * 'elem -> 'array,
            makeEmptyImmutableArray : unit -> 'array,
            length : 'array -> int,
            sub : 'array * int -> 'elem,
            update : 'array * int * 'elem -> unit,
            copy: {src : 'array, si : int, dst : 'array, di : int, len : int}
                  -> unit
        })
    = fn x => V.foldl (BtoVB B) x


  fun ('elem, 'array)
        foldr
        (B:{maxLen : int,
            makeMutableArray : int * 'elem -> 'array,
            makeEmptyMutableArray : unit -> 'array,
            makeImmutableArray : int * 'elem -> 'array,
            makeEmptyImmutableArray : unit -> 'array,
            length : 'array -> int,
            sub : 'array * int -> 'elem,
            update : 'array * int * 'elem -> unit,
            copy: {src : 'array, si : int, dst : 'array, di : int, len : int}
                  -> unit
        })
    = fn x => V.foldr (BtoVB B) x


  fun ('elem, 'array)
        findi
        (B:{maxLen : int,
            makeMutableArray : int * 'elem -> 'array,
            makeEmptyMutableArray : unit -> 'array,
            makeImmutableArray : int * 'elem -> 'array,
            makeEmptyImmutableArray : unit -> 'array,
            length : 'array -> int,
            sub : 'array * int -> 'elem,
            update : 'array * int * 'elem -> unit,
            copy: {src : 'array, si : int, dst : 'array, di : int, len : int}
                  -> unit
        })
    = fn x => V.findi (BtoVB B) x

  fun ('elem, 'array)
        find
        (B:{maxLen : int,
            makeMutableArray : int * 'elem -> 'array,
            makeEmptyMutableArray : unit -> 'array,
            makeImmutableArray : int * 'elem -> 'array,
            makeEmptyImmutableArray : unit -> 'array,
            length : 'array -> int,
            sub : 'array * int -> 'elem,
            update : 'array * int * 'elem -> unit,
            copy: {src : 'array, si : int, dst : 'array, di : int, len : int}
                  -> unit
        })
    = fn x => V.find (BtoVB B) x

  fun ('elem, 'array)
        exists
        (B:{maxLen : int,
            makeMutableArray : int * 'elem -> 'array,
            makeEmptyMutableArray : unit -> 'array,
            makeImmutableArray : int * 'elem -> 'array,
            makeEmptyImmutableArray : unit -> 'array,
            length : 'array -> int,
            sub : 'array * int -> 'elem,
            update : 'array * int * 'elem -> unit,
            copy: {src : 'array, si : int, dst : 'array, di : int, len : int}
                  -> unit
        })
    = fn x => V.exists (BtoVB B) x

  fun ('elem, 'array)
        all
        (B:{maxLen : int,
            makeMutableArray : int * 'elem -> 'array,
            makeEmptyMutableArray : unit -> 'array,
            makeImmutableArray : int * 'elem -> 'array,
            makeEmptyImmutableArray : unit -> 'array,
            length : 'array -> int,
            sub : 'array * int -> 'elem,
            update : 'array * int * 'elem -> unit,
            copy: {src : 'array, si : int, dst : 'array, di : int, len : int}
                  -> unit
        })
    = fn x => V.all (BtoVB B) x
    


  fun ('elem, 'array)
        collate
        (B:{maxLen : int,
            makeMutableArray : int * 'elem -> 'array,
            makeEmptyMutableArray : unit -> 'array,
            makeImmutableArray : int * 'elem -> 'array,
            makeEmptyImmutableArray : unit -> 'array,
            length : 'array -> int,
            sub : 'array * int -> 'elem,
            update : 'array * int * 'elem -> unit,
            copy: {src : 'array, si : int, dst : 'array, di : int, len : int}
                  -> unit
        })
    = fn x => V.collate (BtoVB B) x


end
end;
