(**
 * @author YAMATODANI Kiyoshi
 * @copyright 2010, Tohoku University.
 *)
structure SMLFormatTestUtil =
struct

  local
  structure FE = SMLFormat.FormatExpression
  structure Assert = SMLUnit.Assert
  open Assert
  in
  val assertEqualAssoc =
      assertEqual (fn (left, right) => left = right) FE.assocToString
  val assertEqualPriority =
      assertEqual (fn (left, right) => left = right) FE.priorityToString
  fun assertEqualFormatExpression (FE.Term argLeft) (FE.Term argRight) =
      (assertEqual2Tuple(assertEqualInt, assertEqualString) argLeft argRight
       handle Fail(NotEqualFailure(textLeft, textRight)) =>
              failByNotEqual("Term " ^ textLeft, "Term " ^ textRight))
    | assertEqualFormatExpression (FE.Guard argLeft) (FE.Guard argRight) =
      ((assertEqual2Tuple
           (
             assertEqualOption assertEqualAssoc,
             assertEqualList assertEqualFormatExpression
           )
           argLeft
           argRight)
       handle Fail(NotEqualFailure(textLeft, textRight)) =>
              failByNotEqual("Guard " ^ textLeft, "Guard " ^ textRight))
    | assertEqualFormatExpression
          (FE.Indicator argLeft) (FE.Indicator argRight) =
      (
        (assertEqualBool (#space argLeft) (#space argRight))
        handle Fail(NotEqualFailure(textLeft, textRight)) =>
               failByNotEqual
                   ("Indicator{space = " ^ textLeft,
                    "Indicator{space = " ^ textRight);
        (assertEqualOption
             (fn {priority = leftPriority} => fn {priority = rightPriority} =>
                 assertEqualPriority leftPriority rightPriority)
             (#newline argLeft)
             (#newline argRight))
        handle Fail(NotEqualFailure(textLeft, textRight)) =>
               failByNotEqual
                   ("Indicator{newline = " ^ textLeft,
                    "Indicator{newline = " ^ textRight)
      )
    | assertEqualFormatExpression
          (FE.StartOfIndent argLeft) (FE.StartOfIndent argRight) =
      (assertEqualInt argLeft argRight
       handle Fail(NotEqualFailure(textLeft, textRight)) =>
              failByNotEqual
                  ("StartOfIndent " ^ textLeft, "StartOfIndent " ^ textRight))
    | assertEqualFormatExpression FE.EndOfIndent FE.EndOfIndent = ()
    | assertEqualFormatExpression left right =
      failByNotEqual(FE.toString left, FE.toString right)

  val assertEqualFormatExpressionList =
      assertEqualList assertEqualFormatExpression
  end

end