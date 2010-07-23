(**
 * test case for General structure.
 *
 * @author YAMATODANI Kiyoshi
 * @copyright 2010, Tohoku University.
 *)
structure General001 =
struct

  (************************************************************)

  structure A = SMLUnit.Assert
  structure T = SMLUnit.Test
  open A

  val assertEqualInt2Tuple = assertEqual2Tuple (assertEqualInt, assertEqualInt)

  (************************************************************)

  local
    fun test arg expected = assertEqualString expected (General.exnName arg)
  in
  fun exnName001 () =
      let
        val nameBind = test General.Bind "Bind" 
        val nameMatch = test General.Match "Match" 
        val nameChr = test General.Chr "Chr" 
        val nameDiv = test General.Div "Div" 
        val nameDomain = test General.Domain "Domain" 
        val nameFail = test (General.Fail "foo") "Fail" 
        val nameOverflow = test General.Overflow "Overflow" 
        val nameSize = test General.Size "Size" 
        val nameSpan = test General.Span "Span" 
        val nameSubscript = test General.Subscript "Subscript" 
      in () end
  end (* local *)

  (********************)

  fun deref001 () =
      let
        val refMonoUnboxed1 = ref 100
        val derefMonoUnboxed1 = General.! refMonoUnboxed1
        val _ = assertEqualInt 100 derefMonoUnboxed1

        val refMonoBoxed1 = ref (1, 2)
        val derefMonoBoxed1 = General.! refMonoBoxed1
        val _ = assertEqualInt2Tuple (1, 2) derefMonoBoxed1

        val refPoly1 = ref (fn x => x)
        val derefPoly1 = General.! refPoly1
        val _ = assertEqualInt 1 (derefPoly1 1)
      in () end

  (********************)

  fun assign001 () =
      let
        val refMonoUnboxed2 = ref 200
        val x = General.:= (refMonoUnboxed2, 400)
        val _ = assertEqualInt 400 (!refMonoUnboxed2)

        val refMonoBoxed2 = ref (2, 3)
        val x = General.:= (refMonoBoxed2, (4, 6))
        val _ = assertEqualInt2Tuple (4, 6) (!refMonoBoxed2)

        val refPoly2 = ref (fn x => (0, x))
        val x = General.:= (refPoly2, (fn x => (1, x)))
        val _ = assertEqualInt2Tuple (1, 9) (!refPoly2 9)
      in () end

  (********************)

  fun composition001 () =
      let
        val f1 = fn x => x + 1
        val f2 = fn x => x * 100
        val comp1 = (General.o (f1, f2)) 2
        val _ = assertEqualInt 201 comp1
      in () end

  (********************)

  fun before001 () =
      let
        val beforeRef1 = ref 1
        val before1 =
            General.before
                (
                  beforeRef1 := (!beforeRef1 + 1),
                  beforeRef1 := (!beforeRef1 * 10)
                )
        val _ = assertEqualInt 20 (!beforeRef1)
      in () end

  (********************)

  fun ignore001 () =
      let
        val ignore1 = General.ignore 1
        val _ = assertEqualUnit ignore1
      in () end

  (****************************************)

  fun suite () =
      T.labelTests
      [
        ("exnName001", exnName001),
        ("deref001", deref001),
        ("assign001", assign001),
        ("composition001", composition001),
        ("before001", before001),
        ("ignore001", ignore001)
      ]

  (************************************************************)

end