(**
 * @author YAMATODANI Kiyoshi
 * @version $Id: MultiByteStringTest.sml,v 1.1 2006/12/11 10:57:04 kiyoshiy Exp $
 *)
structure MultiByteStringTest =
struct

  open SMLUnit.Test

  fun suite () =
      TestList
      [
        TestLabel ("MBStringTest0001", MBStringTest0001.suite ()),
        TestLabel ("MBSubstringTest0001", MBSubstringTest0001.suite ())
      ]

end