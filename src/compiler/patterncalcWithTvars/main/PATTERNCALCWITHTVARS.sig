(**
 * A calculus with explicitly scoped user type variables.
 *
 * @copyright (c) 2006, Tohoku University.
 * @author Atsushi Ohori 
 * @author Liu Bochao
 * @version $Id: PATTERNCALCWITHTVARS.sig,v 1.13 2007/02/28 17:57:20 katsu Exp $
 *)
signature PATTERNCALCWITHTVARS = sig

 type loc
 type ty
 type tvarNameSet
 type caseKind
 datatype constant = datatype Absyn.constant
 type callingConvention = Absyn.callingConvention
 type longid
 type tvar

 datatype ptexbind =
          PTEXBINDDEF of bool * string * ty option * loc
        | PTEXBINDREP of bool * string * bool * longid * loc
 datatype ptexp = 
     PTCONSTANT of constant * loc
   | PTVAR of longid * loc
   | PTTYPED of ptexp * ty * loc
   | PTAPPM of ptexp * ptexp list * loc
   | PTLET of ptdecl list * ptexp list * loc
   | PTRECORD of (string * ptexp) list * loc
   | PTRECORD_UPDATE of ptexp * (string * ptexp) list * loc
   | PTTUPLE of ptexp list * loc
   | PTRAISE of ptexp * loc
   | PTHANDLE of ptexp * (ptpat * ptexp) list * loc
   | PTFNM of tvarNameSet * (ptpat list * ptexp) list * loc
   | PTFNM1 of tvarNameSet * (string * ty list option) list * ptexp * loc 
   | PTCASEM of ptexp list *  (ptpat list * ptexp) list * caseKind * loc
   | PTRECORD_SELECTOR of string * loc
   | PTSELECT of string * ptexp * loc
   | PTSEQ of ptexp list * loc
   | PTCAST of ptexp * loc
   | PTFFIIMPORT of ptexp * ty * loc
   | PTFFIEXPORT of ptexp * ty * loc
   | PTFFIAPPLY of callingConvention * ptexp * ffiArg list * ty * loc
 and ffiArg =
     PTFFIARG of ptexp * ty
   | PTFFIARGSIZEOF of ty * ptexp option
 and ptdecl = 
     PTVAL of tvarNameSet * tvarNameSet * (ptpat * ptexp ) list * loc 
   | PTDECFUN of tvarNameSet * tvarNameSet * (ptpat * (ptpat list * ptexp) list) list * loc 
   | PTNONRECFUN of tvarNameSet * tvarNameSet * (ptpat * (ptpat list * ptexp) list) * loc 
   | PTVALREC of tvarNameSet * tvarNameSet * (ptpat * ptexp ) list * loc
   | PTVALRECGROUP of string list * ptdecl list * loc
   | PTTYPE of (tvar list * string * ty) list * loc
   | PTDATATYPE of
     (tvar list * string * (bool * string * ty option) list) list * loc
   | PTREPLICATEDAT of string * longid * loc
   | PTABSTYPE of
       (tvar list * string * (bool * string * ty option) list) list 
       * ptdecl list
       * loc
   | PTEXD of ptexbind list * loc
   | PTLOCALDEC of ptdecl list * ptdecl list * loc
   | PTOPEN of longid list * loc
   | PTINFIXDEC of int * string list * loc
   | PTINFIXRDEC of int * string list * loc
   | PTNONFIXDEC of string list * loc
   | PTEMPTY 

 and ptpat = 
     PTPATWILD of loc
   | PTPATID of longid * loc
   | PTPATCONSTANT of constant * loc
   | PTPATCONSTRUCT of ptpat * ptpat * loc
   | PTPATRECORD of bool * (string * ptpat) list * loc
   | PTPATLAYERED of string * ty option * ptpat * loc
   | PTPATTYPED of ptpat * ty * loc
   | PTPATORPAT of ptpat * ptpat * loc

 and ptstrdec =
     PTCOREDEC of ptdecl * loc
   | PTSTRUCTBIND of (string * ptstrexp) list * loc
   | PTSTRUCTLOCAL of ptstrdec list * ptstrdec list * loc

 and ptstrexp =
     PTSTREXPBASIC of ptstrdec list * loc 
   | PTSTRID of longid* loc 
   | PTSTRTRANCONSTRAINT of ptstrexp * ptsigexp * loc 
   | PTSTROPAQCONSTRAINT of ptstrexp * ptsigexp * loc 
   | PTFUNCTORAPP of string * ptstrexp * loc 
   | PTSTRUCTLET  of ptstrdec list * ptstrexp * loc 

 and ptsigexp = 
     PTSIGEXPBASIC of ptspec * loc 
   | PTSIGID of string * loc 
   | PTSIGWHERE of ptsigexp * (tvar list * longid * ty) list * loc 

 and ptspec =
     PTSPECVAL of (string * ty) list * loc 
   | PTSPECTYPE of (tvar list * string * Absyn.specKind) list * loc 
   | PTSPECTYPEEQUATION of (tvar list * string * ty) * loc
   | PTSPECEQTYPE of (tvar list * string * Absyn.specKind) list * loc 
   | PTSPECDATATYPE of
     (tvar list * string * (string * ty option) list ) list * loc 
   | PTSPECREPLIC of string * longid * loc 
   | PTSPECEXCEPTION of (string * ty option) list * loc 
   | PTSPECSTRUCT of (string * ptsigexp) list * loc 
   | PTSPECINCLUDE of ptsigexp * loc 
   | PTSPECSEQ of ptspec * ptspec * loc 
   | PTSPECSHARE of ptspec * longid list * loc 
   | PTSPECSHARESTR of ptspec * longid list * loc 
   | PTSPECEMPTY

 and pttopdec = 
     PTTOPDECSTR of ptstrdec * loc 
   | PTTOPDECSIG of  ( string * ptsigexp ) list * loc 
   | PTTOPDECFUN of  ( string * string * ptsigexp  * ptstrexp * loc ) list * loc 
   | PTTOPDECIMPORT of ptspec * loc 
   | PTTOPDECEXPORT of ptspec * loc 

  val getLocExp : ptexp -> loc
  val getLocPat : ptpat -> loc
  val getLocDec : ptdecl -> loc
  val getLocTopDec : pttopdec -> loc

  val emptyTvarNameSet : tvarNameSet
  val format_caseKind : caseKind -> SMLFormat.FormatExpression.expression list
  val format_ptdecl : ptdecl -> SMLFormat.FormatExpression.expression list
  val format_ptexp : ptexp -> SMLFormat.FormatExpression.expression list
  val format_ptpat : ptpat -> SMLFormat.FormatExpression.expression list
(*
  val format_smap : (Sord.ord_key * 'a) SMLFormat.BasicFormatters.formatter
                    * SMLFormat.FormatExpression.expression list
                    * SMLFormat.FormatExpression.expression list
                    * SMLFormat.FormatExpression.expression list
                    -> 'a SEnv.map -> SMLFormat.FormatExpression.expression list
*)
  val format_tvar : tvar -> SMLFormat.FormatExpression.expression list
  val format_tvarNameSet
      : bool SEnv.map -> SMLFormat.FormatExpression.expression list
  val format_ty : ty -> SMLFormat.FormatExpression.expression list
  val format_ptstrdec : ptstrdec -> SMLFormat.FormatExpression.expression list
  val format_ptstrexp : ptstrexp -> SMLFormat.FormatExpression.expression list
  val format_ptsigexp : ptsigexp ->  SMLFormat.FormatExpression.expression list
  val format_ptspec : ptspec -> SMLFormat.FormatExpression.expression list
  val format_pttopdec : pttopdec -> SMLFormat.FormatExpression.expression list

end
