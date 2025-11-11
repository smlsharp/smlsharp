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

  (*% *)
  type longid =
      (*%
       * @format(id ids * loc)
       * ids(id)(".")
       *)
      id list * loc

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
   * @formatter(ifcons2) AbsynFormatterUtils.ifcons2
   * @formatter(N0ifcons2) AbsynFormatterUtils.N0ifcons2
   *)
  type tyvarseq =
      (*%
       * @format(tyvar tyvars * loc)
       * tyvars:ifcons2()("(",)
       * tyvars:N0ifcons2()(tyvars(tyvar)("," +1))
       * tyvars:ifcons2()(")",)
       *)
      tyvar list * loc

  (*%
   * @formatter(iftrue) AbsynFormatterUtils.iftrue
   *)
  type op_longvid =
      (*%
       * @format(op1 * longvid * loc)
       * op1:iftrue()("op" +d,)
       * longvid
       *)
      bool * longvid * loc

  (*%
   * @formatter(iftrue) AbsynFormatterUtils.iftrue
   * @formatter(ifcons) AbsynFormatterUtils.ifcons
   * @formatter(ifcons2) AbsynFormatterUtils.ifcons2
   * @formatter(N0ifcons2) AbsynFormatterUtils.N0ifcons2
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
       * !N0{ tyseqOpt(tyseq) tyseqOpt:ifsome()(2[+1],) longtycon }
       *)
      TYCON of tyseq option * longtycon * loc
    | (*%
       * @format(ty tys * loc)
       * !N0{ tys(ty)(+1 "*" +d) }
       *)
      TYTUPLE of ty list * loc
    | (*%
       * @format(argTy * retTy * loc)
       * !N0{ argTy +1 "->" +d retTy }
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
       * @format(tyvar tyvars * ty * loc)
       * "[" !N0{ tyvars(tyvar)("," +1) "." +1 ty } "]"
       *)
      TYPOLY of kinded_tyvar list * ty * loc

  and kind =
      (*%
       * @format(prop props * loc)
       * props:ifcons()("#",)
       * props(prop)("#")
       *)
      UNIV of id list * loc
    | (*%
       * @format(prop props * row rows * loc)
       * props:ifcons()("#",)
       * props(prop)("#")
       * "#{" !N0{ 2[ rows(row)("," +1) ] } "}"
       *)
      REC of id list * tyrow list * loc

  withtype kinded_tyvar =
      (*%
       * @format(tyvar * kind kindOpt * loc)
       * tyvar kindOpt(kind)
       *)
      tyvar * kind option * loc

  and tyrow =
      (*%
       * @format(lab * ty * loc)
       * !N0{ lab +1 ":" +d ty }
       *)
      lab * ty * loc

  and tyseq =
      (*%
       * @format(ty tys * loc)
       * tys:ifcons2()("(",)
       * tys:N0ifcons2()(tys(ty)("," +1))
       * tys:ifcons2()(")",)
       *)
      ty list * loc

  (*%
   * @formatter(ifcons2) AbsynFormatterUtils.ifcons2
   * @formatter(N0ifcons2) AbsynFormatterUtils.N0ifcons2
   *)
  type kinded_tyvarseq =
      (*%
       * @format(tyvar tyvars * loc)
       * tyvars:ifcons2()("(",)
       * tyvars:N0ifcons2()(tyvars(tyvar)("," +1))
       * tyvars:ifcons2()(")",)
       *)
      kinded_tyvar list * loc

  (*%
   * @formatter(ifcons) AbsynFormatterUtils.ifcons
   * @formatter(N0ifcons) AbsynFormatterUtils.N0ifcons
   *)
  type ffi_attr =
      (*%
       * @format(prop props * loc)
       * props:ifcons()("__attribute__(",)
       * props:N0ifcons()(props(prop)("," +1))
       * props:ifcons()(")",)
       *)
      id list * loc

  (*%
   * @formatter(ifsome) AbsynFormatterUtils.ifsome
   * @formatter(ifcons2) AbsynFormatterUtils.ifcons2
   * @formatter(ifsingle) AbsynFormatterUtils.ifsingle
   * @formatter(N0ifcons2) AbsynFormatterUtils.N0ifcons2
   * @formatter(N0ifnotsingle) AbsynFormatterUtils.N0ifnotsingle
   * @formatter(ifsome) AbsynFormatterUtils.ifsome
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
       * !N0{ tyseqOpt(tyseq) tyseqOpt:ifsome()(2[+1],) longtycon }
       *)
      FFITYCON of ffi_tyseq option * longtycon * loc
    | (*%
       * @format(ty tys * loc)
       * !N0{ tys(ty)(+1 "*" +d) }
       *)
      FFITYTUPLE of ffi_ty list * loc
    | (*%
       * @format(attr attrOpt * arg * ret * loc)
       * !N0{ attrOpt(attr) attrOpt:ifsome()(+1,) arg +1 "->" +d ret }
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
       * tys:ifcons2()("(",)
       * tys:N0ifcons2()(tys(ty)("," +1))
       * tys:ifcons2()(")",)
       *)
      ffi_ty list * loc

  and ffi_arg =
      (*%
       * @format(arg args * varg vargs vargOpt * loc)
       * !N0{
       *   "("
       *   !N0{
       *     args(arg)("," +1)
       *     vargOpt:ifsome()("," +d "...(",)
       *     !N0{ vargOpt(vargs(varg)("," +1)) }
       *     vargOpt:ifsome()(")",)
       *   }
       *   ")"
       * }
       *)
      ffi_ty list * ffi_ty list option * loc

  and ffi_ret =
      (*%
       * @format(ty tys * loc)
       * tys:ifsingle()(,"(")
       * tys:N0ifnotsingle()(tys(ty)("," +1))
       * tys:ifsingle()(,")")
       *)
      ffi_ty list * loc

end
