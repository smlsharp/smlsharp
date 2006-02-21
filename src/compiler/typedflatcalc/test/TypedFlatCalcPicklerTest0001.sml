(**
 * @author YAMATODANI Kiyoshi
 * @version $Id: TypedFlatCalcPicklerTest0001.sml,v 1.2 2006/02/20 06:52:03 kiyoshiy Exp $
 *)
structure TypedFlatCalcPicklerTest001 =
struct

  (***************************************************************************)

  structure Assert = SMLUnit.Assert
  structure Test = SMLUnit.Test

  structure Testee = TypedFlatCalcPickler

  structure TFC = TypedFlatCalc

  (***************************************************************************)

  fun equalVarIdInfo (v1 : TFC.varIdInfo, v2 : TFC.varIdInfo) =
      (ID.compare (#id v1, #id v2) = EQUAL)
      andalso (#displayName v1 = #displayName v2)
(*
      andalso (Types.equalTy (#ty v1, #ty v2))
*)

  fun varIdInfoToString {id, displayName, ty} =
      "{"
          ^ "id = " ^ ID.toString id ^ ", "
          ^ "displayName = " ^ displayName ^ ", "
          ^ "ty = " ^ TypeFormatter.tyToString ty
      ^ "}"

  fun testVarIdInfo varIdInfo =
      let
        val pickled = Pickle.toString Testee.varIdInfo varIdInfo
        val varIdInfo2 = Pickle.fromString Testee.varIdInfo pickled
      in
        Assert.assertEqual
            equalVarIdInfo
            varIdInfoToString
            varIdInfo
            varIdInfo2;
        ()
      end

  fun testVarIdInfo0001 () =
      let
        val varIdInfo =
            {
              id = ID.generate (),
              displayName = "foo",
              ty = Types.ATOMty
            }
      in
        testVarIdInfo varIdInfo
      end

  (***************************************************************************)

  fun suite () =
      Test.labelTests
      [
        ("testVarIdInfo0001", testVarIdInfo0001)
      ]

  (***************************************************************************)

end
