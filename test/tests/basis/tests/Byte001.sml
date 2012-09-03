(*
test cases for Byte structure.
*)

structure AS : MONO_ARRAY_SLICE = Word8ArraySlice;
structure A : MONO_ARRAY = Word8Array;
structure VS : MONO_VECTOR_SLICE = Word8VectorSlice;
structure V : MONO_VECTOR = Word8Vector;

fun L2AS list =
    let val array = A.fromList (0w99 :: list @ [0w88])
    in AS.slice(array, 1, SOME(length list)) end;
fun L2VS list =
    let val vector = V.fromList (0w99 :: list @ [0w88])
    in VS.slice(vector, 1, SOME(length list)) end;

fun AS2L array =
    let
      val length = AS.length array
      fun scan ~1 accum = accum
        | scan n accum = scan (n - 1) (AS.sub(array, n) :: accum)
    in scan (length - 1) []
    end;
fun VS2L vector =
    let
      val length = VS.length vector
      fun scan ~1 accum = accum
        | scan n accum = scan (n - 1) (VS.sub(vector, n) :: accum)
    in scan (length - 1) []
    end;
fun V2L vector =
    let
      val length = V.length vector
      fun scan ~1 accum = accum
        | scan n accum = scan (n - 1) (V.sub(vector, n) :: accum)
    in scan (length - 1) []
    end;
fun L2V list = V.fromList list;
fun A2L array =
    let
      val length = A.length array
      fun scan ~1 accum = accum
        | scan n accum = scan (n - 1) (A.sub(array, n) :: accum)
    in scan (length - 1) []
    end;
fun L2A list = A.fromList list;
fun makeArray length = A.tabulate (length, fn index => Word8.fromInt index)

(**********)
val byteToChar_1 = Byte.byteToChar (0w97);

(**********)
val charToByte_1 = Byte.charToByte #"a";

(**********)
val bytesToString_0 = Byte.bytesToString (L2V []);
val bytesToString_1 = Byte.bytesToString (L2V [0w97]);

(**********)
val stringToBytes_0 = V2L(Byte.stringToBytes "");
val stringToBytes_1 = V2L(Byte.stringToBytes "a");

(**********)
val unpackStringVec_0 = Byte.unpackStringVec (L2VS []);
val unpackStringVec_1 = Byte.unpackStringVec (L2VS [0w97]);

(**********)
val unpackString_0 = Byte.unpackString (L2AS []);
val unpackString_1 = Byte.unpackString (L2AS [0w97]);

(**********)
fun testPackString (arraySize, start, string) =
    let val array = makeArray arraySize
    in
      Byte.packString (array, start, Substring.full string);
      A2L array
    end
      handle Subscript => [0w9];
val packString_000 = testPackString (0, 0, "");
val packString_3m11 = testPackString (3, ~1, "a");
val packString_301 = testPackString (3, 0, "a");
val packString_311 = testPackString (3, 1, "a");
val packString_321 = testPackString (3, 2, "a");
val packString_331 = testPackString (3, 3, "a");
val packString_302 = testPackString (3, 0, "ab");
val packString_312 = testPackString (3, 1, "ab");
val packString_322 = testPackString (3, 2, "ab");
