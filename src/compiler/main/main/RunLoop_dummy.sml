(**
 * dummy RunLoop structure
 *
 * @copyright (c) 2011, Tohoku University.
 * @author UENO Katsuhiro
 *)
structure RunLoop : sig

  type options =
       {asmFlags : string list,
        systemBaseDir : Filename.filename,
        stdPath : Filename.filename list,
        loadPath : Filename.filename list,
        LDFLAGS : string list,
        LIBS : string list,
        errorOutput : TextIO.outstream}

  datatype result = SUCCESS of NameEvalEnv.topEnv | FAILED

  val available : unit -> bool
  val run : options -> Top.toplevelContext -> Parser.input -> result
  val interactive : options -> Top.toplevelContext -> unit

end =
struct

  type options =
       {asmFlags : string list,
        systemBaseDir : Filename.filename,
        stdPath : Filename.filename list,
        loadPath : Filename.filename list,
        LDFLAGS : string list,
        LIBS : string list,
        errorOutput : TextIO.outstream}

  datatype result = SUCCESS of NameEvalEnv.topEnv | FAILED

  fun available () = false

  fun run _ =
      raise Control.Bug "RunLoop_dummy: run"
  fun interactive _ =
      raise Control.Bug "RunLoop_dummy: interactive"

end
