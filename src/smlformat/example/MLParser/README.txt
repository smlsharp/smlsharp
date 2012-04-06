SMLFormat sample: Core ML parser

Running.

1) make SMLFormat at the package root directory

 $ make

2) generate formatter

 $ ./bin/smlformat example/MLParser/Absyn.ppg

3) change the working directory.

 $ cd example/MLParser

4) start sml.

 $ sml-cm

5) make the sample.

 - CM.make();

6) run the main function.

 - Main.main();

7) The prompt '->' will be displayed.
  Input some ML code. (Only core syntax is supported.)
  The code you input will be printed.
  The text is formatted to fit within 40(default) colums.

  -> case x = 1 of SOME(NONE x) => x + 1 * 2 | {x = 1, y, z} => let val a = 1 in f(g(h)) end;

  Formatted Code:

  val 
  it =
  case x = 1
    of SOME NONE x => x + 1 * 2
     | {x = 1, y :  as , z :  as } =>
       let val  a = 1 in f (g h) end

  ->fun f x = 1 | f (1, 2, 3) = {a = 1, s ="abcdefghijkmlllll"} | f (a, b) = a;

  Formatted Code:

  fun  f x = 1
     | f (1, 2, 3) =
       {a = 1, s = "abcdefghijkmlllll"}
     | f (a, b) = a

  ->

8) By "use" command, expressions in a file is loaded.

 - use "SampleInput.txt"

9) Some options are supported to change behavior of the parser.

 the column width can be changed by 'columns' command.
 - set columns 80;

 if 'verbose' option is set, the format expression is displayed.
 - set verbose "true";

 to reset 'verbose' option.
 - set verbose "false";

 to exit session.
 - exit;

10) The session finishes by ^C.

===============================================================================
