(**
 * concurrency support code generation
 *
 * @copyright (c) 2014 Tohoku University.
 * @author UENO Katsuhiro
 *)
structure ConcurrencySupport : sig

  val insertCheckGC : MachineCode.program -> MachineCode.program

end =
struct

  (* ToDo: The algorithm is naive. Make it more sophisticated *)

  structure M = MachineCode

(*
  fun compileLast last =
      case last of
        M.MCRETURN {value, loc} => last
      | M.MCRAISE_THROW {raiseAllocResult, argExp, loc} => last
      | M.MCHANDLER {nextExp, id, exnVar, handlerExp, loc} =>
        M.MCHANDLER {nextExp = compileExp nextExp,
                     id = id,
                     exnVar = exnVar,
                     handlerExp = compileBody handlerExp,
                     loc = loc}
      | M.MCSWITCH {switchExp, expTy, branches, default, loc} => last
      | M.MCLOCALCODE {id, recursive, argVarList, bodyExp, nextExp, loc} =>
        M.MCLOCALCODE {id = id,
                       recursive = recursive,
                       argVarList = argVarList,
                       bodyExp = compileBody bodyExp,
                       nextExp = nextExp,
                       loc = loc}
      | M.MCGOTO {id, argList, loc} => last
      | M.MCUNREACHABLE => last

  and compileExp ((mids, last):M.mcexp) =
      (mids, compileLast last)

  and compileBody exp =
      let
        val (mids, last) = compileExp exp
      in
        (M.MCCHECK :: mids, last)
      end
*)

  fun compileBody ((mids, last):M.mcexp) =
      (M.MCCHECK :: mids, last)

  fun compileTopdec topdec =
      case topdec of
        M.MTFUNCTION {id, tyvarKindEnv, argVarList, closureEnvVar,
                      frameSlots, bodyExp, retTy, loc} =>
        M.MTFUNCTION {id = id,
                      tyvarKindEnv = tyvarKindEnv,
                      argVarList = argVarList,
                      closureEnvVar = closureEnvVar,
                      frameSlots = frameSlots,
                      bodyExp = compileBody bodyExp,
                      retTy = retTy,
                      loc = loc}
      | M.MTCALLBACKFUNCTION {id, tyvarKindEnv, argVarList, closureEnvVar,
                              frameSlots, bodyExp, attributes, retTy,
                              cleanupHandler, loc} =>
        M.MTCALLBACKFUNCTION {id = id,
                              tyvarKindEnv = tyvarKindEnv,
                              argVarList = argVarList,
                              closureEnvVar = closureEnvVar,
                              frameSlots = frameSlots,
                              bodyExp = compileBody bodyExp,
                              attributes = attributes,
                              retTy = retTy,
                              cleanupHandler = cleanupHandler,
                              loc = loc}

  fun compileToplevel {dependency, frameSlots, bodyExp, cleanupHandler} =
      {dependency = dependency,
       frameSlots = frameSlots,
       bodyExp = compileBody bodyExp,
       cleanupHandler = cleanupHandler} : M.toplevel

  fun insertCheckGC ({topdata, topdecs, toplevel}:M.program) =
      {topdata = topdata,
       topdecs = map compileTopdec topdecs,
       toplevel = compileToplevel toplevel} : M.program

end
