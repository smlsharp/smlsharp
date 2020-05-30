(**
 * syntax for the IML.
 *
 * @copyright (c) 2006, Tohoku University.
 * @author Atsushi Ohori 
 * @author Liu Bochao
 *)
structure Absyn = 
struct

  (*% @formatter(Loc.loc) Loc.format_loc *)
  type loc = Loc.loc

  (*% @formatter(Symbol.symbol) Symbol.format_symbol*)
  type symbol = Symbol.symbol

  (*% @formatter(Symbol.longsymbol) Symbol.format_longsymbol*)
  type longsymbol = Symbol.longsymbol

  (*% @formatter(AbsynConst.constant) AbsynConstFormatter.format_constant *)
  datatype constant = datatype AbsynConst.constant

  (*% @formatter(AbsynTy.ty) AbsynTyFormatter.format_ty *)
  datatype ty = datatype AbsynTy.ty
  (*% @formatter(AbsynTy.tvarKind) AbsynTyFormatter.format_tvarKind *)
  datatype tvarKind = datatype AbsynTy.tvarKind
  (*% @formatter(AbsynTy.tvar) AbsynTyFormatter.format_tvar *)
  datatype tvar = datatype AbsynTy.tvar
  (*% @formatter(AbsynTy.kindedTvar) AbsynTyFormatter.format_kindedTvar *)
  datatype kindedTvar = datatype AbsynTy.kindedTvar
  (*% @formatter(AbsynTy.ffiTy) AbsynTyFormatter.format_ffiTy *)
  datatype ffiTy = datatype AbsynTy.ffiTy

  (*%
   * @formatter(binaryChoice) SmlppgUtil.formatBinaryChoice
   * @formatter(prependedOpt) SmlppgUtil.formatPrependedOpt
   * @formatter(ifList) TermFormat.formatIfList
   * @formatter(RecordLabel.label) RecordLabel.format_label
   *)
  datatype pat
    = (*%
        * @format(loc) "_"
       *)
      PATWILD of loc
    | (*%
        * @format(cons * loc) cons
       *)
      PATCONSTANT of constant * loc
    | (*%
       * @format({opPrefix:isop, longsymbol:longsymbol, loc:loc}) longsymbol
       *)
      PATID of {opPrefix:bool, longsymbol:longsymbol, loc:loc}
    | (*%
         @format({ifFlex:ifFlex:binaryChoice, fields:field fields,loc:loc})
         "{" 
            1[ 1 fields(field)("," +1) ] 
             ifFlex()(",...","") 
          1
          "}"
       *)
      PATRECORD of {ifFlex:bool, fields:patrow list, loc:loc}
    | (*%
        @format(pat pats * loc) 
        "(" 
          1[ 1 pats(pat)("," +1) ]
          1 
         ")"
       *)
      PATTUPLE of pat list * loc
    | (*%
        @format(elem elems * loc)
        "[" 
           1[ 1 elems(elem)("," +1) ] 
           1 
        "]"
       *)
      PATLIST of pat list * loc
    | (*%
        @format(pat pats * loc)
          pats:ifList()("(")
             pats(pat)(+d)
          pats:ifList()(")")
       *)
      PATAPPLY of pat list * loc
    | (*%
       * @format(pat * ty * loc)
         "("
           d
            1[ pat + ":" +d ty]
           d
          ")"
      *)
      PATTYPED of pat * ty * loc
    | (*%
       * @format(pat1 * pat2 * loc) 
          pat1 +d "as" +d pat2
       *)
      PATLAYERED of pat * pat * loc

  and patrow 
    = (*%
       * @format(label * pat * loc) 
          1[ label +d "=" +d pat ]
       *)
      PATROWPAT of RecordLabel.label * pat * loc
    | (*%
         @format(label * ty opt1:prependedOpt * pat opt2:prependedOpt * loc)
            label 
            opt1(ty)(+d ":" +)
            opt2(pat)(+d "as" +)
       *)
      PATROWVAR of symbol * (ty option) * (pat option) * loc


  (*%
   * @formatter(prependedOpt) SmlppgUtil.formatPrependedOpt
   *)
  datatype exbind 
    = (*%
         @format({opFlag:b:binaryChoice,
                  conSymbol:name,
                  tyOpt:ty option:prependedOpt,
                  loc})
           name option(ty)(+d "of" +)
        *)
       EXBINDDEF of {opFlag:bool, 
                     conSymbol:symbol, 
                     tyOpt:ty option,
                     loc:loc}
     | (*%
         @format({opFlag1:b1:binaryChoice,
                  conSymbol:left,
                  refLongsymbol:right,
                  opFlag2:b2:binaryChoice,
                  loc})
          left +d "=" +d right
        *)
       EXBINDREP of {opFlag1:bool,
                     conSymbol:symbol, 
                     refLongsymbol:longsymbol,
                     opFlag2:bool,
                     loc:loc}
  (*%
   * @formatter(prependedOpt) SmlppgUtil.formatPrependedOpt
   * @formatter(binaryChoice) SmlppgUtil.formatBinaryChoice
   * @formatter(seqList) TermFormat.formatSeqList
   * @formatter(ifCons) TermFormat.formatIfCons
   *)
  type typbind 
    = (*%
         @format({tyvars:tyvar tyvars, 
                  tyConSymbol:name, 
                  ty:ty * tyLoc, loc
                 })
           tyvars:seqList(tyvar)("(", ",", ")")
           tyvars:ifCons()(+)
           1[ name +d "=" +1 ty ]

        *)
      {
        tyvars : tvar list,
        tyConSymbol : symbol,
        ty : ty * loc,
        loc : loc
      }

  (*%
   * @formatter(prependedOpt) SmlppgUtil.formatPrependedOpt
   * @formatter(binaryChoice) SmlppgUtil.formatBinaryChoice
   * @formatter(seqList) TermFormat.formatSeqList
   * @formatter(ifCons) TermFormat.formatIfCons
   *)
  type datbind 
    = (*%
         @format
            ({tyvars:tyvar tyvars,
              tyConSymbol:tyCon,
              rhs:valcon valcons,
              loc:loc
             } 
            )
          1[
             tyvars:seqList(tyvar)("(", ",", ")") 
             tyvars:ifCons()(+)
             tyCon + "="
              +1
             valcons(valcon)(~1[ +1 "|" ] +)
          ]
         @format:valcon({opFlag:b:binaryChoice,
                         conSymbol:name,
                         tyOpt:ty option:prependedOpt, loc})
            b()("op" +, "") name option(ty)(+d "of" +)
       *)
      {
       tyvars : tvar list, 
       tyConSymbol:symbol,
       rhs : {opFlag:bool, 
              conSymbol:symbol, 
              tyOpt:ty option,
              loc:loc}
               list,
(*
       rhs : (bool * symbol * ty option) list
*)
       loc : loc
      }

  (*%
   * @formatter(AbsynSQL.sqlexp) AbsynSQLFormatter.format_sqlexp
   * @formatter(prependedOpt) SmlppgUtil.formatPrependedOpt
   * @formatter(binaryChoice) SmlppgUtil.formatBinaryChoice
   * @formatter(seqList) TermFormat.formatSeqList
   * @formatter(declist) TermFormat.formatDeclList
   * @formatter(ifCons) TermFormat.formatIfCons
   * @formatter(ifList) TermFormat.formatIfList
   * @formatter(RecordLabel.label) RecordLabel.format_label
   *)
  datatype exp
    = (*%
       * @format(const * loc) const
       *)
      EXPCONSTANT of constant * loc
    | (*%
       * @format(ty * loc) "_sizeof(" !N0{ ty ")" }
       *)
      EXPSIZEOF of ty * loc
    | (*%
       * @format(longid) longid
       *)
      EXPID of  longsymbol
    | (*%
       * @format(longid * loc) longid
       *)
      EXPOPID of longsymbol * loc
    | (*%
         @format(field fields * loc)
           "{" 1[ 1 fields(field)( "," +1) ] 1 "}" 
         @format:field(label * exp) 
           1[ label +d "=" +d exp ]
       *)
      EXPRECORD of (RecordLabel.label * exp) list * loc
    | (*%
         @format(exp * field fields * loc)
          exp + 
          "#" + "{" 
             1[1 fields(field)( "," +1) ]
           1 
          "}"
         @format:field(label * exp) {{label} +d "=" +2 {exp}}
       *)
      EXPRECORD_UPDATE of exp * (RecordLabel.label * exp) list * loc
    | (*%
         @format(selector * loc) "#"selector
       *)
      EXPRECORD_SELECTOR of RecordLabel.label * loc
    | (*%
         @format(field fields * loc)
           "(" 
              1[ 1 fields(field)("," +1) ] 
            1 
            ")"
       *)
      EXPTUPLE of exp list * loc
    | (*%
         @format(elem elems * loc)
           "[" 
              1[ 1 elems(elem)("," +1) ] 
            1 
           "]"
       *)
      EXPLIST of exp list * loc
    | (*%
         @format(exp exps * loc)
           "(" 
              1[ 1 exps(exp)(";" +1) ] 
            1 
            ")"
       *)
      EXPSEQ of exp list * loc
    | (*%
         @format(exp exps * loc) 
           exps:ifList()("(")
             exps(exp)(+d)
          exps:ifList()(")")
        *)
      EXPAPP of exp list * loc
    | (*%
         @format(exp * ty * loc) 
          1[
             exp + ":" 
             +1 ty
           ]
       *)
      EXPTYPED of exp * ty * loc
    | (*%
         @format(left * right * loc) 
           1[
             left +d "andalso" 
             +1 right
            ]
       *)
      EXPCONJUNCTION of exp * exp * loc
    | (*%
         @format(left * right * loc) 
           1[
             left +d "orelse" 
             +1 right
            ]
       *)
      EXPDISJUNCTION of exp * exp * loc
    | (*%
         @format(exp * rule rules * loc)
           1[
             exp 
             +1 "handle" 
             +d rules(rule)(~1[ +1 "|"] +)
           ]
         @format:rule(pat * exp) 
           1[ pat + "=>" +1 exp ]
       *)
      EXPHANDLE of exp * (pat * exp) list * loc
    | (*%
         @format(exp * loc) 
           1[ "raise" +d exp ]
       *)
      EXPRAISE of exp * loc
    | (*%
         @format(cond * ifTrue * ifFalse * loc)
          1[
             "if" +d cond
             +1 1["then" +1 ifTrue]
             +1 1["else" +1 ifFalse]
          ]
       *)
      EXPIF of exp * exp * exp * loc
    | (*%
         @format(cond * body * loc)
           "while" 1[ +d {cond} ] 
           +1 
           "do" 1[ +d {body} ]
       *)
      EXPWHILE of exp * exp * loc
    | (*%
         @format(exp * rule rules * loc)
         1[
           "case" + 1[ exp ] + "of" 
            +1
            1[rules(rule)(~1[+1 "|"] +) ]
          ]
         @format:rule(pat * exp) {{pat} + "=>" +1 {exp}}
       *)
      EXPCASE of exp * (pat * exp) list * loc
    | (*%
         @format(rule rules * loc) 
           1[
              "fn" + rules(rule)(~1[ +1 "|"] +) 
            ]
         @format:rule(pat * exp) 
           1[ pat + "=>" +1 exp]
       *)
      EXPFN of (pat * exp) list * loc
    | (*%
         @format(dec decs * exp exps * loc)
           "let" 1[ +1 decs(dec)( +1) ]
            +1
            "in" 1[ +1 exps(exp)( +1 ) ] 
            +1
            "end"
       *)
      EXPLET of dec list * exp list * loc
    | (*%
         @format(exp * ty * loc)
            exp + ":" + "_import" 
            +1 ty 
       *)
      EXPFFIIMPORT of ffiFun * ffiTy * loc
    | (*%
          @format((e,p,t) s * loc) s(e,p,t)
       *)
      EXPSQL of (exp, pat, ty) AbsynSQL.sqlexp * loc
    | (*%
          @format(e * l) e
       *)
      EXPFOREACH of exp_foreach * loc
    | (*%
          @format(isJoin:binaryChoice *  e1 * e2 * loc) 
           isJoin()("JOIN(","EXTEND(") e1 + "," + e2 ")"
       *)
      EXPJOIN of bool * exp * exp * loc
    | (*% 
          @format(e * ty * loc) "_dynamic" + e + "as" + ty
       *)
      EXPDYNAMIC of exp * ty * loc
    | (*% 
          @format(e * ty * loc) "_dynamic" + e + "is" + ty
       *)
      EXPDYNAMICIS of exp * ty * loc
    | (*% 
          @format(ty * loc) "_dynamicnull" + "as" + ty
       *)
      EXPDYNAMICNULL of ty * loc
    | (*% 
          @format(ty * loc) "_dynamictop" + "as" + ty
       *)
      EXPDYNAMICTOP of ty * loc
    | (*% 
          @format(e * ty * loc) "_dynamicview" + e + "as" + ty
       *)
      EXPDYNAMICVIEW of exp * ty * loc
    | (*% 
         @format(exp * rule rules * loc)
         1[
           "_dynanmiccase" + 1[ exp ] + "of" 
            +1
            1[rules(rule)(~1[+1 "|"] +) ]
          ]
         @format:rule(tv tvs * pat * exp)
          {"{"tvs(tv)(",")"}" +d {pat} + "=>" +1 {exp}}
       *)
      EXPDYNAMICCASE of exp * (kindedTvar list * pat * exp) list * loc
    | (*% 
          @format(ty * loc) "_reifyTy(" +  ty + ")"
       *)
      EXPREIFYTY of ty * loc

  and ffiFun
    = (*%
        @format(x) x
      *)
     FFIEXTERN of string
   | (*%
        @format(x) x
      *)
     FFIFUN of exp

  and exp_foreach =
      (*%
        @format({id, pat, data, iterate, pred})
            "foreach" + id + "in" + data
            +1 "with" + pat
            +1 "while" + 2[pred]
            +1 "do" + 2[iterate]
            +1 "end"
       *)
      FOREACHARRAY of {id:symbol, pat:pat, data:exp, iterate:exp, pred:exp}
    | (*%
        @format({id, whereParam, pat, data, iterate, pred})
            "foreach" + id + "in" + data
            +1 "where" + whereParam
            +1 "with" + pat
            +1 "while" + 2[pred]
            +1 "do" + 2[iterate]
            +1 "end"
       *)
      FOREACHDATA of {id:symbol, whereParam:exp, pat:pat, data:exp, iterate:exp, pred:exp}

  and dec 
    = (*%
         @format(var vars * bind binds * loc)
          1[
            "val" +
             vars:seqList(var)("("d, ","+d, d")")
             vars:ifCons()(+)
             binds(bind)(~1[ +1 "and"] +)
           ]
         @format:bind(pat * exp) 
           1[
              pat + "="  +1 exp
            ]
       *)
      DECVAL of kindedTvar list * (pat * exp) list * loc
    | (*%
         @format(var vars * bind binds * loc)
          1[
            "val" +
             vars:seqList(var)("("+d, ","+d, +d")")
             vars:ifCons()(+)
             "rec" +d 
             binds(bind)(~1[+1 "and" +])
             ]
          @format:bind(pat * exp) 
           1[
             pat +d "=" +1 exp
            ]
       *)
      DECREC of kindedTvar list * (pat * exp) list * loc
    | (*%
         @format(bind binds * loc)
          1[
            "val" +
             "_polyRec" +d 
             binds(bind)(~1[+1 "and" +])
             ]
          @format:bind(fid * ty * exp) 
           1[
             fid + ty + "=" +1 exp
            ]
       *)
      DECPOLYREC of (symbol * ty * exp) list * loc
    | (*%
         @format(var vars * rules binds * loc)
           1[
             "fun" 
             vars:seqList(var)("("d, ","d, d")")
             vars:ifCons()(+)
             +
             binds(rules)(~1[+1 "and" +])
            ]
        @format:rules({fdecl:rule rules, loc}) 
            rules(rule)(+1 "|" +)
        @format:rule(pat pats * ty opt:prependedOpt * exp)
         1[
            pats(pat)(+d) 
            opt(ty)(+d ":" +) + "=" 
            +1 exp
          ]
       *)
      DECFUN of kindedTvar list * {fdecl:(pat list * ty option * exp) list, loc:loc} list * loc 
    | (*%
         @format({tbs:bind binds,loc:loc})
           1[ "type" + binds(bind)(~1[ +1 "and"] +) ]
       *)
      DECTYPE of {tbs : typbind list, loc:loc}
    | (*%
         @format({datatys:bind binds, withtys: withbind withbinds,loc:loc})
         1[  "datatype" + binds(bind)(~1[ +1 "and" ] +)
          ]
         +1
         1[
            "withtype" + 
             withbinds(withbind)(~1[ +1 "and" ] +)
          ]
       *)
      DECDATATYPE of {datatys: datbind list,
                      withtys: typbind list,
                      loc:loc}
    | (*%
         @format({abstys:data datas, withtys:withbind withbinds,
                  body:dec decs * decloc, loc:loc})
           1[
             "abstype" 
             +1 datas(data)(~1[ +1 "and" ] +)
             "withtype" 
             +1 withbinds(withbind)(~1[ +1 "and" ] +)
             "with" 1[ +1 {decs(dec)(+1)} ]
              +1
             "end"
           ]
       *)
      DECABSTYPE of 
            {
             abstys: datbind list,
             withtys: typbind list,
             body: dec list * loc,
             loc:loc
            }
    | (*%
          @format(longstrid longstrids * loc)
            "open" + longstrids(longstrid)(+d)
       *)
      DECOPEN of longsymbol list * loc
    | (*%
         @format({defSymbol, refLongsymbol, loc})
           1[ "datatype" + defSymbol + "=" +1 "datatype" + refLongsymbol ]
       *)
      DECREPLICATEDAT of {defSymbol: symbol,
                          refLongsymbol: longsymbol,
                          loc:loc} (* replication *)
    | (*%
         @format({exbinds:exc excs, loc:loc})
          1[
            "exception" + excs(exc)(~1[ +1 "and" ]+)
           ]
       *)
      DECEXN of {exbinds:exbind list,
                 loc:loc}
    | (*%
         @format(localdec localdecs * dec decs * loc)
           "local" 1[ +1 localdecs(localdec)(+d) ] 
            +1
           "in" 1[ +1 decs(dec)(+1) ] 
           1
           "end"
       *)
      DECLOCAL of dec list * dec list * loc
    | (*%
         @format(int * name names * loc)
           "infix" +d int +d names(name)(+d)
       *)
      DECINFIX of string * symbol list * loc
    | (*%
         @format(int * name names * loc)
           "infixr" +d int +1 names(name)(+d)
       *)
      DECINFIXR of string * symbol list * loc
    | (*%
         @format(name names * loc) 
           "nonfix" +d names(name)(+d)
       *)
      DECNONFIX of symbol list * loc

