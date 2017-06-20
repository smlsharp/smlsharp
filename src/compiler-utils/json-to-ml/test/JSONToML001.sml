structure JSONToML001 =
struct
  structure A = SMLUnit.Assert
  structure T = SMLUnit.Test
  structure J = JSON
  structure J2M = JSONToML

  fun testJsonToML () =
      let
        val data =
            [
             fn () => 
                A.assertEqualInt 1 (J2M.jsonToML (J.INT 1, J.INTty)),
             fn () => 
                A.assertEqualBool true (J2M.jsonToML (J.BOOL true, J.BOOLty)),
             fn () => 
                A.assertEqualBool false (J2M.jsonToML (J.BOOL false, J.BOOLty)),
             fn () => 
                A.assertEqualReal 3.14 (J2M.jsonToML (J.REAL 3.14, J.REALty)),
             fn () => 
                A.assertEqualString 
                  "SML#" 
                  (J2M.jsonToML (J.STRING "SML#", J.STRINGty)),
             fn () =>
                A.assertEqualIntList
                  [1,2,3]
                  (J2M.jsonToML (J.ARRAY ([J.INT 1, 
                                           J.INT 2, 
                                           J.INT 3], 
                                          J.INTty),
                                 J.ARRAYty J.INTty)),
             fn () =>
                (A.assertEqualList A.assertEqualBool)
                  [true, false, true]
                  (J2M.jsonToML (J.ARRAY ([J.BOOL true, 
                                           J.BOOL false, 
                                           J.BOOL true], 
                                          J.BOOLty),
                                 J.ARRAYty J.BOOLty)),
             fn () =>
                A.assertEqualRealList
                  [1.1, 2.2, 3.3]
                  (J2M.jsonToML (J.ARRAY ([J.REAL 1.1, 
                                           J.REAL 2.2, 
                                           J.REAL 3.3], 
                                          J.REALty),
                                 J.ARRAYty J.REALty)),
             fn () =>
                A.assertEqualStringList
                  ["hoge", "fuga", "foo"]
                  (J2M.jsonToML (J.ARRAY ([J.STRING "hoge", 
                                           J.STRING "fuga", 
                                           J.STRING "foo"],
                                          J.STRINGty),
                                 J.ARRAYty J.STRINGty)),
             fn () =>
                (A.assertEqualList A.assertEqualIntList)
                  [[1],[2]]
                  (J2M.jsonToML (J.ARRAY ([J.ARRAY ([J.INT 1], J.INTty),
                                           J.ARRAY ([J.INT 2], J.INTty)],
                                          J.ARRAYty J.INTty),
                                 J.ARRAYty (J.ARRAYty J.INTty))),
             fn () =>
                (A.assertEqualList A.assertEqualStringList)
                  [["hoge"], ["fuga"]]
                  (J2M.jsonToML (J.ARRAY ([J.ARRAY ([J.STRING "hoge"], 
                                                    J.STRINGty),
                                           J.ARRAY ([J.STRING "fuga"], 
                                                    J.STRINGty)],
                                          J.ARRAYty J.STRINGty),
                                 J.ARRAYty (J.ARRAYty J.STRINGty))),
             fn () =>
                (A.assertEqual 
                   (op =) 
                   (fn _ => 
                       "(boxed) : {a : int, b : string, c : bool, d : int list}"))
                       (* FIXME *)
                  {a = 1, b = "SML#", c = true, d = [1,2]}
                  (J2M.jsonToML (J.OBJECT [("a", J.INT 1),
                                           ("b", J.STRING "SML#"),
                                           ("c", J.BOOL true),
                                           ("d", J.ARRAY ([J.INT 1, J.INT 2],
                                                          J.INTty))],
                                 J.RECORDty [("a", J.INTty),
                                             ("b", J.STRINGty),
                                             ("c", J.BOOLty),
                                             ("d", J.ARRAYty J.INTty)])),
             fn () =>
                (A.assertEqualIntOption
                   NONE
                   (J2M.jsonToML (J.NULLObject, J.OPTIONty J.INTty))),
             fn () =>
                (A.assertEqualIntOption
                   (SOME 1)
                   (J2M.jsonToML (J.INT 1, J.OPTIONty J.INTty))),
             fn () =>
                (A.assertEqualStringOption
                   NONE
                   (J2M.jsonToML (J.NULLObject, J.OPTIONty J.STRINGty))),
             fn () =>
                (A.assertEqualStringOption
                   (SOME "SML#")
                   (J2M.jsonToML (J.STRING "SML#", J.OPTIONty J.STRINGty)))
            ]
      in
        T.TestList (List.map T.TestCase data)
      end

  fun suite () =
      T.TestList
        [
         T.TestLabel ("testJsonToML", testJsonToML ())
        ]
end
