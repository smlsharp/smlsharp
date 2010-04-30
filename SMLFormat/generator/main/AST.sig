(**
 * Abstract syntax tree.
 * 
 * @author Copyright 1992 by AT&T Bell Laboratories
 * @author YAMATODANI Kiyoshi
 * @version $Id: AST.sig,v 1.5 2006/01/24 17:57:44 katsuu Exp $
 *)
signature AST =
sig

  datatype fixity = INfix of int | INfixR of int | NONfix

  (* to mark positions in files *)
  type srcpos  (* = int *)
  type region  (* = srcpos * srcpos *)

  (** symbolic path (SymPath.spath) *)
  type path

  datatype 'a sigConst =
           NoSig
         | Transparent of 'a
         | Opaque of 'a

  (** declaration header format comment *)
  type headerFormatComment = 
       {
         (** destination anchor *) destinationOpt : string option,
         (** custom formatters *) formatters : (string * string) list,
         (** header of generated function *) funHeaderOpt : string option,
         (** additional parameter names *) params : string list,
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

  (** EXPRESSIONS *)
  type exp = unit

  (** RULE for case functions and exception handler *)
  datatype rule = Rule of {pat:pat,exp:exp}

  (** PATTERN *)
  and pat =
      (** empty pattern *) WildPat
    | (** variable pattern *) VarPat of path
    | (** integer *) IntPat of int
    | (** word int *) WordPat of int
    | (** string *) StringPat of string
    | (** char *) CharPat of string
    | (** record *) RecordPat of {def:(string * pat) list, flexibility:bool}
    | (** [list,in,square,brackets] *) ListPat of pat list
    | (** tuple *) TuplePat of pat list
    | (** patterns prior to fixity parsing *) FlatAppPat of pat list
    | (** application *) AppPat of {constr:pat,argument:pat}
    | (** constraint *) ConstraintPat of {pattern:pat,constraint:ty}
    | (** as expressions *) LayeredPat of {varPat:pat,expPat:pat}
    | (** vector pattern *) VectorPat of pat list
    | (** mark a pattern *) MarkPat of pat * region
    | (** or-pattern *) OrPat of pat list

  (** STRUCTURE EXPRESSION *) 
  and strexp =
      (** variable structure *) VarStr of path
    | (** defined structure *) BaseStr of dec
    | (** signature constrained *) ConstrainedStr of strexp * sigexp sigConst
    | (** application (external) *) AppStr of path * (strexp * bool) list
    | (** application (internal) *) AppStrI of path * (strexp * bool) list
    | (** let in structure *) LetStr of dec * strexp
    | (** mark *) MarkStr of strexp * region

  (** FUNCTOR EXPRESSION *)
  and fctexp =
      (** functor variable *) VarFct of path * fsigexp sigConst
    | (** definition of a functor *)
      BaseFct of
      {
        params : (string option * sigexp) list,
	body : strexp,
	constraint : sigexp sigConst
      }
    | LetFct of dec * fctexp
    | (** application *)
      AppFct of path * (strexp * bool) list * fsigexp sigConst
    | (** mark *) MarkFct of fctexp * region 

  (** WHERE SPEC *)
  and wherespec =
      WhType of string list * tyvar list * ty
    | WhStruct of string list * string list

  (** SIGNATURE EXPRESSION *)
  and sigexp =
      (** signature variable *) VarSig of string
    | (** sig augmented with where spec *) AugSig of sigexp * wherespec list
    | (** defined signature *) BaseSig of spec list
    | (** mark *) MarkSig of sigexp * region

  (** FUNCTOR SIGNATURE EXPRESSION *)
  and fsigexp =
      (** funsig variable *) VarFsig of string
    | (** defined funsig *)
      BaseFsig of {param: (string option * sigexp) list, result:sigexp}
    | (** mark a funsig *) MarkFsig of fsigexp * region

  (** SPECIFICATION FOR SIGNATURE DEFINITIONS *)
  and spec =
      (** structure *) StrSpec of (string * sigexp * path option) list
    | (** type *) TycSpec of ((string * tyvar list * ty option) list * bool)
    | (** functor *) FctSpec of (string * fsigexp) list
    | (** value *) ValSpec of (string * ty) list
    | (** datatype *) DataSpec of {datatycs: db list, withtycs: tb list}
    | (** exception *) ExceSpec of (string * ty option) list
    | (** structure sharing *) ShareStrSpec of path list
    | (** type sharing *) ShareTycSpec of path list
    | (** include specif *) IncludeSpec of sigexp
    | (** mark a spec *) MarkSpec of spec * region

  (** DECLARATIONS (let and structure) *)
  and dec =
      (** values *) ValDec of (vb list * tyvar list)
    | (** recursive values *) ValrecDec of (rvb list * tyvar list)
    | (** recurs functions *) FunDec of (fb list * tyvar list)
    | (** type dec *)
      TypeDec of {formatComments : headerFormatComment list, tbs : tb list}
    | (** datatype dec *)
      DatatypeDec of
      {
        formatComments : headerFormatComment list,
        datatycs: db list,
        withtycs: tb list
      }
    | (** abstract type *)
      AbstypeDec of
      {
        formatComments : headerFormatComment list,
        abstycs: db list,
        withtycs: tb list,
        bodyBeginPos : srcpos,
        body: dec
      }
    | (** exception *)
      ExceptionDec of
      {formatComments : headerFormatComment list, ebs : eb list}
    | (** structure *) StrDec of strb list
    | (** abstract struct *) AbsDec of strb list
    | (** functor *) FctDec of fctb list
    | (** signature *) SigDec of sigb list
    | (** funsig *) FsigDec of fsigb list
    | (** local dec *) LocalDec of dec * dec
    | (** sequence of dec *) SeqDec of dec list
    | (** open structures *) OpenDec of path list
    | (** overloading (internal) *) OvldDec of string * ty * exp list
    | (** fixity *) FixDec of {fixity: fixity, ops: string list}
    | (** mark a dec *) MarkDec of dec * region

  (** VALUE BINDINGS *)
  and vb =
      Vb of {pat:pat, exp:exp, lazyp:bool}
    | MarkVb of vb * region

  (** RECURSIVE VALUE BINDINGS *)
  and rvb =
      Rvb of {var:string, exp:exp, resultty: ty option, lazyp: bool}
    | MarkRvb of rvb * region

  (** RECURSIVE FUNCTIONS BINDINGS *)
  and fb =
      Fb of (clause list * bool)
    | MarkFb of fb * region

  (** CLAUSE: a definition for a single pattern in a function binding *)
  and clause = Clause of {pats: pat list, resultty: ty option, exp:exp}

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
    | MarkTb of tb * region

  (** DATATYPE BINDING *)
  and db =
      Db of {tyConName : string, tyvars : tyvar list, rhs : dbrhs, lazyp: bool,
             innerHeaderFormatComments: innerHeaderFormatComment list}
    | MarkDb of db * region

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
    | MarkEb of eb * region

  (** STRUCTURE BINDING *)
  and strb =
      Strb of {name: string,def: strexp,constraint: sigexp sigConst}
    | MarkStrb of strb * region

  (** FUNCTOR BINDING *)
  and fctb =
      Fctb of {name: string,def: fctexp}
    | MarkFctb of fctb * region

  (** SIGNATURE BINDING *)
  and sigb =
      Sigb of {name: string,def: sigexp}
    | MarkSigb of sigb * region

  (** FUNSIG BINDING *)
  and fsigb =
      Fsigb of {name: string,def: fsigexp}
    | MarkFsigb of fsigb * region

  (** TYPE VARIABLE *)
  and tyvar =
      Tyv of string
    | MarkTyv of tyvar * region

  (** TYPES *)
  and ty =
      (** type variable *) VarTy of tyvar
    | (** type constructor *) ConTy of string list * ty list
    | (** record *) RecordTy of (string * ty) list
    | (** tuple *) TupleTy of ty list
    | (** mark type *) MarkTy of ty * region

  val DefaultFormatterPrefix : string

end (* signature AST *)


