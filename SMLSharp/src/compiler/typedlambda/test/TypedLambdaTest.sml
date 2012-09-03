(**
 * @author Liu Bochao
 * @version $Id: TypedLambdaTest.sml,v 1.1 2006/03/15 02:34:44 bochao Exp $
 *)
structure TypedLambdaTest =
struct

  open SMLUnit.Test

  fun suite () =
      TestList
      [
        TestLabel ("TypedLambdaPicklerTest001", TypedLambdaPicklerTest001.suite ())
      ]

end