(**
 *  Verifies that the assembler translates a symbolic instruction to its
 * corresponding raw instruction.
 * @author YAMATODANI Kiyoshi
 * @version $Id: AssemblerTest0001.sml,v 1.11 2006/02/20 06:52:03 kiyoshiy Exp $
 *)
structure AssemblerTest0001 =
struct

  (***************************************************************************)

  structure Assert = SMLUnit.Assert
  structure Test = SMLUnit.Test

  structure Testee = Assembler

  structure ATU = AssemblerTestUtil
  structure BT = BasicTypes
  structure I = Instructions
  structure SI = SymbolicInstructions
  structure A = Absyn

  (***************************************************************************)

  fun assemble funInfo code =
      let
        val functionCode = 
            {
              name = ATU.makeVarInfo "main",
              funInfo = funInfo,
              instructions = code,
              loc = Loc.noloc
            }
        val executable = 
            Testee.assemble
                {
                  mainFunctionName = ATU.nameToVarID "main",
                  functions = [functionCode]
                }
      in
        #instructions executable
      end

  (****************************************)

  val TESTLOADINT0001_FUNINFO =
      ATU.makeMonoFunInfo {pointers = [], atoms = ["v"]}
  val TESTLOADINT0001_SOURCE =
      [
        SI.LoadInt { value = 123, destination = ATU.makeVarInfo "v" }
      ]
  val TESTLOADINT0001_DESTINATION =
      ATU.getEntry TESTLOADINT0001_FUNINFO TESTLOADINT0001_SOURCE "v"
  val TESTLOADINT0001_EXPECTED =
      (ATU.assembledFunInfo TESTLOADINT0001_FUNINFO TESTLOADINT0001_SOURCE) ::
      [
        I.LoadInt
        {value = 123, destination = TESTLOADINT0001_DESTINATION}
      ]

  fun testLoadInt0001() =
      (
        ATU.assertEqualInstructionList
        TESTLOADINT0001_EXPECTED
        (assemble TESTLOADINT0001_FUNINFO TESTLOADINT0001_SOURCE);
        ()
      )

  (****************************************)

  val TESTLOADWORD0001_FUNINFO =
      ATU.makeMonoFunInfo {pointers = [], atoms = ["v"]}
  val TESTLOADWORD0001_SOURCE =
      [
        SI.LoadWord { value = 0w123, destination = ATU.makeVarInfo "v" }
      ]
  val TESTLOADWORD0001_DESTINATION =
      ATU.getEntry TESTLOADWORD0001_FUNINFO TESTLOADWORD0001_SOURCE "v"
  val TESTLOADWORD0001_EXPECTED =
      (ATU.assembledFunInfo TESTLOADWORD0001_FUNINFO TESTLOADWORD0001_SOURCE) ::
      [
        I.LoadWord
        {
          value = 0w123,
          destination = TESTLOADWORD0001_DESTINATION
        }
      ]

  fun testLoadWord0001() =
      (
        ATU.assertEqualInstructionList
        TESTLOADWORD0001_EXPECTED
        (assemble TESTLOADWORD0001_FUNINFO TESTLOADWORD0001_SOURCE);
        ()
      )

  (****************************************)

  val TESTLOADSTRING0001_FUNINFO =
      ATU.makeMonoFunInfo {pointers = [], atoms = ["v"]}
  val TESTLOADSTRING0001_SOURCE =
      [
        SI.Label (ATU.nameToAddress "s"),
        SI.LoadString
            {string = ATU.nameToAddress "s", destination = ATU.makeVarInfo "v"}
      ]
  val TESTLOADSTRING0001_DESTINATION =
      ATU.getEntry TESTLOADSTRING0001_FUNINFO TESTLOADSTRING0001_SOURCE "v"
  val TESTLOADSTRING0001_EXPECTED =
      (ATU.assembledFunInfo TESTLOADSTRING0001_FUNINFO TESTLOADSTRING0001_SOURCE) ::
      [
        I.LoadString
        {
          string = ATU.funEntrySize TESTLOADSTRING0001_FUNINFO,
          destination = TESTLOADSTRING0001_DESTINATION
        }
      ]

  fun testLoadString0001() =
      (
        ATU.assertEqualInstructionList
        TESTLOADSTRING0001_EXPECTED
        (assemble TESTLOADSTRING0001_FUNINFO TESTLOADSTRING0001_SOURCE);
        ()
      )

  (****************************************)

  val TESTCONSTSTRING0001_FUNINFO =
      ATU.makeMonoFunInfo {pointers = [], atoms = []}
  val TESTCONSTSTRING0001_STRING = "12345"
  val TESTCONSTSTRING0001_SOURCE =
      [
        SI.ConstString { string = TESTCONSTSTRING0001_STRING }
      ]
  val TESTCONSTSTRING0001_EXPECTED_STRING =
      StringCvt.padRight
          #"\000"
          ((((String.size TESTCONSTSTRING0001_STRING) div 4) + 1)* 4)
          TESTCONSTSTRING0001_STRING
  val TESTCONSTSTRING0001_EXPECTED =
      (ATU.assembledFunInfo TESTCONSTSTRING0001_FUNINFO TESTCONSTSTRING0001_SOURCE) ::
      [
        I.ConstString
        {
          length = UInt32.fromInt(String.size TESTCONSTSTRING0001_STRING),
          string =
          map
              (BT.IntToUInt8 o Char.ord)
              (explode TESTCONSTSTRING0001_EXPECTED_STRING)
        }
      ]

  fun testConstString0001() =
      (
        ATU.assertEqualInstructionList
        TESTCONSTSTRING0001_EXPECTED
        (assemble TESTCONSTSTRING0001_FUNINFO TESTCONSTSTRING0001_SOURCE);
        ()
      )
