(**
 * The flattened pattern calculus for the core.
 *
 * @copyright (c) 2006, Tohoku University.
 * @author Liu Bochao
 * @version $Id: PATTERNCALCFLATTENED.sig,v 1.11 2008/08/24 03:54:41 ohori Exp $
 *)
signature PATTERNCALCFLATTENED = sig

 type printSigInfo 
 type kindedTvar

 datatype ty =
      TYID of Absyn.tvar * Loc.loc
    | TYRECORD of (string * ty) list * Loc.loc
    | TYCONSTRUCT of ty list * NameMap.namePath * Loc.loc
    | TYTUPLE of ty list * Loc.loc
    | TYFUN of ty * ty * Loc.loc
    | TYFFI of Absyn.callingConvention * ty list * ty * Loc.loc
    | TYPOLY of kindedTvar list * ty * Loc.loc

  datatype tvarKind = 
    UNIV
  | REC of (string * ty) list

 datatype plfexbind =
          PLFEXBINDDEF of bool * NameMap.namePath * ty option * Loc.loc
        | PLFEXBINDREP of bool * NameMap.namePath * bool * NameMap.namePath * Loc.loc

 datatype plfexp = 
     PLFCONSTANT of Absyn.constant * Loc.loc
   | PLFVAR of NameMap.namePath * Loc.loc
   | PLFTYPED of plfexp *  ty * Loc.loc
   | PLFAPPM of plfexp * plfexp list * Loc.loc
   | PLFLET of pdfdecl list * plfexp list * Loc.loc
   | PLFRECORD of (string * plfexp) list * Loc.loc
   | PLFRECORD_UPDATE of plfexp * (string * plfexp) list * Loc.loc
   | PLFTUPLE of plfexp list * Loc.loc
   | PLFLIST of plfexp list * Loc.loc
   | PLFRAISE of plfexp * Loc.loc
   | PLFHANDLE of plfexp * (plfpat * plfexp) list * Loc.loc
   | PLFFNM of (plfpat list * plfexp) list * Loc.loc
   | PLFCASEM of plfexp list *  (plfpat list * plfexp) list * PatternCalc.caseKind * Loc.loc
   | PLFRECORD_SELECTOR of string * Loc.loc
   | PLFSELECT of string * plfexp * Loc.loc
   | PLFSEQ of plfexp list * Loc.loc
   | PLFCAST of plfexp * Loc.loc
   | PLFFFIIMPORT of plfexp * ty * Loc.loc
   | PLFFFIEXPORT of plfexp * ty * Loc.loc
   | PLFFFIAPPLY of Absyn.callingConvention * plfexp * ffiArg list * ty * Loc.loc

 and ffiArg =
     PLFFFIARG of plfexp * ty * Loc.loc
   | PLFFFIARGSIZEOF of ty * plfexp option * Loc.loc

 and pdfdecl = 
     PDFVAL of kindedTvar list * (plfpat * plfexp ) list * Loc.loc 
   | PDFDECFUN of kindedTvar list * (plfpat * (plfpat list * plfexp) list) list * Loc.loc 
   | PDFNONRECFUN of kindedTvar list * (plfpat * (plfpat list * plfexp) list) * Loc.loc 
   | PDFVALREC of kindedTvar list * (plfpat * plfexp ) list * Loc.loc
   | (** used only for PrinterGeneration to keep the original order of bindings. *)
     PDFVALRECGROUP of string list * pdfdecl list * Loc.loc
   | PDFTYPE of (Absyn.tvar list * NameMap.namePath * ty) list * Loc.loc
   | PDFDATATYPE of
     Path.path * (Absyn.tvar list * NameMap.namePath * (bool * string * ty option) list) list * Loc.loc
   | PDFREPLICATEDAT of NameMap.namePath * NameMap.namePath * Loc.loc
   | PDFABSTYPE of Path.path * (Absyn.tvar list * NameMap.namePath * (bool * string * ty option) list) list * pdfdecl list * Loc.loc
   | PDFEXD of plfexbind list * Loc.loc
   | PDFLOCALDEC of pdfdecl list * pdfdecl list * Loc.loc
   | PDFINTRO of NameMap.basicNameNPEnv * {original : Path.path, current : Path.path} * Loc.loc
   | PDFINFIXDEC of int * string list * Loc.loc
   | PDFINFIXRDEC of int * string list * Loc.loc
   | PDFNONFIXDEC of string list * Loc.loc
   | PDFEMPTY 

 and pdfStrDecl =
     PDFCOREDEC of pdfdecl list * Loc.loc
   | PDFTRANCONSTRAINT of pdfStrDecl list * 
                          NameMap.basicNameNPEnv *
                          plfspec * 
                          NameMap.basicNameNPEnv *
                          Loc.loc
   | PDFOPAQCONSTRAINT of pdfStrDecl list * 
                          NameMap.basicNameNPEnv *
                          plfspec * 
                          NameMap.basicNameNPEnv *
                          Loc.loc
   | PDFFUNCTORAPP of Path.path * string * (Path.path * NameMap.basicNameNPEnv) * Loc.loc
   | PDFANDFLATTENED of (printSigInfo * pdfStrDecl list) list * Loc.loc 
   | PDFSTRLOCAL of pdfStrDecl list * pdfStrDecl list * Loc.loc
     
 and plfpat =
     PLFPATWILD of Loc.loc
   | PLFPATID of NameMap.namePath * Loc.loc
   | PLFPATCONSTANT of Absyn.constant * Loc.loc
   | PLFPATCONSTRUCT of plfpat * plfpat * Loc.loc
   | PLFPATRECORD of bool * (string * plfpat) list * Loc.loc
   | PLFPATLAYERED of string * ty option * plfpat * Loc.loc
   | PLFPATTYPED of plfpat * ty * Loc.loc
   | PLFPATORPAT of plfpat * plfpat * Loc.loc


 and plfspec =
     PLFSPECVAL of (NameMap.namePath * ty) list * Loc.loc 
   | PLFSPECTYPE of (Absyn.tvar list * NameMap.namePath) list * Loc.loc 
   | PLFSPECTYPEEQUATION of (Absyn.tvar list * NameMap.namePath * ty) * Loc.loc
   | PLFSPECEQTYPE of (Absyn.tvar list * NameMap.namePath) list * Loc.loc
   | PLFSPECDATATYPE of Path.path * (Absyn.tvar list * NameMap.namePath * (string * ty option) list) list * Loc.loc
   | PLFSPECREPLIC of NameMap.namePath * NameMap.namePath * Loc.loc 
   | PLFSPECEXCEPTION of (NameMap.namePath * ty option) list * Loc.loc
   | PLFSPECSEQ of plfspec * plfspec * Loc.loc 
   | PLFSPECSHARE of plfspec * NameMap.namePath list * Loc.loc 
   | PLFSPECEMPTY
   | PLFSPECPREFIXEDSIGID of NameMap.namePath * Loc.loc
   | PLFSPECSIGWHERE of plfspec * (Absyn.tvar list * NameMap.namePath * ty) list * Loc.loc
