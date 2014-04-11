(**
 * determine the scope of user type variables.
 * @copyright (c) 2010, Tohoku University.
 * @author UENO Katsuhiro
   @author Atsushi Ohori (refactored UserTvarScoped and ElaborateInterface)
 *)
structure UserTvarScope =
struct
  structure EU = UserErrorUtils

  structure A = Absyn
  structure P = PatternCalc
  structure PI = PatternCalcInterface
  structure E = ElaborateError
  val symbolToString = Symbol.symbolToString
  val longsymbolToString = Symbol.longsymbolToString
  val eqSymbol = Symbol.eqSymbol

  type tvset = (A.tvar * Loc.loc) list
  type btvEnv = (A.eq * A.tvarKind) SEnv.map

  val empty = nil : tvset
  val emptyEnv = SEnv.empty : btvEnv

  fun member (set:tvset, {symbol=s1, eq}:A.tvar) =
      List.exists (fn ({symbol=s2, eq},_) => eqSymbol(s1,s2)) set

  fun singleton (tvar:A.tvar, loc) =
      [(tvar, loc)] : tvset

  fun checkEqkind (tvar as {symbol, eq}:A.tvar, eq2, loc) =
      if eq = eq2 then ()
      else EU.enqueueError
             (loc, E.DifferentEqkindOfSameTvar {tvar = tvar})

  fun union (tvs1:tvset, tvs2:tvset) =
      foldr
        (fn (elem as (tv, loc), tvs:tvset) =>
            case List.find (fn ({symbol=s1,...},_) => eqSymbol(s1,#symbol tv)) tvs1 of
              NONE => elem::tvs
            | SOME ({eq,...}, _) => (checkEqkind (tv, eq, loc); tvs))
        tvs1
        tvs2

  fun toTvarList (tvset:tvset) =
      map (fn (tv, _) => (tv, A.UNIV)) (rev tvset)

  fun toBtvEnv (kindedTvars:A.kindedTvar list, loc) =
      foldl (fn ((tvar as {symbol, eq}, kind), btvEnv) =>
                (if SEnv.inDomain (btvEnv, symbolToString symbol)
                 then EU.enqueueError
                        (loc, E.DuplicateUserTvar {tvar = tvar})
                 else ();
                 SEnv.insert (btvEnv, symbolToString symbol, (eq, kind))))
            SEnv.empty
            kindedTvars
            : btvEnv

  fun bindKindedTvars btvEnv loc kindedTvars =
      SEnv.unionWith #2 (btvEnv, toBtvEnv (kindedTvars, loc))

  fun bindTvars btvEnv loc tvars =
      bindKindedTvars btvEnv loc (map (fn tv => (tv, A.UNIV)) tvars)

  fun extend (btvEnv:btvEnv, tvset:tvset) =
      foldl (fn (({symbol, eq}, _), btvEnv) =>
                SEnv.insert (btvEnv, symbolToString symbol, (eq, A.UNIV)))
            btvEnv
            tvset

  fun sortTyrows rows =
      ListSorter.sort (fn ((k1, _), (k2, _)) => String.compare (k1, k2)) rows

  fun tyvarsOpt f (SOME x) = f x
    | tyvarsOpt f NONE = empty

  fun tyvarsList f l =
      foldl (fn (x, z) => union (z, f x)) empty l

  fun tyvarsTvar btvEnv (tv as {symbol,...}, loc) =
      case SEnv.find (btvEnv, symbolToString symbol) of
        NONE => singleton (tv, loc)
      | SOME (eq, kind) => (checkEqkind (tv, eq, loc); empty)

  fun tyvarsTy btvEnv ty =
      case ty of
        A.TYWILD _ => empty
      | A.TYID tv => tyvarsTvar btvEnv tv
      | A.TYRECORD (rows, loc) =>
        (* sort rows in order to make the "occurrence order" unique *)
        tyvarsList (fn (k,t) => tyvarsTy btvEnv t) (sortTyrows rows)
      | A.TYCONSTRUCT (tys, tycon, loc) =>
        tyvarsList (tyvarsTy btvEnv) tys
      | A.TYTUPLE (tys, loc) =>
        tyvarsList (tyvarsTy btvEnv) tys
      | A.TYFUN (ty1, ty2, loc) =>
        union (tyvarsTy btvEnv ty1, tyvarsTy btvEnv ty2)
      | A.TYPOLY (kindedTvars, ty, loc) =>
        let
          val btvEnv = bindKindedTvars btvEnv loc kindedTvars
        in
          union (tyvarsList (tyvarsKindedTvar btvEnv) kindedTvars,
                 tyvarsTy btvEnv ty)
        end

  and tyvarsKindedTvar btvEnv ((_,kind):A.kindedTvar) =
      tyvarsTvarKind btvEnv kind

  and tyvarsTvarKind btvEnv kind =
      case kind of
        A.UNIV => empty
      | A.REC (rows, loc) =>
        (* sort rows in order to make the "occurrence order" unique *)
        tyvarsList (fn (k,t) => tyvarsTy btvEnv t) (sortTyrows rows)

  and tyvarsFFIty btvEnv ty =
      case ty of
        P.FFIFUNTY (attr, argTys, varTys, retTys, loc) =>
        union (union (tyvarsList (tyvarsFFIty btvEnv) argTys,
                      tyvarsOpt (tyvarsList (tyvarsFFIty btvEnv)) varTys),
               tyvarsList (tyvarsFFIty btvEnv) retTys)
      | P.FFITYVAR tv => tyvarsTvar btvEnv tv
      | P.FFIRECORDTY (rows, loc) =>
        (* sort rows in order to make the "occurrence order" unique *)
        tyvarsList (fn (k,t) => tyvarsFFIty btvEnv t) (sortTyrows rows)
      | P.FFICONTY (tys, tycon, loc) =>
        tyvarsList (tyvarsFFIty btvEnv) tys

  fun tyvarsTypbind btvEnv loc (tvars, tycon, ty) =
      tyvarsTy (bindTvars btvEnv loc tvars) ty

  fun tyvarsConbind btvEnv ({symbol, ty}:P.conbind) =
      tyvarsOpt (tyvarsTy btvEnv) ty

  fun tyvarsDatbind btvEnv loc ({tyvars, symbol, conbind}:P.datbind) =
      tyvarsList (tyvarsConbind (bindTvars btvEnv loc tyvars)) conbind

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

  fun tyvarsMatch btvEnv (pats, exp) =
      union (tyvarsList (tyvarsPat btvEnv) pats, tyvarsExp btvEnv exp)

  and tyvarsBind btvEnv (pat, exp) =
      union (tyvarsPat btvEnv pat, tyvarsExp btvEnv exp)

  and tyvarsRow btvEnv (label:string, exp) =
      tyvarsExp btvEnv exp

  and tyvarsExp btvEnv exp =
      case exp of
        P.PLCONSTANT _ => empty
      | P.PLVAR _ => empty
      | P.PLTYPED (exp, ty, loc) =>
        union (tyvarsExp btvEnv exp, tyvarsTy btvEnv ty)
      | P.PLAPPM (exp, exps, loc) =>
        union (tyvarsExp btvEnv exp, tyvarsList (tyvarsExp btvEnv) exps)
      | P.PLLET (decls, exps, loc) =>
        union (tyvarsList (tyvarsDecl btvEnv) decls,
               tyvarsList (tyvarsExp btvEnv) exps)
      | P.PLRECORD (rows, loc) =>
        (* we don't sort rows here *)
        tyvarsList (tyvarsRow btvEnv) rows
      | P.PLRECORD_UPDATE (exp, rows, loc) =>
        (* we don't sort rows here *)
        union (tyvarsExp btvEnv exp, tyvarsList (tyvarsRow btvEnv) rows)
(*
      | P.PLLIST (exps, loc) => tyvarsList (tyvarsExp btvEnv) exps
*)
      | P.PLRAISE (exp, loc) => tyvarsExp btvEnv exp
      | P.PLHANDLE (exp, matches, loc) =>
        union (tyvarsExp btvEnv exp, tyvarsList (tyvarsBind btvEnv) matches)
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
      | P.PLFFIAPPLY (attr, exp, args, ffiTy, loc) =>
        union (union (tyvarsFFIFun btvEnv exp,
                      tyvarsList (tyvarsFFIArg btvEnv) args),
               tyvarsList (tyvarsFFIty btvEnv) ffiTy)
      | P.PLSQLSCHEMA {columnInfoFnExp, ty, loc} =>
        union (tyvarsExp btvEnv columnInfoFnExp,
               tyvarsTy btvEnv ty)
      | P.PLSQLDBI (pat, exp, loc) =>
        union (tyvarsPat btvEnv pat, tyvarsExp btvEnv exp)
      | P.PLJOIN (exp1, exp2, loc) =>
        union (tyvarsExp btvEnv exp1, tyvarsExp btvEnv exp2)

  and tyvarsFFIArg btvEnv ffiarg =
      case ffiarg of
        P.PLFFIARG (exp, ffiTy, loc) =>
        union (tyvarsExp btvEnv exp, tyvarsFFIty btvEnv ffiTy)
      | P.PLFFIARGSIZEOF (ty, exp, loc) =>
        union (tyvarsTy btvEnv ty, tyvarsOpt (tyvarsExp btvEnv) exp)

  and tyvarsFFIFun btvEnv ffiFun =
      case ffiFun of
        P.PLFFIFUN exp => tyvarsExp btvEnv exp
      | P.PLFFIEXTERN s => empty
  and tyvarsFvalbind btvEnv (pat, fvalclauses) =
      union (tyvarsPat btvEnv pat, tyvarsList (tyvarsMatch btvEnv) fvalclauses)

  and tyvarsDecl btvEnv decl =
      case decl of
        P.PDVAL _ => empty  (* guard point *)
      | P.PDVALREC _ => empty  (* guard point *)
      | P.PDVALPOLYREC _ => empty  (* guard point *)
      | P.PDDECFUN _ => empty  (* guard point *)
(*
      | P.PDNONRECFUN _ => empty  (* guard point *)
*)
      | P.PDTYPE (typbinds, loc) =>
        tyvarsList (tyvarsTypbind btvEnv loc) typbinds
      | P.PDDATATYPE (datbinds, loc) =>
        tyvarsList (tyvarsDatbind btvEnv loc) datbinds
      | P.PDREPLICATEDAT _ => empty
      | P.PDABSTYPE (datbinds, decls, loc) =>
        union (tyvarsList (tyvarsDatbind btvEnv loc) datbinds,
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

  fun decideScope tyvarsFn btvEnv (explicitScope, x, loc) =
      let
        val _ = app (fn (tvar as {symbol,...}, _) =>
                        if SEnv.inDomain (btvEnv, symbolToString symbol)
                        then EU.enqueueError
                               (loc, E.UserTvarScopedAtOuterDecl {tvar = tvar})
                        else ())
                    explicitScope
        val btvEnv = bindKindedTvars btvEnv loc explicitScope
        val unguarded1 = tyvarsList (tyvarsKindedTvar btvEnv) explicitScope
        val unguarded2 = tyvarsFn btvEnv x
        val unguarded = union (unguarded1, unguarded2)
        val scoped = explicitScope @ toTvarList unguarded
        val btvEnv = extend (btvEnv, unguarded)
      in
        (btvEnv, scoped)
      end

  fun decideRow btvEnv (label:string, exp) =
      (label, decideExp btvEnv exp)

  and decideBind btvEnv (pat:P.plpat, exp) =
      (pat, decideExp btvEnv exp)

  and decideMatch btvEnv (pat:P.plpat list, exp) =
      (pat, decideExp btvEnv exp)

  and decideExp btvEnv exp =
      case exp of
        P.PLCONSTANT _ => exp
      | P.PLVAR _ => exp
      | P.PLTYPED (exp, ty, loc) =>
        P.PLTYPED (decideExp btvEnv exp, ty, loc)
      | P.PLAPPM (exp, exps, loc) =>
        P.PLAPPM (decideExp btvEnv exp, map (decideExp btvEnv) exps, loc)
      | P.PLLET (decls, exps, loc) =>
        P.PLLET (map (decideDecl btvEnv) decls, map (decideExp btvEnv) exps,
                 loc)
      | P.PLRECORD (rows, loc) =>
        P.PLRECORD (map (decideRow btvEnv) rows, loc)
      | P.PLRECORD_UPDATE (exp, rows, loc) =>
        P.PLRECORD_UPDATE (decideExp btvEnv exp, map (decideRow btvEnv) rows,
                           loc)
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
      | P.PLRECORD_SELECTOR _ => exp
      | P.PLSELECT (label, exp, loc) =>
        P.PLSELECT (label, decideExp btvEnv exp, loc)
      | P.PLSEQ (exps, loc) =>
        P.PLSEQ (map (decideExp btvEnv) exps, loc)
      | P.PLFFIIMPORT (exp, ffiTy, loc) =>
        P.PLFFIIMPORT (decideFFIFun btvEnv exp, ffiTy, loc)
      | P.PLFFIAPPLY (attr, exp, args, ffiTy, loc) =>
        P.PLFFIAPPLY (attr, decideFFIFun btvEnv exp,
                      map (decideFFIArg btvEnv) args,
                      ffiTy, loc)
      | P.PLSQLSCHEMA {columnInfoFnExp, ty, loc} =>
        P.PLSQLSCHEMA {columnInfoFnExp = decideExp btvEnv columnInfoFnExp,
                       ty = ty,
                       loc = loc}
      | P.PLSQLDBI (pat, exp, loc) =>
        P.PLSQLDBI (pat, decideExp btvEnv exp, loc)
      | P.PLJOIN (exp1, exp2, loc) =>
        P.PLJOIN (decideExp btvEnv exp1, decideExp btvEnv exp2, loc)

  and decideFFIArg btvEnv ffiarg =
      case ffiarg of
        P.PLFFIARG (exp, ffiTy, loc) =>
        P.PLFFIARG (decideExp btvEnv exp, ffiTy, loc)
      | P.PLFFIARGSIZEOF (ty, exp, loc) =>
        P.PLFFIARGSIZEOF (ty, Option.map (decideExp btvEnv) exp, loc)

  and decideFFIFun btvEnv ffiFun =
      case ffiFun of
        P.PLFFIFUN exp => P.PLFFIFUN (decideExp btvEnv exp)
      | P.PLFFIEXTERN s => ffiFun

  and decideValbind btvEnv (pat:P.plpat, exp) =
      (pat, decideExp btvEnv exp)

  and decideFvalbind btvEnv {fdecl=(pat:P.plpat, fvalclauses), loc} =
      {fdecl=(pat, map (decideMatch btvEnv) fvalclauses), loc=loc}

  and decidePolyRecBind btvEnv (id, ty, exp) =
      (id, ty, decideExp btvEnv exp)

  and decideValDec btvEnv (dec as (scoped, valbinds, loc)) =
      let
        val (btvEnv, scoped) = decideScope tyvarsValbindList btvEnv dec
      in
        (scoped, map (decideValbind btvEnv) valbinds, loc)
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
      | P.PDVALREC valdec => P.PDVALREC (decideValDec btvEnv valdec)
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
        P.PLSIGEXPBASIC (decideSpec spec, loc)
      | P.PLSIGID _ => sigexp
      | P.PLSIGWHERE (sigexp, typbinds, loc) =>
        P.PLSIGWHERE (decideSigexp sigexp, typbinds, loc)

  and decideSpec spec =
      case spec of
        P.PLSPECVAL (scope, symbol, ty, loc) =>
        let
          val (_, scoped) = decideScope tyvarsTy emptyEnv (scope, ty, loc)
        in
          P.PLSPECVAL (scoped, symbol, ty, loc)
        end
      | P.PLSPECTYPE _ => spec
      | P.PLSPECTYPEEQUATION _ => spec
(*
      | P.PLSPECEQTYPE _ => spec
*)
      | P.PLSPECDATATYPE _ => spec
      | P.PLSPECREPLIC _ => spec
      | P.PLSPECEXCEPTION _ => spec
      | P.PLSPECSTRUCT (strdescs, loc) =>
        P.PLSPECSTRUCT (map (fn (k,e) => (k, decideSigexp e)) strdescs, loc)
      | P.PLSPECINCLUDE (sigexp, loc) =>
        P.PLSPECINCLUDE (decideSigexp sigexp, loc)
      | P.PLSPECSEQ (spec1, spec2, loc) =>
        P.PLSPECSEQ (decideSpec spec1, decideSpec spec2, loc)
      | P.PLSPECSHARE (spec, tycons, loc) =>
        P.PLSPECSHARE (decideSpec spec, tycons, loc)
      | P.PLSPECSHARESTR (spec, strids, loc) =>
        P.PLSPECSHARESTR (decideSpec spec, strids, loc)
      | P.PLSPECEMPTY => spec

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
          (map (fn (strid, strexp) => (strid, decideStrexp strexp)) strbinds,
           loc)
      | P.PLSTRUCTLOCAL (strdecs1, strdecs2, loc) =>
        P.PLSTRUCTLOCAL
          (map decideStrdec strdecs1, map decideStrdec strdecs2, loc)

  fun decideTopdec topdec =
      case topdec of
        P.PLTOPDECSTR (strdec, loc) =>
        P.PLTOPDECSTR (decideStrdec strdec, loc)
      | P.PLTOPDECSIG (sigbinds, loc) =>
        P.PLTOPDECSIG (map (fn (k,e) => (k, decideSigexp e)) sigbinds, loc)
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

  fun ftv ty = tyvarsTy SEnv.empty ty

  fun tyvarsOverloadInstance inst =
      case inst of
        PI.INST_OVERLOAD overloadCase => tyvarsOverloadCase overloadCase
      | PI.INST_LONGVID {longsymbol} => empty
  and tyvarsOverloadMatch {instTy, instance} =
      union (ftv instTy, tyvarsOverloadInstance instance)
  and tyvarsOverloadCase ({tyvar, expTy, matches, loc}:PI.overloadCase) =
      union
        (union (singleton (tyvar, loc), ftv expTy),
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
        val set = union (singleton (tyvar, loc), ftv expTy)
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
        PI.PIVAL {scopedTvars, symbol,body,loc} =>
        let
          val (scopedTvars, body) = decideValbindBody body
        in
          PI.PIVAL {scopedTvars = scopedTvars, symbol = symbol, body=body, loc=loc}
        end
    | PI.PITYPE {tyvars, symbol, ty, loc} => pidec
    | PI.PIOPAQUE_TYPE {tyvars, symbol, runtimeTy, loc} => pidec
    | PI.PIOPAQUE_EQTYPE {tyvars, symbol,runtimeTy,loc} => pidec
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

  fun decideInterfaceDec {interfaceId, requiredIds, provideTopdecs} =
      {
       interfaceId = interfaceId,
       requiredIds = requiredIds,
       provideTopdecs = decidePitopdecs provideTopdecs
      }
  fun decideInterfaceDecs interfaceDecs = map decideInterfaceDec interfaceDecs
  fun decideInterface {interfaceDecs, requiredIds, provideTopdecs} =
      {interfaceDecs = decideInterfaceDecs interfaceDecs, 
       requiredIds = requiredIds, 
       provideTopdecs = decidePitopdecs provideTopdecs
      }

end
