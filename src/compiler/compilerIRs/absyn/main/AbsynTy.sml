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

  type id =
      Symbol.symbol * loc

  type longid =
      id list * id * loc

  type vid = id
  type longvid = longid
  type tycon = id
  type longtycon = longid

  type lab =
      RecordLabel.label * loc

  type tyvar =
      bool * id

  type tyvarseq =
      tyvar list * loc

  type op_longvid =
      bool * longvid * loc

  datatype ty =
      TYVAR of tyvar
    | TYRECORD of tyrow list * bool * loc
    | TYCON of tyseq option * longtycon * loc
    | TYTUPLE of ty list * loc
    | TYFUN of ty * ty * loc
    | TYPAREN of ty * loc
    | TYWILD of loc
    | TYVAR_FREE of kinded_tyvar
    | TYPOLY of bound_tyvars * ty * loc

  and kind =
      UNIV of id list * loc
    | REC of id list * tyrow list * loc

  withtype kinded_tyvar =
      tyvar * kind option * loc

  and bound_tyvars =
      (tyvar * kind option * loc) list * loc

  and tyrow =
      lab * ty * loc

  and tyseq =
      ty list * loc

  type kinded_tyvarseq =
      kinded_tyvar list * loc

  type ffi_attr =
      id list * loc

  datatype ffi_ty =
      FFITYVAR of tyvar
    | FFITYRECORD of ffi_tyrow list * loc
    | FFITYCON of ffi_tyseq option * longtycon * loc
    | FFITYTUPLE of ffi_ty list * loc
    | FFITYFUN of ffi_attr option * ffi_arg * ffi_ret * loc
    | FFITYPAREN of ffi_ty * loc

  withtype ffi_tyrow =
      lab * ffi_ty * loc

  and ffi_tyseq =
      ffi_ty list * loc

  and ffi_arg =
      ffi_ty list * ffi_ty list option * loc

  and ffi_ret =
      ffi_ty list * loc

end
