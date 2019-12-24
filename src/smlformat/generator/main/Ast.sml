(**
 * Abstract syntax tree.
 * 
 * @author Copyright 1992 by AT&T Bell Laboratories
 * @author YAMATODANI Kiyoshi
 * @version $Id: Ast.sml,v 1.5 2006/01/24 17:57:44 katsuu Exp $
 *)
structure Ast : AST =
struct

  (* to mark positions in files *)
  type srcpos = int  (* character position from beginning of stream (base 0) *)
  type region = srcpos * srcpos   (* start and end position of region *)

  (* symbolic path (Modules.spath) *)
  type path = string list

  (** declaration header format comment *)
  type headerFormatComment = 
       {
         (** destination anchor *) destinationOpt : string option,
         (** custom formatters *) formatters : (string * string) list,
         (** header of generated function *) funHeaderOpt : string option,
         params : {
           (** additional parameter names *) params : string list,
           (** external names *) externs : (string * string) list
         },
         (** ditto format comments (EXPERIMENTAL EXTENSION by Ueno) *)
         ditto : string list,
         (** prefix of formatter name *) prefix : string
       }

  type innerHeaderFormatComment = 
       {
         (** custom formatters *) formatters : (string * string) list,
         (** additional parameter names *) params : string list,
         (** prefix of formatter name *) prefix : string option
       }

  (** defining type expression format comment *)
  type definingFormatComment = 
       {
         (** prefix of formatter name *) prefix : string,
         (** primary tag *) primaryTag : FormatTemplate.formattag,
         (** list of local tags *) localTags : FormatTemplate.formattag list
       }

  (** STRUCTURE EXPRESSION *) 
  datatype strexp =
      (** variable structure *) VarStr
    | (** defined structure *) BaseStr of dec
    | (** signature constrained *) ConstrainedStr of strexp
    | (** application (external) *) AppStr
    | (** let in structure *) LetStr of dec * strexp

  (** FUNCTOR EXPRESSION *)
  and fctexp =
      (** functor variable *) VarFct
    | (** definition of a functor *)
      BaseFct of
      {
	body : strexp
      }
    | LetFct of dec * fctexp
    | (** application *)
      AppFct

  (** DECLARATIONS (let and structure) *)
  and dec =
      (** values *) ValDec
    | (** recursive values *) ValrecDec
    | (** recurs functions *) FunDec
    | (** type dec *)
      TypeDec of
      {
        formatComments : headerFormatComment list,
        tbs : tb list,
        region : region
      }
    | (** datatype dec *)
      DatatypeDec of
      {
        formatComments : headerFormatComment list,
        datatycs: db list,
        withtycs: tb list,
        region: region
      }
    | (** abstract type *)
      AbstypeDec of
      {
        formatComments : headerFormatComment list,
        abstycs: db list,
        withtycs: tb list,
        bodyBeginPos : srcpos,
        region: region
      }
    | (** exception *)
      ExceptionDec of
      {
        formatComments : headerFormatComment list,
        ebs : eb list,
        region : region
      }
    | (** structure *) StrDec of strb list
    | (** functor *) FctDec of fctb list
    | (** signature *) SigDec
    | (** funsig *) FsigDec
    | (** local dec *) LocalDec of dec * dec
    | (** sequence of dec *) SeqDec of dec list
    | (** open structures *) OpenDec
    | (** overloading (internal) *) OvldDec
    | (** fixity *) FixDec

  (** TYPE BINDING *)
  and tb =
      Tb of
      {
        tyConName : string,
        ty : ty,
        tyvars : tyvar list,
        formatComments : definingFormatComment list,
        innerHeaderFormatComments: innerHeaderFormatComment list
      }

  (** DATATYPE BINDING *)
  and db =
      Db of {tyConName : string, tyvars : tyvar list, rhs : dbrhs,
             innerHeaderFormatComments: innerHeaderFormatComment list}

  (** DATATYPE BINDING RIGHT HAND SIDE *)
  and dbrhs =
      Constrs of
      {
        formatComments : definingFormatComment list,
        valConName : string,
        argTypeOpt : ty option
      } list
    | Repl of string list

  (** EXCEPTION BINDING *)
  and eb =
      (** Exception definition *)
      EbGen of
      {
        formatComments : definingFormatComment list,
        innerHeaderFormatComments: innerHeaderFormatComment list,
        exn: string,
        etype: ty option
      }
    | (** defined by equality *)
      EbDef of
      {
        formatComments : definingFormatComment list,
        innerHeaderFormatComments: innerHeaderFormatComment list,
        exn: string,
        edef: path
      }

  (** STRUCTURE BINDING *)
  and strb =
      Strb of {name: string,def: strexp}

  (** FUNCTOR BINDING *)
  and fctb =
      Fctb of {name: string,def: fctexp}

  (** TYPE VARIABLE *)
  and tyvar =
      Tyv of string

  (** TYPES *)
  and ty =
      (** type variable *) VarTy of tyvar
    | (** type constructor *) ConTy of string list * ty list
    | (** record *) RecordTy of (string * ty) list
    | (** tuple *) TupleTy of ty list

  (** used as the prefix of formatter name if no @prefix tag is declared. *)
  val DefaultFormatterPrefix = "format_"

  datatype parse_result =
      Header of headerFormatComment list
    | InnerHeader of innerHeaderFormatComment list
    | Defining of definingFormatComment list
    | DefiningWithInner of
      innerHeaderFormatComment list * definingFormatComment list

end (* structure Ast *)

