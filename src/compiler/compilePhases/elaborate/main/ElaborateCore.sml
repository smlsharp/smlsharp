(**
 * @copyright (C) 2021 SML# Development Team.
 * @author UENO Katsuhiro
 * @author Atsushi Ohori
 * @author YAMATODANI Kiyoshi
 *)
(*
 Elaborator.
 In this pahse, we do the following:
 1. infix elaboration
 2. expand derived form (incomplete; revise later)
   (1) tuples => records
   (2) datatype withtype t = ty => datatype[ty/t] + type t = ty
   (3) while term
   (4) if term

 A note on infix resolution
  About infix identifier, the Definition of Standard ML describes:
    (page 6) The only required use of op is in prefixing a non-infixed
    occurrence of an identifier symbol which has infix status; elsewhere op,
    where permitted, has no effect.
  This means, if symbol has infix status, occurrences of symbol without using op:
    elm symbol elm
  are accepted (elm is either an expression or a pattern), but non-infixed
  occurrences without using op:
    symbol
    ... elm symbol
    symbol elm ...
  are rejected.

 * A while expression
 *   while cond do body
 * is transformed to:
 *   let
 *     val rec f =
 *             fn () =>
 *                  (fn true => (fn _ => f ()) body
 *                    | false => ())
 *                  cond
 *   in f () end
 *
 * @copyright (C) 2021 SML# Development Team.
 * @author YAMATODANI Kiyoshi
 * @author Atsushi Ohori
 * @author Liu Bochao
 * @author Katsuhiro Ueno
 * @version $Id: Elaborator.sml,v 1.105.6.8 2010/02/10 05:17:29 hiro-en Exp $
*)
(*
sig
  val elabFFITy : Absyn.ffiTy -> PatternCalc.ffiTy
  val elabDec : Fixity.fixity SEnv.map
                -> Absyn.dec
                -> PatternCalc.pdecl list * Fixity.fixity SEnv.map
end
*)
structure ElaborateCore =
struct
  structure EU = UserErrorUtils
  structure E = ElaborateError

  structure A = Absyn
  structure PC = PatternCalc
  structure F = FFIAttributes
  datatype loc = datatype Loc.loc
  type loc = A.loc
  type symbol = Symbol.symbol
  type longsymbol = Longsymbol.longsymbol

  val eqLongsymbol = SymbolWithLoc.eqLongsymbol
  val eqSymbol = SymbolWithLoc.eqSymbol

  val initializeErrorQueue = EU.initializeErrorQueue
  val getErrorsAndWarnings = EU.getErrorsAndWarnings
  val getErrors = EU.getErrors
  val getWarnings = EU.getWarnings
  fun enqueueError (loc, exn) = EU.enqueueError (LOC loc, exn)
  val emptyTvars = (nil, Loc.NOLOC) : PC.scopedTvars

  fun bug s = Bug.Bug ("ElaborateCore: " ^ s)

  fun toSymbol ((sym, loc):A.vid) = {symbol = sym, loc = LOC loc}
  fun toLongsymbol ((ids,loc):A.longvid) =
      {symbols = map toSymbol ids, loc = LOC loc}
  fun seq (SOME (items, _)) = items | seq NONE = nil
  fun seq' (SOME (items, loc)) = (items, LOC loc) | seq' NONE = (nil, Loc.NOLOC)

  fun checkAllEqual f nil = true
    | checkAllEqual f [x] = true
    | checkAllEqual f (h :: t) = case f h of k => List.all (fn x => f x = k) t

  fun getLabelOfPatRow (A.PATROW((label, _), _, _)) = label
    | getLabelOfPatRow (A.PATROWVAR(label, _, _, _)) =
      RecordLabel.fromSymbol (#1 label)

  fun classifyValbinds valbinds =
      let
        val (valbinds, recbinds) =
            ListPair.unzip
              (map (fn A.VALBIND bind => ([bind], nil)
                     | A.VALREC bind => (nil, [A.VALREC bind]))
                   valbinds)
      in
        (List.concat valbinds, List.concat recbinds)
      end
  fun flattenValbind (A.VALBIND bind) = [bind]
    | flattenValbind (A.VALREC (binds, _)) = flattenValbinds binds
  and flattenValbinds valbinds =
      List.concat (map flattenValbind valbinds)

  fun elabFFIAttributes loc attr : F.attributes =
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
              (enqueueError (loc, E.UndefinedFFIAttribute {attr=attr});
               attrs))
        F.defaultFFIAttributes
        attr

  fun substTyVarInTy substFun ty =
    let
      fun subst ty =
        case ty of
          A.TYWILD _ => ty
        | A.TYVAR tyVar => substFun tyVar
        | A.TYVAR_FREE (freeTvar, tvarKind, loc) =>
          raise Bug.Bug "TYVAR_FREE in substTyVarInTy"
        | A.TYRECORD (labelTys, ifFlex, loc) =>
            let
              val newLabelTys =
                map (fn (label, ty, loc) => (label, subst ty, loc)) labelTys
            in
              A.TYRECORD (newLabelTys, ifFlex, loc)
            end
        | A.TYCON (NONE, tyConPath, loc) => ty
        | A.TYCON (SOME (argTys, argTysLoc), tyConPath, loc) =>
            let val newArgTys = map subst argTys
            in A.TYCON(SOME (newArgTys, argTysLoc), tyConPath, loc)
            end
        | A.TYTUPLE(tys, loc) =>
          A.TYTUPLE(map subst tys, loc)
        | A.TYFUN(rangeTy, domainTy, loc) =>
          A.TYFUN(subst rangeTy, subst domainTy, loc)
        | A.TYPOLY(tvarList, ty, loc) => 
          let
            val shadowNameList =
                Symbol.Set.fromList
                  (map (fn ((_, (symbol, _)), _, _) => symbol) (#1 tvarList))
            fun newSubstFun  (tyID as (_, (symbol, loc))) =
                if Symbol.Set.member (shadowNameList, symbol)
                then A.TYVAR tyID
                else substFun tyID
          in
            A.TYPOLY(tvarList, substTyVarInTy newSubstFun ty, loc)
          end
        | A.TYPAREN (ty, loc) => subst ty
    in
      subst ty
    end

  fun expandWithTypesInDataBind (withTypeBinds : A.typbind list) =
      let
        fun replaceTyVarInTyWithTy (tyVars, argTys) ty =
            let
              val tyVarMap = 
                  foldr
                    (fn ((tyVar, destTy), map) =>
                        Symbol.Map.insert(map, tyVar, destTy))
                    Symbol.Map.empty
                    (ListPair.zip(tyVars, argTys))
              fun subst (tyID as (isEq, (symbol, loc))) =
                  case Symbol.Map.find(tyVarMap, symbol) of
                    NONE =>
                    (enqueueError(loc, E.NotBoundTyvar {tyvar = symbol});
                     A.TYVAR tyID)
                  | SOME destTy => destTy
            in substTyVarInTy subst ty
            end
        val typeMap =
            foldr
            (fn ((tyargs, (symbol, _), ty, _), map) =>
                Symbol.Map.insert(map, symbol, (seq tyargs, ty)))
            Symbol.Map.empty
            withTypeBinds
        fun expandInTy ty =
            case ty of
              A.TYWILD _ => ty
            | A.TYVAR _ => ty
            | A.TYVAR_FREE _ => ty
            | A.TYRECORD (labelTys, ifFlex, loc) =>
              let
                val newLabelTys =
                    map (fn (label, ty, loc) => (label, expandInTy ty, loc)) labelTys
              in
                A.TYRECORD (newLabelTys, ifFlex, loc)
              end
            | A.TYCON (tyseq, tyConPath, loc) =>
              let
                val expandedTyseq =
                    case tyseq of
                      SOME (tys, loc) => SOME (map expandInTy tys, loc)
                    | NONE => NONE
              in
                case #1 tyConPath of
                  [tyConName] =>
                  (case Symbol.Map.find (typeMap, #1 tyConName) of
                     SOME (withTyVars, withTy) =>
                     let
                       val withTyVarNames = map (#1 o #2) withTyVars
                       val withTyVarsLen = List.length withTyVars
                       val expandedArgTys =
                           getOpt (Option.map #1 expandedTyseq, nil)
                       val givenTyLen = List.length expandedArgTys
                     in
                        if withTyVarsLen = givenTyLen
                        then
                          replaceTyVarInTyWithTy
                              (withTyVarNames, expandedArgTys) withTy
                        else
                          let
                            val exn = 
                                E.ArityMismatchInTypeDeclaration
                                    {
                                      tyCon = #1 tyConName,
                                      wants = withTyVarsLen,
                                      given = givenTyLen
                                    }
                          in
                            enqueueError(loc, exn); ty
                          end
                      end
                   | NONE => A.TYCON(expandedTyseq, tyConPath, loc))
                | _ => A.TYCON(expandedTyseq, tyConPath, loc)
              end
            | A.TYTUPLE(tys, loc) => 
(*
              raise Bug.Bug "TYTUPLE in expandWithTypesInDataBind"
*)
              A.TYTUPLE(map expandInTy tys, loc)
            | A.TYFUN(rangeTy, domainTy, loc) =>
              A.TYFUN(expandInTy rangeTy, expandInTy domainTy, loc)
            | A.TYPOLY(tvarList, ty, loc) => 
              A.TYPOLY(tvarList, expandInTy ty, loc)
            | A.TYPAREN (ty, loc) => expandInTy ty
        fun expandInDataCon {symbol, ty, loc} =
            let
              val newTyOpt =
                  case ty of NONE => NONE | SOME ty => SOME(expandInTy ty)
            in {symbol = symbol, ty = newTyOpt, loc = loc} end
      in
        fn {tyvars, symbol, conbind, loc} =>
           {tyvars=tyvars, symbol = symbol, loc = loc,
            conbind = map expandInDataCon conbind}
      end

  fun truePat loc = PC.PLPATID(SymbolWithLoc.mkLongsymbol ["true"] (LOC loc))
  fun falsePat loc = PC.PLPATID(SymbolWithLoc.mkLongsymbol ["false"] (LOC loc))
  fun trueExp loc = PC.PLVAR(SymbolWithLoc.mkLongsymbol ["true"] (LOC loc))
  fun falseExp loc = PC.PLVAR(SymbolWithLoc.mkLongsymbol ["false"] (LOC loc))
  fun unitPat loc = PC.PLPATCONSTANT(A.UNITCONST, LOC loc)
  fun unitExp loc = PC.PLCONSTANT(A.UNITCONST, LOC loc)

  fun elabLabeledSequence elaborator elements =
      map (fn ((label, _), element, loc) => (label, elaborator element)) elements

  fun elabFFITy ty =
      case ty of
        A.FFITYVAR x => PC.FFITYVAR (x, #2 (#2 x))
      | A.FFITYRECORD (labelTys, loc) =>
        let val newLabelTys = elabLabeledSequence elabFFITy labelTys
        in
          PC.FFIRECORDTY (newLabelTys, loc)
        end
      | A.FFITYCON (argTys, tyConPath, loc) =>
        PC.FFICONTY (map elabFFITy (seq argTys), tyConPath, loc)
      | A.FFITYTUPLE (tys, loc) =>
        PC.FFIRECORDTY (RecordLabel.tupleList (map elabFFITy tys), loc)
      | A.FFITYFUN(attrs, (domTys, varTys, _), (ranTys, _), loc) =>
        PC.FFIFUNTY(case attrs of
                      NONE => NONE
                    | SOME (nil, _) => NONE
                    | SOME (attrs, loc) => SOME (elabFFIAttributes loc attrs),
                    map elabFFITy domTys, Option.map (map elabFFITy) varTys,
                    map elabFFITy ranTys, loc)
      | A.FFITYPAREN (ty, loc) => elabFFITy ty

  fun elabInfixPrec (src, loc) =
      case src of
        "0" => 0
      | "1" => 1
      | "2" => 2
      | "3" => 3
      | "4" => 4
      | "5" => 5
      | "6" => 6
      | "7" => 7
      | "8" => 8
      | "9" => 9
      | _ => (enqueueError (loc, E.InvalidFixityPrecedence);
              case Int.fromString src of
                SOME x => x
              | NONE => 0)

  fun elabPat pat =
      case pat of
        A.PATWILD loc => PC.PLPATWILD (LOC loc)
      | A.PATCONST (constant, loc) =>
        (case constant of
           A.REAL _ =>
           (* According to syntactic restriction of ML Definition, real
            * constant pattern is not allowed. *)
           (enqueueError (loc, E.RealConstantInPattern);
            PC.PLPATCONSTANT (constant, LOC loc))
         | _ => PC.PLPATCONSTANT (constant, LOC loc))
      | A.PATID (_, longvid, _) => PC.PLPATID (toLongsymbol longvid)
      | A.PATAPP (pat1, pat2, loc) =>
        PC.PLPATCONSTRUCT (elabPat pat1, elabPat pat2, LOC loc)
      | A.PATINFIX (pat1, vid, pat2, loc) =>
        PC.PLPATCONSTRUCT
          (PC.PLPATID (toLongsymbol ([vid], #2 vid)),
           PC.PLPATRECORD
             (false,
              RecordLabel.tupleList [elabPat pat1, elabPat pat2],
              LOC loc),
           LOC loc)
      | A.PATRECORD (pfields, flex, loc) =>
        PC.PLPATRECORD (flex, map elabPatRow pfields, LOC loc)
      | A.PATTUPLE (plist, loc) =>
        PC.PLPATRECORD (false, RecordLabel.tupleList (map elabPat plist), LOC loc)
      | A.PATLIST (elist, loc) =>
        let
          val plexp =
              foldr
              (fn (x, y) =>
                  PC.PLPATCONSTRUCT
                  (
                    PC.PLPATID(SymbolWithLoc.mkLongsymbol ["::"] (LOC loc)),
                    PC.PLPATRECORD(false, RecordLabel.tupleList [elabPat x, y], LOC loc),
                    LOC loc
                  ))
              (PC.PLPATID(SymbolWithLoc.mkLongsymbol ["nil"] (LOC loc)))
              elist
        in
          plexp
         (*
          case plexp of
            PC.PLPATID x => PC.PLPATID x
          | PC.PLPATCONSTRUCT(x, y, l) => PC.PLPATCONSTRUCT(x, y, loc)
          | _ => raise Bug.Bug "elab EXPLIST"
         *)
        end
      | A.PATTYPED (pat, ty, loc) => PC.PLPATTYPED(elabPat pat, ty, LOC loc)
      | A.PATAS ((_, id, _), NONE, pat, loc) =>
        PC.PLPATLAYERED(toSymbol id, NONE, elabPat pat, LOC loc)
      | A.PATAS ((_, id, _), SOME ty, pat, loc) =>
        let
          val elabedPat = elabPat pat
        in
          PC.PLPATLAYERED(toSymbol id, SOME ty, elabedPat, LOC loc)
        end
      | A.PATPAREN (pat, loc) => elabPat pat

  and elabPatRow patrow =
      case patrow of
        (* label = pat *)
        A.PATROW ((string, _), pat, loc) => (string, elabPat pat)
        (* label < : ty > < as pat > *)
      | A.PATROWVAR (vid, optTy, optPat, loc) =>
        let
          val pat =
              case optPat of
                SOME pat =>
                PC.PLPATLAYERED(toSymbol vid, optTy, elabPat pat, LOC loc)
              | _ =>
                case optTy of
                  SOME ty => PC.PLPATTYPED (PC.PLPATID (toLongsymbol ([vid], #2 vid)), ty, LOC loc)
                | _ => PC.PLPATID (toLongsymbol ([vid], #2 vid))
        in
          (RecordLabel.fromSymbol (#1 vid), pat)
        end

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
        val (id, idpat, typat, args) =
            case patappSpine pat nil of
              (* fun atpat vid atpat = ... *)
              (A.PATINFIX (pat1, vid, pat2, loc), nil) =>
              (mustBeAtpat pat1;
               mustBeAtpat pat2;
               (SOME vid,
                A.PATID (false, ([vid], #2 vid), #2 vid),
                fn x => x,
                [A.PATTUPLE ([pat1, pat2], loc)]))
            | (* fun (atpat vid atpat) ... = ... *)
              (A.PATPAREN (A.PATINFIX (pat1, vid, pat2, loc), _), args) =>
              (mustBeAtpat pat1;
               mustBeAtpat pat2;
               (SOME vid,
                A.PATID (false, ([vid], #2 vid), #2 vid),
                fn x => x,
                A.PATTUPLE ([pat1, pat2], loc) :: args))
            | (* fun (vid : ty) ... = ... (SML# extension) *)
              (A.PATPAREN
                 (A.PATTYPED (pat as A.PATID (_, ([id], _), _), ty, loc), _),
               args) =>
              (SOME id, pat, fn pat => A.PATTYPED (pat, ty, loc), args)
            | (* fun vid ... = ... *)
              (pat as A.PATID (_, ([id], _), _), args) =>
              (SOME id, pat, fn x => x, args)
            | (head, args) =>
              (enqueueError (AbsynUtils.patLoc head, E.IllegalFunctionSymbol);
               (NONE, head, fn x => x, args))
        (* fun ... : ty = exp  ===>  fun ... = exp : ty *)
        val exp =
            case tyOpt of
              NONE => exp
            | SOME ty => A.EXPTYPED (exp, ty, loc)
      in
        {id = id, pat = idpat, ty = typat, args = args, exp = exp, loc = loc}
      end

  fun elabExp ast =
      case ast of
        A.EXPCONST (const, loc) => PC.PLCONSTANT (const, LOC loc)
      | A.EXPSIZEOF (ty, loc) => PC.PLSIZEOF (ty, LOC loc)
      | A.EXPID (_, longid, _) => PC.PLVAR (toLongsymbol longid)
      | A.EXPRECORD (stringExpList, loc) =>
        PC.PLRECORD (elabLabeledSequence elabExp stringExpList, LOC loc)
      | A.EXPRECORD_UPDATE (exp, stringExpList, loc) =>
        PC.PLRECORD_UPDATE
          (
            elabExp exp,
            elabLabeledSequence elabExp stringExpList,
            LOC loc
          )
      | A.EXPTUPLE_UPDATE (exp, expList, loc) =>
        PC.PLRECORD_UPDATE
          (elabExp exp,
           RecordLabel.tupleList (map elabExp expList),
           LOC loc)
      | A.EXPUPDATE1 (exp, exp2, loc) =>
        PC.PLRECORD_UPDATE2
          (
            elabExp exp,
            elabExp exp2,
            LOC loc
          )
      | A.EXPUPDATE2 (exp, exp2, loc) =>
        PC.PLRECORD_UPDATE2
          (
            elabExp exp,
            elabExp exp2,
            LOC loc
          )
      | A.EXPSELECT ((x, _), loc) => PC.PLRECORD_SELECTOR(x, LOC loc)
      | A.EXPTUPLE (elist, loc) =>
        PC.PLRECORD(RecordLabel.tupleList(map elabExp elist), LOC loc)
      | A.EXPLIST (elist, loc) => 
(*
        if !C.doListExpressionOptimization then
          PC.PLLIST(map (elabExp env) elist, loc)
        else
*)
        let
          fun folder (x, y) =
              PC.PLAPPM
                (PC.PLVAR(SymbolWithLoc.mkLongsymbol ["::"] (LOC loc)),
                 [PC.PLRECORD(RecordLabel.tupleList [elabExp x, y], LOC loc)],
                 LOC loc)
          val plexp = foldr folder (PC.PLVAR(SymbolWithLoc.mkLongsymbol ["nil"] (LOC loc))) elist
        in
          plexp
        end
      | A.EXPAPP (exp1, exp2, loc) =>
        PC.PLAPPM (elabExp exp1, [elabExp exp2], LOC loc)
      | A.EXPINFIX (exp1, vid, exp2, loc) =>
        PC.PLAPPM
          (PC.PLVAR (toLongsymbol ([vid], #2 vid)),
           [PC.PLRECORD
              (RecordLabel.tupleList [elabExp exp1, elabExp exp2],
               LOC loc)],
           LOC loc)
      | A.EXPSEQ (elist, loc) => PC.PLSEQ(map elabExp elist, LOC loc)
      | A.EXPTYPED (exp, ty, loc) => PC.PLTYPED (elabExp exp, ty, LOC loc)
      | A.EXPANDALSO (e1, e2, loc) =>
        let
          val ple1 = elabExp e1
          val ple2 = elabExp e2
        in
          PC.PLCASEM
            (
             [ple1],
             [
              ([falsePat loc], falseExp loc, LOC loc),
              ([truePat loc], ple2, LOC loc)
             ],
             PC.MATCH,
             LOC loc
            )
        end
      | A.EXPORELSE (e1, e2, loc) =>
        let
          val ple1 = elabExp e1
          val ple2 = elabExp e2
        in
          PC.PLCASEM
            (
             [ple1],
             [
              ([truePat loc], trueExp loc, LOC loc),
              ([falsePat loc], ple2, LOC loc)
             ],
             PC.MATCH,
             LOC loc
            )
             
        end
      | A.EXPHANDLE (e1, match, loc) =>
        PC.PLHANDLE
            (
              elabExp e1,
              map (fn (x, y, loc) => (elabPat x, elabExp y, LOC loc)) match,
              LOC loc
            )
      | A.EXPRAISE (e, loc) => PC.PLRAISE(elabExp e, LOC loc)
      | A.EXPIF (e1, e2, e3, loc) =>
        let
          val ple1 = elabExp e1
          val ple2 = elabExp e2
          val ple3 = elabExp e3
        in
          PC.PLCASEM
          ([ple1],
           [([truePat loc], ple2, LOC loc),
            ([falsePat loc], ple3, LOC loc)],
           PC.MATCH,
           LOC loc)
        end
      | A.EXPWHILE (condExp, bodyExp, loc) =>
        let
          val newid = SymbolWithLoc.generate ()
          val condPl = elabExp condExp
          val bodyPl = elabExp bodyExp
          (* (fn _ => newid ()) body *)
          val whbody =
              PC.PLAPPM
              (
                PC.PLFNM
                (
                  [
                    (
                     [PC.PLPATWILD (LOC loc)],
                     PC.PLAPPM(PC.PLVAR (SymbolWithLoc.symbolToLongsymbol newid),
                               [unitExp loc], LOC loc),
                     LOC loc
                    )
                  ],
                  LOC loc
                ),
                [bodyPl],
                LOC loc
              )
          (* fn () => (fn true => whbody | false => ()) cond *)
          val body =
              PC.PLFNM
              (
               [
                (
                 [unitPat loc],
                 PC.PLAPPM
                   (
                    PC.PLFNM
                      (
                       [([truePat loc], whbody, LOC loc),
                        ([falsePat loc], unitExp loc, LOC loc)],
                       LOC loc
                      ),
                    [condPl],
                    LOC loc
                   ),
                 LOC loc
                )
               ],
               LOC loc
              )
        in
          PC.PLLET
          (
            [PC.PDVAL(emptyTvars, nil, [(PC.PLPATID (SymbolWithLoc.symbolToLongsymbol newid), body, LOC loc)], LOC loc)],
            PC.PLAPPM(PC.PLVAR (SymbolWithLoc.symbolToLongsymbol newid), [unitExp loc], LOC loc),
            LOC loc
          )
        end
      | A.EXPCASE (objectExp, match, loc) =>
        PC.PLCASEM
        (
          [elabExp objectExp],
          map (fn (x, y, loc) => ([elabPat x], elabExp y, LOC loc)) match,
          PC.MATCH,
          LOC loc
        )
      | A.EXPFN (match, loc) =>
        PC.PLFNM(map (fn (x, y, loc) => ([elabPat x], elabExp y, LOC loc)) match,
                 LOC loc)
      | A.EXPLET (decs, (elist, _), loc) =>
        let
          val pdecs = elabDecs decs
          val body =
              case map elabExp elist of
                [exp] => exp
              | expList => PC.PLSEQ (expList, LOC loc)
        in
          PC.PLLET (pdecs, body, LOC loc)
        end
      | A.EXPIMPORT_NAME ((s, _), ty, loc) =>
        PC.PLFFIIMPORT (PC.PLFFIEXTERN s, elabFFITy ty, LOC loc)
      | A.EXPIMPORT_EXP (exp, ty, loc) =>
        PC.PLFFIIMPORT (PC.PLFFIFUN (elabExp exp), elabFFITy ty, LOC loc)
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
      | A.EXPJOIN (exp1, exp2, loc) => PC.PLJOIN (true, elabExp exp1, elabExp exp2, LOC loc)
      | A.EXPEXTEND (exp1, exp2, loc) => PC.PLJOIN (false, elabExp exp1, elabExp exp2, LOC loc)
      | A.EXPDYNAMIC_AS (exp, ty, loc) => PC.PLDYNAMIC (elabExp exp, ty, LOC loc)
      | A.EXPDYNAMIC_OF (exp, ty, loc) => PC.PLDYNAMICIS (elabExp exp, ty, LOC loc)
      | A.EXPDYNAMICNULL (ty, loc) => PC.PLDYNAMICNULL (ty, LOC loc)
      | A.EXPDYNAMICTOP (ty, loc) => PC.PLDYNAMICTOP (ty, LOC loc)
      | A.EXPDYNAMICVIEW (exp, ty, loc) => PC.PLDYNAMICVIEW (elabExp exp, ty, LOC loc)
      | A.EXPDYNAMICCASE (exp, matches, loc) =>
        PC.PLDYNAMICCASE
          (elabExp exp,
           map (fn (tyvars, x, y, loc) =>
                   (seq' tyvars, elabPat x, elabExp y, LOC loc))
               matches,
           LOC loc)
      | A.EXPREIFYTY (ty, loc) => PC.PLREIFYTY (ty, LOC loc)
      | A.EXPPAREN (exp, loc) => elabExp exp

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
        val symbol = Option.map toSymbol (#id first)
        val idpat = foldl (fn (x, z) => #ty x z) (#pat first) frules
        val idpat = elabPat idpat
        val rules = map (fn {args, exp, loc, ...} =>
                            (map elabPat args, elabExp exp, LOC loc))
                        frules
      in
        (symbol, {fdecl = (idpat, rules), loc = LOC loc})
      end

  and elabDataBindsWithTypeBinds (dataBinds, withTypeBinds, loc) =
      let
        fun elabDataCon ((_, conSymbol, _), tyOpt, loc) = {symbol=toSymbol conSymbol, ty=tyOpt, loc = LOC loc}
        fun elabDataBind (tvars, name, dataCons, loc) =
            {tyvars=seq tvars, symbol=toSymbol name, conbind = map elabDataCon dataCons, loc=LOC loc}
        val dataCons =
            List.concat (map #3 dataBinds)
        val boundTypeNames =
            (map (fn (_, x, _, _) => toSymbol x) dataBinds)
            @ (map (fn (_, x, _, _) => toSymbol x) (seq withTypeBinds))
        val newDataBinds = map elabDataBind dataBinds
        val expandedDataBinds =
            map (expandWithTypesInDataBind (seq withTypeBinds)) newDataBinds
        val withTypeBinds =
            map (fn (tyvars, tyConSymbol, ty, loc) =>
                    (seq tyvars, toSymbol tyConSymbol, ty, LOC loc))
                (seq withTypeBinds)
      in
        (expandedDataBinds, withTypeBinds)
      end

  and elabDec dec =
      case dec of
        A.DECVAL (tyvs, valbinds, loc) =>
        let
          val (valbinds, recbinds) = classifyValbinds valbinds
          val recbinds = flattenValbinds recbinds
          val elabedValbinds =
              map (fn (pat, e, loc) => (elabPat pat, elabExp e, LOC loc))
                  valbinds

          (* right hand side of val rec must be "fn". *)
          fun assertExp (A.EXPFN _) = ()
            (* fix attempt for val rec x = (fn x =>x) is rejected  ??? *)
            | assertExp (A.EXPPAREN (exp, _)) = assertExp exp
            | assertExp exp = enqueueError (loc, E.NotFnBoundInValRec)
          (* check pattern AFTER elaboration, because even single var pattern
           * is parsed as application pattern. *)
          fun assertPattern pat =
              case pat of
                PC.PLPATWILD _ =>
                enqueueError(loc, E.NonVariablePatternInValRec)
              | PC.PLPATID _ => ()
              | PC.PLPATLAYERED(name, _, rightPat, _) =>
                enqueueError(loc, E.NonVariablePatternInValRec)
              | PC.PLPATTYPED(innerPat, _, _) => assertPattern innerPat
              | _ => enqueueError(loc, E.NonVariablePatternInValRec)
          fun elabBind (pat, exp, loc) =
              let
                val elabedPat = elabPat pat
                val elabedExp = elabExp exp
              in
                assertPattern elabedPat; (* after elab *)
                assertExp exp; (* before elab *)
                (elabedPat, elabedExp, LOC loc)
              end
          val elabedRecbinds = map elabBind recbinds
        in
          [PC.PDVAL (seq' tyvs, elabedValbinds, elabedRecbinds, LOC loc)]
        end
      | A.DECPOLYREC ( decls, loc) =>
        let
          (* right hand side of val rec must be "fn". *)
          fun assertExp (A.EXPFN _) = ()
            (* fix attempt for val rec x = (fn x =>x) is rejected  ??? *)
            | assertExp (A.EXPPAREN (exp, _)) = assertExp exp
            | assertExp exp = enqueueError (loc, E.NotFnBoundInValRec)
          fun elabBind (symbol, ty, exp, loc) =
              let
                val elabedExp = elabExp exp
              in
                assertExp exp; (* before elab *)
                (toSymbol symbol, ty, elabedExp, LOC loc)
              end
          val elabedBinds = map elabBind decls
        in
          [PC.PDVALPOLYREC(elabedBinds, LOC loc)]
        end
      | A.DECFUN (tyvs, fvalbinds, loc) =>
        let
          val elabedFunBinds = map elabFvalbind fvalbinds
        in
          [PC.PDDECFUN (seq' tyvs, map #2 elabedFunBinds, LOC loc)]
        end
      | A.DECTYPE (tyBinds, loc) =>
        let
          fun elabTyBind (tvars, symbol, ty, loc) =
              let
                val newTVars =
                    map
                      (fn (isEq, id) => (false, id))
                      (seq tvars)
                val newTy =
                    substTyVarInTy
                      (fn (isEq, id) => A.TYVAR(false, id))
                      ty
              in
                (newTVars, toSymbol symbol, newTy, LOC loc)
              end
          val newTyBinds = map elabTyBind tyBinds
        in
          [PC.PDTYPE (newTyBinds, LOC loc)]
        end
      | A.DECDATATYPE (dataBinds, withTypeBinds, loc) =>
        let
          val (newDataBinds, newWithTypeBinds) =
              elabDataBindsWithTypeBinds (dataBinds, withTypeBinds, loc)
        in
          PC.PDDATATYPE (newDataBinds, newWithTypeBinds, LOC loc)
          :: (case newWithTypeBinds of
                nil => nil
              | _ :: _ => [PC.PDTYPE(newWithTypeBinds, LOC loc)])
        end
      | A.DECDATATYPEREP (defSymbol, refLongsymbol, loc) =>
        [PC.PDREPLICATEDAT
           (toSymbol defSymbol, toLongsymbol refLongsymbol, LOC loc)]
      | A.DECABSTYPE (dataBinds, withTypeBinds, decs, loc) =>
        let
          val (newDataBinds, newWithTypeBinds) =
              elabDataBindsWithTypeBinds (dataBinds, withTypeBinds, loc)
          val typeNames = map (fn (tvars, symbol, _, _) => (tvars, symbol))
                              newWithTypeBinds
          val newDecs = elabDecs decs
          val newVisibleDecs =
              case newWithTypeBinds of
                [] => newDecs
              | _ => PC.PDTYPE(newWithTypeBinds, LOC loc) :: newDecs
        in
          [PC.PDABSTYPE(newDataBinds, newWithTypeBinds, newVisibleDecs, LOC loc)]
        end
      | A.DECEXCEPTION (exnBinds, loc) =>
        let
          fun elabExnBind (A.EXBIND ((_, conSymbol, _), NONE, loc)) =
              PC.PLEXBINDDEF(toSymbol conSymbol, NONE, LOC loc)
            | elabExnBind (A.EXBIND ((_, conSymbol, _), SOME ty, loc)) =
              PC.PLEXBINDDEF(toSymbol conSymbol, SOME ty, LOC loc)
            | elabExnBind
                (A.EXBINDREP ((_, conSymbol, _), (_, refLongsymbol, _), loc)) =
              PC.PLEXBINDREP(toSymbol conSymbol, toLongsymbol refLongsymbol, LOC loc)
        in
          [PC.PDEXD (map elabExnBind exnBinds, LOC loc)]
        end
      | A.DECLOCAL (dec1, dec2, loc) =>
        let
          val pdecs1 = elabDecs dec1
          val pdecs2 = elabDecs dec2
        in
          [PC.PDLOCALDEC(pdecs1, pdecs2, LOC loc)]
        end
      | A.DECOPEN(longids,loc) =>
        [PC.PDOPEN(map toLongsymbol longids, LOC loc)]
      | A.DECINFIX (n, idlist, loc) =>
        let
          val n = elabInfixPrec (getOpt (n, "0"), loc)
          val idlist = map toSymbol idlist
        in
          [PC.PDINFIXDEC(n, idlist, LOC loc)]
        end
      | A.DECINFIXR (n, idlist, loc) =>
        let
          val n = elabInfixPrec (getOpt (n, "0"), loc)
          val idlist = map toSymbol idlist
        in
          [PC.PDINFIXRDEC(n, idlist, LOC loc)]
        end
      | A.DECNONFIX (idlist, loc) =>
        [PC.PDNONFIXDEC(map toSymbol idlist, LOC loc)]
      | A.DECSEMICOLON _ =>
        nil

  and elabDecs decs =
      List.concat (map elabDec decs)

end
