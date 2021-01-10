structure SMLRef =
struct
local
  structure DB = RefDBAccess
  structure C = Config
  structure D = Dynamic
in
  exception IlleagalLispFFICmd
  exception IlleagalArg

  val argJson = case CommandLine.arguments() of
                   hd::args => hd
                 | _ =>  ""
  val arg = Dynamic.fromJson argJson

  val defReturnTemplate = 
      {baseDir = "",
       version = "",
       systemName = "",
       rootFile = "",
       defList = nil : {category: string,
                        defFileName: string,
                        defPos: int,
                        kind: string} list
      }
  val refReturnTemplate = 
      {baseDir = "",
       version = "",
       systemName = "",
       rootFile = "",
       refList = nil : {refPos: int, refFileName: string} list
      }
       
(*
  val arg = {path = "/home/ohori/share/HG/smlsharp_PGSQLDynamic/smlsharp/src/compiler/compilePhases/elaborate/main/ElaborateCore.sml",
             pos = 48762,
             cmd = "findRef"
            }
  val arg = Dynamic.dynamic arg
*)

  fun smlRef () = 
      let
        val {cmd=cmd} = D.view (_dynamic arg as {cmd:string} D.dyn)
      in
        case cmd of
          "config" => 
          let
            val _ = Log.log "config\n"
            val responseJson = 
		Dynamic.valueToJson 
		    (Config.config ())
            val _ = Log.log (responseJson ^ "\n")
            val _ = print responseJson
          in
            ()
          end
        | "findDef" => 
          let
            val _ = Log.log "findDef\n"
            val arg = D.view (_dynamic arg as {path:string, pos:int} D.dyn)
            val _ = Log.log (Dynamic.format arg)
            val response = DB.findDef arg
            val responseJson = Dynamic.valueToJson response
            val _ = Log.log (responseJson ^ "\n")
            val _ = print responseJson
          in
            ()
          end
        | "findRef" => 
          let
            val _ = Log.log "findRef"
            val arg = D.view (_dynamic arg as {path:string, pos:int} D.dyn)
            val _ = Log.log (Dynamic.format arg)
            val response = DB.findRef arg
            val responseJson = Dynamic.valueToJson response
            val _ = Log.log (responseJson ^ "\n")
            val _ = print responseJson
          in
            ()
          end
        | "findDefEcho" => 
          let
            val _ = Log.log "findDefEcho\n"
            val arg = D.view (_dynamic arg as {path:string, pos:int} D.dyn)
            val response = DB.findDefEcho arg
            val responseJson = Dynamic.valueToJson response
            val _ = Log.log (responseJson ^ "\n")
            val _ = print responseJson
          in
            ()
          end
        | _ =>
          let
            val _ = print "illeagal command"
          in
            ()
          end
      end
  val _ = (smlRef (); Log.stopLogging())
end
end
