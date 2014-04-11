structure UserErrorUtils =
struct
  local
    val errorQueue = UserError.createQueue ()
  in
    fun initializeErrorQueue () = UserError.clearQueue errorQueue
    fun getErrorsAndWarnings () = UserError.getErrorsAndWarnings errorQueue
    fun getErrors () = UserError.getErrors errorQueue
    fun isAnyError () = not (UserError.isEmptyErrorQueue errorQueue)
    fun getWarnings () = UserError.getWarnings errorQueue
    val enqueueError = UserError.enqueueError errorQueue
    val enqueueWarning = UserError.enqueueWarning errorQueue
  end

  (**
   * checks duplication in a set of names.
   * @params getName elements loc makeExn
   * @param getName a function to retriev name from an element. It should
   *               return NONE if no name is bound.
   * @param elements a list of element which contain a name in it.
   * @param loc location to be used in error message, if duplication found.
   * @param makeExn a function to construct an exception to be reported,
   *            if duplication found.
   * @return unit
   *)
  fun checkNameDuplication' getName elements loc makeExn =
    let
      fun collectDuplication names duplicates [] = SEnv.listItems duplicates
        | collectDuplication names duplicates (element :: elements) =
          case getName element of
            SOME name =>
              let
                val newDuplicates =
                  case SEnv.find(names, name) of
                    SOME _ => SEnv.insert(duplicates, name, name)
                  | NONE => duplicates
                val newNames = SEnv.insert(names, name, name)
              in collectDuplication newNames newDuplicates elements
              end
          | NONE => collectDuplication names duplicates elements
      val duplicateNames = collectDuplication SEnv.empty SEnv.empty elements
    in
      app (fn name => enqueueError(loc, makeExn name)) duplicateNames
    end
  (**
   * a variant of name duplicate checker.
   * getName parameter should return a string, instead of a string option.
   *)      
  fun checkNameDuplication getName elements loc makeExn =
      checkNameDuplication' (SOME o getName) elements loc makeExn

  fun checkSymbolDuplication' getName elements makeExn =
    let
      fun collectDuplication names duplicates [] = SymbolEnv.listItems duplicates
        | collectDuplication names duplicates (element :: elements) =
          case getName element of
            SOME name =>
              let
                val newDuplicates =
                  case SymbolEnv.find(names, name) of
                    SOME _ => SymbolEnv.insert(duplicates, name, name)
                  | NONE => duplicates
                val newNames = SymbolEnv.insert(names, name, name)
              in collectDuplication newNames newDuplicates elements
              end
          | NONE => collectDuplication names duplicates elements
      val duplicateNames = collectDuplication SymbolEnv.empty SymbolEnv.empty elements
    in
      app (fn name => enqueueError(Symbol.symbolToLoc name, makeExn name)) duplicateNames
    end

  fun checkSymbolDuplication getName elements makeExn =
      checkSymbolDuplication' (SOME o getName) elements makeExn

end
