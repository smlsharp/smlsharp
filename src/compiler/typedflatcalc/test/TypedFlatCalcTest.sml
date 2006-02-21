(**
 * @author YAMATODANI Kiyoshi
 * @version $Id: TypedFlatCalcTest.sml,v 1.1 2006/01/11 11:47:59 kiyoshiy Exp $
 *)
structure TypedFlatCalcTest =
struct

  open SMLUnit.Test

  fun suite () =
      TestList
      [
        TestLabel
            (
              "TypedFlatCalcPicklerTest001",
              TypedFlatCalcPicklerTest001.suite ()
            )
      ]

end