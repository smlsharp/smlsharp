(**
 * @author YAMATODANI Kiyoshi
 * @version $Id: InstructionsTest.sml,v 1.2 2006/01/02 07:13:27 kiyoshiy Exp $
 *)
structure InstructionsTest =
struct

  open SMLUnit.Test

  fun suite () =
      TestList
      [
        TestLabel
            (
              "PrimitiveSerializerLittleEndianTest001",
              PrimitiveSerializerLittleEndianTest001.suite ()
            ),
        TestLabel
            (
              "PrimitiveSerializerBigEndianTest001",
              PrimitiveSerializerBigEndianTest001.suite ()
            )
      ]

end