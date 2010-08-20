(**
 * test cases for Byte structure.
 *
 * @author YAMATODANI Kiyoshi
 * @copyright 2010, Tohoku University.
 *)
structure Byte001 =
struct

  (************************************************************)

  structure A = SMLUnit.Assert
  structure T = SMLUnit.Test
  open A

  structure AS : MONO_ARRAY_SLICE = Word8ArraySlice
  structure A : MONO_ARRAY = Word8Array
  structure VS : MONO_VECTOR_SLICE = Word8VectorSlice
  structure V : MONO_VECTOR = Word8Vector

  (************************************************************)

  fun L2AS list =
      let val array = A.fromList (0w99 :: list @ [0w88])
      in AS.slice(array, 1, SOME(length list)) end
  fun L2VS list =
      let val vector = V.fromList (0w99 :: list @ [0w88])
      in VS.slice(vector, 1, SOME(length list)) end

  fun V2L vector =
      let
        val length = V.length vector
        fun scan ~1 accum = accum
          | scan n accum = scan (n - 1) (V.sub(vector, n) :: accum)
      in scan (length - 1) []
      end
  fun L2V list = V.fromList list
  fun A2L array =
      let
        val length = A.length array
        fun scan ~1 accum = accum
          | scan n accum = scan (n - 1) (A.sub(array, n) :: accum)
      in scan (length - 1) []
      end
  fun L2A list = A.fromList list

  (****************************************)

  fun byteToChar001 () =
      let
        val byteToChar_1 = Byte.byteToChar (0w97)
        val () = assertEqualChar #"a" byteToChar_1
      in () end

  (********************)

  fun charToByte001 () =
      let
        val charToByte_1 = Byte.charToByte #"a"
        val () = assertEqualWord8 0w97 charToByte_1
      in () end

  (********************)

  fun bytesToString001 () =
      let
        val bytesToString_0 = Byte.bytesToString (L2V [])
        val () = assertEqualString "" bytesToString_0
        val bytesToString_1 = Byte.bytesToString (L2V [0w97])
        val () = assertEqualString "a" bytesToString_1
      in () end

  (********************)

  fun stringToBytes001 () =
      let
        val stringToBytes_0 = V2L(Byte.stringToBytes "")
        val () = assertEqualWord8List [] stringToBytes_0
        val stringToBytes_1 = V2L(Byte.stringToBytes "a")
        val () = assertEqualWord8List [0w97] stringToBytes_1
      in () end

  (********************)

  fun unpackStringVec001 () =
      let
        val unpackStringVec_0 = Byte.unpackStringVec (L2VS [])
        val () = assertEqualString "" unpackStringVec_0
        val unpackStringVec_1 = Byte.unpackStringVec (L2VS [0w97])
        val () = assertEqualString "a" unpackStringVec_1
      in () end

  (********************)

  fun unpackString001 () =
      let
        val unpackString_0 = Byte.unpackString (L2AS [])
        val () = assertEqualString "" unpackString_0
        val unpackString_1 = Byte.unpackString (L2AS [0w97])
        val () = assertEqualString "a" unpackString_1
      in () end

  (********************)

  local
    fun makeArray length = A.tabulate (length, fn index => Word8.fromInt index)
    fun test (arraySize, start, string) expected =
        let val array = makeArray arraySize
        in
          Byte.packString (array, start, Substring.full string);
          assertEqualWord8List expected (A2L array)
        end
    fun testFail (arraySize, start, string) = 
        let val array = makeArray arraySize
        in
          Byte.packString (array, start, Substring.full string);
          fail "packString: Subscript expected."
        end
          handle General.Subscript => ()
  in
  fun packString001 () =
      let
        val case_000 as () = test (0, 0, "") []
        val case_3m11 as () = testFail (3, ~1, "a")
        val case_301 as () = test (3, 0, "a") [0w97, 0w1, 0w2]
        val case_311 as () = test (3, 1, "a") [0w0, 0w97, 0w2]
        val case_321 as () = test (3, 2, "a") [0w0, 0w1, 0w97]
        val case_331 as () = testFail (3, 3, "a")
        val case_302 as () = test (3, 0, "ab") [0w97, 0w98, 0w2]
        val case_312 as () = test (3, 1, "ab") [0w0, 0w97, 0w98]
        val case_322 as () = testFail (3, 2, "ab")
      in () end
  end

  (****************************************)

  fun suite () =
      T.labelTests
      [
        ("byteToChar001", byteToChar001),
        ("charToByte001", charToByte001),
        ("bytesToString001", bytesToString001),
        ("stringToBytes001", stringToBytes001),
        ("unpackStringVec001", unpackStringVec001),
        ("unpackString001", unpackString001),
        ("packString001", packString001)
      ]

  (************************************************************)

end