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
        val case_m1 as () = test #"a" 0 "xx" ("xx", "xx")
        val case_0 as () = test #"a" 0 "xx" ("xx", "xx")
        val case_1 as () = test #"a" 1 "xx" ("xx", "xx")
        val case_2 as () = test #"a" 2 "xx" ("xx", "xx")
        val case_3 as () = test #"a" 3 "xx" ("axx", "xxa")
        val case_4 as () = test #"a" 4 "xx" ("aaxx", "xxaa")
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
        val case_0 as () = test "" ("", [])
        val case_10 as () = test "x" ("", [#"x"])
        val case_11 as () = test "a" ("a", [])
        val case_200 as () = test "xy" ("", [#"x", #"y"])
        val case_201 as () = test "xa" ("", [#"x", #"a"])
        val case_210 as () = test "ay" ("a", [#"y"])
        val case_211 as () = test "ab" ("ab", [])
        val case_3000 as () = test "xyz" ("", [#"x", #"y", #"z"])
        val case_3001 as () = test "xya" ("", [#"x", #"y", #"a"])
        val case_3010 as () = test "xaz" ("", [#"x", #"a", #"z"])
        val case_3100 as () = test "ayz" ("a", [ #"y", #"z"])
        val case_3110 as () = test "abz" ("ab", [#"z"])
        val case_3111 as () = test "abc" ("abc", [])
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
        val case_0 as () = test "" ("", [])
        val case_10 as () = test "x" ("", [#"x"])
        val case_11 as () = test "a" ("a", [])
        val case_200 as () = test "xy" ("", [#"x", #"y"])
        val case_201 as () = test "xa" ("", [#"x", #"a"])
        val case_210 as () = test "ay" ("a", [#"y"])
        val case_211 as () = test "ab" ("ab", [])
        val case_3000 as () = test "xyz" ("", [#"x", #"y", #"z"])
        val case_3001 as () = test "xya" ("", [#"x", #"y", #"a"])
        val case_3010 as () = test "xaz" ("", [#"x", #"a", #"z"])
        val case_3100 as () = test "ayz" ("a", [ #"y", #"z"])
        val case_3110 as () = test "abz" ("ab", [#"z"])
        val case_3111 as () = test "abc" ("abc", [])
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
        val case0 as () = test "" []
        val case1 as () = test "a" [#"a"]
        val case2 as () = test "\032\010\009\013\011\012a" [#"a"]
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
        val case_0 as () = test "" NONE
        val case_1 as () = test "a" (SOME(#"a", #"a"))
        val case_2 as () = test "ab" (SOME(#"a", #"a"))
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