(*
  (****************************************)

  val TESTLOADREAL0001_SOURCE =
      [
        SI.LoadReal { value = "1.23" }
      ]
  val TESTLOADREAL0001_EXPECTED =
      [
        I.LoadReal {value = 1.23}
      ]

  fun testLoadReal0001() =
      (
        ATU.assertEqualInstructionList
        TESTLOADREAL0001_EXPECTED
        (Testee.assemble TESTLOADREAL0001_SOURCE);
        ()
      )
*)
  (****************************************)

  val TESTLOADCHAR0001_FUNINFO =
      ATU.makeMonoFunInfo {pointers = [], atoms = ["v"]}
  val TESTLOADCHAR0001_VALUE = 0w12 : BT.UInt32
  val TESTLOADCHAR0001_SOURCE =
      [
        SI.LoadChar
            {value = TESTLOADCHAR0001_VALUE, destination = ATU.makeVarInfo "v"}
      ]
  val TESTLOADCHAR0001_DESTINATION =
      ATU.getEntry TESTLOADCHAR0001_FUNINFO TESTLOADCHAR0001_SOURCE "v"
  val TESTLOADCHAR0001_EXPECTED =
      (ATU.assembledFunInfo TESTLOADCHAR0001_FUNINFO TESTLOADCHAR0001_SOURCE) ::
      [
        I.LoadChar
        {
          value = TESTLOADCHAR0001_VALUE,
          destination = TESTLOADCHAR0001_DESTINATION
        }
      ]

  fun testLoadChar0001() =
      (
        ATU.assertEqualInstructionList
        TESTLOADCHAR0001_EXPECTED
        (assemble TESTLOADCHAR0001_FUNINFO TESTLOADCHAR0001_SOURCE);
        ()
      )

  (****************************************)

  val TESTACCESS0001_FUNINFO =
      ATU.makeMonoFunInfo {pointers = [], atoms = ["x", "v"]}
  val TESTACCESS0001_SOURCE =
      [
        SI.Access
            {
              variableEntry = ATU.makeVarInfo "x",
              variableSize = SI.SINGLE,
              destination = ATU.makeVarInfo "v"
            }
      ]
  val TESTACCESS0001_VARIABLE =
      ATU.getEntry TESTACCESS0001_FUNINFO TESTACCESS0001_SOURCE "x"
  val TESTACCESS0001_DESTINATION =
      ATU.getEntry TESTACCESS0001_FUNINFO TESTACCESS0001_SOURCE "v"
  val TESTACCESS0001_EXPECTED =
      (ATU.assembledFunInfo TESTACCESS0001_FUNINFO TESTACCESS0001_SOURCE) ::
      [
        I.Access_S
        {
          variableOffset = TESTACCESS0001_VARIABLE,
          destination = TESTACCESS0001_DESTINATION
        }
      ]

  fun testAccess0001() =
      (
        ATU.assertEqualInstructionList
        TESTACCESS0001_EXPECTED
        (assemble TESTACCESS0001_FUNINFO TESTACCESS0001_SOURCE);
        ()
      )

  (****************************************)

  val TESTACCESSENV0001_FUNINFO =
      ATU.makeMonoFunInfo {pointers = [], atoms = ["v"]}
  val TESTACCESSENV0001_OFFSET = 0w1 : BT.UInt32
  val TESTACCESSENV0001_SOURCE =
      [
        SI.AccessEnv
            {
              offset = TESTACCESSENV0001_OFFSET,
              variableSize = SI.SINGLE,
              destination = ATU.makeVarInfo "v"
            }
      ]
  val TESTACCESSENV0001_DESTINATION =
      ATU.getEntry TESTACCESSENV0001_FUNINFO TESTACCESSENV0001_SOURCE "v"
  val TESTACCESSENV0001_EXPECTED =
      (ATU.assembledFunInfo TESTACCESSENV0001_FUNINFO TESTACCESSENV0001_SOURCE) ::
      [
        I.AccessEnv_S
        {
          offset = TESTACCESSENV0001_OFFSET,
          destination = TESTACCESSENV0001_DESTINATION
        }
      ]

  fun testAccessEnv0001() =
      (
        ATU.assertEqualInstructionList
        TESTACCESSENV0001_EXPECTED
        (assemble TESTACCESSENV0001_FUNINFO TESTACCESSENV0001_SOURCE);
        ()
      )

  (****************************************)

  val TESTGETFIELD0001_FUNINFO =
      ATU.makeMonoFunInfo {pointers = ["x"], atoms = ["v"]}
  val TESTGETFIELD0001_FIELD_OFFSET = 0w1 : BT.UInt32
  val TESTGETFIELD0001_SOURCE =
      [
        SI.GetField
            {
              fieldOffset = TESTGETFIELD0001_FIELD_OFFSET,
              fieldSize = SI.SINGLE,
              blockEntry = ATU.makeVarInfo "x",
              destination = ATU.makeVarInfo "v"
            }
      ]
  val TESTGETFIELD0001_BLOCK =
      ATU.getEntry TESTGETFIELD0001_FUNINFO TESTGETFIELD0001_SOURCE "x"
  val TESTGETFIELD0001_DESTINATION =
      ATU.getEntry TESTGETFIELD0001_FUNINFO TESTGETFIELD0001_SOURCE "v"
  val TESTGETFIELD0001_EXPECTED =
      (ATU.assembledFunInfo TESTGETFIELD0001_FUNINFO TESTGETFIELD0001_SOURCE) ::
      [
        I.GetField_S
        {
          fieldOffset = TESTGETFIELD0001_FIELD_OFFSET,
          blockOffset = TESTGETFIELD0001_BLOCK,
          destination = TESTGETFIELD0001_DESTINATION
        }
      ]

  fun testGetField0001() =
      (
        ATU.assertEqualInstructionList
        TESTGETFIELD0001_EXPECTED
        (assemble TESTGETFIELD0001_FUNINFO TESTGETFIELD0001_SOURCE);
        ()
      )

  (****************************************)

  val TESTGETFIELDINDIRECT0001_FUNINFO =
      ATU.makeMonoFunInfo {pointers = ["x"], atoms = ["f", "v"]}
  val TESTGETFIELDINDIRECT0001_SOURCE =
      [
        SI.GetFieldIndirect
            {
              fieldEntry = ATU.makeVarInfo "f",
              fieldSize = SI.SINGLE,
              blockEntry = ATU.makeVarInfo "x",
              destination = ATU.makeVarInfo "v"
            }
      ]
  val TESTGETFIELDINDIRECT0001_FIELD =
      ATU.getEntry
          TESTGETFIELDINDIRECT0001_FUNINFO TESTGETFIELDINDIRECT0001_SOURCE "f"
  val TESTGETFIELDINDIRECT0001_BLOCK =
      ATU.getEntry
          TESTGETFIELDINDIRECT0001_FUNINFO TESTGETFIELDINDIRECT0001_SOURCE "x"
  val TESTGETFIELDINDIRECT0001_DESTINATION =
      ATU.getEntry
          TESTGETFIELDINDIRECT0001_FUNINFO TESTGETFIELDINDIRECT0001_SOURCE "v"
  val TESTGETFIELDINDIRECT0001_EXPECTED =
      (ATU.assembledFunInfo
           TESTGETFIELDINDIRECT0001_FUNINFO
           TESTGETFIELDINDIRECT0001_SOURCE) ::
      [
        I.GetFieldIndirect_S
        {
          fieldOffset = TESTGETFIELDINDIRECT0001_FIELD,
          blockOffset = TESTGETFIELDINDIRECT0001_BLOCK,
          destination = TESTGETFIELDINDIRECT0001_DESTINATION
        }
      ]

  fun testGetFieldIndirect0001() =
      (
        ATU.assertEqualInstructionList
        TESTGETFIELDINDIRECT0001_EXPECTED
        (assemble
             TESTGETFIELDINDIRECT0001_FUNINFO TESTGETFIELDINDIRECT0001_SOURCE);
        ()
      )

  (****************************************)
