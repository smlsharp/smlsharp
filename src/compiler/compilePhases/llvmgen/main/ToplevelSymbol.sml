(**
 * symbol names constituting object toplevel
 *
 * @copyright (c) 2017, Tohoku University.
 * @author UENO Katsuhiro
 *)
structure ToplevelSymbol =
struct

  fun moduleId NONE = ""
    | moduleId (SOME ({source=(_,file), hash}:InterfaceName.interface_name)) =
      let
        val filename =
            String.translate
              (fn c => if Char.isAlphaNum c then str c else "_")
              (Filename.toString
                 (Filename.removeSuffix (Filename.basename file)))
        val hash = InterfaceName.hashToString hash
      in
        hash ^ "_" ^ filename
      end

  fun mainName name = "_SML_main" ^ moduleId name
  fun ftabName name = "_SML_ftab" ^ moduleId name
  fun tabbName name = "_SML_tabb" ^ moduleId name
  fun loadName name = "_SML_load" ^ moduleId name
  fun doneName name = "_SML_done" ^ moduleId name
  fun rootName name = "_SML_root" ^ moduleId name
  fun gvarName name = "_SML_gvar" ^ moduleId name

end
