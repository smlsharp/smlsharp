structure Control =
struct

  val source = ref NONE : InsnDef.source option ref

  exception Bug of string
  exception Error of (InsnDef.pos * string) list

  fun getLoc pos =
      InsnDef.loc (valOf (!source), pos)

  fun loc pos =
      InsnDef.locToString (getLoc pos)

  fun printError msgs =
      app (fn (pos, msg) =>
              TextIO.output (TextIO.stdErr, loc pos ^ ": " ^ msg ^ "\n"))
          msgs

end