(*
  val TESTCOPYANDUPDATEFIELD0001_FUNINFO =
      ATU.makeMonoFunInfo {pointers = ["x"], atoms = ["y", "v"]}
  val TESTCOPYANDUPDATEFIELD0001_FIELD_OFFSET = 0w1 : BT.UInt32
  val TESTCOPYANDUPDATEFIELD0001_SOURCE =
      [
        SI.CopyAndUpdateField
            {
              fieldOffset = TESTCOPYANDUPDATEFIELD0001_FIELD_OFFSET,
              blockEntry = "x",
              newValueEntry = "y",
              destination = "v"
            }
      ]
  val TESTCOPYANDUPDATEFIELD0001_BLOCK =
      ATU.getEntry
      TESTCOPYANDUPDATEFIELD0001_FUNINFO TESTCOPYANDUPDATEFIELD0001_SOURCE "x"
  val TESTCOPYANDUPDATEFIELD0001_NEWVALUE =
      ATU.getEntry
      TESTCOPYANDUPDATEFIELD0001_FUNINFO TESTCOPYANDUPDATEFIELD0001_SOURCE "y"
  val TESTCOPYANDUPDATEFIELD0001_DESTINATION =
      ATU.getEntry
      TESTCOPYANDUPDATEFIELD0001_FUNINFO TESTCOPYANDUPDATEFIELD0001_SOURCE "v"
  val TESTCOPYANDUPDATEFIELD0001_EXPECTED =
      (ATU.assembledFunInfo TESTCOPYANDUPDATEFIELD0001_FUNINFO TESTCOPYANDUPDATEFIELD0001_SOURCE) ::
      [
        I.CopyAndUpdateField
        {
          fieldOffset = TESTCOPYANDUPDATEFIELD0001_FIELD_OFFSET,
          blockOffset = TESTCOPYANDUPDATEFIELD0001_BLOCK,
          newValueOffset = TESTCOPYANDUPDATEFIELD0001_NEWVALUE,
          destination = TESTCOPYANDUPDATEFIELD0001_DESTINATION
        }
      ]

  fun testCopyAndUpdateField0001() =
      (
        ATU.assertEqualInstructionList
        TESTCOPYANDUPDATEFIELD0001_EXPECTED
        (assemble
             TESTCOPYANDUPDATEFIELD0001_FUNINFO
             TESTCOPYANDUPDATEFIELD0001_SOURCE);
        ()
      )

  (****************************************)

  val TESTCOPYANDUPDATEFIELDINDIRECT0001_FUNINFO =
      ATU.makeMonoFunInfo {pointers = ["x"], atoms = ["f", "y", "v"]}
  val TESTCOPYANDUPDATEFIELDINDIRECT0001_SOURCE =
      [
        SI.CopyAndUpdateFieldIndirect
            {
              fieldEntry = "f",
              blockEntry = "x",
              newValueEntry = "y",
              destination = "v"
            }
      ]
  val TESTCOPYANDUPDATEFIELDINDIRECT0001_FIELD =
      ATU.getEntry 
          TESTCOPYANDUPDATEFIELDINDIRECT0001_FUNINFO
          TESTCOPYANDUPDATEFIELDINDIRECT0001_SOURCE
          "f"
  val TESTCOPYANDUPDATEFIELDINDIRECT0001_BLOCK =
      ATU.getEntry
          TESTCOPYANDUPDATEFIELDINDIRECT0001_FUNINFO
          TESTCOPYANDUPDATEFIELDINDIRECT0001_SOURCE
          "x"
  val TESTCOPYANDUPDATEFIELDINDIRECT0001_NEWVALUE = 
      ATU.getEntry
          TESTCOPYANDUPDATEFIELDINDIRECT0001_FUNINFO
          TESTCOPYANDUPDATEFIELDINDIRECT0001_SOURCE
          "y"
  val TESTCOPYANDUPDATEFIELDINDIRECT0001_DESTINATION =
      ATU.getEntry
          TESTCOPYANDUPDATEFIELDINDIRECT0001_FUNINFO
          TESTCOPYANDUPDATEFIELDINDIRECT0001_SOURCE
          "v"
  val TESTCOPYANDUPDATEFIELDINDIRECT0001_EXPECTED =
      (ATU.assembledFunInfo TESTCOPYANDUPDATEFIELDINDIRECT0001_FUNINFO TESTCOPYANDUPDATEFIELDINDIRECT0001_SOURCE) ::
      [
        I.CopyAndUpdateFieldIndirect
        {
          fieldOffset = TESTCOPYANDUPDATEFIELDINDIRECT0001_FIELD,
          blockOffset = TESTCOPYANDUPDATEFIELDINDIRECT0001_BLOCK,
          newValueOffset = TESTCOPYANDUPDATEFIELDINDIRECT0001_NEWVALUE,
          destination = TESTCOPYANDUPDATEFIELDINDIRECT0001_DESTINATION
        }
      ]

  fun testCopyAndUpdateFieldIndirect0001() =
      (
        ATU.assertEqualInstructionList
        TESTCOPYANDUPDATEFIELDINDIRECT0001_EXPECTED
        (assemble
             TESTCOPYANDUPDATEFIELDINDIRECT0001_FUNINFO
             TESTCOPYANDUPDATEFIELDINDIRECT0001_SOURCE);
        ()
      )
*)
  (****************************************)

  val TESTSETFIELD0001_FUNINFO =
      ATU.makeMonoFunInfo {pointers = ["x"], atoms = ["y"]}
  val TESTSETFIELD0001_FIELD_OFFSET = 0w1 : BT.UInt32
  val TESTSETFIELD0001_SOURCE =
      [
        SI.SetField
            {
              fieldOffset = TESTSETFIELD0001_FIELD_OFFSET,
              fieldSize = SI.SINGLE,
              blockEntry = ATU.makeVarInfo "x",
              newValueEntry = ATU.makeVarInfo "y"
            }
      ]
  val TESTSETFIELD0001_BLOCK =
      ATU.getEntry TESTSETFIELD0001_FUNINFO TESTSETFIELD0001_SOURCE "x"
  val TESTSETFIELD0001_NEWVALUE =
      ATU.getEntry TESTSETFIELD0001_FUNINFO TESTSETFIELD0001_SOURCE "y"
  val TESTSETFIELD0001_EXPECTED =
      (ATU.assembledFunInfo
           TESTSETFIELD0001_FUNINFO
           TESTSETFIELD0001_SOURCE) ::
      [
        I.SetField_S
        {
          fieldOffset = TESTSETFIELD0001_FIELD_OFFSET,
          blockOffset = TESTSETFIELD0001_BLOCK,
          newValueOffset = TESTSETFIELD0001_NEWVALUE
        }
      ]

  fun testSetField0001() =
      (
        ATU.assertEqualInstructionList
        TESTSETFIELD0001_EXPECTED
        (assemble
             TESTSETFIELD0001_FUNINFO
             TESTSETFIELD0001_SOURCE);
        ()
      )

  (****************************************)

  val TESTSETFIELDINDIRECT0001_FUNINFO =
      ATU.makeMonoFunInfo {pointers = ["x"], atoms = ["f", "y"]}
  val TESTSETFIELDINDIRECT0001_SOURCE =
      [
        SI.SetFieldIndirect
            {
              fieldEntry = ATU.makeVarInfo "f",
              fieldSize = SI.SINGLE,
              blockEntry = ATU.makeVarInfo "x",
              newValueEntry = ATU.makeVarInfo "y"
            }
      ]
  val TESTSETFIELDINDIRECT0001_FIELD =
      ATU.getEntry
          TESTSETFIELDINDIRECT0001_FUNINFO TESTSETFIELDINDIRECT0001_SOURCE "f"
  val TESTSETFIELDINDIRECT0001_BLOCK =
      ATU.getEntry
          TESTSETFIELDINDIRECT0001_FUNINFO TESTSETFIELDINDIRECT0001_SOURCE "x"
  val TESTSETFIELDINDIRECT0001_NEWVALUE = 
      ATU.getEntry
          TESTSETFIELDINDIRECT0001_FUNINFO TESTSETFIELDINDIRECT0001_SOURCE "y"
  val TESTSETFIELDINDIRECT0001_EXPECTED =
      (ATU.assembledFunInfo
           TESTSETFIELDINDIRECT0001_FUNINFO
           TESTSETFIELDINDIRECT0001_SOURCE) ::
      [
        I.SetFieldIndirect_S
        {
          fieldOffset = TESTSETFIELDINDIRECT0001_FIELD,
          blockOffset = TESTSETFIELDINDIRECT0001_BLOCK,
          newValueOffset = TESTSETFIELDINDIRECT0001_NEWVALUE
        }
      ]

  fun testSetFieldIndirect0001() =
      (
        ATU.assertEqualInstructionList
        TESTSETFIELDINDIRECT0001_EXPECTED
        (assemble
             TESTSETFIELDINDIRECT0001_FUNINFO
             TESTSETFIELDINDIRECT0001_SOURCE);
        ()
      )

  (****************************************)

  val TESTGETGLOBAL0001_FUNINFO =
      ATU.makeMonoFunInfo {pointers = ["v"], atoms = []}
  val TESTGETGLOBAL0001_GLOBALARRAYINDEX = 0w1 : BT.UInt32
  val TESTGETGLOBAL0001_OFFSET = 0w2 : BT.UInt32
  val TESTGETGLOBAL0001_SOURCE =
      [
        SI.GetGlobal
            {
              globalArrayIndex = TESTGETGLOBAL0001_GLOBALARRAYINDEX,
              offset = TESTGETGLOBAL0001_OFFSET,
              variableSize = SI.SINGLE,
              destination = ATU.makeVarInfo "v"
            }
      ]
  val TESTGETGLOBAL0001_DESTINATION =
      ATU.getEntry
          TESTGETGLOBAL0001_FUNINFO TESTGETGLOBAL0001_SOURCE "v"
  val TESTGETGLOBAL0001_EXPECTED =
      (ATU.assembledFunInfo
           TESTGETGLOBAL0001_FUNINFO
           TESTGETGLOBAL0001_SOURCE) ::
      [
        I.GetGlobal_S
        {
          globalArrayIndex = TESTGETGLOBAL0001_GLOBALARRAYINDEX,
          offset = TESTGETGLOBAL0001_OFFSET,
          destination = TESTGETGLOBAL0001_DESTINATION
        }
      ]

  fun testGetGlobal0001() =
      (
        ATU.assertEqualInstructionList
        TESTGETGLOBAL0001_EXPECTED
        (assemble TESTGETGLOBAL0001_FUNINFO TESTGETGLOBAL0001_SOURCE);
        ()
      )

  (****************************************)

  val TESTSETGLOBAL0001_FUNINFO =
      ATU.makeMonoFunInfo {pointers = ["v"], atoms = []}
  val TESTSETGLOBAL0001_GLOBALARRAYINDEX = 0w1 : BT.UInt32
  val TESTSETGLOBAL0001_OFFSET = 0w1 : BT.UInt32
  val TESTSETGLOBAL0001_SOURCE =
      [
        SI.SetGlobal
            {
              globalArrayIndex = TESTSETGLOBAL0001_GLOBALARRAYINDEX,
              offset = TESTSETGLOBAL0001_OFFSET,
              variableSize = SI.SINGLE,
              newValueEntry = ATU.makeVarInfo "v"
            }
      ]
  val TESTSETGLOBAL0001_VARIABLE =
      ATU.getEntry
          TESTSETGLOBAL0001_FUNINFO TESTSETGLOBAL0001_SOURCE "v"
  val TESTSETGLOBAL0001_EXPECTED =
      (ATU.assembledFunInfo
           TESTSETGLOBAL0001_FUNINFO
           TESTSETGLOBAL0001_SOURCE) ::
      [
        I.SetGlobal_S
        {
          globalArrayIndex = TESTSETGLOBAL0001_GLOBALARRAYINDEX,
          offset = TESTSETGLOBAL0001_OFFSET,
          variableOffset = TESTSETGLOBAL0001_VARIABLE
        }
      ]

  fun testSetGlobal0001() =
      (
        ATU.assertEqualInstructionList
        TESTSETGLOBAL0001_EXPECTED
        (assemble TESTSETGLOBAL0001_FUNINFO TESTSETGLOBAL0001_SOURCE);
        ()
      )

  (****************************************)

  val TESTGETENV0001_FUNINFO =
      ATU.makeMonoFunInfo {pointers = ["v"], atoms = []}
  val TESTGETENV0001_SOURCE =
      [
        SI.GetEnv { destination = ATU.makeVarInfo "v" }
      ]
  val TESTGETENV0001_DESTINATION =
      ATU.getEntry TESTGETENV0001_FUNINFO TESTGETENV0001_SOURCE "v"
  val TESTGETENV0001_EXPECTED =
      (ATU.assembledFunInfo TESTGETENV0001_FUNINFO TESTGETENV0001_SOURCE) ::
      [
        I.GetEnv
        {
          destination = TESTGETENV0001_DESTINATION
        }
      ]

  fun testGetEnv0001() =
      (
        ATU.assertEqualInstructionList
        TESTGETENV0001_EXPECTED
        (assemble TESTGETENV0001_FUNINFO TESTGETENV0001_SOURCE);
        ()
      )

  (****************************************)

  val TESTCALLPRIM0001_FUNINFO =
      ATU.makeMonoFunInfo {pointers = ["v"], atoms = ["x", "y", "z"]}
  val TESTCALLPRIM0001_PRIMITIVE_INDEX = 1
  val TESTCALLPRIM0001_PRIMITIVE =
      {bindName = "prim", ty = StaticEnv.intty, instruction = Primitives.External TESTCALLPRIM0001_PRIMITIVE_INDEX}
  val TESTCALLPRIM0001_ARGNAMES = ["x", "y", "z"]
  val TESTCALLPRIM0001_SOURCE =
      [
        SI.CallPrim
        {
          argsCount = UInt32.fromInt(List.length TESTCALLPRIM0001_ARGNAMES),
          primitive = TESTCALLPRIM0001_PRIMITIVE,
          argEntries = map ATU.makeVarInfo TESTCALLPRIM0001_ARGNAMES,
          argSizes = map (fn _ => SI.SINGLE) TESTCALLPRIM0001_ARGNAMES,
          destination = ATU.makeVarInfo "v",
          resultSize = SI.SINGLE
        }
      ]
  val TESTCALLPRIM0001_ARGS =
      map
          (ATU.getEntry TESTCALLPRIM0001_FUNINFO TESTCALLPRIM0001_SOURCE)
          TESTCALLPRIM0001_ARGNAMES
  val TESTCALLPRIM0001_DESTINATION =
      ATU.getEntry TESTCALLPRIM0001_FUNINFO TESTCALLPRIM0001_SOURCE "v"
  val TESTCALLPRIM0001_EXPECTED =
      (ATU.assembledFunInfo TESTCALLPRIM0001_FUNINFO TESTCALLPRIM0001_SOURCE) ::
      [
        I.CallPrim
        {
          argsCount = UInt32.fromInt(List.length TESTCALLPRIM0001_ARGS),
          primitive = UInt32.fromInt TESTCALLPRIM0001_PRIMITIVE_INDEX,
          argIndexes = TESTCALLPRIM0001_ARGS,
          destination = TESTCALLPRIM0001_DESTINATION
        }
      ]

  fun testCallPrim0001() =
      (
        ATU.assertEqualInstructionList
        TESTCALLPRIM0001_EXPECTED
        (assemble TESTCALLPRIM0001_FUNINFO TESTCALLPRIM0001_SOURCE);
        ()
      )

  (****************************************)

  val TESTAPPLY_ML0001_FUNINFO =
      ATU.makeMonoFunInfo {pointers = ["c", "v"], atoms = ["x", "y", "z"]}
  val TESTAPPLY_ML0001_ARGNAMES = ["x", "y", "z"]
  val TESTAPPLY_ML0001_SOURCE =
      [
        SI.Apply_ML
            {
              argsCount = UInt32.fromInt(List.length TESTAPPLY_ML0001_ARGNAMES),
              closureEntry = ATU.makeVarInfo "c",
              argEntries = map ATU.makeVarInfo TESTAPPLY_ML0001_ARGNAMES,
              lastArgSize = SI.SINGLE,
              destination = ATU.makeVarInfo "v"
            }
      ]
  val TESTAPPLY_ML0001_CLOSURE =
      ATU.getEntry TESTAPPLY_ML0001_FUNINFO TESTAPPLY_ML0001_SOURCE "c"
  val TESTAPPLY_ML0001_ARGS =
      map
          (ATU.getEntry TESTAPPLY_ML0001_FUNINFO TESTAPPLY_ML0001_SOURCE)
          TESTAPPLY_ML0001_ARGNAMES
  val TESTAPPLY_ML0001_DESTINATION =
      ATU.getEntry TESTAPPLY_ML0001_FUNINFO TESTAPPLY_ML0001_SOURCE "v"
  val TESTAPPLY_ML0001_EXPECTED =
      (ATU.assembledFunInfo TESTAPPLY_ML0001_FUNINFO TESTAPPLY_ML0001_SOURCE) ::
      [
        I.Apply_ML_S
        {
          argsCount = UInt32.fromInt(List.length TESTAPPLY_ML0001_ARGS),
          closureOffset = TESTAPPLY_ML0001_CLOSURE,
          argOffsets = TESTAPPLY_ML0001_ARGS,
          destination = TESTAPPLY_ML0001_DESTINATION
        }
      ]

  fun testApply_ML0001() =
      (
        ATU.assertEqualInstructionList
        TESTAPPLY_ML0001_EXPECTED
        (assemble TESTAPPLY_ML0001_FUNINFO TESTAPPLY_ML0001_SOURCE);
        ()
      )

  (****************************************)

  val TESTTAILAPPLY_ML0001_FUNINFO =
      ATU.makeMonoFunInfo {pointers = ["c"], atoms = ["x", "y", "z"]}
  val TESTTAILAPPLY_ML0001_ARGNAMES = ["x", "y", "z"]
  val TESTTAILAPPLY_ML0001_SOURCE =
      [
        SI.TailApply_ML
        {
          argsCount = UInt32.fromInt(List.length TESTTAILAPPLY_ML0001_ARGNAMES),
          closureEntry = ATU.makeVarInfo "c",
          argEntries = map ATU.makeVarInfo TESTTAILAPPLY_ML0001_ARGNAMES,
          lastArgSize = SI.SINGLE
        }
      ]
  val TESTTAILAPPLY_ML0001_CLOSURE =
      ATU.getEntry
          TESTTAILAPPLY_ML0001_FUNINFO TESTTAILAPPLY_ML0001_SOURCE "c"
  val TESTTAILAPPLY_ML0001_ARGS =
      map
          (ATU.getEntry TESTTAILAPPLY_ML0001_FUNINFO TESTTAILAPPLY_ML0001_SOURCE)
          TESTTAILAPPLY_ML0001_ARGNAMES
  val TESTTAILAPPLY_ML0001_EXPECTED =
      (ATU.assembledFunInfo
           TESTTAILAPPLY_ML0001_FUNINFO
           TESTTAILAPPLY_ML0001_SOURCE) ::
      [
        I.TailApply_ML_S
        {
          argsCount = UInt32.fromInt(List.length TESTTAILAPPLY_ML0001_ARGS),
          closureOffset = TESTTAILAPPLY_ML0001_CLOSURE,
          argOffsets = TESTTAILAPPLY_ML0001_ARGS
        }
      ]

  fun testTailApply_ML0001() =
      (
        ATU.assertEqualInstructionList
        TESTTAILAPPLY_ML0001_EXPECTED
        (assemble TESTTAILAPPLY_ML0001_FUNINFO TESTTAILAPPLY_ML0001_SOURCE);
        ()
      )

  (****************************************)

  val TESTCALLSTATIC_ML0001_FUNINFO =
      ATU.makeMonoFunInfo {pointers = ["e", "v"], atoms = ["x", "y", "z"]}
  val TESTCALLSTATIC_ML0001_ENVENTRYNAME = "e"
  val TESTCALLSTATIC_ML0001_ARGNAMES = ["x", "y", "z"]
  val TESTCALLSTATIC_ML0001_SOURCE =
      [
        SI.Label (ATU.nameToAddress "f"),
        SI.CallStatic_ML
        {
          argsCount =
          UInt32.fromInt(List.length TESTCALLSTATIC_ML0001_ARGNAMES),
          entryPoint = ATU.nameToAddress "f",
          envEntry = ATU.makeVarInfo TESTCALLSTATIC_ML0001_ENVENTRYNAME,
          argEntries = map ATU.makeVarInfo TESTCALLSTATIC_ML0001_ARGNAMES,
          lastArgSize = SI.SINGLE,
          destination = ATU.makeVarInfo "v"
        }
      ]
  val TESTCALLSTATIC_ML0001_DESTINATION =
      ATU.getEntry
          TESTCALLSTATIC_ML0001_FUNINFO TESTCALLSTATIC_ML0001_SOURCE "v"
  val TESTCALLSTATIC_ML0001_ENVENTRY =
      ATU.getEntry
          TESTCALLSTATIC_ML0001_FUNINFO
          TESTCALLSTATIC_ML0001_SOURCE
          TESTCALLSTATIC_ML0001_ENVENTRYNAME
  val TESTCALLSTATIC_ML0001_ARGS =
      map
          (ATU.getEntry
               TESTCALLSTATIC_ML0001_FUNINFO TESTCALLSTATIC_ML0001_SOURCE)
          TESTCALLSTATIC_ML0001_ARGNAMES
  val TESTCALLSTATIC_ML0001_EXPECTED =
      (ATU.assembledFunInfo
           TESTCALLSTATIC_ML0001_FUNINFO
           TESTCALLSTATIC_ML0001_SOURCE) ::
      [
        I.CallStatic_ML_S
        {
          argsCount = UInt32.fromInt(List.length TESTCALLSTATIC_ML0001_ARGS),
          entryPoint = ATU.funEntrySize TESTCALLSTATIC_ML0001_FUNINFO,
          envOffset = TESTCALLSTATIC_ML0001_ENVENTRY,
          argOffsets = TESTCALLSTATIC_ML0001_ARGS,
          destination = TESTCALLSTATIC_ML0001_DESTINATION
        }
      ]

  fun testCallStatic_ML0001() =
      (
        ATU.assertEqualInstructionList
        TESTCALLSTATIC_ML0001_EXPECTED
        (assemble TESTCALLSTATIC_ML0001_FUNINFO TESTCALLSTATIC_ML0001_SOURCE);
        ()
      )

  (****************************************)

  val TESTTAILCALLSTATIC_ML0001_FUNINFO =
      ATU.makeMonoFunInfo {pointers = ["e"], atoms = ["x", "y", "z"]}
  val TESTTAILCALLSTATIC_ML0001_ENVENTRYNAME = "e"
  val TESTTAILCALLSTATIC_ML0001_ARGNAMES = ["x", "y", "z"]
  val TESTTAILCALLSTATIC_ML0001_SOURCE =
      [
        SI.Label (ATU.nameToAddress "f"),
        SI.TailCallStatic_ML
            {
              argsCount =
              UInt32.fromInt(List.length TESTTAILCALLSTATIC_ML0001_ARGNAMES),
              entryPoint = (ATU.nameToAddress "f"),
              envEntry =
              ATU.makeVarInfo TESTTAILCALLSTATIC_ML0001_ENVENTRYNAME,
              argEntries =
              map ATU.makeVarInfo TESTTAILCALLSTATIC_ML0001_ARGNAMES,
              lastArgSize = SI.SINGLE
            }
      ]
  val TESTTAILCALLSTATIC_ML0001_ENVENTRY =
      ATU.getEntry
          TESTTAILCALLSTATIC_ML0001_FUNINFO
          TESTTAILCALLSTATIC_ML0001_SOURCE
          TESTTAILCALLSTATIC_ML0001_ENVENTRYNAME
  val TESTTAILCALLSTATIC_ML0001_ARGS =
      map
          (ATU.getEntry
               TESTTAILCALLSTATIC_ML0001_FUNINFO
               TESTTAILCALLSTATIC_ML0001_SOURCE)
          TESTTAILCALLSTATIC_ML0001_ARGNAMES
  val TESTTAILCALLSTATIC_ML0001_EXPECTED =
      (ATU.assembledFunInfo
           TESTTAILCALLSTATIC_ML0001_FUNINFO
           TESTTAILCALLSTATIC_ML0001_SOURCE) ::
      [
        I.TailCallStatic_ML_S
        {
          argsCount =
          UInt32.fromInt(List.length TESTTAILCALLSTATIC_ML0001_ARGS),
          envOffset = TESTTAILCALLSTATIC_ML0001_ENVENTRY,
          entryPoint = ATU.funEntrySize TESTTAILCALLSTATIC_ML0001_FUNINFO,
          argOffsets = TESTTAILCALLSTATIC_ML0001_ARGS
        }
      ]

  fun testTailCallStatic_ML0001() =
      (
        ATU.assertEqualInstructionList
        TESTTAILCALLSTATIC_ML0001_EXPECTED
        (assemble TESTTAILCALLSTATIC_ML0001_FUNINFO TESTTAILCALLSTATIC_ML0001_SOURCE);
        ()
      )

  (****************************************)

  val TESTMAKEBLOCK0001_FUNINFO =
      ATU.makeMonoFunInfo
      {pointers = ["v"], atoms = ["b", "s", "x", "xs", "y", "ys", "z", "zs"]}
  val TESTMAKEBLOCK0001_FIELD_ENTRIES = ["x", "y", "z"]
  val TESTMAKEBLOCK0001_FIELDSIZE_ENTRIES = ["xs", "ys", "zs"]
  val TESTMAKEBLOCK0001_SOURCE =
      [
        SI.MakeBlock
            {
              fieldsCount =
              UInt32.fromInt(List.length TESTMAKEBLOCK0001_FIELD_ENTRIES),
              bitmapEntry = ATU.makeVarInfo "b",
              sizeEntry = ATU.makeVarInfo "s",
              fieldEntries =
              map ATU.makeVarInfo TESTMAKEBLOCK0001_FIELD_ENTRIES,
              fieldSizeEntries =
              map ATU.makeVarInfo TESTMAKEBLOCK0001_FIELDSIZE_ENTRIES,
              destination = ATU.makeVarInfo "v"
            }
      ]
  val TESTMAKEBLOCK0001_BITMAP =
      ATU.getEntry TESTMAKEBLOCK0001_FUNINFO TESTMAKEBLOCK0001_SOURCE "b"
  val TESTMAKEBLOCK0001_SIZE =
      ATU.getEntry TESTMAKEBLOCK0001_FUNINFO TESTMAKEBLOCK0001_SOURCE "s"
  val TESTMAKEBLOCK0001_FIELDS =
      map
          (ATU.getEntry TESTMAKEBLOCK0001_FUNINFO TESTMAKEBLOCK0001_SOURCE)
          TESTMAKEBLOCK0001_FIELD_ENTRIES
  val TESTMAKEBLOCK0001_FIELDSIZES =
      map
          (ATU.getEntry TESTMAKEBLOCK0001_FUNINFO TESTMAKEBLOCK0001_SOURCE)
          TESTMAKEBLOCK0001_FIELDSIZE_ENTRIES
  val TESTMAKEBLOCK0001_DESTINATION =
      ATU.getEntry
          TESTMAKEBLOCK0001_FUNINFO TESTMAKEBLOCK0001_SOURCE "v"
  val TESTMAKEBLOCK0001_EXPECTED =
      (ATU.assembledFunInfo TESTMAKEBLOCK0001_FUNINFO TESTMAKEBLOCK0001_SOURCE) ::
      [
        I.MakeBlock
        {
          bitmapIndex = TESTMAKEBLOCK0001_BITMAP,
          sizeIndex = TESTMAKEBLOCK0001_SIZE,
          fieldsCount = 0w3,
          fieldIndexes = TESTMAKEBLOCK0001_FIELDS,
          fieldSizeIndexes = TESTMAKEBLOCK0001_FIELDSIZES,
          destination = TESTMAKEBLOCK0001_DESTINATION
        }
      ]

  fun testMakeBlock0001() =
      (
        ATU.assertEqualInstructionList
        TESTMAKEBLOCK0001_EXPECTED
        (assemble TESTMAKEBLOCK0001_FUNINFO TESTMAKEBLOCK0001_SOURCE);
        ()
      )

  (****************************************)

  val TESTMAKEARRAY0001_FUNINFO =
      ATU.makeMonoFunInfo {pointers = ["v"], atoms = ["b", "s", "i"]}
  val TESTMAKEARRAY0001_SOURCE =
      [
        SI.MakeArray
            {
              bitmapEntry = ATU.makeVarInfo "b",
              sizeEntry = ATU.makeVarInfo "s",
              initialValueEntry = ATU.makeVarInfo "i",
              initialValueSize = SI.SINGLE,
              destination = ATU.makeVarInfo "v"
            }
      ]
  val TESTMAKEARRAY0001_BITMAP =
      ATU.getEntry TESTMAKEARRAY0001_FUNINFO TESTMAKEARRAY0001_SOURCE "b"
  val TESTMAKEARRAY0001_SIZE =
      ATU.getEntry TESTMAKEARRAY0001_FUNINFO TESTMAKEARRAY0001_SOURCE "s"
  val TESTMAKEARRAY0001_INITIAL_VALUE =
      ATU.getEntry TESTMAKEARRAY0001_FUNINFO TESTMAKEARRAY0001_SOURCE "i"
  val TESTMAKEARRAY0001_DESTINATION =
      ATU.getEntry
          TESTMAKEARRAY0001_FUNINFO TESTMAKEARRAY0001_SOURCE "v"
  val TESTMAKEARRAY0001_EXPECTED =
      (ATU.assembledFunInfo TESTMAKEARRAY0001_FUNINFO TESTMAKEARRAY0001_SOURCE) ::
      [
        I.MakeArray_S
        {
          sizeIndex = TESTMAKEARRAY0001_SIZE,
          bitmapIndex = TESTMAKEARRAY0001_BITMAP,
          initialValueIndex = TESTMAKEARRAY0001_INITIAL_VALUE,
          destination = TESTMAKEARRAY0001_DESTINATION
        }
      ]

  fun testMakeArray0001() =
      (
        ATU.assertEqualInstructionList
        TESTMAKEARRAY0001_EXPECTED
        (assemble TESTMAKEARRAY0001_FUNINFO TESTMAKEARRAY0001_SOURCE);
        ()
      )

  (****************************************)

  val TESTMAKECLOSURE0001_FUNINFO =
      ATU.makeMonoFunInfo {pointers = ["e", "v"], atoms = []}
  val TESTMAKECLOSURE0001_SOURCE =
      [
        SI.Label (ATU.nameToAddress "h"),
        SI.MakeClosure
            {
              entryPoint = ATU.nameToAddress "h",
              ENVEntry = ATU.makeVarInfo "e",
              destination = ATU.makeVarInfo "v"
            }
      ]
  val TESTMAKECLOSURE0001_ENV =
      ATU.getEntry
          TESTMAKECLOSURE0001_FUNINFO TESTMAKECLOSURE0001_SOURCE "e"
  val TESTMAKECLOSURE0001_DESTINATION =
      ATU.getEntry
          TESTMAKECLOSURE0001_FUNINFO TESTMAKECLOSURE0001_SOURCE "v"
  val TESTMAKECLOSURE0001_EXPECTED =
      (ATU.assembledFunInfo
           TESTMAKECLOSURE0001_FUNINFO
           TESTMAKECLOSURE0001_SOURCE) ::
      [
        I.MakeClosure
        {
          entryPoint = ATU.funEntrySize TESTMAKECLOSURE0001_FUNINFO,
          ENVOffset = TESTMAKECLOSURE0001_ENV,
          destination = TESTMAKECLOSURE0001_DESTINATION
        }
      ]

  fun testMakeClosure0001() =
      (
        ATU.assertEqualInstructionList
        TESTMAKECLOSURE0001_EXPECTED
        (assemble TESTMAKECLOSURE0001_FUNINFO TESTMAKECLOSURE0001_SOURCE);
        ()
      )

  (****************************************)

  val TESTRAISE0001_FUNINFO =
      ATU.makeMonoFunInfo {pointers = ["e"], atoms = []}
  val TESTRAISE0001_SOURCE =
      [
        SI.Raise { exceptionEntry = ATU.makeVarInfo "e" }
      ]
  val TESTRAISE0001_EXCEPTION =
      ATU.getEntry TESTRAISE0001_FUNINFO TESTRAISE0001_SOURCE "e"
  val TESTRAISE0001_EXPECTED =
      (ATU.assembledFunInfo TESTRAISE0001_FUNINFO TESTRAISE0001_SOURCE) ::
      [
        I.Raise
        {
          exceptionOffset = TESTRAISE0001_EXCEPTION
        }
      ]

  fun testRaise0001() =
      (
        ATU.assertEqualInstructionList
        TESTRAISE0001_EXPECTED
        (assemble TESTRAISE0001_FUNINFO TESTRAISE0001_SOURCE);
        ()
      )

  (****************************************)

  val TESTPUSHHANDLER0001_FUNINFO =
      ATU.makeMonoFunInfo {pointers = ["e"], atoms = []}
  val TESTPUSHHANDLER0001_SOURCE =
      [
        SI.Label (ATU.nameToAddress "h"),
        SI.PushHandler
            {
              handler = ATU.nameToAddress "h",
              exceptionEntry = ATU.makeVarInfo "e"
            }
      ]
  val TESTPUSHHANDLER0001_EXCEPTION =
      ATU.getEntry TESTPUSHHANDLER0001_FUNINFO TESTPUSHHANDLER0001_SOURCE "e"
  val TESTPUSHHANDLER0001_EXPECTED =
      (ATU.assembledFunInfo
           TESTPUSHHANDLER0001_FUNINFO
           TESTPUSHHANDLER0001_SOURCE) ::
      [
        I.PushHandler
        {
          handler = ATU.funEntrySize TESTPUSHHANDLER0001_FUNINFO,
          exceptionOffset = TESTPUSHHANDLER0001_EXCEPTION
        }
      ]

  fun testPushHandler0001() =
      (
        ATU.assertEqualInstructionList
        TESTPUSHHANDLER0001_EXPECTED
        (assemble TESTPUSHHANDLER0001_FUNINFO TESTPUSHHANDLER0001_SOURCE);
        ()
      )

  (****************************************)

  val TESTPOPHANDLER0001_FUNINFO =
      ATU.makeMonoFunInfo {pointers = [], atoms = []}
  val TESTPOPHANDLER0001_SOURCE = [SI.PopHandler]
  val TESTPOPHANDLER0001_EXPECTED =
      (ATU.assembledFunInfo
           TESTPOPHANDLER0001_FUNINFO TESTPOPHANDLER0001_SOURCE) ::
      [I.PopHandler]

  fun testPopHandler0001() =
      (
        ATU.assertEqualInstructionList
        TESTPOPHANDLER0001_EXPECTED
        (assemble TESTPOPHANDLER0001_FUNINFO TESTPOPHANDLER0001_SOURCE);
        ()
      )

  (****************************************)

  val TESTSWITCHINT0001_FUNINFO =
      ATU.makeMonoFunInfo {pointers = [], atoms = ["t"]}
  val TESTSWITCHINT0001_CONSTS = [1 : BT.SInt32, 2, 3]
  val TESTSWITCHINT0001_SOURCE =
      [
        SI.Label (ATU.nameToAddress "h"),
        SI.SwitchInt
            {
              targetEntry = ATU.makeVarInfo "t",
              casesCount =
              UInt32.fromInt(List.length TESTSWITCHINT0001_CONSTS),
              cases =
              map
                  (fn const =>
                      {const = const ,destination = ATU.nameToAddress"h"})
                  TESTSWITCHINT0001_CONSTS,
             default = ATU.nameToAddress"h"
           }
      ]
  val TESTSWITCHINT0001_TARGET = 
      ATU.getEntry TESTSWITCHINT0001_FUNINFO TESTSWITCHINT0001_SOURCE "t"
  val TESTSWITCHINT0001_DESTINATION_OFFSET =
      ATU.funEntrySize TESTSWITCHINT0001_FUNINFO
  val TESTSWITCHINT0001_EXPECTED =
      (ATU.assembledFunInfo
           TESTSWITCHINT0001_FUNINFO
           TESTSWITCHINT0001_SOURCE) ::
      [
        I.SwitchInt
        {
          targetOffset = TESTSWITCHINT0001_TARGET,
          casesCount =
          UInt32.fromInt(List.length TESTSWITCHINT0001_CONSTS),
          cases =
          List.concat
          (map
           (fn const =>
               [
                 const,
                 BT.UInt32ToSInt32(TESTSWITCHINT0001_DESTINATION_OFFSET)
               ])
           TESTSWITCHINT0001_CONSTS),
          default = TESTSWITCHINT0001_DESTINATION_OFFSET
        }
      ]

  fun testSwitchInt0001() =
      (
        ATU.assertEqualInstructionList
        TESTSWITCHINT0001_EXPECTED
        (assemble TESTSWITCHINT0001_FUNINFO TESTSWITCHINT0001_SOURCE);
        ()
      )

  (****************************************)

  val TESTSWITCHWORD0001_FUNINFO =
      ATU.makeMonoFunInfo {pointers = [], atoms = ["t"]}
  val TESTSWITCHWORD0001_CONSTS = [0w1 : BT.UInt32, 0w2, 0w3]
  val TESTSWITCHWORD0001_SOURCE =
      [
        SI.Label (ATU.nameToAddress "h"),
        SI.SwitchWord
            {
              targetEntry = ATU.makeVarInfo "t",
              casesCount =
              UInt32.fromInt(List.length TESTSWITCHWORD0001_CONSTS),
              cases =
              map
                  (fn const =>
                      {const = const, destination = ATU.nameToAddress "h"})
                  TESTSWITCHWORD0001_CONSTS,
             default = ATU.nameToAddress "h"
           }
      ]
  val TESTSWITCHWORD0001_TARGET = 
      ATU.getEntry TESTSWITCHWORD0001_FUNINFO TESTSWITCHWORD0001_SOURCE "t"
  val TESTSWITCHWORD0001_DESTINATION_OFFSET =
      ATU.funEntrySize TESTSWITCHWORD0001_FUNINFO
  val TESTSWITCHWORD0001_EXPECTED =
      (ATU.assembledFunInfo
           TESTSWITCHWORD0001_FUNINFO
           TESTSWITCHWORD0001_SOURCE) ::
      [
        I.SwitchWord
        {
          targetOffset = TESTSWITCHWORD0001_TARGET,
          casesCount =
          UInt32.fromInt(List.length TESTSWITCHWORD0001_CONSTS),
          cases =
          List.concat
          (map
           (fn const => [const, TESTSWITCHWORD0001_DESTINATION_OFFSET])
           TESTSWITCHWORD0001_CONSTS),
          default = TESTSWITCHWORD0001_DESTINATION_OFFSET
        }
      ]

  fun testSwitchWord0001() =
      (
        ATU.assertEqualInstructionList
        TESTSWITCHWORD0001_EXPECTED
        (assemble TESTSWITCHWORD0001_FUNINFO TESTSWITCHWORD0001_SOURCE);
        ()
      )

  (****************************************)

  val TESTSWITCHCHAR0001_FUNINFO =
      ATU.makeMonoFunInfo {pointers = [], atoms = ["t"]}
  val TESTSWITCHCHAR0001_CONSTS = [0w1 : BT.UInt32, 0w2, 0w3]
  val TESTSWITCHCHAR0001_SOURCE =
      [
        SI.Label (ATU.nameToAddress "h"),
        SI.SwitchChar
            {
              targetEntry = ATU.makeVarInfo "t",
              casesCount =
              UInt32.fromInt(List.length TESTSWITCHCHAR0001_CONSTS),
              cases =
              map
                  (fn const =>
                      {const = const ,destination = ATU.nameToAddress "h"})
                  TESTSWITCHCHAR0001_CONSTS,
             default = ATU.nameToAddress "h"
           }
      ]
  val TESTSWITCHCHAR0001_TARGET = 
      ATU.getEntry TESTSWITCHCHAR0001_FUNINFO TESTSWITCHCHAR0001_SOURCE "t"
  val TESTSWITCHCHAR0001_DESTINATION_OFFSET =
      ATU.funEntrySize TESTSWITCHCHAR0001_FUNINFO
  val TESTSWITCHCHAR0001_EXPECTED =
      (ATU.assembledFunInfo
           TESTSWITCHCHAR0001_FUNINFO
           TESTSWITCHCHAR0001_SOURCE) ::
      [
        I.SwitchChar
        {
          targetOffset = TESTSWITCHCHAR0001_TARGET,
          casesCount =
          UInt32.fromInt(List.length TESTSWITCHCHAR0001_CONSTS),
          cases =
          List.concat
          (map
           (fn const => [const, TESTSWITCHCHAR0001_DESTINATION_OFFSET])
           TESTSWITCHCHAR0001_CONSTS),
          default = TESTSWITCHCHAR0001_DESTINATION_OFFSET
        }
      ]

  fun testSwitchChar0001() =
      (
        ATU.assertEqualInstructionList
        TESTSWITCHCHAR0001_EXPECTED
        (assemble TESTSWITCHCHAR0001_FUNINFO TESTSWITCHCHAR0001_SOURCE);
        ()
      )

  (****************************************)

  val TESTSWITCHSTRING0001_FUNINFO =
      ATU.makeMonoFunInfo {pointers = [], atoms = ["t"]}
  val TESTSWITCHSTRING0001_CONSTS_COUNT = 3
  val TESTSWITCHSTRING0001_SOURCE =
      [
        SI.Label (ATU.nameToAddress "h"),
        SI.SwitchString
            {
              targetEntry = ATU.makeVarInfo "t",
              casesCount = UInt32.fromInt TESTSWITCHSTRING0001_CONSTS_COUNT,
              cases =
              List.tabulate
                  (
                    TESTSWITCHSTRING0001_CONSTS_COUNT,
                    (fn _ =>
                        {
                          const = ATU.nameToAddress "h" ,
                          destination = ATU.nameToAddress "h"
                        })
                  ),
             default = ATU.nameToAddress "h"
           }
      ]
  val TESTSWITCHSTRING0001_TARGET = 
      ATU.getEntry
          TESTSWITCHSTRING0001_FUNINFO TESTSWITCHSTRING0001_SOURCE "t"
  val TESTSWITCHSTRING0001_DESTINATION_OFFSET =
      ATU.funEntrySize TESTSWITCHSTRING0001_FUNINFO
  val TESTSWITCHSTRING0001_EXPECTED =
      (ATU.assembledFunInfo
           TESTSWITCHSTRING0001_FUNINFO
           TESTSWITCHSTRING0001_SOURCE) ::
      [
        I.SwitchString
        {
          targetOffset = TESTSWITCHSTRING0001_TARGET,
          casesCount = UInt32.fromInt TESTSWITCHSTRING0001_CONSTS_COUNT,
          cases =
          List.concat
          (List.tabulate
           (
             TESTSWITCHSTRING0001_CONSTS_COUNT, 
             (fn _ =>
                 [
                   TESTSWITCHSTRING0001_DESTINATION_OFFSET,
                   TESTSWITCHSTRING0001_DESTINATION_OFFSET
                 ])
           )),
          default = TESTSWITCHSTRING0001_DESTINATION_OFFSET
        }
      ]

  fun testSwitchString0001() =
      (
        ATU.assertEqualInstructionList
        TESTSWITCHSTRING0001_EXPECTED
        (assemble TESTSWITCHSTRING0001_FUNINFO TESTSWITCHSTRING0001_SOURCE);
        ()
      )

  (****************************************)

  val TESTJUMP0001_FUNINFO = ATU.makeMonoFunInfo {pointers = [], atoms = []}
  val TESTJUMP0001_SOURCE =
      [
        SI.Label (ATU.nameToAddress "h"),
        SI.Jump { destination = ATU.nameToAddress "h" }
      ]
  val TESTJUMP0001_EXPECTED =
      (ATU.assembledFunInfo TESTJUMP0001_FUNINFO TESTJUMP0001_SOURCE) ::
      [
        I.Jump
        {
          destination = ATU.funEntrySize TESTJUMP0001_FUNINFO
        }
      ]

  fun testJump0001() =
      (
        ATU.assertEqualInstructionList
        TESTJUMP0001_EXPECTED
        (assemble TESTJUMP0001_FUNINFO TESTJUMP0001_SOURCE);
        ()
      )

  (****************************************)

  val TESTEXIT0001_FUNINFO = ATU.makeMonoFunInfo {pointers = [], atoms = []}
  val TESTEXIT0001_SOURCE =
      [
        SI.Exit
      ]
  val TESTEXIT0001_EXPECTED =
      (ATU.assembledFunInfo TESTEXIT0001_FUNINFO TESTEXIT0001_SOURCE) ::
      [I.Exit]

  fun testExit0001() =
      (
        ATU.assertEqualInstructionList
        TESTEXIT0001_EXPECTED
        (assemble TESTEXIT0001_FUNINFO TESTEXIT0001_SOURCE);
        ()
      )

  (****************************************)

  val TESTRETURN0001_FUNINFO =
      ATU.makeMonoFunInfo {pointers = [], atoms = ["r"]}
  val TESTRETURN0001_SOURCE =
      [
        SI.Return
            { variableEntry = ATU.makeVarInfo "r", variableSize = SI.SINGLE }
      ]
  val TESTRETURN0001_VARIABLE =
      ATU.getEntry TESTRETURN0001_FUNINFO TESTRETURN0001_SOURCE "r"
  val TESTRETURN0001_EXPECTED =
      (ATU.assembledFunInfo TESTRETURN0001_FUNINFO TESTRETURN0001_SOURCE) ::
      [
        I.Return_S
        {
          variableOffset = TESTRETURN0001_VARIABLE
        }
      ]

  fun testReturn0001() =
      (
        ATU.assertEqualInstructionList
        TESTRETURN0001_EXPECTED
        (assemble TESTRETURN0001_FUNINFO TESTRETURN0001_SOURCE);
        ()
      )

  (***************************************************************************)

  fun suite () =
      Test.labelTests
      [
        ("testLoadInt0001", testLoadInt0001),
        ("testLoadWord0001", testLoadWord0001),
        ("testLoadString0001", testLoadString0001),
(*
        ("testLoadReal0001", testLoadReal0001),
*)
        ("testLoadChar0001", testLoadChar0001),
        ("testAccess0001", testAccess0001),
        ("testAccessEnv0001", testAccessEnv0001),
        ("testGetField0001", testGetField0001),
        ("testGetFieldIndirect0001", testGetFieldIndirect0001),
(*
        ("testCopyAndUpdateField0001", testCopyAndUpdateField0001),
        (
          "testCopyAndUpdateFieldIndirect0001",
          testCopyAndUpdateFieldIndirect0001
        ),
*)
        ("testSetField0001", testSetField0001),
        ("testSetFieldIndirect0001", testSetFieldIndirect0001),
        ("testGetGlobal0001", testGetGlobal0001),
        ("testSetGlobal0001", testSetGlobal0001),
        ("testGetEnv0001", testGetEnv0001),
        ("testCallPrim0001", testCallPrim0001),
        ("testApply_ML0001", testApply_ML0001),
        ("testTailApply_ML0001", testTailApply_ML0001),
        ("testCallStatic_ML0001", testCallStatic_ML0001),
        ("testTailCallStatic_ML0001", testTailCallStatic_ML0001),
        ("testMakeBlock0001", testMakeBlock0001),
        ("testMakeArray0001", testMakeArray0001),
        ("testMakeClosure0001", testMakeClosure0001),
        ("testRaise0001", testRaise0001),
        ("testPushHandler0001", testPushHandler0001),
        ("testPopHandler0001", testPopHandler0001),
        ("testSwitchInt0001", testSwitchInt0001),
        ("testSwitchWord0001", testSwitchWord0001),
        ("testSwitchChar0001", testSwitchChar0001),
        ("testSwitchString0001", testSwitchString0001),
        ("testJump0001", testJump0001),
        ("testExit0001", testExit0001),
        ("testReturn0001", testReturn0001),
        ("testConstString0001", testConstString0001)
      ]

  (***************************************************************************)

end