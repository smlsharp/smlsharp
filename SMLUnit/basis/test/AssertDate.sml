(**
 * assertions for types defined in Date.
 *
 * @author YAMATODANI Kiyoshi
 * @copyright 2010, Tohoku University.
 *)
structure AssertDate
  : sig

    (****************************************)

    (**
     * Asserts that two Date.weekday values are equal.
     *)
    val assertEqualWeekday : Date.weekday SMLUnit.Assert.assertEqual

    (**
     * Asserts that two Date.month values are equal.
     *)
    val assertEqualMonth : Date.month SMLUnit.Assert.assertEqual

    (**
     * Asserts that two Date.date values are equal.
     *)
    val assertEqualDate : Date.date SMLUnit.Assert.assertEqual

    end =
struct

  (****************************************)

  structure A = SMLUnit.Assert

  (****************************************)

  fun weekdayToString Date.Mon = "Mon"
    | weekdayToString Date.Tue = "Tue"
    | weekdayToString Date.Wed = "Wed"
    | weekdayToString Date.Thu = "Thu"
    | weekdayToString Date.Fri = "Fri"
    | weekdayToString Date.Sat = "Sat"
    | weekdayToString Date.Sun = "Sun"

  fun monthToString Date.Jan = "Jan"
    | monthToString Date.Feb = "Feb"
    | monthToString Date.Mar = "Mar"
    | monthToString Date.Apr = "Apr"
    | monthToString Date.May = "May"
    | monthToString Date.Jun = "Jun"
    | monthToString Date.Jul = "Jul"
    | monthToString Date.Aug = "Aug"
    | monthToString Date.Sep = "Sep"
    | monthToString Date.Oct = "Oct"
    | monthToString Date.Nov = "Nov"
    | monthToString Date.Dec = "Dec"

  val assertEqualWeekday =
      A.assertEqual (fn (x, y) => x = y) weekdayToString

  val assertEqualMonth =
      A.assertEqual (fn (x, y) => x = y) monthToString

  val assertEqualDate =
      A.assertEqualByCompare Date.compare Date.toString

  (****************************************)

end;