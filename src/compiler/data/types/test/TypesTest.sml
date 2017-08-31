(**
 * @author YAMATODANI Kiyoshi
 * @version $Id: TypesTest.sml,v 1.1 2006/01/11 11:48:00 kiyoshiy Exp $
 *)
structure TypesTest =
struct

  open SMLUnit.Test

  fun suite () =
      TestList
      [
        TestLabel ("TypesPicklerTest001", TypesPicklerTest001.suite ())
      ]

end
