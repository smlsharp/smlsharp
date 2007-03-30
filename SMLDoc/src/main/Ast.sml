(**
 * abstract syntax tree.
 * @author YAMATODANI Kiyoshi
 * @author AT&T Bell Laboratories 
 * @copyright 1992 by AT&T Bell Laboratories 
 * @copyright 2004 JAIST
 * @version $Id: Ast.sml,v 1.7 2006/05/23 05:23:59 kiyoshiy Exp $
 *)
structure Ast : AST =
struct

  (***************************************************************************)

  datatype fixity = INfix of int | INfixR of int | NONfix

  (* to mark positions in files *)
  type srcpos = int  (* character position from beginning of stream (base 0) *)
  type region = srcpos * srcpos   (* start and end position of region *)

  (* symbolic path (Modules.spath) *)
  type path = string list

  type tyvar = string

  datatype 'a sigConst
    = NoSig
    | Transparent of 'a
    | Opaque of 'a

  (* EXPRESSIONS *)
  type exp = unit

  (* RULE for case functions and exception handler *)
  datatype rule = Rule of {pat:pat,exp:exp}

  (* PATTERN *)
  and pat = WildPat				(* empty pattern *)
	  | VarPat of path			(* variable pattern *)
	  | IntPat of int			(* integer *)
	  | WordPat of int			(* word int *)
	  | StringPat of string			(* string *)
	  | CharPat of string			(* char *)
	  | RecordPat of {def:(string * pat) list, flexibility:bool}
						(* record *)
          | ListPat of pat list		       (*  [list,in,square,brackets] *)
	  | TuplePat of pat list		(* tuple *)
          | FlatAppPat of pat list
                                        (* patterns prior to fixity parsing *)
	  | ConstraintPat of {pattern:pat,constraint:ty}
						  (* constraint *)
	  | LayeredPat of {varPat:pat,expPat:pat}	(* as expressions *)
          | VectorPat of pat list                 (* vector pattern *)
	  | MarkPat of pat * region	(* mark a pattern *)
	  | OrPat of pat list			(* or-pattern *)

  (* STRUCTURE EXPRESSION *) 
  and strexp =
      (* variable structure *)
      VarStr of path
    | (* defined structure *)
      BaseStr of (srcpos * dec)
    | (* signature constrained *)
      ConstrainedStr of strexp * sigexp sigConst
    | (* application (external) *)
      AppStr of path * (strexp * bool) list
    | (* let in structure *)
      LetStr of srcpos * dec * strexp
    | (* mark *)
      MarkStr of strexp * region

  (* FUNCTOR EXPRESSION *)
  and fctexp =
      (* functor variable *)
      VarFct of path * fsigexp sigConst	
    | (* definition of a functor *)
      BaseFct of
      {
        params : (string option * sigexp) list,
	body : strexp,
	constraint : sigexp sigConst
      }
    | LetFct of srcpos * dec * fctexp
    | (* application *)
      AppFct of path * (strexp * bool) list * fsigexp sigConst
    | (* mark *)
      MarkFct of fctexp * region 

  (* WHERE SPEC *)
  and wherespec =
      WhType of string list * tyvar list * srcpos * ty
    | WhStruct of string list * string list

  (* SIGNATURE EXPRESSION *)
  and sigexp =
      (* signature variable *)
      VarSig of string
    | (* sig augmented with where spec *)
      AugSig of sigexp * wherespec list
    | (* defined signature *)
      BaseSig of (srcpos * (spec * srcpos) list)
    | (* mark *)
      MarkSig of sigexp * region

  (* FUNCTOR SIGNATURE EXPRESSION *)
  and fsigexp =
      (* funsig variable *)
      VarFsig of string
    | (* defined funsig *)
      BaseFsig of {params: (string option * sigexp) list, result:sigexp}
    | (* mark a funsig *)
      MarkFsig of fsigexp * region

  (* SPECIFICATION FOR SIGNATURE DEFINITIONS *)
  and spec =
      (* structure *)
      StrSpec of (((string * sigexp * path option) * region) * srcpos) list
    | (* type *)
      TycSpec of
      (
        (((string * tyvar list * srcpos * ty option) * region) * srcpos) list *
        bool
      )
    | (* functor *)
      FctSpec of (((string * fsigexp) * region) * srcpos) list 
    | (* value *)
      ValSpec of (((string * srcpos * ty) * region) * srcpos) list 
    | (* datatype *)
      DataSpec of
      {
        datatycs: (db * srcpos) list,
        withtycsBeginPos : srcpos,
        withtycs: (tb * srcpos) list
      }
    | (* exception *)
      ExceSpec of (((string * srcpos * ty option) * region) * srcpos) list 
    | (* structure sharing *)
      ShareStrSpec of path list 
    | (* type sharing *)
      ShareTycSpec of path list 
    | (* include specif *)
      IncludeSpec of sigexp 

  (* DECLARATIONS (let and structure) *)
  and dec =
      ValDec of ((vb * srcpos) list * tyvar list)	(* values *)
    | ValrecDec of ((rvb * srcpos) list * tyvar list)(* recursive values *)
    | FunDec of ((fb * srcpos) list * tyvar list)	(* recurs functions *)
    | TypeDec of (tb * srcpos) list			(* type dec *)
    | (* datatype dec *)
      DatatypeDec of
      {
        datatycs: (db * srcpos) list,
        withtycsBeginPos : srcpos,
        withtycs: (tb * srcpos) list
      }
    | (* abstract type *)
      AbstypeDec of
      {
        abstycs: (db * srcpos) list,
        withtycsBeginPos : srcpos,
        withtycs: (tb * srcpos) list,
        bodyBeginPos : srcpos,
        body: dec
      }
    | ExceptionDec of (eb * srcpos) list		(* exception *)
    | StrDec of (strb * srcpos) list			(* structure *)
    | AbsDec of (strb * srcpos) list			(* abstract struct *)
    | FctDec of (fctb * srcpos) list			(* functor *)
    | SigDec of (sigb * srcpos) list			(* signature *)
    | FsigDec of (fsigb * srcpos) list			(* funsig *)
    | LocalDec of srcpos * dec * srcpos * dec	(* local dec *)
    | SeqDec of (dec * srcpos) list		(* sequence of dec *)
    | OpenDec of path list			(* open structures *)
    | OvldDec of string * ty * exp list	(* overloading (internal) *)
    | FixDec of {fixity: fixity, ops: string list}  (* fixity *)
    | UseDec of string
    | MarkDec of dec * region		(* mark a dec *)

  (* VALUE BINDINGS *)
  and vb =
      Vb of {pat:pat, exp:exp, lazyp:bool} * region

  (* RECURSIVE VALUE BINDINGS *)
  and rvb =
      Rvb of ({var:string, exp:exp, resultty: ty option, lazyp: bool} * region)

  (* RECURSIVE FUNCTIONS BINDINGS *)
  and fb =
      Fb of (clause list * bool)
    | MarkFb of fb * region

  (* CLAUSE: a definition for a single pattern in a function binding *)
  and clause =
      Clause of ({pats: pat list, resultty: ty option, exp:exp} * region)

  (* TYPE BINDING *)
  and tb =
      Tb of
      (
        {tyc : string, defBeginPos : srcpos, def : ty, tyvars : tyvar list} *
        region
      )

  (* DATATYPE BINDING *)
  and db =
      Db of
      (
        {
          tyc : string,
          tyvars : tyvar list,
          rhsBeginPos : srcpos,
          rhs : dbrhs,
          lazyp: bool
        } *
        region
       )

  (* DATATYPE BINDING RIGHT HAND SIDE *)
  and dbrhs =
      Constrs of (((string * srcpos * ty option) * region) * srcpos) list
    | Repl of string list

  (* EXCEPTION BINDING *)
  and eb =
      (* Exception definition *)
      EbGen of
      ({exn: string, etypeBeginPos : srcpos, etype: ty option} * region) 
    | EbDef of ({exn: string, edef: path} * region)  (* defined by equality *)

  (* STRUCTURE BINDING *)
  and strb =
      Strb of
      ({name: string, def: strexp,constraint: sigexp sigConst} * region)

  (* FUNCTOR BINDING *)
  and fctb =
      Fctb of ({name: string, def: fctexp} * region)

  (* SIGNATURE BINDING *)
  and sigb =
      Sigb of ({name: string,def: sigexp} * region)

  (* FUNSIG BINDING *)
  and fsigb =
      Fsigb of ({name: string,def: fsigexp} * region)

  (* TYPES *)
  and ty 
      = VarTy of tyvar (* type variable *)
      | (* type constructor *)
        ConTy of (string list * srcpos * (ty * srcpos) list)
      | RecordTy of srcpos * (tyrow * srcpos) list (* record *)
      | TupleTy of (ty * srcpos) list (* tuple *)
      | EnclosedTy of srcpos * ty (* enclosed by parenthesis *)
      | MarkTy of ty * region

  and tyrow
    = TyRow of (string * srcpos * ty) * region

  (***************************************************************************)
 
end (* structure Ast *)

