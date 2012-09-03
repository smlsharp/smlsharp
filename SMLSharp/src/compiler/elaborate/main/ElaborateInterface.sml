(**
 * ElaboratorInterface.sml
 * @copyright (c) 2011, Tohoku University.
 * @author UENO Katsuhiro
 *)

structure ElaborateInterface : sig

  val elaborate
      : AbsynInterface.interface
        -> Fixity.fixity SEnv.map
           * PatternCalcInterface.interface

end =
struct

  structure I = AbsynInterface
  structure P = PatternCalcInterface
  structure PC = PatternCalc

  fun checkSigexp sigexp =
      case sigexp of
        PC.PLSIGEXPBASIC (spec, loc) => checkSpec spec
      | PC.PLSIGID (sigid, loc) =>
        ElaboratorUtils.enqueueError
          (loc, ElaborateError.SigIDFoundInInterface sigid)
      | PC.PLSIGWHERE (sigexp, typbinds, loc) => checkSigexp sigexp

  and checkSpec spec =
      case spec of
        PC.PLSPECVAL _ => ()
      | PC.PLSPECTYPE _ => ()
      | PC.PLSPECTYPEEQUATION _ => ()
      | PC.PLSPECDATATYPE _ => ()
      | PC.PLSPECREPLIC _ => ()
      | PC.PLSPECEXCEPTION _ => ()
      | PC.PLSPECSTRUCT (strdecs, loc) =>
        app (fn (strid, sigexp) => checkSigexp sigexp) strdecs
      | PC.PLSPECINCLUDE (sigexp, loc) => checkSigexp sigexp
      | PC.PLSPECSEQ (spec1, spec2, loc) =>
        (checkSpec spec1; checkSpec spec2)
      | PC.PLSPECSHARE (spec, ids, loc) => checkSpec spec
      | PC.PLSPECSHARESTR (spec, ids, loc) => checkSpec spec
      | PC.PLSPECEMPTY => ()

  fun elabSigexp sigexp =
      let
        val sigexp = ElaborateModule.elabSigExp sigexp
        val sigexp = UserTvarScope.decideSigexp sigexp
        val _ = checkSigexp sigexp
      in
        sigexp
      end

  fun tyvarsOverloadInstance inst =
      case inst of
        P.INST_OVERLOAD overloadCase => tyvarsOverloadCase overloadCase
      | P.INST_LONGVID {vid} => UserTvarScope.empty

  and tyvarsOverloadMatch ({instTy, instance}:P.overloadMatch) =
      UserTvarScope.union (UserTvarScope.ftv instTy,
                            tyvarsOverloadInstance instance)
  and tyvarsOverloadCase ({tyvar, expTy, matches, loc}:P.overloadCase) =
      UserTvarScope.union
        (UserTvarScope.union (UserTvarScope.singleton (tyvar, loc),
                              UserTvarScope.ftv expTy),
         UserTvarScope.tyvarsList tyvarsOverloadMatch matches)

  fun tyvarsValbindBody body =
      case body of
        P.VAL_EXTERN {ty} => UserTvarScope.ftv ty
      | P.VAL_BUILTIN {builtinName, ty} => UserTvarScope.ftv ty
      | P.VAL_OVERLOAD overloadCase => tyvarsOverloadCase overloadCase

  fun checkUniqueOverloadTvars used ({tyvar, expTy, matches, loc}
                                     :P.overloadCase) =
      let
        val _ =
            if UserTvarScope.member (used, tyvar)
            then (ElaboratorUtils.enqueueError
                   (loc, ElaborateError.UserTvarScopedAtOuterDecl
                           {tvar = tyvar}))
            else ()
        val set =
            UserTvarScope.union
              (UserTvarScope.singleton (tyvar, loc),
               UserTvarScope.ftv expTy)
        val used = UserTvarScope.union (used, set)
      in
        app (fn {instTy, instance} =>
                case instance of
                  P.INST_OVERLOAD c => checkUniqueOverloadTvars used c
                | P.INST_LONGVID _ => ())
            matches
      end

  fun elabValbindBody body =
      case body of
        P.VAL_EXTERN _ => body
      | P.VAL_BUILTIN _ => body
      | P.VAL_OVERLOAD c =>
        (checkUniqueOverloadTvars UserTvarScope.empty c; body)

  fun elabValbind ({vid, body, loc}:I.valbind) =
      let
        val body = elabValbindBody body
        val tvset = tyvarsValbindBody body
        val tvars = UserTvarScope.toTvarList tvset
      in
        P.PIVAL {scopedTvars = tvars, vid = vid, body = body, loc = loc}
      end

  fun elabExbind exbind =
      case exbind of
        I.EXNDEF {vid, ty, loc} => P.PIEXCEPTION {vid=vid, ty=ty, loc=loc}
      | I.EXNREP {vid, longvid, loc} =>
        P.PIEXCEPTIONREP {vid=vid, origId=longvid, loc=loc}

  fun elabDec dec =
      case dec of
        I.IVAL valbind => map elabValbind valbind
      | I.ITYPE typbind => map P.PITYPE typbind
      | I.IDATATYPE bind => [P.PIDATATYPE bind]
      | I.ITYPEREP bind => [P.PITYPEREP bind]
      | I.ITYPEBUILTIN bind => [P.PITYPEBUILTIN bind]
      | I.IEXCEPTION exbind => map elabExbind exbind
      | I.ISTRUCTURE strbind => map elabStrbind strbind

  and elabStrbind ({strid, strexp, loc}:I.strbind) =
      P.PISTRUCTURE {strid = strid,
                     strexp = elabStrexp strexp,
                     loc = loc}

  and elabStrexp strexp =
      case strexp of
        I.ISTRUCT {decs, loc} =>
        P.PISTRUCT {decs = List.concat (map elabDec decs), loc = loc}

  fun elabFunbind ({funid, param, strexp, loc}:I.funbind) =
      let
        val strexp = elabStrexp strexp
        val param =
            case param of
              I.FUNPARAM_FULL {strid, sigexp} =>
              {strid = strid, sigexp = elabSigexp sigexp}
            | I.FUNPARAM_SPEC spec =>
              (ElaboratorUtils.enqueueError
                 (loc, ElaborateError.DerivedFormFunArg);
               {strid = "", sigexp = PatternCalc.PLSIGID ("", loc)})
      in
        P.PIFUNDEC {funid = funid,
                    param = param,
                    strexp = strexp,
                    loc = loc}
      end

  fun checkInfixPrecedence loc NONE = 0
    | checkInfixPrecedence loc (SOME n) =
      (if BigInt.< (n, BigInt.fromInt 0) orelse BigInt.> (n, BigInt.fromInt 9)
       then ElaboratorUtils.enqueueError
              (loc, ElaborateError.InvalidFixityPrecedence)
       else ();
       BigInt.toInt n)

  fun elabTopdec fixEnv itopdec =
      case itopdec of
      I.IDEC dec =>
      (SEnv.empty, map P.PIDEC (elabDec dec))
    | I.IFUNDEC funbind =>
      (SEnv.empty, map elabFunbind funbind)
    | I.IINFIX {fixity, vids, loc} =>
      let
        val fixity =
            case fixity of
              I.INFIXL n => Fixity.INFIX (checkInfixPrecedence loc n)
            | I.INFIXR n => Fixity.INFIXR (checkInfixPrecedence loc n)
            | I.NONFIX => Fixity.NONFIX

        (* check duplicate declarations *)
        val _ =
            app (fn vid =>
                    case SEnv.find (fixEnv, vid) of
                      SOME (fixity1, loc1) =>
                      if fixity = fixity1 then ()
                      else ElaboratorUtils.enqueueError
                             (loc, ElaborateError.MultipleInfixInInterface
                                     (vid, loc1))
                    | NONE => ())
                vids

        val fixEnv =
            foldl (fn (vid,z) => SEnv.insert (z, vid, (fixity, loc)))
                  SEnv.empty
                  vids
      in
        (fixEnv, nil)
      end

  and elabTopdecList fixEnv nil = (SEnv.empty, nil)
    | elabTopdecList fixEnv (dec::decs) =
      let
        val (newFixEnv1, dec) = elabTopdec fixEnv dec
        val fixEnv = SEnv.unionWith #2 (fixEnv, newFixEnv1)
        val (newFixEnv2, decs) = elabTopdecList fixEnv decs
      in
        (SEnv.unionWith #2 (newFixEnv1, newFixEnv2), dec @ decs)
      end

  fun elabInterfaceDec fixEnv ({interfaceId, interfaceName, requires, topdecs}
                               :I.interfaceDec) =
      let
        val (newFixEnv, topdecs) = elabTopdecList fixEnv topdecs
      in
        (newFixEnv,
         {interfaceId = interfaceId,
          requires = requires,
          topdecs = topdecs} : P.interfaceDec)
      end

  fun elabInterfaceDecs fixEnv nil = (InterfaceID.Map.empty, nil)
    | elabInterfaceDecs fixEnv (dec::decs) =
      let
        val (newFixEnv, dec) = elabInterfaceDec fixEnv dec
        val fixEnvMap1 = InterfaceID.Map.singleton (#interfaceId dec, newFixEnv)
        val fixEnv = SEnv.unionWith #2 (fixEnv, newFixEnv)
        val (fixEnvMap2, decs) = elabInterfaceDecs fixEnv decs
        val fixEnvMap = InterfaceID.Map.unionWith #2 (fixEnvMap1, fixEnvMap2)
      in
        (fixEnvMap, dec::decs)
      end

  fun elaborate ({decls, interfaceName, requires, topdecs}:I.interface) =
      let
        val (fixEnvMap, newDecls) =
            elabInterfaceDecs SEnv.empty decls
        val allFixEnv =
            InterfaceID.Map.foldl (SEnv.unionWith #2) SEnv.empty fixEnvMap
        val (fixEnv, topdecs) =
            elabTopdecList allFixEnv topdecs
        val interface =
            {
              decls = newDecls,
              requires = requires,
              topdecs = topdecs
            }
            : P.interface

        val fixEnv =
            foldl (fn ({id, loc}, z) =>
                      case InterfaceID.Map.find (fixEnvMap, id) of
                        SOME env => SEnv.unionWith #2 (z, env)
                      | NONE =>
                        raise Control.Bug "elaborate: interface not found")
                  fixEnv
                  requires
        val fixEnv =
            SEnv.map (fn (fixity, loc) => fixity) fixEnv
      in
        (fixEnv, interface)
      end

end
