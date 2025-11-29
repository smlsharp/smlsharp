(**
 * syntax for the IML.
 *
 * @copyright (C) 2021 SML# Development Team.
 * @author Atsushi Ohori
 * @author Liu Bochao
 * @author Katsuhiro Ueno
 *)
structure Absyn =
struct
  open AbsynTy

  datatype constant = datatype AbsynConst.constant

  type strid = id
  type sigid = id
  type funid = id
  type longstrid = longid

  type op_vid =
      bool * vid * loc

  type require_path =
      RequirePath.path * loc

  type extern_name =
      string * loc

  type exist_quant =
      kinded_tyvar list * loc

  datatype pat =
      PATWILD of loc
    | PATCONST of constant * loc
    | PATID of op_longvid
    | PATRECORD of patrow list * bool * loc
    | PATTUPLE of pat list * loc
    | PATLIST of pat list * loc
    | PATPAREN of pat * loc
    | PATAPP of pat * pat * loc
    | PATINFIX of pat * vid * pat * loc
    | PATTYPED of pat * ty * loc
    | PATAS of op_vid * ty option * pat * loc

  and patrow =
      PATROW of lab * pat * loc
    | PATROWVAR of vid * ty option * pat option * loc

  datatype exbind =
      EXBIND of op_vid * ty option * loc
    | EXBINDREP of op_vid * op_longvid * loc

  type typbind =
      tyvarseq option * tycon * ty * loc

  type conbind =
      op_vid * ty option * loc

  type datbind =
      tyvarseq option * tycon * conbind list * loc

  type withty =
      typbind list * loc

  datatype exp =
      EXPCONST of constant * loc
    | EXPID of op_longvid
    | EXPRECORD of exprow list * loc
    | EXPSELECT of lab * loc
    | EXPTUPLE of exp list * loc
    | EXPLIST of exp list * loc
    | EXPSEQ of exp list * loc
    | EXPLET of dec list * (exp list * loc) * loc
    | EXPPAREN of exp * loc
    | EXPAPP of exp * exp * loc
    | EXPINFIX of exp * vid * exp * loc
    | EXPTYPED of exp * ty * loc
    | EXPANDALSO of exp * exp * loc
    | EXPORELSE of exp * exp * loc
    | EXPHANDLE of exp * mrule list * loc
    | EXPRAISE of exp * loc
    | EXPIF of exp * exp * exp * loc
    | EXPWHILE of exp * exp * loc
    | EXPCASE of exp * mrule list * loc
    | EXPFN of mrule list * loc
    | EXPSIZEOF of ty * loc
    | EXPRECORD_UPDATE of exp * exprow list * loc
    | EXPTUPLE_UPDATE of exp * exp list * loc
    | EXPIMPORT_NAME of extern_name * ffi_ty * loc
    | EXPIMPORT_EXP of exp * ffi_ty * loc
    | EXPSQL of sqlexp
    | EXPFOREACH_DATA of vid * exp * exp * pat * exp * exp * loc
    | EXPFOREACH_ARRAY of vid * exp * pat * exp * exp * loc
    | EXPJOIN of exp * exp * loc
    | EXPEXTEND of exp * exp * loc
    | EXPUPDATE1 of exp * exp * loc
    | EXPUPDATE2 of exp * exp * loc
    | EXPDYNAMIC_AS of exp * ty * loc
    | EXPDYNAMIC_OF of exp * ty * loc
    | EXPDYNAMICVIEW of exp * ty * loc
    | EXPDYNAMICNULL of ty * loc
    | EXPDYNAMICTOP of ty * loc
    | EXPDYNAMICCASE of exp * dynamic_mrule list * loc
    | EXPREIFYTY of ty * loc

  and exprow =
      EXPROW of lab * exp * loc
    | EXPROWVAR of vid * ty option * loc

  and valbind =
      VALBIND of pat * exp * loc
    | VALREC of valbind list * loc

  and dec =
      DECVAL of kinded_tyvarseq option * valbind list * loc
    | DECVALREC of kinded_tyvarseq option * valrecbind list * loc
    | DECFUN of kinded_tyvarseq option * fvalbind list * loc
    | DECTYPE of typbind list * loc
    | DECDATATYPE of datbind list * withty option * loc
    | DECDATATYPEREP of tycon * longtycon * loc
    | DECABSTYPE of datbind list * withty option * dec list * loc
    | DECEXCEPTION of exbind list * loc
    | DECLOCAL of dec list * dec list * loc
    | DECOPEN of longstrid list * loc
    | DECSEMICOLON of loc
    | DECINFIX of string option * vid list * loc
    | DECINFIXR of string option * vid list * loc
    | DECNONFIX of vid list * loc
    | DECDO of exp * loc

  withtype sqlexp =
      (exp, pat, ty) AbsynSQL.top

  and mrule =
      pat * exp * loc

  and dynamic_mrule =
      exist_quant option * pat * exp * loc

  and valrecbind =
      pat * exp * loc

  and frule =
      pat * ty option * exp * loc

  and fvalbind =
      (pat * ty option * exp * loc) list * loc

  type let_body = exp list * loc

  type valdesc =
      vid * ty * loc

  type typdesc =
      tyvarseq option * tycon * loc

  type condesc =
      vid * ty option * loc

  type datdesc =
      tyvarseq option * tycon * condesc list * loc

  type exdesc =
      vid * ty option * loc

  type wheretype =
      tyvarseq option * longtycon * ty * loc

  datatype spec =
      SPECVAL of valdesc list * loc
    | SPECTYPE of typdesc list * loc
    | SPECTYPBIND of typbind list * loc
    | SPECEQTYPE of typdesc list * loc
    | SPECDATATYPE of datdesc list * loc
    | SPECDATATYPEREP of tycon * longtycon * loc
    | SPECEXCEPTION of exdesc list * loc
    | SPECSTRUCTURE of strdesc list * loc
    | SPECINCLUDE of sigexp * loc
    | SPECINCLUDE_ID of sigid list * loc
    | SPECSHARINGTYPE of spec list * longtycon list * loc
    | SPECSHARING of spec list * longstrid list * loc
    | SPECSEMICOLON of loc

  and sigexp =
      SIGBASIC of spec list * loc
    | SIGID of sigid
    | SIGWHERE of sigexp * wheretype list * loc

  withtype strdesc =
      strid * sigexp * loc

  type sigbind =
      strid * sigexp * loc

  datatype sigop =
      TRANSPARENT
    | OPAQUE

  type sigconstraint =
      sigop * sigexp * loc

  datatype strexp =
      STRBASIC of strdec list * loc
    | STRID of longstrid
    | STRCONSTRAINT of strexp * sigconstraint * loc
    | STRAPP of funid * fun_arg option * loc
    | STRLET of strdec list * strexp * loc

  and strdec =
      STRDEC of dec
    | STRUCTURE of strbind list * loc
    | STRLOCAL of strdec list * strdec list * loc
    | STRSEMICOLON of loc

  and fun_arg =
      FUNARG of strexp
    | FUNARG_DEC of strdec list * loc

  withtype strbind =
      strid * sigconstraint option * strexp * loc

  datatype fun_param =
      FUNPARAM of strid * sigexp * loc
    | FUNPARAM_SPEC of spec list * loc

  type funbind =
      funid * fun_param option * sigconstraint option * strexp * loc

  type sigdec =
      sigbind list * loc

  datatype topdec =
      TOPSTRDEC of strdec
    | TOPSIGNATURE of sigdec
    | TOPFUNCTOR of funbind list * loc
    | TOPEXP of exp * loc

  datatype top =
      TOPDEC of topdec list * loc
    | USE of require_path * loc
    | U_USE of require_path * loc
    | TOPSEMICOLON of loc

  type interface =
      require_path * loc

  type compile_unit =
      interface option * top list * loc

  datatype absyn =
      UNIT of compile_unit
    | EOF of pos

end
