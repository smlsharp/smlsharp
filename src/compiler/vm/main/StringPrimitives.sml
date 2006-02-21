(**
 * Copyright (c) 2006, Tohoku University.
 *
 * implementation of primitives on string values.
 * @author YAMATODANI Kiyoshi
 * @version $Id: StringPrimitives.sml,v 1.7 2006/02/18 04:59:40 ohori Exp $
 *)
structure StringPrimitives : PRIMITIVE_IMPLEMENTATIONS =
struct

  (***************************************************************************)

  open RuntimeTypes
  open BasicTypes
  structure RE = RuntimeErrors
  structure SLD = SourceLanguageDatatypes
  structure H = Heap

  (***************************************************************************)

  fun String_concat2
          VM heap [leftAddress as Pointer _, rightAddress as Pointer _] =
      let
        val (leftArray, leftLength) = SLD.expandStringBlock heap leftAddress
        val (rightArray, rightLength) = SLD.expandStringBlock heap rightAddress

        val resultLength = leftLength + rightLength
        val resultArray = Word8Array.array (UInt32ToInt(resultLength), 0w0)
        val _ = 
            Word8Array.copy
                {
                  dst = resultArray,
                  di = 0,
                  len = SOME (UInt32ToInt leftLength),
                  src = leftArray,
                  si = 0
                }
        val _ =
            Word8Array.copy
                {
                  dst = resultArray,
                  di = UInt32ToInt leftLength,
                  len = SOME (UInt32ToInt rightLength),
                  src = rightArray,
                  si = 0
                }
        val resultBlock =
            SLD.allocateStringBlock heap (resultArray, resultLength)

      in [Pointer resultBlock] end
    | String_concat2 _ _ _ =
      raise RE.UnexpectedPrimitiveArguments "String_concat2"

  fun String_sub VM heap [stringAddress as Pointer _, Int index] =
      let
        val (array, length) = SLD.expandStringBlock heap stringAddress
        val string = UInt8ArrayToString(array, length)
        val char = String.sub (string, SInt32ToInt index)
      in [Word (IntToUInt32(Char.ord char))] end
    | String_sub _ _ _ = raise RE.UnexpectedPrimitiveArguments "String_sub"

  fun String_size VM heap [stringAddress as Pointer _] =
      let
        val (array, length) = SLD.expandStringBlock heap stringAddress
      in [Int (UInt32ToSInt32 length)] end
    | String_size _ _ _ = raise RE.UnexpectedPrimitiveArguments "String_size"

  fun String_substring
          VM heap [stringAddress as Pointer _, Int begin, Int length] =
      let
        val string =
            UInt8ArrayToString (SLD.expandStringBlock heap stringAddress)
        val resultString =
            String.substring (string, SInt32ToInt begin, SInt32ToInt length)
      in
        [SLD.stringToValue heap resultString]
      end
    | String_substring _ _ _ =
      raise RE.UnexpectedPrimitiveArguments "String_substring"

  fun String_update
          VM heap [stringAddress as Pointer _, Int index, Word char] =
      let
        val (array, length) = (SLD.expandStringBlock heap stringAddress)
        val charCode = UInt32ToUInt8 char
        val _ = Word8Array.update (array, SInt32ToInt index, charCode)
      in [SLD.unitToValue heap ()] end
    | String_update _ _ _ =
      raise RE.UnexpectedPrimitiveArguments "String_update"

  fun String_allocate VM heap [Int length, Word char] =
      let
        val byteArray =
            Word8Array.array (SInt32ToInt length, UInt32ToUInt8 char)
        val stringBlock =
            SLD.allocateStringBlock heap (byteArray, SInt32ToUInt32 length)
      in
        [Pointer stringBlock]
      end
    | String_allocate _ _ _ =
      raise RE.UnexpectedPrimitiveArguments "String_allocate"

  val primitives =
      [
        {name = "String_concat2", function = String_concat2},
        {name = "String_sub", function = String_sub},
        {name = "String_size", function = String_size},
        {name = "String_substring", function = String_substring},
        {name = "String_update", function = String_update},
        {name = "String_allocate", function = String_allocate}
      ]

  (***************************************************************************)

end;
