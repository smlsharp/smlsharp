structure TestJSONImpl =
struct
  structure A = SMLUnit.Assert
  structure T = SMLUnit.Test

  open JSON
  open JSONImpl

  fun assertEqualJson expectedJson actualJson =
      A.assertEqual JSONTypes.eqJson JSONTypes.jsonToString expectedJson actualJson

  fun testNaturalJoin () =
      let
        val data =
            [
             ((INT 1, INT 1), INT 1),
             ((STRING "SML#", STRING "SML#"), STRING "SML#"),
             ((BOOL true, BOOL true), BOOL true),
             ((BOOL false, BOOL false), BOOL false),
             ((ARRAY ([INT 1, INT 2, INT 3], INTty),
               ARRAY ([INT 2, INT 3, INT 4], INTty)),
              ARRAY ([INT 2, INT 3], INTty)),
             ((OBJECT [("age", INT 21), ("name", STRING "togetoge")],
               OBJECT [("isCat", BOOL true), ("name", STRING "togetoge")]),
              OBJECT [("age", INT 21), 
                      ("isCat", BOOL true), 
                      ("name", STRING "togetoge")]),
             ((ARRAY ([OBJECT [("age", INT 21), ("name", STRING "foo")],
                       OBJECT [("age", INT 31), ("name", STRING "baa")]],
                      RECORDty [("age", INTty), ("name", STRINGty)]),
               ARRAY ([OBJECT [("name", STRING "foo"), ("salary", REAL 1.1)],
                       OBJECT [("name", STRING "baz"), ("salary", REAL 2.2)]],
                      RECORDty [("name", STRINGty), ("salary", REALty)])),
              ARRAY ([OBJECT [("age", INT 21), 
                              ("name", STRING "foo"), 
                              ("salary", REAL 1.1)]],
                     RECORDty [("age", INTty), ("name", STRINGty), ("salary", REALty)]))
            ]
        fun assert ((elem1, elem2), expected) =
            T.TestCase (fn () => assertEqualJson expected (naturalJoin (elem1, elem2)))
      in
        T.TestList (map assert data)
      end

  fun suite () =
      T.TestList
        [
         T.TestLabel ("testNaturalJoin", testNaturalJoin ())
        ]
end
