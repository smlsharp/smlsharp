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
        val _ = assertFalse not_true
        val not_false = Bool.not Bool.false
        val _ = assertTrue not_false
      in () end

  (********************)

  local
    fun test arg expected =
        assertEqualBoolOption expected (Bool.fromString arg)
  in
  fun fromString001 () =
      let
        val fromString_empty = test "" NONE
        val fromString_true = test "true" (SOME true)
        val fromString_false = test "false" (SOME false)
        val fromString_space_true = test " \t\ntrue" (SOME true)
        val fromString_TruE = test "TruE" (SOME true)
        val fromString_FalsE = test "FalsE" (SOME false)
        val fromString_true_trailer = test "truefalse" (SOME true)
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
        val scan_empty = test "" NONE
        val scan_true = test "true" (SOME(true, []))
        val scan_false = test "false" (SOME(false, []))
        val scan_space_true = test " \t\ntrue" (SOME(true, []))
        val scan_TRUE = test "TruE" (SOME(true, []))
        val scan_FALSE = test "FalsE" (SOME(false, []))
        val scan_true_trailer = test "truefalse" (SOME(true, explode "false"))
      in () end
  end (* local *)

  (********************)

  fun toString001 () =
      let
        val toString_true = Bool.toString Bool.true
        val _ = assertEqualString "true" toString_true

        val toString_false = Bool.toString Bool.false
        val _ = assertEqualString "false" toString_false
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