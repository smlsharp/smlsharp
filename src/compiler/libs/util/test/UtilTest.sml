(**
 * @author YAMATODANI Kiyoshi
 * @version $Id: UtilTest.sml,v 1.1 2005/12/14 09:38:29 kiyoshiy Exp $
 *)
structure UtilTest =
struct

  open SMLUnit.Test

  fun suite () =
      TestList
      [
        TestLabel ("ListSorterTest0001", ListSorterTest0001.suite ())
      ]

end
