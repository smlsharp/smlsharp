(**
 * @copyright (C) 2025 SML# Development Team.
 * @author Katsuhiro Ueno
 *)
structure AbsynUtils =
struct
  structure A = Absyn
  structure S = AbsynSQL

  fun tyLoc ty =
      case ty of
        A.TYVAR (_, (_, loc)) => loc
      | A.TYRECORD (_, _, loc) => loc
      | A.TYCON (_, _, loc) => loc
      | A.TYTUPLE (_, loc) => loc
      | A.TYFUN (_, _, loc) => loc
      | A.TYPAREN (_, loc) => loc
      | A.TYWILD loc => loc
      | A.TYVAR_FREE (_, _, loc) => loc
      | A.TYPOLY (_, _, loc) => loc

  fun kindLoc kind =
      case kind of
        A.UNIV (_, loc) => loc
      | A.REC (_, _, loc) => loc

  fun ffiTyLoc ffiTy =
      case ffiTy of
        A.FFITYVAR (_, (_, loc)) => loc
      | A.FFITYRECORD (_, loc) => loc
      | A.FFITYCON (_, _, loc) => loc
      | A.FFITYTUPLE (_, loc) => loc
      | A.FFITYFUN (_, _, _, loc) => loc
      | A.FFITYPAREN (_, loc) => loc

  fun patLoc pat =
      case pat of
        A.PATWILD loc => loc
      | A.PATCONST (_, loc) => loc
      | A.PATID (_, _, loc) => loc
      | A.PATRECORD (_, _, loc) => loc
      | A.PATTUPLE (_, loc) => loc
      | A.PATLIST (_, loc) => loc
      | A.PATPAREN (_, loc) => loc
      | A.PATAPP (_, loc) => loc
      | A.PATTYPED (_, _, loc) => loc
      | A.PATAS (_, _, _, loc) => loc

  fun patrowLoc patrow =
      case patrow of
        A.PATROW (_, _, loc) => loc
      | A.PATROWVAR (_, _, _, loc) => loc

  fun exbindLoc exbind =
      case exbind of
        A.EXBIND (_, _, loc) => loc
      | A.EXBINDREP (_, _, loc) => loc

  fun sqlexpLoc sqlexp =
      case sqlexp of
        S.SQLSERVER (_, _, loc) => loc
      | S.SQLFN (_, _, loc) => loc
      | S.SQL (_, loc) => loc

  fun expLoc exp =
      case exp of
        A.EXPCONST (_, loc) => loc
      | A.EXPID (_, _, loc) => loc
      | A.EXPRECORD (_, loc) => loc
      | A.EXPSELECT (_, loc) => loc
      | A.EXPTUPLE (_, loc) => loc
      | A.EXPLIST (_, loc) => loc
      | A.EXPSEQ (_, loc) => loc
      | A.EXPLET (_, _, loc) => loc
      | A.EXPPAREN (_, loc) => loc
      | A.EXPAPP (_, loc) => loc
      | A.EXPTYPED (_, _, loc) => loc
      | A.EXPANDALSO (_, _, loc) => loc
      | A.EXPORELSE (_, _, loc) => loc
      | A.EXPHANDLE (_, _, loc) => loc
      | A.EXPRAISE (_, loc) => loc
      | A.EXPIF (_, _, _, loc) => loc
      | A.EXPWHILE (_, _, loc) => loc
      | A.EXPCASE (_, _, loc) => loc
      | A.EXPFN (_, loc) => loc
      | A.EXPSIZEOF (_, loc) => loc
      | A.EXPRECORD_UPDATE (_, _, loc) => loc
      | A.EXPTUPLE_UPDATE (_, _, loc) => loc
      | A.EXPIMPORT_NAME (_, _, loc) => loc
      | A.EXPIMPORT_EXP (_, _, loc) => loc
      | A.EXPSQL sqlexp => sqlexpLoc sqlexp
      | A.EXPFOREACH_DATA (_, _, _, _, _, _, loc) => loc
      | A.EXPFOREACH_ARRAY (_, _, _, _, _, loc) => loc
      | A.EXPJOIN (_, _, loc) => loc
      | A.EXPEXTEND (_, _, loc) => loc
      | A.EXPUPDATE1 (_, _, loc) => loc
      | A.EXPUPDATE2 (_, _, loc) => loc
      | A.EXPDYNAMIC_AS (_, _, loc) => loc
      | A.EXPDYNAMIC_OF (_, _, loc) => loc
      | A.EXPDYNAMICVIEW (_, _, loc) => loc
      | A.EXPDYNAMICNULL (_, loc) => loc
      | A.EXPDYNAMICTOP (_, loc) => loc
      | A.EXPDYNAMICCASE (_, _, loc) => loc
      | A.EXPREIFYTY (_, loc) => loc

  fun valbindLoc valbind =
      case valbind of
        A.VALBIND (_, _, loc) => loc
      | A.VALREC (_, loc) => loc

  fun decLoc dec =
      case dec of
        A.DECVAL (_, _, loc) => loc
      | A.DECFUN (_, _, loc) => loc
      | A.DECTYPE (_, loc) => loc
      | A.DECDATATYPE (_, _, loc) => loc
      | A.DECDATATYPEREP (_, _, loc) => loc
      | A.DECABSTYPE (_, _, _, loc) => loc
      | A.DECEXCEPTION (_, loc) => loc
      | A.DECLOCAL (_, _, loc) => loc
      | A.DECOPEN (_, loc) => loc
      | A.DECSEMICOLON loc => loc
      | A.DECINFIX (_, _, loc) => loc
      | A.DECINFIXR (_, _, loc) => loc
      | A.DECNONFIX (_, loc) => loc
      | A.DECPOLYREC (_, loc) => loc

  fun specLoc spec =
      case spec of
        A.SPECVAL (_, loc) => loc
      | A.SPECTYPE (_, loc) => loc
      | A.SPECTYPEINC (_, loc) => loc
      | A.SPECEQTYPE (_, loc) => loc
      | A.SPECDATATYPE (_, loc) => loc
      | A.SPECDATATYPEREP (_, _, loc) => loc
      | A.SPECEXCEPTION (_, loc) => loc
      | A.SPECSTRUCTURE (_, loc) => loc
      | A.SPECINCLUDE (_, loc) => loc
      | A.SPECINCLUDE_ID (_, loc) => loc
      | A.SPECSHARINGTYPE (_, _, loc) => loc
      | A.SPECSHARING (_, _, loc) => loc
      | A.SPECSEMICOLON loc => loc

  fun sigexpLoc sigexp =
      case sigexp of
        A.SIGBASIC (_, loc) => loc
      | A.SIGID (_, loc) => loc
      | A.SIGWHERE (_, _, loc) => loc

  fun strexpLoc strexp =
      case strexp of
        A.STRBASIC (_, loc) => loc
      | A.STRID (_, loc) => loc
      | A.STRCONSTRAINT (_, _, _, loc) => loc
      | A.STRAPP (_, _, loc) => loc
      | A.STRLET (_, _, loc) => loc

  fun strdecLoc strdec =
      case strdec of
        A.STRDEC dec => decLoc dec
      | A.STRUCTURE (_, loc) => loc
      | A.STRLOCAL (_, _, loc) => loc
      | A.STRSEMICOLON loc => loc

  fun topdecLoc topdec =
      case topdec of
        A.TOPSTRDEC strdec => strdecLoc strdec
      | A.TOPSIGNATURE (_, loc) => loc
      | A.TOPFUNCTOR (_, loc) => loc
      | A.TOPEXP (_, loc) => loc

  fun topLoc top =
      case top of
        A.TOPDEC (_, loc) => loc
      | A.USE (_, loc) => loc
      | A.USE' (_, loc) => loc
      | A.TOPSEMICOLON loc => loc

end
