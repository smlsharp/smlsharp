(**
 * @copyright (c) 2008, Tohoku University.
 * @author UENO Katsuhiro
 * @version $Id: EffectCalcPickler.sml,v 1.4 2008/05/08 09:06:03 katsu Exp $
 *)

structure EffectCalcPickler : sig

  val effectVarEnv : EffectCalc.effectVarEnv Pickle.pu
  val ecvalue : EffectCalc.ecvalue Pickle.pu
  val ecexp : EffectCalc.ecexp Pickle.pu
  val idstate : EffectCalc.idstate Pickle.pu

end =
struct

  structure P = Pickle
  structure E = EffectCalc

  (* dummy for mutual-recursive pickler *)
  val dummyValue = E.ATOM
  val dummyExp = E.ECVALUE E.ATOM
  val dummyDecl = E.ECEFFECT

  val (ecvalueFunctions, ecvalue) = P.makeNullPu dummyValue
  val (ecexpFunctions, ecexp) = P.makeNullPu dummyExp
  val (ecdeclFunctions, ecdecl) = P.makeNullPu dummyDecl

  val varId = NameMapPickler.namePath

  local
    fun pu_CONID pu = P.con0 E.CONID pu
    fun pu_VARID pu = P.con0 E.VARID pu
    fun toInt E.CONID = 0
      | toInt E.VARID = 1
  in
  val idstate =
      P.data
        (
          toInt,
          [
            pu_CONID,    (* 0 *)
            pu_VARID     (* 1 *)
          ]
        )
  end

  val effectVarEnv = NameMapPickler.NPEnv (P.tuple2 (idstate, ecvalue))

  local
    fun pu_CLOSURE pu =
        P.con1
          E.CLOSURE
          (fn E.CLOSURE x => x
            | _ => raise Control.Bug "CLOSURE expected: EffectCalcPickler")
          (P.tuple3 (effectVarEnv, P.list varId, ecexp))

    fun pu_SELECTOR pu =
        P.con1
          E.SELECTOR
          (fn E.SELECTOR x => x
            | _ => raise Control.Bug "SELECTOR expected: EffectCalcPickler")
          P.string

    fun pu_BOTTOMFUN pu =
        P.con1
           E.BOTTOMFUN
           (fn E.BOTTOMFUN x => x
             | _ => raise Control.Bug "BOTTOMFUN expected: EffectCalcPickler")
           P.int

    fun pu_ATOMFUN pu =
        P.con1
           E.ATOMFUN
           (fn E.ATOMFUN x => x
             | _ => raise Control.Bug "ATOMFUN expected: EffectCalcPickler")
           P.int

    fun pu_IDENTFUN pu = P.con0 E.IDENTFUN pu
    fun pu_REFFUN pu = P.con0 E.REFFUN pu
    fun pu_ASSIGNFUN pu = P.con0 E.ASSIGNFUN pu
    fun pu_BOTTOM pu = P.con0 E.BOTTOM pu
    fun pu_ATOM pu = P.con0 E.ATOM pu

    fun pu_RECORD pu =
        P.con1
          E.RECORD
          (fn E.RECORD x => x
            | _ => raise Control.Bug "RECORD expected: EffectCalcPickler")
          (EnvPickler.SEnv ecvalue)

    fun pu_UNION pu =
        P.con1
          E.UNION
          (fn E.UNION x => x
            | _ => raise Control.Bug "UNION expected: EffectCalcPickler")
          (P.tuple2 (ecvalue, ecvalue))

    fun pu_RAISE pu = P.con0 E.RAISE pu
    fun pu_WRONG pu = P.con0 E.WRONG pu

    fun toInt (E.CLOSURE _) = 0
      | toInt (E.SELECTOR _) = 1
      | toInt (E.BOTTOMFUN _) = 2
      | toInt (E.ATOMFUN _) = 3
      | toInt E.IDENTFUN = 4
      | toInt E.REFFUN = 5
      | toInt E.ASSIGNFUN = 6
      | toInt E.BOTTOM = 7
      | toInt E.ATOM = 8
      | toInt (E.RECORD _) = 9
      | toInt (E.UNION _) = 10
      | toInt E.RAISE = 11
      | toInt E.WRONG = 12
  in

  val pu_ecvalue =
      P.data
        (
          toInt,
          [
            pu_CLOSURE,    (* 0 *)
            pu_SELECTOR,   (* 1 *)
            pu_BOTTOMFUN,  (* 2 *)
            pu_ATOMFUN,    (* 3 *)
            pu_IDENTFUN,   (* 4 *)
            pu_REFFUN,     (* 5 *)
            pu_ASSIGNFUN,  (* 6 *)
            pu_BOTTOM,     (* 7 *)
            pu_ATOM,       (* 8 *)
            pu_RECORD,     (* 9 *)
            pu_UNION,      (* 10 *)
            pu_RAISE,      (* 11 *)
            pu_WRONG       (* 12 *)
          ]
        )
  end

  local

    fun pu_ECVALUE pu =
        P.con1
          E.ECVALUE
          (fn E.ECVALUE x => x
            | _ => raise Control.Bug "ECVALUE expected: EffectCalcPickler")
          ecvalue

    fun pu_ECVAR pu =
        P.con1
          E.ECVAR
          (fn E.ECVAR x => x
            | _ => raise Control.Bug "ECVAR expected: EffectCalcPickler")
          varId

    fun pu_ECFN pu =
        P.con1
          E.ECFN
          (fn E.ECFN x => x
            | _ => raise Control.Bug "ECFN expected: EffectCalcPickler")
          (P.tuple2 (P.list varId, ecexp))

    fun pu_ECAPP pu =
        P.con1
          E.ECAPP
          (fn E.ECAPP x => x
            | _ => raise Control.Bug "ECAPP expected: EffectCalcPickler")
          (P.tuple2 (ecexp, P.list ecexp))

    fun pu_ECLET pu =
        P.con1
          E.ECLET
          (fn E.ECLET x => x
            | _ => raise Control.Bug "ECLET expected: EffectCalcPickler")
          (P.tuple2 (P.list ecdecl, ecexp))

    fun pu_ECPARALLEL pu =
        P.con1
          E.ECPARALLEL
          (fn E.ECPARALLEL x => x
            | _ => raise Control.Bug "ECPARALLEL expected: EffectCalcPickler")
          (P.tuple2 (ecexp, ecexp))

    fun pu_ECRECORD pu =
        P.con1
          E.ECRECORD
          (fn E.ECRECORD x => x
            | _ => raise Control.Bug "ERECORD expected: EffectCalcPickler")
          (P.list (P.tuple2 (P.string, ecexp)))

    fun pu_ECSELECT pu =
        P.con1
          E.ECSELECT
          (fn E.ECSELECT x => x
            | _ => raise Control.Bug "ECSELECT expected: EffectCalcPickler")
          (P.tuple2 (P.string, ecexp))

    fun pu_ECMODIFY pu =
        P.con1
          E.ECMODIFY
          (fn E.ECMODIFY x => x
            | _ => raise Control.Bug "ECMODIFY expected: EffectCalcPickler")
          (P.tuple2 (ecexp, P.list (P.tuple2 (P.string, ecexp))))

    fun pu_ECDEREF pu =
        P.con1
          E.ECDEREF
          (fn E.ECDEREF x => x
            | _ => raise Control.Bug "ECDEREF expected: EffectCalcPickler")
          ecexp

    fun toInt (E.ECVALUE _) = 0
      | toInt (E.ECVAR _) = 1
      | toInt (E.ECFN _) = 2
      | toInt (E.ECAPP _) = 3
      | toInt (E.ECLET _) = 4
      | toInt (E.ECPARALLEL _) = 5
      | toInt (E.ECRECORD _) = 6
      | toInt (E.ECSELECT _) = 7
      | toInt (E.ECMODIFY _) = 8
      | toInt (E.ECDEREF _) = 9
  in

  val pu_ecexp =
      P.data
        (
          toInt,
          [
            pu_ECVALUE,     (* 0 *)
            pu_ECVAR,       (* 1 *)
            pu_ECFN,        (* 2 *)
            pu_ECAPP,       (* 3 *)
            pu_ECLET,       (* 4 *)
            pu_ECPARALLEL,  (* 5 *)
            pu_ECRECORD,    (* 6 *)
            pu_ECSELECT,    (* 7 *)
            pu_ECMODIFY,    (* 8 *)
            pu_ECDEREF      (* 9 *)
          ]
        )
  end

  local

    fun pu_ECVAL pu =
        P.con1
          E.ECVAL
          (fn E.ECVAL x => x
            | _ => raise Control.Bug "ECVAL expected: EffectCalcPickler")
          (P.tuple2 (varId, ecexp))

    fun pu_ECLOCAL pu =
        P.con1
          E.ECLOCAL
          (fn E.ECLOCAL x => x
            | _ => raise Control.Bug "ECLOCAL expected: EffectCalcPickler")
          (P.tuple2 (P.list ecdecl, P.list ecdecl))

    fun pu_ECANDVAL pu =
        P.con1
          E.ECANDVAL
          (fn E.ECANDVAL x => x
            | _ => raise Control.Bug "ECANDVAL expected: EffectCalcPickler")
          (P.list (P.list ecdecl))

    fun pu_ECIGNORE pu =
        P.con1
          E.ECIGNORE
          (fn E.ECIGNORE x => x
            | _ => raise Control.Bug "ECIGNORE expected: EffectCalcPickler")
          ecexp

    fun pu_ECEFFECT pu = P.con0 E.ECEFFECT pu

    fun toInt (E.ECVAL _) = 0
      | toInt (E.ECLOCAL _) = 1
      | toInt (E.ECANDVAL _) = 2
      | toInt (E.ECIGNORE _) = 3
      | toInt E.ECEFFECT = 4
  in

  val pu_ecdecl =
      P.data
        (
          toInt,
          [
            pu_ECVAL,       (* 0 *)
            pu_ECLOCAL,     (* 1 *)
            pu_ECANDVAL,    (* 2 *)
            pu_ECIGNORE,    (* 3 *)
            pu_ECEFFECT     (* 4 *)
          ]
        )
  end


  val _ = P.updateNullPu ecvalueFunctions pu_ecvalue
  val _ = P.updateNullPu ecexpFunctions pu_ecexp
  val _ = P.updateNullPu ecdeclFunctions pu_ecdecl

end
