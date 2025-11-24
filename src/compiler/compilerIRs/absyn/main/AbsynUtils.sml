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

  fun ffiTyLoc ty =
      case ty of
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
      | A.PATAPP (_, _, loc) => loc
      | A.PATINFIX (_, _, _, loc) => loc
      | A.PATTYPED (_, _, loc) => loc
      | A.PATAS (_, _, _, loc) => loc

  fun sqlExpLoc exp =
      case exp of
        S.EXP_EMBED (_, loc) => loc
      | S.CONST (_, loc) => loc
      | S.NULL loc => loc
      | S.TRUE loc => loc
      | S.FALSE loc => loc
      | S.COLUMN1 (_, loc) => loc
      | S.COLUMN2 (_, _, loc) => loc
      | S.KWEXP (_, _, loc) => loc
      | S.EXP_SUBQUERY (_, _, loc) => loc
      | S.OP1 (_, _, loc) => loc
      | S.OP2 (_, _, _, loc) => loc
      | S.ID (_, _, loc) => loc
      | S.PAREN (_, loc) => loc
      | S.APP (_, _, loc) => loc
      | S.INFIX (_, _, _, loc) => loc
      | S.CAST (_, _, loc) => loc
      | S.TUPLE (_, loc) => loc

  fun sqlTopLoc top =
      case top of
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
      | A.EXPAPP (_, _, loc) => loc
      | A.EXPINFIX (_, _, _, loc) => loc
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
      | A.EXPSQL sqlexp => sqlTopLoc sqlexp
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

  fun decLoc dec =
      case dec of
        A.DECVAL (_, _, loc) => loc
      | A.DECVALREC (_, _, loc) => loc
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

  fun strexpLoc strexp =
      case strexp of
        A.STRBASIC (_, loc) => loc
      | A.STRID (_, _, loc) => loc
      | A.STRCONSTRAINT (_, _, loc) => loc
      | A.STRAPP (_, _, loc) => loc
      | A.STRLET (_, _, loc) => loc

  fun strdecLoc strdec =
      case strdec of
        A.STRDEC dec => decLoc dec
      | A.STRUCTURE (_, loc) => loc
      | A.STRLOCAL (_, _, loc) => loc
      | A.STRSEMICOLON loc => loc

end
