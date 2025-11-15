(**
 * determine the scope of user type variables.
 * @copyright (C) 2021 SML# Development Team.
 * @author Atsushi Ohori
 * @author UENO Katsuhiro
 *)
structure UserTvarScope =
struct
  structure EU = UserErrorUtils

  structure A = Absyn
  structure P = PatternCalc
  structure PI = PatternCalcInterface
  structure E = ElaborateError
  datatype loc = datatype Loc.loc
  val eqSymbol = SymbolWithLoc.eqSymbol

  type tvset = A.tyvar list
  type btvEnv = {isEq:bool, kind:A.kind option} Symbol.Map.map

  val noloc = Loc.noloc
  val empty = nil : tvset
  val emptyEnv = Symbol.Map.empty : btvEnv

  fun seq NONE = nil
    | seq (SOME (items, _)) = items

  fun member (set:tvset, (_, (s1, _)):A.tyvar) =
      List.exists (fn (_, (s2, _)) => s1 = s2) set

  fun singleton (tvar:A.tyvar) =
      [tvar] : tvset

  fun checkEq (tvar as (isEq, (symbol, loc)):A.tyvar, isEq2) =
      if isEq = isEq2 then ()
      else EU.enqueueError
             (LOC loc, E.DifferentEqOfSameTvar {tvar = tvar})

  fun union (tvs1:tvset, tvs2:tvset) =
      foldr
        (fn (tv2 as (_, (s2, _)), tvs:tvset) =>
            case List.find (fn (_, (s1, _)) => s1 = s2) tvs1 of
              NONE => tv2::tvs
            | SOME (isEq, _) => (checkEq (tv2, isEq); tvs))
        tvs1
        tvs2

  fun setminus (tvs1:tvset, tvs2:A.kinded_tyvar list) =
      List.filter
        (fn (_, (s1, _)) =>
            not (List.exists (fn ((_, (s2, _)), _, _) => s1 = s2) tvs2))
        tvs1

  fun toTvarList (tvset:tvset) =
      map (fn tv as (_, (_, loc)) => (tv, NONE, loc)) (rev tvset)

  fun toBtvEnv (kindedTvars:A.kinded_tyvar list) : btvEnv =
      foldl (fn ((tvar as (isEq, (symbol, loc)), kind, _), btvEnv) =>
                (if Symbol.Map.inDomain (btvEnv, symbol)
                 then EU.enqueueError
                        (LOC loc, E.DuplicateUserTvar {tvar = tvar})
                 else ();
                 Symbol.Map.insert
                   (btvEnv, symbol, {isEq = isEq, kind = kind})))
            Symbol.Map.empty
            kindedTvars

  fun bindKindedTvars btvEnv kindedTvars =
      Symbol.Map.unionWith #2 (btvEnv, toBtvEnv kindedTvars)

  fun bindTvars btvEnv tvars =
      bindKindedTvars
        btvEnv
        (map (fn tv => (tv, NONE, #2 (#2 tv))) tvars)

  fun extend (btvEnv:btvEnv, tvset:tvset) =
      foldl (fn ((isEq, (symbol, _)), btvEnv) =>
                Symbol.Map.insert
                  (btvEnv,
                   symbol,
                   {isEq = isEq, kind = NONE}))
            btvEnv
            tvset

  fun sortTyrows rows =
      ListSorter.sort
        (fn (r1, r2) => RecordLabel.compare (#1 (#1 r1), #1 (#1 r2)))
        rows

  fun sortPlTyrows rows =
      ListSorter.sort (fn (r1, r2) => RecordLabel.compare (#1 r1, #1 r2)) rows

  fun tyvarsOpt f (SOME x) = f x
    | tyvarsOpt f NONE = empty

  fun tyvarsList f l =
      foldl (fn (x, z) => union (z, f x)) empty l

  fun tyvarsTvar btvEnv (tv as (_, (symbol, loc)) : A.tyvar) =
      case Symbol.Map.find (btvEnv, symbol) of
        NONE => singleton tv
      | SOME {isEq, kind} => (checkEq (tv, isEq); empty)

  fun tyvarsTy btvEnv ty =
      case ty of
        A.TYWILD _ => empty
      | A.TYVAR tv => tyvarsTvar btvEnv tv
      | A.TYVAR_FREE tv => empty
      | A.TYRECORD (rows, ifFlex, loc) =>
        (* sort rows in order to make the "occurrence order" unique *)
        tyvarsList (fn (k,t,_) => tyvarsTy btvEnv t) (sortTyrows rows)
      | A.TYCON (tys, tycon, loc) =>
        tyvarsList (tyvarsTy btvEnv) (seq tys)
      | A.TYTUPLE (tys, loc) =>
        tyvarsList (tyvarsTy btvEnv) tys
      | A.TYFUN (ty1, ty2, loc) =>
        union (tyvarsTy btvEnv ty1, tyvarsTy btvEnv ty2)
      | A.TYPOLY ((kindedTvars, _), ty, loc) =>
        let
          val btvEnv = bindKindedTvars btvEnv kindedTvars
        in
          union (tyvarsList (tyvarsKindedTvar btvEnv) kindedTvars,
                 tyvarsTy btvEnv ty)
        end
      | A.TYPAREN (ty, loc) => tyvarsTy btvEnv ty

  and tyvarsKindedTvar btvEnv ((_,kind,_):A.kinded_tyvar) =
      tyvarsTvarKind btvEnv kind

  and tyvarsTvarKind btvEnv kind =
      case kind of
        NONE => empty
      | SOME (A.UNIV _) => empty
      | SOME (A.REC (properties, recordKind, loc)) =>
        (* sort rows in order to make the "occurrence order" unique *)
        tyvarsList (fn (k,t,_) => tyvarsTy btvEnv t) (sortTyrows recordKind)

  and tyvarsFFIty btvEnv ty =
      case ty of
        P.FFIFUNTY (attr, argTys, varTys, retTys, loc) =>
        union (union (tyvarsList (tyvarsFFIty btvEnv) argTys,
                      tyvarsOpt (tyvarsList (tyvarsFFIty btvEnv)) varTys),
               tyvarsList (tyvarsFFIty btvEnv) retTys)
      | P.FFITYVAR (tv, _) => tyvarsTvar btvEnv tv
      | P.FFIRECORDTY (rows, loc) =>
        (* sort rows in order to make the "occurrence order" unique *)
        tyvarsList (fn (k,t) => tyvarsFFIty btvEnv t) (sortPlTyrows rows)
      | P.FFICONTY (tys, tycon, loc) =>
        tyvarsList (tyvarsFFIty btvEnv) tys

  fun tyvarsTypbind btvEnv (tvars, tycon, ty, defLoc) =
      tyvarsTy (bindTvars btvEnv tvars) ty

  fun tyvarsConbind btvEnv ({symbol, ty, loc}:P.conbind) =
      tyvarsOpt (tyvarsTy btvEnv) ty

  fun tyvarsDatbind btvEnv ({tyvars, symbol, conbind, loc=datLoc}:P.datbind) =
      tyvarsList (tyvarsConbind (bindTvars btvEnv tyvars)) conbind

  fun tyvarsExbind btvEnv exbind =
      case exbind of
        P.PLEXBINDDEF (exid, ty, loc) => tyvarsOpt (tyvarsTy btvEnv) ty
      | P.PLEXBINDREP _ => empty

  fun tyvarsPat btvEnv pat =
      case pat of
        P.PLPATWILD loc => empty
      | P.PLPATID _ => empty
      | P.PLPATCONSTANT _ => empty
      | P.PLPATCONSTRUCT (pat1, pat2, loc) =>
        union (tyvarsPat btvEnv pat1, tyvarsPat btvEnv pat2)
      | P.PLPATRECORD (flex, rows, loc) =>
        (* we don't sort rows here *)
        tyvarsList (fn (k,p) => tyvarsPat btvEnv p) rows
      | P.PLPATLAYERED (symbol, ty, pat, loc) =>
        union (tyvarsOpt (tyvarsTy btvEnv) ty, tyvarsPat btvEnv pat)
      | P.PLPATTYPED (pat, ty, loc) =>
        union (tyvarsPat btvEnv pat, tyvarsTy btvEnv ty)

  fun tyvarsMatch btvEnv (pats, exp, loc) =
      union (tyvarsList (tyvarsPat btvEnv) pats, tyvarsExp btvEnv exp)

  and tyvarsMatch1 btvEnv (pat, exp, loc) =
      union (tyvarsPat btvEnv pat, tyvarsExp btvEnv exp)

  and tyvarsDynMatch btvEnv ((tyvars, _), pat, exp, loc) =
      setminus (union (tyvarsPat btvEnv pat, tyvarsExp btvEnv exp), tyvars)

  and tyvarsBind btvEnv (pat, exp, loc) =
      union (tyvarsPat btvEnv pat, tyvarsExp btvEnv exp)


  and tyvarsRow btvEnv (label, exp) =
      tyvarsExp btvEnv exp

  and tyvarsExp btvEnv exp =
      case exp of
        P.PLCONSTANT _ => empty
      | P.PLSIZEOF (ty, loc) => tyvarsTy btvEnv ty
      | P.PLVAR _ => empty
      | P.PLTYPED (exp, ty, loc) =>
        union (tyvarsExp btvEnv exp, tyvarsTy btvEnv ty)
      | P.PLAPPM (exp, exps, loc) =>
        union (tyvarsExp btvEnv exp, tyvarsList (tyvarsExp btvEnv) exps)
      | P.PLLET (decls, exp, loc) =>
        union (tyvarsList (tyvarsDecl btvEnv) decls,
               tyvarsExp btvEnv exp)
      | P.PLRECORD (rows, loc) =>
        (* we don't sort rows here *)
        tyvarsList (tyvarsRow btvEnv) rows
      | P.PLRECORD_UPDATE (exp, rows, loc) =>
        (* we don't sort rows here *)
        union (tyvarsExp btvEnv exp, tyvarsList (tyvarsRow btvEnv) rows)
      | P.PLRECORD_UPDATE2 (exp, exp2, loc) =>
        union (tyvarsExp btvEnv exp, tyvarsExp btvEnv exp2)
(*
      | P.PLLIST (exps, loc) => tyvarsList (tyvarsExp btvEnv) exps
*)
      | P.PLRAISE (exp, loc) => tyvarsExp btvEnv exp
      | P.PLHANDLE (exp, matches, loc) =>
        union (tyvarsExp btvEnv exp, tyvarsList (tyvarsMatch1 btvEnv) matches)
      | P.PLFNM (matches, loc) =>
        tyvarsList (tyvarsMatch btvEnv) matches
      | P.PLCASEM (exps, matches, caseKind, loc) =>
        union (tyvarsList (tyvarsExp btvEnv) exps,
               tyvarsList (tyvarsMatch btvEnv) matches)
      | P.PLRECORD_SELECTOR _ => empty
      | P.PLSELECT (label, exp, loc) => tyvarsExp btvEnv exp
      | P.PLSEQ (exps, loc) => tyvarsList (tyvarsExp btvEnv) exps
      | P.PLFFIIMPORT (exp, ffiTy, loc) =>
        union (tyvarsFFIFun btvEnv exp, tyvarsFFIty btvEnv ffiTy)
      | P.PLSQLSCHEMA {tyFnExp, ty, loc} =>
        union (tyvarsExp btvEnv tyFnExp,
               tyvarsTy btvEnv ty)
      | P.PLJOIN (bool, exp1, exp2, loc) =>
        union (tyvarsExp btvEnv exp1, tyvarsExp btvEnv exp2)
      | P.PLDYNAMIC (exp, ty, loc) =>
        union (tyvarsExp btvEnv exp, tyvarsTy btvEnv ty)
      | P.PLDYNAMICIS (exp, ty, loc) =>
        union (tyvarsExp btvEnv exp, tyvarsTy btvEnv ty)
      | P.PLDYNAMICVIEW (exp, ty, loc) =>
        union (tyvarsExp btvEnv exp, tyvarsTy btvEnv ty)
      | P.PLDYNAMICNULL (ty, loc) => tyvarsTy btvEnv ty
      | P.PLDYNAMICTOP (ty, loc) => tyvarsTy btvEnv ty
      | P.PLDYNAMICCASE (exp, rules, loc) =>
        union (tyvarsExp btvEnv exp,
               tyvarsList (tyvarsDynMatch btvEnv) rules)
      | P.PLREIFYTY (ty, loc) =>
        tyvarsTy btvEnv ty

  and tyvarsFFIFun btvEnv ffiFun =
      case ffiFun of
        P.PLFFIFUN exp => tyvarsExp btvEnv exp
      | P.PLFFIEXTERN s => empty
  and tyvarsFvalbind btvEnv (pat, fvalclauses) =
      union (tyvarsPat btvEnv pat, tyvarsList (tyvarsMatch btvEnv) fvalclauses)

  and tyvarsDecl btvEnv decl =
      case decl of
        P.PDVAL _ => empty  (* guard point *)
      | P.PDVALPOLYREC _ => empty  (* guard point *)
      | P.PDDECFUN _ => empty  (* guard point *)
(*
      | P.PDNONRECFUN _ => empty  (* guard point *)
*)
      | P.PDTYPE (typbinds, loc) =>
        tyvarsList (tyvarsTypbind btvEnv) typbinds
      | P.PDDATATYPE (datbinds, loc) =>
        tyvarsList (tyvarsDatbind btvEnv) datbinds
      | P.PDREPLICATEDAT _ => empty
      | P.PDABSTYPE (datbinds, decls, loc) =>
        union (tyvarsList (tyvarsDatbind btvEnv) datbinds,
               tyvarsList (tyvarsDecl btvEnv) decls)
      | P.PDEXD (exbinds, loc) =>
        tyvarsList (tyvarsExbind btvEnv) exbinds
      | P.PDLOCALDEC (decls1, decls2, loc) =>
        union (tyvarsList (tyvarsDecl btvEnv) decls1,
               tyvarsList (tyvarsDecl btvEnv) decls2)
      | P.PDOPEN _ => empty
      | P.PDINFIXDEC _ => empty
      | P.PDINFIXRDEC _ => empty
      | P.PDNONFIXDEC _ => empty
      | P.PDEMPTY => empty

  fun tyvarsMatchList btvEnv matches =
      tyvarsList (tyvarsMatch btvEnv) matches

  fun tyvarsValbindList btvEnv valbinds =
      tyvarsList (tyvarsBind btvEnv) valbinds

  fun tyvarsFvalbind btvEnv {fdecl=(pat, fvalclauses), loc} =
      union (tyvarsPat btvEnv pat, tyvarsList (tyvarsMatch btvEnv) fvalclauses)

  fun tyvarsFvalbindList btvEnv fvalbinds =
      tyvarsList (tyvarsFvalbind btvEnv) fvalbinds

  fun decideScope tyvarsFn btvEnv ((explicitScope, loc2), x, loc) =
      let
        val _ = app (fn (tvar as (_, (symbol, _)), _, _) =>
                        if Symbol.Map.inDomain (btvEnv, symbol)
                        then EU.enqueueError
                               (loc, E.UserTvarScopedAtOuterDecl {tvar = tvar})
                        else ())
                    explicitScope
        val btvEnv = bindKindedTvars btvEnv explicitScope
        val unguarded1 = tyvarsList (tyvarsKindedTvar btvEnv) explicitScope
        val unguarded2 = tyvarsFn btvEnv x
        val unguarded = union (unguarded1, unguarded2)
        val scoped = explicitScope @ toTvarList unguarded
        val btvEnv = extend (btvEnv, unguarded)
      in
        (btvEnv, (scoped, loc2))
      end

  fun decideRow btvEnv (label, exp) =
      (label, decideExp btvEnv exp)

  and decideBind btvEnv (pat:P.plpat, exp, loc) =
      (pat, decideExp btvEnv exp, loc)

  and decideMatch btvEnv (pat:P.plpat list, exp, loc) =
      (pat, decideExp btvEnv exp, loc)

  and decideDynMatch btvEnv (tyvars, pat:P.plpat, exp, loc) =
      (tyvars, pat, decideExp btvEnv exp, loc)

  and decideExp btvEnv exp =
      case exp of
        P.PLCONSTANT _ => exp
      | P.PLSIZEOF _ => exp
      | P.PLVAR _ => exp
      | P.PLTYPED (exp, ty, loc) =>
        P.PLTYPED (decideExp btvEnv exp, ty, loc)
      | P.PLAPPM (exp, exps, loc) =>
        P.PLAPPM (decideExp btvEnv exp, map (decideExp btvEnv) exps, loc)
      | P.PLLET (decls, exp, loc) =>
        P.PLLET (map (decideDecl btvEnv) decls, decideExp btvEnv exp,
                 loc)
      | P.PLRECORD (rows, loc) =>
        P.PLRECORD (map (decideRow btvEnv) rows, loc)
      | P.PLRECORD_UPDATE (exp, rows, loc) =>
        P.PLRECORD_UPDATE (decideExp btvEnv exp, map (decideRow btvEnv) rows,
                           loc)
      | P.PLRECORD_UPDATE2 (exp, exp2, loc) =>
        P.PLRECORD_UPDATE2 (decideExp btvEnv exp, decideExp btvEnv exp2, loc)
(*
      | P.PLLIST (exps, loc) =>
        P.PLLIST (map (decideExp btvEnv) exps, loc)
*)
      | P.PLRAISE (exp, loc) =>
        P.PLRAISE (decideExp btvEnv exp, loc)
      | P.PLHANDLE (exp, matches, loc) =>
        P.PLHANDLE (decideExp btvEnv exp, map (decideBind btvEnv) matches, loc)
      | P.PLFNM (matches, loc) =>
        P.PLFNM (map (decideMatch btvEnv) matches, loc)
      | P.PLCASEM (exps, matches, caseKind, loc) =>
        P.PLCASEM (map (decideExp btvEnv) exps,
                   map (decideMatch btvEnv) matches,
                   caseKind, loc)
      | P.PLDYNAMIC (exp, ty, loc) => P.PLDYNAMIC (decideExp btvEnv exp, ty, loc)
      | P.PLDYNAMICIS (exp, ty, loc) => P.PLDYNAMICIS (decideExp btvEnv exp, ty, loc)
      | P.PLDYNAMICNULL (ty, loc) => exp
      | P.PLDYNAMICTOP (ty, loc) => exp
      | P.PLDYNAMICVIEW (exp, ty, loc) => P.PLDYNAMICVIEW (decideExp btvEnv exp, ty, loc)
      | P.PLDYNAMICCASE (exp, matches, loc) =>
        P.PLDYNAMICCASE (decideExp btvEnv exp,
                         map (decideDynMatch btvEnv) matches,
                         loc)
      | P.PLRECORD_SELECTOR _ => exp
      | P.PLSELECT (label, exp, loc) =>
        P.PLSELECT (label, decideExp btvEnv exp, loc)
      | P.PLSEQ (exps, loc) =>
        P.PLSEQ (map (decideExp btvEnv) exps, loc)
      | P.PLFFIIMPORT (exp, ffiTy, loc) =>
        P.PLFFIIMPORT (decideFFIFun btvEnv exp, ffiTy, loc)
      | P.PLSQLSCHEMA {tyFnExp, ty, loc} =>
        P.PLSQLSCHEMA {tyFnExp = decideExp btvEnv tyFnExp,
                       ty = ty,
                       loc = loc}
      | P.PLJOIN (bool, exp1, exp2, loc) =>
        P.PLJOIN (bool, decideExp btvEnv exp1, decideExp btvEnv exp2, loc)
      | P.PLREIFYTY (ty, loc) => P.PLREIFYTY (ty, loc)

  and decideFFIFun btvEnv ffiFun =
      case ffiFun of
        P.PLFFIFUN exp => P.PLFFIFUN (decideExp btvEnv exp)
      | P.PLFFIEXTERN s => ffiFun

  and decideValbind btvEnv (pat:P.plpat, exp, loc) =
      (pat, decideExp btvEnv exp, loc)

  and decideFvalbind btvEnv {fdecl=(pat:P.plpat, fvalclauses), loc} =
      {fdecl=(pat, map (decideMatch btvEnv) fvalclauses), loc=loc}

  and decidePolyRecBind btvEnv (id, ty, exp, loc) =
      (id, ty, decideExp btvEnv exp, loc)

  and decideValDec btvEnv (scoped, valbinds, recbinds, loc) =
      let
        val binds = valbinds @ recbinds
        val (btvEnv, scoped) =
            decideScope tyvarsValbindList btvEnv (scoped, binds, loc)
      in
        (scoped,
         map (decideValbind btvEnv) valbinds,
         map (decideValbind btvEnv) recbinds,
         loc)
      end

  and decideFvalDec btvEnv (dec as (scoped, fvalbinds, loc)) =
      let
        val (btvEnv, scoped) = decideScope tyvarsFvalbindList btvEnv dec
      in
        (scoped, map (decideFvalbind btvEnv) fvalbinds, loc)
      end

  and decideDecl btvEnv decl =
      case decl of
        P.PDVAL valdec => P.PDVAL (decideValDec btvEnv valdec)
      | P.PDVALPOLYREC (polybinds, loc) => P.PDVALPOLYREC (map (decidePolyRecBind btvEnv) polybinds, loc)
      | P.PDDECFUN fvaldec => P.PDDECFUN (decideFvalDec btvEnv fvaldec)
(*
      | P.PDNONRECFUN (scoped, fvalbind, loc) =>
        P.PDNONRECFUN
          (case decideFvalDec btvEnv (scoped, [fvalbind], loc) of
             (scoped, [fvalbind], loc) => (scoped, fvalbind, loc)
           | _ => raise Bug.Bug "decideDecl")
*)
      | P.PDTYPE _ => decl
      | P.PDDATATYPE _ => decl
      | P.PDREPLICATEDAT _ => decl
      | P.PDABSTYPE (datbinds, decls, loc) =>
        P.PDABSTYPE (datbinds, map (decideDecl btvEnv) decls, loc)
      | P.PDEXD _ => decl
      | P.PDLOCALDEC (decls1, decls2, loc) =>
        P.PDLOCALDEC (map (decideDecl btvEnv) decls1,
                      map (decideDecl btvEnv) decls2, loc)
      | P.PDOPEN _ => decl
      | P.PDINFIXDEC _ => decl
      | P.PDINFIXRDEC _ => decl
      | P.PDNONFIXDEC _ => decl
      | P.PDEMPTY => decl

  fun decideSigexp sigexp =
      case sigexp of 
        P.PLSIGEXPBASIC (spec, loc) =>
        P.PLSIGEXPBASIC (map decideSpec spec, loc)
      | P.PLSIGID _ => sigexp
      | P.PLSIGWHERE (sigexp, typbinds, loc) =>
        P.PLSIGWHERE (decideSigexp sigexp, typbinds, loc)

  and decideValdesc (scope, symbol, ty, loc) =
      let
        val (_, scoped) = decideScope tyvarsTy emptyEnv (scope, ty, loc)
      in
        (scoped, symbol, ty, loc)
      end

  and decideSpec spec =
      case spec of
        P.PLSPECVAL valdescs =>
        P.PLSPECVAL (map decideValdesc valdescs)
      | P.PLSPECTYPE _ => spec
      | P.PLSPECTYPEEQUATION _ => spec
(*
      | P.PLSPECEQTYPE _ => spec
*)
      | P.PLSPECDATATYPE _ => spec
      | P.PLSPECREPLIC _ => spec
      | P.PLSPECEXCEPTION _ => spec
      | P.PLSPECSTRUCT (strdescs, loc) =>
        P.PLSPECSTRUCT (map (fn (k,e,l) => (k, decideSigexp e, l)) strdescs, loc)
      | P.PLSPECINCLUDE (sigexp, loc) =>
        P.PLSPECINCLUDE (decideSigexp sigexp, loc)
      | P.PLSPECSHARE (spec, tycons, loc) =>
        P.PLSPECSHARE (map decideSpec spec, tycons, loc)
      | P.PLSPECSHARESTR (spec, strids, loc) =>
        P.PLSPECSHARESTR (map decideSpec spec, strids, loc)

  fun decideStrexp strexp =
      case strexp of
        P.PLSTREXPBASIC (strdecs, loc) =>
        P.PLSTREXPBASIC (map decideStrdec strdecs, loc)
      | P.PLSTRID _ => strexp
      | P.PLSTRTRANCONSTRAINT (strexp, sigexp, loc) =>
        P.PLSTRTRANCONSTRAINT (decideStrexp strexp, decideSigexp sigexp, loc)
      | P.PLSTROPAQCONSTRAINT (strexp, sigexp, loc) =>
        P.PLSTROPAQCONSTRAINT (decideStrexp strexp, decideSigexp sigexp, loc)
      | P.PLFUNCTORAPP (funid, strPath, loc) =>
        P.PLFUNCTORAPP (funid, strPath, loc)
      | P.PLSTRUCTLET (strdecs, strexp, loc) =>
        P.PLSTRUCTLET (map decideStrdec strdecs, decideStrexp strexp, loc)

  and decideStrdec strdec =
      case strdec of
        P.PLCOREDEC (pdecl, loc) =>
        P.PLCOREDEC (decideDecl emptyEnv pdecl, loc)
      | P.PLSTRUCTBIND (strbinds, loc) =>
        P.PLSTRUCTBIND
          (map (fn (strid, strexp,loc) => 
                   (strid, decideStrexp strexp, loc)) strbinds,
           loc)
      | P.PLSTRUCTLOCAL (strdecs1, strdecs2, loc) =>
        P.PLSTRUCTLOCAL
          (map decideStrdec strdecs1, map decideStrdec strdecs2, loc)

  fun decideTopdec topdec =
      case topdec of
        P.PLTOPDECSTR (strdec, loc) =>
        P.PLTOPDECSTR (decideStrdec strdec, loc)
      | P.PLTOPDECSIG (sigbinds, loc) =>
        P.PLTOPDECSIG (map (fn (k,e,l) => (k, decideSigexp e, l)) sigbinds, loc)
      | P.PLTOPDECFUN (funbinds, loc) =>
        P.PLTOPDECFUN
          (map (fn {name, argStrName, argSig, body, loc} =>
                   {name=name,
                    argStrName=argStrName,
                    argSig=decideSigexp argSig,
                    body=decideStrexp body,
                    loc=loc})
               funbinds,
           loc)

  fun decide program =
      map decideTopdec program

  fun ftv ty = tyvarsTy Symbol.Map.empty ty

  fun tyvarsOverloadInstance inst =
      case inst of
        PI.INST_OVERLOAD overloadCase => tyvarsOverloadCase overloadCase
      | PI.INST_LONGVID {longsymbol} => empty
  and tyvarsOverloadMatch {instTy, instance} =
      union (ftv instTy, tyvarsOverloadInstance instance)
  and tyvarsOverloadCase ({tyvar, expTy, matches, loc}:PI.overloadCase) =
      union
        (union (singleton tyvar, ftv expTy),
         tyvarsList tyvarsOverloadMatch matches)
  fun tyvarsValbindBody body =
      case body of
        PI.VAL_EXTERN {ty} => ftv ty
      | PI.VALALIAS_EXTERN longsymbol => empty
      | PI.VAL_BUILTIN {builtinSymbol, ty} => ftv ty
      | PI.VAL_OVERLOAD overloadCase => tyvarsOverloadCase overloadCase

  fun checkUniqueOverloadTvars used ({tyvar, expTy, matches, loc}
                                     :PI.overloadCase) =
      let
        val _ =
            if member (used, tyvar)
            then (EU.enqueueError
                    (loc, E.UserTvarScopedAtOuterDecl
                            {tvar = tyvar}))
            else ()
        val set = union (singleton tyvar, ftv expTy)
        val used = union (used, set)
      in
        app (fn {instTy, instance} =>
                case instance of
                  PI.INST_OVERLOAD c => checkUniqueOverloadTvars used c
                | PI.INST_LONGVID _ => ())
            matches
      end

  fun checkValbindBody body =
      case body of
        PI.VAL_EXTERN _ => ()
      | PI.VALALIAS_EXTERN _ => ()
      | PI.VAL_BUILTIN _ => ()
      | PI.VAL_OVERLOAD c =>
        checkUniqueOverloadTvars empty c

  fun decideValbindBody body =
      (checkValbindBody body;
       (toTvarList (tyvarsValbindBody body), body)
      )
  fun decidePidec pidec =
      case pidec of
        PI.PIVAL {scopedTvars = (_, loc2), symbol,body,loc} =>
        let
          val (scopedTvars, body) = decideValbindBody body
        in
          PI.PIVAL {scopedTvars = (scopedTvars, loc2), symbol = symbol, body=body, loc=loc}
        end
    | PI.PITYPE {tyvars, symbol, ty, loc} => pidec
    | PI.PIOPAQUE_TYPE {eq, tyvars, symbol, runtimeTy, loc} => pidec
    | PI.PITYPEBUILTIN {symbol, builtinSymbol, loc} => pidec
    | PI.PIDATATYPE {datbind, loc} => pidec
    | PI.PITYPEREP {symbol, longsymbol, loc} => pidec
    | PI.PIEXCEPTION {symbol, ty, loc} => pidec
    | PI.PIEXCEPTIONREP {symbol, longsymbol, loc} => pidec
    | PI.PISTRUCTURE {symbol, strexp, loc} =>
      let
        val strexp = decidePistr strexp
      in
        PI.PISTRUCTURE {symbol=symbol, strexp=strexp, loc=loc}
      end
  and decidePistr pistr =
      case pistr of
        PI.PISTRUCT {decs, loc} =>
        PI.PISTRUCT {decs = map decidePidec decs, loc = loc}
      | PI.PISTRUCTREP {longsymbol, loc} => pistr
      | PI.PIFUNCTORAPP {functorSymbol, argument, loc} => pistr

  fun decidePitopdec pitopdec =
      case pitopdec of
        PI.PIDEC pidec => PI.PIDEC (decidePidec pidec)
      | PI.PIFUNDEC {functorSymbol, param={strSymbol, sigexp}, strexp, loc} =>
        PI.PIFUNDEC {functorSymbol = functorSymbol,
                     param = {strSymbol=strSymbol, sigexp = decideSigexp sigexp},
                     strexp = decidePistr strexp,
                     loc = loc} 
  fun decidePitopdecs provideTopdecs = 
      map decidePitopdec provideTopdecs

  fun decideInterfaceDec {interfaceId, interfaceName, requiredIds,
                          provideTopdecs} =
      {
       interfaceId = interfaceId,
       interfaceName = interfaceName,
       requiredIds = requiredIds,
       provideTopdecs = decidePitopdecs provideTopdecs
      }
  fun decideInterfaceDecs interfaceDecs = map decideInterfaceDec interfaceDecs
  fun decideInterface {interfaceDecs, requiredIds, locallyRequiredIds,
                       provideTopdecs} =
      {interfaceDecs = decideInterfaceDecs interfaceDecs, 
       requiredIds = requiredIds, 
       locallyRequiredIds = locallyRequiredIds,
       provideTopdecs = decidePitopdecs provideTopdecs
      }

end
