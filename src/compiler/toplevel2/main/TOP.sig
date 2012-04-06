signature TOP =
sig

  datatype stopAt =
      SyntaxCheck                   (* run until syntax check is completed. *)
    | ErrorCheck                    (* run until error check is completed. *)
    | Assembly                      (* generate assembly file and return. *)
    | NoStop

  datatype code =
      FILE of Filename.filename     (* compile result is in a file. *)

  type interfaceNames =
      {
        provide: AbsynInterface.interfaceName option,
        requires: AbsynInterface.interfaceName list,
        depends: (AbsynInterface.filePlace * string) list
      }

  type toplevelOptions =
      {
        stopAt: stopAt,                      (* compile will stop here. *)
        dstfile: Filename.filename option,   (* preferred output file name *)
        baseName: Filename.filename option,  (* base name for file search *)
        stdPath: Filename.filename list,     (* standard path for file search *)
        loadPath: Filename.filename list,    (* user path for file search *)
        asmFlags: string list                (* flags for assembler *)
      }

  val defaultOptions : toplevelOptions

  type toplevelContext =
      {
        topEnv: NameEvalEnv.topEnv,
        version: int option,
        fixEnv: Elaborator.fixEnv,
        builtinDecls: IDCalc.icdecl list
      }

  type newContext =
      {
        topEnv: NameEvalEnv.topEnv,
        fixEnv: Elaborator.fixEnv
      }

  val emptyNewContext : newContext

  datatype result =
      STOPPED                        (* aborted due to stopAt. *)
    | RETURN of newContext * code    (* compile successfully finished *)

  val extendContext : toplevelContext * newContext -> toplevelContext

  (** read one compile unit from input and compile it. *)
  val compile : toplevelOptions
                -> toplevelContext
                -> Parser.input
                -> interfaceNames * result

  val loadInterface : {stopAt: stopAt,
                       stdPath: Filename.filename list,
                       loadPath: Filename.filename list}
                      -> toplevelContext
                      -> Filename.filename
                      -> interfaceNames * newContext option

(*
  val debugPrint : string -> unit
  val printStopAt : stopAt -> unit
  val printInterfaceNames : interfaceNames -> unit
  val printInterfaceName : AbsynInterface.interfaceName -> unit
  val printFileName : Filename.filename -> unit
  val printInterfaceNameList : AbsynInterface.interfaceName list -> unit
  val printResult : result -> unit
  val printToplevelOptions : toplevelOptions -> unit
  val printCompileUnit : AbsynInterface.compileUnit -> unit
*)
end 
