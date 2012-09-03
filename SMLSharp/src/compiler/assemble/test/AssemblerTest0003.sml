(**
 *  Verifies that the assembler translates instruction's operands which points
 * at some location in the code sequence to its absolute address (or its offset
 * for relative jump instructions).
 * @author YAMATODANI Kiyoshi
 * @version $Id: AssemblerTest0003.sml,v 1.2 2005/03/22 02:10:01 kiyoshiy Exp $
 *)
structure AssemblerTest0003 =
struct

  (***************************************************************************)

  open BasicTypes
  open AssemblerTestUtil

  (***************************************************************************)

  structure Assert = SMLUnit.Assert
  structure Test = SMLUnit.Test

  structure Testee = Assembler

  structure SI = SymbolicInstructions
  structure I = Instructions

  (***************************************************************************)

  val TESTLABELREF0001_ARG =
      [
        SI.Label "top",
        SI.Nop,
        SI.Jump {destination = SI.LabelRef "top"}
      ]
  val TESTLABELREF0001_EXPECTED =
      [
        I.Nop {padding = 0w0},
        I.Jump {padding = 0w0, destination = 0w0}
      ]

  fun testLabelRef0001() =
      (
        assertEqualInstructionList
        TESTLABELREF0001_EXPECTED
        (Testee.assemble TESTLABELREF0001_ARG);
        ()
      )

  (****************************************)

  val TESTLABELREF0002_ARG =
      [
        SI.Jump {destination = SI.LabelRef "top"},
        SI.Nop,
        SI.Label "top"
      ]
  val TESTLABELREF0002_EXPECTED =
      [
        I.Jump {padding = 0w0, destination = 0w3},
        I.Nop {padding = 0w0}
      ]

  fun testLabelRef0002() =
      (
        assertEqualInstructionList
        TESTLABELREF0002_EXPECTED
        (Testee.assemble TESTLABELREF0002_ARG);
        ()
      )

  (***************************************************************************)

  fun suite () =
      Test.labelTests
      [
        ("testLabelRef0001", testLabelRef0001),
        ("testLabelRef0002", testLabelRef0002),
        ("testRelative0001", testRelative0001),
        ("testRelative0002", testRelative0002),
        ("testAbsolute0001", testAbsolute0001),
        ("testAbsolute0002", testAbsolute0002)
      ]

  (***************************************************************************)

end
