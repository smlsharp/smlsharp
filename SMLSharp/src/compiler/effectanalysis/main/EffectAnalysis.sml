(**
 * effect analysis.
 * @copyright (c) 2008, Tohoku University.
 * @author UENO Katsuhiro
 * @version $Id: EffectAnalysis.sml,v 1.5 2008/05/09 03:55:27 katsu Exp $
 *)
structure EffectAnalysis : EFFECT_ANALYSIS =
struct

  structure PT = PatternCalcWithTvars
  structure NPEnv = NameMap.NPEnv
  structure NPSet = NameMap.NPSet
  structure E = EffectCalc

  type env =
      {
        tyEnv: (E.idstate * E.ecvalue) SEnv.map NPEnv.map,
        varEnv: E.effectVarEnv
      }

  val emptyEnv = {tyEnv = NPEnv.empty, varEnv = NPEnv.empty} : env

  fun extendEnv (env1:env, env2:env) =
      {
        tyEnv = NPEnv.unionWith #2 (#tyEnv env1, #tyEnv env2),
        varEnv = NPEnv.unionWith #2 (#varEnv env1, #varEnv env2)
      } : env

  fun extendVarEnv (env:env, varEnv) =
      {
        tyEnv = #tyEnv env,
        varEnv = NPEnv.unionWith #2 (#varEnv env, varEnv)
      } : env

  fun addVar (env:env, var, varState) =
      {
        tyEnv = #tyEnv env,
        varEnv = NPEnv.insert (#varEnv env, var, varState)
      } : env

  fun newVar () = (Counters.newVarName (), Path.NilPath)

  fun isAtomicValue value =
      case value of
        E.CLOSURE _ => false
      | E.SELECTOR _ => true
      | E.BOTTOMFUN _ => true
      | E.ATOMFUN _ => true
      | E.IDENTFUN => true
      | E.REFFUN => true
      | E.ASSIGNFUN => true
      | E.BOTTOM => true
      | E.ATOM => true
      | E.RECORD _ => false
      | E.UNION _ => false
      | E.RAISE => true
      | E.WRONG => true

  fun isAtomicExp ecexp =
      case ecexp of
        E.ECVALUE value => isAtomicValue value
      | E.ECVAR _ => true
      | E.ECFN _ => false
      | E.ECAPP _ => false
      | E.ECLET _ => false
      | E.ECPARALLEL _ => false
      | E.ECRECORD _ => false
      | E.ECSELECT _ => false
      | E.ECMODIFY _ => false
      | E.ECDEREF _ => false

  fun orelseopt (SOME x, y) = SOME (x orelse y)
    | orelseopt (NONE, y) = SOME y

  fun tupleRecord elemList =
      let
        fun make n (h::t) = (Int.toString n, h) :: make (n+1) t
          | make n nil = nil
      in
        make 1 elemList
      end

  (* Elaborator ensures that all ptpatList are same length. *)
  fun numberOfPat nil = 0
    | numberOfPat ((ptpatList, ptexp)::_) = length ptpatList

  fun replicate (fromMap, fromName) (toMap, toName) =
      case NPEnv.find (fromMap, fromName) of
        SOME x => NPEnv.insert (toMap, toName, x)
      | NONE => raise Control.Bug "replicate" (* debug *)

  local

    fun conValue (SOME _) = E.IDENTFUN
      | conValue NONE = E.ATOM

    fun evalDataconBind path newVarEnv dataconList =
        foldl
          (fn ((_, conName, tyOpt), {conEnv, varEnv}) =>
              let
                val namePath = (conName, path)
                val value = conValue tyOpt
                val idState = (E.CONID, value)
              in
                {conEnv = SEnv.insert (conEnv, conName, idState),
                 varEnv = NPEnv.insert (varEnv, namePath, idState)}
              end)
          {conEnv = SEnv.empty, varEnv = newVarEnv}
          dataconList

  in

  fun evalDatatypeDecl path declList =
      let
        val {tyEnv, varEnv} =
            foldl
              (fn ((args, namePath, dataconList), {tyEnv, varEnv}) =>
                  let
                    val {conEnv, varEnv} =
                        evalDataconBind path varEnv dataconList
                  in
                    {tyEnv = NPEnv.insert (tyEnv, namePath, conEnv),
                     varEnv = varEnv}
                  end)
              {tyEnv = NPEnv.empty, varEnv = NPEnv.empty}
              declList
      in
        {tyEnv = tyEnv, varEnv = varEnv}
      end

  fun evalExbindList (env:env) ptexbindList =
      let
        val varEnv =
            foldl
              (fn (ptexbind, varEnv) =>
                  case ptexbind of
                    PT.PTEXBINDDEF (_, namePath, tyOpt, loc) =>
                    NPEnv.insert (varEnv, namePath, (E.CONID, conValue tyOpt))
                  | PT.PTEXBINDREP (_, namePath1, _, namePath2, loc) =>
                    replicate (#varEnv env, namePath2) (varEnv, namePath1))
              NPEnv.empty
              ptexbindList
      in
        {tyEnv = NPEnv.empty, varEnv = varEnv}
      end

  end

  local

    fun newBind ecexp =
        let
          val var = newVar ()
        in
          ([E.ECVAL (var, ecexp)], E.ECVAR var)
        end

    fun makeBind ecexp =
        if isAtomicExp ecexp then (nil, ecexp) else newBind ecexp

    fun compilePat (env:env) valueExp ptpat =
        case ptpat of
          PT.PTPATWILD loc => (nil, nil)
        | PT.PTPATCONSTANT (constant, loc) => (nil, nil)
        | PT.PTPATID (namePath, hasEffect, loc) =>
          (
            case NPEnv.find (#varEnv env, namePath) of
              SOME (E.CONID, _) => (nil, nil)
            | _ => (nil, [(namePath, valueExp, [hasEffect])])
          )
        | PT.PTPATCONSTRUCT (PT.PTPATID (conName, _, loc1), ptpat2, loc2) =>
          (
            case NPEnv.find (#varEnv env, conName) of
              SOME (E.CONID, E.REFFUN) =>
              compilePat env (E.ECDEREF valueExp) ptpat2
            | _ => compilePat env valueExp ptpat2
          )
        | PT.PTPATCONSTRUCT (ptpat1, ptpat2, loc) =>
          (* never happen due to syntactic restriction *)
          compilePat env valueExp ptpat2
        | PT.PTPATTYPED (ptpat, ty, loc) =>
          compilePat env valueExp ptpat
        | PT.PTPATLAYERED (var, ty, ptpat, loc) =>
          let
            val varId = (var, Path.NilPath)
          in
            case NPEnv.find (#varEnv env, varId) of
              SOME (E.CONID, _) => compilePat env valueExp ptpat
            | _ =>
              let
                val (local1, valueExp) = makeBind valueExp
                val (local2, bind) = compilePat env valueExp ptpat
              in
                (local1 @ local2, (varId, valueExp, [ref NONE]) :: bind)
              end
          end
        | PT.PTPATRECORD (isFlex, fields, loc) =>
          let
            val (local1, valueExp) =
                case fields of [_] => (nil, valueExp) | _ => makeBind valueExp
            val (local2, bind) =
                foldr (fn ((label, pat), (local2, bind)) =>
                          let
                            val ecexp = E.ECSELECT (label, valueExp)
                            val (local3, bind3) = compilePat env ecexp pat
                          in
                            (local3 @ local2, bind3 @ bind)
                          end)
                      (nil, nil)
                      fields
          in
            (local1 @ local2, bind)
          end
        | PT.PTPATORPAT (ptpat1, ptpat2, loc) =>
          let
            fun toMap l =
                foldl (fn ((v,e,l),z) => NPEnv.insert (z,v,(e,l))) NPEnv.empty l
            val (local0, valueExp) = makeBind valueExp
            val (local1, bind1) = compilePat env valueExp ptpat1
            val (local2, bind2) = compilePat env valueExp ptpat2
            val bind = NPEnv.unionWith
                         (fn ((e1,l1),(e2,l2)) => (E.ECPARALLEL (e1,e2), l1@l2))
                         (toMap bind1, toMap bind2)
            val binds = NPEnv.foldri (fn (k,(e,l),t) => (k,e,l)::t) nil bind
          in
            (local0 @ local1 @ local2, binds)
          end

  in

  fun evalPat env valueExp ptpat =
      let
        fun ANDVAL [bind] = E.ECVAL bind
          | ANDVAL binds = E.ECANDVAL (map (fn x => [E.ECVAL x]) binds)
        fun ANDVAL [(v,e,_)] = E.ECVAL (v,e)
          | ANDVAL l = E.ECANDVAL (map (fn (v,e,_) => [E.ECVAL (v,e)]) l)

        val (locals, binds) = compilePat env valueExp ptpat

        val (varEnv1, e1) =
            EffectCalcEvaluator.evalDeclList (#varEnv env) locals
        val varEnv = NPEnv.unionWith #2 (#varEnv env, varEnv1)
        val varEnv2 =
            foldl
              (fn ((var, exp, gens), varEnv2) =>
                  let
                    val (value, e2) = EffectCalcEvaluator.evalExp varEnv exp
                  in
                    app (fn x => x := orelseopt (!x, e1 orelse e2)) gens;
                    NPEnv.insert (varEnv2, var, (E.VARID, value))
                  end)
              varEnv1
              binds

        val ecdecl =
            case (locals, binds) of
              (nil, nil) => E.ECIGNORE valueExp
            | (nil, binds) => ANDVAL binds
            | (locals, binds) => E.ECLOCAL (locals, [ANDVAL binds])
      in
        (ecdecl, varEnv2)
      end

  fun evalPatList env valueExpList ptpatList =
      let
        fun eval (value::values) (ptpat::ptpats) =
            let
              val (decl1, varEnv1) = evalPat env value ptpat
              val (decl2, varEnv2) = eval values ptpats
            in
              ([decl1]::decl2, NPEnv.unionWith #2 (varEnv1, varEnv2))
            end
          | eval nil (ptpat::ptpats) =
            eval [E.ECVALUE E.BOTTOM] (ptpat::ptpats)
          | eval _ nil = (nil, NPEnv.empty)

        val (decls, varEnv) = eval valueExpList ptpatList
        val ecdecl =
            case decls of
              [[decl]] => decl
            | ecdecls => E.ECANDVAL ecdecls
      in
        (ecdecl, varEnv)
      end

  end

  fun evalMatch1 env valueExpList (ptpatList, ptexp) =
      let
        val (ecdecl, varEnv) = evalPatList env valueExpList ptpatList
        val bodyExp = evalExp (extendVarEnv (env, varEnv)) ptexp
      in
        E.ECLET ([ecdecl], bodyExp)
      end

  and evalMatch env valueExpList [match] =
      evalMatch1 env valueExpList match
    | evalMatch env valueExpList (match::matches) =
      let
        val ecexp1 = evalMatch1 env valueExpList match
        val ecexp2 = evalMatch env valueExpList matches
      in
        E.ECPARALLEL (ecexp1, ecexp2)
      end
    | evalMatch env valueExpList nil = raise Control.Bug "evalMatch: nil"

  and evalSeq env [ptexp] = evalExp env ptexp
    | evalSeq env (ptexp::ptexps) =
      let
        val ecexp1 = evalExp env ptexp
        val ecexp2 = evalSeq env ptexps
      in
        case ecexp2 of
          E.ECLET (decls, exp) => E.ECLET (E.ECIGNORE ecexp1::decls, exp)
        | _ => E.ECLET ([E.ECIGNORE ecexp1], ecexp2)
      end
    | evalSeq env nil = raise Control.Bug "evalSeq: nil"

  and evalExp (env:env) ptexp =
      case ptexp of
        PT.PTCONSTANT (const, loc) => E.ECVALUE E.ATOM
      | PT.PTVAR (namePath, loc) =>
        (
          (* every value constructor is inline-expanded. *)
          case NPEnv.find (#varEnv env, namePath) of
            SOME (E.CONID, x) => E.ECVALUE x
          | SOME (E.VARID, x) => E.ECVAR namePath   (* FIXME: optimization *)
          | NONE => raise Control.Bug "evalExp: unbound var" (* debug *)
        )
      | PT.PTTYPED (ptexp, ty, loc) => evalExp env ptexp
      | PT.PTCAST (ptexp, loc) => evalExp env ptexp
      | PT.PTLET (ptdeclList, ptexpList, loc) =>
        let
          val (ecdecls, env1) = evalDeclList env ptdeclList
          val env = extendEnv (env, env1)
          val ecexp = evalSeq env ptexpList
        in
          case ecexp of
            E.ECLET (decls, exp) => E.ECLET (ecdecls @ decls, exp)
          | _ => E.ECLET (ecdecls, ecexp)
        end
      | PT.PTSEQ (ptexpList, loc) => evalSeq env ptexpList
      | PT.PTRECORD (fieldExpList, loc) =>
        E.ECRECORD (map (fn (label, exp) => (label, evalExp env exp))
                         fieldExpList)
      | PT.PTSELECT (label, ptexp, loc) =>
        E.ECSELECT (label, evalExp env ptexp)
      | PT.PTRECORD_UPDATE (ptexp, fieldExpList, loc) =>
        E.ECMODIFY (evalExp env ptexp,
                     map (fn (label, exp) => (label, evalExp env exp))
                         fieldExpList)
      | PT.PTRECORD_SELECTOR (label, loc) =>
        E.ECVALUE (E.SELECTOR label)
      | PT.PTTUPLE (ptexpList, loc) =>
        E.ECRECORD (tupleRecord (map (evalExp env) ptexpList))
      | PT.PTLIST (ptexpList, loc) =>
        (* [a,b,c,d] ==> ::(a,::(b,::(c,::(d,nil)))) *)
        foldr (fn (x,z) => E.ECRECORD (tupleRecord [evalExp env x, z]))
              (E.ECVALUE E.ATOM)
              ptexpList
      | PT.PTFNM (tvars, body, loc) =>
        let
          val n = numberOfPat body
          val argVars = List.tabulate (n, fn _ => newVar ())
          (* assign dummy BOTTOMs to argVars for computing effects of body. *)
          val env = foldl (fn (x,z) => addVar (z, x, (E.VARID, E.BOTTOM)))
                          env argVars
          val bodyExp = evalMatch env (map E.ECVAR argVars) body
        in
          if n > 0
          then foldr (fn (var, z) => E.ECFN ([var], z)) bodyExp argVars
          else
            (* fn without any args; never happen due to syntactic restriction *)
            E.ECFN (nil, bodyExp)
        end
      | PT.PTFNM1 (tvars, argVars, ptexp, loc) =>
        (* Only type inference create this term; never reach here. *)
        let
          val argVars = map (fn (x,_) => (x, Path.NilPath)) argVars

          (* bind dummy BOTTOMs to argVars for computing effects of body. *)
          val env = foldl (fn (x,z) => addVar (z, x, (E.VARID, E.BOTTOM)))
                          env argVars
        in
          E.ECFN (argVars, evalExp env ptexp)
        end
      | PT.PTCASEM (ptexpList, body, caseKind, loc) =>
        evalMatch env (map (evalExp env) ptexpList) body
      | PT.PTAPPM (ptexp, argExpList, loc) =>
        E.ECAPP (evalExp env ptexp, map (evalExp env) argExpList)
      | PT.PTRAISE (ptexp, loc) =>
        E.ECLET ([E.ECIGNORE (evalExp env ptexp)], E.ECVALUE E.RAISE)
      | PT.PTHANDLE (ptexp, handlerList, loc) =>
        foldl (fn ((pat, exp), z) =>
                  E.ECPARALLEL
                    (evalMatch1 env [E.ECVALUE E.BOTTOM] ([pat], exp), z))
              (evalExp env ptexp)
              handlerList
      | PT.PTFFIIMPORT (ptexp, ty, loc) =>
        (* FFIIMPORT returns an ML function *)
        E.ECLET ([E.ECIGNORE (evalExp env ptexp)], E.ECVALUE E.BOTTOM)
      | PT.PTFFIEXPORT (ptexp, ty, loc) =>
        (* FFIEXPORT returns a C pointer *)
        E.ECLET ([E.ECIGNORE (evalExp env ptexp)], E.ECVALUE E.ATOM)
      | PT.PTFFIAPPLY (convention, ptexp, ffiArgList, ty, loc) =>
        (* We cannot predict how foreign function works.
           They may create new ref cells. *)
        let
          val ecexp1 = evalExp env ptexp
          val args = map (evalFFIArg env) ffiArgList
        in
          E.ECLET (map E.ECIGNORE (ecexp1::args) @ [E.ECEFFECT],
                   E.ECVALUE E.BOTTOM)
        end

  and evalFFIArg env ffiarg =
      case ffiarg of
        PT.PTFFIARG (ptexp, ty, loc) => evalExp env ptexp
      | PT.PTFFIARGSIZEOF (ty, SOME ptexp, loc) => evalExp env ptexp
      | PT.PTFFIARGSIZEOF (ty, NONE, loc) => E.ECVALUE E.ATOM

  and evalDecl env ptdecl =
      case ptdecl of
        PT.PTVAL (tvset1, tvset2, bindList, loc) =>
        let
          val ptpats = map (fn (pat,exp) => pat) bindList
          val ecexps = map (fn (pat,exp) => evalExp env exp) bindList
          val (decl, varEnv) = evalPatList env ecexps ptpats
        in
          ([decl], {tyEnv = NPEnv.empty, varEnv = varEnv})
        end
      | PT.PTDECFUN (tvset1, tvset2, bindList, loc) =>
        let
          val recBindList =
              map (fn (ptpat, body) => (ptpat, PT.PTFNM (tvset2, body, loc)))
                  bindList
        in
          evalDecl env (PT.PTVALREC (tvset1, tvset2, recBindList, loc))
        end
      | PT.PTNONRECFUN (tvset1, tvset2, (ptpat, body), loc) =>
        let
          val ecexp = evalExp env (PT.PTFNM (tvset2, body, loc))
          val (decl, varEnv) = evalPat env ecexp ptpat
        in
          ([decl], {tyEnv = NPEnv.empty, varEnv = varEnv})
        end
      | PT.PTVALREC (tvset1, tvset2, bindList, loc) =>
        (*
         * We assume that recursive call does not have any effect.
         *
         * fun f true x = ref x
         *   | f false x =
         *     let
         *       val g = f true  <-- this "val" is resulted in generalizable,
         *     in                    but never generalized due to restriction
         *       g x                 of polymorphic recursion.
         *     end
         *)
        let
          fun dummyRecValue body =
              case body of
                PT.PTFNM (_, body, _) =>
                E.ECVALUE (E.BOTTOMFUN (numberOfPat body))
              | PT.PTFNM1 _ =>
                E.ECVALUE (E.BOTTOMFUN 1)
              | _ => (* never happen due to syntactic restriction *)
                E.ECVALUE E.BOTTOM

          val ptpats = map (fn (pat,exp) => pat) bindList
          val ptexps = map (fn (pat,exp) => exp) bindList
          val recDummys = map dummyRecValue ptexps
          val (recDecl, recVarEnv) = evalPatList env recDummys ptpats
          val recEnv = extendVarEnv (env, recVarEnv)

          val ecexps = map (fn x => E.ECLET ([recDecl], evalExp recEnv x))
                           ptexps
          val (decl, varEnv) = evalPatList env ecexps ptpats
        in
          ([decl], {tyEnv = NPEnv.empty, varEnv = varEnv})
        end
      | PT.PTVALRECGROUP (idList, ptdeclList, loc) =>
        evalDeclList env ptdeclList
      | PT.PTLOCALDEC (ptdeclList1, ptdeclList2, loc) =>
        let
          val (decls1, env1) = evalDeclList env ptdeclList1
          val env = extendEnv (env, env1)
          val (decls2, env2) = evalDeclList env ptdeclList2
        in
          ([E.ECLOCAL (decls1, decls2)], env2)
        end
      | PT.PTTYPE (typeDeclList, loc) =>
        let
          val tyEnv =
              foldl (fn ((args, namePath, ty), tyEnv) =>
                        NPEnv.insert (tyEnv, namePath, SEnv.empty))
                    NPEnv.empty
                    typeDeclList
        in
          (nil, {tyEnv = tyEnv, varEnv = NPEnv.empty})
        end
      | PT.PTDATATYPE (path, datatypeDeclList, loc) =>
        (nil, evalDatatypeDecl path datatypeDeclList)
      | PT.PTREPLICATEDAT (namePath1 as (_, path), namePath2, loc) =>
        let
          val conEnv =
              case NPEnv.find (#tyEnv env, namePath2) of
                SOME conEnv => conEnv
              | NONE => raise Control.Bug "PTREPLICATEDDAT" (* debug *)
          val tyEnv = NPEnv.singleton (namePath1, conEnv)
          val varEnv = SEnv.foldli
                         (fn (name, value, varEnv) =>
                             NPEnv.insert (varEnv, (name, path), value))
                         NPEnv.empty
                         conEnv
        in
          (nil, {tyEnv = tyEnv, varEnv = varEnv})
        end
      | PT.PTABSTYPE (path, datatypeDeclList, declList, loc) =>
        let
          val env2 = evalDatatypeDecl path datatypeDeclList
          val env = extendEnv (env, env2)
        in
          evalDeclList env declList
        end
      | PT.PTEXD (ptexbindList, loc) =>
        (* exception declaration has side effect because exception is
         * generative. *)
        ([E.ECEFFECT], evalExbindList env ptexbindList)
      | PT.PTINTRO ((tyStateEnv, idStateEnv), strPathPair, loc) =>
        let
          val tyEnv =
              NPEnv.foldli
                (fn (namePath1, tyState, tyEnv) =>
                    let
                      val namePath2 = NameMap.getNamePathFromTyState tyState
                    in
                      replicate (#tyEnv env, namePath2) (tyEnv, namePath1)
                    end)
                NPEnv.empty
                tyStateEnv
          val (decls, varEnv) =
              NPEnv.foldri
                (fn (namePath1, idState, (decls, varEnv)) =>
                    let
                      val namePath2 = NameMap.getNamePathFromIdstate idState
                      val decls =
                          case idState of
                            NameMap.CONID _ => decls
                          | NameMap.EXNID _ => decls
                          | NameMap.VARID _ =>
                            E.ECVAL (namePath1, E.ECVAR namePath2) :: decls
                    in
                      (decls,
                       replicate (#varEnv env, namePath2) (varEnv, namePath1))
                    end)
                (nil, NPEnv.empty)
                idStateEnv
        in
          (decls, {tyEnv = tyEnv, varEnv = varEnv})
        end
      | PT.PTINFIXDEC _ => (nil, emptyEnv)
      | PT.PTINFIXRDEC _ => (nil, emptyEnv)
      | PT.PTNONFIXDEC _ => (nil, emptyEnv)
      | PT.PTEMPTY => (nil, emptyEnv)

  and evalDeclList env (ptdecl::ptdecls) =
      let
        val (decls1, env1) = evalDecl env ptdecl
        val env = extendEnv (env, env1)
        val (decls2, env2) = evalDeclList env ptdecls
      in
        (decls1 @ decls2, extendEnv (env1, env2))
      end
    | evalDeclList env nil = (nil, emptyEnv)

  fun evalStrdecl env ptstrdecl =
      case ptstrdecl of
        PT.PTCOREDEC (ptdeclList, loc) =>
        let
          val (_, env) = evalDeclList env ptdeclList
        in
          env
        end
      | PT.PTTRANCONSTRAINT (ptstrdeclList, nameMap1, spec, nameMap2, loc) =>
        (* just ignore spec; ModuleCompiler ensures that variables hidden by
         * spec are never referenced from outside of the structure. *)
        evalStrdeclList env ptstrdeclList
      | PT.PTOPAQCONSTRAINT (ptstrdeclList, nameMap1, spec, nameMap2, loc) =>
        evalStrdeclList env ptstrdeclList
      | PT.PTFUNCTORAPP (prefix, functorName,
                         (argPath, (tyStateEnv, idStateEnv)), loc) =>
        raise Control.Bug "FIXME: FUNCTORAPP: not implemented"
      | PT.PTANDFLATTENED (decunitList, loc) =>
        foldl (fn ((printSigInfo, decUnit), newEnv) =>
                  let
                    val env1 = evalStrdeclList env decUnit
                  in
                    extendEnv (newEnv, env1)
                  end)
              emptyEnv
              decunitList
      | PT.PTSTRLOCAL (ptstrdeclList1, ptstrdeclList2, loc) =>
        let
          val env1 = evalStrdeclList env ptstrdeclList1
          val env = extendEnv (env, env1)
        in
          evalStrdeclList env ptstrdeclList2
        end

  and evalStrdeclList env (ptstrdecl::ptstrdecls) =
      let
        val env1 = evalStrdecl env ptstrdecl
        val env = extendEnv (env, env1)
        val env2 = evalStrdeclList env ptstrdecls
      in
        extendEnv (env1, env2)
      end
    | evalStrdeclList env nil = emptyEnv

  fun evalTopdec env pttopdec =
      case pttopdec of
        PT.PTDECSTR (ptstrdeclList, loc) => evalStrdeclList env ptstrdeclList
      | PT.PTDECSIG (ptsigdecs, loc) => emptyEnv
      | PT.PTDECFUNCTOR (ptfunbinds, loc) =>
        raise Control.Bug "FIXME: DECFUNCTOR: not implemented"

  fun evalTopdecList env (pttopdec::pttopdecs) =
      let
        val env1 = evalTopdec env pttopdec
        val env = extendEnv (env, env1)
        val env2 = evalTopdecList env pttopdecs
      in
        extendEnv (env1, env2)
      end
    | evalTopdecList env nil = emptyEnv

  val toplevelVarEnv =
      foldl (fn ((k,v),z) => NPEnv.insert (z, (k, Path.externPath), v))
            NPEnv.empty
            [("ref", (E.CONID, E.REFFUN)),
             (":=",  (E.VARID, E.ASSIGNFUN)),
             ("::",  (E.CONID, E.IDENTFUN)),
             ("nil", (E.CONID, E.ATOM)),
             ("+",   (E.VARID, E.ATOMFUN 1))]

  val toplevelEnv =
      {tyEnv = NPEnv.empty, varEnv = toplevelVarEnv}

  fun analyze stamp env topdecList =
      (
        Counters.init stamp;
        (evalTopdecList env topdecList, Counters.getCounterStamp ())
      )
      handle exn => raise exn

end
