(**
 *  Verifies that the assembler translates instruction's operands which denotes
 * entries in a stack frame to their indexes.
 * @author YAMATODANI Kiyoshi
 * @version $Id: AssemblerTest0002.sml,v 1.8 2006/02/20 06:52:03 kiyoshiy Exp $
 *)
structure AssemblerTest0002 =
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
  structure A = Absyn
  structure ATU = AssemblerTestUtil

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

  val TESTFUNINFO0001_FUNINFO =
       {
         args = map ATU.makeVarInfo ["a1", "a2", "p1"],
         bitmapvals =
         {
           args = map ATU.makeVarInfo ["a1", "a2"],
           frees = [0w3 : UInt32, 0w4]
         },
         pointers = map ATU.makeVarInfo ["p1", "p2"],
         atoms = map ATU.makeVarInfo ["a1", "a2"],
         doubles = map ATU.makeVarInfo ["d1", "d2"],
         records =
         [map ATU.makeVarInfo ["r1", "r2"], map ATU.makeVarInfo ["r3", "r4"]]
       } : SI.funInfo

  val TESTFUNINFO0001_EXPECTED =
      [ATU.assembledFunInfo TESTFUNINFO0001_FUNINFO []]

  fun testFunInfo0001() =
      (
        assertEqualInstructionList
        TESTFUNINFO0001_EXPECTED
        (assemble TESTFUNINFO0001_FUNINFO []);
        ()
      )

  (***************************************************************************)

  fun suite () =
      Test.labelTests
      [
        ("testFunInfo0001", testFunInfo0001)
      ]

  (***************************************************************************)

end
