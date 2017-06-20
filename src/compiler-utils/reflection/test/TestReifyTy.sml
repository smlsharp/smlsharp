 (**
 * @author Atsushi Ohori
 * @copyright 2016, Tohoku University.
 *)
structure TestReifyTy =
struct
  structure Assert = SMLUnit.Assert
  structure Test = SMLUnit.Test
  structure R = ReifiedTy

  datatype foo = A of int | B of bool
  datatype 'a bar = A of 'a | B of bool
  datatype 'a hoge = A of int | B of 'a toge
  and 'a toge = C of bool | D of 'a hoge

  val dataTy =
      [
       _reifyTy(int),
       _reifyTy(bool), 
       _reifyTy(string),
       _reifyTy(int list),
       _reifyTy(string list),
       _reifyTy(bool list),
       _reifyTy(foo),
       _reifyTy(int bar),
       _reifyTy(foo bar),
       _reifyTy(int bar bar),
       _reifyTy(int hoge),
       _reifyTy(bool toge hoge)
      
      ]

  fun printTyRep x = print (ReifiedTy.tyRepToString x ^ "\n")
  fun printReifiedTy x = print (ReifiedTy.reifiedTyToString (#reifiedTy x) ^ "\n")
  val _ = map printTyRep dataTy;
  val _ = print "\n"
  val _ = map printReifiedTy dataTy
  val _ = print "\n"

  val dataTy = map ReifiedTy.getConstructTy dataTy
  val _ =  map printReifiedTy dataTy

  val dataTyString =
      [
       (_reifyTy(int), "int"),
       (_reifyTy(bool), "bool"),
       (_reifyTy(string), "string"),
       (_reifyTy(int list), "int list"),
       (_reifyTy(string list), "string list"),
       (_reifyTy(bool list), "bool list"),
       (_reifyTy(foo), "foo"),
       (_reifyTy(int bar), "int bar")
      ]

(*
  fun testReify001 () =
      let 
        fun assert (ty1, ty2) = 
            Test.TestCase (fn () => ReifiedTy.assertEqualReifiedTy (#reifiedTy ty1) ty2)
      in Test.TestList (map assert dataTyTy)
      end
*)
  fun testReify002 () =
      let 
        fun assert (ty, string) = 
            Test.TestCase (fn () => Assert.assertEqualString (ReifiedTy.reifiedTyToString (#reifiedTy ty)) string)
      in Test.TestList (map assert dataTyString)
      end

  fun suite () =
      Test.TestList
      [
(*
       Test.TestLabel ("testReify001", testReify001 ()),
*)
       Test.TestLabel ("testReify002", testReify002 ())
      ]
end
val _ =
    SMLUnit.TextUITestRunner.runTest
    {output = TextIO.stdOut}
    (SMLUnit.Test.TestList
       [
        TestReifyTy.suite ()
        ]
    )
