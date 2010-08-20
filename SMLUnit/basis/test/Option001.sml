(**
 * test cases for Option structure.
 *
 * @author YAMATODANI Kiyoshi
 * @copyright 2010, Tohoku University.
 *)
structure Option001 =
struct

  (************************************************************)

  structure A = SMLUnit.Assert
  structure T = SMLUnit.Test
  open A

  (************************************************************)

  fun getOpt001 () =
      let
        val getOpt1 = Option.getOpt (Option.NONE, 2)
        val () = assertEqualInt 2 getOpt1

        val getOpt2 = Option.getOpt (Option.SOME 1, 3)
        val () = assertEqualInt 1 getOpt2
      in
        ()
      end

  fun isSome001 () =
      let
        val isSome1 = Option.isSome Option.NONE
        val () = assertFalse isSome1

        val isSome2 = Option.isSome (Option.SOME 1)
        val () = assertTrue isSome2
      in
        ()
      end

  fun valOf001 () =
      let
        val valOf1 = Option.valOf Option.NONE handle Option.Option => 9
        val () = assertEqualInt 9 valOf1

        val valOf2 = Option.valOf (Option.SOME 2)
        val () = assertEqualInt 2 valOf2
      in
        ()
      end

  local
    fun filterFun x = x = 1
  in
  fun filter001 () =
      let
        val filter1 = Option.filter filterFun 1
        val () = assertEqualIntOption (SOME 1) filter1

        val filter2 = Option.filter filterFun 2
        val () = assertEqualIntOption NONE filter2
      in
        ()
      end
  end

  fun join001 () =
      let
        val join1 = Option.join Option.NONE
        val () = assertEqualIntOption NONE join1

        val join2 = Option.join (Option.SOME (Option.NONE))
        val () = assertEqualIntOption NONE join2

        val join3 = Option.join (Option.SOME (Option.SOME 1))
        val () = assertEqualIntOption (SOME 1) join3
      in
        ()
      end

  local
    fun mapFun x = x + 1
  in
  fun map001 () =
      let
        val map1 = Option.map mapFun Option.NONE
        val () = assertEqualIntOption NONE map1

        val map2 = Option.map mapFun (Option.SOME 1)
        val () = assertEqualIntOption (SOME 2) map2
      in
        ()
      end
  end

  local
    fun mapPartialFun x = if x then Option.SOME 1 else Option.NONE
  in
    fun mapPartial001 () =
        let
          val mapPartial1 = Option.mapPartial mapPartialFun Option.NONE
          val () = assertEqualIntOption NONE mapPartial1

          val mapPartial2 = Option.mapPartial mapPartialFun (Option.SOME true)
          val () = assertEqualIntOption (SOME 1) mapPartial2

          val mapPartial3 = Option.mapPartial mapPartialFun (Option.SOME false)
          val () = assertEqualIntOption NONE mapPartial3
        in
          ()
        end
  end

  local
    fun composeFun1 x = x * 10
    fun composeFun2 x = if x then Option.SOME 1 else Option.NONE
  in
  fun compose001 () =
      let
        val compose1 = Option.compose (composeFun1, composeFun2) true
        val () = assertEqualIntOption (SOME 10) compose1

        val compose2 = Option.compose (composeFun1, composeFun2) false
        val () = assertEqualIntOption NONE compose2
      in
        ()
      end
  end

  local
    fun composePartialFun1 x = if x = 0 then Option.SOME 9 else Option.NONE
    fun composePartialFun2 x = if 0 <= x then Option.SOME x else Option.NONE
  in
  fun composePartial001 () =
      let
        val composePartial1 =
            Option.composePartial (composePartialFun1, composePartialFun2) ~1
        val () = assertEqualIntOption NONE composePartial1

        val composePartial2 =
            Option.composePartial (composePartialFun1, composePartialFun2) 0
        val () = assertEqualIntOption (SOME 9) composePartial2

        val composePartial3 =
            Option.composePartial (composePartialFun1, composePartialFun2) 1
        val () = assertEqualIntOption NONE composePartial3
      in
        ()
      end
  end

  (****************************************)

  fun suite () =
      T.labelTests
      [
        ("getOpt001", getOpt001),
        ("isSome001", isSome001),
        ("valOf001", valOf001),
        ("filter001", filter001),
        ("join001", join001),
        ("map001", map001),
        ("mapPartial001", mapPartial001),
        ("compose001", compose001),
        ("composePartial001", composePartial001)
      ]

  (************************************************************)

end