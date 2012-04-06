(**
 * @author YAMATODANI Kiyoshi
 * @copyright 2010, Tohoku University.
 *)
structure PPLibTest =
struct

  open SMLUnit.Test

  fun suite () =
      TestList
      [
        TestLabel("SMLFormatTest0001", SMLFormatTest0001.suite ()),
        TestLabel("SMLFormatTest0002", SMLFormatTest0002.suite ()),
        TestLabel("SMLFormatTest0003", SMLFormatTest0003.suite ()),
        TestLabel("SMLFormatTest0004", SMLFormatTest0004.suite ()),
        TestLabel("SMLFormatTest0005", SMLFormatTest0005.suite ()),
        TestLabel("SMLFormatTest0006", SMLFormatTest0006.suite ()),
        TestLabel("SMLFormatTest0007", SMLFormatTest0007.suite ()),
        TestLabel("SMLFormatTest0008", SMLFormatTest0008.suite ()),
        TestLabel("SMLFormatTest0009", SMLFormatTest0009.suite ()),
        TestLabel("SMLFormatTest0010", SMLFormatTest0010.suite ()),
        TestLabel("SMLFormatTest0011", SMLFormatTest0011.suite ()),

        TestLabel
        ("PrinterParameterTest0001", PrinterParameterTest0001.suite()),
        TestLabel
        ("PrinterParameterTest0002", PrinterParameterTest0002.suite()),

        TestLabel
        ("BasicFormattersTest0001", BasicFormattersTest0001.suite ())
      ]

end