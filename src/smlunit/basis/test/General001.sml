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
    fun test arg expected =
        assertEqualAlternatives
            assertEqualString expected (General.exnName arg)
  in
  fun exnName001 () =
      let
        (* exnName may return the name of any exception constructor aliasing
         * the argument exception. *)
        val case_Bind as () = test General.Bind ["Bind", "General.Bind"]
        val case_Match as () = test General.Match ["Match", "General.Match"]
        val case_Chr as () = test General.Chr ["Chr", "General.Chr"]
        val case_Div as () = test General.Div ["Div", "General.Div"] 
        val case_Domain as () = test General.Domain ["Domain", "General.Domain"] 
        val case_Fail as () = test (General.Fail "foo") ["Fail", "General.Fail"] 
        val case_Overflow as () = test General.Overflow ["Overflow", "General.Overflow"] 
        val case_Size as () = test General.Size ["Size", "General.Size"] 
        val case_Span as () = test General.Span ["Span", "General.Span"] 
        val case_Subscript as () = test General.Subscript ["Subscript", "General.Subscript"] 
      in () end
  end (* local *)

  (********************)

  fun deref001 () =
      let
        val refMonoUnboxed1 = ref 100
        val derefMonoUnboxed1 = General.! refMonoUnboxed1
        val () = assertEqualInt 100 derefMonoUnboxed1

        val refMonoBoxed1 = ref (1, 2)
        val derefMonoBoxed1 = General.! refMonoBoxed1
        val () = assertEqualInt2Tuple (1, 2) derefMonoBoxed1

        val refPoly1 = ref (fn x => x)
        val derefPoly1 = General.! refPoly1
        val () = assertEqualInt 1 (derefPoly1 1)
      in () end

  (********************)

  fun assign001 () =
      let
        val refMonoUnboxed2 = ref 200
        val x = General.:= (refMonoUnboxed2, 400)
        val () = assertEqualInt 400 (!refMonoUnboxed2)

        val refMonoBoxed2 = ref (2, 3)
        val x = General.:= (refMonoBoxed2, (4, 6))
        val () = assertEqualInt2Tuple (4, 6) (!refMonoBoxed2)

        val refPoly2 = ref (fn x => (0, x))
        val x = General.:= (refPoly2, (fn x => (1, x)))
        val () = assertEqualInt2Tuple (1, 9) (!refPoly2 9)
      in () end

  (********************)

  fun composition001 () =
      let
        val f1 = fn x => x + 1
        val f2 = fn x => x * 100
        val comp1 = (General.o (f1, f2)) 2
        val () = assertEqualInt 201 comp1
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
        val () = assertEqualInt 20 (!beforeRef1)
      in () end

  (********************)

  fun ignore001 () =
      let
        val ignore1 = General.ignore 1
        val () = assertEqualUnit () ignore1
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