(**
 * tests for document example
 *
 * @copyright (C) 2021 SML# Development Team.
 *)

structure ExampleTests =
struct
open SMLUnit.Test SMLUnit.Assert Compiler


val testList = [
    "Ch05_04_01_Hello",
    "Ch06_03_01_Sn",
    "Ch06_04_01_Int",
    "Ch06_04_02_Real",
    "Ch06_04_03_Char",
    "Ch06_04_04_String",
    "Ch06_04_05_Word",
    "Ch06_05_01_bool",
    "Ch06_06_01_Fun",
    "Ch06_07_01_FunRec",
    "Ch06_08_01_FunMultiArg",
    "Ch06_10_01_FunHigherOrder",
    "Ch06_11_01_UsingFunHigherOrder",
    "Ch06_13_01_Ref",
    "Ch06_19_01_Exp",
    "Ch06_20_01_PolyFun",
    "Ch07_01_01_record",
    "Ch07_02_01_FieldSelection",
    "Ch07_03_01_RecordPattern",
    "Ch07_04_01_FieldUpdate",
    "Ch07_05_01_RecordProgrammingExample",
    "Ch07_06_01_RepresentingObject",
    "Ch07_07_01_PolyVariant",
    "Ch08_01_01_Rank1Poly",
    "Ch08_03_01_FirstClassOverloading"
(* JSON は Dynamicに置き換え
,
  "Ch12_03_01_JSONProgrammingExample"
*)
]

fun inputAll path =
    let
      val io = TextIO.openIn path
    in
      (TextIO.inputAll io handle e => (TextIO.closeIn io; raise e))
      before TextIO.closeIn io
    end

fun assertFile name =
    let
      val output = interactiveFile' ("example/" ^ name ^ ".sml")
      val actual = String.concatWith "\n" (#prints output)
      val expected = inputAll ("./tests/data/example/" ^ name ^ ".out")
    in
      assertEqualString expected actual
    end

fun testFile name =
     Test (name, fn () => assertFile name)


val tests = TestList (map testFile testList)

end
