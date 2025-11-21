(* -*- sml -*- *)
(**
 * syntax for the IML.
 *
 * @copyright (C) 2021 SML# Development Team.
 * @author Atsushi Ohori
 * @author Liu Bochao
 * @author Katsuhiro Ueno
 *)

structure AbsynTy =
struct

  type pos = Loc.pos
  type loc = pos * pos

  (*% @formatter(Symbol.symbol) Symbol.format_symbol *)
  type id =
      (*%
       * @format(symbol * loc)
       * symbol
       *)
      Symbol.symbol * loc

  (*%
   * @formatter(ifcons) AbsynFormatterUtils.ifcons
   *)
  type longid =
      (*%
       * @format(strid strids * id * loc)
       * strids(strid)(".") strids:ifcons()(".",) id
       *)
      id list * id * loc

  (*% *)
  type vid = id

  (*% *)
  type longvid = longid

  (*% *)
  type tycon = id

  (*% *)
  type longtycon = longid

  (*% @formatter(RecordLabel.label) RecordLabel.format_label *)
  type lab =
      (*%
       * @format(label * loc)
       * label
       *)
      RecordLabel.label * loc

  (*% *)
  type tyvar =
      (*%
       * @format(isEq * id)
       * id
       *)
      bool * id

  (*%
   * @formatter(ifsingle) AbsynFormatterUtils.ifsingle
   *)
  type tyvarseq =
      (*%
       * @format(tyvar tyvars * loc)
       * tyvars:ifsingle()(,"(")
       * !N0{ tyvars(tyvar)("," +1) }
       * tyvars:ifsingle()(,")")
       *)
      tyvar list * loc

  (*%
   * @formatter(iftrue) AbsynFormatterUtils.iftrue
   *)
  type op_longvid =
      (*%
       * @format(op1 * longvid * loc)
       * !N0{
       *   op1:iftrue()("op" +1,)
       *   longvid
       * }
       *)
      bool * longvid * loc

  (*%
   * @formatter(iftrue) AbsynFormatterUtils.iftrue
   * @formatter(ifcons) AbsynFormatterUtils.ifcons
   * @formatter(ifsingle) AbsynFormatterUtils.ifsingle
   * @formatter(ifsome) AbsynFormatterUtils.ifsome
   *)
  datatype ty =
      (*%
       * @format(tyvar)
       * tyvar
       *)
      TYVAR of tyvar
    | (*%
       * @format(row rows * flex * loc)
       * "{" !N0{ rows(row)("," +1) flex:iftrue()("," +1 "...",) } "}"
       *)
      TYRECORD of tyrow list * bool * loc
    | (*%
       * @format(tyseq tyseqOpt * longtycon * loc)
       * L9{ tyseqOpt(tyseq) tyseqOpt:ifsome()(2[+1],) longtycon }
       *)
      TYCON of tyseq option * longtycon * loc
    | (*%
       * @format(ty tys * loc)
       * N8{ tys(ty)(+1 "*" +d) }
       *)
      TYTUPLE of ty list * loc
    | (*%
       * @format(ty1 * ty2 * loc)
       * R7{ ty1 +1 "->" +d ty2 }
       *)
      TYFUN of ty * ty * loc
    | (*%
       * @format(ty * loc)
       * "(" !N0{ ty } ")"
       *)
      TYPAREN of ty * loc
    | (*%
       * @format(loc)
       * "_"
       *)
      TYWILD of loc
    | (*%
       * @format(tyvar)
       * tyvar
       *)
      TYVAR_FREE of kinded_tyvar
    | (*%
       * @format(tyvars * ty * loc)
       * "[" !N0{ tyvars "." +1 ty } "]"
       *)
      TYPOLY of bound_tyvars * ty * loc

  and kind =
      (*%
       * @format(prop props * loc)
       * props:ifcons()(d "#",)
       * props(prop)(d "#")
       *)
      UNIV of id list * loc
    | (*%
       * @format(prop props * row rows * loc)
       * props:ifcons()(d "#",)
       * props(prop)(d "#")
       * d "#{" 2[1] rows(row)("," 2[+1]) 1 "}"
       *)
      REC of id list * tyrow list * loc

  withtype kinded_tyvar =
      (*%
       * @format(tyvar * kind kindOpt * loc)
       * !N0{ tyvar kindOpt(kind) }
       *)
      tyvar * kind option * loc

  and bound_tyvars =
      (*%
       * @format(tyvar tyvars * loc)
       * !N0{ tyvars(tyvar:kinded_tyvar)("," +1) }
       *)
      (tyvar * kind option * loc) list * loc

  and tyrow =
      (*%
       * @format(lab * ty * loc)
       * !N0{ lab +1 ":" +d ty }
       *)
      lab * ty * loc

  and tyseq =
      (*%
       * @format(ty tys * loc)
       * tys:ifsingle()(,"(")
       * !N0{ tys(ty)("," +1) }
       * tys:ifsingle()(,")")
       *)
      ty list * loc

  (*%
   * @formatter(ifsingle) AbsynFormatterUtils.ifsingle
   *)
  type kinded_tyvarseq =
      (*%
       * @format(tyvar tyvars * loc)
       * tyvars:ifsingle()(,"(")
       * !N0{ tyvars(tyvar)("," +1) }
       * tyvars:ifsingle()(,")")
       *)
      kinded_tyvar list * loc

  (*%
   * @formatter(ifcons) AbsynFormatterUtils.ifcons
   *)
  type ffi_attr =
      (*%
       * @format(prop props * loc)
       * !N0{
       *   props:ifcons()("__attribute__(" 2[1],)
       *   props(prop)("," 2[+1])
       *   props:ifcons()(1 ")",)
       * }
       *)
      id list * loc

  (*%
   * @formatter(ifsome) AbsynFormatterUtils.ifsome
   * @formatter(ifsingle) AbsynFormatterUtils.ifsingle
   * @formatter(ifcons) AbsynFormatterUtils.ifcons
   *)
  datatype ffi_ty =
      (*%
       * @format(tyvar)
       * tyvar
       *)
      FFITYVAR of tyvar
    | (*%
       * @format(row rows * loc)
       * "{" !N0{ rows(row)("," +1) } "}"
       *)
      FFITYRECORD of ffi_tyrow list * loc
    | (*%
       * @format(tyseq tyseqOpt * longtycon * loc)
       * L9{ tyseqOpt(tyseq) tyseqOpt:ifsome()(2[+1],) longtycon }
       *)
      FFITYCON of ffi_tyseq option * longtycon * loc
    | (*%
       * @format(ty tys * loc)
       * N8{ tys(ty)(+1 "*" +d) }
       *)
      FFITYTUPLE of ffi_ty list * loc
    | (*%
       * @format(attr attrOpt * arg * ret * loc)
       * R7{ attrOpt(attr) attrOpt:ifsome()(+1,) arg +1 "->" +d ret }
       *)
      FFITYFUN of ffi_attr option * ffi_arg * ffi_ret * loc
    | (*%
       * @format(ty * loc)
       * "(" !N0{ ty } ")"
       *)
      FFITYPAREN of ffi_ty * loc

  withtype ffi_tyrow =
      (*%
       * @format(lab * ty * loc)
       * !N0{ lab +1 ":" +d ty }
       *)
      lab * ffi_ty * loc

  and ffi_tyseq =
      (*%
       * @format(ty tys * loc)
       * tys:ifsingle()(,"(")
       * !N0{ tys(ty)("," +1) }
       * tys:ifsingle()(,")")
       *)
      ffi_ty list * loc

  and ffi_arg =
      (*%
       * @format(arg args * varg vargs vargOpt * loc)
       * args:ifsingle()(vargOpt:ifsome()("(",), "(")
       * !N0{
       *   args(arg)("," +1)
       *   vargOpt:ifsome()(
       *     args:ifcons()("," +1,)
       *     "...(" 2[1]
       *     !N0{ vargOpt(vargs(varg)("," 2[+1])) }
       *     1 ")",
       *   )
       * }
       * args:ifsingle()(vargOpt:ifsome()(")",), ")")
       *)
      ffi_ty list * ffi_ty list option * loc

  and ffi_ret =
      (*%
       * @format(ty tys * loc)
       * tys:ifsingle()(,"(")
       * !N0{ tys(ty)("," +1) }
       * tys:ifsingle()(,")")
       *)
      ffi_ty list * loc

end
