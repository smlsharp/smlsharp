(*
 * @copyright (C) 2021 SML# Development Team.
 * @author YAMATODANI Kiyoshi
 * @author Atsushi Ohori
 * @author Liu Bochao
 * @author Katsuhiro Ueno
*)
structure ElaborateCore =
struct
  structure A = Absyn
  structure E = ElaborateError
  structure P = PatternCalc
  structure F = FFIAttributes
  datatype loc = datatype Loc.loc

  fun enqueueError (loc, exn) = UserErrorUtils.enqueueError (LOC loc, exn)
  fun seq (SOME (items, _)) = items | seq NONE = nil

  val trueId = Symbol.intern "true"
  val falseId = Symbol.intern "false"
  val consId = Symbol.intern "::"
  val nilId = Symbol.intern "nil"

  fun trueLongvid loc = (false, (nil, (trueId, loc), loc), loc) : A.op_longvid
  fun falseLongvid loc = (false, (nil, (falseId, loc), loc), loc) : A.op_longvid
  fun nilLongvid loc = (false, (nil, (nilId, loc), loc), loc) : A.op_longvid
  fun consVid loc = (consId, loc) : A.vid

  fun checkAllEqual f nil = true
    | checkAllEqual f [x] = true
    | checkAllEqual f (h :: t) = case f h of k => List.all (fn x => f x = k) t

  fun substTyConbind subst (vid, ty, loc) : A.conbind =
      (vid, Option.map (ElaborateTy.substTy subst) ty, loc)

  fun flattenValbind (A.VALBIND bind) r = r ::> bind
    | flattenValbind (A.VALREC (binds, _)) r = flattenValbinds binds r
  and flattenValbinds nil r = r
    | flattenValbinds (valbind :: valbinds) r =
      flattenValbinds valbinds (flattenValbind valbind r)
  fun classifyValbinds (A.VALBIND bind :: valbinds) vals recs =
      classifyValbinds valbinds (vals ::> bind) recs
    | classifyValbinds (A.VALREC (binds, _) :: valbinds) vals recs =
      classifyValbinds valbinds vals (flattenValbinds binds recs)
    | classifyValbinds nil vals recs = (vals, recs)
  val classifyValbinds = fn valbinds => classifyValbinds valbinds NIL NIL

  fun elabFFIAttributes (attrs, loc) : F.attributes =
      foldl
        (fn (attr, attrs) =>
            case Symbol.toString (#1 attr) of
              "cdecl" => attrs # {callingConvention = SOME F.FFI_CDECL}
            | "stdcall" => attrs # {callingConvention = SOME F.FFI_STDCALL}
            | "fastcc" => attrs # {callingConvention = SOME F.FFI_FASTCC}
            | "pure" => attrs # {isPure = true}
            | "fast" => attrs # {fast = true}
            | "unsafe" => attrs # {unsafe = true}
            | "gc" => attrs # {causeGC = true}
            | attr =>
              (enqueueError (loc, E.UndefinedFFIAttribute attr);
               attrs))
        F.defaultFFIAttributes
        attrs

  fun tupleFfiTyrows tys =
      ElaborateTy.tupleRows AbsynUtils.ffiTyLoc tys

  fun tuplePatrows pats =
      map A.PATROW (ElaborateTy.tupleRows AbsynUtils.patLoc pats)

  fun tupleExprows exps =
      map A.EXPROW (ElaborateTy.tupleRows AbsynUtils.expLoc exps)

  fun elabFfiTyrow (lab, ffiTy, loc) =
      (lab, elabFfiTy ffiTy, LOC loc)

  and elabFfiTy ty =
      case ty of
        A.FFITYVAR (_, tyvar) =>
        P.FFITYVAR tyvar
      | A.FFITYRECORD (tyrows, loc) =>
        P.FFITYRECORD (map elabFfiTyrow tyrows, LOC loc)
      | A.FFITYCON (tyseq, tycon, loc) =>
        P.FFITYCON (map elabFfiTy (seq tyseq), tycon, LOC loc)
      | A.FFITYTUPLE (tys, loc) =>
        elabFfiTy (A.FFITYRECORD (tupleFfiTyrows tys, loc))
      | A.FFITYFUN (attrs, (domTys, varTys, _), (ranTys, _), loc) =>
        P.FFITYFUN
          (case attrs of
             NONE => NONE
           | SOME (nil, _) => NONE
           | SOME (attrs, loc) => SOME (elabFFIAttributes (attrs, loc)),
           (map elabFfiTy domTys, Option.map (map elabFfiTy) varTys),
           map elabFfiTy ranTys,
           LOC loc)
      | A.FFITYPAREN (ty, loc) => elabFfiTy ty

  fun elabPat pat =
      case pat of
        A.PATWILD loc =>
        P.PATWILD (LOC loc)
      | A.PATCONST (const, loc) =>
        (
          case const of
            A.REAL _ => enqueueError (loc, E.RealConstantInPattern)
          | _ => ();
          P.PATCONST (const, LOC loc)
        )
      | A.PATID (_, vid, _) =>
        P.PATID vid
      | A.PATAPP (A.PATID (_, longvid, _), pat, loc) =>
        P.PATCON (longvid, elabPat pat, LOC loc)
      | A.PATAPP (pat1, pat2, loc) =>
        (enqueueError (AbsynUtils.patLoc pat1, E.PatappWithoutIdentifier);
         elabPat (A.PATTUPLE ([pat1, pat2], loc)))
      | A.PATINFIX (pat1, vid, pat2, loc) =>
        elabPat
          (A.PATAPP (A.PATID (false, (nil, vid, loc), loc),
                     A.PATTUPLE ([pat1, pat2], loc),
                     loc))
      | A.PATRECORD (patrows, flex, loc) =>
        P.PATRECORD (map elabPatrow patrows, flex, LOC loc)
      | A.PATTUPLE (nil, loc) =>
        elabPat (A.PATCONST (A.UNITCONST, loc))
      | A.PATTUPLE (pats, loc) =>
        elabPat (A.PATRECORD (tuplePatrows pats, false, loc))
      | A.PATLIST (nil, loc) =>
        elabPat (A.PATID (nilLongvid loc))
      | A.PATLIST (exp :: exps, loc) =>
        let
          val loc1 = AbsynUtils.patLoc exp
        in
          elabPat (A.PATINFIX (exp, consVid loc1, A.PATLIST (exps, loc), loc1))
        end
      | A.PATTYPED (pat, ty, loc) =>
        P.PATTYPED (elabPat pat, ElaborateTy.elabAnnotTy ty, LOC loc)
      | A.PATAS ((_, id, _), ty, pat, loc) =>
        P.PATAS (id,
                 Option.map ElaborateTy.elabAnnotTy ty,
                 elabPat pat,
                 LOC loc)
      | A.PATPAREN (pat, loc) => elabPat pat

  and elabPatrow patrow =
      case patrow of
        A.PATROW (lab, pat, loc) =>
        (lab, elabPat pat, LOC loc)
      | A.PATROWVAR (vid, NONE, NONE, loc) =>
        ((RecordLabel.fromSymbol (#1 vid), #2 vid),
         elabPat (A.PATID (false, (nil, vid, loc), loc)),
         LOC loc)
      | A.PATROWVAR (vid, SOME ty, NONE, loc) =>
        ((RecordLabel.fromSymbol (#1 vid), #2 vid),
         elabPat (A.PATTYPED (A.PATID (false, (nil, vid, loc), loc), ty, loc)),
         LOC loc)
      | A.PATROWVAR (vid, ty, SOME pat, loc) =>
        ((RecordLabel.fromSymbol (#1 vid), #2 vid),
         elabPat (A.PATAS ((false, vid, loc), ty, pat, loc)),
         LOC loc)

  fun patappSpine (A.PATAPP (x, y, _)) r = patappSpine x (y :: r)
    | patappSpine x r = (x, r)

  fun mustBeAtpat pat =
      case pat of
        A.PATAPP (_, _, loc) =>
        enqueueError (loc, E.ImproperInfixPattern)
      | A.PATINFIX (_, _, _, loc) =>
        enqueueError (loc, E.ImproperInfixPattern)
      | _ => ()

  fun resolveFrule ((pat, tyOpt, exp, loc) : A.frule) =
      let
        val (id, ty, args) =
            case patappSpine pat nil of
              (* fun atpat vid atpat = ... *)
              (A.PATINFIX (pat1, vid, pat2, loc), nil) =>
              (mustBeAtpat pat1;
               mustBeAtpat pat2;
               (SOME vid, NONE, [A.PATTUPLE ([pat1, pat2], loc)]))
            | (* fun (atpat vid atpat) ... = ... *)
              (A.PATPAREN (A.PATINFIX (pat1, vid, pat2, loc), _), args) =>
              (mustBeAtpat pat1;
               mustBeAtpat pat2;
               (SOME vid, NONE, A.PATTUPLE ([pat1, pat2], loc) :: args))
            | (* fun (vid : ty) ... = ... (SML# extension) *)
              (A.PATPAREN
                 (A.PATTYPED (A.PATID (_, (nil, id, _), _), ty, loc), _),
               args) =>
              (SOME id, SOME (ty, loc), args)
            | (* fun vid ... = ... *)
              (pat as A.PATID (_, (nil, id, _), _), args) =>
              (SOME id, NONE, args)
            | (head, args) =>
              (enqueueError (AbsynUtils.patLoc head, E.IllegalFunctionSymbol);
               (NONE, NONE, args))
        (* fun ... : ty = exp  ===>  fun ... = exp : ty *)
        val exp =
            case tyOpt of
              NONE => exp
            | SOME ty => A.EXPTYPED (exp, ty, loc)
      in
        {id = id, ty = ty, args = args, exp = exp, loc = loc}
      end

  fun elabTypbind (tyvarseq, tycon, ty, loc) =
      (map #2 (seq tyvarseq), tycon, ElaborateTy.elabMonoTy ty, LOC loc)

  fun elabConbind ((_, vid, _), ty, loc) =
      (vid, Option.map ElaborateTy.elabMonoTy ty, LOC loc)

  fun elabDatbind (tyvarseq, tycon, conbinds, loc) =
      (map #2 (seq tyvarseq), tycon, map elabConbind conbinds, LOC loc)

  fun elabWithty NONE = (nil, nil)
    | elabWithty (SOME (typbinds, loc)) =
      case map elabTypbind typbinds of
        nil => (nil, nil)
      | typbinds => (typbinds, [P.DECTYPE (typbinds, LOC loc)])

  fun elabDatatype datbinds withty =
      let
        val datbinds = ElaborateTy.reduceDatbind (datbinds, withty)
      in
        (map elabDatbind datbinds, elabWithty withty)
      end

  fun elabExbind exbind =
      case exbind of
        A.EXBIND ((_, vid, _), ty, loc) =>
        P.EXBIND (vid, Option.map ElaborateTy.elabMonoTy ty, LOC loc)
      | A.EXBINDREP ((_, vid, _), (_, longvid, _), loc) =>
        P.EXBINDREP (vid, longvid, LOC loc)

  fun elabInfixPrec (src, loc) =
      case src of
        NONE => 0
      | SOME "0" => 0
      | SOME "1" => 1
      | SOME "2" => 2
      | SOME "3" => 3
      | SOME "4" => 4
      | SOME "5" => 5
      | SOME "6" => 6
      | SOME "7" => 7
      | SOME "8" => 8
      | SOME "9" => 9
      | SOME src =>
        (enqueueError (loc, E.InvalidFixityPrecedence);
         case Int.fromString src of SOME x => x | NONE => 0)

  fun elabHandleMrule (pat, exp, loc) =
      (elabPat pat, elabExp exp, LOC loc)

  and elabMrule (pat, exp, loc) =
      (elabPat pat, elabExp exp, LOC loc)

  and elabDynamicMrule (tyvars, pat, exp, loc) =
      (ElaborateTy.elabKindedTyvarseq tyvars, elabPat pat, elabExp exp, LOC loc)

  and elabExprow exprow =
      case exprow of
        A.EXPROW (lab, exp, loc) => (lab, elabExp exp, LOC loc)
      | A.EXPROWVAR (vid, NONE, loc) =>
        ((RecordLabel.fromSymbol (#1 vid), #2 vid),
         elabExp (A.EXPID (false, (nil, vid, #2 vid), #2 vid)),
         LOC loc)
      | A.EXPROWVAR (vid, SOME ty, loc) =>
        ((RecordLabel.fromSymbol (#1 vid), #2 vid),
         elabExp
           (A.EXPTYPED (A.EXPID (false, (nil, vid, #2 vid), #2 vid), ty, loc)),
         LOC loc)

  and elabExp ast =
      case ast of
        A.EXPCONST (const, loc) =>
        P.EXPCONST (const, LOC loc)
      | A.EXPSIZEOF (ty, loc) =>
        P.EXPSIZEOF (ElaborateTy.elabMonoTy ty, LOC loc)
      | A.EXPID (_, vid, _) =>
        P.EXPID vid
      | A.EXPRECORD (exprows, loc) =>
        P.EXPRECORD (map elabExprow exprows, LOC loc)
      | A.EXPRECORD_UPDATE (exp, exprows, loc) =>
        P.EXPRECORD_UPDATE (elabExp exp, map elabExprow exprows, LOC loc)
      | A.EXPTUPLE_UPDATE (exp, exps, loc) =>
        elabExp (A.EXPRECORD_UPDATE (exp, tupleExprows exps, loc))
      | A.EXPUPDATE1 (exp1, exp2, loc) =>
        P.EXPUPDATE (elabExp exp1, elabExp exp2, LOC loc)
      | A.EXPUPDATE2 (exp1, exp2, loc) =>
        P.EXPUPDATE (elabExp exp1, elabExp exp2, LOC loc)
      | A.EXPSELECT (lab, loc) =>
        P.EXPSELECT (lab, LOC loc)
      | A.EXPTUPLE (nil, loc) =>
        elabExp (A.EXPCONST (A.UNITCONST, loc))
      | A.EXPTUPLE (exps, loc) =>
        elabExp (A.EXPRECORD (tupleExprows exps, loc))
      | A.EXPLIST (nil, loc) =>
        elabExp (A.EXPID (nilLongvid loc))
      | A.EXPLIST (exp :: exps, loc) =>
        let
          val loc1 = AbsynUtils.expLoc exp
        in
          elabExp (A.EXPINFIX (exp, consVid loc1, A.EXPLIST (exps, loc), loc1))
        end
      | A.EXPAPP (exp1, exp2, loc) =>
        P.EXPAPP (elabExp exp1, elabExp exp2, LOC loc)
      | A.EXPINFIX (exp1, vid, exp2, loc) =>
        elabExp
          (A.EXPAPP
             (A.EXPID (true, (nil, vid, #2 vid), #2 vid),
              A.EXPTUPLE ([exp1, exp2], loc),
              loc))
      | A.EXPSEQ (nil, loc) =>
        elabExp (A.EXPCONST (A.UNITCONST, loc))
      | A.EXPSEQ ([exp], loc) =>
        elabExp exp
      | A.EXPSEQ (exp :: exps, loc) =>
        elabExp
          (A.EXPCASE (exp, [(A.PATWILD loc, A.EXPSEQ (exps, loc), loc)], loc))
      | A.EXPTYPED (exp, ty, loc) =>
        P.EXPTYPED (elabExp exp, ElaborateTy.elabAnnotTy ty, LOC loc)
      | A.EXPANDALSO (exp1, exp2, loc) =>
        elabExp (A.EXPIF (exp1, exp2, A.EXPID (falseLongvid loc), loc))
      | A.EXPORELSE (exp1, exp2, loc) =>
        elabExp (A.EXPIF (exp1, A.EXPID (trueLongvid loc), exp2, loc))
      | A.EXPHANDLE (exp, mrules, loc) =>
        P.EXPHANDLE (elabExp exp, map elabHandleMrule mrules, LOC loc)
      | A.EXPRAISE (exp, loc) =>
        P.EXPRAISE (elabExp exp, LOC loc)
      | A.EXPIF (exp1, exp2, exp3, loc) =>
        elabExp
          (A.EXPCASE
             (exp1,
              [(A.PATID (trueLongvid loc), exp2, loc),
               (A.PATID (falseLongvid loc), exp3, loc)],
              loc))
      | A.EXPWHILE (exp1, exp2, loc) =>
        let
          val vid = (false, (nil, (Symbol.generate NONE, loc), loc), loc)
          val next = A.EXPAPP (A.EXPID vid, A.EXPTUPLE (nil, loc), loc)
        in
          elabExp
            (A.EXPLET
               ([A.DECVAL
                   (NONE,
                    [A.VALREC
                       ([A.VALBIND
                           (A.PATID vid,
                            A.EXPFN
                              ([(A.PATTUPLE (nil, loc),
                                 A.EXPIF
                                   (exp1,
                                    A.EXPSEQ ([exp2, next], loc),
                                    A.EXPTUPLE (nil, loc),
                                    loc),
                                 loc)],
                               loc),
                            loc)],
                        loc)],
                    loc)],
                ([next], loc),
                loc))
        end
      | A.EXPCASE (exp, mrules, loc) =>
        P.EXPCASE (elabExp exp, map elabMrule mrules, LOC loc)
      | A.EXPFN (mrules, loc) =>
        P.EXPFN (map elabMrule mrules, LOC loc)
      | A.EXPLET (decs, (exps, loc1), loc) =>
        P.EXPLET (elabDecs decs, elabExp (A.EXPSEQ (exps, loc1)), LOC loc)
      | A.EXPIMPORT_NAME ((name, _), ty, loc) =>
        P.EXPIMPORT_NAME (name, elabFfiTy ty, LOC loc)
      | A.EXPIMPORT_EXP (exp, ty, loc) =>
        P.EXPIMPORT_EXP (elabExp exp, elabFfiTy ty, LOC loc)
      | A.EXPSQL sqlexp =>
        ElaborateSQL.elaborateExp
          {elabExp = elabExp, elabPat = elabPat}
          sqlexp
      | A.EXPFOREACH_ARRAY foreach =>
        ElaborateForeach.elaborateForeachArray
          {elabExp = elabExp, elabPat = elabPat}
          foreach
      | A.EXPFOREACH_DATA foreach =>
        ElaborateForeach.elaborateForeachData
          {elabExp = elabExp, elabPat = elabPat}
          foreach
      | A.EXPJOIN (exp1, exp2, loc) =>
        P.EXPJOIN (P.JOIN, elabExp exp1, elabExp exp2, LOC loc)
      | A.EXPEXTEND (exp1, exp2, loc) =>
        P.EXPJOIN (P.EXTEND, elabExp exp1, elabExp exp2, LOC loc)
      | A.EXPDYNAMIC_AS (exp, ty, loc) =>
        P.EXPDYNAMIC_AS (elabExp exp, ElaborateTy.elabMonoTy ty, LOC loc)
      | A.EXPDYNAMIC_OF (exp, ty, loc) =>
        P.EXPDYNAMIC_OF (elabExp exp, ElaborateTy.elabMonoTy ty, LOC loc)
      | A.EXPDYNAMICNULL (ty, loc) =>
        P.EXPDYNAMICNULL (ElaborateTy.elabMonoTy ty, LOC loc)
      | A.EXPDYNAMICTOP (ty, loc) =>
        P.EXPDYNAMICTOP (ElaborateTy.elabMonoTy ty, LOC loc)
      | A.EXPDYNAMICVIEW (exp, ty, loc) =>
        P.EXPDYNAMICVIEW (elabExp exp, ElaborateTy.elabMonoTy ty, LOC loc)
      | A.EXPDYNAMICCASE (exp, mrules, loc) =>
        P.EXPDYNAMICCASE (elabExp exp, map elabDynamicMrule mrules, LOC loc)
      | A.EXPREIFYTY (ty, loc) =>
        P.EXPREIFYTY (ElaborateTy.elabMonoTy ty, LOC loc)
      | A.EXPPAREN (exp, loc) => elabExp exp

  and elabValbind (pat, exp, loc) =
      (elabPat pat, elabExp exp, LOC loc)

  and elabRecbind (pat, exp, loc) =
      (case exp of
         A.EXPFN _ => ()
       | _ => enqueueError (loc, E.NotFnBoundInValRec);
       (elabPat pat, elabExp exp, LOC loc))

  and elabPvalbind (vid, ty, exp, loc) =
      (vid, ElaborateTy.elabPolyTy ty, elabExp exp, LOC loc)

  and elabPvalbinds (NONE, NIL, recbinds as _ ::> _) =
      let
        val recbinds = Snoc.toList recbinds
        val pvalbinds =
            List.mapPartial
              (fn (A.PATTYPED (A.PATID (_, (nil, v, _), _), ty, _), exp, loc) =>
                  SOME (v, ty, exp, loc)
                | _ => NONE)
              recbinds
      in
        if length recbinds = length pvalbinds
           andalso List.exists (ElaborateTy.isPolyTy o #2) pvalbinds
        then SOME (map elabPvalbind pvalbinds)
        else NONE
      end
    | elabPvalbinds _ = NONE

  and elabFvalbind ((frules, loc) : A.fvalbind) =
      let
        val frules = map resolveFrule frules
        val first = hd frules handle _ => raise Bug.Bug "elabFvalbind"
        val _ =
            if checkAllEqual (Option.map #1 o #id) frules
            then ()
            else enqueueError (loc, E.NotAllHaveSameFunctionName)
        val _ =
            if checkAllEqual (length o #args) frules
            then ()
            else enqueueError (loc, E.NotAllHaveSameNumberPatterns)
        val _ =
            case #args first of
              nil => enqueueError (loc, E.FunctionParameterNotFound)
            | _ :: _ => ()
        val vid =
            case #id first of
              SOME id => id
            | NONE => case List.find (isSome o #id) frules of
                        SOME {id = SOME id, ...} => id
                      | _ => (Symbol.generate NONE, loc)
        val tys =
            map (fn (ty, loc) => (ElaborateTy.elabAnnotTy ty, LOC loc))
                (List.mapPartial #ty frules)
        val rules = map (fn {args, exp, loc, ...} =>
                            (map elabPat args, elabExp exp, LOC loc))
                        frules
      in
        (vid, tys, rules, LOC loc)
      end

  and elabDec dec =
      case dec of
        A.DECVAL (tyvarseq, valbinds, loc) =>
        let
          val (valbinds, recbinds) = classifyValbinds valbinds
        in
          case elabPvalbinds (tyvarseq, valbinds, recbinds) of
            SOME pvalbinds =>
            [P.DECPOLYREC (pvalbinds, LOC loc)]
          | NONE =>
            [P.DECVAL (ElaborateTy.elabKindedTyvarseq tyvarseq,
                       map elabValbind (Snoc.toList valbinds),
                       map elabRecbind (Snoc.toList recbinds),
                       LOC loc)]
        end
      | A.DECVALREC (arg as (tyvarseq, valrecbinds, loc)) =>
        [P.DECVAL (ElaborateTy.elabKindedTyvarseq tyvarseq,
                   nil,
                   map elabValbind valrecbinds,
                   LOC loc)]
      | A.DECFUN (tyvs, fvalbinds, loc) =>
        [P.DECFUN (ElaborateTy.elabKindedTyvarseq tyvs,
                   map elabFvalbind fvalbinds,
                   LOC loc)]
      | A.DECTYPE (typbinds, loc) =>
        [P.DECTYPE (map elabTypbind typbinds, LOC loc)]
      | A.DECDATATYPE (datbinds, withty, loc) =>
        let
          val (datbinds, (typbinds, typeDecs)) = elabDatatype datbinds withty
        in
          P.DECDATATYPE (datbinds, typbinds, LOC loc) :: typeDecs
        end
      | A.DECDATATYPEREP (tycon, longtycon, loc) =>
        [P.DECDATATYPEREP (tycon, longtycon, LOC loc)]
      | A.DECABSTYPE (datbinds, typbinds, decs, loc) =>
        let
          val (datbinds, (typbinds, typeDecs)) = elabDatatype datbinds typbinds
          val decs = elabDecs decs
        in
          [P.DECABSTYPE (datbinds, typbinds, typeDecs @ decs, LOC loc)]
        end
      | A.DECEXCEPTION (exbinds, loc) =>
        [P.DECEXCEPTION (map elabExbind exbinds, LOC loc)]
      | A.DECLOCAL (decs1, decs2, loc) =>
        [P.DECLOCAL (elabDecs decs1, elabDecs decs2, LOC loc)]
      | A.DECOPEN (ids, loc) =>
        [P.DECOPEN (ids, LOC loc)]
      | A.DECINFIX _ => nil
      | A.DECINFIXR _ => nil
      | A.DECNONFIX _ => nil
      | A.DECDO (exp, loc) =>
        elabDec
          (A.DECVAL (NONE, [A.VALBIND (A.PATTUPLE (nil, loc), exp, loc)], loc))
      | A.DECSEMICOLON _ => nil

  and elabDecs decs =
      List.concat (map elabDec decs)

end
