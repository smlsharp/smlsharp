structure SMLDocTest =
struct

  open SMLUnit.Test

  fun suite () =
      TestList
      [
        TestLabel("DependencyGraphTest0001", DependencyGraphTest0001.suite ()),
        TestLabel("EasyHTMLParserTest0001", EasyHTMLParserTest0001.suite ())
      ]

end