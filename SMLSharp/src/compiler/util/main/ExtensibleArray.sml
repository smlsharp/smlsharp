(**
 * extensible array.
 * @copyright (c) 2006, Tohoku University.
 * @author YAMATODANI Kiyoshi
 * @version $Id: ExtensibleArray.sml,v 1.3 2008/08/06 07:59:47 ohori Exp $
 *)
functor ExtensibleArray(structure A : MONO_ARRAY
                        structure V : MONO_VECTOR
                        structure AS : MONO_ARRAY_SLICE
                        structure VS : MONO_VECTOR_SLICE
                        sharing type A.elem = AS.elem = VS.elem
                        sharing type A.array = AS.array
                        sharing type A.vector = AS.vector 
                        sharing type AS.vector = VS.vector
                        sharing type AS.vector_slice = VS.slice
                        sharing type A.vector = V.vector
			) =
struct

  type array = {buf : A.array ref, init : A.elem, len : int ref}

  val INITIAL_SIZE = 1024

  fun array (len, v) =
      {
        buf = ref (A.array (Int.max (len, INITIAL_SIZE), v)),
        init = v,
        len = ref len
      } : array

  fun length ({len, ...} : array) = !len

  fun sub ({buf, len, ...} : array, index) =
      if !len <= index
      then raise General.Subscript
      else A.sub (!buf,index)

  fun ensureCapacity ({buf, len, init, ...} : array, requiredIndex) =
      if requiredIndex < A.length (!buf)
      then
        if !len <= requiredIndex
        then len := requiredIndex + 1
        else ()
      else
        let
          val arrayLen =
              Int.max
                  (Int.min (A.maxLen, A.length (!buf) * 2), requiredIndex + 1)
          val _ =
              if A.maxLen < arrayLen
              then raise Fail "ExtensibleArray: too large array size."
              else ()
(*
val _ = print ("requiredIndex = " ^ Int.toString requiredIndex ^ "\n")
val _ = print ("len = " ^ Int.toString (!len) ^ "\n")
val _ = print ("newLength = " ^ Int.toString arrayLen ^ "\n")
*)
          val newBuf = A.array (arrayLen, init)
          val _ =
              AS.copy
              {
               src = AS.slice (!buf,0,SOME (!len)), 
               (*si = 0,*)
               dst = newBuf, 
               (*len = SOME (!len), *)
               di = 0
               }
          val _ = buf := newBuf
          val _ = len := requiredIndex + 1
        in
          ()
        end

  fun update (ar as {buf, len, init, ...} : array, index, v) =
      (ensureCapacity (ar, index); A.update (!buf, index, v))

  fun copyArray {src, si, dst : array, di, len = lenOpt} =
      let
        val copyLen = getOpt (lenOpt, A.length src - si)
      in
        ensureCapacity (dst, di + copyLen - 1);
        AS.copy
        {
         src = AS.slice (src,0,lenOpt), 
         (*si = si,*)
         dst = !(#buf dst),
         (*len = lenOpt, *)
         di = di
        }
      end

  fun copyVector {src, si, dst : array, di, len = lenOpt} =
    let
      val copyLen = getOpt (lenOpt, V.length src - si)
    in
      ensureCapacity (dst, di + copyLen - 1);
      AS.copyVec
       {
        src = VS.slice (src,si,lenOpt),
        (*si = si,*)
        dst = !(#buf dst), 
        (*len = lenOpt, *)
        di = di
        }
      end

  fun toArray ({buf, len, init, ...} : array) =
      let
        val result = A.array (!len, init)
        val _ =
          AS.copy
          {
           src = AS.slice(!buf,0,SOME (!len)),
          (*si = 0,*)
          dst = result, 
          (*len = SOME (!len),*)
          di = 0}
      in
        result
      end

  fun toVector ({buf, len, init, ...} : array) =
    (*A.extract*) 
    AS.vector (AS.slice (!buf, 0, SOME(!len)))

end;
