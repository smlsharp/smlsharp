(**
 * A calculus with explicitly scoped user type variables.
 *
 * @copyright (c) 2006, Tohoku University.
 * @author Atsushi Ohori 
 * @author Liu Bochao
 * @version $Id: PATTERNCALCWITHTVARS.sig,v 1.24.6.8 2010/02/10 05:17:29 hiro-en Exp $
 *)
signature PATTERNCALCWITHTVARS = 
  sig
    type kindedTvarSet 
    type tvarNameSet
    datatype ptexp
      = PTAPPM of ptexp * ptexp list * Loc.loc
      | PTCASEM of ptexp list * (ptpat list * ptexp) list * 
                   PatternCalc.caseKind * Loc.loc
      | PTCAST of ptexp * Loc.loc
      | PTCONSTANT of Absyn.constant * Loc.loc
      | PTGLOBALSYMBOL of string * Absyn.globalSymbolKind * Loc.loc
      | PTFFIAPPLY of Absyn.ffiAttributes * ptexp * ffiArg list * 
                      PatternCalcFlattened.ty * Loc.loc
      | PTFFIEXPORT of ptexp * PatternCalcFlattened.ty * Loc.loc
      | PTFFIIMPORT of ptexp * PatternCalcFlattened.ty * Loc.loc
      | PTFNM of tvarNameSet * (ptpat list * ptexp) list * Loc.loc
      | PTFNM1 of tvarNameSet * 
                  (string * PatternCalcFlattened.ty list option) list * ptexp
                  * Loc.loc
      | PTHANDLE of ptexp * (ptpat * ptexp) list * Loc.loc
      | PTLET of ptdecl list * ptexp list * Loc.loc
      | PTLIST of ptexp list * Loc.loc
      | PTRAISE of ptexp * Loc.loc
      | PTRECORD of (string * ptexp) list * Loc.loc
      | PTRECORD_SELECTOR of string * Loc.loc
      | PTRECORD_UPDATE of ptexp * (string * ptexp) list * Loc.loc
      | PTSELECT of string * ptexp * Loc.loc
      | PTSEQ of ptexp list * Loc.loc
      | PTTUPLE of ptexp list * Loc.loc
      | PTTYPED of ptexp * PatternCalcFlattened.ty * Loc.loc
      | PTVAR of NameMap.namePath * Loc.loc
      | PTSQLSERVER of (string * ptexp) list * ty * Loc.loc
      | PTSQLTABLE of string * Loc.loc
      | PTSQLQUERY of ptexp * Loc.loc
      | PTSQLSELECT of (string * ptexp) list * (string * ptexp) list
                       * ptexp option
                       * ptexp list option * ptexp list
                       * (ptexp option * ptexp option)
                       * string list option * string list option
                       * Loc.loc
      | PTSQLCOLUMN of string * string * Loc.loc
      | PTSQLAPPM of string * string * ptexp list * loc
      | PTSQLCOERCE of ptexp * loc
      | PTSQLTYPED of ptexp * PatternCalcFlattened.ty * Loc.loc
      | PTSQLINSERT of (string * ptexp) list * (string * PatternCalcFlattened.ty)
                       * (string * ptexp) list * Loc.loc
      | PTSQLDELETE of (string * ptexp) * (string * ptexp) list * ptexp option
                       * (string * ptexp) lsit * Loc.loc
      | PTSQLUPDATE of (string * ptexp * PatternCalcFlattened.ty)
                       * (string * ptexp) list * (string * ptexp) list
                       * ptexp option * (string * ptexp) list * Loc.loc
      | PTSQLCREATETABLE of string * (string * ty) list * ptexp
                            * (string * ty) list * Loc.loc
      | PTSQLCREATETBLAS of string * ptexp * ptexp
                            * (string * ty) list * Loc.loc

    datatype ffiArg
      = PTFFIARG of ptexp * PatternCalcFlattened.ty * Loc.loc
      | PTFFIARGSIZEOF of PatternCalcFlattened.ty * ptexp option * Loc.loc
    datatype ptdecl
      = PTABSTYPE of Path.path * 
                     (Absyn.tvar list * NameMap.namePath * 
                      (bool * string * PatternCalcFlattened.ty option) list) 
                       list * ptdecl list * Loc.loc
      | PTDATATYPE of Path.path * 
                      (Absyn.tvar list * NameMap.namePath * 
                       (bool * string * PatternCalcFlattened.ty option) list) 
                        list * Loc.loc
      | PTDECFUN of kindedTvarSet * tvarNameSet * 
                    (ptpat * (ptpat list * ptexp) list) list * Loc.loc
      | PTEMPTY
      | PTEXD of ptexbind list * Loc.loc
      | PTINFIXDEC of int * string list * Loc.loc
      | PTINFIXRDEC of int * string list * Loc.loc
      | PTINTRO of NameMap.basicNameNPEnv * 
                   {current:Path.path, original:Path.path} * Loc.loc
      | PTLOCALDEC of ptdecl list * ptdecl list * Loc.loc
      | PTNONFIXDEC of string list * Loc.loc
      | PTNONRECFUN of kindedTvarSet * tvarNameSet * 
                       (ptpat * (ptpat list * ptexp) list) * Loc.loc
      | PTREPLICATEDAT of NameMap.namePath * NameMap.namePath * Loc.loc
      | PTTYPE of (Absyn.tvar list * NameMap.namePath * 
                   PatternCalcFlattened.ty) list * Loc.loc
      | PTVAL of kindedTvarSet * tvarNameSet * (ptpat * ptexp) list * Loc.loc
      | PTVALREC of kindedTvarSet * tvarNameSet * (ptpat * ptexp) list * 
                    Loc.loc
      | PTVALRECGROUP of string list * ptdecl list * Loc.loc
    datatype ptstrdecl
      = PTANDFLATTENED of (PatternCalcFlattened.printSigInfo * ptstrdecl list) 
                            list * Loc.loc
      | PTCOREDEC of ptdecl list * Loc.loc
      | PTFUNCTORAPP of Path.path * string * 
                        (Path.path * NameMap.basicNameNPEnv) * Loc.loc
      | PTOPAQCONSTRAINT of ptstrdecl list * NameMap.basicNameNPEnv * ptspec
                            * NameMap.basicNameNPEnv * Loc.loc
      | PTSTRLOCAL of ptstrdecl list * ptstrdecl list * Loc.loc
      | PTTRANCONSTRAINT of ptstrdecl list * NameMap.basicNameNPEnv * ptspec
                            * NameMap.basicNameNPEnv * Loc.loc
    datatype ptpat
      = PTPATCONSTANT of Absyn.constant * Loc.loc
      | PTPATCONSTRUCT of ptpat * ptpat * Loc.loc
      | PTPATID of NameMap.namePath * Loc.loc
      | PTPATLAYERED of string * PatternCalcFlattened.ty option * ptpat * 
                        Loc.loc
      | PTPATORPAT of ptpat * ptpat * Loc.loc
      | PTPATRECORD of bool * (string * ptpat) list * Loc.loc
      | PTPATTYPED of ptpat * PatternCalcFlattened.ty * Loc.loc
      | PTPATWILD of Loc.loc
    datatype ptexbind
      = PTEXBINDDEF of bool * NameMap.namePath * 
                       PatternCalcFlattened.ty option * Loc.loc
      | PTEXBINDREP of bool * NameMap.namePath * bool * NameMap.namePath * 
                       Loc.loc
    datatype ptspec
      = PTSPECDATATYPE of Path.path * 
                          (Absyn.tvar list * NameMap.namePath * 
                           (string * PatternCalcFlattened.ty option) list) 
                            list * Loc.loc
      | PTSPECEMPTY
      | PTSPECEQTYPE of (Absyn.tvar list * NameMap.namePath) list * Loc.loc
      | PTSPECEXCEPTION of (NameMap.namePath * PatternCalcFlattened.ty option) 
                             list * Loc.loc
      | PTSPECPREFIXEDSIGID of NameMap.namePath * Loc.loc
      | PTSPECREPLIC of NameMap.namePath * NameMap.namePath * Loc.loc
      | PTSPECSEQ of ptspec * ptspec * Loc.loc
      | PTSPECSHARE of ptspec * NameMap.namePath list * Loc.loc
      | PTSPECSIGWHERE of ptspec * 
                          (Absyn.tvar list * NameMap.namePath * 
                           PatternCalcFlattened.ty) list * Loc.loc
      | PTSPECTYPE of (Absyn.tvar list * NameMap.namePath) list * Loc.loc
      | PTSPECTYPEEQUATION of (Absyn.tvar list * NameMap.namePath * 
                               PatternCalcFlattened.ty) * Loc.loc
      | PTSPECVAL of (NameMap.namePath * PatternCalcFlattened.ty) list * 
                     Loc.loc
    datatype pttopdec
      = PTDECFUNCTOR of (string * 
                         (ptspec * string * NameMap.basicNameNPEnv * 
                          PatternCalc.plsigexp) * 
                         (ptstrdecl list * NameMap.basicNameMap * 
                          PatternCalc.plsigexp option) * Loc.loc) list * 
                        Loc.loc
      | PTDECSIG of (string * (ptspec * PatternCalc.plsigexp)) list * Loc.loc
      | PTDECSTR of ptstrdecl list * Loc.loc

    val format_ptexp : ptexp -> SMLFormat.FormatExpressionTypes.expression list
    val format_pttopdec : pttopdec
                          -> SMLFormat.SMLFormat.FormatExpression.expression list
    val format_ptinterface : ptinterface -> SMLFormat.FormatExpressionTypes.expression list
    val getLocExp : ptexp -> Loc.loc
    val getLocDec : ptdecl -> Loc.loc
    val getLocPat : ptpat -> Loc.loc
    val getLocTopDec : pttopdec -> Loc.loc
    val getLocTopDecs : pttopdec list -> Loc.loc
    val emptyTvarNameSet : tvarNameSet
  end
