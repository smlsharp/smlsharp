SMLPPG sample: FormatExpression parser

Running.

1) change the working directory.

 $ cd example/FormatExpressionParser

2) start sml.

 $ sml-cm

3) make the sample.

 - CM.make();

4) run the main function.

 - Main.main();

5) The prompt '->' will be displayed.
  Input format expressions.
  The formatted text representation of the expression you input will be
 printed.

 ->print "123" 2[ 1 "456" 3[ 1 "789"] "abc" 2[ 1 "def"]];
 123
   456
      789abc
     def

6) By "use" command, expressions in a file is loaded.

 - use "SampleInput.txt"

7) Some options are supported to change behavior of the parser.

 the column width can be changed by 'columns' command.
 - set columns "80";

 to exit session.
 - exit;

===============================================================================
