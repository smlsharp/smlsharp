(**
 * concurrency support code generation
 *
 * @copyright (C) 2021 SML# Development Team.
 * @author UENO Katsuhiro
 *)
structure ConcurrencySupport : sig

  val insertCheckGC : MachineCode.program -> MachineCode.program

end =
struct

  (* ToDo: The algorithm is naive. Make it more sophisticated *)

  structure M = MachineCode

  (* insert MCCHECK at every recursive label,
   * where is possibly a loop header. *)
  fun insertCheckAtLoop handler (exp as (mids, last)) =
      case last of
        M.MCRETURN {value, loc} => exp
      | M.MCRAISE {argExp, cleanup, loc} => exp
      | M.MCUNREACHABLE => exp
      | M.MCGOTO {id, argList, loc} => exp
      | M.MCSWITCH {switchExp, expTy, branches, default, loc} => exp
      | M.MCHANDLER {nextExp, id, exnVar, handlerExp, cleanup, loc} =>
        (* ToDo: handler of MCCHECK *)
        (mids, M.MCHANDLER {nextExp = insertCheckAtLoop handler nextExp,
                            id = id,
                            exnVar = exnVar,
                            handlerExp = insertCheckAtLoop handler handlerExp,
                            cleanup = cleanup,
                            loc = loc})
      | M.MCLOCALCODE {recursive, binds, nextExp, loc} =>
        (mids,
         M.MCLOCALCODE
           {recursive = recursive,
            binds =
              map (fn {id, argVarList, bodyExp} =>
                      {id = id,
                       argVarList = argVarList,
                       bodyExp =
                         case insertCheckAtLoop handler bodyExp of
                           (mids, last) =>
                           if recursive
                           then (M.MCCHECK {handler = handler} :: mids, last)
                           else (mids, last)})
                  binds,
            nextExp = insertCheckAtLoop handler nextExp,
            loc = loc})

  datatype reach = RECURSIVE | BLOCK of (reach * M.mcexp) FunLocalLabel.Map.map

  (* whether or not the expression dominates a recursive label *)
  fun reachableToLoop blocks (_, last) =
      case last of
        M.MCRETURN {value, loc} => false
      | M.MCRAISE {argExp, cleanup, loc} => false
      | M.MCUNREACHABLE => false
      | M.MCGOTO {id, argList, loc} =>
        (case FunLocalLabel.Map.find (blocks, id) of
           NONE => raise Bug.Bug "reachableToLoop"
         | SOME (RECURSIVE, _) => true
         | SOME (BLOCK blocks, exp) => reachableToLoop blocks exp)
      | M.MCSWITCH {switchExp, expTy, branches, default, loc} => false
      | M.MCHANDLER {nextExp, id, exnVar, handlerExp, cleanup, loc} =>
        reachableToLoop blocks nextExp
      | M.MCLOCALCODE {recursive, binds, nextExp, loc} =>
        let
          val reach = if recursive then RECURSIVE else BLOCK blocks
          val blocks2 =
              foldl (fn ({id, argVarList, bodyExp}, z) =>
                        FunLocalLabel.Map.insert (z, id, (reach, bodyExp)))
                    blocks
                    binds
        in
          reachableToLoop blocks2 nextExp
        end
  val reachableToLoop =
      fn exp => reachableToLoop FunLocalLabel.Map.empty exp

  fun hasCall_mid mid =
      case mid of
        M.MCINTINF _ => false
      | M.MCFOREIGNAPPLY _ => true
      | M.MCEXPORTCALLBACK _ => false
      | M.MCEXVAR _ => false
      | M.MCMEMCPY_FIELD _ => false
      | M.MCMEMMOVE_UNBOXED_ARRAY _ => false
      | M.MCMEMMOVE_BOXED_ARRAY _ => false
      | M.MCALLOC _ => false
      | M.MCALLOC_COMPLETED => false
      | M.MCCHECK _ => false
      | M.MCRECORDDUP_ALLOC _ => false
      | M.MCRECORDDUP_COPY _ => false
      | M.MCBZERO _ => false
      | M.MCSAVESLOT _ => false
      | M.MCLOADSLOT _ => false
      | M.MCLOAD _ => false
      | M.MCPRIMAPPLY _ => false
      | M.MCBITCAST _ => false
      | M.MCCALL _ => true
      | M.MCSTORE _ => false
      | M.MCEXPORTVAR _ => false
      | M.MCKEEPALIVE _ => false

  fun hasCall_last last =
      case last of
        M.MCRETURN _ => false
      | M.MCRAISE _ => false
      | M.MCUNREACHABLE => false
      | M.MCGOTO _ => false
      | M.MCSWITCH _ => false
      | M.MCHANDLER {nextExp, id, exnVar, handlerExp, cleanup, loc} =>
        hasCall nextExp orelse hasCall handlerExp
      | M.MCLOCALCODE {recursive, binds, nextExp, loc} =>
        hasCall nextExp
        orelse foldl (fn (x, z) => z orelse hasCall (#bodyExp x)) false binds

  and hasCall (nil, last) = hasCall_last last
    | hasCall (mid::mids, last) =
      hasCall_mid mid orelse hasCall (mids, last)

  fun compileBody handler (exp as (mids, last)) =
      let
        val exp = insertCheckAtLoop handler exp
      in
        if reachableToLoop exp then exp
        else if hasCall exp
        then (M.MCCHECK {handler = handler} :: mids, last)
        else exp
      end

  fun compileTopdec topdec =
      case topdec of
        M.MTFUNCTION {id, tyvarKindEnv, tyArgs, argVarList, closureEnvVar,
                      frameSlots, bodyExp, retTy, gcCheck, loc} =>
        M.MTFUNCTION
          {id = id,
           tyvarKindEnv = tyvarKindEnv,
           tyArgs = tyArgs,
           argVarList = argVarList,
           closureEnvVar = closureEnvVar,
           frameSlots = frameSlots,
           bodyExp = if gcCheck
                     then compileBody NONE(*ToDo*) bodyExp
                     else bodyExp,
           retTy = retTy,
           gcCheck = false,
           loc = loc}
      | M.MTCALLBACKFUNCTION {id, tyvarKindEnv, argVarList, closureEnvVar,
                              frameSlots, bodyExp, attributes, retTy,
                              cleanupHandler, loc} =>
        M.MTCALLBACKFUNCTION
          {id = id,
           tyvarKindEnv = tyvarKindEnv,
           argVarList = argVarList,
           closureEnvVar = closureEnvVar,
           frameSlots = frameSlots,
           bodyExp = compileBody cleanupHandler bodyExp,
           attributes = attributes,
           retTy = retTy,
           cleanupHandler = cleanupHandler,
           loc = loc}

  fun compileToplevel {frameSlots, bodyExp, cleanupHandler} =
      {frameSlots = frameSlots,
       bodyExp = compileBody cleanupHandler bodyExp,
       cleanupHandler = cleanupHandler} : M.toplevel

  fun insertCheckGC ({topdata, topdecs, toplevel}:M.program) =
      {topdata = topdata,
       topdecs = map compileTopdec topdecs,
       toplevel = compileToplevel toplevel} : M.program

end
