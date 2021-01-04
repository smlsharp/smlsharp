fun parse filename =
    let
      val fname = Filename.fromString filename
      val file = openIn filename
      val source = {source = Loc.FILE (Loc.USERPATH, fname),
                    read = fn _ => input file,
                    initialLineno = 1}
      val input = Parser.setup source
      val result = Parser.parse input
                   handle e => (closeIn file; raise e)
    in
      closeIn file
    end
