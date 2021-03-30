(**
 * TestNaturalJoin
 * @author Tomohiro Sasaki
 * @copyright (C) 2021 SML# Development Team.
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
       A.fail ("Must raise NaturalJoin exception at naturalJoin("
               ^ R.reifiedTermToString operand1 ^ ", "
               ^ R.reifiedTermToString operand2 ^ ")."))
      handle N.NaturalJoin => ()

  val tests =
      T.TestList [
        T.Test
          ("true",
           fn () =>
              naturalJoinTester
                (R.BOOL true)
                (R.BOOL true, R.BOOL true)),
        T.Test
          ("false",
           fn () =>
              naturalJoinTester
                (R.BOOL false)
                (R.BOOL false, R.BOOL false)),
        T.Test
          ("false fail",
           fn () =>
              naturalJoinFailTester
                (R.BOOL false, R.BOOL true)),
        T.Test
          ("true fail",
           fn () =>
              naturalJoinFailTester
                (R.BOOL true, R.BOOL false)),
        T.Test
          ("char",
           fn () =>
              naturalJoinTester
                (R.CHAR #"A")
                (R.CHAR #"A", R.CHAR #"A")),
        T.Test
          ("char fail",
           fn () =>
              naturalJoinFailTester
                (R.CHAR #"A", R.CHAR #"B")),
        T.Test
          ("int",
           fn () =>
              naturalJoinTester
                (R.INT 0xffff)
                (R.INT 0xffff, R.INT 0xffff)),
        T.Test
          ("int fail",
           fn () =>
              naturalJoinFailTester
                (R.INT 0xffff, R.INT ~0xffff)),
        T.Test
          ("int8",
           fn () =>
              naturalJoinTester
                (R.INT8 0xf)
                (R.INT8 0xf, R.INT8 0xf)),
        T.Test
          ("int8 fail",
           fn () =>
              naturalJoinFailTester
                (R.INT8 0xf, R.INT8 0xe)),
        T.Test
          ("int16",
           fn () =>
              naturalJoinTester
                (R.INT16 0xfff)
                (R.INT16 0xfff, R.INT16 0xfff)),
        T.Test
          ("int16 fail",
           fn () =>
              naturalJoinFailTester
                (R.INT16 0xfff, R.INT16 0xeee)),
        T.Test
          ("int64",
           fn () =>
              naturalJoinTester
                (R.INT64 0xffffffff)
                (R.INT64 0xffffffff, R.INT64 0xffffffff)),
        T.Test
          ("int64 fail",
           fn () =>
              naturalJoinFailTester
                (R.INT64 0xffffffff, R.INT64 0xfffffffe)),
        T.Test
          ("ptr",
           fn () =>
              naturalJoinTester
                (R.PTR 0wxffff)
                (R.PTR 0wxffff, R.PTR 0wxffff)),
        T.Test
          ("ptr fail",
           fn () =>
              naturalJoinFailTester
                (R.PTR 0wxffff, R.PTR 0w0)),
        T.Test
          ("real32",
           fn () =>
              naturalJoinTester
                (R.REAL32 0.1)
                (R.REAL32 0.1, R.REAL32 0.1)),
        T.Test
          ("real32 fail",
           fn () =>
              naturalJoinFailTester
                (R.REAL32 0.1, R.REAL32 0.2)),
        T.Test
          ("real",
           fn () =>
              naturalJoinTester
                (R.REAL 0.1)
                (R.REAL 0.1, R.REAL 0.1)),
        T.Test
          ("real fail",
           fn () =>
              naturalJoinFailTester
                (R.REAL 0.1, R.REAL 0.2)),
        T.Test
          ("string",
           fn () =>
              naturalJoinTester
                (R.STRING "hoge")
                (R.STRING "hoge", R.STRING "hoge")),
        T.Test
          ("string fail",
           fn () =>
              naturalJoinFailTester
                (R.STRING "hoge", R.STRING "fuga")),
        T.Test
          ("unit",
           fn () =>
              naturalJoinTester
                R.UNIT
                (R.UNIT, R.UNIT)),
        T.Test
          ("word",
           fn () =>
              naturalJoinTester
                (R.WORD 0wxffff)
                (R.WORD 0wxffff, R.WORD 0wxffff)),
        T.Test
          ("word fail",
           fn () =>
              naturalJoinFailTester
                (R.WORD 0wxffff, R.WORD 0wxfffe)),
        T.Test
          ("word8",
           fn () =>
              naturalJoinTester
                (R.WORD8 0wxff)
                (R.WORD8 0wxff, R.WORD8 0wxff)),
        T.Test
          ("word8 fail",
           fn () =>
              naturalJoinFailTester
                (R.WORD 0wxff, R.WORD 0wxfe)),
        T.Test
          ("word16",
           fn () =>
              naturalJoinTester
                (R.WORD16 0wxffff)
                (R.WORD16 0wxffff, R.WORD16 0wxffff)),
        T.Test
          ("word16 fail",
           fn () =>
              naturalJoinFailTester
                (R.WORD16 0wxffff, R.WORD16 0wxfffe)),
        T.Test
          ("word64",
           fn () =>
              naturalJoinTester
                (R.WORD64 0wxffffffffffff)
                (R.WORD64 0wxffffffffffff, R.WORD64 0wxffffffffffff)),
        T.Test
          ("word64 fail",
           fn () =>
              naturalJoinFailTester
                (R.WORD64 0wxffffffffffff, R.WORD64 0wxeeeeeeeeeeee)),
        T.Test
          ("record",
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
                                           ("dc", R.REAL32 2.2)])])),
        T.Test
          ("record fail",
           fn () =>
              naturalJoinFailTester
                (R.RECORD [("a", R.INT 1),
                           ("b", R.STRING "hoge")],
                 R.RECORD [("b", R.STRING "foo"),
                           ("c", R.REAL 1.1)])),
        T.Test
          ("nested record fail",
           fn () =>
              naturalJoinFailTester
                (R.RECORD [("a", R.INT 1),
                           ("b", R.STRING "hoge"),
                           ("d", R.RECORD [("da", R.INT64 11),
                                           ("db", R.STRING "foo")])],
                 R.RECORD [("b", R.STRING "hoge"),
                           ("c", R.REAL 1.1),
                           ("d", R.RECORD [("db", R.STRING "piyo"),
                                           ("dc", R.REAL32 2.2)])])),
        T.Test
          ("tuple",
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
                                    ("c", R.REAL 2.2)]])),
        T.Test
          ("tuple fail",
           fn () =>
              naturalJoinFailTester
                (R.TUPLE [R.INT 1, R.STRING "hoge"],
                 R.TUPLE [R.INT 1, R.STRING "foo"])),
        T.Test
          ("record option",
           fn () =>
              naturalJoinTester
                (R.OPTION (SOME (R.RECORD [("a", R.INT 1),
                                           ("b", R.STRING "hoge"),
                                           ("c", R.REAL 1.1)])))
                (R.OPTION (SOME (R.RECORD [("a", R.INT 1),
                                           ("b", R.STRING "hoge")])),
                 R.OPTION (SOME (R.RECORD [("b", R.STRING "hoge"),
                                           ("c", R.REAL 1.1)])))),
        T.Test
          ("record option fail",
           fn () =>
              naturalJoinFailTester
                (R.OPTION (SOME (R.RECORD [("a", R.INT 1),
                                           ("b", R.STRING "hoge")])),
                 R.OPTION (SOME (R.RECORD [("b", R.STRING "foo"),
                                           ("c", R.REAL 1.1)])))),
        T.Test
          ("string option some",
           fn () =>
              naturalJoinTester
                (R.OPTION (SOME (R.STRING "hoge")))
                (R.OPTION (SOME (R.STRING "hoge")),
                 R.OPTION NONE)),
        T.Test
          ("string option none",
           fn () =>
              naturalJoinTester
                (R.OPTION (SOME (R.STRING "hoge")))
                (R.OPTION NONE,
                 R.OPTION (SOME (R.STRING "hoge")))),
        T.Test
          ("none",
           fn () =>
              naturalJoinTester
                (R.OPTION NONE)
                (R.OPTION NONE, R.OPTION NONE)),
        T.Test
          ("record optionsome",
           fn () =>
              naturalJoinTester
                (R.OPTIONSOME (R.RECORD [("a", R.INT 1),
                                         ("b", R.STRING "hoge"),
                                         ("c", R.REAL 1.1)]))
                (R.OPTIONSOME (R.RECORD [("a", R.INT 1),
                                         ("b", R.STRING "hoge")]),
                 R.OPTIONSOME (R.RECORD [("b", R.STRING "hoge"),
                                         ("c", R.REAL 1.1)]))),
        T.Test
          ("record optionsome fail",
           fn () =>
              naturalJoinFailTester
                (R.OPTIONSOME (R.RECORD [("a", R.INT 1),
                                         ("b", R.STRING "hoge")]),
                 R.OPTIONSOME (R.RECORD [("b", R.STRING "foo"),
                                         ("c", R.REAL 1.1)]))),
        T.Test
          ("string optionsome",
           fn () =>
              naturalJoinTester
                (R.OPTIONSOME (R.STRING "hoge"))
                (R.OPTIONSOME (R.STRING "hoge"),
                 R.OPTIONNONE)),
        T.Test
          ("string optionnone",
           fn () =>
              naturalJoinTester
                (R.OPTIONSOME (R.STRING "hoge"))
                (R.OPTIONNONE,
                 R.OPTIONSOME (R.STRING "hoge"))),
        T.Test
          ("optionnone",
           fn () =>
              naturalJoinTester
                (R.OPTIONNONE)
                (R.OPTIONNONE, R.OPTIONNONE)),
        T.Test
          ("list",
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
                                   ("salary", R.INT 700)]])),
        T.Test
          ("array",
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
                                        ("salary", R.INT 700)]]))),
        T.Test
          ("vector",
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
                                         ("salary", R.INT 700)]]))),
        T.Test
          ("datatype",
           fn () =>
              naturalJoinTester
                (R.DATATYPE ("A", NONE))
                (R.DATATYPE ("A", NONE), R.DATATYPE ("A", NONE))),
        T.Test
          ("datatype with arg",
           fn () =>
              naturalJoinTester
                (R.DATATYPE ("A", SOME (R.INT 1)))
                (R.DATATYPE ("A", SOME (R.INT 1)),
                 R.DATATYPE ("A", SOME (R.INT 1)))),
        T.Test
          ("datatype with record",
           fn () =>
              naturalJoinTester
                (R.DATATYPE ("A", SOME (R.RECORD [("a", R.INT 1),
                                                  ("b", R.STRING "hoge"),
                                                  ("c", R.REAL 1.1)])))
                (R.DATATYPE ("A", SOME (R.RECORD [("a", R.INT 1),
                                                  ("b", R.STRING "hoge")])),
                 R.DATATYPE ("A", SOME (R.RECORD [("b", R.STRING "hoge"),
                                                  ("c", R.REAL 1.1)])))),
        T.Test
          ("datatype fail",
           fn () =>
              naturalJoinFailTester
                (R.DATATYPE ("A", NONE), R.DATATYPE ("B", NONE))),
        T.Test
          ("datatype arg fail",
           fn () =>
              naturalJoinFailTester
                (R.DATATYPE ("A", SOME (R.INT 1)),
                 R.DATATYPE ("A", SOME (R.INT 2)))),
        T.Test
          ("datatype conname fail",
           fn () =>
              naturalJoinFailTester
                (R.DATATYPE ("A", SOME (R.INT 1)),
                 R.DATATYPE ("B", SOME (R.INT 1))))
      ] (* end of TestList *)

end
