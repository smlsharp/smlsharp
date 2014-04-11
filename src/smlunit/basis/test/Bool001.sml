(**
 * test cases for Bool structure.
 *
 * @author YAMATODANI Kiyoshi
 * @copyright 2010, Tohoku University.
 *)
structure Bool001 =
struct

  (************************************************************)

  structure A = SMLUnit.Assert
  structure T = SMLUnit.Test
  open A

  (************************************************************)

  val assertEqualBoolOption = assertEqualOption assertEqualBool
  val assertEqualBoolCListOption =
      assertEqualOption
          (assertEqual2Tuple (assertEqualBool, assertEqualCharList))

  (****************************************)

  fun not001 () =
      let
        val not_true = Bool.not Bool.true
        val () = assertFalse not_true
        val not_false = Bool.not Bool.false
        val () = assertTrue not_false
      in () end

  (********************)

  local
    fun test arg expected =
        assertEqualBoolOption expected (Bool.fromString arg)
  in
  fun fromString001 () =
      let
        val case_empty as () = test "" NONE
        val case_true as () = test "true" (SOME true)
        val case_false as () = test "false" (SOME false)
        val case_space_true as () = test " \t\ntrue" (SOME true)
        val case_TruE as () = test "TruE" (SOME true)
        val case_FalsE as () = test "FalsE" (SOME false)
        val case_true_trailer as () = test "truefalse" (SOME true)
      in () end
  end (* local *)

  (********************)

  local
    fun test arg expected =
        assertEqualBoolCListOption
            expected (Bool.scan List.getItem (explode arg))
  in
  fun scan001 () =
      let
        val case_empty as () = test "" NONE
        val case_true as () = test "true" (SOME(true, []))
        val case_false as () = test "false" (SOME(false, []))
        val case_space_true as () = test " \t\ntrue" (SOME(true, []))
        val case_TRUE as () = test "TruE" (SOME(true, []))
        val case_FALSE as () = test "FalsE" (SOME(false, []))
        val case_true_trailer as () = test "truefalse" (SOME(true, explode "false"))
      in () end
  end (* local *)

  (********************)

  fun toString001 () =
      let
        val toString_true = Bool.toString Bool.true
        val () = assertEqualString "true" toString_true

        val toString_false = Bool.toString Bool.false
        val () = assertEqualString "false" toString_false
      in () end

  (****************************************)

  fun suite () =
      T.labelTests
      [
        ("not001", not001),
        ("fromString001", fromString001),
        ("scan001", scan001),
        ("toString001", toString001)
      ]

  (************************************************************)

end