(****************Module language********************************)
  and strdec 
    = (*%
       * @format(dec * loc) dec
       *)
      COREDEC of dec * loc (* declaration*)
    | (*%
       @format(strbind strbinds * loc)
        1[
          "structure" +
            strbinds(strbind)(~1[+1 "and"] +)
        ]
      *)
      STRUCTBIND of strbind list * loc (* structure bind *)
    | (*%
       @format(localstrdec localstrdecs  * strdec  strdecs * loc)
        "local" 1[ +1 localstrdecs(localstrdec) (+1) ] 
         +1
        "in" 1[ +1 strdecs(strdec)(+1) ] 
         +1
        "end"
      *)
      STRUCTLOCAL of strdec  list * strdec list  * loc (* local declaration *)

  and strexp 
    = (*%
         @format(strdec strdecs * loc)
           "struct"  
             1[ strdecs:declist(strdec)(+1,+1) ]
           +1
           "end"
       *)
      STREXPBASIC of strdec list * loc (*basic*)
    | (*%
       * @format(longid * loc) longid
       *)
      STRID of longsymbol * loc (*structure identifier*)
    | (*%
       * @format(strexp * sigexp * loc) strexp + ":" +  sigexp
       *)
      STRTRANCONSTRAINT of strexp * sigexp * loc (*transparent constraint*)
    | (*%
       * @format(strexp * sigexp * loc) strexp + ":>" + sigexp
       *)
      STROPAQCONSTRAINT of strexp * sigexp * loc (*opaque constraint*)
    | (*%
       * @format(functorid * strexp * loc) {functorid} {+d "(" strexp ")"}
       *)
      FUNCTORAPP of symbol * strexp * loc (* functor application*)
    | (*%
       * @format(strdec strdecs * strexp * loc) 
        "let" 1[ +1 strdecs(strdec)( +1) ]
          +1
          "in" 1[ +1 strexp ] 
          +1
          "end"
       *)
      STRUCTLET  of strdec list * strexp * loc (*local declaration*)
  and strbind 
    = (*%
         @format(strid * sigexp * strexp * loc)
         strid + ":" 
          +1 sigexp + "=" 
          +1 strexp
       *)
      STRBINDTRAN of symbol * sigexp  * strexp * loc 
    | (*%
        * @format(strid * sigexp  * strexp * loc)
        * strid + ":>" +  sigexp + "=" +1  strexp
       *)
      STRBINDOPAQUE of symbol * sigexp  * strexp * loc
    | (*%
         * @format(strid * strexp * loc) strid + "=" +1 strexp
       *)
      STRBINDNONOBSERV of symbol * strexp * loc

  and sigexp 
    = (*%
       * @format(spec * loc) 
          "sig" 1[+1 spec ] 
          +1 
          "end"  
       *)
      SIGEXPBASIC of spec * loc (*basic*)
    | (*%
       * @format(sigid * loc) {sigid} 
       *)
      SIGID of symbol * loc (*signature identifier*)
    | (*%
        @format(sigexp * rlstn * loc)
         1[
            sigexp 
            +1 "where" + "type" + rlstn 

          ]
       @format:rlstn(tyvarseq * longsymbol * ty)
         1[ tyvarseq + longsymbol  +  "=" +1 ty ]
       @format:tyvarseq(tyvar tyvars)
         tyvars:seqList(tyvar)("(", ",", ")")
         tyvars:ifCons()(+)
      *)
     SIGWHERE of sigexp * (tvar list * longsymbol * ty) * loc (* type realisation *) 

  and spec
    = (*%
         @format(specval specvals * loc)
           1[
             "val" + {specvals(specval)(~1[ +1 "and"] +)} 
            ]
         @format:specval(vid * ty) 
            1[ vid + ":" +1 ty ]
       *)
       SPECVAL of (symbol * ty) list * loc (* value *)
    | (*%
         @format(typdesc typdescs * loc)
           1[
              "type" + 
               typdescs(typdesc)(~1[ +1 "and"] +)
            ]
         @format:typdesc(tyvar tyvars * tyCon) 
           tyvars:seqList(tyvar)("(", ",", ")")
           tyvars:ifCons()(+)
           tyCon
       *)
      SPECTYPE of (tvar list * symbol) list * loc (* type *)
    | (*%
         @format(derivedtyp derivedtyps * loc)
           derivedtyps(derivedtyp)(~1[ +1 "and"] +)
         @format:derivedtyp(tyvar tyvars * tyCon * ty)
           1[
             "type" + 
              tyvars:seqList(tyvar) ("(", ",", ")")
              tyvars:ifCons()(+)
              tyCon + "=" +1 ty
           ]
       *)
      SPECDERIVEDTYPE of (tvar list * symbol * ty) list  * loc
    | (*%
         @format(typdesc typdescs * loc)
           1[ 
              "eqtype" + 
              typdescs(typdesc)(~1[ +1 "and"] +)
            ]
         @format:typdesc(tyvar tyvars * tyCon) 
           1[
             tyvars:seqList(tyvar) ("(", ",",  ")") 
             tyvars:ifCons()(+)
             tyCon
            ]
       *)
      SPECEQTYPE of (tvar list * symbol) list * loc (* eqtype *)
    | (*%
         @format(datdesc datdescs * loc)
           1[ "datatype" + datdescs(datdesc)(~1[ +1 "and"] +)
            ]
         @format:datdesc(tyvar tyvars * tyCon * condesc condescs) 
           1[
              tyvars:seqList(tyvar)("(", ",", ")")
              tyvars:ifCons()(+)
              tyCon + "="
              +1
              condescs(condesc)(~1[ +1 "|" ] +)
           ]
         @format:condesc(vid * ty option:prependedOpt)
            vid option(ty)(+d "of" +)
       *)
      SPECDATATYPE of (tvar list * symbol * (symbol * ty option) list ) list * loc (* datatype*)
    | (*%
         @format(tyCon * longsymbol * loc)
           "datatype" + tyCon + "=" + "datatype" + longsymbol
        *)
      SPECREPLIC of symbol * longsymbol * loc (* replication *)
    | (*%
         @format(exdesc exdescs * loc)
           1[ 
              "exception" + exdescs(exdesc)(~1[ +1 "and" ]+)
            ]
          @format:exdesc(vid * ty option:prependedOpt)
             vid option(ty)(+d "of" +)
       *)     
      SPECEXCEPTION of (symbol * ty option) list * loc (* exception *)
    | (*%
         @format(strdesc strdescs * loc)
           1[
             "structure" +
              strdescs(strdesc)(~1[ +1 "and" ] +)
            ]
         @format:strdesc(strid * sigexp) 
           1[  strid ":" +1 sigexp ]
      *)
      SPECSTRUCT of (symbol * sigexp) list * loc (* structure *)
    | (*%
        * @format(sigexp * loc) !N0{"include" + {sigexp}}
        *)
      SPECINCLUDE of sigexp * loc (* include *)
    | (*%
         @format(sigid sigids * loc) !N0{"include" + sigids(sigid)(+)}
       *)
      SPECDERIVEDINCLUDE of symbol list * loc (* include *)
    | (*%
         @format(spec1 * spec2 * loc) 
           spec1
           +1 
           spec2
      *)
      SPECSEQ of spec * spec * loc 
    | (*%
         @format( spec * longsymbol longsymbols * loc) 
          1[
            spec 
            +1 
            1[ "sharing type" 
                +1
               longsymbols(longsymbol)(1[+1 "="] +)
             ]
          ]
       *)
      SPECSHARE of spec * longsymbol list * loc 
    | (*%
         @format(spec * longstrid longstrids * loc)
           spec + !N0{ "sharing" + {longstrids(longstrid)(~2[ +1 "="] +)} }
        *)
       SPECSHARESTR of spec * longsymbol list * loc 
    | (*% 
         @format 
       *)
      SPECEMPTY 

  and funbind 
    = (*%
           @format(funid * strid * sigexp1 * sigexp2 * strexp * loc)
           funid 
           +1 "(" strid + sigexp1 ")" + ":" 
           +1 sigexp2 + "=" 
           +1 strexp
       *)
      FUNBINDTRAN of symbol * symbol * sigexp  * sigexp * strexp * loc 
    | (*%
         @format(funid * strid * sigexp1 * sigexp2 * strexp * loc)
           funid 
            +1 "(" strid + sigexp1 ")" + ":>" 
            +1 sigexp2 + "=" 
            +1 strexp
        *)
      FUNBINDOPAQUE of symbol * symbol * sigexp  * sigexp * strexp * loc 
    | (*%
         @format(funid * strid * sigexp * strexp * loc)
           funid + "(" strid + sigexp +")" + "=" 
           +1 strexp
       *)
      FUNBINDNONOBSERV of symbol * symbol * sigexp  * strexp * loc 
    | (*%
         @format(funid * spec * sigexp * strexp * loc)
           funid + "(" spec +")" + ":" 
           +1 sigexp + "=" 
           +1 strexp
       *)
      FUNBINDSPECTRAN of symbol * spec * sigexp  * strexp * loc 
    | (*%
       * @format(funid * spec * sigexp * strexp * loc)
       * funid + "(" spec +")" + ":>" + sigexp + "=" +1 strexp
       *)
      FUNBINDSPECOPAQUE of symbol * spec * sigexp  * strexp * loc 
    | (*%
       * @format(funid * spec * strexp * loc)
       * funid + "(" spec +")" + "=" +1 strexp
       *)
      FUNBINDSPECNONOBSERV of symbol * spec * strexp * loc 

  and topdec = 
      (*%
       * @format (strdec * loc) strdec
       *)
      TOPDECSTR of strdec * loc (* structure-level declaration *)
    | (*%
         @format(sigdec sigdecs * loc)
           1[
              "signature" + 
                 sigdecs(sigdec)(~1[+1 "and"] +)
            ]
         @format:sigdec(sigid * sigexp) 
            sigid +d "=" +1 sigexp
       *)
      TOPDECSIG of ( symbol * sigexp ) list * loc 
    | (*%
         @format (funbind funbinds * loc)
          1[  
             "functor" + funbinds(funbind)(~1[ +1 "and"] +)
           ]
       *) 
      TOPDECFUN of funbind list * loc (* functor binding *)

  (*%
   * @formatter(RequirePath.path) RequirePath.format_path
   *)
  datatype top 
    = (*%
       * @format (dec decs)
       * decs(dec)(+1)
       *)
      TOPDEC of topdec list
    | (*%
       * @format(f * l) "use" + f
       *)
      USE of RequirePath.path * loc

  (*%
   * @formatter(RequirePath.path) RequirePath.format_path
   *)
  datatype interface 
    = (*% @format(f * l) "_interface" +1 f *)
      INTERFACE of RequirePath.path * loc
    | (*% @format *)
      NOINTERFACE

  (*%
   *)
  type unit 
    = (*%
       * @format({interface,
       *          tops : top tops,
       *          loc : loc})
       * interface "\n"
       * {tops(top)("\n" 1)} "\n"
       *)
      {
        interface : interface,
        tops : top list,
        loc : loc
      }

  (*%
   *)
  datatype unitparseresult
    = (*%
       * @format(unit) 
       *  unit
       *)
      UNIT of unit
    | (*%
       *)
      EOF

  fun getLocExp exp =
      case exp of
        EXPCONSTANT (_, loc) => loc
      | EXPSIZEOF (_, loc) => loc
      | EXPID longsymbol => Symbol.longsymbolToLoc longsymbol
      | EXPOPID (_, loc) => loc
      | EXPRECORD (_, loc) => loc
      | EXPRECORD_UPDATE (_, _, loc) => loc
      | EXPRECORD_SELECTOR (_, loc) => loc
      | EXPTUPLE (_, loc) => loc
      | EXPLIST (_, loc) => loc
      | EXPSEQ (_, loc) => loc
      | EXPAPP (_, loc) => loc
      | EXPTYPED (_, _, loc) => loc
      | EXPCONJUNCTION (_, _, loc) => loc
      | EXPDISJUNCTION (_, _, loc) => loc
      | EXPHANDLE (_, _, loc) => loc
      | EXPRAISE (_, loc) => loc
      | EXPIF (_, _, _, loc) => loc
      | EXPWHILE (_, _, loc) => loc
      | EXPCASE (_, _, loc) => loc
      | EXPFN (_, loc) => loc
      | EXPLET (_, _, loc) => loc
      | EXPFFIIMPORT (_, _, loc) => loc
      | EXPSQL (_, loc) => loc
      | EXPFOREACH (_, loc) => loc
      | EXPJOIN (_, _, _, loc) => loc
      | EXPDYNAMIC (_, _, loc) => loc
      | EXPDYNAMICIS (_, _, loc) => loc
      | EXPDYNAMICNULL (_, loc) => loc
      | EXPDYNAMICTOP (_, loc) => loc
      | EXPDYNAMICVIEW (_, _, loc) => loc
      | EXPDYNAMICCASE (_, _, loc) => loc
      | EXPREIFYTY (_, loc) => loc

  fun getLocPat pat =
      case pat of 
        PATWILD loc => loc
      | PATCONSTANT (_, loc) => loc
      | PATID {opPrefix, longsymbol, loc} => loc
      | PATRECORD {ifFlex, fields, loc} => loc
      | PATTUPLE (_, loc) => loc
      | PATLIST (_, loc) => loc
      | PATAPPLY (_, loc) => loc
      | PATTYPED (_, _, loc) => loc
      | PATLAYERED (_, _, loc) => loc

end
