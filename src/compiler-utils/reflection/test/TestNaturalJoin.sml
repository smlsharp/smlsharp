(**
 * TestNaturalJoin
 * @author Tomohiro Sasaki
 * @copyright 2017-, Tohoku University.
 *)

structure TestNaturalJoin =
struct
  structure A = SMLUnit.Assert
  structure T = SMLUnit.Test
  structure R = ReifiedTerm
  structure N = NaturalJoin

  fun assertEqualReifiedTerm expected actual =
      A.assertEqualString
        (R.reifiedTermToString expected)
        (R.reifiedTermToString actual)

  fun naturalJoinTester expected (operand1, operand2) =
      assertEqualReifiedTerm
        expected
        (N.naturalJoin (operand1, operand2))

  fun naturalJoinFailTester (operand1, operand2) =
      (N.naturalJoin (operand1, operand2);
       A.fail ("Must raise NaturalJoin exception at naturalJoin(" ^ R.reifiedTermToString operand1 ^ ", " ^ R.reifiedTermToString operand2 ^ ")."))
      handle N.NaturalJoin => ()

  fun testNaturalJoin () =
      let
        val data =
            [
              fn () =>
                 naturalJoinTester
                   (R.BOOL true)
                   (R.BOOL true, R.BOOL true),
              fn () =>
                 naturalJoinTester
                   (R.BOOL false)
                   (R.BOOL false, R.BOOL false),
              fn () =>
                 naturalJoinFailTester
                   (R.BOOL false, R.BOOL true),
              fn () =>
                 naturalJoinFailTester
                   (R.BOOL true, R.BOOL false),
              fn () =>
                 naturalJoinTester
                   (R.CHAR #"A")
                   (R.CHAR #"A", R.CHAR #"A"),
              fn () =>
                 naturalJoinFailTester
                   (R.CHAR #"A", R.CHAR #"B"),
              fn () =>
                 naturalJoinTester
                   (R.INT 0xffff)
                   (R.INT 0xffff, R.INT 0xffff),
              fn () =>
                 naturalJoinFailTester
                   (R.INT 0xffff, R.INT ~0xffff),
              fn () =>
                 naturalJoinTester
                   (R.INT8 0xf)
                   (R.INT8 0xf, R.INT8 0xf),
              fn () =>
                 naturalJoinFailTester
                   (R.INT8 0xf, R.INT8 0xe),
              fn () =>
                 naturalJoinTester
                   (R.INT16 0xfff)
                   (R.INT16 0xfff, R.INT16 0xfff),
              fn () =>
                 naturalJoinFailTester
                   (R.INT16 0xfff, R.INT16 0xeee),
              fn () =>
                 naturalJoinTester
                   (R.INT64 0xffffffff)
                   (R.INT64 0xffffffff, R.INT64 0xffffffff),
              fn () =>
                 naturalJoinFailTester
                   (R.INT64 0xffffffff, R.INT64 0xfffffffe),
              fn () =>
                 naturalJoinTester
                   (R.PTR 0wxffff)
                   (R.PTR 0wxffff, R.PTR 0wxffff),
              fn () =>
                 naturalJoinFailTester
                   (R.PTR 0wxffff, R.PTR 0w0),
              fn () =>
                 naturalJoinTester
                   (R.REAL32 0.1)
                   (R.REAL32 0.1, R.REAL32 0.1),
              fn () =>
                 naturalJoinFailTester
                   (R.REAL32 0.1, R.REAL32 0.2),
              fn () =>
                 naturalJoinTester
                   (R.REAL 0.1)
                   (R.REAL 0.1, R.REAL 0.1),
              fn () =>
                 naturalJoinFailTester
                   (R.REAL 0.1, R.REAL 0.2),
              fn () =>
                 naturalJoinTester
                   (R.STRING "hoge")
                   (R.STRING "hoge", R.STRING "hoge"),
              fn () =>
                 naturalJoinFailTester
                   (R.STRING "hoge", R.STRING "fuga"),
              fn () =>
                 naturalJoinTester
                   R.UNIT
                   (R.UNIT, R.UNIT),
              fn () =>
                 naturalJoinTester
                   (R.WORD 0wxffff)
                   (R.WORD 0wxffff, R.WORD 0wxffff),
              fn () =>
                 naturalJoinFailTester
                   (R.WORD 0wxffff, R.WORD 0wxfffe),
              fn () =>
                 naturalJoinTester
                   (R.WORD8 0wxff)
                   (R.WORD8 0wxff, R.WORD8 0wxff),
              fn () =>
                 naturalJoinFailTester
                   (R.WORD 0wxff, R.WORD 0wxfe),
              fn () =>
                 naturalJoinTester
                   (R.WORD16 0wxffff)
                   (R.WORD16 0wxffff, R.WORD16 0wxffff),
              fn () =>
                 naturalJoinFailTester
                   (R.WORD16 0wxffff, R.WORD16 0wxfffe),
              fn () =>
                 naturalJoinTester
                   (R.WORD64 0wxffffffffffff)
                   (R.WORD64 0wxffffffffffff, R.WORD64 0wxffffffffffff),
              fn () =>
                 naturalJoinFailTester
                   (R.WORD64 0wxffffffffffff, R.WORD64 0wxeeeeeeeeeeee),
              fn () =>
                 naturalJoinTester
                   (R.RECORD [("a", R.INT 1),
                              ("b", R.STRING "hoge"),
                              ("c", R.REAL 1.1),
                              ("d", R.RECORD [("da", R.INT64 11),
                                              ("db", R.STRING "foo"),
                                              ("dc", R.REAL32 2.2)])])
                   (R.RECORD [("a", R.INT 1),
                              ("b", R.STRING "hoge"),
                              ("d", R.RECORD [("da", R.INT64 11),
                                              ("db", R.STRING "foo")])],
                    R.RECORD [("b", R.STRING "hoge"),
                              ("c", R.REAL 1.1),
                              ("d", R.RECORD [("db", R.STRING "foo"),
                                              ("dc", R.REAL32 2.2)])]),
              fn () =>
                 naturalJoinFailTester
                   (R.RECORD [("a", R.INT 1),
                              ("b", R.STRING "hoge")],
                    R.RECORD [("b", R.STRING "foo"),
                              ("c", R.REAL 1.1)]),
              fn () =>
                 naturalJoinFailTester
                   (R.RECORD [("a", R.INT 1),
                              ("b", R.STRING "hoge"),
                              ("d", R.RECORD [("da", R.INT64 11),
                                              ("db", R.STRING "foo")])],
                    R.RECORD [("b", R.STRING "hoge"),
                              ("c", R.REAL 1.1),
                              ("d", R.RECORD [("db", R.STRING "piyo"),
                                              ("dc", R.REAL32 2.2)])]),
              fn () =>
                 naturalJoinTester
                   (R.TUPLE [R.INT 1, R.STRING "hoge", R.REAL 1.1, 
                             R.RECORD [("a", R.INT 2), 
                                       ("b", R.STRING "foo"), 
                                       ("c", R.REAL 2.2)]])
                   (R.TUPLE [R.INT 1, R.STRING "hoge", R.REAL 1.1,
                             R.RECORD [("a", R.INT 2),
                                       ("b", R.STRING "foo")]],
                    R.TUPLE [R.INT 1, R.STRING "hoge", R.REAL 1.1,
                             R.RECORD [("b", R.STRING "foo"),
                                       ("c", R.REAL 2.2)]]),
              fn () =>
                 naturalJoinFailTester
                   (R.TUPLE [R.INT 1, R.STRING "hoge"],
                    R.TUPLE [R.INT 1, R.STRING "foo"]),
              fn () =>
                 naturalJoinTester
                   (R.OPTION (SOME (R.RECORD [("a", R.INT 1), 
                                              ("b", R.STRING "hoge"), 
                                              ("c", R.REAL 1.1)])))
                   (R.OPTION (SOME (R.RECORD [("a", R.INT 1),
                                              ("b", R.STRING "hoge")])),
                    R.OPTION (SOME (R.RECORD [("b", R.STRING "hoge"),
                                              ("c", R.REAL 1.1)]))),
              fn () =>
                 naturalJoinFailTester
                   (R.OPTION (SOME (R.RECORD [("a", R.INT 1),
                                              ("b", R.STRING "hoge")])),
                    R.OPTION (SOME (R.RECORD [("b", R.STRING "foo"),
                                              ("c", R.REAL 1.1)]))),
              fn () =>
                 naturalJoinTester
                   (R.OPTION (SOME (R.STRING "hoge")))
                   (R.OPTION (SOME (R.STRING "hoge")),
                    R.OPTION NONE),
              fn () =>
                 naturalJoinTester
                   (R.OPTION (SOME (R.STRING "hoge")))
                   (R.OPTION NONE,
                    R.OPTION (SOME (R.STRING "hoge"))),
              fn () =>
                 naturalJoinTester
                   (R.OPTION NONE)
                   (R.OPTION NONE, R.OPTION NONE),
              fn () =>
                 naturalJoinTester
                   (R.OPTIONSOME (R.RECORD [("a", R.INT 1), 
                                            ("b", R.STRING "hoge"), 
                                            ("c", R.REAL 1.1)]))
                   (R.OPTIONSOME (R.RECORD [("a", R.INT 1),
                                            ("b", R.STRING "hoge")]),
                    R.OPTIONSOME (R.RECORD [("b", R.STRING "hoge"),
                                            ("c", R.REAL 1.1)])),
              fn () =>
                 naturalJoinFailTester
                   (R.OPTIONSOME (R.RECORD [("a", R.INT 1),
                                            ("b", R.STRING "hoge")]),
                    R.OPTIONSOME (R.RECORD [("b", R.STRING "foo"),
                                            ("c", R.REAL 1.1)])),
              fn () =>
                 naturalJoinTester
                   (R.OPTIONSOME (R.STRING "hoge"))
                   (R.OPTIONSOME (R.STRING "hoge"),
                    R.OPTIONNONE),
              fn () =>
                 naturalJoinTester
                   (R.OPTIONSOME (R.STRING "hoge"))
                   (R.OPTIONNONE,
                    R.OPTIONSOME (R.STRING "hoge")),
              fn () =>
                 naturalJoinTester
                   (R.OPTIONNONE)
                   (R.OPTIONNONE, R.OPTIONNONE),
              fn () =>
                 naturalJoinTester
                   (R.LIST [R.RECORD [("id", R.INT 1),
                                      ("name", R.STRING "Taro"),
                                      ("salary", R.INT 450)],
                            R.RECORD [("id", R.INT 2),
                                      ("name", R.STRING "Hanako"),
                                      ("salary", R.INT 500)]])
                   (R.LIST [R.RECORD [("id", R.INT 1),
                                      ("name", R.STRING "Taro")],
                            R.RECORD [("id", R.INT 2),
                                      ("name", R.STRING "Hanako")],
                            R.RECORD [("id", R.INT 3),
                                      ("name", R.STRING "Ichiro")]],
                    R.LIST [R.RECORD [("id", R.INT 1),
                                      ("salary", R.INT 450)],
                            R.RECORD [("id", R.INT 2),
                                      ("salary", R.INT 500)],
                            R.RECORD [("id", R.INT 4),
                                      ("salary", R.INT 700)]]),
              fn () =>
                 naturalJoinTester
                   (R.ARRAY2 (Array.fromList 
                                [R.RECORD [("id", R.INT 1),
                                           ("name", R.STRING "Taro"),
                                           ("salary", R.INT 450)],
                                 R.RECORD [("id", R.INT 2),
                                           ("name", R.STRING "Hanako"),
                                           ("salary", R.INT 500)]]))
                   (R.ARRAY2 (Array.fromList 
                                [R.RECORD [("id", R.INT 1),
                                           ("name", R.STRING "Taro")],
                                 R.RECORD [("id", R.INT 2),
                                           ("name", R.STRING "Hanako")],
                                 R.RECORD [("id", R.INT 3),
                                           ("name", R.STRING "Ichiro")]]),
                    R.ARRAY2 (Array.fromList
                                [R.RECORD [("id", R.INT 1),
                                           ("salary", R.INT 450)],
                                 R.RECORD [("id", R.INT 2),
                                           ("salary", R.INT 500)],
                                 R.RECORD [("id", R.INT 4),
                                           ("salary", R.INT 700)]])),
              fn () =>
                 naturalJoinTester
                   (R.VECTOR2 (Vector.fromList
                                 [R.RECORD [("id", R.INT 1),
                                            ("name", R.STRING "Taro"),
                                            ("salary", R.INT 450)],
                                  R.RECORD [("id", R.INT 2),
                                            ("name", R.STRING "Hanako"),
                                            ("salary", R.INT 500)]]))
                   (R.VECTOR2 (Vector.fromList
                                 [R.RECORD [("id", R.INT 1),
                                            ("name", R.STRING "Taro")],
                                  R.RECORD [("id", R.INT 2),
                                            ("name", R.STRING "Hanako")],
                                  R.RECORD [("id", R.INT 3),
                                            ("name", R.STRING "Ichiro")]]),
                    R.VECTOR2 (Vector.fromList
                                 [R.RECORD [("id", R.INT 1),
                                            ("salary", R.INT 450)],
                                  R.RECORD [("id", R.INT 2),
                                            ("salary", R.INT 500)],
                                  R.RECORD [("id", R.INT 4),
                                            ("salary", R.INT 700)]])),
              fn () => 
                 naturalJoinTester
                   (R.DATATYPE ("A", NONE))
                   (R.DATATYPE ("A", NONE), R.DATATYPE ("A", NONE)),
              fn () =>
                 naturalJoinTester
                   (R.DATATYPE ("A", SOME (R.INT 1)))
                   (R.DATATYPE ("A", SOME (R.INT 1)),
                    R.DATATYPE ("A", SOME (R.INT 1))),
              fn () =>
                 naturalJoinTester
                   (R.DATATYPE ("A", SOME (R.RECORD [("a", R.INT 1),
                                                     ("b", R.STRING "hoge"),
                                                     ("c", R.REAL 1.1)])))
                   (R.DATATYPE ("A", SOME (R.RECORD [("a", R.INT 1),
                                                     ("b", R.STRING "hoge")])),
                    R.DATATYPE ("A", SOME (R.RECORD [("b", R.STRING "hoge"),
                                                     ("c", R.REAL 1.1)]))),
              fn () =>
                 naturalJoinFailTester
                   (R.DATATYPE ("A", NONE), R.DATATYPE ("B", NONE)),
              fn () =>
                 naturalJoinFailTester
                   (R.DATATYPE ("A", SOME (R.INT 1)), 
                    R.DATATYPE ("A", SOME (R.INT 2))),
              fn () =>
                 naturalJoinFailTester
                   (R.DATATYPE ("A", SOME (R.INT 1)), 
                    R.DATATYPE ("B", SOME (R.INT 1)))
            ]
      in
        T.TestList (List.map T.TestCase data)
      end

  fun suite () =
      T.TestList
        [
          T.TestLabel ("testNaturalJoin", testNaturalJoin ())
        ]
end
(*
val _ =
    SMLUnit.TextUITestRunner.runTest
    {output = TextIO.stdOut}
    (SMLUnit.Test.TestList
       [
        TestNaturalJoin.suite ()
        ]
    )

*)
