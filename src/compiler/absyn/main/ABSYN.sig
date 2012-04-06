(* -*- sml -*- *)
(**
 * syntax for the IML.
 * <p>
 *  Copyright (c) 2006, Tohoku University.
 * </p>
 * @author Atsushi Ohori 
 * @version $Id: ABSYN.sig,v 1.27.6.8 2010/02/10 05:17:29 hiro-en Exp $
 *)
signature ABSYN = 
sig
  type tvar
  type kindedTvar
  type longid
  type longTyCon
  type unit

  datatype constant = 
    INT of {radix: StringCvt.radix, digits: string} * Loc.loc
  | WORD of {radix: StringCvt.radix, digits: string} * Loc.loc
  | STRING of string * Loc.loc
  | REAL of string * Loc.loc
  | CHAR of char * Loc.loc
  | UNITCONST of Loc.loc
  | NULLCONST of Loc.loc

  datatype callingConvention =
      FFI_CDECL
    | FFI_STDCALL
 
  type ffiAttributes =
      {
        isPure: bool,
        noCallback: bool,
        allocMLValue: bool,
        suspendThread: bool,
        callingConvention: callingConvention option
      }

  val defaultFFIAttributes : ffiAttributes

  datatype globalSymbolKind =
           ForeignCodeSymbol
