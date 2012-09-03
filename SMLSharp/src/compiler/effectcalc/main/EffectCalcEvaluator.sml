(**
 * effect calc evaluator
 * @copyright (c) 2008, Tohoku University.
 * @author UENO Katsuhiro
 * @version $Id: EffectCalcEvaluator.sml,v 1.6 2008/05/09 03:55:27 katsu Exp $
 *)

structure EffectCalcEvaluator : sig

  val evalExp : EffectCalc.effectVarEnv
                -> EffectCalc.ecexp
                -> EffectCalc.ecvalue * bool  (* value * effect *)

  val evalDeclList : EffectCalc.effectVarEnv
                     -> EffectCalc.ecdecl list
                     -> EffectCalc.effectVarEnv * bool

end =
struct

val nest = ref 0

  structure NPEnv = NameMap.NPEnv
  structure E = EffectCalc

  exception Effect

  fun ifWrong (value1, value2) =
      case value1 of E.WRONG => value1 | _ => value2

  fun evalSelect (label, recordValue) =
      case recordValue of
        E.UNION (value1, value2) =>
        let
          val newValue1 = evalSelect (label, value1)
          val newValue2 = evalSelect (label, value2)
        in
          E.UNION (ifWrong (newValue1, value1), ifWrong (newValue2, value2))
        end
      | E.RECORD fields =>
        (
          case SEnv.find (fields, label) of
            SOME x => x
          | NONE => E.WRONG
        )
      | E.RAISE => E.RAISE
      | E.BOTTOM => E.BOTTOM
      | _ => E.WRONG

  fun evalModify (recordValue, newValues) =
      case recordValue of
        E.UNION (value1, value2) =>
        let
          val newValue1 = evalModify (value1, newValues)
          val newValue2 = evalModify (value2, newValues)
        in
          E.UNION (ifWrong (newValue1, value1), ifWrong (newValue2, value2))
        end
      | E.RECORD fields =>
        E.RECORD (SEnv.unionWith #2 (fields, newValues))
      | E.RAISE => E.RAISE
      | E.BOTTOM => E.BOTTOM
      | _ => E.WRONG

  fun assignArgs (env, var::vars, value::values) =
      assignArgs (NPEnv.insert (env, var, (E.VARID, value)), vars, values)
    | assignArgs (env, var::vars, nil) =
      assignArgs (NPEnv.insert (env, var, (E.VARID, E.BOTTOM)), vars, nil)
    | assignArgs (env, nil, _) = env

  fun evalApp (funValue, argValues) =
      case funValue of
        E.CLOSURE (closureEnv, argVars, bodyExp) =>
        let
          val newEnv = assignArgs (closureEnv, argVars, argValues)
        in
          evalExp newEnv bodyExp
        end
      | E.UNION (value1, value2) =>
        let
          val (newValue1, e1) = evalApp (value1, argValues)
          val (newValue2, e2) = evalApp (value2, argValues)
        in
          (E.UNION (ifWrong (newValue1, value1), ifWrong (newValue2, value2)),
           e1 orelse e2)
        end
      | E.SELECTOR label =>
        (
          case argValues of
            [x] => evalSelect (label, x)
          | _ => E.WRONG,
          false
        )
      | E.BOTTOMFUN n =>
        (if n > 0 then E.BOTTOMFUN (n - 1) else E.BOTTOM, false)
      | E.ATOMFUN n =>
        (if n > 0 then E.ATOMFUN (n - 1) else E.ATOM, false)
      | E.IDENTFUN =>
        (
          case argValues of
            [x] => x
          | _ => E.WRONG,
          false
        )
      | E.REFFUN => (E.ATOM, true)        (* return unit with effect *)
      | E.ASSIGNFUN => (E.ATOM, false)    (* NOTE: assignment has no effect *)
      | E.BOTTOM => (E.BOTTOM, true)      (* unpredictable result *)
      | E.ATOM => (E.WRONG, false)        (* type error *)
      | E.RECORD _ => (E.WRONG, false)    (* type error *)
      | E.WRONG => (E.WRONG, false)       (* type error *)
      | E.RAISE => (E.RAISE, false)       (* ignore this application *)

  and evalRecord env fields =
      foldl (fn ((label, exp), (record, e1)) =>
                let
                  val (value, e2) = evalExp env exp
                in
                  (SEnv.insert (record, label, value), e1 orelse e2)
                end)
            (SEnv.empty, false)
            fields

  and evalExp env ecexp =
let
val _ = nest := !nest + 1
val _ = print ("----evalExp "^Int.toString (!nest)^"----\n")
val _ = print (EffectCalcFormatter.ecexpToString ecexp)
val _ = print "\n- - - - - - - - -\n"
val ret as (value, e) = evalExp' env ecexp
val _ = print "return:\n"
val _ = print (EffectCalcFormatter.ecvalueToString value)
val _ = print "\n"
val _ = print ("effect: "^(if e then "true" else "false"))
val _ = print ("\n-------"^Int.toString (!nest)^"---------\n")
val _ = nest := !nest - 1
in
  ret
end

  and evalExp' env ecexp =
      case ecexp of
        E.ECVALUE value => (value, false)
      | E.ECVAR varId =>
        (
          case NPEnv.find (env, varId) of
            SOME (_, x) => x
          | NONE => raise Control.Bug "evalExp: unbound variable",
          false
        )
      | E.ECFN (argVars, bodyExp) =>
        (E.CLOSURE (env, argVars, bodyExp), false)
      | E.ECAPP (funExp, argExps) =>
        let
          val (funValue, e1) = evalExp env funExp
          val (argValues, e2) = evalExpList env argExps
          val (value, e3) = evalApp (funValue, argValues)
        in
          (value, e1 orelse e2 orelse e3)
        end
      | E.ECLET (ecdecls, ecexp2) =>
        let
          val (env1, e1) = evalDeclList env ecdecls
          val env = NPEnv.unionWith #2 (env, env1)
          val (value2, e2) = evalExp env ecexp2
        in
          (value2, e1 orelse e2)
        end
      | E.ECPARALLEL (ecexp1, ecexp2) =>
        let
          val (value1, e1) = evalExp env ecexp1
          val (value2, e2) = evalExp env ecexp2
        in
          (E.UNION (value1, value2), e1 orelse e2)
        end
      | E.ECRECORD fields =>
        let
          val (record, e) = evalRecord env fields
        in
          (E.RECORD record, e)
        end
      | E.ECSELECT (label, ecexp) =>
        let
          val (value, e) = evalExp env ecexp
        in
          (evalSelect (label, value), e)
        end
      | E.ECMODIFY (ecexp1, fields) =>
        let
          val (value1, e1) = evalExp env ecexp1
          val (record, e2) = evalRecord env fields
        in
          (evalModify (value1, record), e1 orelse e2)
        end
      | E.ECDEREF ecexp =>
        let
          val (value, e) = evalExp env ecexp
        in
          (* NOTE: dereference has no effect *)
          (E.BOTTOM, e)
        end

  and evalExpList env (ecexp::ecexps) =
      let
        val (value, e1) = evalExp env ecexp
        val (values, e2) = evalExpList env ecexps
      in
        (value::values, e1 orelse e2)
      end
    | evalExpList env nil = (nil, false)


  and evalDecl env ecdecl =
let
val _ = nest := !nest + 1
val _ = print ("----evalDecl "^Int.toString (!nest)^"----\n")
val _ = print (Control.prettyPrint (EffectCalc.format_effectVarEnv env)^"\n")
val _ = print (EffectCalcFormatter.ecdeclToString ecdecl)
val _ = print "\n- - - - - - - - -\n"
val ret as (varEnv, e) = evalDecl' env ecdecl
val _ = print "return:\n"
val _ = print (Control.prettyPrint (EffectCalc.format_effectVarEnv varEnv))
val _ = print "\n"
val _ = print ("effect: "^(if e then "true" else "false"))
val _ = print ("\n-------"^Int.toString (!nest)^"---------\n")
val _ = nest := !nest - 1
in
  ret
end

  and evalDecl' env ecdecl =
      case ecdecl of
        E.ECVAL (varId, ecexp) =>
        let
          val (value, e) = evalExp env ecexp
        in
          (NPEnv.singleton (varId, (E.VARID, value)), e)
        end
      | E.ECLOCAL (ecdecls1, ecdecls2) =>
        let
          val (env1, e1) = evalDeclList env ecdecls1
          val env = NPEnv.unionWith #2 (env, env1)
          val (env2, e2) = evalDeclList env ecdecls2
        in
          (env2, e1 orelse e2)
        end
      | E.ECANDVAL decls =>
        foldl (fn (ecdecls, (newEnv, e)) =>
                  let
                    val (env1, e1) = evalDeclList env ecdecls
                  in
                    (NPEnv.unionWith #2 (newEnv, env1), e orelse e1)
                  end)
              (NPEnv.empty, false)
              decls
      | E.ECIGNORE ecexp =>
        let
          val (_, e) = evalExp env ecexp
        in
          (NPEnv.empty, e)
        end
      | E.ECEFFECT => (NPEnv.empty, true)

  and evalDeclList env (ecdecl::ecdecls) =
      let
        val (env1, e1) = evalDecl env ecdecl
        val env = NPEnv.unionWith #2 (env, env1)
        val (env2, e2) = evalDeclList env ecdecls
      in
        (NPEnv.unionWith #2 (env1, env2), e1 orelse e2)
      end
    | evalDeclList env nil = (NPEnv.empty, false)

end
