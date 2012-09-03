(**
 * base implementation of MONO_VECTOR_SLICE, defunctorized version.
 * @author YAMATODANI Kiyoshi
 * @author Atsushi Ohori
 * @version $Id: MonoVectorSliceBase.sml,v 1.3 2007/09/01 03:21:16 kiyoshiy Exp $
 *)
structure MonoVectorSliceUtils =
struct

  fun ('elem, 'vector)
        length
        (B:{fromList : 'elem list -> 'vector,
            length   : 'vector -> int,
            sub      : 'vector * int -> 'elem,
            collate: ('elem * 'elem -> order) -> 'vector * 'vector -> order,
            concatSlices : ('vector * int * int) list -> 'vector})
        (_, _, length)
    = length

  fun ('elem, 'vector)
        sub
        (B:{fromList : 'elem list -> 'vector,
            length   : 'vector -> int,
            sub      : 'vector * int -> 'elem,
            collate: ('elem * 'elem -> order) -> 'vector * 'vector -> order,
            concatSlices : ('vector * int * int) list -> 'vector})
        ((vector, start, length), index)
    =
      if (index < 0) orelse (length <= index)
      then raise General.Subscript
      else #sub B (vector, start + index)

  fun ('elem, 'vector)
        full
        (B:{fromList : 'elem list -> 'vector,
            length   : 'vector -> int,
            sub      : 'vector * int -> 'elem,
            collate: ('elem * 'elem -> order) -> 'vector * 'vector -> order,
            concatSlices : ('vector * int * int) list -> 'vector})
        vector
    = (vector, 0, #length B vector)

  fun ('elem, 'vector)
        slice
        (B:{fromList : 'elem list -> 'vector,
            length   : 'vector -> int,
            sub      : 'vector * int -> 'elem,
            collate: ('elem * 'elem -> order) -> 'vector * 'vector -> order,
            concatSlices : ('vector * int * int) list -> 'vector})
        (vector : 'vector, start : int, lengthOpt)
    =
      let
        val vectorLength = #length B vector
        val length = 
            case lengthOpt of
              NONE =>
              if (start < 0) orelse (vectorLength < start)
              then raise General.Subscript
              else vectorLength - start
            | SOME length =>
              if
                (start < 0)
                orelse (length < 0)
                orelse (vectorLength < start + length)
              then raise General.Subscript
              else length
      in
        (vector, start, length)
      end

  fun ('elem, 'vector)
        subslice
        (B:{fromList : 'elem list -> 'vector,
            length   : 'vector -> int,
            sub      : 'vector * int -> 'elem,
            collate: ('elem * 'elem -> order) -> 'vector * 'vector -> order,
            concatSlices : ('vector * int * int) list -> 'vector})
        ((vector, start1, length1), start2, length2Opt)
    =
      let
        val length = 
            case length2Opt of
              NONE =>
              if (start2 < 0) orelse (length1 < start2)
              then raise General.Subscript
              else length1 - start2
            | SOME length2 =>
              if
                (start2 < 0)
                orelse (length2 < 0)
                orelse (length1 < start2 + length2)
              then raise General.Subscript
              else length2
        val start = start1 + start2
      in
        (vector, start, length)
      end
      
  fun ('elem, 'vector)
        base
        (B:{fromList : 'elem list -> 'vector,
            length   : 'vector -> int,
            sub      : 'vector * int -> 'elem,
            collate: ('elem * 'elem -> order) -> 'vector * 'vector -> order,
            concatSlices : ('vector * int * int) list -> 'vector})
        ((vector, start, length) : 'vector * int * int)
    = (vector, start, length)

  fun ('elem, 'vector)
        foldli
        (B:{fromList : 'elem list -> 'vector,
            length   : 'vector -> int,
            sub      : 'vector * int -> 'elem,
            collate: ('elem * 'elem -> order) -> 'vector * 'vector -> order,
            concatSlices : ('vector * int * int) list -> 'vector})
        foldFun
        initial
        (vector, start, length)
    =
      let
        fun fold (index, accum) =
            if index = length
            then accum
            else
              let
                val newAccum =
                    foldFun (index, #sub B (vector, start + index), accum)
              in fold (index + 1, newAccum)
              end
      in
        fold (0, initial)
      end

  fun ('elem, 'vector)
        foldri
        (B:{fromList : 'elem list -> 'vector,
            length   : 'vector -> int,
            sub      : 'vector * int -> 'elem,
            collate: ('elem * 'elem -> order) -> 'vector * 'vector -> order,
            concatSlices : ('vector * int * int) list -> 'vector})
        foldFun
        initial
        (vector, start, length)
    =
      let
        fun fold (index, accum) =
            if index = ~1
            then accum
            else
              let
                val newAccum =
                    foldFun (index, #sub B (vector, start + index), accum)
              in fold (index - 1, newAccum)
              end
      in
        fold (length - 1, initial)
      end

  fun ('elem, 'vector)
        foldl
        (B:{fromList : 'elem list -> 'vector,
            length   : 'vector -> int,
            sub      : 'vector * int -> 'elem,
            collate: ('elem * 'elem -> order) -> 'vector * 'vector -> order,
            concatSlices : ('vector * int * int) list -> 'vector})
        foldFun
        initial
        slice
    = 
      foldli B (fn (_, element, accum) => foldFun(element, accum)) initial slice

  fun ('elem, 'vector)
        foldr
        (B:{fromList : 'elem list -> 'vector,
            length   : 'vector -> int,
            sub      : 'vector * int -> 'elem,
            collate: ('elem * 'elem -> order) -> 'vector * 'vector -> order,
            concatSlices : ('vector * int * int) list -> 'vector})
        foldFun
        initial
        slice
    = 
      foldri B (fn (_, element, accum) => foldFun (element, accum)) initial slice

  fun ('elem, 'vector)
        mapi
        (B:{fromList : 'elem list -> 'vector,
            length   : 'vector -> int,
            sub      : 'vector * int -> 'elem,
            collate: ('elem * 'elem -> order) -> 'vector * 'vector -> order,
            concatSlices : ('vector * int * int) list -> 'vector})
        mapFun
        slice
    =
      #fromList B
          (List.rev
               (foldli B
                    (fn (index, a, l) => (mapFun (index, a) :: l)) [] slice))
  fun ('elem, 'vector)
        map
        (B:{fromList : 'elem list -> 'vector,
            length   : 'vector -> int,
            sub      : 'vector * int -> 'elem,
            collate: ('elem * 'elem -> order) -> 'vector * 'vector -> order,
            concatSlices : ('vector * int * int) list -> 'vector})
        mapFun
        slice
    = mapi B (fn (_, element) => mapFun element) slice

  fun ('elem, 'vector)
        appi
        (B:{fromList : 'elem list -> 'vector,
            length   : 'vector -> int,
            sub      : 'vector * int -> 'elem,
            collate: ('elem * 'elem -> order) -> 'vector * 'vector -> order,
            concatSlices : ('vector * int * int) list -> 'vector})
        appFun
        slice
    =
      foldli B (fn (index, a, _) => (appFun (index, a))) () slice

  fun ('elem, 'vector)
        app
        (B:{fromList : 'elem list -> 'vector,
            length   : 'vector -> int,
            sub      : 'vector * int -> 'elem,
            collate: ('elem * 'elem -> order) -> 'vector * 'vector -> order,
            concatSlices : ('vector * int * int) list -> 'vector})
        appFun
        slice
    = appi B (fn (_, element) => appFun element) slice
                                     
  fun ('elem, 'vector)
        vector
        (B:{fromList : 'elem list -> 'vector,
            length   : 'vector -> int,
            sub      : 'vector * int -> 'elem,
            collate: ('elem * 'elem -> order) -> 'vector * 'vector -> order,
            concatSlices : ('vector * int * int) list -> 'vector})
        slice
    = #concatSlices B [slice]

  fun ('elem, 'vector)
        concat
        (B:{fromList : 'elem list -> 'vector,
            length   : 'vector -> int,
            sub      : 'vector * int -> 'elem,
            collate: ('elem * 'elem -> order) -> 'vector * 'vector -> order,
            concatSlices : ('vector * int * int) list -> 'vector})
        slices
    = #concatSlices B slices

  fun ('elem, 'vector)
        isEmpty
        (B:{fromList : 'elem list -> 'vector,
            length   : 'vector -> int,
            sub      : 'vector * int -> 'elem,
            collate: ('elem * 'elem -> order) -> 'vector * 'vector -> order,
            concatSlices : ('vector * int * int) list -> 'vector})
        (_, _, length)
    = length = 0

  fun ('elem, 'vector)
        getItem
        (B:{fromList : 'elem list -> 'vector,
            length   : 'vector -> int,
            sub      : 'vector * int -> 'elem,
            collate: ('elem * 'elem -> order) -> 'vector * 'vector -> order,
            concatSlices : ('vector * int * int) list -> 'vector})
        X
        =
        case X of
        (vector, start, 0) => NONE
      | (vector, start, length) =>
        let val item = #sub B (vector, start)
        in SOME(item, (vector, start + 1, length - 1))
        end

  fun ('elem, 'vector)
        findi
        (B:{fromList : 'elem list -> 'vector,
            length   : 'vector -> int,
            sub      : 'vector * int -> 'elem,
            collate: ('elem * 'elem -> order) -> 'vector * 'vector -> order,
            concatSlices : ('vector * int * int) list -> 'vector})
        predicate
        (vector, start, length)
    = 
      let
        fun scan index =
            if index = length
            then NONE
            else
              let val value = #sub B (vector, start + index)
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
        (B:{fromList : 'elem list -> 'vector,
            length   : 'vector -> int,
            sub      : 'vector * int -> 'elem,
            collate: ('elem * 'elem -> order) -> 'vector * 'vector -> order,
            concatSlices : ('vector * int * int) list -> 'vector})
        predicate slice
    =
      Option.map
          (fn (_, value) => value)
          (findi B (fn (_, value) => predicate value) slice)

  fun ('elem, 'vector)
        exists
        (B:{fromList : 'elem list -> 'vector,
            length   : 'vector -> int,
            sub      : 'vector * int -> 'elem,
            collate: ('elem * 'elem -> order) -> 'vector * 'vector -> order,
            concatSlices : ('vector * int * int) list -> 'vector})
        predicate
        slice
    = Option.isSome(find B predicate slice)

  fun ('elem, 'vector)
        all
        (B:{fromList : 'elem list -> 'vector,
            length   : 'vector -> int,
            sub      : 'vector * int -> 'elem,
            collate: ('elem * 'elem -> order) -> 'vector * 'vector -> order,
            concatSlices : ('vector * int * int) list -> 'vector})
        predicate slice
    = 
      not(Option.isSome(find B (fn value => not(predicate value)) slice))

  fun ('elem, 'vector)
        collate
        (B:{fromList : 'elem list -> 'vector,
            length   : 'vector -> int,
            sub      : 'vector * int -> 'elem,
            collate: ('elem * 'elem -> order) -> 'vector * 'vector -> order,
            concatSlices : ('vector * int * int) list -> 'vector})
        comparator (leftSlice, rightSlice)
    =
      #collate B comparator (vector B leftSlice, vector B rightSlice)

  (***************************************************************************)

end;
