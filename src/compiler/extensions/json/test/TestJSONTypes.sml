(**
 * @author Atsushi Ohori
 * @copyright 2016, Tohoku University.
 *)
structure TestJSONTypes =
struct
  structure Assert = SMLUnit.Assert
  structure Test = SMLUnit.Test

  open JSONTypes 

  fun testJsonTyToString () =
      let
        val data = 
            [
             (DYNty, "DYNty"),
             (NULLty, "NULLty"),
             (BOOLty, "BOOLty"),
             (INTty, "INTty"),
             (REALty, "REALty"),
             (STRINGty, "STRINGty"),
             (ARRAYty INTty, "ARRAYty(INTty)"),
             (RECORDty [("age",INTty), ("name",STRINGty)],
              "RECORDty {age:INTty, name:STRINGty}"),
             (PARTIALRECORDty [("age",INTty), ("name",STRINGty)],
              "PARTIALRECORDty {age:INTty, name:STRINGty}"),
             (PARTIALINTty, "PARTIALINTty"),
             (PARTIALBOOLty, "PARTIALBOOLty"),
             (PARTIALSTRINGty, "PARTIALSTRINGty"),
             (PARTIALREALty, "PARTIALREALty"),
             (OPTIONty INTty, "OPTIONty(INTty)")
            ]
        fun assert (ty, string) =
            (Test.TestCase (fn () => Assert.assertEqualString string (jsonTyToString ty)))
      in
        Test.TestList (map assert data)
      end

  fun testJsonToString () =
      let
        val data = 
            [
             (ARRAY ([INT 1, INT 2], INTty), "ARRAY [INT(1), INT(2)] : INTty"),
             (BOOL true, "BOOL(true)"),
             (INT 1, "INT(1)"),
             (NULLObject, "NULLObject"),
             (OBJECT [("age", INT 21), ("name", STRING "joe")],
              "OBJECT {age=INT(21), name=STRING(\"joe\")}"),
             (REAL 3.14, "REAL(3.14)"),
             (STRING "SML#", "STRING(\"SML#\")")
            ]
        fun assert (ty, string) =
            (Test.TestCase (fn () => Assert.assertEqualString string (jsonToString ty)))
      in
        Test.TestList (map assert data)
      end

  fun suite () =
      Test.TestList
        [
         Test.TestLabel ("jsonTyToString", testJsonTyToString ()),
         Test.TestLabel ("jsonToString", testJsonToString ())
        ]
end
