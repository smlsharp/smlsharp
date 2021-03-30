(**
 * @author Atsushi Ohori
 * @copyright (C) 2021 SML# Development Team.
 *)
structure TestPolyDynamic =
struct
(*
structure Test =
  struct
    type testFunction = unit -> unit
    datatype test =
        TestCase of testFunction
      | TestLabel of string * SMLUnit.Test.test
      | TestList of SMLUnit.Test.test list
    val labelTests = fn : (string * testFunction) list -> SMLUnit.Test.test
  end

structure PolyDynamic =
  struct
    type object (= boxed)
    type dynamic (= boxed)
    type tyRep = JSONTypes.jsonTy
    exception IlleagalJsonTy
    exception IlleagalObject

    val dynamic : ['a#dynamic.'a -> dynamic]

    val typeOf : dynamic -> tyRep
    val objOf : dynamic -> object
    val size : object -> word
    val mkDynamic : {ty:tyRep, obj:object} -> dynamic
    val sizeOf : tyRep -> word
    val offset : object * word -> object

    val deref : object -> object

    val align : object * tyRep -> object

    val getInt : object -> int
    val getReal : object -> real
    val getString : object -> string
    val getBool : object -> bool
    val isNull : object -> bool
    val car : object -> object
    val cdr : tyRep * object -> object
  end

*)
  structure Assert = SMLUnit.Assert
  structure Test = SMLUnit.Test
  open PolyDynamic
  val assertEqualJsonTy = Assert.assertEqual (op =) JSONTypes.jsonTyToString

  (* to be written soon *)
  val suite  = fn () => SMLUnit.Test.TestList nil 
end
