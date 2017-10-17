(**
 * TestReifiedTermToML
 * @author Tomohiro Sasaki
 * @copyright 2017-, Tohoku University.
 *)
structure TestReifiedTermToML =
struct
  structure A = SMLUnit.Assert
  structure T = SMLUnit.Test
  structure R2M = ReifiedTermToML
  structure R = ReifiedTerm
  structure RT = ReifyTerm

  fun testReifiedTermToML () =
      let
        val data =
            [
              fn () => 
                 A.assertEqualBool true (R2M.reifiedTermToML (R.BOOL true)),
              fn () => 
                 A.assertEqualBool false (R2M.reifiedTermToML (R.BOOL false)),
              fn () =>
                 A.assertEqualChar #"A" (R2M.reifiedTermToML (R.CHAR #"A")),
              fn () =>
                 (A.assertEqual (op =) Int8.toString)
                   0xe
                   (R2M.reifiedTermToML (R.INT8 0xe)),
              fn () => 
                 (A.assertEqual (op =) Int16.toString)
                   0xef
                   (R2M.reifiedTermToML (R.INT16 0xef)),
              fn () => 
                 (A.assertEqual (op =) Int64.toString)
                   0xffffffffffff
                   (R2M.reifiedTermToML (R.INT64 0xffffffffffff)),
              fn () => 
                 (A.assertEqual (op =) IntInf.toString)
                   0xffffffffffffffffff
                   (R2M.reifiedTermToML (R.INTINF 0xffffffffffffffffff)),
              fn () =>
                 A.assertEqualInt 1 (R2M.reifiedTermToML (R.INT 1)),
              fn () => 
                 (A.assertEqual (Real32.==) Real32.toString)
                   0.1
                   (R2M.reifiedTermToML (R.REAL32 0.1)),
              fn () => 
                 A.assertEqualReal 0.1 (R2M.reifiedTermToML (R.REAL 0.1)),
              fn () => 
                 A.assertEqualString "hoge" (R2M.reifiedTermToML (R.STRING "hoge")),
              fn () =>
                 A.assertEqualUnit () (R2M.reifiedTermToML R.UNIT),
              fn () => 
                 (A.assertEqual (op =) Word64.toString)
                   0wxffffffffffff
                   (R2M.reifiedTermToML (R.WORD64 0wxffffffffffff)),
              fn () => 
                 A.assertEqualWord8
                   0wxa
                   (R2M.reifiedTermToML (R.WORD8 0wxa)),
              fn () =>
                 (A.assertEqual (op =) Word16.toString)
                   0wxff
                   (R2M.reifiedTermToML (R.WORD16 0wxff)),
              fn () => 
                 A.assertEqualWord
                   0wxfffffff 
                   (R2M.reifiedTermToML (R.WORD 0wxfffffff)),
              fn () =>
                 (A.assertEqualArray A.assertEqualInt)
                   (Array.fromList [1,2,3]) 
                   (R2M.reifiedTermToML 
                      (R.ARRAY2 (Array.fromList [R.INT 1, R.INT 2, R.INT 3]))),
              fn () =>
                 (A.assertEqualArray A.assertEqualString)
                   (Array.fromList ["hoge", "fuga", "foo"])
                   (R2M.reifiedTermToML
                      (R.ARRAY2 (Array.fromList [R.STRING "hoge", R.STRING "fuga", R.STRING "foo"]))),
              fn () =>
                 A.assertEqualIntList
                   [1,2,3]
                   (R2M.reifiedTermToML (R.LIST [R.INT 1, R.INT 2, R.INT 3])),
              fn () =>
                 A.assertEqualStringList
                   ["hoge", "fuga", "foo"]
                   (R2M.reifiedTermToML (R.LIST [R.STRING "hoge", R.STRING "fuga", R.STRING "foo"])),
              fn () =>
                 A.assertEqualIntOption 
                   (SOME 1)
                   (R2M.reifiedTermToML (R.OPTION (SOME (R.INT 1)))),
              fn () =>
                 A.assertEqualIntOption
                   NONE
                   (R2M.reifiedTermToML (R.OPTION NONE)),
              fn () =>
                 A.assertEqualStringOption
                   (SOME "hoge")
                   (R2M.reifiedTermToML (R.OPTION (SOME (R.STRING "hoge")))),
              fn () =>
                 A.assertEqualStringOption
                   NONE
                   (R2M.reifiedTermToML (R.OPTION NONE)),
              fn () =>
                 (A.assertEqual 
                    (op =) 
                    (fn _ => "(boxed) : {a : int, b : string, c : {ca : bool, cb : word}}"))
                     {a = 1, b = "hoge", c = {ca = true, cb = 0w1}}
                     (R2M.reifiedTermToML
                        (R.RECORD [("a", R.INT 1),
                                   ("b", R.STRING "hoge"),
                                   ("c", R.RECORD [("ca", R.BOOL true),
                                                   ("cb", R.WORD 0w1)])])),
              fn () => 
                 (A.assertEqualRef A.assertEqualInt)
                   (ref 1)
                   (R2M.reifiedTermToML (R.REF (R.INT 1))),
              fn () => 
                 (A.assertEqualRef A.assertEqualString)
                   (ref "hoge")
                   (R2M.reifiedTermToML (R.REF (R.STRING "hoge"))),
              fn () => 
                 (A.assertEqual3Tuple 
                    (A.assertEqualInt, 
                     A.assertEqualString, 
                     A.assertEqualWord))
                     (1, "hoge", 0w1)
                     (R2M.reifiedTermToML 
                        (R.TUPLE [R.INT 1, R.STRING "hoge", R.WORD 0w1])),
              fn () =>
                 (A.assertEqualVector A.assertEqualInt)
                   (Vector.fromList [1,2,3])
                   (R2M.reifiedTermToML 
                      (R.VECTOR2 (Vector.fromList [R.INT 1, R.INT 2, R.INT 3]))),
              fn () =>
                 (A.assertEqualVector A.assertEqualString)
                   (Vector.fromList ["hoge", "fuga", "foo"])
                   (R2M.reifiedTermToML 
                      (R.VECTOR2 (Vector.fromList [R.STRING "hoge", R.STRING "fuga", R.STRING "foo"])))
            ]
      in
        T.TestList (List.map T.TestCase data)
      end

  fun testMLToReifiedTermToML () =
      let
        datatype 'a layout_tagged_tagged_record =
                 A of int * int
               | B of bool
               | C of 'a
               | D
               | E
        datatype 'a layout_tagged_tagged_or_null =
                 F of int * int
               | G of bool 
               | H of 'a
               | I 
        datatype layout_arg_or_null_wrap_false =
                 J of int * layout_arg_or_null_wrap_false
               | K
        datatype layout_arg_or_null_wrap_true_1 =
                 L of int
               | M
        datatype 'a layout_arg_or_null_wrap_true_2 =
                 N of 'a
               | O
        datatype layout_arg_or_null_wrap_true_3 =
                 P of layout_arg_or_null_wrap_true_4
               | Q
             and layout_arg_or_null_wrap_true_4 =
                 R of layout_arg_or_null_wrap_true_3
               | S
        datatype layout_single_arg_wrap_false =
                 T of int * int
        datatype 'a layout_single_arg_wrap_true_1 =
                 U of 'a
        datatype layout_single_arg_wrap_true_2 =
                 V of int
        datatype layout_tagged_tagged_only =
                 W | X | Y
        datatype layout_choice =
                 AA | BB
        datatype layout_single =
                 CC
        val data =
            [
              fn () =>
                 (A.assertEqual (op =) (fn _ => "LAYOUT_TAGGED (TAGGED_RECORD) A"))
                   (A (1, 2))
                   ((R2M.reifiedTermToML (RT.toReifiedTerm (A (1, 2)))) : int layout_tagged_tagged_record),
              fn () =>
                 (A.assertEqual (op =) (fn _ => "LAYOUT_TAGGED (TAGGED_RECORD) B"))
                   (B true)
                   ((R2M.reifiedTermToML (RT.toReifiedTerm (B true))) : int layout_tagged_tagged_record),
              fn () =>
                 (A.assertEqual (op =) (fn _ => "LAYOUT_TAGGED (TAGGED_RECORD) C"))
                   (C "hoge")
                   (R2M.reifiedTermToML (RT.toReifiedTerm (C "hoge"))),
              fn () =>
                 (A.assertEqual (op =) (fn _ => "LAYOUT_TAGGED (TAGGED_RECORD) D"))
                   D
                   ((R2M.reifiedTermToML (RT.toReifiedTerm D)) : int layout_tagged_tagged_record),
              fn () =>
                 (A.assertEqual (op =) (fn _ => "LAYOUT_TAGGED (TAGGED_RECORD) E"))
                   E
                   ((R2M.reifiedTermToML (RT.toReifiedTerm E)) : int layout_tagged_tagged_record),
              fn () =>
                 (A.assertEqual (op =) (fn _ => "LAYOUT_TAGGED (TAGGED_OR_NULL) F"))
                   (F (1, 2))
                   ((R2M.reifiedTermToML (RT.toReifiedTerm (F (1, 2)))) : int layout_tagged_tagged_or_null),
              fn () =>
                 (A.assertEqual (op =) (fn _ => "LAYOUT_TAGGED (TAGGED_OR_NULL) G"))
                   (G true)
                   ((R2M.reifiedTermToML (RT.toReifiedTerm (G true))) : int layout_tagged_tagged_or_null),
              fn () =>
                 (A.assertEqual (op =) (fn _ => "LAYOUT_TAGGED (TAGGED_OR_NULL) H"))
                   (H "hoge")
                   (R2M.reifiedTermToML (RT.toReifiedTerm (H "hoge"))),
              fn () =>
                 (A.assertEqual (op =) (fn _ => "LAYOUT_TAGGED (TAGGED_OR_NULL) I"))
                   I
                   ((R2M.reifiedTermToML (RT.toReifiedTerm I)) : int layout_tagged_tagged_or_null),
              fn () =>
                 (A.assertEqual (op =) (fn _ => "LAYOUT_ARG_OR_NULL ({wrap=false}) J"))
                   K
                   (R2M.reifiedTermToML (RT.toReifiedTerm K)),
              fn () =>
                 (A.assertEqual (op =) (fn _ => "LAYOUT_ARG_OR_NULL ({wrap=false}) J"))
                   (J (1, K))
                   (R2M.reifiedTermToML (RT.toReifiedTerm (J (1, K)))),
              fn () =>
                 (A.assertEqual (op =) (fn _ => "LAYOUT_ARG_OR_NULL ({wrap=true}) L"))
                   (L 1)
                   (R2M.reifiedTermToML (RT.toReifiedTerm (L 1))),
              fn () =>
                 (A.assertEqual (op =) (fn _ => "LAYOUT_ARG_OR_NULL ({wrap=true}) M"))
                   M
                   (R2M.reifiedTermToML (RT.toReifiedTerm M)),
              fn () =>
                 (A.assertEqual (op =) (fn _ => "LAYOUT_ARG_OR_NULL ({wrap=true}) N"))
                   (N 1)
                   (R2M.reifiedTermToML (RT.toReifiedTerm (N 1))),
              fn () =>
                 (A.assertEqual (op =) (fn _ => "LAYOUT_ARG_OR_NULL ({wrap=true}) O"))
                   O
                   (R2M.reifiedTermToML (RT.toReifiedTerm O)),
              fn () =>
                 (A.assertEqual (op =) (fn _ => "LAYOUT_ARG_OR_NULL ({wrap=true}) P"))
                   (P S)
                   (R2M.reifiedTermToML (RT.toReifiedTerm (P S))),
              fn () =>
                 (A.assertEqual (op =) (fn _ => "LAYOUT_ARG_OR_NULL ({wrap=true}) Q"))
                   Q
                   (R2M.reifiedTermToML (RT.toReifiedTerm Q)),
              fn () =>
                 (A.assertEqual (op =) (fn _ => "LAYOUT_ARG_OR_NULL ({wrap=true}) R"))
                   (R Q)
                   (R2M.reifiedTermToML (RT.toReifiedTerm (R Q))),
              fn () =>
                 (A.assertEqual (op =) (fn _ => "LAYOUT_ARG_OR_NULL ({wrap=true}) S"))
                   S
                   (R2M.reifiedTermToML (RT.toReifiedTerm S)),
              fn () =>
                 (A.assertEqual (op =) (fn _ => "LAYOUT_SINGLE_ARG ({wrap=false}) T"))
                   (T (1, 2))
                   (R2M.reifiedTermToML (RT.toReifiedTerm (T (1, 2)))),
              fn () =>
                 (A.assertEqual (op =) (fn _ => "LAYOUT_SINGLE_ARG ({wrap=true}) U"))
                   (U "hoge")
                   (R2M.reifiedTermToML (RT.toReifiedTerm (U "hoge"))),
              fn () =>
                 (A.assertEqual (op =) (fn _ => "LAYOUT_SINGLE_ARG ({wrap=true}) V"))
                   (V 1)
                   (R2M.reifiedTermToML (RT.toReifiedTerm (V 1))),
              fn () =>
                 (A.assertEqual (op =) (fn _ => "LAYOUT_TAGGED (TAGGED_ONLY) W"))
                   W
                   (R2M.reifiedTermToML (RT.toReifiedTerm W)),
              fn () =>
                 (A.assertEqual (op =) (fn _ => "LAYOUT_TAGGED (TAGGED_ONLY) X"))
                   X
                   (R2M.reifiedTermToML (RT.toReifiedTerm X)),
              fn () =>
                 (A.assertEqual (op =) (fn _ => "LAYOUT_TAGGED (TAGGED_ONLY) Y"))
                   Y
                   (R2M.reifiedTermToML (RT.toReifiedTerm Y)),
              fn () => 
                 (A.assertEqual (op =) (fn _ => "LAYOUT_CHOICE AA"))
                   AA
                   (R2M.reifiedTermToML (RT.toReifiedTerm AA)),
              fn () => 
                 (A.assertEqual (op =) (fn _ => "LAYOUT_CHOICE BB"))
                   BB
                   (R2M.reifiedTermToML (RT.toReifiedTerm BB)),
              fn () => 
                 (A.assertEqual (op =) (fn _ => "LAYOUT_SINGLE CC"))
                   CC
                   (R2M.reifiedTermToML (RT.toReifiedTerm CC))
            ]
      in
        T.TestList (List.map T.TestCase data)
      end

  fun suite () =
      T.TestList
        [

          T.TestLabel ("testReifiedTermToML", testReifiedTermToML ()),
          T.TestLabel ("testMLToReifiedTermToML", testMLToReifiedTermToML ())
        ]
end
(*
val _ =
    SMLUnit.TextUITestRunner.runTest
    {output = TextIO.stdOut}
    (SMLUnit.Test.TestList
       [
        TestReifiedTermToML.suite ()
        ]
    )
*)
