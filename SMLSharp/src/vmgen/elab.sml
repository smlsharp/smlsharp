structure Elaboration : sig

 val elaborate : InsnDef.def list -> InsnDef.def_elaborated list

end =
struct

  structure I = InsnDef
  structure SMap = Utils.SMap

  fun evalMetaif suffix metaif =
      Utils.evalMetaif
          (fn I.METAEQ _ => NONE
            | I.METAEQTY _ => NONE
            | I.METAEQSUFFIX (s, pos) => SOME (suffix = SOME s))
          metaif

  fun expandMetaif meta =
      let
        val cases =
            Utils.expandMetaif
                (fn I.METAEQ x => x
                  | I.METAEQTY (_, pos) =>
                    raise Control.Error [(pos, "meta type equation in syntax")]
                  | I.METAEQSUFFIX _ =>
                    raise Control.Bug "expandMetaif: METAEQSUFFIX")
                meta
      in
        map (fn (fixed, format, pos) =>
                {fixed = fixed, format = format, pos = pos} : I.syntaxCase)
            cases
      end

  fun argList ({fixed, format, pos}:I.syntaxCase) =
      foldr (fn (I.FMTARG (arg, pos), z) => (arg, 0, pos) :: z
              | (I.FMTSTR _, z) => z)
            fixed
            format

  fun argEq ((arg1:I.arg, _, _), (arg2:I.arg, _, _)) =
      arg1 = arg2

  fun elabSyntax suffix args syntax =
      let
        val insnArgs = map (fn x => (x, 0, (~1, ~1))) args

        val cases = expandMetaif (evalMetaif suffix syntax)

        val _ =
            app (fn syntax =>
                    let
                      val syntaxArgs = argList syntax
                    in
                      (* duplication check *)
                      case Utils.checkDuplication argEq syntaxArgs of
                        SOME (_, (arg, _, pos)) =>
                        raise Control.Error
                                [(pos, "`"^I.formatArg arg^"' occurred twice \
                                       \in a syntax")]
                      | NONE => ();

                      (* exhaustive check *)
                      if Utils.equalSet argEq (syntaxArgs, insnArgs)
                      then ()
                      else raise Control.Error
                                   [(#pos syntax, "non-exhaustive syntax")]
                    end)
                cases
      in
        cases
      end

  fun elabDef env ({name, suffixList, tyList, args,
                    syntax, preprocess, semantics, alternate,
                    pos}:I.def) =
      let
        (* duplication check of symbol suffix *)
        val _ = case Utils.checkDuplication (op =) suffixList of
                  SOME (_, SOME x) =>
                  raise Control.Error [(pos, "duplicated suffix `"^x^"'")]
                | SOME (_, NONE) =>
                  raise Control.Bug "elabDef: duplicated NONE suffix"
                | NONE => ()

        (* duplication check of type suffix *)
        val _ = case Utils.checkDuplication (op =) tyList of
                  SOME (_, x) =>
                  raise Control.Error
                          [(pos, "duplicated type suffix `"^I.formatTy x^"'")]
                | NONE => ()

        (* duplication check of arguments *)
        val _ = case Utils.checkDuplication (op =) args of
                  SOME (_, x) =>
                  raise Control.Error
                          [(pos, "duplicated arg `"^I.formatArg x^"'")]
                | NONE => ()

        val suffixedNames =
            map (fn SOME s => (name ^ s, SOME s)
                  | NONE => (name, NONE))
                suffixList

        val mnemonicNames =
            case tyList of
              nil => map #1 suffixedNames
            | _ =>
              List.concat
                (map (fn (name, suffix) =>
                         map (fn ty => name ^ Utils.tyToSuffix ty) tyList)
                     suffixedNames)

        val _ =
            case mnemonicNames of
              nil => raise Control.Bug "elabDef: no mnemonic name"
            | _ => ()

        (* duplication check of mnemonic instruction names *)
        val env =
            foldl
              (fn (name, env) =>
                  (case SMap.find (env, name) of
                     SOME prev =>
                     raise Control.Error
                             [(pos, "duplicated instruction `"^name^"'"),
                              (prev, "previous definition was here")]
                   | NONE => ();
                   SMap.insert (env, name, pos)))
              env
              mnemonicNames

        (* duplicate the definition for each suffix *)
        val newDefs =
            map
              (fn (name, suffix) =>
                  let
                    val newSyntax = elabSyntax suffix args syntax
                    val newSemantics = evalMetaif suffix semantics

                    val mnemonicArgs =
                        (case List.last newSyntax of
                           syn as {fixed = nil, ...} =>
                           map (fn (arg, _, _) => arg) (argList syn)
                         | _ =>
                           raise Control.Bug "elabDef: no default syntax")
                        handle Empty =>
                               raise Control.Bug "elabDef: no syntax"
                  in
                    {
                      name = name,
                      tyList = tyList,
                      codeArgs = args,
                      mnemonicArgs = mnemonicArgs,
                      syntax = newSyntax,
                      preprocess = preprocess,
                      semantics = newSemantics,
                      alternate = alternate,
                      pos = pos
                    } : I.def_elaborated
                  end)
              suffixedNames
      in
        (env, newDefs)
      end

  fun elabDefList env (def::defs) =
      let
        val (env, newDefs1) = elabDef env def
        val (env, newDefs2) = elabDefList env defs
      in
        (env, newDefs1 @ newDefs2)
      end
    | elabDefList env nil = (env, nil)

  fun elaborate defs =
      #2 (elabDefList SMap.empty defs)

end
