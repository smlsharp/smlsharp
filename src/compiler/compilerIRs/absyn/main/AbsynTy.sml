(* -*- sml -*- *)
(**
 * syntax for the IML.
 *
 * @copyright (C) 2021 SML# Development Team.
 * @author Atsushi Ohori
 * @author Liu Bochao
 *)

structure AbsynTy =
struct

  type loc = Loc.loc

  (*% @formatter(Symbol.symbol) Symbol.format_symbol *)
  type symbol = Symbol.symbol

  (*% @formatter(Symbol.longsymbol) Symbol.format_longsymbol *)
  type longsymbol = Symbol.longsymbol

  (*%
   * @formatter(listWithEnclosureOne) SmlppgUtil.formatListWithEnclosureOne
   * @formatter(listWithEnclosure) SmlppgUtil.formatListWithEnclosure
   * @formatter(binaryChoice) SmlppgUtil.formatBinaryChoice
   * @formatter(prependedOpt) SmlppgUtil.formatPrependedOpt
   * @formatter(formatListWithEnclosureOne) SmlppgUtil.formatListWithEnclosureOne
   * @formatter(NameMap.namePath) NameMap.format_namePath
   * @formatter(seqList) TermFormat.formatSeqList
   * @formatter(ifCons) TermFormat.formatIfCons
   * @formatter(RecordLabel.label) RecordLabel.format_label
   *)
  datatype ty
    = (*%
         @format(loc) "_"
       *)
      TYWILD of loc
    | (*%
         @format(tvar * loc) tvar
       *)
      TYID of tvar * loc
    | (*%
         @format({freeTvar:tvar, tvarKind, loc:loc}) 
            tvar
       *)
      FREE_TYID of {freeTvar:tvar, tvarKind:tvarKind, loc:loc}
    | (*%
         @format({ifFlex, fields:field fields, loc:loc})
             ifFlex:binaryChoice()
              (1[fields:listWithEnclosure(field)(","d, "{", ",...}") ],
               1[fields:listWithEnclosure(field)(","d, "{", "}"   ) ])
         @format:field(label * ty)
           label ":" ty
       *)
      TYRECORD of {ifFlex:bool, fields:(RecordLabel.label * ty) list, loc:loc}
    | (*%
         @format(arg args * longsymbol * loc)
          args:seqList(arg)("(" d, "," d, d ")")
          args:ifCons()(+)
          longsymbol
       *)
      TYCONSTRUCT of ty list * longsymbol * loc
    | (*%
         @format(elem elems * loc)
           elems(elem)( + "*" +d )
       *)
      TYTUPLE of ty list * loc
    | (*%
       * @format(dom * result * loc)
          "("
           1[
              dom + "->" +d result
            ]
           +1
           ")"
       *)
      TYFUN of ty * ty * loc
    | (*%
       * @format(tvar tvars * ty * loc)
        "["
          +1
          1[
            tvars(tvar)(",") "."
            +1 ty
           ]
          +1
         "]"
       *)
      TYPOLY of (kindedTvar) list * ty * loc

  and tvarKind
    = (*%
       * @format (prop props * loc)
          props:ifCons()("#")
          props(prop)("#")
       *)
      UNIV of string list * loc
    | (*%
         @format({properties:prop props, recordKind:field fields} * loc)
            props:ifCons()("#")
            props(prop)("#")
            "#{"
              1[1 fields(field)(","+1)]
            1
            "}"
         @format:field(label * ty) {label} +d ":" +d {ty}
       *)
      REC of {properties:string list,
              recordKind:(RecordLabel.label * ty) list} * loc

  withtype tvar
    = (*%
       * @format({symbol:symbol, isEq}) symbol
       *)
      {symbol:symbol, isEq:bool}

  and kindedTvar
    = (*%
       * @format({symbol, isEq} * tvarKind) symbol tvarKind
       *)
      {symbol:symbol, isEq:bool} * tvarKind

  (*%
   * @formatter(seqList) TermFormat.formatSeqList
   * @formatter(ifCons) TermFormat.formatIfCons
   * @formatter(RecordLabel.label) RecordLabel.format_label
   *)
  datatype ffiTy
    = (*%
       * @format(attr attrs * dom doms * var vars varsOpt * ret rets * loc)
       *           R1{ "(" doms(dom)("," + ) ")" +d "->"
       *               2[ +1 "(" rets(ret)("," + ) ")" ] }
       *)
      FFIFUNTY of string list * ffiTy list * ffiTy list option * ffiTy list
                  * loc
    | (*%
       * @format(elem elems * loc) N1{ d elems(elem)( + "*" +d ) }
       *)
      FFITUPLETY of ffiTy list * loc
    | (*%
       * @format(tvar * loc) tvar
       *)
      FFITYVAR of tvar * loc
    | (*%
       * @format(field fields * loc)
       *           !N0{ "{" 2[ 1 fields(field)("," +1) ] 1 "}" }
       * @format:field(label * ty) {label} +d ":" +d {ty}
       *)
      FFIRECORDTY of (RecordLabel.label * ffiTy) list * loc
    | (*%
       * @format(arg args * longsymbol * loc)
          args:seqList(arg)("(" d, "," d, d ")")
          args:ifCons()(+)
          longsymbol
       *)
      FFICONTY of ffiTy list * longsymbol * loc

  (*% *)
  datatype opaque_impl
    = (*% @format(ty) ty *)
      IMPL_TY of longsymbol
    | (*% @format "*" *)
      IMPL_TUPLE
    | (*% @format "{}" *)
      IMPL_RECORD
    | (*% @format "->" *)
      IMPL_FUNC

end
