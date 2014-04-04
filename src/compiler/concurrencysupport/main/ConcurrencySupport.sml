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

  fun compileLast last =
      case last of
        M.MCRETURN {value, loc} => last
      | M.MCRAISE {argExp, loc} => last
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
        (M.MCCHECKGC :: mids, last)
      end

  fun compileTopdec topdec =
      case topdec of
        M.MTTOPLEVEL {symbol, frameSlots, bodyExp, loc} =>
        M.MTTOPLEVEL {symbol = symbol,
                      frameSlots = frameSlots,
                      bodyExp = compileBody bodyExp,
                      loc = loc}
      | M.MTFUNCTION {id, tyvarKindEnv, argVarList, closureEnvVar,
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

  fun insertCheckGC ({topdata, topdecs}:M.program) =
      {topdata = topdata, topdecs = map compileTopdec topdecs} : M.program

end
