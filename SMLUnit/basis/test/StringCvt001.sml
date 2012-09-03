(**
 * test cases for StringCvt.
 *
 * @author YAMATODANI Kiyoshi
 * @copyright 2010, Tohoku University.
 *)
structure StringCvt001 =
struct

  (************************************************************)

  structure A = SMLUnit.Assert
  structure T = SMLUnit.Test
  open A

  structure S = StringCvt

  (************************************************************)

  val assertEqualStringCList =
      assertEqual2Tuple (assertEqualString, assertEqualCharList)

  val assertEqualChar2Option =
      assertEqualOption (assertEqual2Tuple (assertEqualChar, assertEqualChar))

  val assertEqualString2 =
      assertEqual2Tuple (assertEqualString, assertEqualString)

  (********************)

  local
    fun test arg1 arg2 arg3 expected =
        assertEqualString2
            expected (S.padLeft arg1 arg2 arg3, S.padRight arg1 arg2 arg3)
  in
  fun pad0001 () =
      let
        val pad_m1 = test #"a" 0 "xx" ("xx", "xx")
        val pad_0 = test #"a" 0 "xx" ("xx", "xx")
        val pad_1 = test #"a" 1 "xx" ("xx", "xx")
        val pad_2 = test #"a" 2 "xx" ("xx", "xx")
        val pad_3 = test #"a" 3 "xx" ("axx", "xxa")
        val pad_4 = test #"a" 4 "xx" ("aaxx", "xxaa")
      in
        ()
      end
  end (* local *)

  (********************)

  local
    fun predicate c = c = #"a" orelse c = #"b" orelse c = #"c"
  in
  local
    fun test arg expected =
        assertEqualStringCList
            expected (S.splitl predicate List.getItem (explode arg))
  in
  fun splitl0001 () =
      let
        val splitl_0 = test "" ("", [])
        val splitl_10 = test "x" ("", [#"x"])
        val splitl_11 = test "a" ("a", [])
        val splitl_200 = test "xy" ("", [#"x", #"y"])
        val splitl_201 = test "xa" ("", [#"x", #"a"])
        val splitl_210 = test "ay" ("a", [#"y"])
        val splitl_211 = test "ab" ("ab", [])
        val splitl_3000 = test "xyz" ("", [#"x", #"y", #"z"])
        val splitl_3001 = test "xya" ("", [#"x", #"y", #"a"])
        val splitl_3010 = test "xaz" ("", [#"x", #"a", #"z"])
        val splitl_3100 = test "ayz" ("a", [ #"y", #"z"])
        val splitl_3110 = test "abz" ("ab", [#"z"])
        val splitl_3111 = test "abc" ("abc", [])
      in
        ()
      end
  end (* local *)

  local
    fun test arg expected =
        assertEqualStringCList
            expected
            (
              S.takel predicate List.getItem (explode arg),
              S.dropl predicate List.getItem (explode arg)
            )
  in
  fun takeDrop0001 () =
      let
        val takedrop_0 = test "" ("", [])
        val takedrop_10 = test "x" ("", [#"x"])
        val takedrop_11 = test "a" ("a", [])
        val takedrop_200 = test "xy" ("", [#"x", #"y"])
        val takedrop_201 = test "xa" ("", [#"x", #"a"])
        val takedrop_210 = test "ay" ("a", [#"y"])
        val takedrop_211 = test "ab" ("ab", [])
        val takedrop_3000 = test "xyz" ("", [#"x", #"y", #"z"])
        val takedrop_3001 = test "xya" ("", [#"x", #"y", #"a"])
        val takedrop_3010 = test "xaz" ("", [#"x", #"a", #"z"])
        val takedrop_3100 = test "ayz" ("a", [ #"y", #"z"])
        val takedrop_3110 = test "abz" ("ab", [#"z"])
        val takedrop_3111 = test "abc" ("abc", [])
      in
        ()
      end
  end (* local *)

  end (* outer local *)

  local
    fun test arg expected =
        assertEqualCharList expected (S.skipWS List.getItem (explode arg))
  in
  fun skipWS0001 () =
      let
        (*
        whitespace characters are space (032), newline(010), tab(009),
        carriage return(013), vertical tab(011), formfeed(012)
         *)
        val skipWS0 = test "" []
        val skipWS1 = test "a" [#"a"]
        val skipWS2 = test "\032\010\009\013\011\012a" [#"a"]
      in
        ()
      end
  end (* local *)

  local
    fun conv reader stream =
        case reader stream of
          NONE => NONE
        | SOME(ch, newStream) => SOME((ch, ch), newStream)
    fun test arg expected =
        assertEqualChar2Option expected (S.scanString conv arg)
  in
  fun scanString0001 () =
      let
        val scanString_0 = test "" NONE
        val scanString_1 = test "a" (SOME(#"a", #"a"))
        val scanString_2 = test "ab" (SOME(#"a", #"a"))
      in
        ()
      end
  end (* local *)

  (****************************************)

  fun suite () =
      T.labelTests
      [
        ("pad0001", pad0001),
        ("splitl0001", splitl0001),
        ("takeDrop0001", takeDrop0001),
        ("skipWS0001", skipWS0001),
        ("scanString0001", scanString0001)
      ]

  (************************************************************)

end