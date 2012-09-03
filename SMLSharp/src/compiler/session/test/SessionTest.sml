structure SessionTest =
struct

  open SMLUnit.Test

  fun suite () =
      TestList
      [
        TestLabel("ByteListChannelTest0001", ByteListChannelTest0001.suite ()),
        TestLabel
        ("StandAloneSessionTest0001", StandAloneSessionTest0001.suite())
      ]

end