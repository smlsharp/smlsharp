(**
 * @author YAMATODANI Kiyoshi
 * @copyright 2010, Tohoku University.
 * @version $Id: FFITest.sml,v 1.1 2007/05/20 03:53:25 kiyoshiy Exp $
 *)
structure FFITest =
struct

  open SMLUnit.Test

  fun suite () =
      TestList
      [
        TestLabel ("NativeDataTransporterTest0001",
                   NativeDataTransporterTest0001.suite ()),
        TestLabel ("NativeDataTransporterTest0002",
                   NativeDataTransporterTest0002.suite ())
      ]

end