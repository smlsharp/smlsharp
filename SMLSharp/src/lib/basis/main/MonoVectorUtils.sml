(**
 * base of implementations of the MONO_VECTOR signature.
 * @author Atsushi Ohori
 * @author YAMATODANI Kiyoshi
 * @copyright 2010, Tohoku University.
 * @version $Id: MonoVectorBase.sml,v 1.9 2007/12/19 02:00:56 kiyoshiy Exp $
 *)
structure MonoVectorUtils =
struct

(*
  type B =
       {
        maxLen : int,
        makeVector : int * 'elem -> 'vector,
        makeEmptyVector : unit -> 'vector,
        length : vector -> int,
        sub : 'vector * int -> 'elem,
        update : 'vector * int * 'elem -> unit,
        copy : {src : 'vector, si : int, dst : 'vector, di : int, len : int}
              -> unit
       }
*)


  fun ('elem, 'vector) 
        maxLen
        (B :{
         maxLen : int,
         makeVector : int * 'elem -> 'vector,
         makeEmptyVector : unit -> 'vector,
         length : 'vector -> int,
         sub : 'vector * int -> 'elem,
         update : 'vector * int * 'elem -> unit,
         copy : {src : 'vector, si : int, dst : 'vector, di : int, len : int}
                -> unit
        })
    = #maxLen B

  fun ('elem, 'vector)
        makeVector
        (B :{
         maxLen : int,
         makeVector : int * 'elem -> 'vector,
         makeEmptyVector : unit -> 'vector,
         length : 'vector -> int,
         sub : 'vector * int -> 'elem,
         update : 'vector * int * 'elem -> unit,
         copy : {src : 'vector, si : int, dst : 'vector, di : int, len : int}
                -> unit
        })
        (intSize, init) =
      if intSize < 0 orelse maxLen B < intSize
      then raise General.Size
      else #makeVector B (intSize, init)

  fun ('elem, 'vector)
        fromList 
        (B :{
         maxLen : int,
         makeVector : int * 'elem -> 'vector,
         makeEmptyVector : unit -> 'vector,
         length : 'vector -> int,
         sub : 'vector * int -> 'elem,
         update : 'vector * int * 'elem -> unit,
         copy : {src : 'vector, si : int, dst : 'vector, di : int, len : int}
                -> unit
        })
        L
        =
        case L of 
          [] => #makeEmptyVector B ()
        | (head :: tail) =>
          let
            val bufferLength = 1 + List.length tail
            val buffer = makeVector B (bufferLength, head)
            fun write [] _ = ()
              | write (next :: remains) index =
                (#update B (buffer, index, next); write remains (index + 1))
          in
            (* write elements from the second element. *)
              write tail 1; 
            buffer
          end

  fun ('elem, 'vector)
        tabulate
        (B :{
         maxLen : int,
         makeVector : int * 'elem -> 'vector,
         makeEmptyVector : unit -> 'vector,
         length : 'vector -> int,
         sub : 'vector * int -> 'elem,
         update : 'vector * int * 'elem -> unit,
         copy : {src : 'vector, si : int, dst : 'vector, di : int, len : int}
                -> unit
        })
        (number, generator) =
      fromList B (List.tabulate (number, fn index => generator index))

  fun ('elem, 'vector)
        length 
        (B :{
         maxLen : int,
         makeVector : int * 'elem -> 'vector,
         makeEmptyVector : unit -> 'vector,
         length : 'vector -> int,
         sub : 'vector * int -> 'elem,
         update : 'vector * int * 'elem -> unit,
         copy : {src : 'vector, si : int, dst : 'vector, di : int, len : int}
                -> unit
        })
        vector =
      #length B vector

  fun ('elem, 'vector)
        sub
        (B :{
         maxLen : int,
         makeVector : int * 'elem -> 'vector,
         makeEmptyVector : unit -> 'vector,
         length : 'vector -> int,
         sub : 'vector * int -> 'elem,
         update : 'vector * int * 'elem -> unit,
         copy : {src : 'vector, si : int, dst : 'vector, di : int, len : int}
                -> unit
        })
        (vector, index)
    =
    if index < 0 orelse (#length B vector) <= index
    then raise Subscript (* if buffer = NONE, the sub always fails. *)
    else #sub B (vector, index)

  fun ('elem, 'vector)
        foldli
        (B :{
         maxLen : int,
         makeVector : int * 'elem -> 'vector,
         makeEmptyVector : unit -> 'vector,
         length : 'vector -> int,
         sub : 'vector * int -> 'elem,
         update : 'vector * int * 'elem -> unit,
         copy : {src : 'vector, si : int, dst : 'vector, di : int, len : int}
                -> unit
        })
        foldFun initial vector =
      let
        val length = length B vector
        fun fold (index, accum) =
            if index = length
            then accum
            else
              let val newAccum = foldFun (index, sub B (vector, index), accum)
              in fold (index + 1, newAccum)
              end
      in
        fold (0, initial)
      end
  fun ('elem, 'vector)
        foldl
        (B :{
         maxLen : int,
         makeVector : int * 'elem -> 'vector,
         makeEmptyVector : unit -> 'vector,
         length : 'vector -> int,
         sub : 'vector * int -> 'elem,
         update : 'vector * int * 'elem -> unit,
         copy : {src : 'vector, si : int, dst : 'vector, di : int, len : int}
                -> unit
        })
        foldFun initial vector
    =
      foldli B
          (fn (_, element, accum) => foldFun (element, accum)) initial vector

  fun ('elem, 'vector)
        foldri
        (B :{
         maxLen : int,
         makeVector : int * 'elem -> 'vector,
         makeEmptyVector : unit -> 'vector,
         length : 'vector -> int,
         sub : 'vector * int -> 'elem,
         update : 'vector * int * 'elem -> unit,
         copy : {src : 'vector, si : int, dst : 'vector, di : int, len : int}
                -> unit
        })
        foldFun initial vector =
      let
        val length = length B vector
        fun fold (index, accum) =
            if index = ~1
            then accum
            else
              let val newAccum = foldFun (index, sub B (vector, index), accum)
              in fold (index - 1, newAccum)
              end
      in
        fold (length - 1, initial)
      end

  fun ('elem, 'vector)
       foldr
        (B :{
         maxLen : int,
         makeVector : int * 'elem -> 'vector,
         makeEmptyVector : unit -> 'vector,
         length : 'vector -> int,
         sub : 'vector * int -> 'elem,
         update : 'vector * int * 'elem -> unit,
         copy : {src : 'vector, si : int, dst : 'vector, di : int, len : int}
                -> unit
        })
        foldFun initial vector
    =
      foldri B
          (fn (_, element, accum) => foldFun (element, accum))
          initial
          vector

  fun ('elem, 'vector)
        mapi
        (B :{
         maxLen : int,
         makeVector : int * 'elem -> 'vector,
         makeEmptyVector : unit -> 'vector,
         length : 'vector -> int,
         sub : 'vector * int -> 'elem,
         update : 'vector * int * 'elem -> unit,
         copy : {src : 'vector, si : int, dst : 'vector, di : int, len : int}
                -> unit
        })
        mapFun vector
    =
      fromList B
          (List.rev
               (foldli B
                    (fn (index, a, l) => (mapFun (index, a) :: l)) [] vector))

  fun ('elem, 'vector)
        map
        (B :{
         maxLen : int,
         makeVector : int * 'elem -> 'vector,
         makeEmptyVector : unit -> 'vector,
         length : 'vector -> int,
         sub : 'vector * int -> 'elem,
         update : 'vector * int * 'elem -> unit,
         copy : {src : 'vector, si : int, dst : 'vector, di : int, len : int}
                -> unit
        })
        mapFun vector
    = mapi B (fn (_, element) => mapFun element) vector

  fun ('elem, 'vector)
        appi
        (B :{
         maxLen : int,
         makeVector : int * 'elem -> 'vector,
         makeEmptyVector : unit -> 'vector,
         length : 'vector -> int,
         sub : 'vector * int -> 'elem,
         update : 'vector * int * 'elem -> unit,
         copy : {src : 'vector, si : int, dst : 'vector, di : int, len : int}
                -> unit
        })
        appFun vector
    =
      foldli B (fn (index, a, _) => (appFun (index, a))) () vector

  fun ('elem, 'vector)
        app
        (B :{
         maxLen : int,
         makeVector : int * 'elem -> 'vector,
         makeEmptyVector : unit -> 'vector,
         length : 'vector -> int,
         sub : 'vector * int -> 'elem,
         update : 'vector * int * 'elem -> unit,
         copy : {src : 'vector, si : int, dst : 'vector, di : int, len : int}
                -> unit
        })
        appFun vector
    = appi B (fn (_, element) => appFun element) vector

  fun ('elem, 'vector)
        update
        (B :{
         maxLen : int,
         makeVector : int * 'elem -> 'vector,
         makeEmptyVector : unit -> 'vector,
         length : 'vector -> int,
         sub : 'vector * int -> 'elem,
         update : 'vector * int * 'elem -> unit,
         copy : {src : 'vector, si : int, dst : 'vector, di : int, len : int}
                -> unit
        })
        (vector, index, value)
    =
      if index < 0 orelse length B vector <= index
      then raise General.Subscript
      else
        let fun valueOfIndex i = if i = index then value else sub B (vector, i)
        in tabulate B (length B vector, valueOfIndex)
        end

  (** A utility for VectorSlice and other structures.*)
  fun ('elem, 'vector)
       copy
       (B :{
         maxLen : int,
         makeVector : int * 'elem -> 'vector,
         makeEmptyVector : unit -> 'vector,
         length : 'vector -> int,
         sub : 'vector * int -> 'elem,
         update : 'vector * int * 'elem -> unit,
         copy : {src : 'vector, si : int, dst : 'vector, di : int, len : int}
                -> unit
        })
    = #copy B

  fun ('elem, 'vector)
        concatSlices
        (B :{
         maxLen : int,
         makeVector : int * 'elem -> 'vector,
         makeEmptyVector : unit -> 'vector,
         length : 'vector -> int,
         sub : 'vector * int -> 'elem,
         update : 'vector * int * 'elem -> unit,
         copy : {src : 'vector, si : int, dst : 'vector, di : int, len : int}
                -> unit
        })
        (slices : ('vector * int * int) list) =
      let
        val (totalLength, initialValueOpt) =
            List.foldr
                (fn ((_, _, length), (totalLength, SOME value)) =>
                    (totalLength + length, SOME value)
                  | ((_, _, 0), (totalLength, NONE)) => (totalLength, NONE)
                  | ((vector, _, length), (totalLength, NONE)) =>
                    (totalLength + length, SOME(#sub B (vector, 0))))
                (0, NONE)
                slices
      in
        case (totalLength, initialValueOpt) of
          (0, _) => #makeEmptyVector B ()
        | (_, SOME initialValue) =>
          let
            val resultBuffer = makeVector B(totalLength, initialValue)
            fun write ((src, start, 0), index) = index
              | write ((src, start, length), index) =
                  (
                    copy B
                        {
                          src = src,
                          si = start,
                          dst = resultBuffer,
                          di = index,
                          len = length
                        };
                    index + length
                  )
          in
            List.foldl write 0 slices;
            resultBuffer
          end
        | (_, NONE) => raise Fail "BUG: vector concat"
      end

  fun ('elem, 'vector)
        concat
        (B :{
         maxLen : int,
         makeVector : int * 'elem -> 'vector,
         makeEmptyVector : unit -> 'vector,
         length : 'vector -> int,
         sub : 'vector * int -> 'elem,
         update : 'vector * int * 'elem -> unit,
         copy : {src : 'vector, si : int, dst : 'vector, di : int, len : int}
                -> unit
        })
        vectors
    =
    concatSlices B
      (List.map (fn vector => (vector, 0, #length B vector)) vectors)

  fun ('elem, 'vector)
        findi
        (B :{
         maxLen : int,
         makeVector : int * 'elem -> 'vector,
         makeEmptyVector : unit -> 'vector,
         length : 'vector -> int,
         sub : 'vector * int -> 'elem,
         update : 'vector * int * 'elem -> unit,
         copy : {src : 'vector, si : int, dst : 'vector, di : int, len : int}
                -> unit
        })
        predicate vector
    =
    let
      val length = length B vector
      fun scan index =
          if index = length
          then NONE
          else
            let val value = sub B (vector, index)
            in
              if predicate (index, value)
              then SOME(index, value)
              else scan (index + 1)
            end
    in
      scan 0
    end
      
  fun ('elem, 'vector)
        find
        (B :{
         maxLen : int,
         makeVector : int * 'elem -> 'vector,
         makeEmptyVector : unit -> 'vector,
         length : 'vector -> int,
         sub : 'vector * int -> 'elem,
         update : 'vector * int * 'elem -> unit,
         copy : {src : 'vector, si : int, dst : 'vector, di : int, len : int}
                -> unit
        })
        predicate vector
    =
      Option.map
          (fn (_, value) => value)
          (findi B (fn (_, value) => predicate value) vector)

  fun ('elem, 'vector)
        exists
        (B :{
         maxLen : int,
         makeVector : int * 'elem -> 'vector,
         makeEmptyVector : unit -> 'vector,
         length : 'vector -> int,
         sub : 'vector * int -> 'elem,
         update : 'vector * int * 'elem -> unit,
         copy : {src : 'vector, si : int, dst : 'vector, di : int, len : int}
                -> unit
        })
        predicate vector
    = Option.isSome(find B predicate vector)

  fun ('elem, 'vector)
        all
        (B :{
         maxLen : int,
         makeVector : int * 'elem -> 'vector,
         makeEmptyVector : unit -> 'vector,
         length : 'vector -> int,
         sub : 'vector * int -> 'elem,
         update : 'vector * int * 'elem -> unit,
         copy : {src : 'vector, si : int, dst : 'vector, di : int, len : int}
                -> unit
        })
        predicate vector
    =
    not (Option.isSome(find B (fn value => not(predicate value)) vector))

  fun ('elem, 'vector)
        collate
        (B :{
         maxLen : int,
         makeVector : int * 'elem -> 'vector,
         makeEmptyVector : unit -> 'vector,
         length : 'vector -> int,
         sub : 'vector * int -> 'elem,
         update : 'vector * int * 'elem -> unit,
         copy : {src : 'vector, si : int, dst : 'vector, di : int, len : int}
                -> unit
        })
        elementCollate (left, right)
    =
      let
        fun scan _ 0 0 = General.EQUAL
          | scan _ 0 _ = General.LESS
          | scan _ _ 0 = General.GREATER
          | scan index leftRemain rightRemain =
            case elementCollate(sub B (left, index), sub B (right, index)) of
              General.EQUAL =>
              scan (index + 1) (leftRemain - 1) (rightRemain - 1)
            | diff => diff
      in
        scan 0 (length B left) (length B right)
      end

  (***************************************************************************)

end;
