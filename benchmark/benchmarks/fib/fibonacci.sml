fun fibonacci 0 = 1
  | fibonacci 1 = 1
  | fibonacci n = fibonacci (n - 1) + fibonacci (n - 2);

val x = fibonacci 40;

fun doit () = ignore (fibonacci 40)

fun testit out =
    TextIO.output (out, Int.toString (fibonacci 40))