(*
   | PLFSPECFUNCTOR of (string * 
                        (plfspec * NameMap.basicNameNPEnv) * 
                        (plfspec * NameMap.basicNameNPEnv)) list * 
                       Loc.loc 
*)
 
and plftopdec = 
     PLFDECSTR of pdfStrDecl list * Loc.loc
   | PLFDECSIG of (string * (plfspec * PatternCalc.plsigexp)) list * Loc.loc 
   | PLFDECFUN of  (string *
                   (plfspec * string * NameMap.basicNameNPEnv * PatternCalc.plsigexp) * 
                   (pdfStrDecl list * NameMap.basicNameMap * PatternCalc.plsigexp option) *
                   Loc.loc) list *
                  Loc.loc 

  val getLeftPosExp :  plfexp  -> Loc.pos
  val getRightPosExp :  plfexp  -> Loc.pos 
  val getRightPosPat : plfpat -> Loc.pos
  val getLeftPosPat : plfpat -> Loc.pos
  val getLocExp : plfexp -> Loc.loc
  val getLocPat : plfpat -> Loc.loc
  val getLocDec : pdfdecl -> Loc.loc
  val getLocTy : ty -> Loc.loc

  val format_ty : ty -> SMLFormat.FormatExpression.expression list
  val format_kindedTvar : kindedTvar -> SMLFormat.FormatExpression.expression list
  val format_pdfdecl 
      : (plfexp -> SMLFormat.FormatExpression.expression list) list
        * (plfpat -> SMLFormat.FormatExpression.expression list) list
         -> pdfdecl SMLFormat.BasicFormatters.formatter
  val format_plfexp 
      : (plfexp -> SMLFormat.FormatExpression.expression list) list
        * (plfpat -> SMLFormat.FormatExpression.expression list) list
            -> plfexp -> SMLFormat.FormatExpression.expression list
  val format_plfpat 
     : (plfexp -> SMLFormat.FormatExpression.expression list) list
       * (plfpat -> SMLFormat.FormatExpression.expression list) list
          -> plfpat -> SMLFormat.FormatExpression.expression list
  val format_plftopdec
      : (plfexp -> SMLFormat.FormatExpression.expression list) list
        * (plfpat -> SMLFormat.FormatExpression.expression list) list
        -> plftopdec SMLFormat.BasicFormatters.formatter

  val format_plfspec
      :   (plfexp -> SMLFormat.FormatExpression.expression list) list
        * (plfpat -> SMLFormat.FormatExpression.expression list) list
        -> plfspec SMLFormat.BasicFormatters.formatter

end
