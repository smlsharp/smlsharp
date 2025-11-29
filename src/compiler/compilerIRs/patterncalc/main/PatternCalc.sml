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

  datatype 't tvkind =
      UNIV
    | REC of 't tyrow list

  type 't kind = kind_prop * 't tvkind * loc

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

  structure F = FFIAttributes
  structure P = PrintCalc
  structure A = AbsynFormatter

  fun printKindProp {reify, boxed, unboxed, eq} =
      (if reify then [P.KIND_ID (P.KEYWORD ["reify"])] else nil)
      @ (if boxed then [P.KIND_ID (P.KEYWORD ["boxed"])] else nil)
      @ (if unboxed then [P.KIND_ID (P.KEYWORD ["unboxed"])] else nil)
      @ (if eq then [P.KIND_ID (P.KEYWORD ["eq"])] else nil)

  fun printFfiAttr {isPure, fast, unsafe, causeGC, callingConvention} =
      P.FFI_ATTR
        ((if isPure then [P.KEYWORD ["pure"]] else nil)
         @ (if fast then [P.KEYWORD ["fast"]] else nil)
         @ (if unsafe then [P.KEYWORD ["unsafe"]] else nil)
         @ (if causeGC then [P.KEYWORD ["causeGC"]] else nil)
         @ (case callingConvention of
              NONE => nil
            | SOME F.FFI_CDECL => [P.KEYWORD ["cdecl"]]
            | SOME F.FFI_STDCALL => [P.KEYWORD ["stdcall"]]
            | SOME F.FFI_FASTCC => [P.KEYWORD ["fastcc"]]))

  fun printTyvar tyvar =
      A.printId tyvar

  fun printTy ext ty =
      case ty of
        TYVAR tyvar =>
        printTyvar tyvar
      | TYRECORD (rows, _) =>
        P.EXPRECORD (map (printTyrow ext) rows, false)
      | TYCON (tys, tycon, _) =>
        P.TYCON (map (printTy ext) tys, A.printLongtycon tycon)
      | TYFUN (ty1, ty2, _) =>
        P.TYFUN (printTy ext ty1, printTy ext ty2)
      | TY t => ext t

  and printTyrow ext (lab, ty, _) =
      P.TYROW (A.printLab lab, printTy ext ty)

  fun printMono (TYMONO ty) =
      printTy printMono ty

  fun printMonoTy ty =
      printTy printMono ty

  fun printTvkind ext tvkind =
      case tvkind of
        UNIV => nil
      | REC rows => [P.KIND_RECORD (map (printTyrow ext) rows)]

  fun printKind ext (prop, tvkind, _) =
      printKindProp prop @ printTvkind ext tvkind

  fun printKindedTyvar ext (tyvar, kind, _) =
      P.TYVAR (printTyvar tyvar, printKind ext kind)

  fun printKindedTyvarseq (nil, _) = nil
    | printKindedTyvarseq (tyvars, _) = map (printKindedTyvar printMono) tyvars

  fun printPoly (TYPOLY ((tyvars, _), ty, _)) =
      P.TYPOLY (map (printKindedTyvar printMono) tyvars,
                printTy printPoly ty)

  fun printPolyTy ty =
      printTy printPoly ty

  fun printAnnot annot =
      case annot of
        TYWILD _ =>
        P.PATWILD
      | TYVAR_FREE tyvar =>
        P.TYVAR_FREE (printKindedTyvar printAnnot tyvar)
      | TYFLEXRECORD (rows, _) =>
        P.EXPRECORD (map (printTyrow printAnnot) rows, true)

  fun printAnnotTy ty =
      printTy printAnnot ty

  fun printFfiTy ty =
      case ty of
        FFITYVAR tyvar =>
        printTyvar tyvar
      | FFITYRECORD (rows, _) =>
        P.EXPRECORD (map printFfiTyrow rows, false)
      | FFITYCON (tys, tycon, _) =>
        P.TYCON (map printFfiTy tys, A.printLongtycon tycon)
      | FFITYFUN (attr, (argTys, varTys), retTys, _) =>
        P.FFITYFUN
          (Option.map printFfiAttr attr,
           P.FFI_ARG
             (map printFfiTy argTys, Option.map (map printFfiTy) varTys),
           P.FFI_RET (map printFfiTy retTys))

  and printFfiTyrow (lab, ty, _) =
      P.TYROW (A.printLab lab, printFfiTy ty)

  fun printPat pat =
      case pat of
        PATWILD _ =>
        P.PATWILD
      | PATCONST (const, _) =>
        A.printConstant const
      | PATID vid =>
        A.printLongvid vid
      | PATRECORD (rows, flex, _) =>
        P.EXPRECORD (map printPatrow rows, flex)
      | PATCON (vid, pat, _) =>
        P.EXPAPP (A.printLongvid vid, printPat pat)
      | PATTYPED (pat, ty, _) =>
        P.EXPTYPED (printPat pat, printAnnotTy ty)
      | PATAS (vid, NONE, pat, _) =>
        P.PATAS (A.printVid vid, printPat pat)
      | PATAS (vid, SOME ty, pat, _) =>
        P.PATAS (P.EXPTYPED (A.printVid vid, printAnnotTy ty), printPat pat)

  and printPatrow (lab, pat, _) =
      P.EXPROW (A.printLab lab, printPat pat)

  fun printExbind exbind =
      case exbind of
        EXBIND (vid, ty, _) =>
        P.CONBIND (A.printVid vid, Option.map printMonoTy ty)
      | EXBINDREP (vid, longvid, _) =>
        P.VALBIND (A.printVid vid, A.printLongvid longvid)

  fun printTypbind (tyvarseq, tycon, ty, _) =
      P.TYPBIND (map printTyvar tyvarseq, A.printTycon tycon, printMonoTy ty)

  fun printWithty nil = NONE
    | printWithty typbind = SOME (P.WITHTYPE (map printTypbind typbind))

  fun printConbind (vid, ty, _) =
      P.CONBIND (A.printVid vid, Option.map printMonoTy ty)

  fun printDatbind (tyvarseq, tycon, conbinds, _) =
      P.DATBIND (map printTyvar tyvarseq,
                 A.printTycon tycon,
                 map printConbind conbinds)

  fun printExp exp =
      case exp of
        EXPCONST (const, _) =>
        A.printConstant const
      | EXPID vid =>
        A.printLongvid vid
      | EXPRECORD (rows, _) =>
        P.EXPRECORD (map printExprow rows, false)
      | EXPSELECT (lab, _) =>
        P.EXPSELECT (A.printLab lab)
      | EXPLET (decs, exp, _) =>
        P.EXPLET (map printDec decs, [printExp exp])
      | EXPAPP (exp1, exp2, _) =>
        P.EXPAPP (printExp exp1, printExp exp2)
      | EXPTYPED (exp, ty, _) =>
        P.EXPTYPED (printExp exp, printAnnotTy ty)
      | EXPHANDLE (exp, mrules, _) =>
        P.EXPHANDLE (printExp exp, map printMrule mrules)
      | EXPRAISE (exp, _) =>
        P.EXPRAISE (printExp exp)
      | EXPCASE (exp, mrules, _) =>
        P.EXPCASE (printExp exp, map printMrule mrules)
      | EXPFN (mrules, _) =>
        P.EXPFN (map printMrule mrules)
      | EXPSIZEOF (ty, _) =>
        P.EXPSIZEOF (printMonoTy ty)
      | EXPRECORD_UPDATE (exp, rows, _) =>
        P.EXPRECORD_UPDATE (printExp exp, map printExprow rows)
      | EXPIMPORT_NAME (name, ty, _) =>
        P.EXPIMPORT_NAME (P.STRING name, printFfiTy ty)
      | EXPIMPORT_EXP (exp, ty, _) =>
        P.EXPIMPORT_EXP (printExp exp, printFfiTy ty)
      | EXPSQLSCHEMA (exp, ty, _) =>
        P.EXPAPP
          (P.EXPAPP (P.KEYWORD ["EXPSQLSCHEMA"], printExp exp), printMonoTy ty)
      | EXPJOIN (JOIN, exp1, exp2, _) =>
        P.EXPJOIN (printExp exp1, printExp exp2)
      | EXPJOIN (EXTEND, exp1, exp2, _) =>
        P.EXPEXTEND (printExp exp1, printExp exp2)
      | EXPUPDATE (exp1, exp2, _) =>
        P.EXPUPDATE1 (printExp exp1, printExp exp2)
      | EXPDYNAMIC_AS (exp, ty, _) =>
        P.EXPDYNAMIC_AS (printExp exp, printMonoTy ty)
      | EXPDYNAMIC_OF (exp, ty, _) =>
        P.EXPDYNAMIC_OF (printExp exp, printMonoTy ty)
      | EXPDYNAMICVIEW (exp, ty, _) =>
        P.EXPDYNAMICVIEW (printExp exp, printMonoTy ty)
      | EXPDYNAMICNULL (ty, _) =>
        P.EXPDYNAMICNULL (printMonoTy ty)
      | EXPDYNAMICTOP (ty, _) =>
        P.EXPDYNAMICTOP (printMonoTy ty)
      | EXPDYNAMICCASE (exp, mrules, _) =>
        P.EXPDYNAMICCASE (printExp exp, map printDynamicMrule mrules)
      | EXPREIFYTY (ty, _) =>
        P.EXPREIFYTY (printMonoTy ty)

  and printExprow (lab, exp, _) =
      P.EXPROW (A.printLab lab, printExp exp)

  and printMrule (pat, exp, _) =
      P.MRULE (printPat pat, printExp exp)

  and printDynamicMrule (tyvars, pat, exp, _) =
      P.DYNAMIC_MRULE (printKindedTyvarseq tyvars, printPat pat, printExp exp)

  and printDec dec =
      case dec of
        DECVAL (tyvarseq, valbinds, recbinds, _) =>
        P.DECVAL (printKindedTyvarseq tyvarseq,
                  map printValbind valbinds
                  @ (case recbinds of
                       nil => nil
                     | _ :: _ => [P.VALREC (map printValbind recbinds)]))
      | DECFUN (tyvarseq, fvalbinds, _) =>
        P.DECFUN (printKindedTyvarseq tyvarseq,
                  map printFvalbind fvalbinds)
      | DECTYPE (typbinds, _) =>
        P.DECTYPE (map printTypbind typbinds)
      | DECDATATYPE (datbinds, typbinds, _) =>
        P.DECDATATYPE (map printDatbind datbinds, printWithty typbinds)
      | DECDATATYPEREP (tycon, longtycon, _) =>
        P.DECDATATYPEREP (A.printTycon tycon, A.printLongtycon longtycon)
      | DECABSTYPE (datbinds, typbinds, decs, _) =>
        P.DECABSTYPE (map printDatbind datbinds,
                      printWithty typbinds,
                      map printDec decs)
      | DECEXCEPTION (exbinds, _) =>
        P.DECEXCEPTION (map printExbind exbinds)
      | DECLOCAL (decs1, decs2, _) =>
        P.DECLOCAL (map printDec decs1, map printDec decs2)
      | DECOPEN (strids, _) =>
        P.DECOPEN (map A.printLongstrid strids)
      | DECPOLYREC (pvalbinds, _) =>
        P.DECVALREC (nil, map printPvalbind pvalbinds)

  and printValbind (pat, exp, _) =
      P.VALBIND (printPat pat, printExp exp)

  and printFrule pat (pats, exp, _) =
      P.FRULE
        (foldl (fn (pat, z) => P.EXPAPP (z, printPat pat)) pat pats,
         NONE,
         printExp exp)

  and printFvalbind (vid, tys, frules, _) =
      let
        val id = foldl (fn ((ty, _), z) => P.EXPTYPED (z, printAnnotTy ty))
                       (A.printVid vid)
                       tys
      in
        P.FVALBIND (map (printFrule id) frules)
      end

  and printPvalbind (vid, ty, exp, _) =
      P.VALBIND (P.EXPTYPED (A.printVid vid, printPolyTy ty), printExp exp)

  fun printValdesc (vid, ty, _) =
      P.VALDESC (A.printVid vid, printPolyTy ty)

  fun printTypdesc (tyvars, tycon, _) =
      P.TYPDESC (map printTyvar tyvars, A.printTycon tycon)

  fun printCondesc (vid, ty, _) =
      P.CONBIND (A.printVid vid, Option.map printMonoTy ty)

  fun printDatdesc (tyvars, tycon, condescs, _) =
      P.DATBIND (map printTyvar tyvars,
                 A.printTycon tycon,
                 map printCondesc condescs)

  fun printSpec spec =
      case spec of
        SPECVAL (valdescs, _) =>
        P.DECVAL (nil, map printValdesc valdescs)
      | SPECTYPE (false, typdescs, _) =>
        P.DECTYPE (map printTypdesc typdescs)
      | SPECTYPE (true, typdescs, _) =>
        P.SPECEQTYPE (map printTypdesc typdescs)
      | SPECDATATYPE (datdescs, _) =>
        P.DECDATATYPE (map printDatdesc datdescs, NONE)
      | SPECDATATYPEREP (tycon, longtycon, _) =>
        P.DECDATATYPEREP (A.printTycon tycon, A.printLongtycon longtycon)
      | SPECEXCEPTION (exdescs, _) =>
        P.DECEXCEPTION (map printCondesc exdescs)
      | SPECSTRUCTURE (strdescs, _) =>
        P.STRUCTURE (map printStrdesc strdescs)
      | SPECINCLUDE (sigexp, _) =>
        P.SPECINCLUDE [printSigexp sigexp]
      | SPECSHARINGTYPE (specs, tycons, _) =>
        P.SPECSHARINGTYPE (map printSpec specs, map A.printLongtycon tycons)
      | SPECSHARING (specs, strids, _) =>
        P.SPECSHARING (map printSpec specs, map A.printLongstrid strids)

  and printSigexp sigexp =
      case sigexp of
        SIGBASIC (specs, _) =>
        P.SIGBASIC (map printSpec specs)
      | SIGID sigid =>
        A.printSigid sigid
      | SIGWHERE (sigexp, wheretype, _) =>
        P.SIGWHERE (printSigexp sigexp, [printWheretype wheretype])

  and printStrdesc (strid, sigexp, _) =
      P.VALDESC (A.printStrid strid, printSigexp sigexp)

  and printWheretype (tyvars, tycon, ty, _) =
      P.TYPBIND (map printTyvar tyvars, A.printLongtycon tycon, printMonoTy ty)

  fun printStrexp strexp =
      case strexp of
        STRBASIC (strdecs, _) =>
        P.STRBASIC (map printStrdec strdecs)
      | STRID strid =>
        A.printLongstrid strid
      | STRCONSTRAINT (strexp, Absyn.TRANSPARENT, sigexp, _) =>
        P.STRCONSTRAINT (printStrexp strexp, P.TRANSPARENT (printSigexp sigexp))
      | STRCONSTRAINT (strexp, Absyn.OPAQUE, sigexp, _) =>
        P.STRCONSTRAINT (printStrexp strexp, P.OPAQUE (printSigexp sigexp))
      | STRAPP (funid, strexp, _) =>
        P.STRAPP (A.printFunid funid, [printStrexp strexp])
      | STRLET (strdecs, strexp, _) =>
        P.EXPLET (map printStrdec strdecs, [printStrexp strexp])

  and printStrdec strdec =
      case strdec of
        STRDEC dec =>
        printDec dec
      | STRUCTURE (strbinds, _) =>
        P.STRUCTURE (map printStrbind strbinds)
      | STRLOCAL (strdecs1, strdecs2, _) =>
        P.DECLOCAL (map printStrdec strdecs1, map printStrdec strdecs2)

  and printStrbind (strid, strexp, _) =
      P.STRBIND (A.printStrid strid, NONE, printStrexp strexp)

  fun printSigbind (sigid, sigexp, _) =
      P.VALBIND (A.printSigid sigid, printSigexp sigexp)

  fun printFunbind (funid, strid, sigexp, strexp, _) =
      P.FUNBIND
        ((A.printFunid funid,
          [P.STRCONSTRAINT
             (A.printStrid strid, P.TRANSPARENT (printSigexp sigexp))]),
         NONE,
         printStrexp strexp)

  fun printSigdec (sigbinds, _) =
      P.SIGNATURE (map printSigbind sigbinds)

  fun printTopdec topdec =
      case topdec of
        TOPSTRDEC strdec =>
        printStrdec strdec
      | TOPSIGNATURE sigdec =>
        printSigdec sigdec
      | TOPFUNCTOR (funbinds, _) =>
        P.FUNCTOR (map printFunbind funbinds)

  fun format_pat x = PrintCalc.format_exp (printPat x)
  fun format_ffi_ty x = PrintCalc.format_exp (printFfiTy x)
  fun format_mono_kind x =
      PrintCalc.format_exp (P.CONCAT (printKind printMono x))
  fun format_annot_kind x =
      PrintCalc.format_exp (P.CONCAT (printKind printAnnot x))
  fun format_sigexp x = PrintCalc.format_exp (printSigexp x)
  fun format_strexp x = PrintCalc.format_exp (printStrexp x)
  fun format_strdec x = PrintCalc.format_exp (printStrdec x)
  fun format_funbind x y = PrintCalc.format_bind x (printFunbind y)
  fun format_topdec x = PrintCalc.format_exp (printTopdec x)

end
