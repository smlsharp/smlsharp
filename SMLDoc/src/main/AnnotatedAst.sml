(**
 * abstract syntax tree annotated with doc comment.
 * @author YAMATODANI Kiyoshi
 * @copyright 2010, Tohoku University.
 * @version $Id: AnnotatedAst.sml,v 1.5 2006/05/23 05:23:59 kiyoshiy Exp $
 *)
structure AnnotatedAst =
struct

  (***************************************************************************)

  type loc = {fileName : string, line : int, column : int}

  (** symbolic path (Modules.spath) *)
  type path = string list

  datatype 'a sigConst =
           NoSig
         | Transparent of 'a
         | Opaque of 'a

  type tyvar = string

  type optDocComment = DocComment.docComment option

  (* STRUCTURE EXPRESSION *)
  datatype strexp =
           VarStr of path (* variable structure *)
	 | BaseStr of dec list (* basic structure (struct...end) *)
         | ConstrainedStr of strexp * sigexp sigConst (* constrained sig *)
	 | AppStr of path * (strexp * bool) list (* application (external) *)
         | LetStr of dec list * strexp

  (* FUNCTOR EXPRESSION *)
  and fctexp =
      VarFct of path * fsigexp sigConst	(* functor variable *)
    | BaseFct of
      {	
        params : (string option * sigexp) list,
	body : strexp,
	constraint : sigexp sigConst
      } (* definition of a functor *)
    | AppFct of
      path * (strexp * bool) list * fsigexp sigConst (* application *)
    | LetFct of dec list * fctexp

  (* WHERE SPEC *)
  and wherespec =
      WhType of string list * tyvar list * ty
    | WhStruct of string list * string list

  (* SIGNATURE EXPRESSION *)
  and sigexp =
      VarSig of string (* signature variable *)
    | AugSig of sigexp * wherespec list (* sig augmented with where specs *)
    | BaseSig of spec list (* basic signature (sig...end) *)

  (* FUNCTOR SIGNATURE EXPRESSION *)
  and fsigexp =
      VarFsig of string	(* funsig variable *)
    | BaseFsig of
      {params: (string option * sigexp) list, result:sigexp} (* basic funsig *)

  (* SPECIFICATION FOR SIGNATURE DEFINITIONS *)
  and spec =
      (* structure *)
      StrSpec of (string * loc * sigexp * path option * optDocComment)
    | (* type *)
      TycSpec of (string * loc * tyvar list * ty option * bool * optDocComment)
    | FctSpec of (string * loc * fsigexp * optDocComment) (* functor *)
    | ValSpec of (string * loc * ty * optDocComment) (* value *)
    | DataSpec of {datatycs: db list, withtycs: tb list} (* datatype *)
    | ExceSpec of (string * loc * ty option * optDocComment) (* exception *)
    | ShareStrSpec of path list (* structure sharing *)
    | ShareTycSpec of path list (* type sharing *)
    | IncludeSpec of sigexp (* include specif *)

  (* DECLARATIONS (let and structure) *)
  and dec =
      ValDec of (string * loc * optDocComment) (* values *)
    | FunDec of (string * loc * optDocComment) (* recurs functions *)
    | TypeDec of tb (* type dec *)
    | DatatypeDec of {datatycs : db list, withtycs : tb list}(* datatype dec *)
    | (* abstype dec *)
      AbstypeDec of {datatycs : db list, withtycs : tb list, body : dec list}
    | ExceptionDec of eb (* exception *)
    | (* structure *)
      StrDec of (string * loc * strexp * sigexp sigConst * optDocComment)
    | FctDec of (string * loc * fctexp * optDocComment) (* functor *)
    | SigDec of (string * loc * sigexp * optDocComment) (* signature *)
    | FsigDec of (string * loc * fsigexp * optDocComment) (* funsig *)
    | LocalDec of dec list * dec list
    | OpenDec of path

  and tb = Tb of (string * loc * tyvar list * ty option * optDocComment)

  (* DATATYPE BINDING *)
  and db =
      Db of
      {tyc : string, loc : loc, tyvars : tyvar list, rhs : dbrhs} *
      optDocComment

  (* DATATYPE BINDING RIGHT HAND SIDE *)
  and dbrhs =
      Constrs of (string * loc * ty option * optDocComment) list
    | Repl of string list

  and eb =
      EbGen of (string * loc * ty option * optDocComment)
    | EbDef of (string * loc * path * optDocComment)

  (* TYPES *)
  and ty = 
      VarTy of tyvar (* type variable *)
    | ConTy of string list * ty list (* type constructor *)
    | RecordTy of (string * ty * optDocComment) list (* record *)
    | TupleTy of ty list (* tuple *)
    | CommentedTy of DocComment.docComment * ty (* commented type *)

  (** source file name and set of all declarations in the file. *)
  datatype compileUnit =
           CompileUnit of string * dec list

  (***************************************************************************)
 
end

