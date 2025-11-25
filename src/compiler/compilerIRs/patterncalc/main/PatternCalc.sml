(**
 * The Untyped Pattern Calculus
 *
 * @copyright (C) 2021 SML# Development Team.
 * @author Atsushi Ohori
 * @author Liu Bochao
 * @author YAMATODANI Kiyoshi
 * @author Katsuhiro Ueno
 *)
structure PatternCalc =
struct

  type loc = Loc.loc

  type vid = Absyn.vid
  type longvid = Absyn.longvid
  type tycon = Absyn.tycon
  type longtycon = Absyn.longtycon
  type strid = Absyn.strid
  type longstrid = Absyn.longstrid
  type sigid = Absyn.sigid
  type funid = Absyn.funid
  type lab = Absyn.lab
  type tyvar = AbsynTy.id
  datatype constant = datatype Absyn.constant
  datatype sigop = datatype Absyn.sigop
  type ffi_attr = FFIAttributes.attributes

  type kind_prop = {reify : bool, boxed : bool, unboxed : bool, eq : bool}

  val emptyKindProp =
      {reify = false, boxed = false, unboxed = false, eq = false}

  datatype 't ty =
      TYVAR of tyvar
    | TYRECORD of 't tyrow list * loc
    | TYCON of 't ty list * longtycon * loc
    | TYFUN of 't ty * 't ty * loc
    | TY of 't

  withtype 't tyrow = lab * 't ty * loc

  datatype mono =
      TYMONO of mono ty

  datatype 't record_kind =
      UNIV
    | REC of 't tyrow list

  type 't kind = kind_prop * 't record_kind * loc

  type 't kinded_tyvar = tyvar * 't kind * loc

  type kinded_tyvarseq = mono kinded_tyvar list * loc

  datatype poly =
      TYPOLY of kinded_tyvarseq * poly ty * loc

  datatype annot =
      TYWILD of loc
    | TYVAR_FREE of annot kinded_tyvar
    | TYFLEXRECORD of annot tyrow list * loc

  type mono_ty = mono ty
  type poly_ty = poly ty
  type annot_ty = annot ty
  type mono_kind = mono kind
  type annot_kind = annot kind

  datatype ffi_ty =
      FFITYVAR of tyvar
    | FFITYRECORD of ffi_tyrow list * loc
    | FFITYCON of ffi_ty list * longtycon * loc
    | FFITYFUN of ffi_attr option * ffi_arg * ffi_ret * loc

  withtype ffi_tyrow = lab * ffi_ty * loc
  and ffi_arg = ffi_ty list * ffi_ty list option
  and ffi_ret = ffi_ty list

  datatype pat =
      PATWILD of loc
    | PATCONST of constant * loc
    | PATID of longvid
    | PATRECORD of patrow list * bool * loc
    | PATCON of longvid * pat * loc
    | PATTYPED of pat * annot ty * loc
    | PATAS of vid * annot ty option * pat * loc

  withtype patrow = lab * pat * loc

  datatype exbind =
      EXBIND of vid * mono ty option * loc
    | EXBINDREP of vid * longvid * loc

  type typbind = tyvar list * tycon * mono ty * loc

  type conbind = vid * mono ty option * loc

  type datbind = tyvar list * tycon * conbind list * loc

  datatype join_extend = JOIN | EXTEND

  datatype exp =
      EXPCONST of constant * loc
    | EXPID of longvid
    | EXPRECORD of exprow list * loc
    | EXPSELECT of lab * loc
    | EXPLET of dec list * exp * loc
    | EXPAPP of exp * exp * loc
    | EXPTYPED of exp * annot ty * loc
    | EXPHANDLE of exp * mrule list * loc
    | EXPRAISE of exp * loc
    | EXPCASE of exp * mrule list * loc
    | EXPFN of mrule list * loc
    | EXPSIZEOF of mono ty * loc
    | EXPRECORD_UPDATE of exp * exprow list * loc
    | EXPIMPORT_NAME of string * ffi_ty * loc
    | EXPIMPORT_EXP of exp * ffi_ty * loc
    | EXPJOIN of join_extend * exp * exp * loc
    | EXPSQLSCHEMA of exp * mono ty * loc
    | EXPUPDATE of exp * exp * loc
    | EXPDYNAMIC_AS of exp * mono ty * loc
    | EXPDYNAMIC_OF of exp * mono ty * loc
    | EXPDYNAMICVIEW of exp * mono ty * loc
    | EXPDYNAMICNULL of mono ty * loc
    | EXPDYNAMICTOP of mono ty * loc
    | EXPDYNAMICCASE of exp * dynamic_mrule list * loc
    | EXPREIFYTY of mono ty * loc

  and dec =
      DECVAL of kinded_tyvarseq * valbind list * valbind list * loc
    | DECFUN of kinded_tyvarseq * fvalbind list * loc
    | DECTYPE of typbind list * loc
    | DECDATATYPE of datbind list * typbind list * loc
    | DECDATATYPEREP of tycon * longtycon * loc
    | DECABSTYPE of datbind list * typbind list * dec list * loc
    | DECEXCEPTION of exbind list * loc
    | DECLOCAL of dec list * dec list * loc
    | DECOPEN of longstrid list * loc
    | DECPOLYREC of pvalbind list * loc

  withtype mrule = pat * exp * loc
  and dynamic_mrule = kinded_tyvarseq * pat * exp * loc
  and exprow = lab * exp * loc
  and valbind = pat * exp * loc
  and fvalbind = vid * (annot ty * loc) list * (pat list * exp * loc) list * loc
  and pvalbind = vid * poly ty * exp * loc

  type frule = pat list * exp * loc

  datatype spec =
      SPECVAL of valdesc list * loc
    | SPECTYPE of bool * typdesc list * loc
    | SPECDATATYPE of datdesc list * loc
    | SPECDATATYPEREP of tycon * longtycon * loc
    | SPECEXCEPTION of exdesc list * loc
    | SPECSTRUCTURE of strdesc list * loc
    | SPECINCLUDE of sigexp * loc
    | SPECSHARINGTYPE of spec list * longtycon list * loc
    | SPECSHARING of spec list * longstrid list * loc

  and sigexp =
      SIGBASIC of spec list * loc
    | SIGID of sigid
    | SIGWHERE of sigexp * wheretype * loc

  withtype valdesc = vid * poly ty * loc
  and typdesc = tyvar list * tycon * loc
  and datdesc = datbind
  and exdesc = vid * mono ty option * loc
  and strdesc = strid * sigexp * loc
  and wheretype = tyvar list * longtycon * mono ty * loc

  datatype strexp =
      STRBASIC of strdec list * loc
    | STRID of longstrid
    | STRCONSTRAINT of strexp * sigop * sigexp * loc
    | STRAPP of funid * strexp * loc
    | STRLET of strdec list * strexp * loc

  and strdec =
      STRDEC of dec
    | STRUCTURE of strbind list * loc
    | STRLOCAL of strdec list * strdec list * loc

  withtype strbind = strid * strexp * loc

  type sigbind = sigid * sigexp * loc

  type funbind = funid * strid * sigexp * strexp * loc

  type sigdec = sigbind list * loc

  datatype topdec =
      TOPSTRDEC of strdec
    | TOPSIGNATURE of sigdec
    | TOPFUNCTOR of funbind list * loc

  fun patLoc pat =
      case pat of
        PATWILD loc => loc
      | PATCONST (_, loc) => loc
      | PATID (_, _, loc) => Loc.LOC loc
      | PATRECORD (_, _, loc) => loc
      | PATCON (_, _, loc) => loc
      | PATTYPED (_, _, loc) => loc
      | PATAS (_, _, _, loc) => loc

  fun sigexpLoc sigexp =
      case sigexp of
        SIGBASIC (_, loc) => loc
      | SIGID (_, loc) => Loc.LOC loc
      | SIGWHERE (_, _, loc) => loc

  (* revert to absyn for printing *)

  structure F = FFIAttributes
  structure A = Absyn

  val dummyPos = {source = Loc.INTERACTIVE, pos = Loc.EOF}
  val loc = (dummyPos, dummyPos)

  fun absynKindProp {reify, boxed, unboxed, eq} =
      (if reify then [(Symbol.intern "reify", loc)] else nil)
      @ (if boxed then [(Symbol.intern "boxed", loc)] else nil)
      @ (if unboxed then [(Symbol.intern "unboxed", loc)] else nil)
      @ (if eq then [(Symbol.intern "eq", loc)] else nil)

  fun absynFfiAttr {isPure, fast, unsafe, causeGC, callingConvention} =
      ((if isPure then [(Symbol.intern "pure", loc)] else nil)
       @ (if fast then [(Symbol.intern "fast", loc)] else nil)
       @ (if unsafe then [(Symbol.intern "unsafe", loc)] else nil)
       @ (if causeGC then [(Symbol.intern "causeGC", loc)] else nil)
       @ (case callingConvention of
            NONE => nil
          | SOME F.FFI_CDECL => [(Symbol.intern "cdecl", loc)]
          | SOME F.FFI_STDCALL => [(Symbol.intern "stdcall", loc)]
          | SOME F.FFI_FASTCC => [(Symbol.intern "fastcc", loc)]),
       loc)

  fun absynTy ext ty =
      case ty of
        TYVAR tyvar =>
        A.TYVAR (false, tyvar)
      | TYRECORD (rows, _) =>
        A.TYRECORD (map (absynTyrow ext) rows, false, loc)
      | TYCON (tys, tycon, _) =>
        A.TYCON (absynTyseq ext tys, tycon, loc)
      | TYFUN (ty1, ty2, _) =>
        A.TYFUN (absynTy ext ty1, absynTy ext ty2, loc)
      | TY t => ext t

  and absynTyrow ext (lab, ty, _) =
      (lab, absynTy ext ty, loc)

  and absynTyseq ext nil = NONE
    | absynTyseq ext tys = SOME (map (absynTy ext) tys, loc)

  fun absynMono (TYMONO ty) =
      absynTy absynMono ty

  fun absynMonoTy ty =
      absynTy absynMono ty

  fun absynKind ext (prop, reckind, _) =
      case reckind of
        REC rows =>
        SOME (A.REC (absynKindProp prop, map (absynTyrow ext) rows, loc))
      | UNIV =>
        case absynKindProp prop of
          nil => NONE
        | props => SOME (A.UNIV (props, loc))

  fun absynKindedTyvar ext (tyvar, kind, _) =
      ((false, tyvar), absynKind ext kind, loc)

  fun absynKindedTyvarseq (nil, _) = NONE
    | absynKindedTyvarseq (tyvars, _) =
      SOME (map (absynKindedTyvar absynMono) tyvars, loc)

  fun absynPoly (TYPOLY ((tyvars, _), ty, _)) =
      A.TYPOLY ((map (absynKindedTyvar absynMono) tyvars, loc),
                absynTy absynPoly ty,
                loc)

  fun absynPolyTy ty =
      absynTy absynPoly ty

  fun absynAnnot annot =
      case annot of
        TYWILD _ =>
        A.TYWILD loc
      | TYVAR_FREE tyvar =>
        A.TYVAR_FREE (absynKindedTyvar absynAnnot tyvar)
      | TYFLEXRECORD (rows, _) =>
        A.TYRECORD (map (absynTyrow absynAnnot) rows, true, loc)

  fun absynAnnotTy ty =
      absynTy absynAnnot ty

  fun absynFfiTy ty =
      case ty of
        FFITYVAR tyvar =>
        A.FFITYVAR (false, tyvar)
      | FFITYRECORD (rows, _) =>
        A.FFITYRECORD (map absynFfiTyrow rows, loc)
      | FFITYCON (tys, tycon, _) =>
        A.FFITYCON (absynFfiTyseq tys, tycon, loc)
      | FFITYFUN (attr, (argTys, varTys), retTys, _) =>
        A.FFITYFUN
          (Option.map absynFfiAttr attr,
           (map absynFfiTy argTys, Option.map (map absynFfiTy) varTys, loc),
           (map absynFfiTy retTys, loc),
           loc)

  and absynFfiTyrow (lab, ty, _) =
      (lab, absynFfiTy ty, loc)

  and absynFfiTyseq nil = NONE
    | absynFfiTyseq tys = SOME (map absynFfiTy tys, loc)

  fun absynPat pat =
      case pat of
        PATWILD _ =>
        A.PATWILD loc
      | PATCONST (const, _) =>
        A.PATCONST (const, loc)
      | PATID vid =>
        A.PATID (false, vid, loc)
      | PATRECORD (rows, flex, _) =>
        A.PATRECORD (map absynPatrow rows, flex, loc)
      | PATCON (vid, pat, _) =>
        A.PATAPP (A.PATID (false, vid, loc), absynPat pat, loc)
      | PATTYPED (pat, ty, _) =>
        A.PATTYPED (absynPat pat, absynAnnotTy ty, loc)
      | PATAS (vid, ty, pat, _) =>
        A.PATAS ((false, vid, loc),
                 Option.map absynAnnotTy ty,
                 absynPat pat,
                 loc)

  and absynPatrow (lab, pat, _) =
      A.PATROW (lab, absynPat pat, loc)

  fun absynExbind exbind =
      case exbind of
        EXBIND (vid, ty, _) =>
        A.EXBIND ((false, vid, loc), Option.map absynMonoTy ty, loc)
      | EXBINDREP (vid, longvid, _) =>
        A.EXBINDREP ((false, vid, loc), (false, longvid, loc), loc)

  fun absynTyvarseq nil = NONE
    | absynTyvarseq tyvars = SOME (map (fn t => (false, t)) tyvars, loc)

  fun absynTypbind (tyvars, tycon, ty, _) =
      (absynTyvarseq tyvars, tycon, absynMonoTy ty, loc)

  fun absynWithty nil = NONE
    | absynWithty typbind = SOME (map absynTypbind typbind, loc)

  fun absynConbind (vid, ty, _) =
      ((false, vid, loc), Option.map absynMonoTy ty, loc)

  fun absynDatbind (tyvars, tycon, conbinds, _) =
      (absynTyvarseq tyvars, tycon, map absynConbind conbinds, loc)

  fun absynExp exp =
      case exp of
        EXPCONST (const, _) =>
        A.EXPCONST (const, loc)
      | EXPID vid =>
        A.EXPID (false, vid, loc)
      | EXPRECORD (rows, _) =>
        A.EXPRECORD (map absynExprow rows, loc)
      | EXPSELECT (lab, _) =>
        A.EXPSELECT (lab, loc)
      | EXPLET (decs, exp, _) =>
        A.EXPLET (map absynDec decs, ([absynExp exp], loc), loc)
      | EXPAPP (exp1, exp2, _) =>
        A.EXPAPP (absynExp exp1, absynExp exp2, loc)
      | EXPTYPED (exp, ty, _) =>
        A.EXPTYPED (absynExp exp, absynAnnotTy ty, loc)
      | EXPHANDLE (exp, mrules, _) =>
        A.EXPHANDLE (absynExp exp, map absynMrule mrules, loc)
      | EXPRAISE (exp, _) =>
        A.EXPRAISE (absynExp exp, loc)
      | EXPCASE (exp, mrules, _) =>
        A.EXPCASE (absynExp exp, map absynMrule mrules, loc)
      | EXPFN (mrules, _) =>
        A.EXPFN (map absynMrule mrules, loc)
      | EXPSIZEOF (ty, _) =>
        A.EXPSIZEOF (absynMonoTy ty, loc)
      | EXPRECORD_UPDATE (exp, rows, _) =>
        A.EXPRECORD_UPDATE (absynExp exp, map absynExprow rows, loc)
      | EXPIMPORT_NAME (name, ty, _) =>
        A.EXPIMPORT_NAME ((name, loc), absynFfiTy ty, loc)
      | EXPIMPORT_EXP (exp, ty, _) =>
        A.EXPIMPORT_EXP (absynExp exp, absynFfiTy ty, loc)
      | EXPSQLSCHEMA (exp, ty, _) =>
        A.EXPAPP (absynExp exp,
                  A.EXPSQL (AbsynSQL.SQLSERVER (NONE, absynMonoTy ty, loc)),
                  loc)
      | EXPJOIN (JOIN, exp1, exp2, _) =>
        A.EXPJOIN (absynExp exp1, absynExp exp2, loc)
      | EXPJOIN (EXTEND, exp1, exp2, _) =>
        A.EXPEXTEND (absynExp exp1, absynExp exp2, loc)
      | EXPUPDATE (exp1, exp2, _) =>
        A.EXPUPDATE1 (absynExp exp1, absynExp exp2, loc)
      | EXPDYNAMIC_AS (exp, ty, _) =>
        A.EXPDYNAMIC_AS (absynExp exp, absynMonoTy ty, loc)
      | EXPDYNAMIC_OF (exp, ty, _) =>
        A.EXPDYNAMIC_OF (absynExp exp, absynMonoTy ty, loc)
      | EXPDYNAMICVIEW (exp, ty, _) =>
        A.EXPDYNAMICVIEW (absynExp exp, absynMonoTy ty, loc)
      | EXPDYNAMICNULL (ty, _) =>
        A.EXPDYNAMICNULL (absynMonoTy ty, loc)
      | EXPDYNAMICTOP (ty, _) =>
        A.EXPDYNAMICTOP (absynMonoTy ty, loc)
      | EXPDYNAMICCASE (exp, mrules, _) =>
        A.EXPDYNAMICCASE (absynExp exp, map absynDynamicMrule mrules, loc)
      | EXPREIFYTY (ty, _) =>
        A.EXPREIFYTY (absynMonoTy ty, loc)

  and absynExprow (lab, exp, _) =
      A.EXPROW (lab, absynExp exp, loc)

  and absynMrule (pat, exp, _) =
      (absynPat pat, absynExp exp, loc)

  and absynDynamicMrule (tyvars, pat, exp, _) =
      (absynKindedTyvarseq tyvars, absynPat pat, absynExp exp, loc)

  and absynDec dec =
      case dec of
        DECVAL (tyvarseq, valbinds, recbinds, _) =>
        A.DECVAL (absynKindedTyvarseq tyvarseq,
                  map absynValbind valbinds
                  @ (case recbinds of
                       nil => nil
                     | _ :: _ => [A.VALREC (map absynValbind recbinds, loc)]),
                  loc)
      | DECFUN (tyvarseq, fvalbinds, _) =>
        A.DECFUN (absynKindedTyvarseq tyvarseq,
                  map absynFvalbind fvalbinds, loc)
      | DECTYPE (typbinds, _) =>
        A.DECTYPE (map absynTypbind typbinds, loc)
      | DECDATATYPE (datbinds, typbinds, _) =>
        A.DECDATATYPE (map absynDatbind datbinds, absynWithty typbinds, loc)
      | DECDATATYPEREP (tycon, longtycon, _) =>
        A.DECDATATYPEREP (tycon, longtycon, loc)
      | DECABSTYPE (datbinds, typbinds, decs, _) =>
        A.DECABSTYPE (map absynDatbind datbinds,
                      absynWithty typbinds,
                      map absynDec decs,
                      loc)
      | DECEXCEPTION (exbinds, _) =>
        A.DECEXCEPTION (map absynExbind exbinds, loc)
      | DECLOCAL (decs1, decs2, _) =>
        A.DECLOCAL (map absynDec decs1, map absynDec decs2, loc)
      | DECOPEN (strids, _) =>
        A.DECOPEN (strids, loc)
      | DECPOLYREC (pvalbinds, _) =>
        A.DECVALREC (NONE, map absynPvalbind pvalbinds, loc)

  and absynValbind (pat, exp, _) =
      A.VALBIND (absynPat pat, absynExp exp, loc)

  and absynFrule pat (pats, exp, _) : A.frule =
      (foldl (fn (pat, z) => A.PATAPP (z, absynPat pat, loc)) pat pats,
       NONE,
       absynExp exp,
       loc)

  and absynFvalbind (vid, tys, frules, _) =
      let
        val id = foldl (fn ((ty, _), z) => A.PATTYPED (z, absynAnnotTy ty, loc))
                       (A.PATID (false, (nil, vid, loc), loc))
                       tys
      in
        (map (absynFrule id) frules, loc)
      end

  and absynPvalbind (vid, ty, exp, _) =
      (A.PATTYPED (A.PATID (false, (nil, vid, loc), loc), absynPolyTy ty, loc),
       absynExp exp,
       loc)

  fun absynValdesc (vid, ty, _) =
      (vid, absynPolyTy ty, loc)

  fun absynTypdesc (tyvars, tycon, _) =
      (absynTyvarseq tyvars, tycon, loc)

  fun absynCondesc (vid, ty, _) =
      (vid, Option.map absynMonoTy ty, loc)

  fun absynDatdesc (tyvars, tycon, condescs, _) =
      (absynTyvarseq tyvars, tycon, map absynCondesc condescs, loc)

  fun absynSpec spec =
      case spec of
        SPECVAL (valdescs, _) =>
        A.SPECVAL (map absynValdesc valdescs, loc)
      | SPECTYPE (false, typdescs, _) =>
        A.SPECTYPE (map absynTypdesc typdescs, loc)
      | SPECTYPE (true, typdescs, _) =>
        A.SPECEQTYPE (map absynTypdesc typdescs, loc)
      | SPECDATATYPE (datdescs, _) =>
        A.SPECDATATYPE (map absynDatdesc datdescs, loc)
      | SPECDATATYPEREP (tycon, longtycon, _) =>
        A.SPECDATATYPEREP (tycon, longtycon, loc)
      | SPECEXCEPTION (exdescs, _) =>
        A.SPECEXCEPTION (map absynCondesc exdescs, loc)
      | SPECSTRUCTURE (strdescs, _) =>
        A.SPECSTRUCTURE (map absynStrdesc strdescs, loc)
      | SPECINCLUDE (sigexp, _) =>
        A.SPECINCLUDE (absynSigexp sigexp, loc)
      | SPECSHARINGTYPE (specs, tycons, _) =>
        A.SPECSHARINGTYPE (map absynSpec specs, tycons, loc)
      | SPECSHARING (specs, strids, _) =>
        A.SPECSHARING (map absynSpec specs, strids, loc)

  and absynSigexp sigexp =
      case sigexp of
        SIGBASIC (specs, _) =>
        A.SIGBASIC (map absynSpec specs, loc)
      | SIGID sigid =>
        A.SIGID sigid
      | SIGWHERE (sigexp, wheretype, _) =>
        A.SIGWHERE (absynSigexp sigexp, [absynWheretype wheretype], loc)

  and absynStrdesc (strid, sigexp, _) =
      (strid, absynSigexp sigexp, loc)

  and absynWheretype (tyvars, tycon, ty, _) =
      (absynTyvarseq tyvars, tycon, absynMonoTy ty, loc)

  fun absynStrexp strexp =
      case strexp of
        STRBASIC (strdecs, _) =>
        A.STRBASIC (map absynStrdec strdecs, loc)
      | STRID strid =>
        A.STRID strid
      | STRCONSTRAINT (strexp, sigop, sigexp, _) =>
        A.STRCONSTRAINT
          (absynStrexp strexp, (sigop, absynSigexp sigexp, loc), loc)
      | STRAPP (funid, strexp, _) =>
        A.STRAPP (funid, SOME (A.FUNARG (absynStrexp strexp)), loc)
      | STRLET (strdecs, strexp, _) =>
        A.STRLET (map absynStrdec strdecs, absynStrexp strexp, loc)

  and absynStrdec strdec =
      case strdec of
        STRDEC dec =>
        A.STRDEC (absynDec dec)
      | STRUCTURE (strbinds, _) =>
        A.STRUCTURE (map absynStrbind strbinds, loc)
      | STRLOCAL (strdecs1, strdecs2, _) =>
        A.STRLOCAL (map absynStrdec strdecs1, map absynStrdec strdecs2, loc)

  and absynStrbind (strid, strexp, _) : A.strbind =
      (strid, NONE, absynStrexp strexp, loc)

  fun absynSigbind (sigid, sigexp, _) =
      (sigid, absynSigexp sigexp, loc)

  fun absynFunbind (funid, strid, sigexp, strexp, _) =
      (funid,
       SOME (A.FUNPARAM (strid, absynSigexp sigexp, loc)),
       NONE,
       absynStrexp strexp,
       loc)

  fun absynSigdec (sigbinds, _) =
      (map absynSigbind sigbinds, loc)

  fun absynTopdec topdec =
      case topdec of
        TOPSTRDEC strdec =>
        A.TOPSTRDEC (absynStrdec strdec)
      | TOPSIGNATURE sigdec =>
        A.TOPSIGNATURE (absynSigdec sigdec)
      | TOPFUNCTOR (funbinds, _) =>
        A.TOPFUNCTOR (map absynFunbind funbinds, loc)

  fun format_mono_ty ty = AbsynTyFormatter.format_ty (absynMonoTy ty)
  fun format_poly_ty ty = AbsynTyFormatter.format_ty (absynPolyTy ty)
  fun format_annot_ty ty = AbsynTyFormatter.format_ty (absynAnnotTy ty)
  fun format_kind ext kind =
      case absynKind ext kind of
        NONE => nil
      | SOME kind => AbsynTyFormatter.format_kind kind
  fun format_mono_kind kind = format_kind absynMono kind
  fun format_annot_kind kind = format_kind absynAnnot kind
  fun format_ffi_ty ty = AbsynTyFormatter.format_ffi_ty (absynFfiTy ty)
  fun format_pat pat = AbsynFormatter.format_pat (absynPat pat)
  fun format_sigexp sigexp = AbsynFormatter.format_sigexp (absynSigexp sigexp)
  fun format_strdec strdec = AbsynFormatter.format_strdec (absynStrdec strdec)
  fun format_strexp strexp = AbsynFormatter.format_strexp (absynStrexp strexp)
  fun format_funbind head funbind =
      AbsynFormatter.format_funbind head (absynFunbind funbind)
  fun format_topdec topdec = AbsynFormatter.format_topdec (absynTopdec topdec)

end
