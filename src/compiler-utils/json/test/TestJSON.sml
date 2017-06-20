(**
 * @author Atsushi Ohori
 * @copyright 2016, Tohoku University.
 *)
structure TestJSON =
struct
  structure A = SMLUnit.Assert
  structure T = SMLUnit.Test

  open JSON
  
  fun assertEqualJson expectedJson actualJson  = 
      A.assertEqual JSONTypes.eqJson JSONTypes.jsonToString expectedJson actualJson
  fun assertEqualJsonTy expectedJsonTy actualJsonTy  = 
      A.assertEqual (op =) JSONTypes.jsonTyToString expectedJsonTy actualJsonTy
  fun assertEqualJsonDyn (DYN (_, expectedJson)) (DYN (_, actualJson))  = 
      assertEqualJson expectedJson actualJson 

  fun testImport () =
      let
        val data =
            [
             ("1", INT 1),
             ("3.14", REAL 3.14),
             ("\"SML#\"", STRING "SML#"),
             ("true", BOOL true),
             ("[1,2,3]", ARRAY ([INT 1, INT 2, INT 3], INTty)),
             ("{\"name\":\"togetoge\", \"age\":21}", 
              OBJECT [("age", INT 21), ("name", STRING "togetoge")]),
             ("{\"age\":21, \"name\":\"togetoge\"}", 
              OBJECT [("age", INT 21), ("name", STRING "togetoge")])
            ]
        fun assert (string, json) =
            T.TestCase (fn () => assertEqualJsonDyn (jsonToJsonDyn json) (import string))
      in
        T.TestList (map assert data)
      end

  fun testTypeOf () =
      let
        val data =
            [
             (INT 1, INTty),
             (BOOL true, BOOLty),
             (REAL 3.14, REALty),
             (STRING "SML#", STRINGty),
             (ARRAY ([INT 1, INT 2], INTty), ARRAYty INTty),
             (OBJECT [("name", STRING "togetoge"), ("age", INT 21)],
              RECORDty [("name", STRINGty), ("age", INTty)])
            ]
        fun assert (json, jsonTy) =
            T.TestCase (fn () => assertEqualJsonTy jsonTy (typeOf json))
      in
        T.TestList (map assert data)
      end

  fun testToJson () =
      let
        val data =
            [
             (toJson 1, INT 1),
             (toJson true, BOOL true),
             (toJson 3.14, REAL 3.14),
             (toJson "SML#", STRING "SML#"),
             (toJson [1,2,3], ARRAY ([INT 1, INT 2, INT 3], INTty)),
             (toJson {name = "togetoge", age = 21},
              OBJECT [("age", INT 21), ("name", STRING "togetoge")]),
             (toJson [{name = "togetoge", age = 21}],
              ARRAY ([OBJECT [("age", INT 21), ("name", STRING "togetoge")]],
                     RECORDty [("age", INTty), ("name", STRINGty)]))
            ]
        fun assert (actual, expected) =
            T.TestCase (fn () => assertEqualJson expected actual) 
      in
        T.TestList (map assert data)
      end

  fun testToJsonDyn () =
      let
        val data =
            [
             (toJsonDyn 1, import "1"),
             (toJsonDyn true, import "true"),
             (toJsonDyn false, import "false"),
             (toJsonDyn 3.14, import "3.14"),
             (toJsonDyn "SML#", import "\"SML#\""),
             (toJsonDyn NONE, import "null"),
             (toJsonDyn [1,2,3], import "[1,2,3]"),
             (toJsonDyn {name = "togetoge", age = 21}, 
              import "{\"age\":21,\"name\":\"togetoge\"}"),
             (toJsonDyn [{name = "togetoge", age = 21}],
              import "[{\"age\":21,\"name\":\"togetoge\"}]")
            ]
        fun assert (actual, expected) =
            T.TestCase (fn () => assertEqualJsonDyn expected actual)
      in
        T.TestList (map assert data)
      end

  fun suite () =
      T.TestList
        [
         T.TestLabel ("testImport", testImport ()),
         T.TestLabel ("testTypeOf", testTypeOf ()),
         T.TestLabel ("testToJson", testToJson ()),
         T.TestLabel ("testToJsonDyn", testToJsonDyn ())
        ]
end