(*
         | MLCodeSymbol
         | MLDataSymbol
*)

   datatype eq = EQ | NONEQ

  datatype ty = 
     TYWILD of Loc.loc
  |  TYID of tvar * Loc.loc
  | TYRECORD of (string * ty) list * Loc.loc
  | TYCONSTRUCT of ty list * string list * Loc.loc
  | TYTUPLE of ty list * Loc.loc
  | TYFUN of ty * ty * Loc.loc
  | TYPOLY of kindedTvar list * ty * Loc.loc

  datatype tvarKind = 
    UNIV
  | REC of (string * ty) list * Loc.loc

  datatype ffiTy =
      FFIFUNTY of string list * ffiTy list * ffiTy list * Loc.loc
    | FFITUPLETY of ffiTy list * Loc.loc
    | FFITYVAR of tvar * Loc.loc
    | FFIRECORDTY of (string * ffiTy) list * Loc.loc
    | FFICONTY of ffiTy list * string list * Loc.loc

  datatype pat = 
    PATWILD of Loc.loc
  | PATCONSTANT of constant * Loc.loc
  | PATID of {id:longid, loc:Loc.loc, opPrefix:bool}
  | PATRECORD of {fields:patrow list, ifFlex:bool, loc:Loc.loc}
  | PATTUPLE of pat list * Loc.loc
  | PATLIST of pat list * Loc.loc
  | PATAPPLY of pat list * Loc.loc
  | PATTYPED of pat * ty * Loc.loc
  | PATLAYERED of pat * pat * Loc.loc

  and patrow =
      PATROWPAT of string * pat * Loc.loc
    | PATROWVAR of string * (ty option) * (pat option) * Loc.loc

  datatype exbind =
           EXBINDDEF of bool * string * ty option * Loc.loc
         | EXBINDREP of bool * string * bool * longid * Loc.loc

  type typbind = tvar list * string * ty
  type datbind = tvar list * string * (bool * string * ty option) list
  datatype exp = 
      EXPCONSTANT of constant * Loc.loc
    | EXPGLOBALSYMBOL of string * globalSymbolKind * Loc.loc
    | EXPID of  longid * Loc.loc
    | EXPOPID of  longid * Loc.loc
    | EXPRECORD of (string * exp) list * Loc.loc
    | EXPRECORD_SELECTOR of string * Loc.loc
    | EXPRECORD_UPDATE of exp * (string * exp) list * Loc.loc
    | EXPTUPLE of exp list * Loc.loc
    | EXPLIST of exp list * Loc.loc
    | EXPSEQ of exp list * Loc.loc
    | EXPAPP of exp list * Loc.loc
    | EXPTYPED of exp * ty * Loc.loc
    | EXPCONJUNCTION of exp * exp * Loc.loc
    | EXPDISJUNCTION of exp * exp * Loc.loc
    | EXPHANDLE of exp * (pat * exp) list * Loc.loc
    | EXPRAISE of exp * Loc.loc
    | EXPIF of exp * exp * exp * Loc.loc
    | EXPWHILE of exp * exp * Loc.loc
    | EXPCASE of exp * (pat * exp) list * Loc.loc
    | EXPFN of (pat * exp) list * Loc.loc
    | EXPLET of dec list * exp list * Loc.loc
    | EXPCAST of exp * Loc.loc
    | EXPFFIIMPORT of exp * ffiTy * Loc.loc
    | EXPFFIEXPORT of exp * ffiTy * Loc.loc
    | EXPFFIAPPLY of string list * exp * ffiArg list * ffiTy * Loc.loc
    | EXPSQL of (exp,pat,ty) AbsynSQL.exp * Loc.loc
  and ffiArg =
      FFIARG of exp * ffiTy * Loc.loc
    | FFIARGSIZEOF of ty * exp option * Loc.loc
  and dec =
      DECVAL of kindedTvar list * (pat * exp) list * Loc.loc
    | DECREC of kindedTvar list * (pat * exp) list * Loc.loc
    | DECFUN of kindedTvar list * (pat list * ty option * exp) list list * Loc.loc 
    | DECTYPE of typbind list * Loc.loc
    | DECDATATYPE of datbind list * typbind list * Loc.loc
    | DECREPLICATEDAT of string * longid * Loc.loc
    | DECABSTYPE of datbind list * typbind list * dec list * Loc.loc
    | DECOPEN of longid list * Loc.loc
    | DECEXN of exbind list * Loc.loc
    | DECLOCAL of dec list * dec list * Loc.loc
    | DECINFIX of string * string list * Loc.loc
    | DECINFIXR of string * string list * Loc.loc
    | DECNONFIX of string list * Loc.loc

  and strdec =
      COREDEC of dec * Loc.loc 
    | STRUCTBIND of strbind list * Loc.loc 
    | STRUCTLOCAL of strdec  list * strdec list  * Loc.loc 
  and strexp =
      STREXPBASIC of strdec list * Loc.loc 
    | STRID of longid * Loc.loc 
    | STRTRANCONSTRAINT of strexp * sigexp * Loc.loc 
    | STROPAQCONSTRAINT of strexp * sigexp * Loc.loc 
    | FUNCTORAPP of string * strexp * Loc.loc 
    | STRUCTLET  of strdec list * strexp * Loc.loc 
  and strbind = 
      STRBINDTRAN of string * sigexp  * strexp * Loc.loc 
    | STRBINDOPAQUE of string * sigexp  * strexp * Loc.loc
    | STRBINDNONOBSERV of string * strexp * Loc.loc
  and sigexp =
      SIGEXPBASIC of spec * Loc.loc 
    | SIGID of string * Loc.loc 
    | SIGWHERE of sigexp * (tvar list * longTyCon * ty) list * Loc.loc 
  and spec = 
      SPECVAL of (string * ty) list * Loc.loc 
    | SPECTYPE of (tvar list * string) list * Loc.loc 
    | SPECDERIVEDTYPE of (tvar list * string * ty) list  * Loc.loc
    | SPECEQTYPE of (tvar list * string) list * Loc.loc 
    | SPECDATATYPE of
      (tvar list * string * (string * ty option) list ) list * Loc.loc 
    | SPECREPLIC of string * longTyCon * Loc.loc 
    | SPECEXCEPTION of (string * ty option) list * Loc.loc 
    | SPECSTRUCT of (string * sigexp) list * Loc.loc 
    | SPECINCLUDE of sigexp * Loc.loc (* include *)
    | SPECDERIVEDINCLUDE of string list * Loc.loc (* include *)
    | SPECSEQ of spec * spec * Loc.loc 
    | SPECSHARE of spec * longTyCon list * Loc.loc 
    | SPECSHARESTR of spec * longid list * Loc.loc 
    | SPECEMPTY
  and funbind =
      FUNBINDTRAN of string * string * sigexp  * sigexp * strexp * Loc.loc 
    | FUNBINDOPAQUE of string * string * sigexp  * sigexp * strexp * Loc.loc 
    | FUNBINDNONOBSERV of string * string * sigexp  * strexp * Loc.loc 
    | FUNBINDSPECTRAN of string * spec  * sigexp  * strexp * Loc.loc 
    | FUNBINDSPECOPAQUE of string * spec * sigexp  * strexp * Loc.loc 
    | FUNBINDSPECNONOBSERV of string * spec * strexp * Loc.loc 
  and topdec = 
      TOPDECSTR of strdec * Loc.loc (* structure-level declaration *)
    | TOPDECSIG of ( string * sigexp ) list * Loc.loc 
    | TOPDECFUN of funbind list * Loc.loc (* functor binding*)

  datatype top =
      TOPDEC of topdec list
    | USE of string * Loc.loc

  datatype interface =
      INTERFACE of {name: string, loc: Loc.loc}
    | NOINTERFACE

  datatype unitparseresult
    = UNIT of unit
    | EOF

  val getLocTy : ty -> Loc.loc
  val getLocPat : pat -> Loc.loc
  val format_longid : longid ->SMLFormat.FormatExpression.expression list
  val isShortId : longid -> bool
  val longidToString : longid -> string
  val getLastIdOfLongid : longid -> string
  val getParentIdsOfLongid : longid -> longid
  val format_constant : constant -> SMLFormat.FormatExpression.expression list
  val format_globalSymbolKind:
      globalSymbolKind -> SMLFormat.FormatExpression.expression list
  val format_ffiAttributes :
      ffiAttributes -> SMLFormat.FormatExpression.expression list
  val format_sigexp : sigexp -> SMLFormat.FormatExpression.expression list
  val format_spec : spec -> SMLFormat.FormatExpression.expression list
  val format_dec : dec -> SMLFormat.FormatExpression.expression list
  val format_topdec : topdec -> SMLFormat.FormatExpression.expression list
  val format_exp : exp -> SMLFormat.FormatExpression.expression list
  val format_eq : eq -> SMLFormat.FormatExpression.expression list
  val format_unitparseresult
      : unitparseresult -> SMLFormat.FormatExpression.expression list
  val format_pat : pat -> SMLFormat.FormatExpression.expression list
  val format_patrow : patrow -> SMLFormat.FormatExpression.expression list
  val format_tvar : tvar -> SMLFormat.FormatExpression.expression list
  val format_tvarKind : tvarKind -> SMLFormat.FormatExpression.expression list
  val format_kindedTvar : kindedTvar -> SMLFormat.FormatExpression.expression list
  val format_ty : ty -> SMLFormat.FormatExpression.expression list
  val format_ffiTy : ffiTy -> SMLFormat.FormatExpression.expression list
  val format_typbind : typbind -> SMLFormat.FormatExpression.expression list
  val replaceLoc : exp * Loc.loc -> exp
  val format_unit : unit -> SMLFormat.FormatExpression.expression list
end
