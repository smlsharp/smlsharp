structure Import =
struct
open SMLUnit.Test SMLUnit.Assert

  fun testImportAtoi() =
      let
        val atoi = _import "atoi" : __attribute__((pure, fast)) string -> int
        val a = "123"
        val _ = assertEqualInt 123 (atoi a)
        val a = "124"
        val _ = assertEqualInt 124 (atoi a)
        val _ = assertEqualInt 0 (atoi "A")
      in
        ()
      end

  fun testImportStrtod() =
      let
        val strtod = _import "strtod" : (string, char ptr ref) -> real
        val endptr = ref (Pointer.NULL ())
        val r = strtod("1.23abc", endptr)
        val _ = assertEqualReal 1.23 r
        val _ = assertEqualString "abc" (Pointer.importString (!endptr))
      in
        ()
      end

  fun testImportSprintf() =
      let
        val malloc = _import "malloc" : int -> char ptr
        val free = _import "free" : char ptr -> ()
        val sprintf = _import "sprintf" 
                      : (char ptr, string, ... (string, int)) -> int 
        val ret = malloc(100)
        val _ = sprintf (ret, "%s %d", "abc", 1)
        val _ = assertEqualString "abc 1" (Pointer.importString ret)
        val _ = free ret
      in
        ()
      end

  fun testImportQsortUnboxed() =
      let
        val 'a#unboxed qsort =
            _import "qsort" 
            : ('a array, int, word, ('a ptr, 'a ptr) -> int) -> ()
        val ary = Array.fromList [1,6,4,0,7,3,2,9,5,8]
        fun compare (xPtr, yPtr) = 
            case Int.compare (Pointer.load xPtr, Pointer.load yPtr) of
                 EQUAL => 0
               | GREATER => 1
               | LESS => ~1
        val width = ReifiedTy.sizeOf ReifiedTy.INT32ty
        val _ = qsort (ary, Array.length ary, width, compare)
        val sortedAry = Array.fromList [0,1,2,3,4,5,6,7,8,9]
        val _ = assertEqualArray assertEqualInt sortedAry ary
      in
        ()
      end

  fun testImportQsortBoxed() =
      let
        val 'a#boxed qsort =
            _import "qsort" 
            : ('a array, int, word, ('a ptr, 'a ptr) -> int) -> ()
        val ary = Array.fromList ["b","d","a","c"]
        fun compare (xPtr, yPtr) = 
            case String.compare (Pointer.load xPtr, Pointer.load yPtr) of
                 EQUAL => 0
               | GREATER => 1
               | LESS => ~1
        val width = ReifiedTy.sizeOf ReifiedTy.STRINGty
        val _ = qsort (ary, Array.length ary, width, compare)
        val sortedAry = Array.fromList ["a","b","c","d"]
        val _ = assertEqualArray assertEqualString sortedAry ary
      in
        ()
      end

  val tests = TestList [
    Test ("testImportAtoi", testImportAtoi),
    Test ("testImportStrtod", testImportStrtod),
    Test ("testImportFprintf", testImportSprintf),
    Test ("testImportQsortUnboxed", testImportQsortUnboxed),
    Test ("testImportQsortBoxed", testImportQsortBoxed)
  ]

end
