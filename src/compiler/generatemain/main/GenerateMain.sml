(**
 * GenerateMain.sml
 * @copyright (c) 2011, Tohoku University.
 * @author UENO Katsuhiro
 *)
structure GenerateMain : sig

  val generate : AbsynInterface.interfaceName list -> string
  val mainSymbol : AbsynInterface.compileUnit -> {mainSymbol: string}

end =
struct

  fun makeMainSymbol ({hash,...}:AbsynInterface.interfaceName) =
      "SMLmain" ^ hash

  fun mainSymbol ({interface={interfaceName,...}, topdecs}
                  : AbsynInterface.compileUnit) =
      case interfaceName of
        NONE => {mainSymbol = "SMLmain"}
      | SOME name => {mainSymbol = makeMainSymbol name}

  fun escape s =
      String.translate
        (fn c => if Char.isAlphaNum c orelse c = #"_"
                 then str c
                 else if ord c < 256
                 then "\\" ^ StringCvt.padLeft #"0" 3 (Int.toString (ord c))
                 else raise Control.Bug "escape")
        s

  fun generate interfaceNames =
      let
        val _ =
            foldl
              (fn ({hash, sourceName, place}, map) =>
                  case SEnv.find (map, hash) of
                    NONE => SEnv.insert (map, hash, sourceName)
                  | SOME prevName =>
                    raise UserError.UserErrorsWithoutLoc
                            [(UserError.Error,
                              GenerateMainError.HashConflict
                                (prevName, sourceName, hash))])
              SEnv.empty
              interfaceNames

        val decs =
            map (fn name =>
                    let
                      val mainSymbol = escape (makeMainSymbol name)
                    in
                      "val _ = (_import \"" ^ mainSymbol ^ "\" : () -> ()) ()\n"
                    end)
                interfaceNames
      in
        String.concat decs
      end
end
