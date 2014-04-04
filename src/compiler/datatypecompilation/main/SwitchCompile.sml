(**
 * Translation of complex switches.
 *
 * @copyright (c) 2013, Tohoku University.
 * @author UENO Katsuhiro
 *)
structure SwitchCompile : sig

  val compileStringSwitch
      : {switchExp : TypedLambda.tlexp,
         expTy : Types.ty,
         branches :
           {constant : ConstantTerm.constant, exp : TypedLambda.tlexp} list,
         defaultExp : TypedLambda.tlexp,
         resultTy : Types.ty,
         loc : TypedLambda.loc}
        -> TypedLambda.tlexp

  val compileIntInfSwitch
      : {switchExp : TypedLambda.tlexp,
         expTy : Types.ty,
         branches :
           {constant : ConstantTerm.constant, exp : TypedLambda.tlexp} list,
         defaultExp : TypedLambda.tlexp,
         resultTy : Types.ty,
         loc : TypedLambda.loc}
        -> TypedLambda.tlexp

end =
struct

  structure L = TypedLambda
  structure C = ConstantTerm
  structure B = BuiltinTypes
  structure T = Types
  structure E = EmitTypedLambda

  datatype tree =
      LEAF of string * E.exp
    | BRANCH of string * tree IEnv.map

  datatype trie =
      EMPTY
    | TREES of tree IEnv.map

  (* for debug *)
  fun dump' (pre, LEAF (pat, exp)) =
      print (pre ^ " " ^ pat ^ " $\n")
    | dump' (pre, BRANCH (pat, next)) =
      (print (pre ^ " " ^ pat ^ "@\n");
       IEnv.appi (fn (i,t) => dump' (pre, t)) next)

  (* for debug *)
  fun dump EMPTY = print "E"
    | dump (TREES t) =
      IEnv.appi (fn (i,t) => dump' (Int.toString i ^ ":", t)) t

  fun commonPrefix (str1, str2) =
      let
        fun loop i =
            if String.sub (str1, i) = String.sub (str2, i)
            then loop (i + 1)
            else i
      in
        loop 0
      end

  fun join (key1, t1, key2, t2) =
      let
        val i = commonPrefix (key1, key2)
      in
        BRANCH (substring (key1, 0, i),
                IEnv.insert (IEnv.singleton (ord (String.sub (key1, i)), t1),
                             ord (String.sub (key2, i)), t2))
      end

  fun insert' (t as LEAF (pat, _), key, exp) =
      if key = pat
      then raise Bug.Bug "insert: doubled branch"
      else join (pat, t, key, LEAF (key, exp))
    | insert' (t as BRANCH (pat, next), key, exp) =
      if String.isPrefix pat key
      then BRANCH (pat, insertBranch (next, ord (String.sub (key, size pat)),
                                      key, exp))
      else join (pat, t, key, LEAF (key, exp))

  and insertBranch (next, nextKey, key, exp) =
      IEnv.insert (next, nextKey,
                   case IEnv.find (next, nextKey) of
                     NONE => LEAF (key, exp)
                   | SOME t => insert' (t, key, exp))

  fun insert (EMPTY, key, exp) =
      TREES (IEnv.singleton (size key, LEAF (key, exp)))
    | insert (TREES ts, key, exp) =
      TREES (insertBranch (ts, size key, key, exp))

  fun Match (exp, pat, idx, matchedExp, defaultExp) =
      if size pat = idx
      then matchedExp
      else E.Switch (E.String_sub_unsafe (exp, E.Int idx),
                     [(C.CHAR (String.sub (pat, idx)),
                       Match (exp, pat, idx + 1, matchedExp, defaultExp))],
                     defaultExp)

  fun hex n =
      CharVector.map (fn #"~" => #"-" | c => c) (BigInt.fmt StringCvt.HEX n)

  fun IntInf_hex (exp, loc) =
      case exp of
        L.TLCONSTANT {const = C.LARGEINT n, ty, loc} =>
        L.TLCONSTANT {const = C.STRING (hex n), ty = B.stringTy, loc = loc}
      | _ =>
        let
          val attributes =
              {isPure = true,
               noCallback = true,
               allocMLValue = true,
               suspendThread = false,
               callingConvention = NONE}
        in
          L.TLFOREIGNAPPLY
            {funExp = L.TLFOREIGNSYMBOL
                        {name = "sml_intinf_hex",
                         ty = T.BACKENDty (T.FOREIGNFUNPTRty
                                             {argTyList = [B.intInfTy],
                                              varArgTyList = NONE,
                                              resultTy = SOME B.stringTy,
                                              attributes = attributes}),
                         loc = loc},
             attributes = attributes,
             resultTy = SOME B.stringTy,
             argExpList = [exp],
             loc = loc}
        end

  fun emitTree (LEAF (pat, exp), idx, keyExp, defaultExp) =
      Match (keyExp, pat, idx, exp, defaultExp)
    | emitTree (BRANCH (pat, next), idx, keyExp, defaultExp) =
      Match (keyExp, pat, idx,
             E.Switch
               (E.String_sub_unsafe (keyExp, E.Int (size pat)),
                map (fn (c, t) =>
                        (C.CHAR (chr c),
                         emitTree (t, size pat + 1, keyExp, defaultExp)))
                    (IEnv.listItemsi next),
                defaultExp),
             defaultExp)

  fun emit (EMPTY, keyExp, keyTy, defaultExp, resultTy, loc) = defaultExp
    | emit (TREES trees, keyExp, keyTy, defaultExp, resultTy, loc) =
      let
        val vid = EmitTypedLambda.newId ()
        val defaultLabel = FunLocalLabel.generate nil
        val jumpExp = E.Exp (L.TLGOTO {destinationLabel = defaultLabel,
                                       argExpList = nil,
                                       resultTy = resultTy,
                                       loc = loc},
                             resultTy)
        val exp =
            E.Let ([(vid, E.Exp (keyExp, keyTy))],
                   E.Switch (E.String_size (E.Var vid),
                             map (fn (len, t) =>
                                     (C.INT (Int32.fromInt len),
                                      emitTree (t, 0, E.Var vid, jumpExp)))
                                 (IEnv.listItemsi trees),
                             jumpExp))
      in
        L.TLLOCALCODE
          {codeLabel = defaultLabel,
           argVarList = nil,
           codeBodyExp = defaultExp,
           mainExp = EmitTypedLambda.emit loc exp,
           resultTy = resultTy,
           loc = loc}
      end

  fun compileStringSwitch {switchExp, expTy, branches, defaultExp, resultTy,
                           loc} =
      let
        val trie =
            foldl
              (fn ({constant = C.STRING s, exp}, trie) =>
                  insert (trie, s, E.Exp (exp, resultTy))
                | _ => raise Bug.Bug "compileStringSwitch")
              EMPTY
              branches
      in
        emit (trie, switchExp, expTy, defaultExp, resultTy, loc)
      end

  fun compileIntInfSwitch {switchExp, expTy, branches, defaultExp, resultTy,
                           loc} =
      let
        val trie =
            foldl
              (fn ({constant = C.LARGEINT n, exp}, trie) =>
                  insert (trie, hex n, E.Exp (exp, resultTy))
                | _ => raise Bug.Bug "compileIntInfSwitch")
              EMPTY
              branches
        val switchExp = IntInf_hex (switchExp, loc)
      in
        emit (trie, switchExp, B.stringTy, defaultExp, resultTy, loc)
      end

end
